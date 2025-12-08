-- =============================================================================
-- SYNTH PROTOCOL - Views
-- Convenience views for common queries
-- =============================================================================

-- =============================================================================
-- PROJECT OVERVIEW
-- =============================================================================

CREATE VIEW IF NOT EXISTS v_project_overview AS
SELECT
    p.id AS project_id,
    p.version AS project_version,
    p.schema_version,
    pm.name,
    pm.description,
    pm.version AS metadata_version,
    pm.author,
    r.mode AS runtime_mode,
    l.level AS log_level,
    (SELECT COUNT(*) FROM plugins WHERE project_id = p.id) AS plugin_count,
    (SELECT COUNT(*) FROM pipelines WHERE project_id = p.id) AS pipeline_count,
    (SELECT COUNT(*) FROM mcp_servers WHERE project_id = p.id) AS mcp_server_count,
    (SELECT COUNT(*) FROM resources WHERE project_id = p.id) AS resource_count,
    p.created_at,
    p.updated_at
FROM project p
LEFT JOIN project_metadata pm ON p.id = pm.project_id
LEFT JOIN runtime r ON p.id = r.project_id
LEFT JOIN logging l ON p.id = l.project_id;

-- =============================================================================
-- MCP SERVER DETAILS
-- =============================================================================

CREATE VIEW IF NOT EXISTS v_mcp_servers_full AS
SELECT
    s.id AS server_id,
    s.project_id,
    s.name AS server_name,
    s.version AS server_version,
    s.description,
    s.enabled,
    CASE
        WHEN ts.server_id IS NOT NULL THEN 'stdio'
        WHEN th.server_id IS NOT NULL THEN 'http'
        WHEN te.server_id IS NOT NULL THEN 'sse'
    END AS transport_type,
    ts.command AS stdio_command,
    th.base_url AS http_base_url,
    te.url AS sse_url,
    (SELECT COUNT(*) FROM mcp_tools WHERE server_id = s.id) AS tool_count,
    (SELECT COUNT(*) FROM mcp_resources WHERE server_id = s.id) AS resource_count,
    (SELECT COUNT(*) FROM mcp_prompts WHERE server_id = s.id) AS prompt_count
FROM mcp_servers s
LEFT JOIN mcp_transport_stdio ts ON s.id = ts.server_id
LEFT JOIN mcp_transport_http th ON s.id = th.server_id
LEFT JOIN mcp_transport_sse te ON s.id = te.server_id;

-- =============================================================================
-- PIPELINE STRUCTURE
-- =============================================================================

CREATE VIEW IF NOT EXISTS v_pipeline_structure AS
SELECT
    pl.id AS pipeline_id,
    pl.project_id,
    pl.name AS pipeline_name,
    pl.description AS pipeline_description,
    ps.id AS step_id,
    ps.tool,
    ps.depends_on,
    ps.step_order,
    (SELECT GROUP_CONCAT(name || '=' || COALESCE(value, ref), '; ')
     FROM step_input_params WHERE step_id = ps.id) AS inputs,
    (SELECT GROUP_CONCAT(name || '=' || COALESCE(value, ref), '; ')
     FROM step_output_params WHERE step_id = ps.id) AS outputs
FROM pipelines pl
LEFT JOIN pipeline_steps ps ON pl.id = ps.pipeline_id
ORDER BY pl.pipeline_order, ps.step_order;

-- =============================================================================
-- SECURITY OVERVIEW
-- =============================================================================

CREATE VIEW IF NOT EXISTS v_security_overview AS
SELECT
    s.project_id,
    s.enabled AS security_enabled,
    auth.required AS auth_required,
    authz.model AS auth_model,
    (SELECT COUNT(*) FROM auth_providers WHERE project_id = s.project_id) AS provider_count,
    (SELECT COUNT(*) FROM policies WHERE project_id = s.project_id) AS policy_count,
    (SELECT COUNT(*) FROM roles WHERE project_id = s.project_id) AS role_count,
    ear.enabled AS encryption_at_rest,
    eit.enabled AS encryption_in_transit,
    aud.enabled AS audit_enabled
FROM security s
LEFT JOIN authentication auth ON s.project_id = auth.project_id
LEFT JOIN authorization authz ON s.project_id = authz.project_id
LEFT JOIN encryption_at_rest ear ON s.project_id = ear.project_id
LEFT JOIN encryption_in_transit eit ON s.project_id = eit.project_id
LEFT JOIN audit aud ON s.project_id = aud.project_id;

-- =============================================================================
-- RESOURCES BY TYPE
-- =============================================================================

CREATE VIEW IF NOT EXISTS v_resources_by_type AS
SELECT
    r.id AS resource_id,
    r.project_id,
    r.resource_type,
    r.uri,
    (SELECT GROUP_CONCAT(key || '=' || value, '; ')
     FROM resource_metadata WHERE resource_id = r.id) AS metadata
FROM resources r
ORDER BY r.resource_type, r.resource_order;

-- =============================================================================
-- MCP TOOLS WITH SCHEMA
-- =============================================================================

CREATE VIEW IF NOT EXISTS v_mcp_tools_full AS
SELECT
    t.id AS tool_id,
    t.server_id,
    s.name AS server_name,
    t.name AS tool_name,
    t.description,
    (SELECT GROUP_CONCAT(name || ':' || prop_type, ', ')
     FROM mcp_tool_properties WHERE tool_id = t.id
     ORDER BY prop_order) AS properties,
    (SELECT GROUP_CONCAT(field_name, ', ')
     FROM mcp_tool_required WHERE tool_id = t.id) AS required_fields
FROM mcp_tools t
JOIN mcp_servers s ON t.server_id = s.id
ORDER BY s.server_order, t.tool_order;