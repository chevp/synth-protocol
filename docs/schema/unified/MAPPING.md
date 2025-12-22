# Component-Format Mapping

## Übersicht

Dieses Dokument beschreibt das Mapping zwischen Component-Typen, Content-Types und deren Speicherung.

## Prinzip

```
┌─────────────────────────────────────────────────────────────────┐
│                     UNIFIED SCHEMA MAPPING                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Component Type    Content-Type         Storage                 │
│   ──────────────    ────────────         ───────                 │
│   transform    ───► application/xml ───► data_text (XML)         │
│   mesh         ───► application/xml ───► data_text (XML)         │
│   script       ───► text/x-lua      ───► data_text (Lua)         │
│   shader       ───► text/x-glsl     ───► data_text (GLSL)        │
│   state_machine ─►  application/xml ───► data_text (XML)         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Entity Mapping

### entities Tabelle

| Feld | SQLite Type | Beschreibung |
|------|-------------|--------------|
| `uuid` | `TEXT PRIMARY KEY` | UUID string |
| `version` | `INTEGER` | Optimistic locking |
| `created_at` | `INTEGER` | Unix ms |
| `updated_at` | `INTEGER` | Unix ms |
| `name` | `TEXT NOT NULL` | Entity-Name |
| `entity_type` | `TEXT` | Frei definierbar: "player", "npc", "prop", etc. |
| `state` | `INTEGER` | 1=ACTIVE, 2=INACTIVE, 3=HIDDEN, 4=DELETED |
| `parent_uuid` | `TEXT` | FK zu entities, nullable für Root |
| `sibling_order` | `INTEGER` | Sortierung unter Geschwistern |
| `scene_uuid` | `TEXT` | FK zu scenes |
| `metadata_json` | `TEXT` | Editor-Metadaten (collapsed, locked, color, etc.) |

### Hierarchie

```sql
-- Root Entity (parent_uuid = NULL)
INSERT INTO entities (uuid, name, parent_uuid)
VALUES ('world-001', 'World', NULL);

-- Child Entity
INSERT INTO entities (uuid, name, parent_uuid)
VALUES ('player-001', 'Player', 'world-001');

-- Grandchild Entity
INSERT INTO entities (uuid, name, parent_uuid)
VALUES ('weapon-001', 'Sword', 'player-001');
```

## Component Mapping

### components Tabelle

| Feld | SQLite Type | Beschreibung |
|------|-------------|--------------|
| `uuid` | `TEXT PRIMARY KEY` | UUID string |
| `entity_uuid` | `TEXT NOT NULL` | FK zu entities |
| `component_type` | `TEXT NOT NULL` | "transform", "mesh", "script", etc. |
| `enabled` | `INTEGER` | 0 oder 1 |
| `content_type` | `TEXT NOT NULL` | MIME-Type |
| `data_text` | `TEXT NOT NULL` | Human-readable Source |
| `data_blob` | `BLOB` | Optional: Binary Cache |
| `schema_version` | `TEXT` | Für Migrationen |

### Content-Type zu Component-Type Mapping

| component_type | content_type | Beschreibung |
|----------------|--------------|--------------|
| `transform` | `application/xml` | Position, Rotation, Scale |
| `mesh` | `application/xml` | Mesh-Asset Referenz, LOD, Shadows |
| `material` | `application/xml` | Material-Asset Referenz, Properties |
| `light` | `application/xml` | Light-Typ, Farbe, Intensity |
| `camera` | `application/xml` | FOV, Near/Far, Projection |
| `physics` | `application/xml` | Collider, Rigidbody, Constraints |
| `audio` | `application/xml` | Audio-Asset, Volume, Spatial |
| `script` | `text/x-lua` | Lua Gameplay Code |
| `shader` | `text/x-glsl` | GLSL Shader Code |
| `state_machine` | `application/xml` | States, Transitions, Triggers |
| `config` | `application/json` | Beliebige JSON-Konfiguration |

## Entity State Enum

| Wert | Name | Beschreibung |
|------|------|--------------|
| 1 | ACTIVE | Normal, wird gerendert und verarbeitet |
| 2 | INACTIVE | Existiert, aber wird nicht verarbeitet |
| 3 | HIDDEN | Wird nicht gerendert, aber verarbeitet |
| 4 | DELETED | Soft-deleted |

## Beispiele

### Entity mit Transform-Component

```sql
-- Entity erstellen
INSERT INTO entities (uuid, name, entity_type, scene_uuid)
VALUES ('player-001', 'Player', 'player', 'scene-001');

