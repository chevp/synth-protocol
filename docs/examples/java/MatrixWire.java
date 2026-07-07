// =============================================================================
// SYNTH MATRIX WIRE - Java Interface
// =============================================================================
//
// This file defines the Java interface for the Synth Matrix Wire protocol.
// Package: io.synth.protocol.wire
//
// =============================================================================

package io.synth.protocol.wire;

import java.nio.ByteBuffer;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.time.Duration;

// =============================================================================
// ENUMS
// =============================================================================

public enum PayloadType {
    UNSPECIFIED(0),
    ASSET(1),
    STATE(2),
    RPC(3),
    BINARY(4),
    CONTROL(5);

    private final int value;
    PayloadType(int value) { this.value = value; }
    public int getValue() { return value; }
}

public enum Compression {
    NONE(0),
    ZSTD(1),
    LZ4(2),
    GZIP(3);

    private final int value;
    Compression(int value) { this.value = value; }
    public int getValue() { return value; }
}

public enum AssetEventType {
    UNSPECIFIED(0),
    LOAD(1),
    RESOLVE(2),
    DATA(3),
    READY(4),
    ERROR(5),
    EVICT(6);

    private final int value;
    AssetEventType(int value) { this.value = value; }
    public int getValue() { return value; }
}

public enum StateEventType {
    UNSPECIFIED(0),
    SNAPSHOT_REQUEST(1),
    SNAPSHOT(2),
    DELTA(3),
    INPUT(4),
    CORRECT(5),
    ACK(6);

    private final int value;
    StateEventType(int value) { this.value = value; }
    public int getValue() { return value; }
}

public enum RpcEventType {
    UNSPECIFIED(0),
    CALL(1),
    RESULT(2),
    ERROR(3),
    STREAM_START(4),
    STREAM_DATA(5),
    STREAM_END(6);

    private final int value;
    RpcEventType(int value) { this.value = value; }
    public int getValue() { return value; }
}

public enum ControlEventType {
    UNSPECIFIED(0),
    PING(1),
    PONG(2),
    WIRE_DISCOVER(3),
    WIRE_AVAILABLE(4),
    WIRE_SELECT(5),
    WIRE_CONNECT(6),
    WIRE_FAIL(7),
    WIRE_FALLBACK(8);

    private final int value;
    ControlEventType(int value) { this.value = value; }
    public int getValue() { return value; }
}

// =============================================================================
// MATRIX HEADER
// =============================================================================

public class MatrixHeader {
    private String eventId;
    private String uri;
    private long timestamp;
    private String sourceId;
    private String sourceType;
    private String wireId;
    private String correlationId;
    private String streamId;
    private int streamSequence;
    private Compression compression = Compression.NONE;
    private int flags;
    private int binaryLength;
    private String binaryChecksum;
    private String binaryContentType;

    // Flag constants
    public static final int FLAG_HAS_BINARY = 0x01;
    public static final int FLAG_COMPRESSED = 0x02;
    public static final int FLAG_END_STREAM = 0x04;
    public static final int FLAG_REQUIRES_ACK = 0x08;
    public static final int FLAG_ENCRYPTED = 0x10;
    public static final int FLAG_CHUNKED = 0x20;

    // Getters and setters
    public String getEventId() { return eventId; }
    public void setEventId(String eventId) { this.eventId = eventId; }

