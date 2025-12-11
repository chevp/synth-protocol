// =============================================================================
// SYNTH MATRIX WIRE - C++ Client Example
// =============================================================================
//
// This example demonstrates how to use the MatrixWire interface in C++.
//
// Build:
//   g++ -std=c++17 -I. MatrixWireExample.cpp -lsynth-wire -lprotobuf -o client
//
// =============================================================================

#include "MatrixWire.h"
#include <iostream>
#include <thread>

using namespace synth::wire;

// =============================================================================
// EVENT HANDLER
// =============================================================================

class MyHandler : public IMatrixHandler {
public:
    void onEvent(const MatrixEvent& event) override {
        std::cout << "[EVENT] " << event.header.uri << std::endl;

        switch (event.payloadType) {
            case PayloadType::Asset: {
                auto* asset = event.getPayload<AssetPayload>();
                if (asset) {
                    handleAssetEvent(*asset, event.data);
                }
                break;
            }
            case PayloadType::State: {
                auto* state = event.getPayload<StatePayload>();
                if (state) {
                    handleStateEvent(*state, event.data);
                }
                break;
            }
            case PayloadType::Rpc: {
                auto* rpc = event.getPayload<RpcPayload>();
                if (rpc) {
                    handleRpcEvent(*rpc, event.data);
                }
                break;
            }
            case PayloadType::Control: {
                auto* control = event.getPayload<ControlPayload>();
                if (control) {
                    handleControlEvent(*control);
                }
                break;
            }
            default:
                std::cout << "  Unknown payload type" << std::endl;
        }
    }

    void onConnected(const std::string& wireId) override {
        std::cout << "[CONNECTED] Wire: " << wireId << std::endl;
    }

    void onDisconnected(const std::string& wireId, const std::string& reason) override {
        std::cout << "[DISCONNECTED] Wire: " << wireId << " Reason: " << reason << std::endl;
    }

    void onError(const std::string& errorCode, const std::string& message) override {
        std::cerr << "[ERROR] " << errorCode << ": " << message << std::endl;
    }

private:
    void handleAssetEvent(const AssetPayload& asset, const std::vector<uint8_t>& data) {
        switch (asset.type) {
            case AssetEventType::Ready:
                std::cout << "  Asset ready: " << asset.assetId << std::endl;
                std::cout << "  Size: " << asset.totalSize << " bytes" << std::endl;
                std::cout << "  From cache: " << (asset.fromCache ? "yes" : "no") << std::endl;
                break;

            case AssetEventType::Data:
                std::cout << "  Asset data chunk: " << asset.assetId << std::endl;
                std::cout << "  Chunk: " << asset.chunkIndex << "/" << asset.totalChunks << std::endl;
                std::cout << "  Data size: " << data.size() << " bytes" << std::endl;
                // Process binary data here
                break;

            case AssetEventType::Error:
                std::cerr << "  Asset error: " << asset.errorCode << std::endl;
                std::cerr << "  Message: " << asset.errorMessage << std::endl;
                break;

            default:
                break;
        }
    }

    void handleStateEvent(const StatePayload& state, const std::vector<uint8_t>& data) {
        switch (state.type) {
            case StateEventType::Snapshot:
                std::cout << "  State snapshot: " << state.sceneId << std::endl;
                std::cout << "  Tick: " << state.tick << std::endl;
                std::cout << "  Nodes: " << state.nodeCount << std::endl;
                // Apply snapshot from data
                break;

            case StateEventType::Delta:
                std::cout << "  State delta: " << state.sceneId << std::endl;
                std::cout << "  Tick: " << state.tick << std::endl;
                std::cout << "  Changes: " << state.changeCount << std::endl;
                // Apply delta from data
                break;

            case StateEventType::Correct:
                std::cout << "  State correction for node: " << state.correctedNodeId << std::endl;
                // Apply correction
                break;

            default:
                break;
        }
    }

    void handleRpcEvent(const RpcPayload& rpc, const std::vector<uint8_t>& data) {
        if (rpc.type == RpcEventType::Result) {
            std::cout << "  RPC result: " << rpc.requestId << std::endl;
            std::cout << "  Success: " << (rpc.success ? "yes" : "no") << std::endl;
            std::cout << "  Duration: " << rpc.durationMs << "ms" << std::endl;
        } else if (rpc.type == RpcEventType::Error) {
            std::cerr << "  RPC error: " << rpc.errorCode << std::endl;
        }
    }

