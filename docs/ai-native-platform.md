# Synth: AI-Native Content Creation Platform

**Die Infrastruktur für AI-gesteuerte Content Pipelines**

---

## Vision

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   "AI Agents können Content ERSTELLEN, VERWALTEN und            │
│    VERTEILEN - über EIN einheitliches Protokoll"                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

Synth ist keine einzelne Anwendung, sondern ein **Ökosystem** für AI-native Content Creation. Es ermöglicht AI Agents (Claude, GPT, eigene Modelle) direkten Zugriff auf:

- **Scenes** - 3D-Szenen erstellen und modifizieren
- **Assets** - Texturen, Modelle, Audio verwalten
- **Pipelines** - Content automatisiert verarbeiten und verteilen
- **Collaboration** - Mensch und AI arbeiten zusammen

---

## Was bedeutet "AI-Native"?

### Traditionelle Tools vs. AI-Native

```
┌─────────────────────────────────────────────────────────────────┐
│  Traditionelle Content-Tools                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Mensch ──► GUI ──► Tool ──► Datei                             │
│                                                                 │
│   • Designed für menschliche Interaktion                        │
│   • Menüs, Buttons, visuelle Feedback                           │
│   • AI kann nur "zuschauen" oder Screenshots analysieren        │
│   • Keine programmatische Kontrolle                             │
│                                                                 │
│   Beispiele: Blender, Photoshop, Unity Editor                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  AI-Native Platform (Synth)                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   AI Agent ──► API ──► Platform ──► Content                     │
│       ▲                    │                                    │
│       │                    ▼                                    │
│   Mensch ◄──────────── Feedback                                 │
│                                                                 │
│   • Designed für programmatischen Zugriff                       │
│   • Strukturierte APIs (REST, gRPC, MCP)                        │
│   • AI kann direkt agieren                                      │
│   • Mensch supervisiert und korrigiert                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### AI-First Design Prinzipien

| Prinzip | Traditionell | AI-Native (Synth) |
|---------|--------------|-------------------|
| **Interface** | GUI für Menschen | API für Agents + GUI für Menschen |
| **Aktionen** | Click, Drag, Type | Strukturierte Commands |
| **Feedback** | Visuell | Strukturierte Responses |
| **Automation** | Scripting nachträglich | Automation-first |
| **Collaboration** | Mensch-Mensch | Mensch-AI-Mensch |

---

## Architektur-Übersicht

```
┌─────────────────────────────────────────────────────────────────┐
│                    Synth Platform Stack                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                    AI Layer                             │   │
│   │                                                         │   │
│   │   Claude ◄──► MCP Server ◄──► GPT ◄──► Custom Models    │   │
│   │                    │                                    │   │
│   └────────────────────┼────────────────────────────────────┘   │
│                        │                                        │
│   ┌────────────────────┼────────────────────────────────────┐   │
│   │                    ▼                                    │   │
│   │            Synth Endpoint                               │   │
│   │     (Unified Data + Messaging API)                      │   │
│   │                                                         │   │
│   │   /api/v1/resources  - Files & Assets                   │   │
│   │   /api/v1/messages   - Events & Commands                │   │
│   │   /api/v1/scenes     - Scene Composition                │   │
│   │   /api/v1/nodes      - Infrastructure                   │   │
│   │                                                         │   │
│   └────────────────────┬────────────────────────────────────┘   │
│                        │                                        │
│   ┌────────────────────┼────────────────────────────────────┐   │
│   │                    ▼                                    │   │
│   │              Core Services                              │   │
│   │                                                         │   │
│   │   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │   │
│   │   │  Nuna   │ │  Cryo   │ │ Arctic  │ │  Axon   │       │   │
│   │   │ Scenes  │ │ Assets  │ │ Render  │ │Inference│       │   │
│   │   └─────────┘ └─────────┘ └─────────┘ └─────────┘       │   │
│   │                                                         │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                   Storage Layer                         │   │
│   │                                                         │   │
│   │   SQLite (Local) ◄──► S3/GCS (Cloud) ◄──► CDN (Edge)    │   │
│   │                                                         │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Synth Endpoint

