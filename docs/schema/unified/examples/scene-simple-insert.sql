-- =============================================================================
-- SIMPLE INSERT TEST DATA (HeidiSQL compatible)
-- =============================================================================
-- Simplified version with short data_text values for GUI tools
-- =============================================================================

-- Scene
INSERT INTO scenes (uuid, version, name, description)
VALUES ('scene-001', 1, 'Test Level', 'Simple test scene');

-- Assets
INSERT INTO assets (uuid, name, asset_type, source_path, uri) VALUES
    ('asset-mesh-cube', 'Cube', 1, 'models/cube.gltf', 'asset://models/cube.gltf'),
    ('asset-mat-red', 'Red Material', 3, 'materials/red.mat', 'asset://materials/red.mat');

-- Entities
INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid) VALUES
    ('world', 'World', 'root', 1, NULL, 0, 'scene-001'),
    ('cube-001', 'Cube 1', 'prop', 1, 'world', 0, 'scene-001'),
    ('cube-002', 'Cube 2', 'prop', 1, 'world', 1, 'scene-001'),
    ('light-001', 'Sun', 'light', 1, 'world', 2, 'scene-001');

-- Components (simple XML, single line)
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text) VALUES
    ('c-cube1-tf', 'cube-001', 'transform', 1, 'application/xml', '<transform><position x="0" y="0" z="0"/></transform>'),
    ('c-cube1-mesh', 'cube-001', 'mesh', 1, 'application/xml', '<mesh><asset uuid="asset-mesh-cube"/></mesh>'),
    ('c-cube2-tf', 'cube-002', 'transform', 1, 'application/xml', '<transform><position x="5" y="0" z="0"/></transform>'),
    ('c-cube2-mesh', 'cube-002', 'mesh', 1, 'application/xml', '<mesh><asset uuid="asset-mesh-cube"/></mesh>'),
    ('c-light-tf', 'light-001', 'transform', 1, 'application/xml', '<transform><position x="0" y="10" z="0"/></transform>'),
    ('c-light-light', 'light-001', 'light', 1, 'application/xml', '<light><type>directional</type><intensity>1.0</intensity></light>');

-- Verify
-- SELECT * FROM v_entity_tree;
-- SELECT * FROM v_entities_with_components;
