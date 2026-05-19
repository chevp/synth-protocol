# Lokale Schema-Validierung

## Übersicht

Die XML Schemas können lokal validiert werden, ohne GitHub Pages. Die Public URLs (`https://chevp.github.io/...`) werden über einen XML Katalog auf lokale Dateien gemappt.

## VSCode Setup (C:\chevp Workspace)

### 1. XML Extension installieren

Installiere die **XML** Extension von Red Hat:
- Extension ID: `redhat.vscode-xml`
- Marketplace: https://marketplace.visualstudio.com/items?itemName=redhat.vscode-xml

### 2. Workspace Settings

Die [.vscode/settings.json](c:/chevp/.vscode/settings.json) im Workspace-Root ist bereits konfiguriert:

```json
{
  "xml.catalogs": [
    "synth/synth-protocol/docs/schema/catalog.xml"
  ],
  "xml.validation.enabled": true,
  "xml.validation.namespaces.enabled": "always",
  "xml.fileAssociations": [
    {
      "pattern": "**/components/**/*.synth.xml",
      "systemId": "${workspaceFolder}/synth/synth-protocol/docs/schema/synth/component/1.0/component.xsd"
    },
    {
      "pattern": "**/scenes/**/*.synth.xml",
      "systemId": "${workspaceFolder}/synth/synth-protocol/docs/schema/synth/scene/1.0/scene.xsd"
    }
  ]
}
```

### 3. Wie es funktioniert

**Zwei-Ebenen Mapping:**

1. **XML Datei** verwendet Public URL:
   ```xml
   <synthComponent xmlns="https://chevp.github.io/synth-protocol/schema/synth/component/1.0">
   ```

2. **XML Catalog** mappt URL → lokaler Pfad:
   ```xml
   <uri name="https://chevp.github.io/synth-protocol/schema/synth/component/1.0"
        uri="synth/component/1.0/component.xsd"/>
   ```

3. **VSCode** löst relativ vom Katalog-Verzeichnis auf:
   ```
   c:/chevp/synth/synth-protocol/docs/schema/catalog.xml
   → synth/component/1.0/component.xsd
   = c:/chevp/synth/synth-protocol/docs/schema/synth/component/1.0/component.xsd
   ```

**Zusätzlich:** `xml.fileAssociations` mappt File-Pattern direkt auf Schema via `${workspaceFolder}` Variable.

## Validierung testen

### In VSCode

1. Öffne eine `.synth.xml` Datei (z.B. `bakery.synth.xml`)
2. Fehlerhafte Syntax wird rot unterstrichen
3. Autocomplete funktioniert (Ctrl+Space)
4. Hover zeigt Schema-Dokumentation

### Kommandozeile (xmllint)

```bash
# Linux/macOS/WSL
cd c:/chevp
xmllint --schema synth/synth-protocol/docs/schema/synth/component/1.0/component.xsd \
        synth/synth-playground/synth-game/assets/src/components/buildings/bakery.synth.xml

# Windows (mit xmllint.exe im PATH)
cd c:\chevp
xmllint.exe --schema synth\synth-protocol\docs\schema\synth\component\1.0\component.xsd ^
            synth\synth-playground\synth-game\assets\src\components\buildings\bakery.synth.xml
```

### PowerShell Validation Script

```powershell
# validate-synth-xml.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$XmlFile,

    [Parameter(Mandatory=$false)]
    [string]$SchemaFile
)

$workspaceRoot = "C:\chevp"
$catalogPath = "$workspaceRoot\synth\synth-protocol\docs\schema\catalog.xml"

# Auto-detect schema based on file pattern
if (-not $SchemaFile) {
    if ($XmlFile -like "*\components\*") {
        $SchemaFile = "$workspaceRoot\synth\synth-protocol\docs\schema\synth\component\1.0\component.xsd"
    }
    elseif ($XmlFile -like "*\scenes\*") {
        $SchemaFile = "$workspaceRoot\synth\synth-protocol\docs\schema\synth\scene\1.0\scene.xsd"
    }
    else {
        Write-Error "Could not auto-detect schema. Please specify -SchemaFile parameter."
        exit 1
    }
}

Write-Host "Validating: $XmlFile"
Write-Host "Schema: $SchemaFile"

# Using .NET XmlDocument with XSD validation
$xml = New-Object System.Xml.XmlDocument
$xml.Schemas.Add($null, $SchemaFile)

try {
    $xml.Load($XmlFile)
    $xml.Validate({
        param($sender, $e)
        Write-Error $e.Message
    })
    Write-Host "✓ Validation successful!" -ForegroundColor Green
}
catch {
    Write-Error "✗ Validation failed: $_"
    exit 1
}
```

**Usage:**
```powershell
.\validate-synth-xml.ps1 -XmlFile "synth\synth-playground\synth-game\assets\src\components\buildings\bakery.synth.xml"
```

## Vorteile lokaler Validierung

✅ **Offline Development** - Keine Internet-Verbindung nötig
✅ **Schneller** - Keine HTTP Requests
✅ **Versionskontrolle** - Schemas im Git Repository
✅ **IDE Integration** - Autocomplete, Fehlerprüfung, Hover-Docs
✅ **CI/CD** - Kann in Build-Pipelines integriert werden

## Troubleshooting

### Schemas werden nicht erkannt

1. **Prüfe XML Extension:**
   ```
   VSCode → Extensions → "XML" by Red Hat
   ```

2. **Reload VSCode Window:**
   ```
   Ctrl+Shift+P → "Developer: Reload Window"
   ```

3. **Prüfe Katalog-Pfad:**
   ```json
   "xml.catalogs": [
     "synth/synth-protocol/docs/schema/catalog.xml"  // Relativ vom Workspace Root
   ]
   ```

4. **Prüfe ob Workspace Root korrekt:**
   ```
   VSCode → File → Open Folder → C:\chevp
   ```

### Namespace-Fehler

Stelle sicher, dass die xmlns URL exakt mit dem Katalog übereinstimmt:

**XML Datei:**
```xml
xmlns="https://chevp.github.io/synth-protocol/schema/synth/component/1.0"
```

**Katalog:**
```xml
<uri name="https://chevp.github.io/synth-protocol/schema/synth/component/1.0"
     uri="synth/component/1.0/component.xsd"/>
```

### VSCode zeigt keine Autocomplete

1. Cursor in XML Tag platzieren
2. `Ctrl+Space` drücken
3. Falls nichts erscheint: Prüfe ob `xml.validation.enabled: true`

## Migration zu GitHub Pages

Wenn später GitHub Pages aktiviert wird:
- **Keine Änderungen nötig!** ✨
- Die URLs bleiben gleich
- VSCode nutzt weiterhin den Katalog (schneller)
- Browser/externe Tools nutzen GitHub Pages (Public)

## Weitere Informationen

- [XML Catalog Spec](https://www.oasis-open.org/committees/download.php/14809/xml-catalogs.html)
- [VSCode XML Extension Docs](https://github.com/redhat-developer/vscode-xml)
- [Schema README](README.md)
