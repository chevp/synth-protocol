# C++ Direct-Load Workflow

## Übersicht

Der C++ Renderer (arctic) kann Entities **direkt aus SQLite laden**, ohne Java-Server.
Component-Daten werden als human-readable Text (XML, Lua, GLSL, JSON) gespeichert.

```
┌─────────────────────────────────────────────────────────────────┐
│                    C++ DIRECT-LOAD WORKFLOW                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   game.nuna.db                                                   │
│   ┌─────────────────────────────────────────┐                   │
│   │ entities                                 │                   │
│   │ ├── uuid: "player-001"                   │                   │
│   │ ├── name: "Player"                       │                   │
│   │ └── parent_uuid: NULL (root)             │                   │
│   │                                          │                   │
│   │ components                               │                   │
│   │ ├── entity_uuid: "player-001"            │                   │
│   │ ├── component_type: "transform"          │                   │
│   │ ├── content_type: "application/xml"      │                   │
│   │ └── data_text: "<component>...</component>"                  │
│   └─────────────────────────────────────────┘                   │
│                                              │                   │
│   C++ Renderer (arctic)                      │                   │
│   ┌─────────────────────────────────────────┐│                   │
│   │                                          ││                   │
│   │   pugixml::load_string(data_text) ◄──────┘│                   │
│   │   lua_loadstring(data_text) ◄─────────────┘                   │
│   │   glShaderSource(data_text) ◄─────────────                   │
│   │                                          │                   │
│   │   render(transform, mesh);               │                   │
│   │                                          │                   │
│   └─────────────────────────────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Voraussetzungen

### 1. Dependencies in CMake einbinden

```cmake
# CMakeLists.txt
find_package(SQLite3 REQUIRED)

# pugixml für XML-Parsing
FetchContent_Declare(
    pugixml
    GIT_REPOSITORY https://github.com/zeux/pugixml.git
    GIT_TAG v1.14
)
FetchContent_MakeAvailable(pugixml)

# Lua für Scripts
find_package(Lua REQUIRED)

add_executable(arctic_renderer
    main.cpp
    EntityLoader.cpp
    ComponentParser.cpp
)

target_link_libraries(arctic_renderer
    SQLite::SQLite3
    pugixml
    ${LUA_LIBRARIES}
)
```

### 2. Includes

```cpp
#include <sqlite3.h>
#include <pugixml.hpp>
#include <lua.hpp>
#include <string>
#include <vector>
#include <optional>
#include <map>
```

## Data Structures

### Transform

```cpp
struct Vec3 {
    float x = 0, y = 0, z = 0;
};

struct Quat {
    float x = 0, y = 0, z = 0, w = 1;
};

struct Transform {
    Vec3 position;
    Quat rotation;
    Vec3 scale{1, 1, 1};
};
```

### Component

```cpp
struct Component {
    std::string uuid;
    std::string type;          // "transform", "mesh", "script", etc.
    std::string content_type;  // "application/xml", "text/x-lua", etc.
    std::string data_text;     // Source code
    bool enabled = true;
};
```

### Entity

```cpp
struct LoadedEntity {
    std::string uuid;
    std::string name;
    std::string entity_type;
    int state = 1;

    std::string parent_uuid;
    int sibling_order = 0;
    std::string scene_uuid;

    // Parsed components
    std::optional<Transform> transform;
    std::map<std::string, Component> components;

    // Children (for hierarchy)
    std::vector<LoadedEntity*> children;
};
```

## Component Parser

### Header: ComponentParser.h

```cpp
#pragma once

#include <string>
#include <optional>
#include "DataStructures.h"

namespace arctic {

class ComponentParser {
public:
    // XML Components
    static std::optional<Transform> parseTransform(const std::string& xml);
    static std::optional<MeshData> parseMesh(const std::string& xml);
    static std::optional<LightData> parseLight(const std::string& xml);
    static std::optional<StateMachine> parseStateMachine(const std::string& xml);

    // Generic XML helper
    static pugi::xml_document parseXml(const std::string& xml);
};

} // namespace arctic
```

### Implementation: ComponentParser.cpp

```cpp
#include "ComponentParser.h"
#include <pugixml.hpp>

