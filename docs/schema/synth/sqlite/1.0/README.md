# Synth Protocol - SQLite Schema 1.0

SQLite-Schema für das Dist-Format von Synth-Projekten.

## Übersicht

```
Source (XML)              Build              Dist (SQLite)
─────────────────────     ─────►     ─────────────────────
project.synth.xml                    project.synth.db
├── Editierbar                       ├── Kompakt
├── Git-Diff-freundlich              ├── Runtime-optimiert
└── Claude-kompatibel                └── Schneller Zugriff
```

## Schema-Dateien

| Datei | Beschreibung |
|-------|--------------|
| `00-init.sql` | Initialisierung, Pragmas, Metadata-Tabelle |
| `01-project.sql` | Projekt-Struktur (project.xsd) |
| `02-core.sql` | Core-Konfiguration (core.xsd) |
| `03-mcp.sql` | MCP-Server und Tools (mcp.xsd) |
| `04-security.sql` | Security-Konfiguration (security.xsd) |
| `05-views.sql` | Convenience-Views für Abfragen |
| `06-triggers.sql` | Auto-Update Trigger |

## Verwendung

### Datenbank erstellen

```bash
# Alle Schema-Dateien in Reihenfolge ausführen
cat 0*.sql | sqlite3 project.synth.db
```

### Build-Integration (synth-sdk-dev)

```bash
# XML → SQLite
synth-sdk-dev build

# Liest:  src/project.synth.xml
# Schreibt: dist/project.synth.db
```

## Mapping: XSD → SQLite

### project.xsd

| XSD Element | SQLite Tabelle |
|-------------|----------------|
| `synthProject` | `project` |
| `metadata` | `project_metadata`, `project_tags` |
| `plugins/plugin` | `plugins`, `plugin_config` |
| `pipelines/pipeline` | `pipelines`, `pipeline_steps` |
| `resources/resource` | `resources`, `resource_metadata` |

### core.xsd

| XSD Element | SQLite Tabelle |
|-------------|----------------|
| `configuration` | `configuration` |
| `runtime` | `runtime` |
| `logging` | `logging`, `log_appenders` |
| `metrics` | `metrics`, `metrics_exporters` |
| `environment` | `environment_vars` |

### mcp.xsd

| XSD Element | SQLite Tabelle |
|-------------|----------------|
| `servers/server` | `mcp_servers` |
| `transport/stdio` | `mcp_transport_stdio` |
| `transport/http` | `mcp_transport_http` |
| `transport/sse` | `mcp_transport_sse` |
| `tools/tool` | `mcp_tools`, `mcp_tool_properties` |
| `resources` | `mcp_resources` |
| `prompts` | `mcp_prompts`, `mcp_prompt_arguments` |

### security.xsd

| XSD Element | SQLite Tabelle |
|-------------|----------------|
| `security` | `security` |
| `authentication` | `authentication`, `auth_providers` |
| `authorization` | `authorization`, `policies`, `roles` |
| `encryption` | `encryption_at_rest`, `encryption_in_transit` |
| `audit` | `audit`, `audit_events`, `audit_destination` |

## Views

| View | Beschreibung |
|------|--------------|
| `v_project_overview` | Projekt-Zusammenfassung |
| `v_mcp_servers_full` | MCP-Server mit Transport-Details |
| `v_pipeline_structure` | Pipeline mit Steps |
| `v_security_overview` | Security-Konfiguration |
| `v_resources_by_type` | Ressourcen gruppiert nach Typ |
| `v_mcp_tools_full` | MCP-Tools mit Schema |