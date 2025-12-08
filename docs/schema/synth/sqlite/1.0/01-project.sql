-- =============================================================================
-- SYNTH PROTOCOL - Project Schema
-- Maps to: project.xsd (SynthProjectType)
-- =============================================================================

-- =============================================================================
-- PROJECT
-- Root entity for a Synth project
-- =============================================================================

CREATE TABLE IF NOT EXISTS project (
    id TEXT PRIMARY KEY,
    version TEXT NOT NULL DEFAULT '1.0',
    schema_version TEXT NOT NULL DEFAULT '1.0',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- =============================================================================
-- PROJECT METADATA
-- Maps to: ProjectMetadataType
-- =============================================================================

CREATE TABLE IF NOT EXISTS project_metadata (
    project_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    version TEXT NOT NULL,
    author TEXT,
    created_at INTEGER,
    modified_at INTEGER,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS project_tags (
    project_id TEXT NOT NULL,
    tag TEXT NOT NULL,
    PRIMARY KEY (project_id, tag),
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE INDEX idx_project_tags_tag ON project_tags(tag);

-- =============================================================================
-- PLUGINS
-- Maps to: PluginsType, PluginRefType
-- =============================================================================

CREATE TABLE IF NOT EXISTS plugins (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    version TEXT,
    enabled INTEGER NOT NULL DEFAULT 1,
    plugin_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS plugin_config (
    plugin_id TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (plugin_id, key),
    FOREIGN KEY (plugin_id) REFERENCES plugins(id) ON DELETE CASCADE
);

CREATE INDEX idx_plugins_project ON plugins(project_id);

-- =============================================================================
-- PIPELINES
-- Maps to: PipelinesType, PipelineType
-- =============================================================================

CREATE TABLE IF NOT EXISTS pipelines (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    name TEXT,
    description TEXT,
    pipeline_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE INDEX idx_pipelines_project ON pipelines(project_id);

-- =============================================================================
-- PIPELINE STEPS
-- Maps to: StepsType, StepType
-- =============================================================================

CREATE TABLE IF NOT EXISTS pipeline_steps (
    id TEXT PRIMARY KEY,
    pipeline_id TEXT NOT NULL,
    tool TEXT NOT NULL,
    depends_on TEXT,
    step_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (pipeline_id) REFERENCES pipelines(id) ON DELETE CASCADE,
    FOREIGN KEY (depends_on) REFERENCES pipeline_steps(id)
);

CREATE TABLE IF NOT EXISTS step_input_params (
    step_id TEXT NOT NULL,
    name TEXT NOT NULL,
    value TEXT,
    type TEXT,
    ref TEXT,
    PRIMARY KEY (step_id, name),
    FOREIGN KEY (step_id) REFERENCES pipeline_steps(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS step_output_params (
    step_id TEXT NOT NULL,
    name TEXT NOT NULL,
    value TEXT,
    type TEXT,
    ref TEXT,
    PRIMARY KEY (step_id, name),
    FOREIGN KEY (step_id) REFERENCES pipeline_steps(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS step_config (
    step_id TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (step_id, key),
    FOREIGN KEY (step_id) REFERENCES pipeline_steps(id) ON DELETE CASCADE
);

CREATE INDEX idx_pipeline_steps_pipeline ON pipeline_steps(pipeline_id);

-- =============================================================================
-- PIPELINE TRIGGERS
-- Maps to: TriggersType, TriggerType
-- =============================================================================

CREATE TABLE IF NOT EXISTS pipeline_triggers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pipeline_id TEXT NOT NULL,
    trigger_type TEXT NOT NULL CHECK (trigger_type IN ('manual', 'schedule', 'file-watch', 'event')),
    value TEXT,
    FOREIGN KEY (pipeline_id) REFERENCES pipelines(id) ON DELETE CASCADE
);

CREATE INDEX idx_pipeline_triggers_pipeline ON pipeline_triggers(pipeline_id);

-- =============================================================================
-- RESOURCES
-- Maps to: ResourcesType, ResourceType
-- =============================================================================

CREATE TABLE IF NOT EXISTS resources (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    resource_type TEXT NOT NULL CHECK (resource_type IN ('model', 'dataset', 'config', 'asset', 'script')),
    uri TEXT NOT NULL,
    resource_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS resource_metadata (
    resource_id TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (resource_id, key),
    FOREIGN KEY (resource_id) REFERENCES resources(id) ON DELETE CASCADE
);

CREATE INDEX idx_resources_project ON resources(project_id);
CREATE INDEX idx_resources_type ON resources(resource_type);