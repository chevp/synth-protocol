# Synth Endpoint Protocol

**Unified Data + Messaging Layer für verteilte Synth-Netzwerke**

---

## Warum nicht Kafka?

```
┌─────────────────────────────────────────────────────────────────┐
│  Problem: Kafka + separate File Access = Komplexität           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   C++ Vulkan Renderer müsste verwenden:                         │
│                                                                 │
│   ❌ librdkafka        (Kafka Client)     → 2MB+ Library        │
│   ❌ libcurl           (HTTP für Files)   → Separate Auth       │
│   ❌ libssh2           (SFTP für Dev)     → Weitere Deps        │
│   ❌ aws-sdk-cpp       (S3 für Assets)    → Riesige Library     │
│                                                                 │
│   = 4+ Dependencies, 4 Auth-Systeme, hohe Komplexität           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Lösung: Synth Endpoint = Files + Messages über HTTPS          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   C++ Vulkan Renderer braucht nur:                              │
│                                                                 │
│   ✅ libcurl (oder native HTTP)                                 │
│                                                                 │
│   GET  /api/v1/resources/scenes/forest.glb   → File laden       │
│   GET  /api/v1/messages/poll?topic=events/*  → Events empfangen │
│   POST /api/v1/messages/publish              → Event senden     │
│                                                                 │
│   = 1 Library, 1 Auth-Token, 1 Endpoint                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Übersicht

Das Synth Endpoint Protocol vereint **Datenzugriff** und **Messaging** in einem einheitlichen REST/gRPC Interface:

- **Files + Messages** über einen Endpoint (kein Kafka nötig)
- **Protokoll-agnostisch** - Backend kann HTTP, FTP, S3, etc. nutzen
- **Ein HTTP-Client reicht** für C++, keine weiteren Dependencies
- **Automatische Node-Auswahl** basierend auf Geografie und Last
- **Scene-Komposition** aus verteilten Quellen

```
┌─────────────────────────────────────────────────────────────────┐
│                     Synth Endpoint Layer                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Client Request                                                │
│        │                                                        │
│        ▼                                                        │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              EndpointService.Resolve()                  │   │
│   │                                                         │   │
│   │   synth://de-node/scenes/forest                         │   │
│   │              │                                          │   │
│   │              ▼                                          │   │
│   │   ┌─────────────────────────────────────────────────┐   │   │
│   │   │  1. NodeRegistry: de-node → 185.x.x.x           │   │   │
│   │   │  2. Protocol: HTTPS                             │   │   │
│   │   │  3. Cache: Check local → Edge → Origin          │   │   │
│   │   │  4. Fetch: GET /api/v1/scenes/forest            │   │   │
│   │   │  5. Return: Format-agnostisch                   │   │   │
│   │   └─────────────────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Proto-Dateien

| Datei | Package | Beschreibung |
|-------|---------|--------------|
| [endpoint.proto](endpoint.proto) | `synth.endpoint` | Kern-Definitionen für URI-Auflösung und Datenzugriff |
| [node-registry.proto](node-registry.proto) | `synth.endpoint` | Node-Registrierung, Discovery und Load-Balancing |
| [composition.proto](composition.proto) | `synth.endpoint` | Scene-Komposition und Dependency-Management |
| [messaging.proto](messaging.proto) | `synth.endpoint` | Pub/Sub Messaging und Request/Reply Patterns |
| [mcp-tools.proto](mcp-tools.proto) | `synth.endpoint.mcp` | MCP Tool-Definitionen für AI Agents |
| [rest-api.proto](rest-api.proto) | `synth.endpoint.rest` | REST/HTTP API für C++ und Web Clients |

---

## Architektur

### 1. Unified Data Access

