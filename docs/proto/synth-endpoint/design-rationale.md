# Design Rationale: Warum ein Unified Endpoint?

Dieses Dokument erklärt die Design-Entscheidungen hinter dem Synth Endpoint Protocol.

---

## Das Problem: Fragmentierte Systeme

In modernen verteilten Systemen werden typischerweise separate Lösungen für verschiedene Aufgaben eingesetzt:

```
┌─────────────────────────────────────────────────────────────────┐
│  Typische Architektur: Viele Systeme                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│   │   Kafka     │  │   S3/HTTP   │  │   FTP       │            │
│   │  (Events)   │  │  (Files)    │  │  (Dev)      │            │
│   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘            │
│          │                │                │                    │
│   Kafka Protocol    HTTP/S3 API      FTP Protocol               │
│   SASL Auth         Bearer Token     SSH Keys                   │
│   librdkafka        libcurl          libssh2                    │
│          │                │                │                    │
│          └────────────────┼────────────────┘                    │
│                           │                                     │
│                    ┌──────┴──────┐                              │
│                    │   Client    │                              │
│                    │   (C++)     │                              │
│                    │             │                              │
│                    │ 3+ Libraries│                              │
│                    │ 3+ Auth     │                              │
│                    │ 3+ Configs  │                              │
│                    └─────────────┘                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Probleme dieser Architektur

| Problem | Auswirkung |
|---------|------------|
| **Mehrere Protokolle** | Jedes System hat eigenes Wire-Protocol |
| **Mehrere Auth-Systeme** | Kafka SASL, HTTP Bearer, SSH Keys, etc. |
| **Mehrere Libraries** | librdkafka (2MB+), libcurl, libssh2, aws-sdk |
| **Mehrere Konfigurationen** | Broker-Listen, Endpoints, Credentials |
| **Doppelte Fehlerbehandlung** | Jedes System hat eigene Error-Codes |
| **Doppeltes Monitoring** | Separate Metriken und Logs |
| **Cognitive Load** | Entwickler müssen alles verstehen |

---

## Warum nicht einfach Kafka für alles?

### Kafka's Design-Prinzipien

Kafka wurde als **Event Log** designed, nicht als **File Storage**:

```
                    Kafka: Append-Only Event Log

    Zeit ──────────────────────────────────────────────►

    │ Event1 │ Event2 │ Event3 │ Event4 │ Event5 │ ...
    └────────┴────────┴────────┴────────┴────────┘
                                            ▲
                                            │
                               Consumer Offset (sequentiell)
```

### Kafka-Limitierungen für File Access

| Feature | Kafka | File Storage (HTTP/S3) |
|---------|-------|------------------------|
| **Max Message Size** | 1MB default | Unbegrenzt |
| **Zugriffsmuster** | Sequentiell (Offset) | Random Access |
| **Range Requests** | Nicht möglich | `Range: bytes=0-1023` |
| **Caching (ETag)** | Nicht vorgesehen | Native HTTP-Feature |
| **Retention** | Zeitbasiert (löscht!) | Permanent |
| **Replikation** | Alles auf alle Broker | On-demand |
| **Protokoll** | Kafka Wire Protocol | Standard HTTP |

### Konkretes Beispiel: 50MB Textur laden

```
Mit Kafka (theoretisch):
─────────────────────────
1. Producer splittet 50MB in 50x 1MB Messages
2. Kafka repliziert alle 50 auf alle Broker
3. Consumer liest alle 50 Messages sequentiell
4. Consumer reassembliert die Datei
5. Bei Fehler: Alles von vorne

Mit HTTP:
─────────────────────────
1. GET /textures/bark.ktx2
2. Server sendet Datei (mit Chunked Transfer)
3. Bei Fehler: Range-Request für fehlende Bytes
4. Caching mit ETag für nächsten Request

→ HTTP ist das richtige Tool für Files!
```

---

## Die Lösung: Unified Endpoint

Synth Endpoint vereint **Kafka-Features** und **File-Access** in einem API:

```
┌─────────────────────────────────────────────────────────────────┐
│  Synth Endpoint: Ein System für alles                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                    ┌─────────────────────┐                      │
│                    │   Synth Endpoint    │                      │
│                    │      Gateway        │                      │
│                    └──────────┬──────────┘                      │
│                               │                                 │
│              ┌────────────────┼────────────────┐                │
│              │                │                │                │
│              ▼                ▼                ▼                │
│   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐           │
│   │  /resources  │ │  /messages   │ │  /scenes     │           │
│   │              │ │              │ │              │           │
│   │  File Access │ │  Pub/Sub     │ │  Composition │           │
│   │  Range Req.  │ │  Consumer Gr.│ │  Prefetch    │           │
│   │  Caching     │ │  Replay      │ │  LOD         │           │
│   └──────────────┘ └──────────────┘ └──────────────┘           │
│              │                │                │                │
│              └────────────────┼────────────────┘                │
│                               │                                 │
│                    ┌──────────┴──────────┐                      │
│                    │      Client         │                      │
│                    │                     │                      │
│                    │  1 Library (curl)   │                      │
│                    │  1 Auth Token       │                      │
│                    │  1 Config           │                      │
│                    └─────────────────────┘                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Was wir von Kafka übernehmen