namespace arctic {

pugi::xml_document ComponentParser::parseXml(const std::string& xml) {
    pugi::xml_document doc;
    doc.load_string(xml.c_str());
    return doc;
}

std::optional<Transform> ComponentParser::parseTransform(const std::string& xml) {
    auto doc = parseXml(xml);
    auto component = doc.child("component");

    if (!component || std::string(component.attribute("type").as_string()) != "transform") {
        return std::nullopt;
    }

    Transform t;

    auto pos = component.child("position");
    if (pos) {
        t.position.x = pos.attribute("x").as_float(0);
        t.position.y = pos.attribute("y").as_float(0);
        t.position.z = pos.attribute("z").as_float(0);
    }

    auto rot = component.child("rotation");
    if (rot) {
        t.rotation.x = rot.attribute("x").as_float(0);
        t.rotation.y = rot.attribute("y").as_float(0);
        t.rotation.z = rot.attribute("z").as_float(0);
        t.rotation.w = rot.attribute("w").as_float(1);
    }

    auto scale = component.child("scale");
    if (scale) {
        t.scale.x = scale.attribute("x").as_float(1);
        t.scale.y = scale.attribute("y").as_float(1);
        t.scale.z = scale.attribute("z").as_float(1);
    }

    return t;
}

std::optional<MeshData> ComponentParser::parseMesh(const std::string& xml) {
    auto doc = parseXml(xml);
    auto component = doc.child("component");

    if (!component) return std::nullopt;

    MeshData mesh;

    auto asset = component.child("asset");
    if (asset) {
        mesh.asset_uuid = asset.attribute("uuid").as_string();
        mesh.asset_path = asset.attribute("path").as_string();
    }

    auto lod = component.child("lod");
    if (lod) {
        mesh.lod_level = lod.attribute("level").as_int(0);
        mesh.lod_bias = lod.attribute("bias").as_float(0);
    }

    auto shadows = component.child("shadows");
    if (shadows) {
        mesh.cast_shadows = shadows.attribute("cast").as_bool(true);
        mesh.receive_shadows = shadows.attribute("receive").as_bool(true);
    }

    return mesh;
}

std::optional<StateMachine> ComponentParser::parseStateMachine(const std::string& xml) {
    auto doc = parseXml(xml);
    auto component = doc.child("component");

    if (!component) return std::nullopt;

    StateMachine fsm;
    auto sm = component.child("state-machine");

    fsm.name = sm.attribute("name").as_string();
    fsm.initial_state = sm.attribute("initial").as_string();

    // Parse states
    auto states = sm.child("states");
    for (auto state : states.children("state")) {
        State s;
        s.id = state.attribute("id").as_string();
        s.display = state.attribute("display").as_string();

        // Parse properties
        auto props = state.child("properties");
        for (auto prop : props.children("property")) {
            s.properties[prop.attribute("name").as_string()] =
                prop.text().as_string();
        }

        fsm.states[s.id] = s;
    }

    // Parse transitions
    auto transitions = sm.child("transitions");
    for (auto trans : transitions.children("transition")) {
        Transition t;
        t.from = trans.attribute("from").as_string();
        t.to = trans.attribute("to").as_string();

        auto triggers = trans.child("triggers");
        for (auto trigger : triggers.children("trigger")) {
            t.triggers.push_back(trigger.text().as_string());
        }

        fsm.transitions.push_back(t);
    }

    return fsm;
}

} // namespace arctic
```

## Entity Loader

### Header: EntityLoader.h

```cpp
#pragma once

#include <sqlite3.h>
#include <string>
#include <vector>
#include <map>
#include <optional>
#include "DataStructures.h"

namespace arctic {

class EntityLoader {
public:
    EntityLoader(const std::string& db_path);
    ~EntityLoader();

    // Load single entity with all components
    std::optional<LoadedEntity> loadEntity(const std::string& uuid);

    // Load all entities in scene (flat list)
    std::vector<LoadedEntity> loadScene(const std::string& scene_uuid);

