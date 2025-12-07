# Nuna Protocol

Protocol Buffer definitions for the Nuna Closed Monolith Plugin System.

## Design Principles

1. **Access Only via Tooling** - All system interaction goes through MCP tools (reduced degrees of freedom)
2. **File-Embedded Configuration** - Plugin/MCP config stored in project files, not separate manifest files
3. **SQLite3 Compatible** - All messages designed for efficient SQLite storage
4. **ECS Architecture** - Entity-Component-System data model
5. **Dynamic Permissions** - Permissions derived from active MCP server capabilities

## Protocol Files

| File | Package | Purpose |
|------|---------|---------|
| `core.proto` | `nuna.core` | ECS fundamentals: Entity, Component, System, Tags |
| `project.proto` | `nuna.project` | Project file format, MCP/plugin requirements |
| `mcp.proto` | `nuna.mcp` | MCP server management, tool registry, invocation |
| `security.proto` | `nuna.security` | Permissions, sandbox, trust, audit |

## SQLite3 Table Mapping

```
┌─────────────────────────────────────────────────────────────────┐
│                     .nuna PROJECT FILE (SQLite3)                │
├─────────────────────────────────────────────────────────────────┤
│ TABLE project           ← nuna.project.Project                  │
│ TABLE mcp_servers       ← nuna.project.McpServerRequirement     │
│ TABLE plugins           ← nuna.project.PluginRequirement        │
│ TABLE ribbon_config     ← nuna.project.RibbonConfiguration      │
│ TABLE scenes            ← nuna.project.Scene                    │
│ TABLE assets            ← nuna.project.Asset                    │
│ TABLE entities          ← nuna.core.Entity                      │
│ TABLE components        ← nuna.core.Component                   │
│ TABLE tags              ← nuna.core.Tag                         │
│ TABLE relationships     ← nuna.core.Relationship                │
├─────────────────────────────────────────────────────────────────┤
│                     RUNTIME TABLES (in-memory)                  │
├─────────────────────────────────────────────────────────────────┤
│ TABLE mcp_server_registry ← nuna.mcp.McpServer                  │
│ TABLE mcp_tools           ← nuna.mcp.McpTool                    │
│ TABLE tool_history        ← nuna.mcp.ToolHistoryEntry           │
│ TABLE permissions         ← nuna.security.Permission            │
│ TABLE security_audit      ← nuna.security.SecurityAuditEntry    │
└─────────────────────────────────────────────────────────────────┘
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CLOSED MONOLITH CORE                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                        MCP Server Manager                             │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  │
│  │  │   Start/    │  │  Discover   │  │   Health    │  │  Permission │   │  │
│  │  │   Stop      │  │   Tools     │  │   Check     │  │   Gateway   │   │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                      │                                      │
│                    ┌─────────────────┼─────────────────┐                    │
│                    ▼                 ▼                 ▼                    │
│            ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│            │ MCP Server A │  │ MCP Server B │  │ MCP Server C │             │
│            │  (vision)    │  │   (nlp)      │  │  (custom)    │             │
│            ├──────────────┤  ├──────────────┤  ├──────────────┤             │
│            │ Tools:       │  │ Tools:       │  │ Tools:       │             │
│            │ • analyze    │  │ • summarize  │  │ • my_tool    │             │
│            │ • detect     │  │ • translate  │  │ • other_tool │             │
│            └──────────────┘  └──────────────┘  └──────────────┘             │
│                    │                 │                 │                    │
│                    └─────────────────┼─────────────────┘                    │
│                                      ▼                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                         Tool Executor                                 │  │
│  │  • All system access goes through tool invocation                     │  │
│  │  • Audit log for every action                                         │  │
│  │  • Undo/Redo support                                                  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                      │                                      │
│                                      ▼                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                        ECS Data Model                                 │  │
│  │  ┌─────────┐  ┌────────────┐  ┌──────────┐  ┌────────────────┐        │  │
│  │  │ Entity  │──│ Component  │  │  System  │  │  Relationship  │        │  │
│  │  └─────────┘  └────────────┘  └──────────┘  └────────────────┘        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                      │                                      │
│                                      ▼                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                      SQLite3 Storage (.nuna file)                     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Concepts

### 1. ECS (Entity-Component-System)

- **Entity**: Container with UUID, holds components
- **Component**: Data attached to entity (transform, mesh, script)
- **System**: Logic that processes entities with specific components

### 2. MCP as Plugin Runtime

Each plugin provides an MCP server that:
- Reports available tools via `tools/list`
- Reports capabilities (permissions needed)
- Defines its ribbon tab/groups
- Executes tools in sandboxed environment

### 3. Dynamic UI (Ribbon)

Ribbon tabs are dynamically built from:
1. Active MCP servers
2. Their reported tools
3. Tool context conditions (show/enable when)

### 4. Permission Flow

```
File Opened
    │
    ▼
Parse <mcp-servers> section
    │
    ▼
Start required servers
    │
    ▼
Query each server for capabilities
    │
    ▼
Aggregate permissions needed
    │
    ▼
Build security context
    │
    ▼
UI reflects allowed actions
```

## Usage

### Java Generation

```xml
<plugin>
    <groupId>org.xolstice.maven.plugins</groupId>
    <artifactId>protobuf-maven-plugin</artifactId>
    <configuration>
        <protoSourceRoot>src/main/proto</protoSourceRoot>
    </configuration>
</plugin>
```

### SQLite Storage

Messages are stored as BLOB columns:
```sql
CREATE TABLE entities (
    id TEXT PRIMARY KEY,
    version INTEGER,
    created_at INTEGER,
    updated_at INTEGER,
    data BLOB  -- Serialized nuna.core.Entity
);
```

Or denormalized for queries:
```sql
CREATE TABLE entities (
    uuid TEXT PRIMARY KEY,
    version INTEGER,
    name TEXT,
    type TEXT,
    state INTEGER,
    parent_id TEXT,
    metadata BLOB,
    created_at INTEGER,
    updated_at INTEGER
);
```
