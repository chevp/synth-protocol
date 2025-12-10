# Synth Protocol

Protocol Buffer schemas for the **Synth AI-Native Content Creation Platform**.

> **[Was ist Synth?](docs/ai-native-platform.md)** - Die Infrastruktur für AI-gesteuerte Content Pipelines

---

## Overview

This module defines the gRPC service interfaces and message types for:

- **Model Management** - ML model definitions, parameters, and requirements
- **Agent System** - Autonomous AI agents, tasks, and inter-agent communication
- **Vision** - Image analysis, asset classification, and computer vision
- **NLP** - Text processing, generation, and semantic search
- **Content Generation** - Texture, material, and asset generation for Cryo/Arctic
- **Unified Endpoint** - Protocol-agnostic data access across distributed nodes

## Protocol Packages

| Package | Directory | Description |
|---------|-----------|-------------|
| `synth.*` | [synth-core/](docs/proto/synth-core/) | Core ML types, models, plugins, content generation |
| `synth.agents` | [synth-agent/](docs/proto/synth-agent/) | Autonomous AI agent system |
| `synth.events` | [synth-events/](docs/proto/synth-events/) | Event-driven pub/sub with URI routing |
| `synth.state_sync` | [synth-state-sync/](docs/proto/synth-state-sync/) | State synchronization |
| `synth.endpoint` | [synth-endpoint/](docs/proto/synth-endpoint/) | **Unified Data Access Layer** |
| `nuna.*` | [nuna/](docs/proto/nuna/) | Closed Monolith Plugin System (SQLite-native) |

## Synth Endpoint (NEU)

Das **Synth Endpoint Protocol** ermöglicht protokoll-agnostischen Datenzugriff über verteilte Nodes:

```
synth://de-frankfurt/scenes/forest
        │            │
        │            └── Ressourcen-Pfad
        └── Node-ID (auto-routing möglich)
```

**Features:**
- Einheitlicher Zugriff (HTTP, FTP, S3, lokale Dateien)
- Geografische Node-Registry mit Auto-Routing
- Scene-Komposition aus verteilten Quellen
- Intelligentes Caching mit verschiedenen Strategien

→ [Dokumentation](docs/proto/synth-endpoint/README.md)

## Proto Files (Quick Reference)

| File | Description |
|------|-------------|
| `model.proto` | Core ML model definitions and inference |
| `agent.proto` | Autonomous agent system and task execution |
| `vision.proto` | Computer vision and asset analysis |
| `nlp.proto` | Natural language processing services |
| `content.proto` | Generative AI for game assets |
| `endpoint.proto` | Unified data access and URI resolution |
| `node-registry.proto` | Distributed node management |
| `composition.proto` | Scene/resource composition |

## Integration

These protocols are designed to integrate with:

- **Cryo** - Asset definitions and content libraries
- **Arctic** - Rendering pipeline and content distribution
- **Nuna** - Plugin system for ML model hosting
- **Axon** - Distributed inference and agent coordination
- **synth-cluster-editor** - URI-based resource loading
