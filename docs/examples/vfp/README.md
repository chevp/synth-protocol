# VFP-REST Examples

VFP (Virtual File Protocol) over REST/WebSocket - einheitliches Interface fuer beliebige Business Cases.

## Uebersicht

VFP-REST definiert **WIE** Daten transportiert werden, nicht **WAS** sie bedeuten.
Der Server implementiert die Business-Logik, der Client nutzt das einheitliche Interface.

```
┌─────────────────────────────────────────────────────────────────┐
│                     VFP-REST TRANSPORT LAYER                    │
│  HTTP: GET/PUT/DELETE/POST  │  WebSocket: WATCH/PUSH/DELTA      │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
   Game Server          CMS Server           E-Commerce
   (Physik, AI)        (Workflows)          (Inventar, Payment)
```

## Beispiele

| Datei | Beschreibung |
|-------|--------------|
| [01-chess-game.md](01-chess-game.md) | Schachspiel mit Zugvalidierung |
| [02-multiplayer-game.md](02-multiplayer-game.md) | AAA Multiplayer mit Realtime Sync |
| [03-cms-headless.md](03-cms-headless.md) | Headless CMS mit Publishing Workflow |
| [04-ecommerce.md](04-ecommerce.md) | E-Commerce mit Warenkorb und Bestellung |
| [05-collaborative-editor.md](05-collaborative-editor.md) | Collaborative Document Editor |

## Session Beispiele

| Datei | Beschreibung |
|-------|--------------|
| [10-vfp-unified-session.txt](10-vfp-unified-session.txt) | Alle 5 VFP Paradigmen |
| [11-vfp-rest-session.txt](11-vfp-rest-session.txt) | VFP-REST HTTP/WebSocket |
| [12-vfp-rest-synth-example.txt](12-vfp-rest-synth-example.txt) | Synth Projekt ueber VFP-REST |

## Tools

| Datei | Beschreibung |
|-------|--------------|
| [vfp-rest-client.html](vfp-rest-client.html) | Browser-basierter REST/WebSocket Client |

## Clients

VFP-REST kann mit jedem HTTP/WebSocket Client verwendet werden:

- **Browser**: fetch() + WebSocket
- **TypeScript/Three.js**: 3D Visualisierung
- **Electron**: Desktop Apps
- **Unity/C#**: Game Clients
- **Mobile**: React Native, Flutter