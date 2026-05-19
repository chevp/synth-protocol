# Synth-Protocol Schema Roadmap

Plan zur Vervollständigung von `docs/schema/synth/` für Kosmos/Iris-Games.

**Leitprinzip:** Mechanik zuerst. Ein Game *ist* seine Mechanik —
Audio/Lighting/VFX sind Polish und können bis zum Schluss flach bleiben.

**Angular-Analogie:** synth-protocol erfüllt für 3D-Games dieselbe Rolle, die
Angular für Web-Apps spielt — Routes, Services, Components, Assets, Build-Pipeline,
DI — nur eben für 3D-Renderer + Game-Logic statt DOM + HTTP.

---

## Status quo

Vorhanden in `docs/schema/synth/`:

| Schema | Angular-Pendant | Status |
|---|---|---|
| `routes/1.0/routes.xsd` | Router | basic (path, scene, spawnPoint, params) |
| `scene/1.0/scene.xsd` | Page-Tree | Entities, Hierarchie, Camera, PointLight |
| `component/1.0/component.xsd` | Component | + UI-Layout + StateMachine |
| `asset-registry/1.0/asset-registry.xsd` | Asset-Repo (npm-style) | ✓ |
| `pipeline/1.0/asset-pipeline.xsd` | Build-Pipeline | ✓ |
| `runtime/1.0/runtime.xsd` | Bootstrap (Renderer) | Vulkan/OpenGL/Metal/DX12/WebGPU |
| `runtime/1.0/runtime-logic.xsd` | Bootstrap (Backend) | Hub, DB, Server, Plugins |
| `runtime/1.0/runtime-renderer.xsd` | — | (siehe Datei) |
| `events/1.0/events.xsd` | EventEmitter / RxJS | URI-Routing, Subscriptions, Batching |
| `project/1.0/project.xsd` + `game-project.xsd` | Workspace / angular.json | .cryo orchestriert Backend+Renderer |
| `extension/1.0/extension.xsd` | NgModule / Library | ✓ |
| `mcp/1.0/mcp.xsd` | HttpClient (AI-Tools) | ✓ |
| `security/1.0/security.xsd` | Guards (global) | ✓ aber nicht route-gebunden |
| `core/1.0/core.xsd` + `common-types.xsd` | Core-Types | Transform, Vec, Mesh, Properties |
| `sqlite/1.0/*` | DB-Migrations | ✓ |

---

## Priorisierung

### Stufe 1 — Kritisch (ohne diese kein Game)

| # | Schema | Zweck | Abhängigkeiten |
|---|---|---|---|
| 1 | `input/1.0/input.xsd` | Action-Maps (Keyboard/Mouse/Gamepad/Touch), Binding-Contexts | — |
| 2 | `physics/1.0/physics.xsd` | Rigidbody, Collider, Joint, Trigger, Layer-Matrix | `scene` (Entity-Components) |
| 3 | `save/1.0/save.xsd` | Save-Slots, Snapshots, Versioning, Serialization | `core`, `sqlite` |
| 4 | `service/1.0/service.xsd` | In-Process DI für Game-Logic-Singletons | — |
| 5 | `routes/1.0/routes.xsd` **v1.1** | Guards (`canActivate`, `canDeactivate`), Resolvers (`resolve`) | `service`, `save` |
| 6 | `ai/1.0/behavior-tree.xsd` | BTs für NPCs/Enemies; mehr als die generische `StateMachineType` | `service` |
| 7 | `navigation/1.0/navmesh.xsd` | NavMesh, Pathfinding-Queries, Areas, Off-Mesh-Links | `scene` |

### Stufe 2 — Wichtig (Engine-Infrastruktur)

| # | Schema | Zweck | Abhängigkeiten |
|---|---|---|---|
| 8 | `animation/1.0/animation.xsd` | Skeletal, Blend-Trees, Anim-State-Machines, IK | `core` |
| 9 | `camera/1.0/camera.xsd` | Cuts, Splines, Cinematic, Multi-Viewport, Triggered-Changes | `scene`, `events` |
| 10 | `net/1.0/replication.xsd` | Authority, Prediction, Rollback (Multiplayer; separat von `state-sync`) | `events` |
| 11 | `routes/1.0/routes.xsd` **v1.2** | Lazy-Loading-Marker pro Route (eager/lazy/streamed) | `asset-registry` |

