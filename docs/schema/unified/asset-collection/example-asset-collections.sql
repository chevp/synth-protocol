-- ==================================================
-- SQLite Init Script für Asset-Library
-- ==================================================

-- Tabelle für Collections / Pakete (z.B. Vendor / Thema)
CREATE TABLE IF NOT EXISTS collections (
    id TEXT PRIMARY KEY,         -- z.B. "vendor_sci_fi"
    name TEXT NOT NULL,          -- Menschlicher Name, z.B. "Sci-Fi Assets"
    description TEXT,            -- optional
    version TEXT,                -- z.B. "1.0"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabelle für Assets (Modelle, Texturen, Materialien)
CREATE TABLE IF NOT EXISTS assets (
    id TEXT PRIMARY KEY,          -- eindeutige Asset-ID, z.B. "spaceship_01"
    collection_id TEXT NOT NULL,  -- FK auf collections.id
    type TEXT NOT NULL,           -- "model", "texture", "material"
    name TEXT NOT NULL,           -- Dateiname oder interner Name
    data BLOB NOT NULL,           -- Binärdaten (GLB, KTX2, PNG, EXR)
    meta JSON,                    -- JSON mit Auflösung, Format, LOD, etc.
    hash TEXT,                    -- SHA256 / MD5 für Cache/Integrity
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_id) REFERENCES collections(id)
);

-- Tabelle für Asset-Abhängigkeiten
CREATE TABLE IF NOT EXISTS dependencies (
    asset_id TEXT NOT NULL,       -- Asset, das die Abhängigkeit hat
    depends_on TEXT NOT NULL,     -- Referenziertes Asset
    PRIMARY KEY (asset_id, depends_on),
    FOREIGN KEY (asset_id) REFERENCES assets(id),
    FOREIGN KEY (depends_on) REFERENCES assets(id)
);

-- Optional: Table für schnelle Cache / Dev-Mode Infos
CREATE TABLE IF NOT EXISTS cache_info (
    asset_id TEXT PRIMARY KEY,
    cached BOOLEAN DEFAULT 0,      -- 0 = noch nicht im Cache, 1 = im Cache
    last_loaded TIMESTAMP,         -- wann zuletzt decodiert / GPU-ready
    FOREIGN KEY (asset_id) REFERENCES assets(id)
);

-- Indizes für schnellen Zugriff
CREATE INDEX IF NOT EXISTS idx_assets_collection ON assets(collection_id);
CREATE INDEX IF NOT EXISTS idx_dependencies_depends_on ON dependencies(depends_on);

-- ==================================================
-- Beispiel Inserts (optional)
-- ==================================================

-- Collection anlegen
INSERT INTO collections (id, name, description, version)
VALUES ('vendor_sci_fi', 'Sci-Fi Assets', 'Spaceships, Lasers, Sci-Fi Props', '1.0');

-- Beispiel Asset
INSERT INTO assets (id, collection_id, type, name, hash, meta)
VALUES (
    'spaceship_01',
    'vendor_sci_fi',
    'model',
    'spaceship_01.glb',
    'PLACEHOLDER_HASH',
    '{"lods": 3, "format": "glb", "dependencies":["spaceship_01_albedo","spaceship_01_normal"]}'
);

-- Beispiel Texturen
INSERT INTO assets (id, collection_id, type, name, hash, meta)
VALUES
('spaceship_01_albedo', 'vendor_sci_fi', 'texture', 'spaceship_01_albedo.ktx2', 'HASH_ALBEDO', '{"resolution":"2048x2048"}'),
('spaceship_01_normal', 'vendor_sci_fi', 'texture', 'spaceship_01_normal.ktx2', 'HASH_NORMAL', '{"resolution":"2048x2048"}');

-- Abhängigkeiten festlegen
INSERT INTO dependencies (asset_id, depends_on) VALUES
('spaceship_01', 'spaceship_01_albedo'),
('spaceship_01', 'spaceship_01_normal');
