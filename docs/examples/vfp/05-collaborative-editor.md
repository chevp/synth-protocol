# VFP-REST: Collaborative Editor

Echtzeit Collaborative Document Editor wie Google Docs.

## Architektur

```
┌─────────────────┐                    ┌─────────────────┐
│  Editor Client  │   VFP WebSocket    │  Collab Server  │
│  (React)        │ ◄───────────────►  │  (Node.js)      │
│                 │                    │                 │
│  - ProseMirror  │                    │  - OT/CRDT      │
│  - Cursors      │                    │  - Presence     │
│  - Comments     │                    │  - Versioning   │
└─────────────────┘                    └─────────────────┘
        │                                      │
        │                              ┌───────▼───────┐
        │                              │   Storage     │
        │                              │  (SQLite/S3)  │
        └──────────────────────────────┴───────────────┘
```

## URL Schema

```
/vfp/workspaces/{wsId}/
    meta.json                   Workspace Konfiguration
    documents/
        {docId}/
            content.json        Document Content (CRDT State)
            meta.json           Metadaten
            comments/
                {commentId}.json
            history/            Revision History
    presence/
        {sessionId}.json        Aktive Sessions
    permissions/
        {userId}.json           Berechtigungen
```

## Document erstellen

```http
PUT /vfp/workspaces/ws_001/documents/doc_001/content.json HTTP/1.1
Content-Type: application/json
X-Vfp-Message: Create new document

{
  "type": "doc",
  "version": 0,
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 1 },
      "content": [{ "type": "text", "text": "Untitled Document" }]
    },
    {
      "type": "paragraph",
      "content": []
    }
  ]
}
```

## Realtime Verbindung

```json
{
  "id": "req-001",
  "op": "WATCH",
  "payload": {
    "patterns": [
      "/workspaces/ws_001/documents/doc_001/*",
      "/workspaces/ws_001/presence/*"
    ],
    "initial": true
  }
}
```

## Presence anmelden

Client meldet sich an:

```json
{
  "id": "req-002",
  "op": "PUSH",
  "payload": {
    "path": "/workspaces/ws_001/presence/sess_abc123",
    "field": "user",
    "value": {
      "userId": "user_001",
      "name": "Alice",
      "color": "#FF5722",
      "cursor": null,
      "selection": null,
      "documentId": "doc_001",
      "lastSeen": 1733400000000
    }
  }
}
```

## Cursor Position senden

```json
{
  "id": "input-1001",
  "op": "PUSH",
  "payload": {
    "path": "/workspaces/ws_001/presence/sess_abc123",
    "field": "cursor",
    "value": {
      "anchor": 145,
      "head": 145
    },
    "seq": 1001
  }
}
```

## Andere User sehen Cursor

```json
{
  "op": "DELTA",
  "payload": {
    "tick": 500,
    "nodes": [
      {
        "path": "/presence/sess_xyz789",
        "op": "update",
        "fields": [
          {
            "field": "cursor",
            "value": { "anchor": 200, "head": 220 }
          }
        ]
      }
    ]
  }
}
```

## Text Operation senden (OT/CRDT)

Client sendet Operation:

```json
{
  "id": "op-1002",
  "op": "PUSH",
  "payload": {
    "path": "/workspaces/ws_001/documents/doc_001/content",
    "field": "operation",
    "value": {
      "type": "insert",
      "position": 145,
      "text": "Hello, ",
      "clientId": "sess_abc123",
      "parentVersion": 42,
      "seq": 1002
    },
    "predicted": true
  }
}
```

## Server transformiert und broadcastet

```json
{
  "op": "DELTA",
  "payload": {
    "tick": 501,
    "nodes": [
      {
        "path": "/documents/doc_001/content",
        "op": "update",
        "fields": [
          {
            "field": "version",
            "value": 43
          },
          {
            "field": "operation",
            "value": {
              "type": "insert",
              "position": 145,
              "text": "Hello, ",
              "author": "user_001",
              "serverSeq": 501
            }
          }
        ]
      }
    ]
  }
}
```

## Konflikt-Korrektur

Wenn zwei User gleichzeitig an derselben Stelle tippen:

```json
{
  "op": "CORRECTION",
  "payload": {
    "tick": 502,
    "path": "/documents/doc_001/content",
    "field": "operation",
    "value": {
      "type": "insert",
      "position": 152,
      "text": "Hello, ",
      "transformed": true
    },
    "rejected_seq": 1002,
    "reason": "Position shifted by concurrent edit"
  }
}
```

## Kommentar hinzufuegen

