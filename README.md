# Synth Protocol

Protocol Buffer schemas for the Synth AI/ML ecosystem.

## Overview

This module defines the gRPC service interfaces and message types for:

- **Model Management** - ML model definitions, parameters, and requirements
- **Agent System** - Autonomous AI agents, tasks, and inter-agent communication
- **Vision** - Image analysis, asset classification, and computer vision
- **NLP** - Text processing, generation, and semantic search
- **Content Generation** - Texture, material, and asset generation for Cryo/Arctic

## Proto Files

| File | Description |
|------|-------------|
| `model.proto` | Core ML model definitions and inference |
| `agent.proto` | Autonomous agent system and task execution |
| `vision.proto` | Computer vision and asset analysis |
| `nlp.proto` | Natural language processing services |
| `content.proto` | Generative AI for game assets |

## Build

```bash
mvn clean compile
```

## Usage

Add as dependency in other Synth modules:

```xml
<dependency>
    <groupId>io.synth</groupId>
    <artifactId>synth-protocol</artifactId>
    <version>1.0.0-SNAPSHOT</version>
</dependency>
```

## Integration

These protocols are designed to integrate with:

- **Cryo** - Asset definitions and content libraries
- **Arctic** - Rendering pipeline and content distribution
- **Nuna** - Plugin system for ML model hosting
- **Axon** - Distributed inference and agent coordination