    void handleControlEvent(const ControlPayload& control) {
        if (control.type == ControlEventType::Pong) {
            std::cout << "  Pong received, latency: " << control.measuredLatencyMs << "ms" << std::endl;
        }
    }
};

// =============================================================================
// MAIN - EXAMPLE USAGE
// =============================================================================

int main() {
    std::cout << "=== Synth Matrix Wire C++ Client ===" << std::endl;

    // Create wire configuration
    WireConfig config;
    config.type = "grpc";
    config.url = "localhost:50051";
    config.clientId = "cpp-client-001";
    config.autoReconnect = true;

    // Create wire instance
    auto wire = MatrixWireFactory::create(config);

    // Set event handler
    MyHandler handler;
    wire->setHandler(&handler);

    // Connect
    if (!wire->connect()) {
        std::cerr << "Failed to connect" << std::endl;
        return 1;
    }

    // Subscribe to events
    wire->subscribe({
        "synth://asset/*",
        "synth://state/scene_001/*",
        "synth://rpc/*"
    });

    // ==========================================================================
    // Example 1: Load an asset
    // ==========================================================================
    std::cout << "\n--- Loading asset ---" << std::endl;

    auto loadEvent = MatrixEvent::createAssetLoad("car_model", 3);  // High priority
    wire->send(loadEvent);

    // ==========================================================================
    // Example 2: RPC call (synchronous)
    // ==========================================================================
    std::cout << "\n--- RPC call ---" << std::endl;

    // Create RPC request
    std::string jsonArgs = R"({"id": "car_model", "include_metadata": true})";
    auto rpcEvent = MatrixEvent::createRpcCall(
        "asset/resolve",
        std::vector<uint8_t>(jsonArgs.begin(), jsonArgs.end())
    );

    // Synchronous call with timeout
    auto response = wire->call(rpcEvent, std::chrono::milliseconds(5000));
    if (response) {
        auto* rpc = response->getPayload<RpcPayload>();
        if (rpc && rpc->success) {
            std::cout << "Resolved URI: " << std::string(response->data.begin(), response->data.end()) << std::endl;
        }
    }

    // ==========================================================================
    // Example 3: Send state input
    // ==========================================================================
    std::cout << "\n--- State input ---" << std::endl;

    // Player moved - send input to server
    std::string inputJson = R"({"position": [10.0, 0.0, 5.0], "rotation": [0, 90, 0]})";
    auto inputEvent = MatrixEvent();
    inputEvent.payloadType = PayloadType::State;
    inputEvent.payload = StatePayload{
        .sceneId = "scene_001",
        .type = StateEventType::Input,
        .inputSequence = 100,
        .inputType = "transform",
        .targetNodeId = "player_01"
    };
    inputEvent.data = std::vector<uint8_t>(inputJson.begin(), inputJson.end());
    inputEvent.header.uri = "synth://state/scene_001/input";
    inputEvent.header.eventId = util::generateEventId();
    inputEvent.header.timestamp = util::currentTimestampMs();

    wire->send(inputEvent);

    // ==========================================================================
    // Example 4: Ping
    // ==========================================================================
    std::cout << "\n--- Ping ---" << std::endl;

    auto pingEvent = MatrixEvent::createPing();
    wire->send(pingEvent);

    // ==========================================================================
    // Keep running to receive events
    // ==========================================================================
    std::cout << "\nWaiting for events (press Ctrl+C to exit)..." << std::endl;

    // In a real application, this would be your main loop
    for (int i = 0; i < 10; ++i) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    // Cleanup
    wire->disconnect();

    return 0;
}

// =============================================================================
// IMPLEMENTATION STUBS (for compilation - real impl in library)
// =============================================================================

