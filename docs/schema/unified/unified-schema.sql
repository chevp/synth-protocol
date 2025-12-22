-- =============================================================================
-- UNIFIED ENTITY SCHEMA (SQLite3)
-- =============================================================================
--
-- 1:1 Mapping zu unified-entity.proto und unified-component.proto
--
-- BLOB-Felder enthalten Protobuf-serialisierte Daten, die direkt von:
-- - C++ Renderer gelesen werden können (ParseFromArray)
-- - Java Server gesendet werden können (bereits im Wire-Format)
--
-- =============================================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- =============================================================================
-- FILE METADATA
-- =============================================================================

CREATE TABLE IF NOT EXISTS file_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

INSERT OR REPLACE INTO file_metadata (key, value) VALUES
    ('magic', 'UNIFIED'),
    ('format_version', '1'),
    ('schema_version', '1.0.0'),
    ('created_at', strftime('%s', 'now') * 1000);

-- =============================================================================
-- SCENES
-- Proto: Scene message
-- =============================================================================

CREATE TABLE IF NOT EXISTS scenes (
    -- EntityId fields
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),

    -- Scene fields
    name TEXT NOT NULL,
    description TEXT,

    -- Proto-serialized BLOBs (SceneSettings, EnvironmentSettings)
    settings_blob BLOB,                     -- Proto: SceneSettings
    environment_blob BLOB,                  -- Proto: EnvironmentSettings

    -- Thumbnail
    thumbnail_blob BLOB                     -- PNG image
);

CREATE INDEX idx_scenes_name ON scenes(name);

-- =============================================================================
-- ENTITIES
-- Proto: Entity message
-- =============================================================================

CREATE TABLE IF NOT EXISTS entities (
    -- ==========================================================================
    -- ENTITY: Container für Components
    -- ==========================================================================
    -- Eine Entity ist ein Container der Components gruppiert.
    -- Alle Daten (Transform, Mesh, Script, StateMachine) sind Components.
    -- Entities können hierarchisch verschachtelt sein (parent_uuid).
    -- ==========================================================================

    -- Identification
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),

    -- Basic Info
    name TEXT NOT NULL,
    entity_type TEXT,                       -- Optional: "player", "npc", "prop", "light", etc.
    state INTEGER NOT NULL DEFAULT 1,       -- 1=ACTIVE, 2=INACTIVE, 3=HIDDEN, 4=DELETED

    -- ==========================================================================
    -- HIERARCHY
    -- ==========================================================================
    -- Entities können beliebig tief verschachtelt sein.
    -- parent_uuid = NULL bedeutet Root-Entity in der Scene.
    -- Child-Entities erben Transform von Parent (wenn beide Transform haben).
    -- ==========================================================================
    parent_uuid TEXT,                       -- FK to entities (NULL = root)
    sibling_order INTEGER NOT NULL DEFAULT 0, -- Sortierung unter Siblings

    -- Scene reference (optional - für Scene-Root-Entities)
    scene_uuid TEXT,                        -- FK to scenes

    -- Metadata (Editor-spezifisch: collapsed, locked, color, etc.)
    metadata_json TEXT,

    -- Foreign Keys
    FOREIGN KEY (parent_uuid) REFERENCES entities(uuid) ON DELETE CASCADE,
    FOREIGN KEY (scene_uuid) REFERENCES scenes(uuid) ON DELETE CASCADE
);

CREATE INDEX idx_entities_scene ON entities(scene_uuid);
CREATE INDEX idx_entities_parent ON entities(parent_uuid);
CREATE INDEX idx_entities_type ON entities(entity_type);
CREATE INDEX idx_entities_state ON entities(state);

-- =============================================================================
-- COMPONENTS
-- Proto: Component messages (MeshComponent, PhysicsComponent, etc.)
-- =============================================================================

