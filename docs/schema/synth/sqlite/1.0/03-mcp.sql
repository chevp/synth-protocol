-- =============================================================================
-- SYNTH PROTOCOL - MCP Schema
-- Maps to: mcp.xsd (Model Context Protocol)
-- =============================================================================

-- =============================================================================
-- MCP SERVERS
-- Maps to: ServersType, ServerType
-- =============================================================================

CREATE TABLE IF NOT EXISTS mcp_servers (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    name TEXT,
    version TEXT,
    description TEXT,
    enabled INTEGER NOT NULL DEFAULT 1,
    server_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE INDEX idx_mcp_servers_project ON mcp_servers(project_id);

-- =============================================================================
-- TRANSPORT - STDIO
-- Maps to: StdioTransportType
-- =============================================================================

CREATE TABLE IF NOT EXISTS mcp_transport_stdio (
    server_id TEXT PRIMARY KEY,
    command TEXT NOT NULL,
    work_dir TEXT,
    FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mcp_transport_stdio_args (
    server_id TEXT NOT NULL,
    arg_index INTEGER NOT NULL,
    arg_value TEXT NOT NULL,
    PRIMARY KEY (server_id, arg_index),
    FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mcp_transport_stdio_env (
    server_id TEXT NOT NULL,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (server_id, name),
    FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE
);

-- =============================================================================
-- TRANSPORT - HTTP
-- Maps to: HttpTransportType
-- =============================================================================

CREATE TABLE IF NOT EXISTS mcp_transport_http (
    server_id TEXT PRIMARY KEY,
    base_url TEXT NOT NULL,
    timeout INTEGER NOT NULL DEFAULT 30000,
    FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mcp_transport_http_headers (
    server_id TEXT NOT NULL,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (server_id, name),
    FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE
);

-- =============================================================================
-- TRANSPORT - SSE
-- Maps to: SseTransportType
-- =============================================================================

CREATE TABLE IF NOT EXISTS mcp_transport_sse (
    server_id TEXT PRIMARY KEY,
    url TEXT NOT NULL,
    FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mcp_transport_sse_headers (
    server_id TEXT NOT NULL,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (server_id, name),
    FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE
);

-- =============================================================================
-- MCP TOOLS
-- Maps to: ToolsType, ToolType
-- =============================================================================

CREATE TABLE IF NOT EXISTS mcp_tools (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    schema_type TEXT NOT NULL DEFAULT 'object',
    tool_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE,
    UNIQUE (server_id, name)
);

CREATE TABLE IF NOT EXISTS mcp_tool_properties (
    tool_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    prop_type TEXT NOT NULL,
    description TEXT,
    default_value TEXT,
    prop_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (tool_id, name),
    FOREIGN KEY (tool_id) REFERENCES mcp_tools(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mcp_tool_property_enum (
    tool_id INTEGER NOT NULL,
    property_name TEXT NOT NULL,
    enum_index INTEGER NOT NULL,
    enum_value TEXT NOT NULL,
    PRIMARY KEY (tool_id, property_name, enum_index),
    FOREIGN KEY (tool_id, property_name) REFERENCES mcp_tool_properties(tool_id, name) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mcp_tool_required (
    tool_id INTEGER NOT NULL,
    field_name TEXT NOT NULL,
    PRIMARY KEY (tool_id, field_name),
    FOREIGN KEY (tool_id) REFERENCES mcp_tools(id) ON DELETE CASCADE
);

CREATE INDEX idx_mcp_tools_server ON mcp_tools(server_id);
CREATE INDEX idx_mcp_tools_name ON mcp_tools(name);

-- =============================================================================
-- MCP RESOURCES
-- Maps to: ResourcesType, ResourceType
-- =============================================================================

CREATE TABLE IF NOT EXISTS mcp_resources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id TEXT NOT NULL,
    uri TEXT NOT NULL,
    name TEXT,
    mime_type TEXT,
    description TEXT,
    resource_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE
);

CREATE INDEX idx_mcp_resources_server ON mcp_resources(server_id);
CREATE INDEX idx_mcp_resources_uri ON mcp_resources(uri);

-- =============================================================================
-- MCP PROMPTS
-- Maps to: PromptsType, PromptType
-- =============================================================================

CREATE TABLE IF NOT EXISTS mcp_prompts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    prompt_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE,
    UNIQUE (server_id, name)
);

CREATE TABLE IF NOT EXISTS mcp_prompt_arguments (
    prompt_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    required INTEGER NOT NULL DEFAULT 0,
    arg_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (prompt_id, name),
    FOREIGN KEY (prompt_id) REFERENCES mcp_prompts(id) ON DELETE CASCADE
);

CREATE INDEX idx_mcp_prompts_server ON mcp_prompts(server_id);