```
                    ┌──────────────────────┐
                    │   ResolveRequest     │
                    │   uri: "synth://..." │
                    └──────────┬───────────┘
                               │
                               ▼
              ┌────────────────────────────────┐
              │        EndpointService         │
              ├────────────────────────────────┤
              │  ┌──────────────────────────┐  │
              │  │   Protocol Handlers      │  │
              │  ├──────────────────────────┤  │
              │  │  • FileHandler (file://) │  │
              │  │  • HttpHandler (https://)│  │
              │  │  • FtpHandler (sftp://)  │  │
              │  │  • SynthHandler (synth://)│ │
              │  │  • S3Handler (s3://)     │  │
              │  │  • ...                   │  │
              │  └──────────────────────────┘  │
              └────────────────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │   ResolveResponse    │
                    │   content, meta      │
                    └──────────────────────┘
```

### 2. Node Registry & Discovery

```
                        ┌─────────────────┐
                        │  Client (DE)    │
                        └────────┬────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │    SelectNode()        │
                    │    strategy: NEAREST   │
                    └────────────┬───────────┘
                                 │
            ┌────────────────────┼────────────────────┐
            │                    │                    │
            ▼                    ▼                    ▼
    ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
    │ de-frankfurt  │   │ nl-amsterdam  │   │ us-east-1     │
    │ latency: 5ms  │   │ latency: 15ms │   │ latency: 90ms │
    │   ◄─────────  │   │               │   │               │
    │   SELECTED    │   │               │   │               │
    └───────────────┘   └───────────────┘   └───────────────┘
```

### 3. Scene Composition

```
    ComposeScene("synth://hub/scenes/forest")
                        │
                        ▼
    ┌───────────────────────────────────────────────────────┐
    │                 CompositionService                    │
    ├───────────────────────────────────────────────────────┤
    │                                                       │
    │   Scene Definition                                    │
    │   ├── base_scene: synth://lib/scenes/nature-base      │
    │   └── dependencies:                                   │
    │       ├── synth://de/models/tree-oak.glb              │
    │       ├── synth://de/textures/bark-001.ktx2           │
    │       ├── synth://cdn/audio/forest-ambient.ogg        │
    │       └── synth://compute/hdri/forest-sky.hdr         │
    │                                                       │
    │   ┌─────────────────────────────────────────────┐     │
    │   │  Parallel Fetch (max_concurrent: 8)         │     │
    │   │                                             │     │
    │   │  [de-node] ──► tree-oak.glb ✓               │     │
    │   │  [de-node] ──► bark-001.ktx2 ✓              │     │
    │   │  [cdn-edge] ─► forest-ambient.ogg ✓         │     │
    │   │  [compute] ──► forest-sky.hdr ✓             │     │
    │   └─────────────────────────────────────────────┘     │
    │                                                       │
    └───────────────────────────────────────────────────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │   ComposedScene       │
            │   - All resources     │
            │   - Dependency graph  │
            │   - Cache manifest    │
            └───────────────────────┘
```

---

## Kern-Konzepte

### URI-Schema: `synth://`

Das Synth-URI-Schema ermöglicht Node-unabhängige Ressourcen-Referenzierung:

```
synth://[node-id]/[path]?[query]#[fragment]

Beispiele:
  synth://de-frankfurt/scenes/forest           # Spezifischer Node
  synth://auto/models/tree.glb                 # Auto-Routing
  synth://nearest/textures/bark.ktx2           # Nächster Node
```

### Resource Status

```protobuf
enum ResourceStatus {
  AVAILABLE       // Ressource verfügbar
  UNAVAILABLE     // Nicht erreichbar
  REQUIRES_AUTH   // Authentifizierung erforderlich
  REQUIRES_CONFIG // Konfiguration nötig
  LOADING         // Wird geladen
  CACHED          // Aus Cache
  ERROR           // Fehler
  NOT_FOUND       // Existiert nicht
  FORBIDDEN       // Zugriff verweigert
}
```

### Cache-Strategien

