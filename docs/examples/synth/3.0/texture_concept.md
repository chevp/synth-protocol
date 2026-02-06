Asset- und Szenen-Workflow (Dev-Mode → Production)

Alle Game-Assets (Modelle, Texturen, Materialien, Szenenreferenzen) werden im Entwicklungsmodus zentral in SQLite-Libraries verwaltet. Jede Library repräsentiert eine in sich geschlossene Collection (z. B. pro Anbieter oder Themenpaket) und enthält die eigentlichen Asset-Daten als BLOBs inklusive Metadaten, Abhängigkeiten und Hashes. SQLite fungiert dabei als Single Source of Truth und vermeidet jegliche Duplikation großer Quelldaten (z. B. mehrere hundert Gigabyte an Material-Texturen).

Beim Erststart des C++/Vulkan-Clients im Dev-Mode erfolgt ein kontrollierter Preload-Schritt:
Der Client liest die benötigten Assets aus der SQLite-Library, decodiert sie (z. B. PNG/EXR/GLB), optional verschlüsselt sie und erzeugt daraus einen lokalen, GPU-nahen Cache (z. B. KTX2 für Texturen, binäre Mesh-Formate). Nach diesem Initialisierungsschritt greift das Rendering ausschließlich auf den Cache zu; direkte SQLite-Zugriffe während des Renderings finden nicht mehr statt. Dadurch bleiben auch Szenen mit vielen Assets performant und frei von Frame-Drops.

Änderungen an Assets (z. B. durch Blender-Exports oder Editor-Aktionen) werden über Hash-Vergleiche erkannt. Betroffene Cache-Einträge werden invalidiert und gezielt neu erzeugt, wodurch Hot-Reloading im Dev-Mode möglich ist, ohne das gesamte Asset-Set neu aufzubauen.

Für den Production-Build werden die SQLite-Libraries nicht ausgeliefert. Stattdessen extrahiert ein Build-Tool nur die tatsächlich benötigten Assets aus der Library und erzeugt eine stark optimierte Runtime-Struktur (typischerweise wenige Gigabyte), angepasst an Zielplattform und GPU-Format. Die Runtime kennt weder SQLite noch Dev-Metadaten und lädt ausschließlich voroptimierte Assets.

Dieses Vorgehen trennt klar zwischen Entwicklung, Asset-Autorenschaft und Runtime, reduziert Datenchaos, verhindert Duplikation, erlaubt zentrale Verwaltung großer Asset-Mengen und bietet gleichzeitig hohe Performance sowie Erweiterbarkeit für Verschlüsselung, Multi-User-Setups und automatisierte Build-Pipelines.