# VFP-REST: Chess Game

Schachspiel mit Server-seitiger Zugvalidierung.

## Architektur

```
┌─────────────────┐                    ┌─────────────────┐
│  Chess Client   │   VFP-REST/WS      │  Chess Server   │
│  (TypeScript)   │ ◄───────────────►  │  (PHP/Java)     │
│                 │                    │                 │
│  - Board UI     │                    │  - Validierung  │
│  - Drag & Drop  │                    │  - Schachmatt   │
│  - Animations   │                    │  - ELO Rating   │
└─────────────────┘                    └─────────────────┘
```

## URL Schema

```
/vfp/games/{gameId}/
    state.json          Aktueller Spielstand
    moves/              Alle Zuege
        001.json        Zug 1
        002.json        Zug 2
        ...
    players/
        white.json      Weiss Spieler
        black.json      Schwarz Spieler
    chat/               Chat Nachrichten
```

## Spiel erstellen

```http
PUT /vfp/games/game_001/state.json HTTP/1.1
Content-Type: application/json
X-Vfp-Message: New chess game

{
  "id": "game_001",
  "status": "waiting",
  "board": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR",
  "turn": "white",
  "moveCount": 0,
  "whitePlayer": null,
  "blackPlayer": null,
  "createdAt": 1733400000000
}
```

**Response:**
```http
HTTP/1.1 201 Created
X-Vfp-Tick: 1
ETag: "game_v1"
```

## Spiel beitreten

```http
PUT /vfp/games/game_001/players/white.json HTTP/1.1
Content-Type: application/json

{
  "userId": "user_alice",
  "name": "Alice",
  "elo": 1500,
  "joinedAt": 1733400100000
}
```

**Server aktualisiert state.json automatisch:**
```json
{
  "status": "waiting",
  "whitePlayer": "user_alice"
}
```

## Zug ausfuehren

```http
PUT /vfp/games/game_001/moves/001.json HTTP/1.1
Content-Type: application/json
X-Vfp-Message: e2-e4

{
  "from": "e2",
  "to": "e4",
  "piece": "pawn",
  "player": "white",
  "timestamp": 1733400200000
}
```

**Server validiert und antwortet:**

Erfolg:
```http
HTTP/1.1 201 Created
X-Vfp-Tick: 5

{
  "valid": true,
  "newBoard": "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR",
  "turn": "black",
  "check": false,
  "checkmate": false
}
```

Fehler (ungueltiger Zug):
```http
HTTP/1.1 400 Bad Request

{
  "code": "INVALID_MOVE",
  "message": "Pawn cannot move diagonally without capture",
  "from": "e2",
  "to": "d3"
}
```

## Realtime Updates (WebSocket)

**Client verbindet:**
```
ws://chess.example.com/vfp/realtime
```

**WATCH abonnieren:**
```json
{
  "id": "req-001",
  "op": "WATCH",
  "payload": {
    "patterns": ["/games/game_001/*"],
    "initial": true
  }
}
```

**Server sendet DELTA bei Gegnerzug:**
```json
{
  "op": "DELTA",
  "payload": {
    "tick": 6,
    "nodes": [
      {
        "path": "/games/game_001/state.json",
        "op": "update",
        "fields": [
          { "field": "board", "value": "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR" },
          { "field": "turn", "value": "white" },
          { "field": "moveCount", "value": 2 }
        ]
      },
      {
        "path": "/games/game_001/moves/002.json",
        "op": "create",
        "data": {
          "from": "e7",
          "to": "e5",
          "piece": "pawn",
          "player": "black"
        }
      }
    ]
  }
}
```

## Spielhistorie abrufen

```http
GET /vfp/games/game_001/_log?limit=50 HTTP/1.1
```

**Response:**
```json
{
  "entries": [
    { "version": { "tick": 6 }, "message": "e7-e5", "changes": 2 },
    { "version": { "tick": 5 }, "message": "e2-e4", "changes": 2 },
    { "version": { "tick": 3 }, "message": "Black joined", "changes": 1 },
    { "version": { "tick": 2 }, "message": "White joined", "changes": 1 },
    { "version": { "tick": 1 }, "message": "New chess game", "changes": 1 }
  ]
}
```

## Zug zuruecknehmen (Revert)

```http
POST /vfp/games/game_001/_revert HTTP/1.1
Content-Type: application/json

{
  "to_tick": 5,
  "message": "Takeback accepted"
}
```

## TypeScript Client

```typescript
class ChessClient {
    private vfp: VfpClient;
    private gameId: string;

    async makeMove(from: string, to: string): Promise<MoveResult> {
        const moveNum = this.state.moveCount + 1;
        const path = `/games/${this.gameId}/moves/${String(moveNum).padStart(3, '0')}.json`;

        try {
            return await this.vfp.write(path, {
                from, to,
                piece: this.getPieceAt(from),
                player: this.state.turn,
                timestamp: Date.now()
            });
        } catch (e) {
            if (e.code === 'INVALID_MOVE') {
                this.showError(e.message);
            }
            throw e;
        }
    }

    onOpponentMove(delta: VfpDelta): void {
        // Server hat Gegnerzug validiert - UI aktualisieren
        this.updateBoard(delta.fields.find(f => f.field === 'board')?.value);
        this.playMoveSound();
    }
}
```