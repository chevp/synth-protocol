# Synth Protocol

Protocol Buffer schemas for the **Synth AI-Native Content Creation Platform**.

> **[Was ist Synth?](docs/ai-native-platform.md)** - Die Infrastruktur für AI-gesteuerte Content Pipelines

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SYNTH PROTOCOL STACK                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   APPLICATION LAYER                                                         │
│   ─────────────────                                                         │
│   synth-core/     Core types, assets, content generation                    │
│   synth-events/   Event notifications and subscriptions                     │
│   synth-agent/    Autonomous AI agents and tasks                            │
│   synth-state-sync/ Real-time scene synchronization                         │
│                                                                             │
│   ═══════════════════════════════════════════════════════════════════════   │
│                                                                             │
│   WIRE LAYER (Unified Transport)                                            │
│   ──────────────────────────────                                            │
│   synth-wire/envelope.proto   Universal message container                   │
│   synth-wire/channel.proto    Communication patterns                        │
│   synth-wire/transport.proto  HTTP, WebSocket, gRPC, Kafka, TCP bindings    │
│   synth-wire/service.proto    gRPC service definition                       │
│                                                                             │
│   ═══════════════════════════════════════════════════════════════════════   │
│                                                                             │
│   TRANSPORT (Client ↔ Server)                                               │
│   ───────────────────────────                                               │
│   HTTP/REST, WebSocket, gRPC, Kafka, TCP, UDP, QUIC                         │
│                                                                             │
│   ═══════════════════════════════════════════════════════════════════════   │
│                                                                             │
│   SERVER-INTERNAL (not part of protocol)                                    │
│   ──────────────────────────────────────                                    │
│   SQLite, MySQL, PostgreSQL, Redis, FTP, S3, etc.                           │
│   (How server stores data is its own concern)                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key Insight**: Storage backends (MySQL, S3, FTP, etc.) are SERVER-INTERNAL.
The wire protocol only defines REQUEST → RESPONSE. Clients never see storage.

## Proto Packages

### Core (`synth-core/`)

| File | Description |
|------|-------------|
| `common.proto` | Shared types (Vec3, Color, Transform, etc.) |
| `model.proto` | ML model definitions and inference |
| `content.proto` | Generative AI for game assets |
| `asset.proto` | Asset referencing, loading, and caching |
| `plugin.proto` | Plugin system definitions |

### Events (`synth-events/`)

| File | Description |
|------|-------------|
| `event.proto` | Event structure and routing |
| `uri.proto` | URI schemes, paths, and actions |

### State Sync (`synth-state-sync/`)

| File | Description |
|------|-------------|
| `math_types.proto` | Vector, quaternion, matrix types |
| `scene_state.proto` | Scene snapshots and deltas |
| `sync_service.proto` | State synchronization service |

### Agents (`synth-agent/`)

| File | Description |
|------|-------------|
| `agent.proto` | Autonomous agent system |
| `nlp.proto` | Natural language processing |
| `vision.proto` | Computer vision services |

### Wire Protocol (`synth-wire/`)

| File | Description |
|------|-------------|
| `envelope.proto` | Universal message container for all payloads |
| `channel.proto` | Communication patterns and session management |
| `transport.proto` | Transport bindings (HTTP, WS, gRPC, Kafka, TCP) |
| `service.proto` | gRPC service definition |

## Wire Protocol

The **synth-wire** package provides a unified protocol layer:

### One Envelope for Everything

```protobuf
message SynthEnvelope {
    EnvelopeHeader header = 1;
    PayloadType payload_type = 2;

    oneof payload {
        EventPayload event = 10;      // Notifications
        StatePayload state = 11;      // Scene sync
        AssetPayload asset = 12;      // Data transfer
        RpcPayload rpc = 13;          // Tool calls
        BinaryPayload binary = 14;    // Large files
        ControlPayload control = 15;  // Protocol control
    }
}
```

### Transport Agnostic

Same bytes work over:
- **HTTP/REST** - Request/response
- **WebSocket** - Bidirectional streaming
- **gRPC** - Native protobuf streaming
- **Kafka** - Event distribution
- **TCP** - Raw socket for maximum performance

### Client Perspective

The client only sees **REQUEST → RESPONSE**:

```
Client: { method: "asset/get", id: "car_model" }
Server: { data: <bytes>, metadata: {...} }

// Client doesn't know or care if server uses MySQL, S3, or FTP internally
```

## Integration

| System | Usage |
|--------|-------|
| **Cryo** | Asset definitions, content libraries |
| **Arctic** | Rendering pipeline, scene format |
| **Nuna** | Plugin system, MCP integration |
| **Synth Studio** | Editor protocol, state sync |

## Code Generation

```bash
# Generate for all languages
protoc --proto_path=docs/proto \
       --cpp_out=gen/cpp \
       --php_out=gen/php \
       --ts_out=gen/ts \
       docs/proto/**/*.proto
```

## Client Libraries

| Language | Package |
|----------|---------|
| C++ | `libsynth-wire` |
| PHP | `synth/wire` |
| TypeScript | `@synth/wire` |
| C# | `Synth.Wire` |
| Java | `io.synth.protocol.wire` |
| Go | `synth/wire` |