**Die Unified API für alles**

```
┌─────────────────────────────────────────────────────────────────┐
│  Synth Endpoint: Ein Protokoll für Files + Messages             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Statt:                                                        │
│   • Kafka für Events                                            │
│   • S3 für Files                                                │
│   • HTTP für APIs                                               │
│   • FTP für Development                                         │
│                                                                 │
│   Nur:                                                          │
│   • HTTPS /api/v1/* für ALLES                                   │
│                                                                 │
│   AI Agent oder C++ Client - gleiche API:                       │
│                                                                 │
│   GET  /api/v1/resources/scenes/forest.glb                      │
│   POST /api/v1/messages/publish                                 │
│   POST /api/v1/scenes/compose                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

→ Siehe [Synth Endpoint Protocol](proto/synth-endpoint/README.md)

### 2. Nuna - Scene Management

**ECS-basiertes Scene System**

```
┌─────────────────────────────────────────────────────────────────┐
│  Nuna: Closed Monolith Plugin System                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Scene                                                         │
│   ├── ClusterNode (Entity)                                      │
│   │   ├── TransformComponent                                    │
│   │   ├── MeshComponent ──► Asset Reference                     │
│   │   └── MaterialComponent ──► Asset Reference                 │
│   │                                                             │
│   ├── ClusterNode (Light)                                       │
│   │   ├── TransformComponent                                    │
│   │   └── LightComponent                                        │
│   │                                                             │
│   └── Systems (via MCP Plugins)                                 │
│       ├── RenderSystem                                          │
│       ├── PhysicsSystem                                         │
│       └── AIBehaviorSystem                                      │
│                                                                 │
│   Storage: SQLite (single file, portable)                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

→ Siehe [Nuna Protocol](proto/nuna/README.md)

### 3. MCP Integration

**AI Agents als First-Class Citizens**

