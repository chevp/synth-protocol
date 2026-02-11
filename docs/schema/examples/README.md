# Synth Protocol - XML Examples

Umfassende Beispiele für alle synth-protocol Sub-Typen.

## Übersicht

| Schema Type | Example File | Description |
|-------------|--------------|-------------|
| **Runtime Renderer** | [runtime-frost-studio.synth.xml](runtime-frost-studio.synth.xml) | Frost Studio Vulkan renderer config (based on arctic-workspace) |
| **Runtime Logic** | [runtime-game-server.synth.xml](runtime-game-server.synth.xml) | Game server backend config (Java Quarkus) |
| **Component** | [component-building.synth.xml](component-building.synth.xml) | Building component (Town Hall) |
| **Component** | [component-npc.synth.xml](component-npc.synth.xml) | NPC component (Merchant) |
| **Component** | [component-environment.synth.xml](component-environment.synth.xml) | Environment (Procedural Skybox) |
| **Scene** | [scene-simple.synth.xml](scene-simple.synth.xml) | Town Plaza scene with entities |
| **Project** | [project-game.synth.xml](project-game.synth.xml) | Game project configuration |
| **Project + Pipeline** | [project-asset-pipeline.synth.xml](project-asset-pipeline.synth.xml) | Blender asset build pipeline |
| **Project + Production** | [project-game-production.synth.xml](project-game-production.synth.xml) | Full game with pipelines |
| **Routes** | [routes-game.synth.xml](routes-game.synth.xml) | Routing configuration |

---

## Kritischer Unterschied: Runtime Typen

### Spezifische Root-Tags (NICHT generisch!)

| Root Element | Verwendung | Schema |
|--------------|------------|--------|
| `<synthRuntimeRenderer>` | Vulkan/C++ Renderer (frost-studio, arctic-renderer) | runtime-renderer.xsd |
| `<synthRuntimeLogic>` | Game Logic/Backend (synth-core-hub, game server) | runtime-logic.xsd |

**WICHTIG:** `<synthRuntime>` ist VERALTET - verwende spezifische Tags!

### `<synthRuntimeRenderer>` - NUR Asset URIs!

Runtime format darf **KEINE** XML-Referenzen enthalten (`ref="path.synth.xml"`).

**Erlaubt:**
```xml
<searchPath type="models">synth-game/assets/models</searchPath>
<shader id="pbr_vertex" stage="vertex">
    <file path="synth://shaders/pbr.vert" language="glsl"/>
</shader>
<texture id="white">
    <file>synth://assets/textures/white_1x1.png</file>
</texture>
```

**VERBOTEN:**
```xml
<!-- FALSCH! Runtime darf keine XML refs enthalten -->
<component ref="components/player.synth.xml"/>
```

### `<synth><component>` / `<synth><scene>` - XML Refs erlaubt

Component und Scene Formate dürfen XML-Referenzen nutzen:

```xml
<!-- Component -->
<mesh ref="synth://assets/models/building_bakery"/>

<!-- Scene -->
<entity id="player_01">
    <component ref="components/player/player-topdown.synth.xml"/>
</entity>
```

---

## Runtime Format

### Shaders

Das Runtime Format unterstützt **3 Arten** von Shadern:

#### 1. Text Source (GLSL inline)

```xml
<shader id="simple_vertex" stage="vertex">
    <source language="glsl"><![CDATA[
#version 450

layout(location = 0) in vec3 inPosition;
// ... mehr GLSL code ...

void main() {
    gl_Position = ubo.proj * ubo.view * ubo.model * vec4(inPosition, 1.0);
}
]]></source>
</shader>
```

#### 2. Binary (SPIR-V base64)

```xml
<shader id="pbr_vertex_spirv" stage="vertex">
    <binary format="spirv" encoding="base64">
        AwIjBwAAAAABAQ0AAADVAAAAAgIAAGSQhZYAAAGQkAERAAI=
    </binary>
</shader>
```

#### 3. File Reference (Asset URI)

```xml
<shader id="skybox_vertex" stage="vertex">
    <file path="synth://shaders/skybox.vert" language="glsl"/>
</shader>
```