    public String getUri() { return uri; }
    public void setUri(String uri) { this.uri = uri; }

    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }

    public String getSourceId() { return sourceId; }
    public void setSourceId(String sourceId) { this.sourceId = sourceId; }

    public String getSourceType() { return sourceType; }
    public void setSourceType(String sourceType) { this.sourceType = sourceType; }

    public String getWireId() { return wireId; }
    public void setWireId(String wireId) { this.wireId = wireId; }

    public String getCorrelationId() { return correlationId; }
    public void setCorrelationId(String correlationId) { this.correlationId = correlationId; }

    public String getStreamId() { return streamId; }
    public void setStreamId(String streamId) { this.streamId = streamId; }

    public int getStreamSequence() { return streamSequence; }
    public void setStreamSequence(int streamSequence) { this.streamSequence = streamSequence; }

    public Compression getCompression() { return compression; }
    public void setCompression(Compression compression) { this.compression = compression; }

    public int getFlags() { return flags; }
    public void setFlags(int flags) { this.flags = flags; }

    public int getBinaryLength() { return binaryLength; }
    public void setBinaryLength(int binaryLength) { this.binaryLength = binaryLength; }

    public String getBinaryChecksum() { return binaryChecksum; }
    public void setBinaryChecksum(String binaryChecksum) { this.binaryChecksum = binaryChecksum; }

    public String getBinaryContentType() { return binaryContentType; }
    public void setBinaryContentType(String binaryContentType) { this.binaryContentType = binaryContentType; }

    // Flag helpers
    public boolean hasBinary() { return (flags & FLAG_HAS_BINARY) != 0; }
    public boolean isCompressed() { return (flags & FLAG_COMPRESSED) != 0; }
    public boolean isEndStream() { return (flags & FLAG_END_STREAM) != 0; }
    public boolean requiresAck() { return (flags & FLAG_REQUIRES_ACK) != 0; }
    public boolean isEncrypted() { return (flags & FLAG_ENCRYPTED) != 0; }
    public boolean isChunked() { return (flags & FLAG_CHUNKED) != 0; }

    public void setHasBinary(boolean value) {
        if (value) flags |= FLAG_HAS_BINARY;
        else flags &= ~FLAG_HAS_BINARY;
    }
}

// =============================================================================
// PAYLOAD INTERFACES
// =============================================================================

public interface MatrixPayload {
    PayloadType getPayloadType();
}

// =============================================================================
// ASSET PAYLOAD
// =============================================================================

public class AssetPayload implements MatrixPayload {
    private String assetId;
    private AssetEventType type = AssetEventType.UNSPECIFIED;
    private int priority = 2;  // Normal
    private boolean includeMetadata;

    // Chunked transfer
    private int chunkIndex;
    private int totalChunks;
    private boolean finalChunk;

    // Metadata
    private String filename;
    private String contentType;
    private long totalSize;
    private String totalChecksum;

    // Result
    private String resolvedUri;
    private long durationMs;
    private boolean fromCache;

    // Error
    private String errorCode;
    private String errorMessage;
    private boolean retriable;

    @Override
    public PayloadType getPayloadType() { return PayloadType.ASSET; }

    // Getters and setters
    public String getAssetId() { return assetId; }
    public void setAssetId(String assetId) { this.assetId = assetId; }

    public AssetEventType getType() { return type; }
    public void setType(AssetEventType type) { this.type = type; }

    public int getPriority() { return priority; }
    public void setPriority(int priority) { this.priority = priority; }

    public boolean isIncludeMetadata() { return includeMetadata; }
    public void setIncludeMetadata(boolean includeMetadata) { this.includeMetadata = includeMetadata; }

    public int getChunkIndex() { return chunkIndex; }
    public void setChunkIndex(int chunkIndex) { this.chunkIndex = chunkIndex; }

    public int getTotalChunks() { return totalChunks; }
    public void setTotalChunks(int totalChunks) { this.totalChunks = totalChunks; }

    public boolean isFinalChunk() { return finalChunk; }
    public void setFinalChunk(boolean finalChunk) { this.finalChunk = finalChunk; }

    public String getFilename() { return filename; }
    public void setFilename(String filename) { this.filename = filename; }

    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }

    public long getTotalSize() { return totalSize; }
    public void setTotalSize(long totalSize) { this.totalSize = totalSize; }

    public String getTotalChecksum() { return totalChecksum; }
    public void setTotalChecksum(String totalChecksum) { this.totalChecksum = totalChecksum; }

    public String getResolvedUri() { return resolvedUri; }
    public void setResolvedUri(String resolvedUri) { this.resolvedUri = resolvedUri; }

    public long getDurationMs() { return durationMs; }
    public void setDurationMs(long durationMs) { this.durationMs = durationMs; }

    public boolean isFromCache() { return fromCache; }
    public void setFromCache(boolean fromCache) { this.fromCache = fromCache; }

    public String getErrorCode() { return errorCode; }
    public void setErrorCode(String errorCode) { this.errorCode = errorCode; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    public boolean isRetriable() { return retriable; }
    public void setRetriable(boolean retriable) { this.retriable = retriable; }
}

// =============================================================================
// STATE PAYLOAD
// =============================================================================