```
┌─────────────────────────────────────────────────────────────────┐
│  Model Context Protocol (MCP) Integration                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Claude/GPT                                                    │
│       │                                                         │
│       ▼                                                         │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                 Synth MCP Server                        │   │
│   ├─────────────────────────────────────────────────────────┤   │
│   │                                                         │   │
│   │   Tools:                                                │   │
│   │   • synth_fetch_resource   - Assets laden               │   │
│   │   • synth_compose_scene    - Scenes zusammenstellen     │   │
│   │   • synth_publish_event    - Events senden              │   │
│   │   • synth_query_resources  - Assets suchen              │   │
│   │   • synth_list_nodes       - Infrastruktur anzeigen     │   │
│   │                                                         │   │
│   │   Resources:                                            │   │
│   │   • Scene Definitions                                   │   │
│   │   • Asset Catalogs                                      │   │
│   │   • Node Status                                         │   │
│   │                                                         │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│   AI kann:                                                      │
│   • Scenes analysieren und modifizieren                         │
│   • Assets suchen und organisieren                              │
│   • Pipelines triggern                                          │
│   • Mit anderen Agents kommunizieren                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

→ Siehe [MCP Tools](proto/synth-endpoint/mcp-tools.proto)

---

## Use Cases

### Use Case 1: AI-Assisted Scene Building

```
┌─────────────────────────────────────────────────────────────────┐
│  "Baue mir eine Waldszene mit Eichen und einem Bach"            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   User ──► Claude                                               │
│              │                                                  │
│              ▼                                                  │
│   1. synth_query_resources("trees/oak/*")                       │
│      → Findet verfügbare Eichen-Modelle                         │
│                                                                 │
│   2. synth_query_resources("water/stream/*")                    │
│      → Findet Bach-Assets                                       │
│                                                                 │
│   3. synth_compose_scene({                                      │
│        base: "templates/forest",                                │
│        add: ["oak-tree-01", "oak-tree-02", "stream-01"],        │
│        layout: "natural-scatter"                                │
│      })                                                         │
│      → Erstellt die Scene                                       │
│                                                                 │
│   4. Returns Scene-ID und Preview                               │
│              │                                                  │
│              ▼                                                  │
│   User ◄── "Hier ist deine Waldszene: synth://scenes/xyz"       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Use Case 2: Automated Asset Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│  Artist lädt neues 3D-Modell hoch                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Artist ──► Upload model.fbx                                   │
│                    │                                            │
│                    ▼                                            │
│   ┌────────────────────────────────────────────────────────┐    │
│   │  Event: "asset/uploaded"                               │    │
│   │  { type: "model", path: "models/new/model.fbx" }       │    │
│   └────────────────────────────────────────────────────────┘    │
│                    │                                            │
│         ┌─────────┼─────────┐                                   │
│         ▼         ▼         ▼                                   │
│   ┌──────────┐ ┌──────────┐ ┌──────────┐                       │
│   │ Optimize │ │ Generate │ │ Validate │                       │
│   │   LODs   │ │ Thumbs   │ │  Quality │                       │
│   └────┬─────┘ └────┬─────┘ └────┬─────┘                       │
│        │            │            │                              │
│        └────────────┼────────────┘                              │
│                     ▼                                           │
│   ┌────────────────────────────────────────────────────────┐    │
│   │  Event: "asset/processed"                              │    │
│   │  { lods: [...], thumbnail: "...", quality: "A" }       │    │
│   └────────────────────────────────────────────────────────┘    │
│                     │                                           │
│                     ▼                                           │
│   AI Agent: "Neues Modell verarbeitet. Qualität: A.             │
│              Soll ich es in bestehende Scenes integrieren?"     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Use Case 3: Multi-Agent Collaboration

```
┌─────────────────────────────────────────────────────────────────┐
│  Mehrere AI Agents arbeiten zusammen                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────┐         ┌─────────────┐                      │
│   │ Scene Agent │ ◄─────► │ Asset Agent │                      │
│   │  (Claude)   │  Msgs   │   (GPT-4)   │                      │
│   └──────┬──────┘         └──────┬──────┘                      │
│          │                       │                              │
│          │    ┌─────────────┐    │                              │
│          └───►│   Review    │◄───┘                              │
│               │   Agent     │                                   │
│               │  (Custom)   │                                   │
│               └──────┬──────┘                                   │
│                      │                                          │
│                      ▼                                          │
│   ┌────────────────────────────────────────────────────────┐    │
│   │  Workflow:                                             │    │
│   │                                                        │    │
│   │  1. Scene Agent: "Brauche Baum für Position (10,0,5)"  │    │
│   │  2. Asset Agent: "Hier sind 3 passende Bäume..."       │    │
│   │  3. Scene Agent: "Nehme oak-02, platziere..."          │    │
│   │  4. Review Agent: "Scene validiert, keine Kollisionen" │    │
│   │                                                        │    │
│   └────────────────────────────────────────────────────────┘    │
│                                                                 │
│   Alles über Synth Endpoint Messages koordiniert                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Vergleich mit Alternative

### Warum nicht nur Blender + Scripts?

```
┌─────────────────────────────────────────────────────────────────┐
│  Blender + Python                    Synth Platform             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  • Single Machine                    • Distributed              │
│  • File-based                        • Service-based            │
│  • Sync = Manual                     • Sync = Automatic         │
│  • AI = Screen Scraping              • AI = Native API          │
│  • Collaboration = Git               • Collaboration = Real-time│
│                                                                 │
│  Blender bleibt ein Tool im Workflow!                           │
│  Synth orchestriert den gesamten Workflow.                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Zielgruppen

### 1. Game Studios (B2B)