**Bewusst ausgeschlossen:** Inventory, Quests, Dialog, Items, Loot-Tables — das
sind *Spielmechaniken*, kein Engine-/Framework-Pendant. Synth-protocol bleibt
auf Infrastruktur-Ebene (wie Angular Router/Forms/HttpClient, nicht ShoppingCart).

### Stufe 3 — Polish (kann flach bleiben, bis das Game läuft)

| # | Schema | Zweck |
|---|---|---|
| 12 | `lighting/1.0/lighting.xsd` | Directional/Spot/Area/IBL/Probes/Shadows (Scene hat nur PointLight) |
| 13 | `material/1.0/material.xsd` | PBR-Maps, Render-Queue, Variants (über `DefaultMaterialType` hinaus) |
| 14 | `audio/1.0/audio.xsd` | Mixer, Buses, 3D-Spatial, Music-Layer (`audio` ist bisher nur AssetType-Enum) |
| 15 | `vfx/1.0/particles.xsd` | Particle-Systems, Emitter, Forces |
| 16 | `postfx/1.0/post-processing.xsd` | Bloom, SSAO, Tonemapping, Color-Grading |
| 17 | `settings/1.0/user-settings.xsd` | Graphics/Audio/Controls/Accessibility-Prefs (User, nicht Engine) |

### Stufe 4 — Größere Brocken (nur wenn Anwendung es fordert)

| # | Schema | Zweck |
|---|---|---|
| 18 | `world/1.0/streaming.xsd` | Terrain, Chunk/Tile-Streaming für große Welten |
| 19 | `build/1.0/platform-targets.xsd` | Build-Configs pro PC/Console/Mobile/VR/Web |
| 20 | `mods/1.0/mods.xsd` | User-Mods/UGC (anders als `extension.xsd` für Engine-Extensions) |

---

## Iris-MVP-Pfad

Reihenfolge für ein erstes spielbares Iris-Game:

```
1. input.xsd          → Spieler kann handeln
2. physics.xsd        → Welt reagiert
3. save.xsd           → Fortschritt bleibt
4. service.xsd        → Game-Logic-DI sauber strukturiert
5. routes v1.1        → Guards/Resolvers für Scene-Übergänge
```

Mit diesen fünf ist **mechanische Vollständigkeit** erreicht.

Danach **Animation + Camera-System** für spürbare Game-Qualität.

Lighting/Audio/VFX kann am Schluss.

---

## Konventionen für neue Schemas

Pro neues Schema:

- Pfad: `docs/schema/synth/<domain>/1.0/<domain>.xsd`
- Target-Namespace: `https://chevp.github.io/synth-protocol/schema/synth/<domain>/1.0`
- Root-Element: `synth<Domain>` (z. B. `synthInput`, `synthPhysics`)
- Import `common-types.xsd` für Vec3/Transform/Properties
- Mindestens ein Beispiel in `docs/schema/examples/`
- Eintrag in `catalog.xml` und `synth-all.xsd`
- README in `<domain>/1.0/` ist optional, bei nicht-trivialer Semantik empfohlen

---

## Offene Design-Fragen

- **Service-Lifecycle:** Singleton vs. Scoped (per Scene/Route)? Wann instanziiert?
- **Save-Versioning:** Migration-Hooks im Schema oder im Loader?
- **Physics-Engine-Agnostik:** Bullet/PhysX/Jolt — Schema beschreibt Daten, nicht Engine?
- **BT vs. StateMachine:** BTs ersetzen oder ergänzen die `StateMachineType` aus `component`?
- **Replication vs. State-Sync:** Wie weit darf sich `net/replication` von `state-sync` unterscheiden, bevor sie zusammengelegt werden?