CREATE TABLE IF NOT EXISTS components (
    -- EntityId fields
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),

    -- Component fields
    entity_uuid TEXT NOT NULL,              -- FK to entities
    component_type TEXT NOT NULL,           -- "mesh", "physics", "light", "camera", "script", etc.
    enabled INTEGER NOT NULL DEFAULT 1,     -- Boolean

    -- ==========================================================================
    -- FLEXIBLE DATA STORAGE
    -- ==========================================================================
    --
    -- content_type: MIME-Type oder Format-Identifier
    --   - "application/xml"           -> XML Component
    --   - "text/x-lua"                -> Lua Script
    --   - "text/x-glsl"               -> GLSL Shader
    --   - "application/json"          -> JSON Config
    --   - "application/x-protobuf"    -> Proto Binary (cached)
    --
    -- data_text: Human-readable Source (XML, Lua, GLSL, JSON, etc.)
    --   - Direkt editierbar
    --   - Git-versionierbar
    --   - Validierbar
    --
    -- data_blob: Binary Cache (optional)
    --   - Compiled Shader bytecode
    --   - Proto-serialized für Runtime
    --   - NULL wenn nicht generiert
    --
    content_type TEXT NOT NULL DEFAULT 'application/xml',
    data_text TEXT NOT NULL,                -- Source: XML, Lua, GLSL, JSON, etc.
    data_blob BLOB,                         -- Binary Cache (optional)

    -- Schema version für Migration
    schema_version TEXT DEFAULT '1.0.0',

    -- Foreign Keys
    FOREIGN KEY (entity_uuid) REFERENCES entities(uuid) ON DELETE CASCADE
);

CREATE INDEX idx_components_entity ON components(entity_uuid);
CREATE INDEX idx_components_type ON components(component_type);
CREATE UNIQUE INDEX idx_components_entity_type ON components(entity_uuid, component_type);

-- =============================================================================
-- ASSETS
-- Referenzen zu externen Dateien (GLTF, Texturen, Audio, etc.)
-- =============================================================================

CREATE TABLE IF NOT EXISTS assets (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),

    -- Asset info
    name TEXT NOT NULL,
    asset_type INTEGER NOT NULL,            -- AssetType enum
    source_path TEXT,                       -- Original file path
    uri TEXT,                               -- asset://project/...

    -- Embedded data (für kleine Assets)
    data_blob BLOB,

    -- Metadata
    size_bytes INTEGER,
    checksum TEXT,                          -- SHA256
    metadata_json TEXT
);

-- AssetType enum values:
-- 0 = UNSPECIFIED
-- 1 = MESH (GLTF, OBJ, FBX)
-- 2 = TEXTURE (PNG, JPG, KTX2)
-- 3 = MATERIAL
-- 4 = SHADER
-- 5 = AUDIO (WAV, OGG, MP3)
-- 6 = SCRIPT (Lua)
-- 7 = ANIMATION
-- 8 = PARTICLE_SYSTEM
-- 9 = FONT
-- 10 = PREFAB

CREATE INDEX idx_assets_type ON assets(asset_type);
CREATE INDEX idx_assets_uri ON assets(uri);
CREATE INDEX idx_assets_name ON assets(name);

-- =============================================================================
-- STATE MACHINE DEFINITIONS
-- =============================================================================
-- State Machines sind COMPONENTS mit component_type = 'state_machine'
-- Keine separate Tabelle nötig!
--
-- Beispiel in components:
--   component_type = 'state_machine'
--   content_type = 'application/xml'
--   data_text = '<state-machine name="movement" initial="IDLE">...</state-machine>'
--
-- Siehe: component-formats/examples/state-machine.xml
-- =============================================================================

-- =============================================================================
-- TAGS
-- =============================================================================

CREATE TABLE IF NOT EXISTS tags (
    uuid TEXT PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),

    name TEXT NOT NULL UNIQUE,
    color TEXT,                             -- Hex color
    category TEXT
);

