-- =============================================================================
-- SYNTH PROTOCOL - Security Schema
-- Maps to: security.xsd
-- =============================================================================

-- =============================================================================
-- SECURITY CONFIGURATION
-- Maps to: SecurityType
-- =============================================================================

CREATE TABLE IF NOT EXISTS security (
    project_id TEXT PRIMARY KEY,
    enabled INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

-- =============================================================================
-- AUTHENTICATION
-- Maps to: AuthenticationType
-- =============================================================================

CREATE TABLE IF NOT EXISTS authentication (
    project_id TEXT PRIMARY KEY,
    required INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

-- =============================================================================
-- AUTH PROVIDERS
-- Maps to: AuthProviderType
-- =============================================================================

CREATE TABLE IF NOT EXISTS auth_providers (
    id TEXT,
    project_id TEXT NOT NULL,
    provider_type TEXT NOT NULL CHECK (provider_type IN ('api-key', 'jwt', 'oauth2', 'mtls', 'basic')),
    provider_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (id, project_id),
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS auth_provider_config (
    provider_id TEXT NOT NULL,
    project_id TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (provider_id, project_id, key),
    FOREIGN KEY (provider_id, project_id) REFERENCES auth_providers(id, project_id) ON DELETE CASCADE
);

CREATE INDEX idx_auth_providers_project ON auth_providers(project_id);

-- =============================================================================
-- AUTHORIZATION
-- Maps to: AuthorizationType
-- =============================================================================

CREATE TABLE IF NOT EXISTS authorization (
    project_id TEXT PRIMARY KEY,
    model TEXT NOT NULL DEFAULT 'rbac' CHECK (model IN ('rbac', 'abac', 'acl')),
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

-- =============================================================================
-- POLICIES
-- Maps to: PoliciesType, PolicyType
-- =============================================================================

CREATE TABLE IF NOT EXISTS policies (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    effect TEXT NOT NULL DEFAULT 'allow' CHECK (effect IN ('allow', 'deny')),
    policy_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS policy_resources (
    policy_id TEXT NOT NULL,
    resource_pattern TEXT NOT NULL,
    pattern_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (policy_id, resource_pattern),
    FOREIGN KEY (policy_id) REFERENCES policies(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS policy_actions (
    policy_id TEXT NOT NULL,
    action TEXT NOT NULL,
    action_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (policy_id, action),
    FOREIGN KEY (policy_id) REFERENCES policies(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS policy_conditions (
    policy_id TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    operator TEXT NOT NULL DEFAULT 'equals' CHECK (operator IN ('equals', 'not-equals', 'contains', 'starts-with', 'matches')),
    PRIMARY KEY (policy_id, key),
    FOREIGN KEY (policy_id) REFERENCES policies(id) ON DELETE CASCADE
);

CREATE INDEX idx_policies_project ON policies(project_id);

-- =============================================================================
-- ROLES
-- Maps to: RolesType, RoleType
-- =============================================================================

CREATE TABLE IF NOT EXISTS roles (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    name TEXT,
    description TEXT,
    role_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id TEXT NOT NULL,
    permission TEXT NOT NULL,
    PRIMARY KEY (role_id, permission),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS role_inheritance (
    role_id TEXT NOT NULL,
    inherits_from TEXT NOT NULL,
    PRIMARY KEY (role_id, inherits_from),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (inherits_from) REFERENCES roles(id) ON DELETE CASCADE
);

CREATE INDEX idx_roles_project ON roles(project_id);

-- =============================================================================
-- ENCRYPTION
-- Maps to: EncryptionType
-- =============================================================================

CREATE TABLE IF NOT EXISTS encryption_at_rest (
    project_id TEXT PRIMARY KEY,
    enabled INTEGER NOT NULL DEFAULT 1,
    algorithm TEXT NOT NULL DEFAULT 'AES-256-GCM',
    key_provider TEXT,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS encryption_at_rest_config (
    project_id TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (project_id, key),
    FOREIGN KEY (project_id) REFERENCES encryption_at_rest(project_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS encryption_in_transit (
    project_id TEXT PRIMARY KEY,
    enabled INTEGER NOT NULL DEFAULT 1,
    min_version TEXT NOT NULL DEFAULT 'TLS1.2',
    certificate TEXT,
    private_key TEXT,
    ca TEXT,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

-- =============================================================================
-- AUDIT
-- Maps to: AuditType
-- =============================================================================

CREATE TABLE IF NOT EXISTS audit (
    project_id TEXT PRIMARY KEY,
    enabled INTEGER NOT NULL DEFAULT 1,
    log_all INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS audit_events (
    project_id TEXT NOT NULL,
    event TEXT NOT NULL,
    PRIMARY KEY (project_id, event),
    FOREIGN KEY (project_id) REFERENCES audit(project_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS audit_destination (
    project_id TEXT PRIMARY KEY,
    dest_type TEXT NOT NULL CHECK (dest_type IN ('file', 'syslog', 'database', 'webhook')),
    FOREIGN KEY (project_id) REFERENCES audit(project_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS audit_destination_config (
    project_id TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (project_id, key),
    FOREIGN KEY (project_id) REFERENCES audit_destination(project_id) ON DELETE CASCADE
);