**WICHTIG:** Shaders werden als **Text oder Binary** gespeichert, **NIEMALS als Node-Tree**!

### Default Textures

#### PNG als Base64 (1x1 white pixel)

```xml
<texture id="fallback" format="png">
    <data encoding="base64">
        iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==
    </data>
</texture>
```

#### PNG als File Path

```xml
<texture id="white" format="png">
    <file>synth://assets/textures/white_1x1.png</file>
</texture>
```

### Asset Search Paths

```xml
<assets>
    <searchPath type="all" priority="10">synth-game/assets/shared</searchPath>
    <searchPath type="models" priority="20">synth-game/assets/models</searchPath>
    <searchPath type="textures" priority="20">synth-game/assets/textures</searchPath>
    <searchPath type="shaders" priority="30">synth-game/assets/shaders</searchPath>
</assets>
```

---

## Component Format

### Building

```xml
<synth version="1.0" xmlns="https://chevp.github.io/synth-protocol/schema/synth/1.0">
<component version="1.0" id="building-townhall">

    <metadata>
        <name>Town Hall</name>
        <type>building</type>
    </metadata>

    <!-- Mesh Reference (Asset URI) -->
    <mesh ref="synth://assets/models/building_townhall"/>

    <properties>
        <property name="producerId" type="string" value="townhall_001"/>
        <property name="interactable" type="bool" value="true"/>
        <property name="footprintX" type="int" value="5"/>
        <property name="footprintZ" type="int" value="5"/>
    </properties>

</component>
</synth>
```

### NPC

```xml
<synth version="1.0" xmlns="https://chevp.github.io/synth-protocol/schema/synth/1.0">
<component version="1.0" id="npc-merchant">

    <metadata>
        <name>Merchant NPC</name>
        <type>npc</type>
    </metadata>

    <mesh ref="synth://assets/models/character_merchant"/>

    <properties>
        <property name="npcName" type="string" value="Hans the Trader"/>
        <property name="dialogueTree" type="string" value="synth://dialogues/merchant_general"/>
        <property name="hasShop" type="bool" value="true"/>
    </properties>

</component>
</synth>
```

### Environment (Procedural)

```xml
<synth version="1.0" xmlns="https://chevp.github.io/synth-protocol/schema/synth/1.0">
<component version="1.0" id="environment-skybox">

    <metadata>
        <name>Procedural Skybox</name>
        <type>environment</type>
    </metadata>

    <!-- NO mesh - procedurally generated! -->

    <properties>
        <property name="topColor" type="color" value="#87CEEB"/>
        <property name="bottomColor" type="color" value="#E0F0FF"/>
        <property name="sunDirection" type="vec3" value="0.3,-0.7,0.5"/>
    </properties>

</component>
</synth>
```

---

## Scene Format

```xml
<synth version="1.0" xmlns="https://chevp.github.io/synth-protocol/schema/synth/1.0">
<scene version="1.0" id="plaza-scene">

    <metadata>
        <name>Town Plaza</name>
    </metadata>

    <entities>
        <!-- Environment -->
        <entity id="skybox_01" name="Sky">
            <component ref="components/environment/skybox.synth.xml"/>
        </entity>

        <!-- Buildings -->
        <entity id="building_bakery" name="Bakery">
            <component ref="components/buildings/bakery.synth.xml"/>
            <transform>
                <position x="-10" y="0" z="5"/>
                <rotation x="0" y="45" z="0"/>
            </transform>
        </entity>
    </entities>

    <lights>
        <light id="sun" type="directional">
            <direction x="0.3" y="-0.7" z="0.5"/>
            <color r="1.0" g="0.98" b="0.95"/>
            <intensity>1.2</intensity>
        </light>
    </lights>

    <camera>
        <type>topdown</type>
        <position x="0" y="15" z="10"/>
        <fov>60</fov>
    </camera>

</scene>
</synth>
```

---

## Project Format

