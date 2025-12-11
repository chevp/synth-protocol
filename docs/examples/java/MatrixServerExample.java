// =============================================================================
// SYNTH MATRIX WIRE - Java Server Example
// =============================================================================
//
// This example demonstrates how to implement a Matrix Wire server in Java.
// The server acts as a RELAIS between clients and backends.
//
// Build:
//   javac -cp synth-wire.jar:grpc-netty.jar MatrixServerExample.java
//   java -cp .:synth-wire.jar:grpc-netty.jar MatrixServerExample
//
// =============================================================================

package io.synth.protocol.wire.example;

import io.synth.protocol.wire.*;
import io.grpc.*;
import io.grpc.stub.StreamObserver;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.*;

public class MatrixServerExample {

    private final int port;
    private Server grpcServer;
    private final MatrixWireService service;

    public MatrixServerExample(int port) {
        this.port = port;
        this.service = new MatrixWireService();
    }

    public void start() throws IOException {
        grpcServer = ServerBuilder.forPort(port)
            .addService(service)
            .build()
            .start();

        System.out.println("=== Synth Matrix Wire Server ===");
        System.out.println("Listening on port " + port);

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("Shutting down server...");
            MatrixServerExample.this.stop();
        }));
    }

    public void stop() {
        if (grpcServer != null) {
            grpcServer.shutdown();
        }
    }

    public void blockUntilShutdown() throws InterruptedException {
        if (grpcServer != null) {
            grpcServer.awaitTermination();
        }
    }

    public static void main(String[] args) throws Exception {
        MatrixServerExample server = new MatrixServerExample(50051);
        server.start();
        server.blockUntilShutdown();
    }

    // ==========================================================================
    // MATRIX WIRE SERVICE IMPLEMENTATION
    // ==========================================================================

    static class MatrixWireService extends SynthWireGrpc.SynthWireImplBase {

        private final BackendRouter backendRouter;
        private final Map<String, Session> sessions = new ConcurrentHashMap<>();
        private final Map<String, Set<StreamObserver<MatrixEvent>>> subscriptions = new ConcurrentHashMap<>();

        public MatrixWireService() {
            this.backendRouter = new BackendRouter();
        }

        // ======================================================================
        // BIDIRECTIONAL STREAMING (Main channel)
        // ======================================================================

        @Override
        public StreamObserver<MatrixEvent> exchange(StreamObserver<MatrixEvent> responseObserver) {
            String sessionId = MatrixUtil.generateEventId();
            Session session = new Session(sessionId, responseObserver);
            sessions.put(sessionId, session);

            System.out.println("[SESSION] New connection: " + sessionId);

            return new StreamObserver<MatrixEvent>() {
                @Override
                public void onNext(MatrixEvent event) {
                    handleEvent(session, event, responseObserver);
                }

                @Override
                public void onError(Throwable t) {
                    System.err.println("[SESSION] Error: " + t.getMessage());
                    sessions.remove(sessionId);
                }

                @Override
                public void onCompleted() {
                    System.out.println("[SESSION] Closed: " + sessionId);
                    sessions.remove(sessionId);
                    responseObserver.onCompleted();
                }
            };
        }

        // ======================================================================
        // UNARY RPC
        // ======================================================================

        @Override
        public void call(MatrixEvent request, StreamObserver<MatrixEvent> responseObserver) {
            System.out.println("[CALL] " + request.getHeader().getUri());

            MatrixEvent response = processEvent(null, request);
            responseObserver.onNext(response);
            responseObserver.onCompleted();
        }

        // ======================================================================
        // SERVER STREAMING (Subscribe)
        // ======================================================================

        @Override
        public void subscribe(SubscribeRequest request, StreamObserver<MatrixEvent> responseObserver) {
            String subscriptionId = MatrixUtil.generateEventId();
            System.out.println("[SUBSCRIBE] " + subscriptionId + " patterns: " + request.getPatternsList());

            for (String pattern : request.getPatternsList()) {
                subscriptions.computeIfAbsent(pattern, k -> ConcurrentHashMap.newKeySet())
                    .add(responseObserver);
            }

            // Keep stream open until client cancels
        }

        // ======================================================================
        // EVENT HANDLING
        // ======================================================================

        private void handleEvent(Session session, MatrixEvent event,
                                StreamObserver<MatrixEvent> responseObserver) {
            System.out.println("[EVENT] " + event.getHeader().getUri());

            MatrixEvent response = processEvent(session, event);
            if (response != null) {
                responseObserver.onNext(response);
            }
        }

        private MatrixEvent processEvent(Session session, MatrixEvent event) {
            switch (event.getPayloadType()) {
                case ASSET:
                    return handleAssetEvent(event);
                case STATE:
                    return handleStateEvent(session, event);
                case RPC:
                    return handleRpcEvent(event);
                case CONTROL:
                    return handleControlEvent(event);
                default:
                    return createErrorResponse(event, "UNKNOWN_PAYLOAD", "Unknown payload type");
            }
        }

        // ======================================================================
        // ASSET HANDLING
        // ======================================================================

        private MatrixEvent handleAssetEvent(MatrixEvent event) {
            AssetPayload asset = event.getPayloadAs(AssetPayload.class);
            if (asset == null) {
                return createErrorResponse(event, "INVALID_PAYLOAD", "Missing asset payload");
            }

            switch (asset.getType()) {
                case LOAD:
                    return handleAssetLoad(event, asset);
                case RESOLVE:
                    return handleAssetResolve(event, asset);
                default:
                    return createErrorResponse(event, "UNSUPPORTED_ASSET_TYPE",
                        "Unsupported asset type: " + asset.getType());
            }
        }

        private MatrixEvent handleAssetLoad(MatrixEvent event, AssetPayload request) {
            String assetId = request.getAssetId();
            System.out.println("  Loading asset: " + assetId);

            // RELAIS PATTERN: Server decides which backend to use
            // Client doesn't know if we use FTP, MySQL, S3, etc.
            BackendResult result = backendRouter.loadAsset(assetId);

            if (result.isSuccess()) {
                // Send asset data back
                MatrixEvent response = new MatrixEvent();
                response.setPayloadType(PayloadType.ASSET);

                AssetPayload responsePayload = new AssetPayload();
                responsePayload.setAssetId(assetId);
                responsePayload.setType(AssetEventType.READY);
                responsePayload.setTotalSize(result.getData().length);
                responsePayload.setContentType(result.getContentType());
                responsePayload.setTotalChecksum(MatrixUtil.computeChecksum(result.getData()));
                responsePayload.setFromCache(result.isFromCache());
                responsePayload.setDurationMs(result.getDurationMs());
                response.setPayload(responsePayload);

                response.setData(result.getData());
                response.getHeader().setUri("synth://asset/ready#" + assetId);
                response.getHeader().setEventId(MatrixUtil.generateEventId());
                response.getHeader().setCorrelationId(event.getHeader().getEventId());
                response.getHeader().setTimestamp(System.currentTimeMillis());

                return response;
            } else {
                return createAssetError(event, assetId, result.getErrorCode(), result.getErrorMessage());
            }
        }

        private MatrixEvent handleAssetResolve(MatrixEvent event, AssetPayload request) {
            String assetId = request.getAssetId();
            System.out.println("  Resolving asset: " + assetId);

            // Resolve asset ID to URI (without loading the actual data)
            String uri = backendRouter.resolveAsset(assetId);

            MatrixEvent response = new MatrixEvent();
            response.setPayloadType(PayloadType.RPC);

            RpcPayload rpc = new RpcPayload();
            rpc.setRequestId(event.getPayloadAs(RpcPayload.class) != null
                ? event.getPayloadAs(RpcPayload.class).getRequestId()
                : event.getHeader().getEventId());
            rpc.setType(RpcEventType.RESULT);
            rpc.setSuccess(uri != null);
            response.setPayload(rpc);

            if (uri != null) {
                response.setData(uri.getBytes());
            }

            response.getHeader().setUri("synth://rpc/result");
            response.getHeader().setEventId(MatrixUtil.generateEventId());
            response.getHeader().setCorrelationId(event.getHeader().getEventId());
            response.getHeader().setTimestamp(System.currentTimeMillis());

            return response;
        }

        private MatrixEvent createAssetError(MatrixEvent event, String assetId,
                                             String errorCode, String errorMessage) {
            MatrixEvent response = new MatrixEvent();
            response.setPayloadType(PayloadType.ASSET);

            AssetPayload payload = new AssetPayload();
            payload.setAssetId(assetId);
            payload.setType(AssetEventType.ERROR);
            payload.setErrorCode(errorCode);
            payload.setErrorMessage(errorMessage);
            payload.setRetriable(true);
            response.setPayload(payload);

            response.getHeader().setUri("synth://asset/error#" + assetId);
            response.getHeader().setEventId(MatrixUtil.generateEventId());
            response.getHeader().setCorrelationId(event.getHeader().getEventId());
            response.getHeader().setTimestamp(System.currentTimeMillis());

            return response;
        }

        // ======================================================================
        // STATE HANDLING
        // ======================================================================

        private MatrixEvent handleStateEvent(Session session, MatrixEvent event) {
            StatePayload state = event.getPayloadAs(StatePayload.class);
            if (state == null) {
                return createErrorResponse(event, "INVALID_PAYLOAD", "Missing state payload");
            }

            switch (state.getType()) {
                case SNAPSHOT_REQUEST:
                    return handleSnapshotRequest(event, state);
                case INPUT:
                    return handleStateInput(session, event, state);
                default:
                    return null;  // No response needed for deltas
            }
        }

        private MatrixEvent handleSnapshotRequest(MatrixEvent event, StatePayload request) {
            String sceneId = request.getSceneId();
            System.out.println("  Snapshot request for scene: " + sceneId);

            // Load scene state from backend
            byte[] snapshotData = backendRouter.loadSceneSnapshot(sceneId);

            MatrixEvent response = new MatrixEvent();
            response.setPayloadType(PayloadType.STATE);

            StatePayload payload = new StatePayload();
            payload.setSceneId(sceneId);
            payload.setType(StateEventType.SNAPSHOT);
            payload.setTick(System.currentTimeMillis());
            payload.setNodeCount(100);  // Example
            payload.setUncompressedSize(snapshotData.length);
            response.setPayload(payload);

            response.setData(snapshotData);
            response.getHeader().setUri("synth://state/" + sceneId + "/snapshot");
            response.getHeader().setEventId(MatrixUtil.generateEventId());
            response.getHeader().setCorrelationId(event.getHeader().getEventId());
            response.getHeader().setTimestamp(System.currentTimeMillis());

            return response;
        }

        private MatrixEvent handleStateInput(Session session, MatrixEvent event, StatePayload input) {
            String sceneId = input.getSceneId();
            String nodeId = input.getTargetNodeId();
            System.out.println("  Input for node " + nodeId + " in scene " + sceneId);

            // Process input and potentially send correction
            boolean needsCorrection = validateAndApplyInput(sceneId, nodeId, event.getData());

            if (needsCorrection) {
                MatrixEvent correction = new MatrixEvent();
                correction.setPayloadType(PayloadType.STATE);

                StatePayload payload = new StatePayload();
                payload.setSceneId(sceneId);
                payload.setType(StateEventType.CORRECT);
                payload.setTick(System.currentTimeMillis());
                payload.setCorrectedNodeId(nodeId);
                payload.setCorrectedField("position");
                correction.setPayload(payload);

                // Corrected value
                correction.setData("{\"position\": [10.0, 0.0, 5.0]}".getBytes());
                correction.getHeader().setUri("synth://state/" + sceneId + "/correct");
                correction.getHeader().setEventId(MatrixUtil.generateEventId());
                correction.getHeader().setTimestamp(System.currentTimeMillis());

                return correction;
            }

            // Acknowledge input
            MatrixEvent ack = new MatrixEvent();
            ack.setPayloadType(PayloadType.STATE);

            StatePayload payload = new StatePayload();
            payload.setSceneId(sceneId);
            payload.setType(StateEventType.ACK);
            payload.setAckTick(System.currentTimeMillis());
            payload.setAckInputs(Arrays.asList(input.getInputSequence()));
            ack.setPayload(payload);

            ack.getHeader().setUri("synth://state/" + sceneId + "/ack");
            ack.getHeader().setEventId(MatrixUtil.generateEventId());
            ack.getHeader().setTimestamp(System.currentTimeMillis());

            return ack;
        }

        private boolean validateAndApplyInput(String sceneId, String nodeId, byte[] inputData) {
            // Server-side validation - returns true if correction needed
            return false;
        }

        // ======================================================================
        // RPC HANDLING
        // ======================================================================

        private MatrixEvent handleRpcEvent(MatrixEvent event) {
            RpcPayload rpc = event.getPayloadAs(RpcPayload.class);
            if (rpc == null || rpc.getType() != RpcEventType.CALL) {
                return createErrorResponse(event, "INVALID_RPC", "Invalid RPC request");
            }

            String method = rpc.getMethod();
            System.out.println("  RPC call: " + method);

            long startTime = System.currentTimeMillis();

            // Route to appropriate handler
            Object result;
            try {
                result = executeRpcMethod(method, event.getData());
            } catch (Exception e) {
                return createRpcError(event, rpc.getRequestId(), "EXECUTION_ERROR", e.getMessage());
            }

            long duration = System.currentTimeMillis() - startTime;

            // Create response
            MatrixEvent response = new MatrixEvent();
            response.setPayloadType(PayloadType.RPC);

            RpcPayload responsePayload = new RpcPayload();
            responsePayload.setRequestId(rpc.getRequestId());
            responsePayload.setType(RpcEventType.RESULT);
            responsePayload.setSuccess(true);
            responsePayload.setDurationMs(duration);
            response.setPayload(responsePayload);

            if (result instanceof byte[]) {
                response.setData((byte[]) result);
            } else if (result != null) {
                response.setData(result.toString().getBytes());
            }

            response.getHeader().setUri("synth://rpc/result#" + method);
            response.getHeader().setEventId(MatrixUtil.generateEventId());
            response.getHeader().setCorrelationId(event.getHeader().getEventId());
            response.getHeader().setTimestamp(System.currentTimeMillis());

            return response;
        }

        private Object executeRpcMethod(String method, byte[] args) throws Exception {
            switch (method) {
                case "asset/resolve":
                    return backendRouter.resolveAsset(parseAssetId(args));
                case "asset/list":
                    return backendRouter.listAssets();
                case "scene/list":
                    return backendRouter.listScenes();
                default:
                    throw new IllegalArgumentException("Unknown method: " + method);
            }
        }

        private String parseAssetId(byte[] args) {
            // Parse JSON to extract asset ID
            String json = new String(args);
            // Simplified - use proper JSON parsing
            int start = json.indexOf("\"id\"") + 6;
            int end = json.indexOf("\"", start);
            return json.substring(start, end);
        }

        private MatrixEvent createRpcError(MatrixEvent event, String requestId,
                                          String errorCode, String errorMessage) {
            MatrixEvent response = new MatrixEvent();
            response.setPayloadType(PayloadType.RPC);

            RpcPayload payload = new RpcPayload();
            payload.setRequestId(requestId);
            payload.setType(RpcEventType.ERROR);
            payload.setErrorCode(errorCode);
            payload.setErrorMessage(errorMessage);
            payload.setRetriable(true);
            response.setPayload(payload);

            response.getHeader().setUri("synth://rpc/error");
            response.getHeader().setEventId(MatrixUtil.generateEventId());
            response.getHeader().setCorrelationId(event.getHeader().getEventId());
            response.getHeader().setTimestamp(System.currentTimeMillis());

            return response;
        }

        // ======================================================================
        // CONTROL HANDLING
        // ======================================================================

        private MatrixEvent handleControlEvent(MatrixEvent event) {
            ControlPayload control = event.getPayloadAs(ControlPayload.class);
            if (control == null) {
                return createErrorResponse(event, "INVALID_CONTROL", "Missing control payload");
            }

            switch (control.getType()) {
                case PING:
                    return MatrixEvent.createPong(control.getPingTimestamp());
                case WIRE_DISCOVER:
                    return handleWireDiscover(event);
                default:
                    return null;
            }
        }

        private MatrixEvent handleWireDiscover(MatrixEvent event) {
            // Return available wires
            MatrixEvent response = new MatrixEvent();
            response.setPayloadType(PayloadType.CONTROL);

            ControlPayload payload = new ControlPayload();
            payload.setType(ControlEventType.WIRE_AVAILABLE);
            payload.setWireId("grpc_main");
            payload.setWireUrl("grpc://localhost:50051");
            payload.setLatencyHintMs(5);
            payload.setBandwidthHintKbps(100000);
            response.setPayload(payload);

            response.getHeader().setUri("synth://control/wire_available");
            response.getHeader().setEventId(MatrixUtil.generateEventId());
            response.getHeader().setCorrelationId(event.getHeader().getEventId());
            response.getHeader().setTimestamp(System.currentTimeMillis());

            return response;
        }

        // ======================================================================
        // HELPERS
        // ======================================================================

        private MatrixEvent createErrorResponse(MatrixEvent event, String errorCode, String message) {
            MatrixEvent response = new MatrixEvent();
            response.setPayloadType(PayloadType.RPC);

            RpcPayload payload = new RpcPayload();
            payload.setType(RpcEventType.ERROR);
            payload.setErrorCode(errorCode);
            payload.setErrorMessage(message);
            response.setPayload(payload);

            response.getHeader().setUri("synth://error");
            response.getHeader().setEventId(MatrixUtil.generateEventId());
            response.getHeader().setCorrelationId(event.getHeader().getEventId());
            response.getHeader().setTimestamp(System.currentTimeMillis());

            return response;
        }
    }

    // ==========================================================================
    // SESSION
    // ==========================================================================

    static class Session {
        private final String sessionId;
        private final StreamObserver<MatrixEvent> responseObserver;
        private final Set<String> subscriptions = ConcurrentHashMap.newKeySet();

        public Session(String sessionId, StreamObserver<MatrixEvent> responseObserver) {
            this.sessionId = sessionId;
            this.responseObserver = responseObserver;
        }

        public String getSessionId() { return sessionId; }

        public void send(MatrixEvent event) {
            responseObserver.onNext(event);
        }

        public void subscribe(String pattern) {
            subscriptions.add(pattern);
        }
    }

    // ==========================================================================
    // BACKEND ROUTER (RELAIS PATTERN)
    // ==========================================================================

    static class BackendRouter {
        // In real implementation, these would be actual backend connections
        // Server decides which backend to use - client doesn't know

        public BackendResult loadAsset(String assetId) {
            System.out.println("    [BACKEND] Loading from backend: " + assetId);

            // Simulate loading from backend (FTP, MySQL, S3, etc.)
            // Client doesn't know which backend is used!
            long startTime = System.currentTimeMillis();

            // Example: Load PNG texture
            byte[] data = generateSamplePngData();

            return new BackendResult(
                true,
                data,
                "image/png",
                false,  // not from cache
                System.currentTimeMillis() - startTime
            );
        }

        public String resolveAsset(String assetId) {
            // Resolve to internal URI
            return "synth://assets/textures/" + assetId + ".png";
        }

        public byte[] loadSceneSnapshot(String sceneId) {
            // Load scene state
            return "{\"nodes\": [], \"tick\": 0}".getBytes();
        }

        public String listAssets() {
            return "[\"car_model\", \"car_texture\", \"wheel_model\"]";
        }

        public String listScenes() {
            return "[\"scene_001\", \"scene_002\"]";
        }

        private byte[] generateSamplePngData() {
            // Return minimal PNG for example
            return new byte[] {
                (byte)0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  // PNG signature
                0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,        // IHDR chunk
                // ... simplified
            };
        }
    }

    static class BackendResult {
        private final boolean success;
        private final byte[] data;
        private final String contentType;
        private final boolean fromCache;
        private final long durationMs;
        private String errorCode;
        private String errorMessage;

        public BackendResult(boolean success, byte[] data, String contentType,
                           boolean fromCache, long durationMs) {
            this.success = success;
            this.data = data;
            this.contentType = contentType;
            this.fromCache = fromCache;
            this.durationMs = durationMs;
        }

        public static BackendResult error(String errorCode, String errorMessage) {
            BackendResult result = new BackendResult(false, null, null, false, 0);
            result.errorCode = errorCode;
            result.errorMessage = errorMessage;
            return result;
        }

        public boolean isSuccess() { return success; }
        public byte[] getData() { return data; }
        public String getContentType() { return contentType; }
        public boolean isFromCache() { return fromCache; }
        public long getDurationMs() { return durationMs; }
        public String getErrorCode() { return errorCode; }
        public String getErrorMessage() { return errorMessage; }
    }
}