CREATE TABLE IF NOT EXISTS entity_tags (
    entity_uuid TEXT NOT NULL,
    tag_uuid TEXT NOT NULL,
    PRIMARY KEY (entity_uuid, tag_uuid),
    FOREIGN KEY (entity_uuid) REFERENCES entities(uuid) ON DELETE CASCADE,
    FOREIGN KEY (tag_uuid) REFERENCES tags(uuid) ON DELETE CASCADE
);

-- =============================================================================
-- VIEWS
-- =============================================================================

-- Alle aktiven Entities
CREATE VIEW IF NOT EXISTS v_entities_active AS
SELECT
    e.uuid,
    e.name,
    e.entity_type,
    e.state,
    e.parent_uuid,
    e.sibling_order,
    e.scene_uuid,
    s.name as scene_name
FROM entities e
LEFT JOIN scenes s ON e.scene_uuid = s.uuid
WHERE e.state = 1;  -- Only ACTIVE

-- Entities mit allen Components
CREATE VIEW IF NOT EXISTS v_entities_with_components AS
SELECT
    e.uuid as entity_uuid,
    e.name as entity_name,
    e.entity_type,
    e.parent_uuid,
    e.scene_uuid,
    c.uuid as component_uuid,
    c.component_type,
    c.content_type,
    c.data_text,
    c.data_blob
FROM entities e
LEFT JOIN components c ON e.uuid = c.entity_uuid
WHERE e.state = 1;  -- Only ACTIVE

-- Scene hierarchy mit Child-Count
CREATE VIEW IF NOT EXISTS v_scene_hierarchy AS
SELECT
    e.uuid,
    e.name,
    e.entity_type,
    e.parent_uuid,
    e.sibling_order,
    e.scene_uuid,
    (
        SELECT COUNT(*)
        FROM entities c
        WHERE c.parent_uuid = e.uuid AND c.state = 1
    ) as child_count
FROM entities e
WHERE e.state = 1
ORDER BY e.scene_uuid, e.parent_uuid NULLS FIRST, e.sibling_order;

-- Recursive CTE für komplette Hierarchie (mit Tiefe)
CREATE VIEW IF NOT EXISTS v_entity_tree AS
WITH RECURSIVE entity_tree AS (
    -- Root entities (no parent)
    SELECT
        uuid,
        name,
        entity_type,
        parent_uuid,
        sibling_order,
        scene_uuid,
        0 as depth,
        uuid as root_uuid
    FROM entities
    WHERE parent_uuid IS NULL AND state = 1

    UNION ALL

    -- Child entities
    SELECT
        e.uuid,
        e.name,
        e.entity_type,
        e.parent_uuid,
        e.sibling_order,
        e.scene_uuid,
        t.depth + 1,
        t.root_uuid
    FROM entities e
    INNER JOIN entity_tree t ON e.parent_uuid = t.uuid
    WHERE e.state = 1
)
SELECT * FROM entity_tree
ORDER BY scene_uuid, root_uuid, depth, sibling_order;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Auto-update updated_at
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

CREATE TRIGGER IF NOT EXISTS tr_scenes_updated_at
AFTER UPDATE ON scenes
BEGIN
    UPDATE scenes SET updated_at = strftime('%s', 'now') * 1000
    WHERE uuid = NEW.uuid;
END;

CREATE TRIGGER IF NOT EXISTS tr_assets_updated_at
AFTER UPDATE ON assets
BEGIN
    UPDATE assets SET updated_at = strftime('%s', 'now') * 1000
    WHERE uuid = NEW.uuid;
END;

-- =============================================================================
-- EXAMPLE DATA (for testing)
-- =============================================================================

-- Uncomment to insert test data:
/*
INSERT INTO scenes (uuid, name, description) VALUES
    ('scene-001', 'Main Level', 'The main game level');

INSERT INTO entities (uuid, name, entity_type, scene_uuid, transform_blob, current_state, state_machine_id) VALUES
    ('player-001', 'Player', 1, 'scene-001', X'', 'CHARACTER_IDLE', 'movement'),
    ('npc-001', 'Guard', 2, 'scene-001', X'', 'NPC_PATROL', 'npc_behavior');
*/
