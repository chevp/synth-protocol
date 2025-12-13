# REST + Protobuf Hybrid

**Standard REST API mit kompakten Protobuf-Payloads** - kein gRPC, kein Proxy!

## Konzept

```
┌──────────────┐     HTTP/1.1     ┌──────────────┐
│   Browser    │ ◄──────────────► │ REST Server  │
│              │   Protobuf Body  │   (Java)     │
└──────────────┘                  └──────────────┘

Content-Type: application/x-protobuf
```

## Warum dieser Ansatz?

| Aspekt | gRPC-Web | REST + Protobuf |
|--------|----------|-----------------|
| Proxy erforderlich | Ja (Envoy) | **Nein** |
| HTTP Version | HTTP/2 (Proxy) | HTTP/1.1 |
| Streaming | Server Streaming | SSE/WebSocket |
| Komplexität | Hoch | **Niedrig** |
| Migration | Komplett | **Schrittweise** |
| Debugging | Schwierig | Einfach (JSON-Fallback) |

## Größenvergleich

Typische Ersparnis gegenüber JSON: **30-50%**

```
Beispiel: Project-Liste (3 Projekte)
├── JSON:     312 bytes
├── Protobuf: 187 bytes
└── Ersparnis: 40%
```

## Implementierung

### Java Server (Spring Boot)

```java
// 1. Dependency hinzufügen (pom.xml)
<dependency>
    <groupId>com.google.protobuf</groupId>
    <artifactId>protobuf-java</artifactId>
    <version>3.25.1</version>
</dependency>

// 2. Message Converter registrieren
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
        converters.add(new ProtobufHttpMessageConverter());
    }
}

// 3. Controller mit Content Negotiation
@RestController
@RequestMapping("/api")
public class ProjectController {

    @GetMapping(value = "/projects/{id}",
                produces = {"application/x-protobuf", "application/json"})
    public Project getProject(@PathVariable String id) {
        return projectService.findById(id);
    }

    @PostMapping(value = "/projects",
                 consumes = {"application/x-protobuf", "application/json"},
                 produces = {"application/x-protobuf", "application/json"})
    public CreateProjectResponse createProject(@RequestBody CreateProjectRequest req) {
        // Spring handelt Serialisierung automatisch basierend auf Headers
        Project project = projectService.create(req);
        return CreateProjectResponse.newBuilder()
            .setProject(project)
            .build();
    }
}
```

### Browser Client (JavaScript)

```javascript
// Mit protobuf.js (CDN oder npm)
import protobuf from 'protobufjs';

// Proto laden
const root = await protobuf.load('rest-protobuf-example.proto');
const Project = root.lookupType('synth.example.Project');
const CreateProjectRequest = root.lookupType('synth.example.CreateProjectRequest');

// POST mit Protobuf Body
async function createProject(data) {
    const message = CreateProjectRequest.create(data);
    const buffer = CreateProjectRequest.encode(message).finish();

    const response = await fetch('/api/projects', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-protobuf',
            'Accept': 'application/x-protobuf'
        },
        body: buffer
    });

    const responseBuffer = await response.arrayBuffer();
    return CreateProjectResponse.decode(new Uint8Array(responseBuffer));
}

// Oder JSON anfordern für Debugging
async function createProjectJson(data) {
    const response = await fetch('/api/projects', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        },
        body: JSON.stringify(data)
    });
    return response.json();
}
```

## HTTP Headers

```http
# Request mit Protobuf
POST /api/projects HTTP/1.1
Content-Type: application/x-protobuf
Accept: application/x-protobuf

[Binary Protobuf Data]

# Content Negotiation
Accept: application/x-protobuf          # Nur Protobuf
Accept: application/json                 # Nur JSON
Accept: application/x-protobuf, application/json;q=0.9  # Protobuf bevorzugt
```

## Dateien

| Datei | Beschreibung |
|-------|--------------|
| `rest-protobuf-example.proto` | Protobuf Schema für Payloads |
| `index.html` | Interaktive Demo mit Größenvergleich |

## Vorteile

1. **Keine zusätzliche Infrastruktur** - Standard HTTP-Server reicht
2. **Content Negotiation** - Client wählt Format (Proto oder JSON)
3. **Schrittweise Migration** - Einzelne Endpoints umstellen
4. **Bekannte Tools** - curl, Postman, Browser DevTools funktionieren
5. **Standard Caching** - HTTP-Caching unverändert nutzbar