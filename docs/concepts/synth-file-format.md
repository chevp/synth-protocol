# Synth File Format Konzept

## Übersicht: Drei Ebenen der Synth-Architektur

```
┌─────────────────────────────────────────────────────────────────┐
│                     .synth.xml (Dokument)                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    State (Zustand)                        │  │
│  │  - Scene Graph (Nodes, Components)                        │  │
│  │  - Assets (Referenzen)                                    │  │
│  │  - Settings (Konfiguration)                               │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │               Events (Änderungen/History)                 │  │
│  │  - CompactEvent Stream (Optional, für Undo/Replay)        │  │
│  │  - Recorded Actions                                       │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Scripts (Logik)                          │  │
│  │  - Inline Scripts                                         │  │
│  │  - External Script References                             │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Die Kernfrage: State vs Events

### Option A: State-basiert (empfohlen für .synth.xml)
```xml
<!-- .synth.xml speichert den AKTUELLEN ZUSTAND -->
<synth version="1.0">
  <scene id="scene_outdoor">
    <node id="node_tree_01" type="asset" name="Oak Tree">
      <transform position="10,0,5" rotation="0,0,0" scale="1,1,1"/>
      <material ref="mat_bark_pbr"/>
    </node>
  </scene>
</synth>
```

### Option B: Event-basiert (Event Sourcing)
```xml
<!-- Speichert ALLE ÄNDERUNGEN seit Projektbeginn -->
<synth version="1.0">
  <events>
    <event>cluster node create node_tree_01 in scene_outdoor</event>
    <event>component node create comp_transform on node_tree_01</event>
    <event>component node update comp_transform on node_tree_01 --position="10,0,5"</event>
  </events>
</synth>
```

### Option C: Hybrid (empfohlen)
```xml
<!-- State + optionale Event-History -->
<synth version="1.0">
  <!-- Aktueller Zustand (schnelles Laden) -->
  <state>
    <scene id="scene_outdoor">...</scene>
  </state>

  <!-- Event-History (für Undo/Replay, optional) -->
  <history max-events="1000">
    <event ts="1702468800000">cluster node create node_tree_01 in scene_outdoor</event>
  </history>
</synth>
```

---

## Empfohlene Architektur

### 1. `.synth.xml` = Dokument-Format (State)

Das Hauptformat für Projektdateien. Speichert den **aktuellen Zustand**.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<synth version="1.0" xmlns="https://synth.dev/schema/1.0">

  <!-- Projekt-Metadaten -->
  <meta>
    <name>My Project</name>
    <created>2024-12-13T10:00:00Z</created>
    <modified>2024-12-13T15:30:00Z</modified>
  </meta>

  <!-- Szenen-Graph (State) -->
  <scenes>
    <scene id="scene_outdoor" name="Outdoor Scene" state="active">
      <nodes>
        <node id="node_tree_01" type="asset" name="Oak Tree" parent="folder_veg">
          <components>
            <transform position="10,0,5" rotation="0,45,0" scale="1,1,1"/>
            <material ref="assets/materials/bark_pbr.mat"/>
            <mesh ref="assets/meshes/oak_tree.fbx"/>
          </components>
        </node>
        <folder id="folder_veg" name="Vegetation"/>
      </nodes>
    </scene>
  </scenes>

  <!-- Asset-Referenzen -->
  <assets>
    <asset id="asset_oak" type="mesh" path="assets/meshes/oak_tree.fbx"/>
    <asset id="mat_bark" type="material" path="assets/materials/bark_pbr.mat"/>
  </assets>

  <!-- MCP Server Konfiguration -->
  <mcp>
    <server id="mcp_vision" transport="stdio" auto-start="true">
      <command>python</command>
      <args>-m mcp_vision_server</args>
    </server>
  </mcp>

  <!-- Agent Definitionen -->
  <agents>
    <agent id="agent_vision" type="reactive" name="Vision Analyzer">
      <capabilities>analyze, segment, upscale</capabilities>
      <mcp-server ref="mcp_vision"/>
    </agent>
  </agents>

  <!-- Projekt-Settings -->
  <settings>
    <setting key="theme" value="dark"/>
    <setting key="auto-save" value="true"/>
    <setting key="undo-limit" value="100"/>
  </settings>

</synth>
```

### 2. CompactEvents = Wire-Format (Runtime)

Events werden **zur Laufzeit** verwendet für:
- Kommunikation zwischen Komponenten
- Undo/Redo
- Collaboration (Multi-User)
- Replay/Recording

```
┌──────────────┐    CompactEvents    ┌──────────────┐
│   Editor     │ ◄─────────────────► │   Backend    │
└──────────────┘                     └──────────────┘
       │                                    │
       │ save                               │ state
       ▼                                    ▼
┌──────────────┐                     ┌──────────────┐
│ .synth.xml   │                     │   Database   │
│   (State)    │                     │   (State)    │
└──────────────┘                     └──────────────┘
```

### 3. Event-History (Optional in .synth.xml)

Für Undo/Redo und Recording kann eine Event-History eingebettet werden:

```xml
<synth version="1.0">
  <state><!-- aktueller Zustand --></state>

  <!-- Optional: Event-History für Undo -->
  <history enabled="true" max-events="100">
    <event id="evt_001" ts="1702468800000" correlation="session_001">
      <compact domain="cluster" resource="node" action="create"
               subject="node_tree_01" modifier="in" target="scene_outdoor">
        <arg key="name" value="Oak Tree"/>
      </compact>
    </event>
    <event id="evt_002" ts="1702468801000" correlation="session_001">
      <compact domain="component" resource="node" action="create"
               subject="comp_transform" modifier="on" target="node_tree_01">
        <arg key="type" value="transform"/>
      </compact>
    </event>
  </history>

  <!-- Undo/Redo Pointer -->
  <undo-stack current="evt_002"/>
</synth>
```

---

## Editor-Konzept: Multi-Mode Editor

Der Haupteditor unterstützt verschiedene Ansichten/Modi:

```
┌─────────────────────────────────────────────────────────────────┐
│  Synth Editor                                    [─] [□] [×]    │
├─────────────────────────────────────────────────────────────────┤
│  [Structure] [Events] [Script] [Raw XML] [Preview]              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┬───────────────────────────────────┐   │
│  │  Scene Hierarchy    │  Inspector / Properties           │   │
│  │  ─────────────────  │  ─────────────────────────────    │   │
│  │  ▼ scene_outdoor    │  Node: node_tree_01               │   │
│  │    ▼ folder_veg     │  ─────────────────────────────    │   │
│  │      ■ node_tree_01 │  Name: [Oak Tree        ]         │   │
│  │      ■ node_rock_01 │  Type: asset                      │   │
│  │    ▶ folder_props   │                                   │   │
│  │                     │  Transform:                       │   │
│  │                     │  Position: [10] [0] [5]           │   │
│  │                     │  Rotation: [0] [45] [0]           │   │
│  │                     │                                   │   │
│  └─────────────────────┴───────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Event Console (Live)                                    │   │
│  │  ─────────────────────────────────────────────────────  │   │
│  │  > cluster node create node_tree_01 in scene_outdoor    │   │
│  │  > component node create comp_transform on node_tree_01 │   │
│  │  > component node update comp_transform --position=...  │   │
│  │  > _                                                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  Events: 3 | Unsaved changes | Last save: 15:30               │
└─────────────────────────────────────────────────────────────────┘
```

### Tab-Modi:

1. **Structure** - Visueller Tree-Editor für Scene Graph
2. **Events** - CompactEvent Editor (wie v2) für direkte Event-Eingabe
3. **Script** - Script-Editor für eingebettete/externe Scripts
4. **Raw XML** - Direkter XML-Editor mit Schema-Validierung
5. **Preview** - 3D/2D Vorschau (wenn applicable)

---

## Workflow: Event → State

```
User Action (UI)
      │
      ▼
┌─────────────┐
│ Generate    │  "cluster node create node_01 in scene_01"
│ CompactEvent│
└─────────────┘
      │
      ├──────────────────┬─────────────────┐
      ▼                  ▼                 ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Apply to    │  │ Send via    │  │ Add to      │
│ State       │  │ Wire        │  │ Undo Stack  │
└─────────────┘  └─────────────┘  └─────────────┘
      │                  │
      ▼                  ▼
┌─────────────┐  ┌─────────────┐
│ Update UI   │  │ Sync to     │
│             │  │ Collaborators│
└─────────────┘  └─────────────┘
      │
      ▼
┌─────────────┐
│ Save to     │  (State → .synth.xml)
│ File        │
└─────────────┘
```

---

## Schema-Dateien

### synth-document.xsd (für .synth.xml)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
           targetNamespace="https://synth.dev/schema/1.0"
           xmlns:synth="https://synth.dev/schema/1.0">

  <xs:element name="synth">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="meta" type="synth:MetaType"/>
        <xs:element name="scenes" type="synth:ScenesType"/>
        <xs:element name="assets" type="synth:AssetsType" minOccurs="0"/>
        <xs:element name="mcp" type="synth:McpType" minOccurs="0"/>
        <xs:element name="agents" type="synth:AgentsType" minOccurs="0"/>
        <xs:element name="settings" type="synth:SettingsType" minOccurs="0"/>
        <xs:element name="history" type="synth:HistoryType" minOccurs="0"/>
      </xs:sequence>
      <xs:attribute name="version" type="xs:string" use="required"/>
    </xs:complexType>
  </xs:element>

  <!-- ... weitere Type-Definitionen ... -->

</xs:schema>
```

---

## Zusammenfassung

| Aspekt | .synth.xml (Dokument) | CompactEvents (Wire) |
|--------|----------------------|---------------------|
| **Zweck** | Persistenz, Projektdatei | Kommunikation, Änderungen |
| **Format** | XML (human-readable) | Protobuf/Binary (effizient) |
| **Inhalt** | State (aktueller Zustand) | Delta (was hat sich geändert) |
| **Verwendung** | Laden/Speichern | Runtime, Undo, Sync |
| **Editor** | Tree-View, Properties | Event Console, DSL |

### Empfehlung:

1. **Haupteditor** = Multi-Mode Editor mit Structure + Events + Raw XML
2. **.synth.xml** = State-basiert mit optionaler Event-History
3. **CompactEvents** = Für Runtime-Kommunikation und Undo/Redo
4. **Events in XML** = Als `<history>` Tag optional einbetten

Soll ich einen **HTML-Prototyp des Multi-Mode Editors** erstellen?
