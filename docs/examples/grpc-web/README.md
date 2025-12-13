# gRPC-Web Example

Dieses Beispiel zeigt, wie man gRPC-Endpunkte direkt aus dem Browser aufruft und die Datenobjekte anhand von Protobuf-Definitionen extrahiert.

## Architektur

```
┌──────────────┐     HTTP/1.1      ┌──────────────┐     HTTP/2      ┌──────────────┐
│   Browser    │ ◄──────────────► │  Envoy Proxy │ ◄──────────────► │ gRPC Server  │
│  (gRPC-Web)  │   gRPC-Web        │  (Port 8080) │   gRPC native    │ (Port 9090)  │
└──────────────┘                   └──────────────┘                  └──────────────┘
```

## Dateien

| Datei | Beschreibung |
|-------|--------------|
| `grpc-web-example.proto` | Protobuf Service-Definition |
| `index.html` | Interaktive Demo-Oberfläche |
| `envoy.yaml` | Envoy Proxy Konfiguration |

## Unterschied zu REST

| Aspekt | REST | gRPC-Web |
|--------|------|----------|
| Format | JSON (Text) | Protobuf (Binary) |
| Schema | OpenAPI (optional) | Protobuf (pflicht) |
| Typsicherheit | Manuell | Automatisch generiert |
| Streaming | WebSocket/SSE | Native Server Streaming |
| Größe | Größer | ~30% kleiner |
| Geschwindigkeit | Langsamer | Schneller |

## Setup

### 1. Proto kompilieren

```bash
# Tools installieren
npm install -g grpc-tools grpc_tools_node_protoc_ts

# JavaScript + TypeScript Bindings generieren
protoc -I=. \
  --js_out=import_style=commonjs:./generated \
  --grpc-web_out=import_style=typescript,mode=grpcwebtext:./generated \
  grpc-web-example.proto
```

### 2. Envoy Proxy starten

```bash
# Mit Docker
docker run -d -v $(pwd)/envoy.yaml:/etc/envoy/envoy.yaml:ro \
  -p 8080:8080 -p 9901:9901 envoyproxy/envoy:v1.28-latest

# Oder native Installation
envoy -c envoy.yaml
```

### 3. gRPC Server implementieren (Node.js Beispiel)

```javascript
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');

const packageDefinition = protoLoader.loadSync('grpc-web-example.proto');
const proto = grpc.loadPackageDefinition(packageDefinition).synth.example;

const server = new grpc.Server();

server.addService(proto.ExampleService.service, {
    getUser: (call, callback) => {
        callback(null, {
            user: {
                id: call.request.userId,
                name: 'Demo User',
                email: 'demo@example.com',
                createdAt: Date.now()
            }
        });
    },

    listProjects: (call, callback) => {
        callback(null, {
            projects: [
                { id: 'proj_1', name: 'Project 1', status: 1 }
            ],
            totalCount: 1
        });
    },

    createProject: (call, callback) => {
        callback(null, {
            project: {
                id: 'proj_new',
                name: call.request.name,
                description: call.request.description,
                status: 1
            }
        });
    },

    watchProjects: (call) => {
        // Server Streaming
        const interval = setInterval(() => {
            call.write({
                projectId: 'proj_1',
                updateType: 2, // UPDATED
                timestamp: Date.now()
            });
        }, 1000);

        call.on('cancelled', () => clearInterval(interval));
    }
});

server.bindAsync('0.0.0.0:9090', grpc.ServerCredentials.createInsecure(), () => {
    console.log('gRPC Server running on port 9090');
});
```

## Client-Nutzung im Browser

```typescript
import { ExampleServiceClient } from './generated/ExampleServiceClientPb';
import { GetUserRequest } from './generated/grpc-web-example_pb';

// Client erstellen
const client = new ExampleServiceClient('http://localhost:8080');

// Request erstellen (typsicher!)
const request = new GetUserRequest();
request.setUserId('user_123');

// Aufruf mit Callback
client.getUser(request, {}, (err, response) => {
    if (err) {
        console.error('gRPC Error:', err.code, err.message);
        return;
    }

    // Typsichere Datenextraktion
    const user = response.getUser();
    console.log('User ID:', user.getId());
    console.log('Name:', user.getName());
    console.log('Email:', user.getEmail());

    // Oder als Plain Object
    console.log('Raw:', response.toObject());
});
```

## Einschränkungen von gRPC-Web

1. **Kein bidirektionales Streaming** - Nur Unary und Server Streaming
2. **Proxy erforderlich** - Browser kann kein natives HTTP/2 mit Trailers
3. **CORS** - Proxy muss CORS-Header setzen

## Vorteile gegenüber REST

1. **Typsicherheit** - Compile-time Checks durch generierte Klassen
2. **Effizienz** - Binary Format, kleinere Payloads
3. **Schema-First** - API-Vertrag durch .proto Dateien
4. **Code-Generierung** - Client-Stubs automatisch erstellt
5. **Streaming** - Native Unterstützung für Server-Streaming