    // Load scene as hierarchy tree
    std::vector<LoadedEntity> loadSceneHierarchy(const std::string& scene_uuid);

private:
    sqlite3* db_ = nullptr;

    void loadComponents(const std::string& entity_uuid, LoadedEntity& entity);
    void buildHierarchy(std::vector<LoadedEntity>& entities);
};

} // namespace arctic
```

### Implementation: EntityLoader.cpp

```cpp
#include "EntityLoader.h"
#include "ComponentParser.h"
#include <stdexcept>
#include <algorithm>

namespace arctic {

EntityLoader::EntityLoader(const std::string& db_path) {
    int rc = sqlite3_open_v2(db_path.c_str(), &db_,
        SQLITE_OPEN_READONLY, nullptr);

    if (rc != SQLITE_OK) {
        throw std::runtime_error("Failed to open database: " + db_path);
    }

    sqlite3_exec(db_, "PRAGMA foreign_keys = ON", nullptr, nullptr, nullptr);
}

EntityLoader::~EntityLoader() {
    if (db_) {
        sqlite3_close(db_);
    }
}

std::optional<LoadedEntity> EntityLoader::loadEntity(const std::string& uuid) {
    const char* sql = R"(
        SELECT
            uuid, name, entity_type, state,
            parent_uuid, sibling_order, scene_uuid
        FROM entities
        WHERE uuid = ? AND state != 4
    )";

    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db_, sql, -1, &stmt, nullptr) != SQLITE_OK) {
        return std::nullopt;
    }

    sqlite3_bind_text(stmt, 1, uuid.c_str(), -1, SQLITE_STATIC);

    if (sqlite3_step(stmt) != SQLITE_ROW) {
        sqlite3_finalize(stmt);
        return std::nullopt;
    }

    LoadedEntity entity;
    entity.uuid = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
    entity.name = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));

    const char* type = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));
    if (type) entity.entity_type = type;

    entity.state = sqlite3_column_int(stmt, 3);

    const char* parent = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 4));
    if (parent) entity.parent_uuid = parent;

    entity.sibling_order = sqlite3_column_int(stmt, 5);

    const char* scene = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 6));
    if (scene) entity.scene_uuid = scene;

    sqlite3_finalize(stmt);

    // Load all components
    loadComponents(uuid, entity);

    return entity;
}

void EntityLoader::loadComponents(const std::string& entity_uuid,
                                   LoadedEntity& entity) {
    const char* sql = R"(
        SELECT uuid, component_type, content_type, data_text, enabled
        FROM components
        WHERE entity_uuid = ?
    )";

    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db_, sql, -1, &stmt, nullptr) != SQLITE_OK) {
        return;
    }

    sqlite3_bind_text(stmt, 1, entity_uuid.c_str(), -1, SQLITE_STATIC);

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        Component comp;
        comp.uuid = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
        comp.type = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
        comp.content_type = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));

        const char* data = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 3));
        if (data) comp.data_text = data;

        comp.enabled = sqlite3_column_int(stmt, 4) != 0;

        // Parse known component types
        if (comp.type == "transform" && comp.content_type == "application/xml") {
            entity.transform = ComponentParser::parseTransform(comp.data_text);
        }

        // Store raw component for later use
        entity.components[comp.type] = comp;
    }

    sqlite3_finalize(stmt);
}

std::vector<LoadedEntity> EntityLoader::loadScene(const std::string& scene_uuid) {
    std::vector<LoadedEntity> entities;

    const char* sql = R"(
        SELECT uuid FROM entities
        WHERE scene_uuid = ? AND state = 1
        ORDER BY sibling_order
    )";

    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db_, sql, -1, &stmt, nullptr) != SQLITE_OK) {
        return entities;
    }

    sqlite3_bind_text(stmt, 1, scene_uuid.c_str(), -1, SQLITE_STATIC);

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char* uuid = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
        if (auto entity = loadEntity(uuid)) {
            entities.push_back(std::move(*entity));
        }
    }

    sqlite3_finalize(stmt);
    return entities;
}