public class StatePayload implements MatrixPayload {
    private String sceneId;
    private StateEventType type = StateEventType.UNSPECIFIED;
    private long tick;

    // Snapshot
    private int nodeCount;
    private long uncompressedSize;

    // Delta
    private int changeCount;

    // Input
    private int inputSequence;
    private String inputType;
    private String targetNodeId;

    // Correction
    private String correctedNodeId;
    private String correctedField;

    // Ack
    private long ackTick;
    private List<Integer> ackInputs;

    @Override
    public PayloadType getPayloadType() { return PayloadType.STATE; }

    // Getters and setters
    public String getSceneId() { return sceneId; }
    public void setSceneId(String sceneId) { this.sceneId = sceneId; }

    public StateEventType getType() { return type; }
    public void setType(StateEventType type) { this.type = type; }

    public long getTick() { return tick; }
    public void setTick(long tick) { this.tick = tick; }

    public int getNodeCount() { return nodeCount; }
    public void setNodeCount(int nodeCount) { this.nodeCount = nodeCount; }

    public long getUncompressedSize() { return uncompressedSize; }
    public void setUncompressedSize(long uncompressedSize) { this.uncompressedSize = uncompressedSize; }

    public int getChangeCount() { return changeCount; }
    public void setChangeCount(int changeCount) { this.changeCount = changeCount; }

    public int getInputSequence() { return inputSequence; }
    public void setInputSequence(int inputSequence) { this.inputSequence = inputSequence; }

    public String getInputType() { return inputType; }
    public void setInputType(String inputType) { this.inputType = inputType; }

    public String getTargetNodeId() { return targetNodeId; }
    public void setTargetNodeId(String targetNodeId) { this.targetNodeId = targetNodeId; }

    public String getCorrectedNodeId() { return correctedNodeId; }
    public void setCorrectedNodeId(String correctedNodeId) { this.correctedNodeId = correctedNodeId; }

    public String getCorrectedField() { return correctedField; }
    public void setCorrectedField(String correctedField) { this.correctedField = correctedField; }

    public long getAckTick() { return ackTick; }
    public void setAckTick(long ackTick) { this.ackTick = ackTick; }

    public List<Integer> getAckInputs() { return ackInputs; }
    public void setAckInputs(List<Integer> ackInputs) { this.ackInputs = ackInputs; }
}

// =============================================================================
// RPC PAYLOAD
// =============================================================================

public class RpcPayload implements MatrixPayload {
    private String requestId;
    private RpcEventType type = RpcEventType.UNSPECIFIED;

    // Call
    private String method;

    // Result
    private boolean success;
    private long durationMs;
    private int itemCount;

    // Error
    private String errorCode;
    private String errorMessage;
    private boolean retriable;

    // Stream
    private int streamSequence;
    private int totalChunks;
    private boolean isFinal;

    @Override
    public PayloadType getPayloadType() { return PayloadType.RPC; }

    // Getters and setters
    public String getRequestId() { return requestId; }
    public void setRequestId(String requestId) { this.requestId = requestId; }

    public RpcEventType getType() { return type; }
    public void setType(RpcEventType type) { this.type = type; }

    public String getMethod() { return method; }
    public void setMethod(String method) { this.method = method; }

    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public long getDurationMs() { return durationMs; }
    public void setDurationMs(long durationMs) { this.durationMs = durationMs; }

    public int getItemCount() { return itemCount; }
    public void setItemCount(int itemCount) { this.itemCount = itemCount; }

    public String getErrorCode() { return errorCode; }
    public void setErrorCode(String errorCode) { this.errorCode = errorCode; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    public boolean isRetriable() { return retriable; }
    public void setRetriable(boolean retriable) { this.retriable = retriable; }

    public int getStreamSequence() { return streamSequence; }
    public void setStreamSequence(int streamSequence) { this.streamSequence = streamSequence; }

    public int getTotalChunks() { return totalChunks; }
    public void setTotalChunks(int totalChunks) { this.totalChunks = totalChunks; }

    public boolean isFinal() { return isFinal; }
    public void setFinal(boolean isFinal) { this.isFinal = isFinal; }
}

// =============================================================================
// CONTROL PAYLOAD
// =============================================================================

public class ControlPayload implements MatrixPayload {
    private ControlEventType type = ControlEventType.UNSPECIFIED;

