# Test: Remote .frost File Execution

## Problem (Gelöst)
Vorher: `.frost` Dateien konnten nur im gleichen Verzeichnis wie `frost-studio.exe` gestartet werden.

Jetzt: `.frost` Dateien können von überall gestartet werden.

## Implementierung

### 1. Absolute Path Resolution
`FrostRuntimeLoader` konvertiert den `.frost` Dateipfad zu einem absoluten Pfad und speichert das Verzeichnis:

```cpp
// In FrostRuntimeLoader.cpp
std::filesystem::path frostPath = std::filesystem::absolute(frostFile);
std::string frostFileDir = frostPath.parent_path().string();
outConfig.frostFileDir = frostFileDir;
```

### 2. Relative Scene Path Resolution
`ModelLoader` löst relative Scene-URIs relativ zum `.frost` Datei-Verzeichnis auf:

```cpp
// In ModelLoader.cpp
std::filesystem::path scenePath(sceneFile);
if (scenePath.is_relative()) {
    std::filesystem::path frostDir(runtimeConfig.frostFileDir);
    scenePath = frostDir / scenePath;
    sceneFile = scenePath.string();
}
```

## Test-Szenarien

### Szenario 1: Relative Scene URI
**Datei:** `C:\chevp\synth\synth-protocol\docs\schema\examples\runtime-frost-studio.frost`

```xml
<scene uri="file://index.elyrion.xml"/>
```

**Verhalten:**
1. `.frost` Datei Verzeichnis: `C:\chevp\synth\synth-protocol\docs\schema\examples\`
2. Scene URI: `index.elyrion.xml` (relativ)
3. Aufgelöst zu: `C:\chevp\synth\synth-protocol\docs\schema\examples\index.elyrion.xml`

### Szenario 2: Absolute Scene URI
```xml
<scene uri="file://C:/chevp/arctic/arctic-workspace/build/bin/Release/damaged-helmet.elyrion"/>
```

**Verhalten:**
1. Scene URI ist bereits absolut
2. Keine Pfad-Auflösung nötig
3. Direktes Laden der Datei

### Szenario 3: Doppelklick von Explorer
**Aktion:** Doppelklick auf `runtime-frost-studio.frost` im Windows Explorer

**Windows Befehl (nach Registrierung):**
```
"C:\chevp\arctic\arctic-workspace\build\bin\Release\frost-studio.exe" "C:\chevp\synth\synth-protocol\docs\schema\examples\runtime-frost-studio.frost"
```

**Verhalten:**
1. `frost-studio.exe` startet mit absolutem Pfad zur `.frost` Datei
2. Arbeitsverzeichnis kann beliebig sein (z.B. `C:\Windows\System32`)
3. Pfad-Auflösung funktioniert korrekt, da `.frost` Datei-Verzeichnis verwendet wird

## Registrierung (Optional)

Um `.frost` Dateien per Doppelklick zu öffnen, Windows Registry Eintrag erstellen:

```batch
REM Siehe: register-frost-extension.bat
reg add "HKEY_CLASSES_ROOT\.frost" /ve /d "FrostRuntimeFile" /f
reg add "HKEY_CLASSES_ROOT\FrostRuntimeFile\shell\open\command" /ve /d "\"C:\chevp\arctic\arctic-workspace\build\bin\Release\frost-studio.exe\" \"%%1\"" /f
```

## Vorteile

1. **Flexible Projekt-Struktur**: Game Assets können in separaten Ordnern organisiert werden
2. **Portable Configurations**: `.frost` Dateien können verschoben werden, solange relative Pfade korrekt sind
3. **Development Workflow**: Entwickler können `.frost` Dateien direkt aus Asset-Ordnern starten
4. **Cross-Directory Loading**: Mehrere Projekte können gleichzeitig existieren ohne Konflikte

## Beispiel: Game Asset Struktur

```
C:\chevp\synth\synth-playground\synth-game\
├── assets\
│   ├── scenes\
│   │   ├── main-menu.elyrion
│   │   ├── level-01.elyrion
│   │   └── boss-arena.elyrion
│   └── models\
│       ├── player.gltf
│       └── enemy.gltf
├── config\
│   ├── runtime-dev.frost         # Development runtime
│   ├── runtime-production.frost  # Production runtime
│   └── runtime-test.frost        # Testing runtime
└── start-dev.bat

# runtime-dev.frost
<scene uri="../assets/scenes/main-menu.elyrion"/>

# start-dev.bat
C:\chevp\arctic\arctic-workspace\build\bin\Release\frost-studio.exe config\runtime-dev.frost
```

Mit dieser Implementierung können Game-Entwickler ihre Assets außerhalb des `frost-studio.exe` Verzeichnisses organisieren.