std::vector<LoadedEntity> EntityLoader::loadSceneHierarchy(const std::string& scene_uuid) {
    auto entities = loadScene(scene_uuid);
    buildHierarchy(entities);
    return entities;
}

void EntityLoader::buildHierarchy(std::vector<LoadedEntity>& entities) {
    // Build UUID to pointer map
    std::map<std::string, LoadedEntity*> entityMap;
    for (auto& e : entities) {
        entityMap[e.uuid] = &e;
    }

    // Link children to parents
    for (auto& e : entities) {
        if (!e.parent_uuid.empty()) {
            auto it = entityMap.find(e.parent_uuid);
            if (it != entityMap.end()) {
                it->second->children.push_back(&e);
            }
        }
    }

    // Sort children by sibling_order
    for (auto& e : entities) {
        std::sort(e.children.begin(), e.children.end(),
            [](const LoadedEntity* a, const LoadedEntity* b) {
                return a->sibling_order < b->sibling_order;
            });
    }
}

} // namespace arctic
```

## Usage Example

### main.cpp

```cpp
#include "EntityLoader.h"
#include "ComponentParser.h"
#include <iostream>

void printHierarchy(const arctic::LoadedEntity& entity, int depth = 0) {
    std::string indent(depth * 2, ' ');

    std::cout << indent << "Entity: " << entity.name << " (" << entity.uuid << ")\n";

    if (entity.transform) {
        std::cout << indent << "  Position: ("
            << entity.transform->position.x << ", "
            << entity.transform->position.y << ", "
            << entity.transform->position.z << ")\n";
    }

    // Print component types
    for (const auto& [type, comp] : entity.components) {
        std::cout << indent << "  Component: " << type
            << " [" << comp.content_type << "]\n";
    }

    // Recurse into children
    for (const auto* child : entity.children) {
        printHierarchy(*child, depth + 1);
    }
}

int main() {
    try {
        arctic::EntityLoader loader("game.nuna.db");

        // Load scene with hierarchy
        auto entities = loader.loadSceneHierarchy("scene-001");

        std::cout << "Loaded " << entities.size() << " entities\n\n";

        // Print root entities and their children
        for (const auto& entity : entities) {
            if (entity.parent_uuid.empty()) {
                printHierarchy(entity);
            }
        }

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }

    return 0;
}
```

## Lua Script Loading

### ScriptManager.h

```cpp
#pragma once

#include <lua.hpp>
#include <string>
#include <map>

namespace arctic {

class ScriptManager {
public:
    ScriptManager();
    ~ScriptManager();

    // Load a script component
    bool loadScript(const std::string& entity_uuid, const std::string& lua_source);

    // Call update on all scripts
    void updateAll(float deltaTime);

    // Call specific script method
    void callMethod(const std::string& entity_uuid,
                    const std::string& method,
                    int nargs = 0);

private:
    lua_State* L_;
    std::map<std::string, int> script_refs_;  // entity_uuid -> Lua ref
};

} // namespace arctic
```

### Implementation

```cpp
#include "ScriptManager.h"

