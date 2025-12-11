# VFP-REST: Multiplayer Game

AAA Multiplayer Game mit Realtime State Sync, Client Prediction und Server Reconciliation.

## Architektur

```
┌─────────────────┐                    ┌─────────────────┐
│  Game Client    │   VFP-REST/WS      │  Game Server    │
│  (Three.js)     │ ◄───────────────►  │  (Authoritative)│
│                 │                    │                 │
│  - 3D Rendering │                    │  - Physik       │
│  - Input        │                    │  - Kollision    │
│  - Prediction   │                    │  - Anti-Cheat   │
│  - Interpolation│                    │  - Matchmaking  │
└─────────────────┘                    └─────────────────┘
```

## URL Schema

```
/vfp/worlds/{worldId}/
    meta.json               World Metadaten
    players/
        {playerId}.json     Spieler State
    entities/
        {entityId}.json     NPCs, Items, Projectiles
    terrain/
        chunk_{x}_{z}.json  Terrain Chunks
    events/                 Game Events (Kills, Captures)
```

## World State

```http
GET /vfp/worlds/world_001/meta.json HTTP/1.1
```

```json
{
  "id": "world_001",
  "name": "Battle Arena",
  "mode": "deathmatch",
  "maxPlayers": 64,
  "currentPlayers": 42,
  "tickRate": 60,
  "serverTick": 158432,
  "bounds": {
    "min": [-500, 0, -500],
    "max": [500, 100, 500]
  }
}
```

## Player State

```http
GET /vfp/worlds/world_001/players/player_001.json HTTP/1.1
```

```json
{
  "id": "player_001",
  "name": "ProGamer99",
  "team": "red",
  "position": [125.5, 2.0, -340.2],
  "rotation": [0, 1.57, 0],
  "velocity": [5.0, 0, 2.5],
  "health": 85,
  "armor": 50,
  "weapon": "rifle",
  "ammo": 24,
  "state": "running",
  "lastInputSeq": 45623,
  "updatedAt": 1733400500000
}
```

## Realtime Connection

```json
{
  "id": "req-001",
  "op": "WATCH",
  "payload": {
    "patterns": [
      "/worlds/world_001/players/*",
      "/worlds/world_001/entities/*",
      "/worlds/world_001/events/*"
    ],
    "initial": true,
    "from_tick": 158000
  }
}
```

## Client Input (PUSH)

Client sendet Input mit Prediction:

```json
{
  "id": "input-45624",
  "op": "PUSH",
  "payload": {
    "path": "/worlds/world_001/players/player_001",
    "field": "input",
    "value": {
      "seq": 45624,
      "tick": 158433,
      "keys": ["W", "A"],
      "mouseX": 0.05,
      "mouseY": -0.02,
      "actions": ["fire"]
    },
    "predicted": true
  }
}
```

## Server ACK

```json
{
  "id": "input-45624",
  "op": "ACK",
  "payload": {
    "tick": 158434,
    "seq": 45624
  }
}
```

## Server DELTA (Broadcast)

```json
{
  "op": "DELTA",
  "payload": {
    "tick": 158434,
    "nodes": [
      {
        "path": "/players/player_001",
        "op": "update",
        "fields": [
          { "field": "position", "value": [126.2, 2.0, -339.8] },
          { "field": "rotation", "value": [0, 1.62, 0] },
          { "field": "ammo", "value": 23 }
        ]
      },
      {
        "path": "/players/player_042",
        "op": "update",
        "fields": [
          { "field": "position", "value": [130.1, 2.0, -335.5] },
          { "field": "health", "value": 72 }
        ]
      },
      {
        "path": "/entities/projectile_8821",
        "op": "create",
        "data": {
          "type": "bullet",
          "origin": [126.2, 3.5, -339.8],
          "direction": [0.8, 0, 0.6],
          "owner": "player_001"
        }
      }
    ]
  }
}
```

## Server CORRECTION

Wenn Client-Prediction falsch war:

