# Client Integration Guide

Dieses Dokument beschreibt die Integration des Synth Endpoint Protocol in verschiedene Client-Typen.

---

## Übersicht: Client-Typen

```
┌─────────────────────────────────────────────────────────────────┐
│                    Synth Endpoint Gateway                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│   │ C++ Vulkan  │  │ Electron    │  │ AI Agents   │            │
│   │ Renderer    │  │ Scene-Dev   │  │ (MCP)       │            │
│   │ (Prod)      │  │ (Dev/Admin) │  │             │            │
│   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘            │
│          │                │                │                    │
│     HTTPS REST       HTTPS REST        MCP/gRPC                 │
│     libcurl          fetch/axios       SDK                      │
│          │                │                │                    │
│          └────────────────┼────────────────┘                    │
│                           │                                     │
│                    /api/v1/*                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

| Client | Umgebung | Protokoll | Library |
|--------|----------|-----------|---------|
| **C++ Vulkan Renderer** | Produktion | HTTPS REST | libcurl |
| **Electron Scene-Dev** | Development | HTTPS REST | fetch/axios |
| **AI Agents** | Claude/GPT | MCP Tools | SDK |
| **Web Apps** | Browser | HTTPS REST | fetch |
| **Mobile Apps** | iOS/Android | HTTPS REST | Native HTTP |

---

## C++ Vulkan Renderer Integration

### Minimale Dependencies

```cmake
# CMakeLists.txt
find_package(CURL REQUIRED)
find_package(nlohmann_json REQUIRED)  # Optional: für JSON

target_link_libraries(renderer
    CURL::libcurl
    nlohmann_json::nlohmann_json
)
```

### Basis-Client Implementierung

```cpp
// synth_client.hpp
#pragma once

#include <string>
#include <vector>
#include <functional>
#include <optional>
#include <curl/curl.h>

namespace synth {

struct ResourceResponse {
    bool success;
    std::string content_type;
    std::vector<uint8_t> data;
    std::string etag;
    std::string error;
};

struct Message {
    std::string message_id;
    std::string topic;
    std::string payload;  // JSON string
    std::string ack_id;
};

class SynthClient {
public:
    SynthClient(const std::string& base_url, const std::string& auth_token)
        : base_url_(base_url), auth_token_(auth_token) {
        curl_global_init(CURL_GLOBAL_DEFAULT);
    }

    ~SynthClient() {
        curl_global_cleanup();
    }

    // =========================================================================
    // Resource Access
    // =========================================================================

    // GET /api/v1/resources/{path}
    ResourceResponse getResource(const std::string& path) {
        return httpGet("/api/v1/resources/" + path);
    }

    // GET mit ETag (Conditional Request)
    ResourceResponse getResourceIfModified(const std::string& path,
                                           const std::string& etag) {
        return httpGet("/api/v1/resources/" + path, {
            {"If-None-Match", etag}
        });
    }

    // HEAD /api/v1/resources/{path}
    ResourceResponse checkResource(const std::string& path) {
        return httpHead("/api/v1/resources/" + path);
    }

    // =========================================================================
    // Messaging
    // =========================================================================

    // POST /api/v1/messages/publish
    bool publish(const std::string& topic, const std::string& payload) {
        std::string body = R"({"topic":")" + topic + R"(","payload":)" + payload + "}";
        auto resp = httpPost("/api/v1/messages/publish", body);
        return resp.success;
    }

    // GET /api/v1/messages/poll (Long-Polling)
    std::vector<Message> poll(const std::string& topic, int timeout_seconds = 30) {
        std::string url = "/api/v1/messages/poll?topic=" + urlEncode(topic)
                        + "&timeout=" + std::to_string(timeout_seconds);
        auto resp = httpGet(url);
        return parseMessages(resp.data);
    }