```xml
<synthProject version="1.0" schemaVersion="1.0"
              xmlns="https://chevp.github.io/synth-protocol/schema/synth/project/1.0">

    <metadata id="synth-game">
        <name>Synth Game</name>
        <version>0.1.0</version>
    </metadata>

    <plugins>
        <plugin id="synth-player-controller" version="1.0" enabled="true"/>
    </plugins>

    <resources>
        <resource id="main-scene" type="asset" uri="scenes/shopping-district/scene.synth.xml"/>
    </resources>

    <settings>
        <setting key="hub.url" value="http://localhost:8180"/>
        <setting key="defaultScene" value="shopping-district"/>
    </settings>

</synthProject>
```

---

## Routes Format

```xml
<synthRoutes xmlns="https://chevp.github.io/synth-protocol/schema/synth/routes/1.0">

    <route id="shopping-district" path="/world/shopping-district" default="true">
        <scene ref="scenes/shopping-district/scene.synth.xml"/>
        <spawnPoint id="spawn_center" x="0" y="0.1" z="0"/>
    </route>

    <route id="bakery-interior" path="/world/shop/bakery_001">
        <scene ref="scenes/shop-interiors/bakery/scene.synth.xml"/>
        <spawnPoint id="spawn_entrance" x="0" y="0.1" z="5"/>
        <parameters>
            <parameter name="shopId" value="bakery_001"/>
            <parameter name="returnRoute" value="/world/shopping-district"/>
        </parameters>
    </route>

</synthRoutes>
```

---

## Pipeline Format (Asset Build)

### Tool Registry

Deklariert CLI-Tools, die Pipeline-Steps verwenden. synth-core löst Pfade zur Laufzeit auf:

```xml
<toolRegistry>
    <tool id="blender" executable="blender" version="4.2">
        <config>
            <entry key="args">--background --python-exit-code 1</entry>
        </config>
    </tool>
    <tool id="gltf-transform" executable="gltf-transform" version="4.0"/>
    <tool id="toktx" executable="toktx" version="4.3"/>
</toolRegistry>
```

### Pipeline mit Steps (DAG)

Steps bilden einen gerichteten azyklischen Graphen via `dependsOn`:

```xml
<pipeline id="asset-build" name="Full Asset Build" enabled="true">
    <description>Blender export, mesh optimization, texture compression</description>
    <steps>
        <step id="export" tool="blender" timeout="300">
            <input>
                <param name="source" type="directory">assets/raw</param>
                <param name="pattern">**/*.blend</param>
                <param name="script">scripts/blender_gltf_export.py</param>
            </input>
            <output>
                <param name="target" type="directory">assets/build/gltf</param>
            </output>
        </step>

        <step id="optimize" tool="gltf-transform" dependsOn="export">
            <input>
                <param name="source" type="directory">assets/build/gltf</param>
            </input>
            <output>
                <param name="target" type="directory">assets/runtime</param>
            </output>
            <config>
                <entry key="commands">dedup,draco,prune</entry>
            </config>
        </step>

        <!-- Parallel zum optimize-Step (beide hängen nur von export ab) -->
        <step id="compress" tool="toktx" dependsOn="export">
            <input>
                <param name="source" type="directory">assets/build/gltf</param>
                <param name="pattern">**/*.png</param>
            </input>
            <output>
                <param name="target" type="directory">assets/build/textures</param>
            </output>
            <config>
                <entry key="codec">uastc</entry>
                <entry key="quality">2</entry>
            </config>
        </step>
    </steps>

    <triggers>
        <trigger type="manual"/>
        <trigger type="file-watch" pattern="assets/raw/**/*.blend"/>
        <trigger type="hub-event" value="pipeline.asset-build.requested"/>
        <trigger type="schedule" value="0 2 * * *"/>
    </triggers>
</pipeline>
```

### Trigger-Typen

| Trigger | Beschreibung | `value` / `pattern` |
|---------|-------------|---------------------|
| `manual` | User klickt im synth-cluster-editor | - |
| `file-watch` | Filesystem-Änderung | Glob-Pattern: `assets/raw/**/*.blend` |
| `hub-event` | synth-core-hub Event | Topic: `pipeline.asset-build.requested` |
| `schedule` | Cron-Schedule | Cron: `0 2 * * *` (täglich 02:00) |
| `event` | Generisches Event | Event-Name |

