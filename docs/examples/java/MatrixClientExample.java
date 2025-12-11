// =============================================================================
// SYNTH MATRIX WIRE - Java Client Example
// =============================================================================
//
// This example demonstrates how to use the MatrixWire interface as a client.
//
// Build:
//   javac -cp synth-wire.jar MatrixClientExample.java
//   java -cp .:synth-wire.jar MatrixClientExample
//
// =============================================================================

package io.synth.protocol.wire.example;

import io.synth.protocol.wire.*;
import java.time.Duration;
import java.util.Arrays;
import java.util.Optional;

public class MatrixClientExample {

    public static void main(String[] args) {
        System.out.println("=== Synth Matrix Wire Java Client ===");

        // Create wire configuration
        WireConfig config = new WireConfig();
        config.setType("grpc");
        config.setUrl("localhost:50051");
        config.setClientId("java-client-001");
        config.setAutoReconnect(true);

        // Create wire instance
        try (MatrixWire wire = MatrixWireFactory.create(config)) {

            // Set event handler
            wire.setHandler(new MyHandler());

            // Connect
            if (!wire.connect()) {
                System.err.println("Failed to connect");
                return;
            }

            // Subscribe to events
            wire.subscribe(Arrays.asList(
                "synth://asset/*",
                "synth://state/scene_001/*",
                "synth://rpc/*"
            ));

            // ======================================================================
            // Example 1: Load an asset
            // ======================================================================
            System.out.println("\n--- Loading asset ---");

            MatrixEvent loadEvent = MatrixEvent.createAssetLoad("car_model", 3);
            wire.send(loadEvent);

            // ======================================================================
            // Example 2: RPC call (synchronous)
            // ======================================================================
            System.out.println("\n--- RPC call ---");

            String jsonArgs = "{\"id\": \"car_model\", \"include_metadata\": true}";
            MatrixEvent rpcEvent = MatrixEvent.createRpcCall(
                "asset/resolve",
                jsonArgs.getBytes()
            );

            Optional<MatrixEvent> response = wire.call(rpcEvent, Duration.ofSeconds(5));
            if (response.isPresent()) {
                RpcPayload rpc = response.get().getPayloadAs(RpcPayload.class);
                if (rpc != null && rpc.isSuccess()) {
                    String result = new String(response.get().getData());
                    System.out.println("Resolved URI: " + result);
                }
            }

            // ======================================================================
            // Example 3: Send state input
            // ======================================================================
            System.out.println("\n--- State input ---");

            String inputJson = "{\"position\": [10.0, 0.0, 5.0], \"rotation\": [0, 90, 0]}";

            MatrixEvent inputEvent = new MatrixEvent();
            inputEvent.setPayloadType(PayloadType.STATE);

            StatePayload state = new StatePayload();
            state.setSceneId("scene_001");
            state.setType(StateEventType.INPUT);
            state.setInputSequence(100);
            state.setInputType("transform");
            state.setTargetNodeId("player_01");
            inputEvent.setPayload(state);

            inputEvent.setData(inputJson.getBytes());
            inputEvent.getHeader().setUri("synth://state/scene_001/input");
            inputEvent.getHeader().setEventId(MatrixUtil.generateEventId());
            inputEvent.getHeader().setTimestamp(System.currentTimeMillis());

            wire.send(inputEvent);

            // ======================================================================
            // Example 4: Ping
            // ======================================================================
            System.out.println("\n--- Ping ---");

            MatrixEvent pingEvent = MatrixEvent.createPing();
            wire.send(pingEvent);

            // ======================================================================
            // Keep running to receive events
            // ======================================================================
            System.out.println("\nWaiting for events (10 seconds)...");
            Thread.sleep(10000);

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    // ==========================================================================
    // EVENT HANDLER
    // ==========================================================================

    static class MyHandler implements MatrixHandler {

        @Override
        public void onEvent(MatrixEvent event) {
            System.out.println("[EVENT] " + event.getHeader().getUri());

            switch (event.getPayloadType()) {
                case ASSET:
                    handleAssetEvent(event);
                    break;
                case STATE:
                    handleStateEvent(event);
                    break;
                case RPC:
                    handleRpcEvent(event);
                    break;
                case CONTROL:
                    handleControlEvent(event);
                    break;
                default:
                    System.out.println("  Unknown payload type");
            }
        }

        @Override
        public void onConnected(String wireId) {
            System.out.println("[CONNECTED] Wire: " + wireId);
        }

        @Override
        public void onDisconnected(String wireId, String reason) {
            System.out.println("[DISCONNECTED] Wire: " + wireId + " Reason: " + reason);
        }

        @Override
        public void onError(String errorCode, String message) {
            System.err.println("[ERROR] " + errorCode + ": " + message);
        }

        private void handleAssetEvent(MatrixEvent event) {
            AssetPayload asset = event.getPayloadAs(AssetPayload.class);
            if (asset == null) return;

            switch (asset.getType()) {
                case READY:
                    System.out.println("  Asset ready: " + asset.getAssetId());
                    System.out.println("  Size: " + asset.getTotalSize() + " bytes");
                    System.out.println("  From cache: " + (asset.isFromCache() ? "yes" : "no"));
                    break;

                case DATA:
                    System.out.println("  Asset data chunk: " + asset.getAssetId());
                    System.out.println("  Chunk: " + asset.getChunkIndex() + "/" + asset.getTotalChunks());
                    if (event.getData() != null) {
                        System.out.println("  Data size: " + event.getData().length + " bytes");
                    }
                    break;

                case ERROR:
                    System.err.println("  Asset error: " + asset.getErrorCode());
                    System.err.println("  Message: " + asset.getErrorMessage());
                    break;

                default:
                    break;
            }
        }

        private void handleStateEvent(MatrixEvent event) {
            StatePayload state = event.getPayloadAs(StatePayload.class);
            if (state == null) return;

            switch (state.getType()) {
                case SNAPSHOT:
                    System.out.println("  State snapshot: " + state.getSceneId());
                    System.out.println("  Tick: " + state.getTick());
                    System.out.println("  Nodes: " + state.getNodeCount());
                    break;

                case DELTA:
                    System.out.println("  State delta: " + state.getSceneId());
                    System.out.println("  Tick: " + state.getTick());
                    System.out.println("  Changes: " + state.getChangeCount());
                    break;

                case CORRECT:
                    System.out.println("  State correction for node: " + state.getCorrectedNodeId());
                    break;

                default:
                    break;
            }
        }

        private void handleRpcEvent(MatrixEvent event) {
            RpcPayload rpc = event.getPayloadAs(RpcPayload.class);
            if (rpc == null) return;

            if (rpc.getType() == RpcEventType.RESULT) {
                System.out.println("  RPC result: " + rpc.getRequestId());
                System.out.println("  Success: " + (rpc.isSuccess() ? "yes" : "no"));
                System.out.println("  Duration: " + rpc.getDurationMs() + "ms");
            } else if (rpc.getType() == RpcEventType.ERROR) {
                System.err.println("  RPC error: " + rpc.getErrorCode());
            }
        }

        private void handleControlEvent(MatrixEvent event) {
            ControlPayload control = event.getPayloadAs(ControlPayload.class);
            if (control == null) return;

            if (control.getType() == ControlEventType.PONG) {
                System.out.println("  Pong received, latency: " + control.getMeasuredLatencyMs() + "ms");
            }
        }
    }
}