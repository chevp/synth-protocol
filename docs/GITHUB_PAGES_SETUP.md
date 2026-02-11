# GitHub Pages Setup für Synth Protocol Schemas

## Ziel

Die XML Schemas sollen unter folgenden URLs verfügbar sein:
- `https://chevp.github.io/synth-protocol/schema/synth/component/1.0/component.xsd`
- `https://chevp.github.io/synth-protocol/schema/synth/scene/1.0/scene.xsd`
- `https://chevp.github.io/synth-protocol/schema/synth/project/1.0/project.xsd`

## Setup Schritte

### 1. GitHub Pages aktivieren

1. Gehe zu: https://github.com/chevp/synth-protocol/settings/pages
2. Unter **Source**:
   - Branch: `main`
   - Folder: `/docs`
3. Klicke auf **Save**

### 2. Warten auf Deployment

GitHub Pages braucht 1-2 Minuten zum Deployment. Du siehst den Status unter:
- Actions: https://github.com/chevp/synth-protocol/actions

### 3. Testen

Nach dem Deployment, teste die URLs:

```bash
# Component Schema
curl https://chevp.github.io/synth-protocol/schema/synth/component/1.0/component.xsd

# Scene Schema
curl https://chevp.github.io/synth-protocol/schema/synth/scene/1.0/scene.xsd

# Index Page
open https://chevp.github.io/synth-protocol/schema/
```

### 4. DNS Konfiguration (Optional)

Falls du eine Custom Domain nutzen möchtest:
1. Füge CNAME Record hinzu: `synth-protocol.chevp.io` → `chevp.github.io`
2. In Repository Settings → Pages → Custom domain: `synth-protocol.chevp.io`

## Verzeichnisstruktur

```
synth-protocol/
├── .nojekyll                    # Verhindert Jekyll Processing
├── docs/
│   ├── schema/
│   │   ├── index.html           # Landing Page (https://chevp.github.io/synth-protocol/schema/)
│   │   ├── catalog.xml          # XML Catalog für IDEs
│   │   ├── README.md            # Dokumentation
│   │   └── synth/
│   │       ├── component/
│   │       │   └── 1.0/
│   │       │       └── component.xsd
│   │       ├── scene/
│   │       │   └── 1.0/
│   │       │       └── scene.xsd
│   │       └── project/
│   │           └── 1.0/
│   │               └── project.xsd
│   └── ...
```

## Wichtig

- Die `.nojekyll` Datei **muss** im Repository Root liegen
- Schemas liegen in `docs/schema/synth/` nicht `docs/`
- Die URL-Struktur muss exakt mit `xmlns` in XML Dateien übereinstimmen

## Troubleshooting

### Schemas nicht erreichbar (404)

1. Prüfe GitHub Actions: https://github.com/chevp/synth-protocol/actions
2. Warte 2-3 Minuten nach Push
3. Prüfe ob `.nojekyll` existiert: https://github.com/chevp/synth-protocol/blob/main/.nojekyll

### Falsche URL

Die URL **muss** mit der Verzeichnisstruktur übereinstimmen:
- xmlns: `https://chevp.github.io/synth-protocol/schema/synth/component/1.0`
- Datei: `docs/schema/synth/component/1.0/component.xsd`

### CORS Probleme

GitHub Pages liefert automatisch korrekte CORS Headers für XSD Dateien.

## Nach dem Setup

1. Teste alle Schema URLs
2. Validiere ein XML Dokument gegen die Online-Schemas
3. Update die README im synth-game Repository mit den Schema URLs