namespace arctic {

ScriptManager::ScriptManager() {
    L_ = luaL_newstate();
    luaL_openlibs(L_);

    // Register engine API
    // ... Input, Vec3, Entity bindings
}

ScriptManager::~ScriptManager() {
    // Release refs
    for (const auto& [uuid, ref] : script_refs_) {
        luaL_unref(L_, LUA_REGISTRYINDEX, ref);
    }
    lua_close(L_);
}

bool ScriptManager::loadScript(const std::string& entity_uuid,
                                const std::string& lua_source) {
    // Load and execute script to get module table
    if (luaL_loadstring(L_, lua_source.c_str()) != LUA_OK) {
        const char* err = lua_tostring(L_, -1);
        std::cerr << "Lua parse error: " << err << "\n";
        lua_pop(L_, 1);
        return false;
    }

    if (lua_pcall(L_, 0, 1, 0) != LUA_OK) {
        const char* err = lua_tostring(L_, -1);
        std::cerr << "Lua runtime error: " << err << "\n";
        lua_pop(L_, 1);
        return false;
    }

    // Store reference to module table
    int ref = luaL_ref(L_, LUA_REGISTRYINDEX);
    script_refs_[entity_uuid] = ref;

    return true;
}

void ScriptManager::updateAll(float deltaTime) {
    for (const auto& [uuid, ref] : script_refs_) {
        callMethod(uuid, "update", 1);
        lua_pushnumber(L_, deltaTime);
        // Call would happen here with proper stack management
    }
}

} // namespace arctic
```

## Render Integration

### Mit Vulkan Renderer

```cpp
void ArcticRenderer::loadScene(const std::string& db_path,
                                const std::string& scene_uuid) {
    arctic::EntityLoader loader(db_path);
    auto entities = loader.loadSceneHierarchy(scene_uuid);

    for (const auto& entity : entities) {
        // Skip entities without transform
        if (!entity.transform) continue;

        RenderObject obj;
        obj.uuid = entity.uuid;

        // Build transform matrix
        obj.transform = glm::mat4(1.0f);
        obj.transform = glm::translate(obj.transform, glm::vec3(
            entity.transform->position.x,
            entity.transform->position.y,
            entity.transform->position.z
        ));

        glm::quat rotation(
            entity.transform->rotation.w,
            entity.transform->rotation.x,
            entity.transform->rotation.y,
            entity.transform->rotation.z
        );
        obj.transform *= glm::mat4_cast(rotation);

        obj.transform = glm::scale(obj.transform, glm::vec3(
            entity.transform->scale.x,
            entity.transform->scale.y,
            entity.transform->scale.z
        ));

        // Load mesh if present
        auto meshIt = entity.components.find("mesh");
        if (meshIt != entity.components.end()) {
            auto meshData = ComponentParser::parseMesh(meshIt->second.data_text);
            if (meshData) {
                obj.mesh = assetManager.loadMesh(meshData->asset_uuid);
            }
        }

        // Load script if present
        auto scriptIt = entity.components.find("script");
        if (scriptIt != entity.components.end() &&
            scriptIt->second.content_type == "text/x-lua") {
            scriptManager.loadScript(entity.uuid, scriptIt->second.data_text);
        }

        renderObjects.push_back(std::move(obj));
    }
}
```

## Performance Optimierungen

### 1. Batch Loading mit JOIN

```cpp
const char* sql = R"(
    SELECT
        e.uuid, e.name, e.entity_type, e.state,
        e.parent_uuid, e.sibling_order,
        c.uuid as comp_uuid, c.component_type, c.content_type, c.data_text
    FROM entities e
    LEFT JOIN components c ON e.uuid = c.entity_uuid AND c.enabled = 1
    WHERE e.scene_uuid = ? AND e.state = 1
    ORDER BY e.uuid, c.component_type
)";
```

### 2. Memory-Mapped Database

```cpp
sqlite3_open_v2(db_path.c_str(), &db_,
    SQLITE_OPEN_READONLY | SQLITE_OPEN_URI,
    nullptr);

sqlite3_exec(db_, "PRAGMA mmap_size = 268435456", nullptr, nullptr, nullptr);
```

### 3. Component Cache

```cpp
// Cache parsed XML components
std::map<std::string, Transform> transformCache_;

std::optional<Transform> getTransform(const std::string& comp_uuid,
                                       const std::string& xml) {
    auto it = transformCache_.find(comp_uuid);
    if (it != transformCache_.end()) {
        return it->second;
    }

    auto t = ComponentParser::parseTransform(xml);
    if (t) {
        transformCache_[comp_uuid] = *t;
    }
    return t;
}
```

## Fazit

Mit diesem Setup kann der C++ Renderer:

1. **Direkt aus SQLite laden** - kein Server nötig
2. **Human-readable parsen** - XML mit pugixml, Lua mit lua_loadstring
3. **Hierarchien unterstützen** - Parent-Child Beziehungen
4. **Offline arbeiten** - Editor ohne Netzwerk
5. **Später auf Multiplayer wechseln** - Server konvertiert XML zu Proto für Wire-Format