| Kafka Feature | Synth Endpoint Äquivalent |
|---------------|---------------------------|
| Topics | `POST /messages/publish { topic: "..." }` |
| Consumer Groups | `JoinConsumerGroup()` in MessagingService |
| At-least-once | `DeliveryMode.AT_LEAST_ONCE` |
| Exactly-once | `DeliveryMode.EXACTLY_ONCE` |
| Message Replay | `QueryMessages()` mit Zeitbereich |
| Partitions | `partition_key` in Message |

### Was wir von HTTP/S3 übernehmen

| HTTP/S3 Feature | Synth Endpoint Äquivalent |
|-----------------|---------------------------|
| GET/PUT/DELETE | `/api/v1/resources/*` |
| Range Requests | `Range` Header support |
| ETag Caching | `etag` in ResourceMeta |
| Content-Type | `mime_type` in Response |
| Conditional GET | `If-None-Match` Header |

---

## Der wahre Vorteil: Reduzierte Komplexität

### Entwickler-Perspektive

```
┌─────────────────────────────────────────────────────────────────┐
│  Aufgabe: "Scene laden und auf Updates reagieren"               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Mit Kafka + HTTP (2 Systeme):                                  │
│  ─────────────────────────────                                  │
│                                                                 │
│  // Kafka Setup                                                 │
│  KafkaConsumer consumer = new KafkaConsumer(props);             │
│  consumer.subscribe("scene-updates");                           │
│                                                                 │
│  // HTTP Setup (separate!)                                      │
│  HttpClient http = HttpClient.newHttpClient();                  │
│                                                                 │
│  // Scene laden                                                 │
│  var scene = http.GET("https://cdn/scenes/forest.glb");         │
│                                                                 │
│  // Auf Updates warten (anderes System!)                        │
│  while (true) {                                                 │
│    var records = consumer.poll(Duration.ofMillis(100));         │
│    for (var record : records) {                                 │
│      if (record.key().equals("forest")) {                       │
│        scene = http.GET("https://cdn/scenes/forest.glb");       │
│      }                                                          │
│    }                                                            │
│  }                                                              │
│                                                                 │
│  → 2 Connections, 2 Auth, 2 Error Handling                      │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Mit Synth Endpoint (1 System):                                 │
│  ──────────────────────────────                                 │
│                                                                 │
│  SynthClient client = new SynthClient(endpoint, token);         │
│                                                                 │
│  // Scene laden                                                 │
│  var scene = client.get("/resources/scenes/forest.glb");        │
│                                                                 │
│  // Auf Updates warten (gleicher Client!)                       │
│  client.subscribe("/messages?topic=scenes/forest/*", msg -> {   │
│    scene = client.get("/resources/scenes/forest.glb");          │
│  });                                                            │
│                                                                 │
│  → 1 Connection, 1 Auth, 1 Error Handling                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Build-Perspektive (C++)

```cmake
# Mit Kafka + HTTP + FTP + S3
find_package(RdKafka REQUIRED)      # ~2MB, ZooKeeper deps
find_package(CURL REQUIRED)          # HTTP
find_package(LibSSH2 REQUIRED)       # SFTP
find_package(AWSSDK REQUIRED)        # S3, ~50MB+

target_link_libraries(renderer
    RdKafka::rdkafka
    CURL::libcurl
    LibSSH2::libssh2
    aws-cpp-sdk-s3
)

# Mit Synth Endpoint
find_package(CURL REQUIRED)          # Das ist alles!

target_link_libraries(renderer
    CURL::libcurl
)
```

---

## Trade-offs

### Was Synth Endpoint NICHT ist

| Feature | Kafka | Synth Endpoint |
|---------|-------|----------------|
| **Throughput** | Millionen msg/s | Tausende req/s |
| **Log Compaction** | Native | Nicht vorgesehen |
| **Stream Processing** | Kafka Streams | Extern |
| **Exactly-once Semantics** | Native | Best-effort |

### Wann Kafka trotzdem sinnvoll ist

- **Extrem hoher Throughput** (>100k msg/s)
- **Event Sourcing** als primäres Pattern
- **Stream Processing** mit Kafka Streams/ksqlDB
- **Bereits vorhandene Kafka-Infrastruktur**

### Wann Synth Endpoint besser ist

- **Mixed Workloads** (Files + Messages)
- **Einfache Client-Integration** (nur HTTP)
- **Geografisch verteilte Nodes**
- **Scene/Asset Composition**
- **AI Agent Integration** (MCP)

---

## Fazit

Synth Endpoint ist kein Kafka-Ersatz, sondern eine **Alternative für Use Cases wo Files und Messages zusammengehören**.

Die Kernidee: **Ein Protokoll (HTTPS), ein Auth-Token, ein Endpoint** - für alles.

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   "Zwei Systeme zu benutzen ist mühsam"                         │
│                                                                 │
│   → Deshalb: Ein System das beides kann.                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```