    // Ping/Pong
    private long pingTimestamp;
    private long pongTimestamp;
    private int measuredLatencyMs;

    // Wire
    private String wireId;
    private String wireUrl;
    private String wireStatus;
    private int latencyHintMs;
    private int bandwidthHintKbps;

    // Fallback
    private String fallbackTo;
    private String fallbackReason;

    // Reconnect
    private int attempt;
    private int maxAttempts;
    private int backoffMs;

    @Override
    public PayloadType getPayloadType() { return PayloadType.CONTROL; }

    // Getters and setters
    public ControlEventType getType() { return type; }
    public void setType(ControlEventType type) { this.type = type; }

    public long getPingTimestamp() { return pingTimestamp; }
    public void setPingTimestamp(long pingTimestamp) { this.pingTimestamp = pingTimestamp; }

    public long getPongTimestamp() { return pongTimestamp; }
    public void setPongTimestamp(long pongTimestamp) { this.pongTimestamp = pongTimestamp; }

    public int getMeasuredLatencyMs() { return measuredLatencyMs; }
    public void setMeasuredLatencyMs(int measuredLatencyMs) { this.measuredLatencyMs = measuredLatencyMs; }

    public String getWireId() { return wireId; }
    public void setWireId(String wireId) { this.wireId = wireId; }

    public String getWireUrl() { return wireUrl; }
    public void setWireUrl(String wireUrl) { this.wireUrl = wireUrl; }

    public String getWireStatus() { return wireStatus; }
    public void setWireStatus(String wireStatus) { this.wireStatus = wireStatus; }

    public int getLatencyHintMs() { return latencyHintMs; }
    public void setLatencyHintMs(int latencyHintMs) { this.latencyHintMs = latencyHintMs; }

    public int getBandwidthHintKbps() { return bandwidthHintKbps; }
    public void setBandwidthHintKbps(int bandwidthHintKbps) { this.bandwidthHintKbps = bandwidthHintKbps; }

    public String getFallbackTo() { return fallbackTo; }
    public void setFallbackTo(String fallbackTo) { this.fallbackTo = fallbackTo; }

    public String getFallbackReason() { return fallbackReason; }
    public void setFallbackReason(String fallbackReason) { this.fallbackReason = fallbackReason; }

    public int getAttempt() { return attempt; }
    public void setAttempt(int attempt) { this.attempt = attempt; }

    public int getMaxAttempts() { return maxAttempts; }
    public void setMaxAttempts(int maxAttempts) { this.maxAttempts = maxAttempts; }

    public int getBackoffMs() { return backoffMs; }
    public void setBackoffMs(int backoffMs) { this.backoffMs = backoffMs; }
}

// =============================================================================
// MATRIX EVENT
// =============================================================================

public class MatrixEvent {
    private MatrixHeader header = new MatrixHeader();
    private PayloadType payloadType = PayloadType.UNSPECIFIED;
    private MatrixPayload payload;
    private byte[] data;  // Binary data

    // Wire format magic
    public static final int MAGIC = 0x53594E54;  // "SYNT"

    public MatrixHeader getHeader() { return header; }
    public void setHeader(MatrixHeader header) { this.header = header; }

    public PayloadType getPayloadType() { return payloadType; }
    public void setPayloadType(PayloadType payloadType) { this.payloadType = payloadType; }

    public MatrixPayload getPayload() { return payload; }
    public void setPayload(MatrixPayload payload) {
        this.payload = payload;
        if (payload != null) {
            this.payloadType = payload.getPayloadType();
        }
    }

    public byte[] getData() { return data; }
    public void setData(byte[] data) {
        this.data = data;
        if (data != null && data.length > 0) {
            header.setHasBinary(true);
            header.setBinaryLength(data.length);
        }
    }

    // Typed payload accessors
    @SuppressWarnings("unchecked")
    public <T extends MatrixPayload> T getPayloadAs(Class<T> clazz) {
        if (payload != null && clazz.isInstance(payload)) {
            return (T) payload;
        }
        return null;
    }