```
Problem:  Asset Pipelines sind fragmentiert, AI-Integration schwierig
Lösung:   Synth als zentrale Content-Infrastruktur
Value:    Schnellere Iteration, AI-Assistenz, bessere Collaboration
```

### 2. VFX/Architektur (B2B)

```
Problem:  Viele Tools, keine einheitliche Asset-Verwaltung
Lösung:   Synth Endpoint als Universal Asset Layer
Value:    Tool-agnostische Pipelines, AI-gesteuerte Automation
```

### 3. Indie Developers (Prosumer)

```
Problem:  Können sich keine großen Pipelines leisten
Lösung:   Synth Studio (Electron App) mit AI-Assistenz
Value:    Professionelle Workflows zu geringen Kosten
```

### 4. AI/ML Teams (B2B)

```
Problem:  Keine gute Infrastruktur für Content-generierende AI
Lösung:   Synth als Training/Inference Platform für Content-AI
Value:    Structured Data, Distribution, Feedback Loops
```

---

## Technologie-Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                    Technology Stack                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Protocols:                                                    │
│   • Protobuf (synth-protocol)                                   │
│   • gRPC (Service Communication)                                │
│   • REST/HTTP (Client Access)                                   │
│   • MCP (AI Agent Integration)                                  │
│                                                                 │
│   Languages:                                                    │
│   • TypeScript/Node.js (Services, Electron)                     │
│   • C++ (Vulkan Renderer, Performance-critical)                 │
│   • Rust (CLI Tools, WASM)                                      │
│   • Python (ML Pipelines)                                       │
│                                                                 │
│   Storage:                                                      │
│   • SQLite (Local, Portable)                                    │
│   • S3-compatible (Cloud)                                       │
│   • LevelDB (Cache)                                             │
│                                                                 │
│   Infrastructure:                                               │
│   • Docker/Kubernetes (Deployment)                              │
│   • Terraform (IaC)                                             │
│   • GitHub Actions (CI/CD)                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Roadmap

### Phase 1: Foundation (Current)

- [x] Synth Protocol Definitions
- [x] Synth Endpoint Design
- [ ] Reference Implementation
- [ ] Basic MCP Server

### Phase 2: Core Platform

- [ ] Nuna Scene Service
- [ ] Asset Management
- [ ] Multi-Node Deployment
- [ ] Electron Scene Editor

### Phase 3: AI Integration

- [ ] Full MCP Tool Suite
- [ ] AI Agent Framework
- [ ] Training Data Pipelines
- [ ] Feedback Loops

### Phase 4: Ecosystem

- [ ] Plugin Marketplace
- [ ] Community Assets
- [ ] Enterprise Features
- [ ] SDK & Documentation

---

## Zusammenfassung

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   Synth ist die INFRASTRUKTUR für AI-native Content Creation    │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                                                         │   │
│   │   Nicht: "Noch ein 3D-Tool"                             │   │
│   │                                                         │   │
│   │   Sondern: "Das Protokoll, über das AI Agents           │   │
│   │            Content erstellen, verwalten und verteilen"  │   │
│   │                                                         │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│   Kern-Innovation:                                              │
│                                                                 │
│   • Unified API (Files + Messages + Composition)                │
│   • AI-First Design (MCP native)                                │
│   • Distributed Architecture (Geo-Routing)                      │
│   • Open Protocol (nicht locked-in)                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Weiterführende Dokumentation

| Dokument | Beschreibung |
|----------|--------------|
| [Synth Endpoint Protocol](proto/synth-endpoint/README.md) | Unified Data + Messaging API |
| [Design Rationale](proto/synth-endpoint/design-rationale.md) | Warum so und nicht anders? |
| [Client Integration](proto/synth-endpoint/client-integration.md) | C++, TypeScript, AI Integration |
| [System Comparison](proto/synth-endpoint/comparison.md) | Vergleich mit Kafka, S3, etc. |
| [Nuna Protocol](proto/nuna/README.md) | Scene & ECS System |