```protobuf
enum CacheStrategy {
  DEFAULT                  // Standard-Caching
  NO_CACHE                 // Immer frisch laden
  CACHE_FIRST              // Cache bevorzugen
  NETWORK_FIRST            // Netzwerk bevorzugen
  STALE_WHILE_REVALIDATE   // Cache + Background-Refresh
}
```

### Node-Auswahl

```protobuf
enum NodeSelectionStrategy {
  NEAREST         // Geografisch nächster Node
  LOWEST_LATENCY  // Niedrigste Latenz
  ROUND_ROBIN     // Gleichmäßige Verteilung
  LEAST_LOADED    // Geringste Last
  PRIORITY        // Nach Priorität
}
```

---

## gRPC Services

### EndpointService

```protobuf
service EndpointService {
  // Einzelne Ressource laden
  rpc Resolve(ResolveRequest) returns (ResolveResponse);

  // Batch-Loading
  rpc BatchResolve(BatchResolveRequest) returns (BatchResolveResponse);

  // Streaming für große Dateien
  rpc StreamResolve(ResolveRequest) returns (stream ResolveResponse);

  // Status prüfen (ohne Content)
  rpc CheckStatus(ResolveRequest) returns (ResolveResponse);

  // Schreiben
  rpc Write(WriteRequest) returns (WriteResponse);
}
```

### NodeRegistryService

```protobuf
service NodeRegistryService {
  // Node-Verwaltung
  rpc RegisterNode(RegisterNodeRequest) returns (RegisterNodeResponse);
  rpc UnregisterNode(UnregisterNodeRequest) returns (UnregisterNodeResponse);

  // Discovery
  rpc FindNodes(FindNodesRequest) returns (FindNodesResponse);
  rpc SelectNode(SelectNodeRequest) returns (SelectNodeResponse);

  // Health
  rpc Heartbeat(HeartbeatRequest) returns (HeartbeatResponse);
  rpc StreamNodeEvents(StreamNodeEventsRequest) returns (stream NodeEvent);
}
```

### CompositionService

```protobuf
service CompositionService {
  // Scene zusammenstellen
  rpc ComposeScene(ComposeSceneRequest) returns (ComposeSceneResponse);

  // Streaming für große Szenen
  rpc StreamComposeScene(ComposeSceneRequest) returns (stream ComposeSceneResponse);

  // Live-Updates
  rpc WatchScene(WatchSceneRequest) returns (stream SceneChangeEvent);

  // Prefetching
  rpc Prefetch(PrefetchRequest) returns (PrefetchResponse);

  // Analyse
  rpc AnalyzeDependencies(AnalyzeDependenciesRequest) returns (DependencyManifest);
}
```

### MessagingService

```protobuf
service MessagingService {
  // Pub/Sub
  rpc Publish(PublishRequest) returns (PublishResponse);
  rpc Subscribe(SubscribeRequest) returns (stream ReceivedMessage);
  rpc Acknowledge(AcknowledgeRequest) returns (AcknowledgeResponse);

  // Request/Reply
  rpc Request(RequestMessage) returns (ReplyMessage);

  // Node Messaging
  rpc SendToNode(NodeMessage) returns (NodeMessageResponse);
  rpc Broadcast(BroadcastRequest) returns (BroadcastResponse);

  // Consumer Groups (wie Kafka)
  rpc JoinConsumerGroup(JoinGroupRequest) returns (ConsumerGroup);

  // Queries (Replay)
  rpc QueryMessages(QueryMessagesRequest) returns (QueryMessagesResponse);
}
```

---

## Beispiele

### 1. Ressource laden

```typescript
// TypeScript Client
const response = await endpoint.resolve({
  uri: "synth://de-frankfurt/models/tree.glb",
  cacheStrategy: CacheStrategy.CACHE_FIRST,
  timeout: { seconds: 30 }
});

if (response.status === ResourceStatus.AVAILABLE) {
  const model = response.content;
}
```