    // POST /api/v1/messages/ack
    bool acknowledge(const std::vector<std::string>& ack_ids) {
        std::string body = R"({"ack_ids":[)";
        for (size_t i = 0; i < ack_ids.size(); ++i) {
            if (i > 0) body += ",";
            body += "\"" + ack_ids[i] + "\"";
        }
        body += "]}";
        auto resp = httpPost("/api/v1/messages/ack", body);
        return resp.success;
    }

    // =========================================================================
    // Scene Composition
    // =========================================================================

    // POST /api/v1/scenes/compose
    ResourceResponse composeScene(const std::string& scene_uri) {
        std::string body = R"({"scene_uri":")" + scene_uri + R"("})";
        return httpPost("/api/v1/scenes/compose", body);
    }

private:
    std::string base_url_;
    std::string auth_token_;

    ResourceResponse httpGet(const std::string& path,
                            const std::map<std::string, std::string>& headers = {});
    ResourceResponse httpPost(const std::string& path, const std::string& body);
    ResourceResponse httpHead(const std::string& path);
    std::string urlEncode(const std::string& str);
    std::vector<Message> parseMessages(const std::vector<uint8_t>& data);
};

} // namespace synth
```

### Verwendung im Renderer

```cpp
// main.cpp
#include "synth_client.hpp"

int main() {
    synth::SynthClient client(
        "https://de.synth.network/api/v1",
        "Bearer eyJ..."
    );

    // Scene laden
    auto scene = client.getResource("scenes/forest.glb");
    if (scene.success) {
        loadScene(scene.data);
    }

    // Event-Loop für Updates
    while (running) {
        // Long-Poll für Scene-Updates (blockiert bis Event oder Timeout)
        auto messages = client.poll("scenes/forest/*", 30);

        for (const auto& msg : messages) {
            if (msg.topic == "scenes/forest/updated") {
                // Scene neu laden
                auto updated = client.getResource("scenes/forest.glb");
                reloadScene(updated.data);
            }

            // Message bestätigen
            client.acknowledge({msg.ack_id});
        }

        // Frame rendern
        renderFrame();
    }

    return 0;
}
```

### Caching mit ETags

```cpp
class CachedSynthClient {
    SynthClient& client_;
    std::unordered_map<std::string, CacheEntry> cache_;

    struct CacheEntry {
        std::vector<uint8_t> data;
        std::string etag;
    };

public:
    std::vector<uint8_t> getWithCache(const std::string& path) {
        auto it = cache_.find(path);

        if (it != cache_.end()) {
            // Conditional GET
            auto resp = client_.getResourceIfModified(path, it->second.etag);

            if (resp.status == 304) {
                // Nicht geändert, Cache verwenden
                return it->second.data;
            }

            // Aktualisieren
            it->second.data = resp.data;
            it->second.etag = resp.etag;
            return resp.data;
        }

        // Nicht im Cache
        auto resp = client_.getResource(path);
        cache_[path] = {resp.data, resp.etag};
        return resp.data;
    }
};
```

---

## Electron Scene-Dev Integration

### TypeScript Client

```typescript
// synth-client.ts

interface ResourceResponse {
  success: boolean;
  contentType: string;
  data: ArrayBuffer | string;
  etag?: string;
  error?: string;
}

interface Message {
  messageId: string;
  topic: string;
  payload: unknown;
  ackId: string;
  timestamp: string;
}

export class SynthClient {
  constructor(
    private baseUrl: string,
    private authToken: string
  ) {}

  // =========================================================================
  // Resource Access
  // =========================================================================

  async getResource(path: string): Promise<ResourceResponse> {
    const response = await fetch(`${this.baseUrl}/api/v1/resources/${path}`, {
      headers: {
        'Authorization': `Bearer ${this.authToken}`
      }
    });

    return {
      success: response.ok,
      contentType: response.headers.get('content-type') || '',
      data: await response.arrayBuffer(),
      etag: response.headers.get('etag') || undefined,
      error: response.ok ? undefined : await response.text()
    };
  }

  async getJson<T>(path: string): Promise<T> {
    const response = await this.getResource(path);
    const text = new TextDecoder().decode(response.data as ArrayBuffer);
    return JSON.parse(text);
  }

