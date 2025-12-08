-- =============================================================================
-- SYNTH PROTOCOL - SQLite Schema Initialization
-- Version: 1.0
-- =============================================================================

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Performance settings for build output
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

-- =============================================================================
-- FILE METADATA
-- Identifies the file format and version
-- =============================================================================

CREATE TABLE IF NOT EXISTS synth_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

INSERT OR REPLACE INTO synth_metadata (key, value) VALUES
    ('magic', 'SYNTH'),
    ('format_version', '1'),
    ('schema_version', '1.0'),
    ('created_at', strftime('%s', 'now') * 1000);