    // Factory methods
    public static MatrixEvent createAssetLoad(String assetId, int priority) {
        MatrixEvent event = new MatrixEvent();
        event.payloadType = PayloadType.ASSET;

        AssetPayload asset = new AssetPayload();
        asset.setAssetId(assetId);
        asset.setType(AssetEventType.LOAD);
        asset.setPriority(priority);
        event.payload = asset;

        event.header.setUri("synth://asset/load#" + assetId);
        event.header.setEventId(MatrixUtil.generateEventId());
        event.header.setTimestamp(System.currentTimeMillis());

        return event;
    }

    public static MatrixEvent createAssetData(String assetId, byte[] data,
                                               int chunkIndex, int totalChunks) {
        MatrixEvent event = new MatrixEvent();
        event.payloadType = PayloadType.ASSET;

        AssetPayload asset = new AssetPayload();
        asset.setAssetId(assetId);
        asset.setType(AssetEventType.DATA);
        asset.setChunkIndex(chunkIndex);
        asset.setTotalChunks(totalChunks);
        asset.setFinalChunk(chunkIndex == totalChunks - 1);
        event.payload = asset;

        event.setData(data);
        event.header.setUri("synth://asset/data#" + assetId);
        event.header.setEventId(MatrixUtil.generateEventId());
        event.header.setTimestamp(System.currentTimeMillis());

        return event;
    }

    public static MatrixEvent createRpcCall(String method, byte[] args) {
        MatrixEvent event = new MatrixEvent();
        event.payloadType = PayloadType.RPC;

        RpcPayload rpc = new RpcPayload();
        rpc.setRequestId(MatrixUtil.generateEventId());
        rpc.setType(RpcEventType.CALL);
        rpc.setMethod(method);
        event.payload = rpc;

        if (args != null && args.length > 0) {
            event.setData(args);
        }

        event.header.setUri("synth://rpc/call#" + method);
        event.header.setEventId(MatrixUtil.generateEventId());
        event.header.setCorrelationId(rpc.getRequestId());
        event.header.setTimestamp(System.currentTimeMillis());

        return event;
    }

    public static MatrixEvent createPing() {
        MatrixEvent event = new MatrixEvent();
        event.payloadType = PayloadType.CONTROL;

        ControlPayload control = new ControlPayload();
        control.setType(ControlEventType.PING);
        control.setPingTimestamp(System.currentTimeMillis());
        event.payload = control;

        event.header.setUri("synth://control/ping");
        event.header.setEventId(MatrixUtil.generateEventId());
        event.header.setTimestamp(System.currentTimeMillis());

        return event;
    }

    public static MatrixEvent createPong(long pingTimestamp) {
        MatrixEvent event = new MatrixEvent();
        event.payloadType = PayloadType.CONTROL;

        long now = System.currentTimeMillis();
        ControlPayload control = new ControlPayload();
        control.setType(ControlEventType.PONG);
        control.setPingTimestamp(pingTimestamp);
        control.setPongTimestamp(now);
        control.setMeasuredLatencyMs((int)(now - pingTimestamp));
        event.payload = control;

        event.header.setUri("synth://control/pong");
        event.header.setEventId(MatrixUtil.generateEventId());
        event.header.setTimestamp(now);

        return event;
    }

    // Serialization
    public byte[] serialize() {
        // Uses protobuf serialization
        // Implementation would use generated protobuf classes
        throw new UnsupportedOperationException("Use MatrixEventSerializer");
    }

    public static MatrixEvent deserialize(byte[] buffer) {
        throw new UnsupportedOperationException("Use MatrixEventSerializer");
    }

    // Wire format
    public byte[] toWireFormat() {
        // Format: [MAGIC:4][TOTAL_LEN:4][HDR_LEN:2][PLD_LEN:2][BIN_LEN:4][FLAGS:2][HEADER][PAYLOAD][BINARY]
        throw new UnsupportedOperationException("Use MatrixEventSerializer");
    }

    public static MatrixEvent fromWireFormat(byte[] buffer) {
        throw new UnsupportedOperationException("Use MatrixEventSerializer");
    }
}

// =============================================================================
// MATRIX WIRE INTERFACE
// =============================================================================

public interface MatrixHandler {
    void onEvent(MatrixEvent event);
    void onConnected(String wireId);
    void onDisconnected(String wireId, String reason);
    void onError(String errorCode, String message);
}

public interface MatrixWire extends AutoCloseable {
    // Connection lifecycle
    boolean connect();
    void disconnect();
    boolean isConnected();