### Step-Attribute

| Attribut | Pflicht | Beschreibung |
|----------|---------|-------------|
| `id` | ja | Eindeutiger Step-Name |
| `tool` | ja | Referenz auf Tool aus `toolRegistry` |
| `dependsOn` | nein | Komma-separierte Step-IDs (DAG) |
| `timeout` | nein | Timeout in Sekunden |
| `continueOnError` | nein | Bei Fehler weitermachen (default: false) |

### Resource-Typen (erweitert)

| Type | Beschreibung |
|------|-------------|
| `model` | 3D Modell (glTF, FBX) |
| `blend` | Blender Source File (.blend) |
| `texture` | Bild-Asset (PNG, KTX2, EXR) |
| `shader` | Shader-Datei (GLSL, SPIR-V) |
| `audio` | Audio-Asset (WAV, OGG) |
| `scene` | Scene-Definition (.synth.xml) |
| `directory` | Verzeichnis-Referenz |
| `script` | Pipeline-Script (Python, JS) |
| `config` | Konfigurations-Datei |
| `asset` | Generisches Asset |
| `dataset` | Daten-Datei |

### Execution Flow

```
synth-cluster-editor         synth-core-hub          synth-core (C++)
        |                          |                        |
        |-- "Run Pipeline" ------->|                        |
        |                          |-- hub-event ---------->|
        |                          |                        |-- parse .synth
        |                          |                        |-- resolve tools
        |                          |                        |-- execute DAG:
        |                          |                        |   1. blender --background
        |                          |                        |   2. gltf-transform (parallel)
        |                          |                        |   3. toktx (parallel)
        |                          |                        |   4. gltfpack (after 2+3)
        |                          |<-- progress events ----|
        |<-- SSE progress ---------|                        |
        |                          |<-- completed event ----|
        |<-- SSE completed --------|                        |
```

---

## Philosophie

> **synth-protocol ist domain-driven, NICHT over-engineered.**

### Was synth-protocol IST:

✅ **Einfache Shader Referenzen** - Text (GLSL/HLSL) oder Binary (SPIR-V base64)
✅ **Direkte Asset URIs** - `synth://assets/models/bakery`
✅ **Straightforward Configuration** - Key-Value Settings
✅ **Klare Separation** - Runtime (Asset URIs) vs. Component/Scene (XML refs)

### Was synth-protocol NICHT ist:

❌ **Shader Node-Trees** - Shaders sind Text oder Binary, KEINE Graphen
❌ **Komplexe Asset Graphs** - Einfache URI Referenzen
❌ **Abstraktions-Layers** - Direkte Konfiguration

---

## Validierung

Alle Beispiele sind **schema-validiert** in VSCode mit dem XML Extension by Red Hat.

### Setup:

1. Installiere "XML" Extension by Red Hat in VSCode
2. Die `.vscode/settings.json` im Workspace Root (`C:\chevp`) ist bereits konfiguriert
3. Öffne ein `*.synth.xml` File → Automatische Validation!

### Test:

```bash
# In VSCode öffnen:
code c:/chevp/synth/synth-protocol/docs/schema/examples/runtime-vulkan.synth.xml
```

Keine Validation-Fehler = ✅ Schema-konform!

---

## Weiterführende Dokumentation

- [Runtime Schema (runtime.xsd)](../synth/runtime/1.0/runtime.xsd)
- [Component Schema (component.xsd)](../synth/component/1.0/component.xsd)
- [Scene Schema (scene.xsd)](../synth/scene/1.0/scene.xsd)
- [Project Schema (project.xsd)](../synth/project/1.0/project.xsd)
- [Routes Schema (routes.xsd)](../synth/routes/1.0/routes.xsd)
- [Local Validation Guide](../LOCAL_VALIDATION.md)
- [Asset References Guide](../../../../synth-playground/synth-game/docs/ASSET_REFERENCES.md)
