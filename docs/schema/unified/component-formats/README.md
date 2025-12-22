# Component Data Formats

## Übersicht

Components können in zwei Formaten gespeichert werden:

| Format | Spalte | Verwendung |
|--------|--------|------------|
| **XML** | `data_xml` | Human-readable, Git-freundlich, Editor |
| **Proto** | `data_blob` | Runtime-optimiert, schnelles Parsing |

## Empfohlener Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      COMPONENT WORKFLOW                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Editor / Authoring                                             │
│   ┌─────────────┐                                                │
│   │  data_xml   │  ← Human bearbeitet XML                        │
│   │  (TEXT)     │  ← Git-versioniert                             │
│   └──────┬──────┘                                                │
│          │                                                       │
│          │  Build / Export                                       │
│          ▼                                                       │
│   ┌─────────────┐                                                │
│   │  data_blob  │  ← Generiert aus XML (optional)                │
│   │  (BLOB)     │  ← Für schnelles Runtime-Loading               │
│   └──────┬──────┘                                                │
│          │                                                       │
│          │  Runtime                                              │
│          ▼                                                       │
│   ┌─────────────┐                                                │
│   │  C++ / Java │  ← Liest BLOB (schnell)                        │
│   │  Runtime    │  ← Oder parsed XML (Fallback)                  │
│   └─────────────┘                                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Vorteile von XML

1. **Ein Format für alle Components** - keine separate Proto-Message pro Typ
2. **Erweiterbar** - neue Felder ohne Schema-Änderung
3. **Human-readable** - direkt im Editor bearbeitbar
4. **Git-friendly** - sinnvolle Diffs
5. **Validierbar** - via XSD Schema

## Dateien

| Datei | Beschreibung |
|-------|--------------|
| `component.xsd` | XML Schema für Component-Validierung |
| `examples/` | Beispiel-XMLs für jeden Component-Typ |
