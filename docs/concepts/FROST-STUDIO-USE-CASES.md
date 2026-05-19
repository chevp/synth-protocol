# Frost Studio - Use Cases & File Types

## Overview

`frost-studio.exe` ist der **universelle Einstiegspunkt** für alle Szenarien. Die Anwendung erkennt automatisch den Dateityp und startet die entsprechenden Komponenten.

## File Type Detection

| Dateiendung | Root Element | Zweck | Startet |
|-------------|--------------|-------|---------|
| `.frost` | `<synthRuntimeRenderer>` | Renderer-Only (Game Player) | Renderer |
| `.synth-game` | `<synthGameProject>` | Complete Dev Environment | Backend + Renderer |
| `.elyrion` | `<Elyrion>` | Scene Preview | Renderer (Quick Mode) |

## Use Cases

### 1. Game Player (Play Mode)

**Workflow:**
```
Doppelklick: my-game.frost
  → Startet frost-studio.exe
  → Lädt Renderer-Only Konfiguration
  → Verbindet zu existierendem Game-Server (lokal oder remote)
  → Keine Editor-Features
```

**Konfiguration:** `my-game.frost`
```xml
<synthRuntimeRenderer version="1.0" xmlns="...">
    <metadata>
        <name>My Awesome Game</name>
        <client>frost-studio</client>
    </metadata>

    <renderer>
        <api type="vulkan" version="1.0"/>
        <window width="1920" height="1080" fullscreen="true" vsync="true"/>
    </renderer>

    <scene uri="file://main-menu.elyrion"/>

    <settings>
        <setting key="editMode" value="false"/>           <!-- NO EDITOR -->
        <setting key="gameServerUrl" value="http://localhost:8090"/>
    </settings>
</synthRuntimeRenderer>
```

**Eigenschaften:**
- ✅ Fullscreen optimiert
- ✅ Keine ImGui-Overlays
- ✅ Verbindet zu Game-Server
- ❌ Keine Development-Tools

---

### 2. Game Developer (Editor Mode)

**Workflow:**
```
Doppelklick: my-game.synth-game
  → Startet frost-studio.exe
  → Erkennt .synth-game Format
  → Startet Backend-Server (runtime-synth-game.synth)
  → Startet Renderer mit Editor (runtime-frost-studio.frost)
  → Vollständige Development-Umgebung
```

**Konfiguration:** `my-game.synth-game`
```xml
<synthGameProject version="1.0" xmlns="...">
    <metadata>
        <name>My Awesome Game</name>
        <description>Complete game development project</description>
        <version>0.1.0</version>
        <author>chevp</author>
    </metadata>

    <backend>
        <runtime>runtime-synth-game.synth</runtime>
        <autoStart>true</autoStart>
        <waitForReady>true</waitForReady>
        <startupTimeout>30</startupTimeout>
    </backend>

    <renderer>
        <runtime>runtime-frost-studio.frost</runtime>
        <autoStart>true</autoStart>
    </renderer>

    <paths>
        <assets>assets/src</assets>
        <scenes>assets/src/scenes</scenes>
        <components>assets/src/components</components>
        <data>data</data>
    </paths>

    <launcher>
        <startupOrder>sequential</startupOrder>
        <showConsole>true</showConsole>
    </launcher>
</synthGameProject>
```

**Eigenschaften:**
- ✅ Editor-Mode (ImGui)
- ✅ Backend-Server automatisch gestartet
- ✅ Hot-reload, Debug-Tools
- ✅ Windowed-Mode für Multi-Monitor

---

### 3. Scene Preview (Quick Mode)

**Workflow:**
```
Doppelklick: my-scene.elyrion
  → Startet frost-studio.exe
  → Lädt Scene direkt
  → Minimale Renderer-Konfiguration (Defaults)
  → Schneller Preview
```

**Eigenschaften:**
- ✅ Schnellster Start
- ✅ Keine Backend-Verbindung
- ✅ Ideal für Asset-Preview

---

## Startup Logic in frost-studio.exe

```cpp
// In Application.cpp

std::string ext = getFileExtension(appSettings.inputFile);

if (ext == "frost") {
    // Renderer-Only Mode (Game Player)
    frost::RuntimeConfig runtimeConfig;
    FrostRuntimeLoader::loadFrostRuntime(appSettings.inputFile, runtimeConfig);
    // NO backend startup
    startRenderer(runtimeConfig);
}
else if (ext == "synth-game") {
    // Complete Development Mode (Editor)
    GameProjectConfig projectConfig;
    GameProjectLoader::loadGameProject(appSettings.inputFile, projectConfig);

    // Start backend first
    startBackend(projectConfig.backendRuntime);
    waitForBackendReady();

    // Then start renderer with editor
    startRenderer(projectConfig.rendererRuntime);
}
else if (ext == "elyrion") {
    // Quick Scene Preview
    createDefaultRuntimeConfig();
    loadSceneDirect(appSettings.inputFile);
    startRenderer(defaultConfig);
}
```

---

## File Location Recommendations

### Development Project Structure

```
C:\MyGames\AwesomeGame\
├── my-game.synth-game          # Developer entry point (double-click)
├── runtime-synth-game.synth    # Backend configuration
├── runtime-frost-studio.frost  # Editor renderer configuration
├── my-game-launcher.frost      # Player entry point (for distribution)
├── assets\
│   └── src\
│       ├── scenes\
│       │   ├── main-menu.elyrion
│       │   └── level-01.elyrion
│       └── components\
├── backend\
│   └── target\
│       └── synth-game-backend-runner.jar
└── data\
    └── synth-game.db
```

### Player Distribution

```
AwesomeGame-Release\
├── my-game.frost               # Player double-clicks this
├── frost-studio.exe            # Bundled renderer
├── assets\
│   └── (compiled assets)
└── config.json
```

---

## Registry Integration (Windows)

Nach Ausführung von `register-frost-extension.bat`:

```
.frost      → "C:\...\frost-studio.exe" "%1"
.synth-game → "C:\...\frost-studio.exe" "%1"
.elyrion    → "C:\...\frost-studio.exe" "%1"
```

Alle drei Dateitypen können per Doppelklick gestartet werden.

---

## Summary

| Rolle | Ziel | Startet | Datei |
|-------|------|---------|-------|
| **Player** | Spiel spielen | `my-game.frost` | Renderer only |
| **Developer** | Spiel entwickeln | `my-game.synth-game` | Backend + Renderer |
| **Artist** | Scene preview | `my-scene.elyrion` | Renderer (quick) |

Alle nutzen **frost-studio.exe** - nur die Eingabedatei unterscheidet sich.