    // Send events
    boolean send(MatrixEvent event);
    CompletableFuture<Boolean> sendAsync(MatrixEvent event);

    // Request/Response (RPC)
    Optional<MatrixEvent> call(MatrixEvent request, Duration timeout);
    CompletableFuture<MatrixEvent> callAsync(MatrixEvent request);

    // Streaming
    void subscribe(List<String> patterns);
    void unsubscribe(List<String> patterns);

    // Handler
    void setHandler(MatrixHandler handler);

    // Wire info
    String getWireId();
    String getWireType();
}

// =============================================================================
// WIRE CONFIGURATION
// =============================================================================

public class WireConfig {
    private String type = "grpc";  // "grpc", "websocket", "tcp", "http"
    private String url;
    private String clientId;

    // Timeouts
    private int connectTimeoutMs = 5000;
    private int requestTimeoutMs = 30000;

    // Reconnection
    private boolean autoReconnect = true;
    private int reconnectDelayMs = 1000;
    private int maxReconnectAttempts = 10;

    // Compression
    private Compression defaultCompression = Compression.NONE;

    // TLS
    private boolean useTls = false;
    private String certFile;
    private String keyFile;
    private String caFile;

    // Getters and setters
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public String getClientId() { return clientId; }
    public void setClientId(String clientId) { this.clientId = clientId; }

    public int getConnectTimeoutMs() { return connectTimeoutMs; }
    public void setConnectTimeoutMs(int connectTimeoutMs) { this.connectTimeoutMs = connectTimeoutMs; }

    public int getRequestTimeoutMs() { return requestTimeoutMs; }
    public void setRequestTimeoutMs(int requestTimeoutMs) { this.requestTimeoutMs = requestTimeoutMs; }

    public boolean isAutoReconnect() { return autoReconnect; }
    public void setAutoReconnect(boolean autoReconnect) { this.autoReconnect = autoReconnect; }

    public int getReconnectDelayMs() { return reconnectDelayMs; }
    public void setReconnectDelayMs(int reconnectDelayMs) { this.reconnectDelayMs = reconnectDelayMs; }

    public int getMaxReconnectAttempts() { return maxReconnectAttempts; }
    public void setMaxReconnectAttempts(int maxReconnectAttempts) { this.maxReconnectAttempts = maxReconnectAttempts; }

    public Compression getDefaultCompression() { return defaultCompression; }
    public void setDefaultCompression(Compression defaultCompression) { this.defaultCompression = defaultCompression; }

    public boolean isUseTls() { return useTls; }
    public void setUseTls(boolean useTls) { this.useTls = useTls; }

    public String getCertFile() { return certFile; }
    public void setCertFile(String certFile) { this.certFile = certFile; }

    public String getKeyFile() { return keyFile; }
    public void setKeyFile(String keyFile) { this.keyFile = keyFile; }

    public String getCaFile() { return caFile; }
    public void setCaFile(String caFile) { this.caFile = caFile; }
}

// =============================================================================
// WIRE FACTORY
// =============================================================================

public class MatrixWireFactory {
    public static MatrixWire create(WireConfig config) {
        switch (config.getType().toLowerCase()) {
            case "grpc":
                return new GrpcMatrixWire(config);
            case "websocket":
                return new WebSocketMatrixWire(config);
            case "tcp":
                return new TcpMatrixWire(config);
            default:
                throw new IllegalArgumentException("Unknown wire type: " + config.getType());
        }
    }

    public static MatrixWire createGrpc(String host, int port) {
        WireConfig config = new WireConfig();
        config.setType("grpc");
        config.setUrl(host + ":" + port);
        return create(config);
    }

    public static MatrixWire createWebSocket(String url) {
        WireConfig config = new WireConfig();
        config.setType("websocket");
        config.setUrl(url);
        return create(config);
    }
}

// =============================================================================
// UTILITY
// =============================================================================

public class MatrixUtil {
    private static long eventCounter = 0;

    public static synchronized String generateEventId() {
        return "evt_" + System.currentTimeMillis() + "_" + (++eventCounter);
    }

    public static String generateCorrelationId() {
        return "cor_" + System.currentTimeMillis() + "_" + (++eventCounter);
    }

    public static String computeChecksum(byte[] data) {
        // Use SHA-256 in real implementation
        return "checksum_" + data.length;
    }
}