  // =========================================================================
  // Messaging
  // =========================================================================

  async publish(topic: string, payload: unknown): Promise<boolean> {
    const response = await fetch(`${this.baseUrl}/api/v1/messages/publish`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ topic, payload })
    });

    return response.ok;
  }

  async poll(topic: string, timeoutSeconds = 30): Promise<Message[]> {
    const url = new URL(`${this.baseUrl}/api/v1/messages/poll`);
    url.searchParams.set('topic', topic);
    url.searchParams.set('timeout', timeoutSeconds.toString());

    const response = await fetch(url.toString(), {
      headers: {
        'Authorization': `Bearer ${this.authToken}`
      }
    });

    if (!response.ok) return [];

    const data = await response.json();
    return data.messages || [];
  }

  async acknowledge(ackIds: string[]): Promise<void> {
    await fetch(`${this.baseUrl}/api/v1/messages/ack`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ ack_ids: ackIds })
    });
  }

  // =========================================================================
  // Scene Composition
  // =========================================================================

  async composeScene(sceneUri: string, options?: ComposeOptions): Promise<ComposedScene> {
    const response = await fetch(`${this.baseUrl}/api/v1/scenes/compose`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.authToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        scene_uri: sceneUri,
        options
      })
    });

    return response.json();
  }

  // =========================================================================
  // Reactive Subscriptions
  // =========================================================================

  subscribe(topic: string, callback: (msg: Message) => void): () => void {
    let running = true;

    const poll = async () => {
      while (running) {
        try {
          const messages = await this.poll(topic, 30);

          for (const msg of messages) {
            callback(msg);
            await this.acknowledge([msg.ackId]);
          }
        } catch (error) {
          console.error('Poll error:', error);
          await new Promise(r => setTimeout(r, 1000)); // Retry delay
        }
      }
    };

    poll();

    // Return unsubscribe function
    return () => { running = false; };
  }
}

interface ComposeOptions {
  maxConcurrentFetches?: number;
  useCache?: boolean;
  maxLodLevel?: number;
  maxTextureResolution?: number;
}

interface ComposedScene {
  sceneId: string;
  status: 'success' | 'partial' | 'failed';
  resources: ResourceRef[];
  stats: {
    resourcesFetched: number;
    resourcesFromCache: number;
    totalBytes: number;
    durationMs: number;
  };
}

interface ResourceRef {
  uri: string;
  contentType: string;
  sizeBytes: number;
  localPath?: string;
}
```

### Verwendung in Electron

```typescript
// scene-editor.ts
import { SynthClient } from './synth-client';

const client = new SynthClient(
  'https://de.synth.network',
  localStorage.getItem('auth_token')!
);

// Scene laden und komponieren
async function loadScene(sceneUri: string) {
  const scene = await client.composeScene(sceneUri, {
    maxConcurrentFetches: 8,
    useCache: true,
    maxTextureResolution: 2048
  });

  console.log(`Loaded ${scene.stats.resourcesFetched} resources`);

  // Scene rendern
  renderScene(scene);
}

// Live-Updates abonnieren
const unsubscribe = client.subscribe('scenes/+/updated', async (msg) => {
  console.log('Scene updated:', msg.payload);

  // Betroffene Scene neu laden
  const sceneId = msg.topic.split('/')[1];
  await loadScene(`synth://hub/scenes/${sceneId}`);
});

// Cleanup bei Window-Close
window.addEventListener('beforeunload', () => {
  unsubscribe();
});
```

---

## AI Agent Integration (MCP)

### MCP Server Konfiguration

```json
{
  "mcpServers": {
    "synth-endpoint": {
      "command": "synth-mcp-server",
      "args": ["--endpoint", "https://de.synth.network"],
      "env": {
        "SYNTH_AUTH_TOKEN": "${SYNTH_AUTH_TOKEN}"
      }
    }
  }
}
```

### Verfügbare MCP Tools

| Tool | Beschreibung |
|------|--------------|
| `synth_fetch_resource` | Ressource von einem Node laden |
| `synth_list_nodes` | Verfügbare Nodes auflisten |
| `synth_compose_scene` | Scene zusammenstellen |
| `synth_publish_event` | Event publizieren |
| `synth_query_resources` | Ressourcen suchen |

### Beispiel: AI Agent lädt Scene

```
User: "Lade die Forest-Scene vom deutschen Node"

