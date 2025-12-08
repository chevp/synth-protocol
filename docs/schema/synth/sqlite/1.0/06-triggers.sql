-- =============================================================================
-- SYNTH PROTOCOL - Triggers
-- Auto-update timestamps and data integrity
-- =============================================================================

-- =============================================================================
-- AUTO-UPDATE TIMESTAMPS
-- =============================================================================

CREATE TRIGGER IF NOT EXISTS tr_project_updated_at
AFTER UPDATE ON project
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.id;
END;

-- =============================================================================
-- CASCADE METADATA UPDATES
-- =============================================================================

-- Update project timestamp when metadata changes
CREATE TRIGGER IF NOT EXISTS tr_project_metadata_updated
AFTER UPDATE ON project_metadata
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.project_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_project_metadata_inserted
AFTER INSERT ON project_metadata
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.project_id;
END;

-- Update project timestamp when plugins change
CREATE TRIGGER IF NOT EXISTS tr_plugins_updated
AFTER UPDATE ON plugins
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.project_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_plugins_inserted
AFTER INSERT ON plugins
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.project_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_plugins_deleted
AFTER DELETE ON plugins
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = OLD.project_id;
END;

-- Update project timestamp when MCP servers change
CREATE TRIGGER IF NOT EXISTS tr_mcp_servers_updated
AFTER UPDATE ON mcp_servers
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.project_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_mcp_servers_inserted
AFTER INSERT ON mcp_servers
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.project_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_mcp_servers_deleted
AFTER DELETE ON mcp_servers
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = OLD.project_id;
END;

-- Update project timestamp when pipelines change
CREATE TRIGGER IF NOT EXISTS tr_pipelines_updated
AFTER UPDATE ON pipelines
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.project_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_pipelines_inserted
AFTER INSERT ON pipelines
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.project_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_pipelines_deleted
AFTER DELETE ON pipelines
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = OLD.project_id;
END;

-- Update project timestamp when resources change
CREATE TRIGGER IF NOT EXISTS tr_resources_updated
AFTER UPDATE ON resources
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.project_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_resources_inserted
AFTER INSERT ON resources
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = NEW.project_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_resources_deleted
AFTER DELETE ON resources
BEGIN
    UPDATE project SET updated_at = strftime('%s', 'now') * 1000
    WHERE id = OLD.project_id;
END;

-- =============================================================================
-- UPDATE SYNTH METADATA ON SCHEMA CHANGES
-- =============================================================================

CREATE TRIGGER IF NOT EXISTS tr_update_synth_metadata
AFTER UPDATE ON project
BEGIN
    UPDATE synth_metadata SET value = strftime('%s', 'now') * 1000
    WHERE key = 'updated_at';
END;