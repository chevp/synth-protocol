# Unified Entity Schema

> **Ziel: SQLite = Human-Readable = Git-Friendly**

Dieses Schema ermöglicht:
1. SQLite-Tabellen mit flexiblem Component-System
2. Component-Daten als XML, Lua, GLSL oder JSON (human-readable)
3. C++ Renderer kann direkt aus SQLite laden (ohne Java-Server)
4. Java-Server kann später dieselben Daten via gRPC übertragen
5. Hierarchische Entities (Parent-Child-Beziehungen)

## Architektur

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         UNIFIED ENTITY SCHEMA                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Phase 1: Offline / Editor                                                 │
│   ┌─────────────┐                    ┌─────────────────────┐                │
│   │   SQLite    │ ──── direkt ────►  │   C++ Renderer      │                │
│   │  (.nuna.db) │                    │   (arctic)          │                │
│   └─────────────┘                    └─────────────────────┘                │
│         │                                                                   │
│         │  Human-readable in data_text (XML, Lua, GLSL, JSON)               │
│         │  Optional: Binary Cache in data_blob                              │
│         │                                                                   │
│   Phase 2: Multiplayer / Live                                               │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐            │
│   │   SQLite    │───►│ Java Server │───►│   C++ Renderer      │            │
│   │  (.nuna.db) │    │  (gRPC)     │    │   (arctic)          │            │
│   └─────────────┘    └─────────────┘    └─────────────────────┘            │
│                            │                                                │
│                      Proto über Wire (konvertiert aus XML)                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Schlüsselprinzip

**Alles ist ein Component.** Transform, Mesh, Script, State Machine - alles sind Components mit unterschiedlichen `content_type`s.

```
┌──────────────────────────────────────────────────────────────────────┐
│                            ENTITY                                     │
│  (Container für Components, kann Child-Entities haben)               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐      │
│   │ Component       │  │ Component       │  │ Component       │      │
│   │ type: transform │  │ type: mesh      │  │ type: script    │      │
│   │ XML             │  │ XML             │  │ Lua             │      │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘      │
│                                                                       │
│   ┌─────────────────┐  ┌─────────────────┐                           │
│   │ Component       │  │ Component       │                           │
│   │ type: shader    │  │ type: state_machine                         │
│   │ GLSL            │  │ XML             │                           │
│   └─────────────────┘  └─────────────────┘                           │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

## Content-Types

| Content-Type | Verwendung | Beispiel |
|--------------|------------|----------|
| `application/xml` | Transform, Mesh, Light, Physics, Audio, State Machine | `<component type="transform">...</component>` |
| `text/x-lua` | Scripte | `local Controller = {} ...` |
| `text/x-glsl` | Shader | `#version 450 ...` |
| `application/json` | Konfiguration | `{ "key": "value" }` |
| `application/x-protobuf` | Binary Cache (optional) | Proto-Bytes in data_blob |

## Dateien

| Datei | Beschreibung |
|-------|--------------|
| `unified-schema.sql` | SQLite-Schema mit Entity/Component-Tabellen |
| `component-formats/component.xsd` | XSD-Schema für XML-Validation |
| `component-formats/examples/` | Beispiele für alle Component-Typen |
| `MAPPING.md` | Mapping-Dokumentation |

## Entity-Hierarchie

Entities können beliebig tief verschachtelt sein:

```sql
-- Root Entity
INSERT INTO entities (uuid, name, parent_uuid) VALUES ('root-001', 'World', NULL);

-- Child Entities
INSERT INTO entities (uuid, name, parent_uuid) VALUES ('player-001', 'Player', 'root-001');
INSERT INTO entities (uuid, name, parent_uuid) VALUES ('weapon-001', 'Sword', 'player-001');
```

Child-Entities werden automatisch gelöscht wenn der Parent gelöscht wird (CASCADE).

### Hierarchie-View

```sql
-- Rekursive Abfrage für kompletten Entity-Tree
SELECT * FROM v_entity_tree WHERE scene_uuid = 'scene-001';
```

## Verwendung

### C++ (Phase 1 - Offline)

```cpp
#include <pugixml.hpp>

// SQLite öffnen
sqlite3* db;
sqlite3_open("game.nuna.db", &db);

// Entity mit Components laden
sqlite3_stmt* stmt;
sqlite3_prepare_v2(db,
    "SELECT c.component_type, c.content_type, c.data_text "
    "FROM components c WHERE c.entity_uuid = ?",
    -1, &stmt, 0);
sqlite3_bind_text(stmt, 1, entityUuid, -1, SQLITE_STATIC);

while (sqlite3_step(stmt) == SQLITE_ROW) {
    const char* type = (const char*)sqlite3_column_text(stmt, 0);
    const char* contentType = (const char*)sqlite3_column_text(stmt, 1);
    const char* dataText = (const char*)sqlite3_column_text(stmt, 2);

    if (strcmp(contentType, "application/xml") == 0) {
        pugi::xml_document doc;
        doc.load_string(dataText);

        if (strcmp(type, "transform") == 0) {
            auto pos = doc.child("component").child("position");
            float x = pos.attribute("x").as_float();
            float y = pos.attribute("y").as_float();
            float z = pos.attribute("z").as_float();
            // Transform setzen...
        }
    }
    else if (strcmp(contentType, "text/x-lua") == 0) {
        // Lua-Script laden
        luaL_loadstring(L, dataText);
    }
    else if (strcmp(contentType, "text/x-glsl") == 0) {
        // Shader kompilieren
        GLuint shader = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(shader, 1, &dataText, NULL);
        glCompileShader(shader);
    }
}
```

### Java Server (Phase 2 - Multiplayer)

```java
// Entity mit Components laden
Entity entity = entityRepository.findById(uuid);
List<Component> components = componentRepository.findByEntityUuid(uuid);

for (Component comp : components) {
    if ("application/xml".equals(comp.getContentType())) {
        // XML parsen und zu Proto konvertieren
        Document doc = parseXml(comp.getDataText());

        if ("transform".equals(comp.getComponentType())) {
            TransformProto proto = xmlToTransformProto(doc);
            // Via gRPC senden...
        }
    }
}
```

## Component-Beispiele

### Transform (XML)

```xml
<component type="transform" version="1.0">
    <position x="0" y="1.5" z="0"/>
    <rotation x="0" y="0" z="0" w="1"/>
    <scale x="1" y="1" z="1"/>
</component>
```

### Script (Lua)

```lua
-- Component: script
-- Content-Type: text/x-lua
local PlayerController = {}
function PlayerController:update(dt)
    -- Game logic
end
return PlayerController
```

### State Machine (XML)

```xml
<component type="state_machine" version="1.0">
    <state-machine name="movement" initial="IDLE">
        <states>
            <state id="IDLE"/>
            <state id="WALKING"/>
        </states>
        <transitions>
            <transition from="IDLE" to="WALKING">
                <triggers><trigger>input_move</trigger></triggers>
            </transition>
        </transitions>
    </state-machine>
</component>
```

## Vorteile

1. **Human-Readable**: XML, Lua, GLSL sind lesbar und editierbar
2. **Git-Friendly**: Diff und Merge funktionieren
3. **Flexibel**: Neue Component-Typen ohne Schema-Änderung
4. **Erweiterbar**: data_blob für kompilierte Caches (Shader, etc.)
5. **Hierarchisch**: Entities können verschachtelt werden