AI Agent:
1. Ruft synth_list_nodes auf um verfügbare Nodes zu sehen
2. Ruft synth_compose_scene auf:
   {
     "scene_uri": "synth://de-frankfurt/scenes/forest",
     "max_lod_level": 2
   }
3. Erhält Ergebnis mit allen geladenen Ressourcen
4. Berichtet dem User über den Erfolg
```

### Tool-Definitionen (siehe mcp-tools.proto)

```typescript
// Beispiel Tool-Aufruf
const result = await mcpClient.callTool('synth_fetch_resource', {
  uri: 'synth://de-frankfurt/scenes/forest.json',
  use_cache: true
});

// Ergebnis
{
  success: true,
  content_type: 'application/json',
  content: '{"name": "Forest Scene", ...}',
  source_node: 'de-frankfurt-1'
}
```

---

## Umgebungs-spezifische Konfiguration

### Entwicklung vs. Produktion

```typescript
// config.ts
const config = {
  development: {
    endpoint: 'http://localhost:8080',
    // FTP für direkten Dateizugriff (nur Dev!)
    ftpEnabled: true,
    ftpHost: 'localhost',
    ftpPort: 21
  },

  production: {
    endpoint: 'https://de.synth.network',
    // Kein FTP in Produktion - nur HTTPS
    ftpEnabled: false
  }
};

export const currentConfig = config[process.env.NODE_ENV || 'development'];
```

### C++ Präprozessor

```cpp
// config.hpp
#ifdef SYNTH_PRODUCTION
    constexpr const char* SYNTH_ENDPOINT = "https://de.synth.network";
    constexpr bool FTP_ENABLED = false;
#else
    constexpr const char* SYNTH_ENDPOINT = "http://localhost:8080";
    constexpr bool FTP_ENABLED = true;
#endif
```

---

## Error Handling

### Einheitliche Fehlerbehandlung

```typescript
// Alle Clients verwenden dieselben HTTP Status Codes

interface SynthError {
  status: number;      // HTTP Status
  code: string;        // Synth Error Code
  message: string;     // Menschenlesbar
  details?: unknown;   // Zusätzliche Infos
}

// Status Codes
// 200 - OK
// 304 - Not Modified (Cache hit)
// 400 - Bad Request
// 401 - Unauthorized
// 403 - Forbidden
// 404 - Not Found
// 429 - Rate Limited
// 500 - Server Error
// 503 - Service Unavailable

// Synth Error Codes
// RESOURCE_NOT_FOUND
// NODE_UNAVAILABLE
// COMPOSITION_FAILED
// MESSAGE_DELIVERY_FAILED
// AUTH_EXPIRED
```

### Retry-Strategie

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  backoffMs = 1000
): Promise<T> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;

      // Exponential backoff
      await new Promise(r => setTimeout(r, backoffMs * Math.pow(2, i)));
    }
  }
  throw new Error('Max retries exceeded');
}

// Verwendung
const scene = await withRetry(() =>
  client.composeScene('synth://de/scenes/forest')
);
```

---

## Zusammenfassung

| Client | Integration | Aufwand |
|--------|-------------|---------|
| **C++** | libcurl + JSON Parser | ~200 LOC |
| **TypeScript** | fetch API | ~100 LOC |
| **AI Agents** | MCP Tools | Config only |
| **Python** | requests | ~50 LOC |
| **Go** | net/http | ~100 LOC |

**Ein Protokoll. Ein Auth-Token. Überall dieselbe API.**
