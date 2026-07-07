// =============================================================================
// SYNTH MATRIX WIRE - C++ Interface
// =============================================================================
//
// This header defines the C++ interface for the Synth Matrix Wire protocol.
// It provides:
//   - MatrixEvent structure (Header + Payload + Binary)
//   - IMatrixWire interface for transport abstraction
//   - IMatrixHandler callback interface
//
// Usage:
//   auto wire = MatrixWireFactory::create(config);
//   wire->connect();
//   wire->send(event);
//
// =============================================================================

#pragma once

#include <cstdint>
#include <string>
#include <vector>
#include <memory>
#include <functional>
#include <variant>
#include <optional>
#include <chrono>

namespace synth::wire {

// =============================================================================
// FORWARD DECLARATIONS
// =============================================================================

class MatrixEvent;
class MatrixHeader;
class IMatrixWire;
class IMatrixHandler;

// =============================================================================
// ENUMS
// =============================================================================

enum class PayloadType : uint8_t {
    Unspecified = 0,
    Asset = 1,
    State = 2,
    Rpc = 3,
    Binary = 4,
    Control = 5
};

enum class Compression : uint8_t {
    None = 0,
    Zstd = 1,
    Lz4 = 2,
    Gzip = 3
};

enum class AssetEventType : uint8_t {
    Unspecified = 0,
    Load = 1,
    Resolve = 2,
    Data = 3,
    Ready = 4,
    Error = 5,
    Evict = 6
};

enum class StateEventType : uint8_t {
    Unspecified = 0,
    SnapshotRequest = 1,
    Snapshot = 2,
    Delta = 3,
    Input = 4,
    Correct = 5,
    Ack = 6
};

enum class RpcEventType : uint8_t {
    Unspecified = 0,
    Call = 1,
    Result = 2,
    Error = 3,
    StreamStart = 4,
    StreamData = 5,
    StreamEnd = 6
};

enum class ControlEventType : uint8_t {
    Unspecified = 0,
    Ping = 1,
    Pong = 2,
    WireDiscover = 3,
    WireAvailable = 4,
    WireSelect = 5,
    WireConnect = 6,
    WireFail = 7,
    WireFallback = 8
};

// =============================================================================
// MATRIX HEADER
// =============================================================================

struct MatrixHeader {
    std::string eventId;
    std::string uri;
    int64_t timestamp = 0;
    std::string sourceId;
    std::string sourceType;
    std::string wireId;
    std::string correlationId;
    std::string streamId;
    uint32_t streamSequence = 0;
    Compression compression = Compression::None;
    uint32_t flags = 0;
    uint32_t binaryLength = 0;
    std::string binaryChecksum;
    std::string binaryContentType;

    // Flag helpers
    bool hasBinary() const { return (flags & 0x01) != 0; }
    bool isCompressed() const { return (flags & 0x02) != 0; }
    bool isEndStream() const { return (flags & 0x04) != 0; }
    bool requiresAck() const { return (flags & 0x08) != 0; }
    bool isEncrypted() const { return (flags & 0x10) != 0; }
    bool isChunked() const { return (flags & 0x20) != 0; }
};

// =============================================================================
// PAYLOAD TYPES
// =============================================================================

struct AssetPayload {
    std::string assetId;
    AssetEventType type = AssetEventType::Unspecified;
    uint8_t priority = 2;  // Normal
    bool includeMetadata = false;

    // Chunked transfer
    int32_t chunkIndex = 0;
    int32_t totalChunks = 0;
    bool isFinalChunk = false;

    // Metadata
    std::string filename;
    std::string contentType;
    int64_t totalSize = 0;
    std::string totalChecksum;

    // Result
    std::string resolvedUri;
    int64_t durationMs = 0;
    bool fromCache = false;

    // Error
    std::string errorCode;
    std::string errorMessage;
    bool retriable = false;
};

struct StatePayload {
    std::string sceneId;
    StateEventType type = StateEventType::Unspecified;
    uint64_t tick = 0;

    // Snapshot
    int32_t nodeCount = 0;
    int64_t uncompressedSize = 0;

    // Delta
    int32_t changeCount = 0;

    // Input
    uint32_t inputSequence = 0;
    std::string inputType;
    std::string targetNodeId;

    // Correction
    std::string correctedNodeId;
    std::string correctedField;

    // Ack
    uint64_t ackTick = 0;
    std::vector<uint32_t> ackInputs;
};

struct RpcPayload {
    std::string requestId;
    RpcEventType type = RpcEventType::Unspecified;

    // Call
    std::string method;

    // Result
    bool success = false;
    int64_t durationMs = 0;
    int32_t itemCount = 0;

    // Error
    std::string errorCode;
    std::string errorMessage;
    bool retriable = false;

    // Stream
    int32_t streamSequence = 0;
    int32_t totalChunks = 0;
    bool isFinal = false;
};

struct BinaryPayload {
    std::string transferId;
    std::string assetId;
    std::string filename;
    std::string contentType;
    int64_t totalSize = 0;
    int32_t totalChunks = 0;

    // Chunk
    int32_t chunkIndex = 0;
    int64_t chunkOffset = 0;
    std::string chunkChecksum;