```http
PUT /vfp/workspaces/ws_001/documents/doc_001/comments/cmt_001.json HTTP/1.1
Content-Type: application/json

{
  "id": "cmt_001",
  "author": "user_002",
  "authorName": "Bob",
  "text": "Should we rephrase this?",
  "selection": {
    "from": 145,
    "to": 165
  },
  "resolved": false,
  "replies": [],
  "createdAt": 1733401000000
}
```

**Realtime Broadcast:**
```json
{
  "op": "DELTA",
  "payload": {
    "tick": 510,
    "nodes": [
      {
        "path": "/documents/doc_001/comments/cmt_001.json",
        "op": "create",
        "data": {
          "id": "cmt_001",
          "author": "user_002",
          "text": "Should we rephrase this?",
          "selection": { "from": 145, "to": 165 }
        }
      }
    ]
  }
}
```

## Version History

```http
GET /vfp/workspaces/ws_001/documents/doc_001/_log?limit=20 HTTP/1.1
```

```json
{
  "entries": [
    {
      "version": { "tick": 510, "hash": "abc123" },
      "message": "Auto-save",
      "changes": 15,
      "author": "user_001"
    },
    {
      "version": { "tick": 450, "hash": "def456" },
      "message": "Added introduction",
      "changes": 8,
      "author": "user_002"
    }
  ]
}
```

## Zu Version zurueckspringen

```http
POST /vfp/workspaces/ws_001/documents/doc_001/_revert HTTP/1.1
Content-Type: application/json

{
  "to_tick": 450,
  "message": "Revert to previous version"
}
```

## Document Snapshot laden

Bei reconnect oder neuem Tab:

```json
{
  "id": "req-010",
  "op": "PULL",
  "payload": {
    "path": "/workspaces/ws_001/documents/doc_001/content.json",
    "format": "json"
  }
}
```

**Response:**
```json
{
  "id": "req-010",
  "op": "PULL_OK",
  "payload": {
    "tick": 510,
    "data": {
      "type": "doc",
      "version": 510,
      "content": [...]
    }
  }
}
```

## React + ProseMirror Integration

```tsx
function CollaborativeEditor({ workspaceId, documentId }: Props) {
    const vfp = useVfpClient();
    const editorRef = useRef<EditorView | null>(null);
    const [presence, setPresence] = useState<Map<string, UserPresence>>(new Map());

    useEffect(() => {
        // Connect
        vfp.connect(`ws://collab.example.com/vfp/realtime`);

        // Load initial document
        vfp.pull(`/workspaces/${workspaceId}/documents/${documentId}/content.json`)
           .then(snapshot => {
               initializeEditor(snapshot.data);
           });

        // Watch document changes
        vfp.watch(`/workspaces/${workspaceId}/documents/${documentId}/*`, (delta) => {
            if (delta.fields.find(f => f.field === 'operation')) {
                applyRemoteOperation(delta);
            }
        });

        // Watch presence
        vfp.watch(`/workspaces/${workspaceId}/presence/*`, (delta) => {
            updatePresence(delta);
        });

        // Register presence
        registerPresence();

        return () => {
            unregisterPresence();
        };
    }, [workspaceId, documentId]);

    function onLocalChange(tr: Transaction) {
        if (!tr.docChanged) return;

        // Send operation to server
        const operation = transactionToOperation(tr);
        vfp.push(
            `/workspaces/${workspaceId}/documents/${documentId}/content`,
            'operation',
            operation
        );
    }

    function onSelectionChange(selection: Selection) {
        vfp.push(
            `/workspaces/${workspaceId}/presence/${sessionId}`,
            'cursor',
            { anchor: selection.anchor, head: selection.head }
        );
    }

    return (
        <div className="editor-container">
            <RemoteCursors presence={presence} />
            <ProseMirrorEditor
                ref={editorRef}
                onChange={onLocalChange}
                onSelectionChange={onSelectionChange}
            />
            <CommentsPanel documentId={documentId} />
            <PresenceBar users={Array.from(presence.values())} />
        </div>
    );
}
```

## Offline Support

Bei Verbindungsverlust:

1. Lokale Operationen werden gepuffert
2. Bei Reconnect: PULL aktuellen State
3. Gepufferte Operationen gegen Server-State transformieren
4. Transformierte Operationen senden

```typescript
class OfflineQueue {
    private pending: Operation[] = [];

    add(op: Operation): void {
        this.pending.push(op);
        this.persistToLocalStorage();
    }

    async flush(vfp: VfpClient, serverVersion: number): Promise<void> {
        for (const op of this.pending) {
            const transformed = transform(op, serverVersion);
            await vfp.push(transformed);
            serverVersion++;
        }
        this.pending = [];
    }
}
```