namespace synth::wire {

MatrixEvent MatrixEvent::createAssetLoad(const std::string& assetId, uint8_t priority) {
    MatrixEvent event;
    event.payloadType = PayloadType::Asset;
    event.payload = AssetPayload{
        .assetId = assetId,
        .type = AssetEventType::Load,
        .priority = priority
    };
    event.header.uri = "synth://asset/load#" + assetId;
    event.header.eventId = util::generateEventId();
    event.header.timestamp = util::currentTimestampMs();
    return event;
}

MatrixEvent MatrixEvent::createAssetData(const std::string& assetId,
                                         const std::vector<uint8_t>& data,
                                         int32_t chunkIndex, int32_t totalChunks) {
    MatrixEvent event;
    event.payloadType = PayloadType::Asset;
    event.payload = AssetPayload{
        .assetId = assetId,
        .type = AssetEventType::Data,
        .chunkIndex = chunkIndex,
        .totalChunks = totalChunks,
        .isFinalChunk = (chunkIndex == totalChunks - 1)
    };
    event.data = data;
    event.header.uri = "synth://asset/data#" + assetId;
    event.header.eventId = util::generateEventId();
    event.header.timestamp = util::currentTimestampMs();
    event.header.flags |= 0x01;  // HAS_BINARY
    event.header.binaryLength = static_cast<uint32_t>(data.size());
    return event;
}

MatrixEvent MatrixEvent::createRpcCall(const std::string& method,
                                       const std::vector<uint8_t>& args) {
    MatrixEvent event;
    event.payloadType = PayloadType::Rpc;
    event.payload = RpcPayload{
        .requestId = util::generateEventId(),
        .type = RpcEventType::Call,
        .method = method
    };
    event.data = args;
    event.header.uri = "synth://rpc/call#" + method;
    event.header.eventId = util::generateEventId();
    event.header.correlationId = std::get<RpcPayload>(event.payload).requestId;
    event.header.timestamp = util::currentTimestampMs();
    if (!args.empty()) {
        event.header.flags |= 0x01;
        event.header.binaryLength = static_cast<uint32_t>(args.size());
    }
    return event;
}

MatrixEvent MatrixEvent::createStateDelta(const std::string& sceneId,
                                          uint64_t tick,
                                          const std::vector<uint8_t>& deltaData) {
    MatrixEvent event;
    event.payloadType = PayloadType::State;
    event.payload = StatePayload{
        .sceneId = sceneId,
        .type = StateEventType::Delta,
        .tick = tick
    };
    event.data = deltaData;
    event.header.uri = "synth://state/" + sceneId + "/delta";
    event.header.eventId = util::generateEventId();
    event.header.timestamp = util::currentTimestampMs();
    event.header.flags |= 0x01;
    event.header.binaryLength = static_cast<uint32_t>(deltaData.size());
    return event;
}

MatrixEvent MatrixEvent::createPing() {
    MatrixEvent event;
    event.payloadType = PayloadType::Control;
    event.payload = ControlPayload{
        .type = ControlEventType::Ping,
        .pingTimestamp = util::currentTimestampMs()
    };
    event.header.uri = "synth://control/ping";
    event.header.eventId = util::generateEventId();
    event.header.timestamp = util::currentTimestampMs();
    return event;
}

MatrixEvent MatrixEvent::createPong(int64_t pingTimestamp) {
    MatrixEvent event;
    event.payloadType = PayloadType::Control;
    auto now = util::currentTimestampMs();
    event.payload = ControlPayload{
        .type = ControlEventType::Pong,
        .pingTimestamp = pingTimestamp,
        .pongTimestamp = now,
        .measuredLatencyMs = static_cast<int32_t>(now - pingTimestamp)
    };
    event.header.uri = "synth://control/pong";
    event.header.eventId = util::generateEventId();
    event.header.timestamp = now;
    return event;
}

namespace util {
    std::string generateEventId() {
        // Simplified - real impl uses UUID
        static int counter = 0;
        return "evt_" + std::to_string(++counter);
    }

    std::string generateCorrelationId() {
        static int counter = 0;
        return "cor_" + std::to_string(++counter);
    }

    int64_t currentTimestampMs() {
        return std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()
        ).count();
    }

    std::string computeChecksum(const std::vector<uint8_t>& data) {
        // Simplified - real impl uses SHA-256
        return "checksum_placeholder";
    }
}

} // namespace synth::wire