    // Complete
    std::string totalChecksum;
    int64_t durationMs = 0;

    // Error
    std::string errorCode;
    std::string errorMessage;
    int32_t failedAtChunk = 0;
    bool resumable = false;
};

struct ControlPayload {
    ControlEventType type = ControlEventType::Unspecified;

    // Ping/Pong
    int64_t pingTimestamp = 0;
    int64_t pongTimestamp = 0;
    int32_t measuredLatencyMs = 0;

    // Wire
    std::string wireId;
    std::string wireUrl;
    std::string wireStatus;
    int32_t latencyHintMs = 0;
    int32_t bandwidthHintKbps = 0;

    // Fallback
    std::string fallbackTo;
    std::string fallbackReason;

    // Reconnect
    int32_t attempt = 0;
    int32_t maxAttempts = 0;
    int32_t backoffMs = 0;
};

using Payload = std::variant<
    std::monostate,
    AssetPayload,
    StatePayload,
    RpcPayload,
    BinaryPayload,
    ControlPayload
>;

// =============================================================================
// MATRIX EVENT
// =============================================================================

class MatrixEvent {
public:
    MatrixHeader header;
    PayloadType payloadType = PayloadType::Unspecified;
    Payload payload;
    std::vector<uint8_t> data;  // Binary data

    // Convenience constructors
    static MatrixEvent createAssetLoad(const std::string& assetId, uint8_t priority = 2);
    static MatrixEvent createAssetData(const std::string& assetId,
                                       const std::vector<uint8_t>& data,
                                       int32_t chunkIndex, int32_t totalChunks);
    static MatrixEvent createRpcCall(const std::string& method,
                                     const std::vector<uint8_t>& args);
    static MatrixEvent createStateDelta(const std::string& sceneId,
                                        uint64_t tick,
                                        const std::vector<uint8_t>& deltaData);
    static MatrixEvent createPing();
    static MatrixEvent createPong(int64_t pingTimestamp);

    // Payload accessors
    template<typename T>
    T* getPayload() {
        return std::get_if<T>(&payload);
    }

    template<typename T>
    const T* getPayload() const {
        return std::get_if<T>(&payload);
    }

    // Serialization
    std::vector<uint8_t> serialize() const;
    static MatrixEvent deserialize(const std::vector<uint8_t>& buffer);

    // Wire format (with SYNT magic header)
    std::vector<uint8_t> toWireFormat() const;
    static MatrixEvent fromWireFormat(const std::vector<uint8_t>& buffer);
};

// =============================================================================
// MATRIX WIRE INTERFACE
// =============================================================================

class IMatrixHandler {
public:
    virtual ~IMatrixHandler() = default;

    virtual void onEvent(const MatrixEvent& event) = 0;
    virtual void onConnected(const std::string& wireId) = 0;
    virtual void onDisconnected(const std::string& wireId, const std::string& reason) = 0;
    virtual void onError(const std::string& errorCode, const std::string& message) = 0;
};

class IMatrixWire {
public:
    virtual ~IMatrixWire() = default;

    // Connection lifecycle
    virtual bool connect() = 0;
    virtual void disconnect() = 0;
    virtual bool isConnected() const = 0;

    // Send events
    virtual bool send(const MatrixEvent& event) = 0;
    virtual bool sendAsync(const MatrixEvent& event,
                          std::function<void(bool success)> callback) = 0;

    // Request/Response (RPC)
    virtual std::optional<MatrixEvent> call(const MatrixEvent& request,
                                            std::chrono::milliseconds timeout) = 0;

    // Streaming
    virtual void subscribe(const std::vector<std::string>& patterns) = 0;
    virtual void unsubscribe(const std::vector<std::string>& patterns) = 0;

    // Handler
    virtual void setHandler(IMatrixHandler* handler) = 0;

    // Wire info
    virtual std::string getWireId() const = 0;
    virtual std::string getWireType() const = 0;  // "grpc", "websocket", "tcp"
};

// =============================================================================
// WIRE FACTORY
// =============================================================================

struct WireConfig {
    std::string type;           // "grpc", "websocket", "tcp", "http"
    std::string url;
    std::string clientId;

    // Timeouts
    int32_t connectTimeoutMs = 5000;
    int32_t requestTimeoutMs = 30000;

    // Reconnection
    bool autoReconnect = true;
    int32_t reconnectDelayMs = 1000;
    int32_t maxReconnectAttempts = 10;

    // Compression
    Compression defaultCompression = Compression::None;

    // TLS
    bool useTls = false;
    std::string certFile;
    std::string keyFile;
    std::string caFile;
};

class MatrixWireFactory {
public:
    static std::unique_ptr<IMatrixWire> create(const WireConfig& config);
    static std::unique_ptr<IMatrixWire> createGrpc(const std::string& host, int port);
    static std::unique_ptr<IMatrixWire> createWebSocket(const std::string& url);
    static std::unique_ptr<IMatrixWire> createTcp(const std::string& host, int port);
};

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

namespace util {
    std::string generateEventId();
    std::string generateCorrelationId();
    int64_t currentTimestampMs();
    std::string computeChecksum(const std::vector<uint8_t>& data);
}

} // namespace synth::wire