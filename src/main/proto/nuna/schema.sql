-- =============================================================================
-- NUNA PROJECT FILE SCHEMA (SQLite3)
-- Generated from nuna/*.proto definitions
-- =============================================================================

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- =============================================================================
-- PROJECT METADATA
-- =============================================================================

CREATE TABLE IF NOT EXISTS project (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    name TEXT NOT NULL,
    description TEXT,
    schema_version TEXT NOT NULL DEFAULT '1.0.0',
    settings_json TEXT,                     -- ProjectSettings as JSON
    last_opened_at INTEGER,
    last_opened_by TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- =============================================================================
-- MCP SERVER REQUIREMENTS
-- Servers this project needs
-- =============================================================================

CREATE TABLE IF NOT EXISTS mcp_servers (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    server_name TEXT NOT NULL,
    server_version TEXT NOT NULL,
    required INTEGER NOT NULL DEFAULT 1,    -- boolean
    marketplace_source INTEGER NOT NULL DEFAULT 1, -- MarketplaceSource enum
    config_json TEXT,                       -- McpServerConfig as JSON
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE INDEX idx_mcp_servers_name ON mcp_servers(server_name);

-- =============================================================================
-- PLUGIN REQUIREMENTS
-- Plugins (JARs) this project needs
-- =============================================================================

CREATE TABLE IF NOT EXISTS plugins (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    artifact TEXT NOT NULL,                 -- e.g., "io.synth:image-processor:1.2.0"
    plugin_type INTEGER NOT NULL DEFAULT 1, -- PluginType enum
    marketplace_source INTEGER NOT NULL DEFAULT 1,
    mcp_bridge_server_id TEXT,              -- FK to mcp_servers
    provides_mcp_server INTEGER NOT NULL DEFAULT 0,
    config_blob BLOB,                       -- Plugin-specific config
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (mcp_bridge_server_id) REFERENCES mcp_servers(uuid)
);

CREATE INDEX idx_plugins_artifact ON plugins(artifact);

-- =============================================================================
-- RIBBON CONFIGURATION
-- UI ribbon tabs and tools mapping
-- =============================================================================

CREATE TABLE IF NOT EXISTS ribbon_tabs (
    id TEXT PRIMARY KEY,
    label TEXT NOT NULL,
    icon TEXT,
    tab_order INTEGER NOT NULL DEFAULT 0,
    mcp_server_id TEXT,
    accent_color TEXT,
    is_dev_tab INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (mcp_server_id) REFERENCES mcp_servers(uuid)
);

CREATE TABLE IF NOT EXISTS ribbon_groups (
    id TEXT PRIMARY KEY,
    tab_id TEXT NOT NULL,
    label TEXT NOT NULL,
    group_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (tab_id) REFERENCES ribbon_tabs(id)
);

CREATE TABLE IF NOT EXISTS ribbon_tools (
    id TEXT PRIMARY KEY,
    group_id TEXT NOT NULL,
    mcp_tool_name TEXT NOT NULL,
    icon TEXT,
    label TEXT NOT NULL,
    size INTEGER NOT NULL DEFAULT 1,        -- ToolSize enum
    shortcut TEXT,
    visibility_json TEXT,                   -- ToolVisibility as JSON
    tool_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (group_id) REFERENCES ribbon_groups(id)
);

CREATE INDEX idx_ribbon_tools_mcp ON ribbon_tools(mcp_tool_name);

-- =============================================================================
-- ECS: ENTITIES
-- =============================================================================

CREATE TABLE IF NOT EXISTS entities (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    name TEXT NOT NULL,
    entity_type TEXT NOT NULL,              -- e.g., "scene", "asset", "node"
    state INTEGER NOT NULL DEFAULT 1,       -- EntityState enum
    parent_id TEXT,                         -- FK to entities (nullable)
    metadata_json TEXT,                     -- Extensible metadata
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (parent_id) REFERENCES entities(uuid)
);

CREATE INDEX idx_entities_type ON entities(entity_type);
CREATE INDEX idx_entities_parent ON entities(parent_id);
CREATE INDEX idx_entities_state ON entities(state);

-- =============================================================================
-- ECS: COMPONENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS components (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    entity_id TEXT NOT NULL,                -- FK to entities
    component_type TEXT NOT NULL,           -- e.g., "transform", "mesh", "script"
    state INTEGER NOT NULL DEFAULT 1,       -- ComponentState enum
    data_blob BLOB,                         -- Serialized component data
    schema_version TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (entity_id) REFERENCES entities(uuid) ON DELETE CASCADE
);

CREATE INDEX idx_components_entity ON components(entity_id);
CREATE INDEX idx_components_type ON components(component_type);
CREATE UNIQUE INDEX idx_components_entity_type ON components(entity_id, component_type);

-- =============================================================================
-- ECS: SYSTEMS
-- =============================================================================

CREATE TABLE IF NOT EXISTS systems (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    name TEXT NOT NULL,
    mcp_server_id TEXT NOT NULL,            -- Which MCP server provides this
    state INTEGER NOT NULL DEFAULT 1,       -- SystemState enum
    priority INTEGER NOT NULL DEFAULT 0,
    required_components_json TEXT,          -- Array of component types
    config_blob BLOB,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (mcp_server_id) REFERENCES mcp_servers(uuid)
);

CREATE INDEX idx_systems_server ON systems(mcp_server_id);

-- =============================================================================
-- ECS: TAGS
-- =============================================================================

CREATE TABLE IF NOT EXISTS tags (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    name TEXT NOT NULL UNIQUE,
    color TEXT,
    category TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS entity_tags (
    entity_id TEXT NOT NULL,
    tag_id TEXT NOT NULL,
    PRIMARY KEY (entity_id, tag_id),
    FOREIGN KEY (entity_id) REFERENCES entities(uuid) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(uuid) ON DELETE CASCADE
);

-- =============================================================================
-- ECS: RELATIONSHIPS
-- =============================================================================

CREATE TABLE IF NOT EXISTS relationships (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    source_id TEXT NOT NULL,                -- FK to entities
    target_id TEXT NOT NULL,                -- FK to entities
    relationship_type INTEGER NOT NULL,      -- RelationshipType enum
    metadata_json TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (source_id) REFERENCES entities(uuid) ON DELETE CASCADE,
    FOREIGN KEY (target_id) REFERENCES entities(uuid) ON DELETE CASCADE
);

CREATE INDEX idx_relationships_source ON relationships(source_id);
CREATE INDEX idx_relationships_target ON relationships(target_id);
CREATE INDEX idx_relationships_type ON relationships(relationship_type);

-- =============================================================================
-- SCENES
-- =============================================================================

CREATE TABLE IF NOT EXISTS scenes (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    name TEXT NOT NULL,
    description TEXT,
    settings_json TEXT,                     -- SceneSettings as JSON
    thumbnail_blob BLOB,                    -- PNG thumbnail
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS scene_root_entities (
    scene_id TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    entity_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (scene_id, entity_id),
    FOREIGN KEY (scene_id) REFERENCES scenes(uuid) ON DELETE CASCADE,
    FOREIGN KEY (entity_id) REFERENCES entities(uuid) ON DELETE CASCADE
);

-- =============================================================================
-- ASSETS
-- =============================================================================

CREATE TABLE IF NOT EXISTS assets (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    name TEXT NOT NULL,
    asset_type INTEGER NOT NULL,            -- AssetType enum
    source_path TEXT,
    uri TEXT,                               -- asset://project/assets/...
    data_blob BLOB,                         -- Embedded data (if small)
    size_bytes INTEGER,
    checksum TEXT,                          -- SHA256
    metadata_json TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE INDEX idx_assets_type ON assets(asset_type);
CREATE INDEX idx_assets_uri ON assets(uri);

-- =============================================================================
-- RUNTIME TABLES (in-memory, recreated on load)
-- =============================================================================

-- Active MCP servers
CREATE TABLE IF NOT EXISTS mcp_server_registry (
    uuid TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    version TEXT,
    state INTEGER NOT NULL DEFAULT 1,       -- McpServerState enum
    capabilities_json TEXT,
    connection_json TEXT,
    started_at INTEGER,
    last_health_check INTEGER
);

-- Discovered tools from active servers
CREATE TABLE IF NOT EXISTS mcp_tools (
    uuid TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    server_id TEXT NOT NULL,
    description TEXT,
    input_schema_json TEXT,
    output_schema_json TEXT,
    state INTEGER NOT NULL DEFAULT 1,       -- McpToolState enum
    ribbon_binding_json TEXT,               -- RibbonToolBinding as JSON
    required_permissions_json TEXT,
    FOREIGN KEY (server_id) REFERENCES mcp_server_registry(uuid)
);

CREATE INDEX idx_mcp_tools_server ON mcp_tools(server_id);
CREATE INDEX idx_mcp_tools_name ON mcp_tools(name);

-- Tool invocation history (for undo/redo and audit)
CREATE TABLE IF NOT EXISTS tool_history (
    uuid TEXT PRIMARY KEY,
    invocation_id TEXT NOT NULL,
    tool_name TEXT NOT NULL,
    server_id TEXT NOT NULL,
    parameters_json TEXT,
    context_json TEXT,
    result_json TEXT,
    success INTEGER NOT NULL,
    error_json TEXT,
    execution_time_ms INTEGER,
    undo_data_blob BLOB,
    undoable INTEGER NOT NULL DEFAULT 0,
    was_undone INTEGER NOT NULL DEFAULT 0,
    user_id TEXT,
    timestamp INTEGER NOT NULL
);

CREATE INDEX idx_tool_history_tool ON tool_history(tool_name);
CREATE INDEX idx_tool_history_timestamp ON tool_history(timestamp);

-- =============================================================================
-- SECURITY TABLES
-- =============================================================================

-- Granted permissions for this session
CREATE TABLE IF NOT EXISTS permissions (
    uuid TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category INTEGER NOT NULL,              -- PermissionCategory enum
    scope_json TEXT,                        -- PermissionScope as JSON
    description TEXT,
    risk_level INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS granted_permissions (
    permission_id TEXT NOT NULL,
    granted_by TEXT NOT NULL,
    granted_at INTEGER NOT NULL,
    session_only INTEGER NOT NULL DEFAULT 1,
    remember INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (permission_id),
    FOREIGN KEY (permission_id) REFERENCES permissions(uuid)
);

-- Security audit log
CREATE TABLE IF NOT EXISTS security_audit (
    uuid TEXT PRIMARY KEY,
    event_type INTEGER NOT NULL,            -- SecurityEventType enum
    actor TEXT NOT NULL,
    target TEXT,
    permission_used TEXT,
    success INTEGER NOT NULL,
    details TEXT,
    timestamp INTEGER NOT NULL
);

CREATE INDEX idx_security_audit_type ON security_audit(event_type);
CREATE INDEX idx_security_audit_timestamp ON security_audit(timestamp);
CREATE INDEX idx_security_audit_actor ON security_audit(actor);

-- Plugin trust levels
CREATE TABLE IF NOT EXISTS plugin_trust (
    uuid TEXT PRIMARY KEY,
    plugin_id TEXT NOT NULL UNIQUE,
    trust_level INTEGER NOT NULL DEFAULT 1, -- TrustLevel enum
    signature TEXT,
    signed_by TEXT,
    verified INTEGER NOT NULL DEFAULT 0,
    verified_at INTEGER,
    trust_chain_json TEXT
);

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- All entities with their components
CREATE VIEW IF NOT EXISTS v_entities_with_components AS
SELECT
    e.uuid as entity_id,
    e.name as entity_name,
    e.entity_type,
    e.state as entity_state,
    e.parent_id,
    c.uuid as component_id,
    c.component_type,
    c.state as component_state
FROM entities e
LEFT JOIN components c ON e.uuid = c.entity_id;

-- Active tools with their server info
CREATE VIEW IF NOT EXISTS v_active_tools AS
SELECT
    t.uuid as tool_id,
    t.name as tool_name,
    t.description,
    t.state as tool_state,
    s.uuid as server_id,
    s.name as server_name,
    s.state as server_state
FROM mcp_tools t
JOIN mcp_server_registry s ON t.server_id = s.uuid
WHERE s.state = 3;  -- RUNNING

-- Ribbon structure
CREATE VIEW IF NOT EXISTS v_ribbon_structure AS
SELECT
    t.id as tab_id,
    t.label as tab_label,
    t.tab_order,
    g.id as group_id,
    g.label as group_label,
    g.group_order,
    r.id as tool_id,
    r.mcp_tool_name,
    r.label as tool_label,
    r.tool_order
FROM ribbon_tabs t
JOIN ribbon_groups g ON t.id = g.tab_id
JOIN ribbon_tools r ON g.id = r.group_id
ORDER BY t.tab_order, g.group_order, r.tool_order;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS tr_entities_updated_at
AFTER UPDATE ON entities
BEGIN
    UPDATE entities SET updated_at = strftime('%s', 'now') * 1000
    WHERE uuid = NEW.uuid;
END;

CREATE TRIGGER IF NOT EXISTS tr_components_updated_at
AFTER UPDATE ON components
BEGIN
    UPDATE components SET updated_at = strftime('%s', 'now') * 1000
    WHERE uuid = NEW.uuid;
END;

CREATE TRIGGER IF NOT EXISTS tr_assets_updated_at
AFTER UPDATE ON assets
BEGIN
    UPDATE assets SET updated_at = strftime('%s', 'now') * 1000
    WHERE uuid = NEW.uuid;
END;

-- =============================================================================
-- FILE METADATA
-- Stored in the file itself for quick identification
-- =============================================================================

CREATE TABLE IF NOT EXISTS file_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

INSERT OR REPLACE INTO file_metadata (key, value) VALUES
    ('magic', 'NUNA'),
    ('format_version', '1'),
    ('schema_version', '1.0.0'),
    ('created_at', strftime('%s', 'now') * 1000);