```json
{
  "op": "CORRECTION",
  "payload": {
    "tick": 158434,
    "path": "/players/player_001",
    "field": "position",
    "value": [125.8, 2.0, -340.0],
    "rejected_seq": 45624,
    "reason": "Wall collision"
  }
}
```

## Entity Spawning

```http
PUT /vfp/worlds/world_001/entities/item_5501.json HTTP/1.1
Content-Type: application/json

{
  "type": "health_pack",
  "position": [200, 1, -100],
  "respawnTime": 30,
  "value": 50
}
```

## Kill Event

Server erzeugt Event:

```json
{
  "op": "DELTA",
  "payload": {
    "tick": 158500,
    "nodes": [
      {
        "path": "/events/kill_1234",
        "op": "create",
        "data": {
          "type": "kill",
          "killer": "player_001",
          "victim": "player_042",
          "weapon": "rifle",
          "headshot": true,
          "timestamp": 1733400600000
        }
      },
      {
        "path": "/players/player_042",
        "op": "update",
        "fields": [
          { "field": "health", "value": 0 },
          { "field": "state", "value": "dead" },
          { "field": "respawnAt", "value": 1733400610000 }
        ]
      }
    ]
  }
}
```

## TypeScript + Three.js Client

```typescript
class GameClient {
    private vfp: VfpClient;
    private scene: THREE.Scene;
    private players = new Map<string, PlayerEntity>();
    private inputBuffer: InputFrame[] = [];
    private lastAckedSeq = 0;

    connect(worldId: string): void {
        this.vfp.connect(`ws://game.example.com/vfp/realtime`);

        this.vfp.watch(`/worlds/${worldId}/players/*`, (delta) => {
            this.handlePlayerDelta(delta);
        });

        this.vfp.watch(`/worlds/${worldId}/entities/*`, (delta) => {
            this.handleEntityDelta(delta);
        });

        this.vfp.onCorrection((correction) => {
            this.reconcile(correction);
        });
    }

    // Client Prediction
    processInput(input: InputFrame): void {
        // 1. Speichere Input
        this.inputBuffer.push(input);

        // 2. Sende an Server
        this.vfp.push(`/worlds/${this.worldId}/players/${this.playerId}`, 'input', {
            seq: input.seq,
            tick: this.serverTick,
            keys: input.keys,
            mouseX: input.mouseX,
            mouseY: input.mouseY,
            actions: input.actions
        });

        // 3. Lokale Prediction anwenden
        this.predictMovement(input);
    }

    // Server Reconciliation
    reconcile(correction: VfpCorrection): void {
        // 1. Setze auf Server-State zurueck
        this.localPlayer.position.set(...correction.value);

        // 2. Replay alle Inputs nach rejected_seq
        const replayInputs = this.inputBuffer.filter(i => i.seq > correction.rejected_seq);
        for (const input of replayInputs) {
            this.predictMovement(input);
        }
    }

    // Entity Interpolation
    handlePlayerDelta(delta: VfpNodeDelta): void {
        const playerId = delta.path.split('/').pop();
        const player = this.players.get(playerId);

        if (player && playerId !== this.playerId) {
            // Andere Spieler: Interpolation
            const posField = delta.fields.find(f => f.field === 'position');
            if (posField) {
                player.targetPosition.set(...posField.value);
            }
        }
    }

    // Render Loop
    update(dt: number): void {
        // Interpoliere andere Spieler
        for (const [id, player] of this.players) {
            if (id !== this.playerId) {
                player.mesh.position.lerp(player.targetPosition, 10 * dt);
            }
        }
    }
}
```

## Server Authority

Der Server hat volle Autoritaet ueber:

- **Physik**: Bewegung, Kollision, Gravitation
- **Schaden**: Hit Detection, Damage Calculation
- **Spiellogik**: Respawn, Scoring, Round End
- **Anti-Cheat**: Speed Checks, Aim Validation

Der Client zeigt nur an, was der Server erlaubt.