-- Transform-Component hinzufügen
INSERT INTO components (uuid, entity_uuid, component_type, content_type, data_text)
VALUES (
    'comp-transform-001',
    'player-001',
    'transform',
    'application/xml',
    '<component type="transform" version="1.0" xmlns="http://synth.io/component/1.0">
        <position x="0" y="1.5" z="0"/>
        <rotation x="0" y="0" z="0" w="1"/>
        <scale x="1" y="1" z="1"/>
    </component>'
);
```

### Entity mit Lua-Script

```sql
-- Script-Component hinzufügen
INSERT INTO components (uuid, entity_uuid, component_type, content_type, data_text)
VALUES (
    'comp-script-001',
    'player-001',
    'script',
    'text/x-lua',
    '-- Component: script
-- Entity: player-001

local PlayerController = {}
PlayerController.__index = PlayerController

function PlayerController:new(entity)
    local self = setmetatable({}, PlayerController)
    self.entity = entity
    return self
end

function PlayerController:update(deltaTime)
    local moveX = Input.getAxis("Horizontal")
    local moveZ = Input.getAxis("Vertical")
    -- Movement logic...
end

return PlayerController'
);
```

### Entity mit State Machine

```sql
-- State Machine als Component
INSERT INTO components (uuid, entity_uuid, component_type, content_type, data_text)
VALUES (
    'comp-fsm-001',
    'player-001',
    'state_machine',
    'application/xml',
    '<component type="state_machine" version="1.0" xmlns="http://synth.io/component/1.0">
        <state-machine name="movement" initial="IDLE">
            <states>
                <state id="IDLE" display="Idle"/>
                <state id="WALKING" display="Walking"/>
                <state id="RUNNING" display="Running"/>
            </states>
            <transitions>
                <transition from="IDLE" to="WALKING">
                    <triggers><trigger>input_move</trigger></triggers>
                </transition>
                <transition from="WALKING" to="RUNNING">
                    <triggers><trigger>input_sprint</trigger></triggers>
                </transition>
            </transitions>
        </state-machine>
    </component>'
);
```

## C++ Parsing

### XML Components (pugixml)

```cpp
#include <pugixml.hpp>

void loadTransform(const char* xmlText, Transform& out) {
    pugi::xml_document doc;
    doc.load_string(xmlText);

    auto component = doc.child("component");
    auto pos = component.child("position");
    auto rot = component.child("rotation");
    auto scale = component.child("scale");

    out.position = {
        pos.attribute("x").as_float(),
        pos.attribute("y").as_float(),
        pos.attribute("z").as_float()
    };

    out.rotation = {
        rot.attribute("x").as_float(),
        rot.attribute("y").as_float(),
        rot.attribute("z").as_float(),
        rot.attribute("w").as_float()
    };

    out.scale = {
        scale.attribute("x").as_float(),
        scale.attribute("y").as_float(),
        scale.attribute("z").as_float()
    };
}
```

### Lua Scripts

```cpp
#include <lua.hpp>

void loadScript(lua_State* L, const char* luaText) {
    if (luaL_loadstring(L, luaText) != LUA_OK) {
        const char* error = lua_tostring(L, -1);
        LOG_ERROR("Lua parse error: {}", error);
        return;
    }

    // Script ausführen um Modul zu erhalten
    if (lua_pcall(L, 0, 1, 0) != LUA_OK) {
        const char* error = lua_tostring(L, -1);
        LOG_ERROR("Lua runtime error: {}", error);
        return;
    }

    // Jetzt liegt das Modul (Table) auf dem Stack
}
```

### GLSL Shaders

```cpp
GLuint compileShader(const char* glslText, GLenum shaderType) {
    GLuint shader = glCreateShader(shaderType);
    glShaderSource(shader, 1, &glslText, NULL);
    glCompileShader(shader);

    GLint success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        char infoLog[512];
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        LOG_ERROR("Shader compile error: {}", infoLog);
    }

    return shader;
}
```

## Binary Cache (data_blob)

Der `data_blob` ist optional und kann für Caching verwendet werden:

| Verwendung | Inhalt |
|------------|--------|
| Compiled Shader | SPIR-V Bytecode |
| Proto Cache | Proto-serialisierte Version für schnelles Laden |
| Compressed Data | Komprimierte Version großer Components |

```sql
-- Shader mit SPIR-V Cache
UPDATE components
SET data_blob = X'07230203...'  -- SPIR-V magic number
WHERE uuid = 'comp-shader-001';
```

## Migration

### Schema-Versionierung

```sql
-- Bei Schema-Änderungen
SELECT uuid, schema_version, data_text
FROM components
WHERE schema_version = '1.0.0';

-- Daten migrieren und Version aktualisieren
UPDATE components
SET data_text = ?, schema_version = '2.0.0'
WHERE uuid = ?;
```

### Beispiel: Field Rename

```cpp
// 1.0.0: <position x="..." />
// 2.0.0: <translation x="..." />

pugi::xml_document doc;
doc.load_string(oldXml);

auto pos = doc.child("component").child("position");
if (pos) {
    pos.set_name("translation");
}

std::stringstream ss;
doc.save(ss);
std::string newXml = ss.str();
```

## Validation

### XSD Schema

XML-Components können gegen `component-formats/component.xsd` validiert werden.

### Content-Type Check

```cpp
bool isValidContentType(const std::string& componentType,
                        const std::string& contentType) {
    static const std::map<std::string, std::set<std::string>> valid = {
        {"transform", {"application/xml"}},
        {"mesh", {"application/xml"}},
        {"script", {"text/x-lua"}},
        {"shader", {"text/x-glsl"}},
        {"state_machine", {"application/xml"}},
        {"config", {"application/json"}},
    };

    auto it = valid.find(componentType);
    if (it == valid.end()) return true;  // Unknown type, allow
    return it->second.count(contentType) > 0;
}
```