### 2. Besten Node auswählen

```typescript
const node = await registry.selectNode({
  resourceUri: "synth://auto/scenes/forest",
  clientLocation: {
    latitude: 50.1109,
    longitude: 8.6821,
    countryCode: "DE"
  },
  strategy: NodeSelectionStrategy.LOWEST_LATENCY
});

console.log(`Selected: ${node.selectedNode.nodeId}`);
// Output: "Selected: de-frankfurt-1"
```

### 3. Scene komponieren

```typescript
const scene = await composition.composeScene({
  sceneUri: "synth://hub/scenes/forest",
  options: {
    maxConcurrentFetches: 8,
    useCache: true,
    lod: {
      maxLodLevel: 2,
      textureMaxResolution: 2048
    }
  },
  context: {
    location: clientLocation,
    device: {
      availableVram: 8 * 1024 * 1024 * 1024, // 8GB
      supportedFormats: ["glb", "ktx2", "webp"]
    }
  }
});

console.log(`Loaded ${scene.stats.resourcesFetched} resources`);
console.log(`${scene.stats.resourcesFromCache} from cache`);
```

---

## Integration mit bestehenden Systemen

### synth-cluster-editor

Die Proto-Definitionen erweitern das bestehende URI-System:

```typescript
// Bestehend in uri-types.ts
enum UriScheme {
  FILE, FTPS, FTP, SFTP, HTTPS, HTTP, SYNTH, DATA
}

// Neu: Proto-basierte Typen mit voller Interoperabilität
import { UriScheme as ProtoUriScheme } from '@synth/protocol';
```

### synth-events

Events für Node-Änderungen und Composition-Updates:

```protobuf
// Event-URIs
synth://events/endpoint/node-status-changed
synth://events/endpoint/composition-updated
synth://events/endpoint/cache-invalidated
```

---

## Deployment-Topologie

```
                    ┌─────────────────────────┐
                    │     Global Registry     │
                    │    (synth-hub.net)      │
                    └───────────┬─────────────┘
                                │
           ┌────────────────────┼────────────────────┐
           │                    │                    │
           ▼                    ▼                    ▼
   ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
   │   EU Region   │   │   US Region   │   │  Asia Region  │
   │               │   │               │   │               │
   │ de-frankfurt  │   │  us-east-1    │   │  ap-tokyo-1   │
   │ nl-amsterdam  │   │  us-west-1    │   │  ap-singapore │
   │ fr-paris      │   │               │   │               │
   └───────────────┘   └───────────────┘   └───────────────┘
           │
           ├── Origin Nodes (Primärdaten)
           ├── Edge Nodes (Cache/CDN)
           ├── Compute Nodes (ML-Inferenz)
           └── Gateway Nodes (API)
```

---

## Weiterentwicklung

### Geplante Erweiterungen

1. **P2P-Sync** - Peer-to-Peer Synchronisation zwischen Nodes
2. **Delta-Sync** - Inkrementelle Updates für große Ressourcen
3. **Content-Addressing** - IPFS-ähnliche Content-basierte Adressierung
4. **Signed Resources** - Kryptografisch signierte Ressourcen
5. **Quota Management** - Ressourcen-Limits pro Client/Node

---

## Weitere Dokumentation

| Dokument | Beschreibung |
|----------|--------------|
| [Design Rationale](design-rationale.md) | Warum ein Unified Endpoint? Warum nicht Kafka? |
| [Client Integration](client-integration.md) | C++, TypeScript, AI Agent Integration Guide |
| [System Comparison](comparison.md) | Vergleich mit Kafka, NATS, S3, CDN |

---

## Referenzen

- [synth-core/common.proto](../synth-core/common.proto) - Gemeinsame Typen
- [synth-events/event.proto](../synth-events/event.proto) - Event-System
- [nuna/core.proto](../nuna/core.proto) - ECS-Definitionen
