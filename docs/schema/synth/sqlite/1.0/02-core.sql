-- =============================================================================
-- SYNTH PROTOCOL - Core Schema
-- Maps to: core.xsd (ConfigurationType)
-- =============================================================================

-- =============================================================================
-- CONFIGURATION
-- Maps to: ConfigurationType
-- =============================================================================

CREATE TABLE IF NOT EXISTS configuration (
    project_id TEXT PRIMARY KEY,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

-- =============================================================================
-- RUNTIME
-- Maps to: RuntimeType
-- =============================================================================

CREATE TABLE IF NOT EXISTS runtime (
    project_id TEXT PRIMARY KEY,
    mode TEXT NOT NULL DEFAULT 'production' CHECK (mode IN ('development', 'staging', 'production')),
    work_dir TEXT,
    temp_dir TEXT,
    cache_dir TEXT,
    max_memory_mb INTEGER,
    max_threads INTEGER,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

-- =============================================================================
-- LOGGING
-- Maps to: LoggingType
-- =============================================================================

CREATE TABLE IF NOT EXISTS logging (
    project_id TEXT PRIMARY KEY,
    level TEXT NOT NULL DEFAULT 'INFO' CHECK (level IN ('TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR')),
    format TEXT,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

-- =============================================================================
-- LOG APPENDERS
-- Maps to: AppenderType
-- =============================================================================

CREATE TABLE IF NOT EXISTS log_appenders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id TEXT NOT NULL,
    appender_type TEXT NOT NULL CHECK (appender_type IN ('console', 'file', 'rolling-file', 'syslog')),
    name TEXT,
    appender_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS log_appender_config (
    appender_id INTEGER NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (appender_id, key),
    FOREIGN KEY (appender_id) REFERENCES log_appenders(id) ON DELETE CASCADE
);

CREATE INDEX idx_log_appenders_project ON log_appenders(project_id);

-- =============================================================================
-- METRICS
-- Maps to: MetricsType
-- =============================================================================

CREATE TABLE IF NOT EXISTS metrics (
    project_id TEXT PRIMARY KEY,
    enabled INTEGER NOT NULL DEFAULT 1,
    interval_seconds INTEGER NOT NULL DEFAULT 60,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

-- =============================================================================
-- METRICS EXPORTERS
-- Maps to: ExporterType
-- =============================================================================

CREATE TABLE IF NOT EXISTS metrics_exporters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id TEXT NOT NULL,
    exporter_type TEXT NOT NULL,
    endpoint TEXT,
    exporter_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS metrics_exporter_config (
    exporter_id INTEGER NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (exporter_id, key),
    FOREIGN KEY (exporter_id) REFERENCES metrics_exporters(id) ON DELETE CASCADE
);

CREATE INDEX idx_metrics_exporters_project ON metrics_exporters(project_id);

-- =============================================================================
-- ENVIRONMENT VARIABLES
-- Maps to: EnvironmentType, EnvVarType
-- =============================================================================

CREATE TABLE IF NOT EXISTS environment_vars (
    project_id TEXT NOT NULL,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    secret INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (project_id, name),
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

-- =============================================================================
-- COMMON TYPES
-- =============================================================================

-- Tensors (Maps to: TensorType)
CREATE TABLE IF NOT EXISTS tensors (
    id TEXT PRIMARY KEY,
    name TEXT,
    dtype TEXT NOT NULL DEFAULT 'FLOAT32' CHECK (dtype IN ('FLOAT32', 'FLOAT16', 'INT32', 'INT64', 'UINT8', 'BOOL', 'STRING')),
    data BLOB
);

CREATE TABLE IF NOT EXISTS tensor_shape (
    tensor_id TEXT NOT NULL,
    dim_index INTEGER NOT NULL,
    dim_value INTEGER NOT NULL,
    PRIMARY KEY (tensor_id, dim_index),
    FOREIGN KEY (tensor_id) REFERENCES tensors(id) ON DELETE CASCADE
);