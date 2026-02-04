-- =============================================================================
-- INSERT TEST DATA: scene-complete.scene.synth.xml
-- =============================================================================
-- Generated from: scene-complete.scene.synth.xml
-- Target schema: unified-schema.sql
-- =============================================================================

-- =============================================================================
-- SCENE
-- =============================================================================

INSERT INTO scenes (uuid, version, created_at, updated_at, name, description)
VALUES (
    'scene-001',
    1,
    1703155200000,
    1703241600000,
    'Main Level',
    'The main game level with player, NPCs and environment'
);

-- =============================================================================
-- ASSETS
-- =============================================================================

INSERT INTO assets (uuid, name, asset_type, source_path, uri) VALUES
    ('asset-mesh-player', 'Player Model', 1, 'models/characters/player.gltf', 'asset://models/characters/player.gltf'),
    ('asset-mesh-guard', 'Guard Model', 1, 'models/characters/guard.gltf', 'asset://models/characters/guard.gltf'),
    ('asset-mesh-sword', 'Sword Model', 1, 'models/weapons/sword.gltf', 'asset://models/weapons/sword.gltf'),
    ('asset-mesh-plane', 'Plane Model', 1, 'models/primitives/plane.gltf', 'asset://models/primitives/plane.gltf'),
    ('asset-mesh-oak', 'Oak Tree Model', 1, 'models/nature/oak_tree.gltf', 'asset://models/nature/oak_tree.gltf'),
    ('asset-mat-grass', 'Grass Material', 3, 'materials/terrain/grass.mat', 'asset://materials/terrain/grass.mat'),
    ('asset-audio-forest', 'Forest Ambient', 5, 'audio/ambient_forest.ogg', 'asset://audio/ambient_forest.ogg');

-- =============================================================================
-- ENTITIES (hierarchisch)
-- =============================================================================

-- World Root (kein Parent)
INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('world-root', 'World', 'root', 1, NULL, 0, 'scene-001');

-- Environment: Sun
INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('env-sun', 'Sun', 'light', 1, 'world-root', 0, 'scene-001');

-- Environment: Ambient Audio
INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('env-ambient', 'Ambient Audio', 'audio', 1, 'world-root', 1, 'scene-001');

-- Player
INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('player-001', 'Player', 'player', 1, 'world-root', 2, 'scene-001');

-- Player Children
INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('player-camera', 'Main Camera', 'camera', 1, 'player-001', 0, 'scene-001');

INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('player-weapon-holder', 'Weapon Holder', 'prop', 1, 'player-001', 1, 'scene-001');

INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('player-sword', 'Sword', 'item', 1, 'player-weapon-holder', 0, 'scene-001');

-- NPC: Guard
INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('npc-guard-001', 'Guard', 'npc', 1, 'world-root', 3, 'scene-001');

-- Environment: Ground
INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('env-ground', 'Ground', 'prop', 1, 'world-root', 4, 'scene-001');

-- Trees Container
INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('env-trees', 'Trees', 'container', 1, 'world-root', 5, 'scene-001');

INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('tree-001', 'Oak Tree 1', 'prop', 1, 'env-trees', 0, 'scene-001');

INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('tree-002', 'Oak Tree 2', 'prop', 1, 'env-trees', 1, 'scene-001');

-- Trigger Zone: Checkpoint
INSERT INTO entities (uuid, name, entity_type, state, parent_uuid, sibling_order, scene_uuid)
VALUES ('trigger-checkpoint', 'Checkpoint', 'trigger', 1, 'world-root', 6, 'scene-001');

-- =============================================================================
-- COMPONENTS
-- =============================================================================

-- Sun Components
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-sun-transform', 'env-sun', 'transform', 1, 'application/xml',
'<transform>
    <position x="0" y="100" z="0"/>
    <rotation x="-0.5" y="0.1" z="0" w="0.86"/>
    <scale x="1" y="1" z="1"/>
</transform>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-sun-light', 'env-sun', 'light', 1, 'application/xml',
'<light>
    <light-type>directional</light-type>
    <color r="1.0" g="0.95" b="0.8"/>
    <intensity>1.5</intensity>
    <shadows enabled="true" resolution="2048" bias="0.001"/>
</light>');

-- Ambient Audio Component
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-ambient-audio', 'env-ambient', 'audio', 1, 'application/xml',
'<audio>
    <asset uuid="asset-audio-forest" path="audio/ambient_forest.ogg"/>
    <volume>0.3</volume>
    <loop>true</loop>
    <play-on-awake>true</play-on-awake>
    <spatial>false</spatial>
</audio>');

-- Player Components
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-player-transform', 'player-001', 'transform', 1, 'application/xml',
'<transform>
    <position x="0" y="1.0" z="5"/>
    <rotation x="0" y="0" z="0" w="1"/>
    <scale x="1" y="1" z="1"/>
</transform>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-player-mesh', 'player-001', 'mesh', 1, 'application/xml',
'<mesh>
    <asset uuid="asset-mesh-player" path="models/characters/player.gltf"/>
    <lod level="0" bias="0"/>
    <shadows cast="true" receive="true"/>
    <render-layer>default</render-layer>
</mesh>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-player-physics', 'player-001', 'physics', 1, 'application/xml',
'<physics>
    <body-type>dynamic</body-type>
    <mass>70</mass>
    <drag>0.1</drag>
    <angular-drag>0.05</angular-drag>
    <use-gravity>true</use-gravity>
    <freeze-rotation x="true" y="false" z="true"/>
    <collider type="capsule">
        <center x="0" y="0.9" z="0"/>
        <radius>0.3</radius>
        <height>1.8</height>
    </collider>
</physics>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-player-fsm', 'player-001', 'state_machine', 1, 'application/xml',
'<state-machine name="movement" initial="IDLE">
    <states>
        <state id="IDLE" display="Idle">
            <properties>
                <property name="canInteract" type="bool">true</property>
            </properties>
        </state>
        <state id="WALKING" display="Walking">
            <properties>
                <property name="moveSpeed" type="float">2.5</property>
            </properties>
        </state>
        <state id="RUNNING" display="Running">
            <properties>
                <property name="moveSpeed" type="float">5.0</property>
                <property name="staminaDrain" type="float">10</property>
            </properties>
        </state>
        <state id="JUMPING" display="Jumping"/>
    </states>
    <transitions>
        <transition from="IDLE" to="WALKING">
            <triggers><trigger>input_move</trigger></triggers>
        </transition>
        <transition from="WALKING" to="RUNNING">
            <triggers><trigger>input_sprint</trigger></triggers>
        </transition>
        <transition from="*" to="JUMPING">
            <triggers><trigger>input_jump</trigger></triggers>
            <conditions><condition type="grounded" value="true"/></conditions>
        </transition>
    </transitions>
</state-machine>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-player-script', 'player-001', 'script', 1, 'text/x-lua',
'local PlayerController = {}
PlayerController.__index = PlayerController

PlayerController.moveSpeed = 5.0
PlayerController.jumpForce = 8.0

function PlayerController:new(entity)
    local self = setmetatable({}, PlayerController)
    self.entity = entity
    self.isGrounded = false
    return self
end

function PlayerController:update(deltaTime)
    local moveX = Input.getAxis("Horizontal")
    local moveZ = Input.getAxis("Vertical")
    local move = Vec3(moveX, 0, moveZ):normalize() * self.moveSpeed

    local transform = self.entity:getComponent("transform")
    if transform then
        transform.position = transform.position + move * deltaTime
    end

    if Input.getButtonDown("Jump") and self.isGrounded then
        self.entity:requestStateTransition("movement", "JUMPING")
    end
end

return PlayerController');

-- Camera Components
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-camera-transform', 'player-camera', 'transform', 1, 'application/xml',
'<transform>
    <position x="0" y="1.6" z="-3"/>
    <rotation x="0.1" y="0" z="0" w="0.995"/>
    <scale x="1" y="1" z="1"/>
</transform>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-camera-camera', 'player-camera', 'camera', 1, 'application/xml',
'<camera>
    <projection>perspective</projection>
    <fov>60</fov>
    <near>0.1</near>
    <far>1000</far>
    <clear-color r="0.1" g="0.1" b="0.15" a="1"/>
</camera>');

-- Weapon Holder Transform
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-weapon-holder-transform', 'player-weapon-holder', 'transform', 1, 'application/xml',
'<transform>
    <position x="0.3" y="1.2" z="0.2"/>
    <rotation x="0" y="0" z="0" w="1"/>
    <scale x="1" y="1" z="1"/>
</transform>');

-- Sword Components
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-sword-transform', 'player-sword', 'transform', 1, 'application/xml',
'<transform>
    <position x="0" y="0" z="0"/>
    <rotation x="0" y="0" z="0" w="1"/>
    <scale x="1" y="1" z="1"/>
</transform>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-sword-mesh', 'player-sword', 'mesh', 1, 'application/xml',
'<mesh>
    <asset uuid="asset-mesh-sword" path="models/weapons/sword.gltf"/>
    <shadows cast="true" receive="false"/>
</mesh>');

-- Guard Components
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-guard-transform', 'npc-guard-001', 'transform', 1, 'application/xml',
'<transform>
    <position x="10" y="0" z="-5"/>
    <rotation x="0" y="0.707" z="0" w="0.707"/>
    <scale x="1" y="1" z="1"/>
</transform>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-guard-mesh', 'npc-guard-001', 'mesh', 1, 'application/xml',
'<mesh>
    <asset uuid="asset-mesh-guard" path="models/characters/guard.gltf"/>
    <shadows cast="true" receive="true"/>
</mesh>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-guard-fsm', 'npc-guard-001', 'state_machine', 1, 'application/xml',
'<state-machine name="ai_behavior" initial="PATROL">
    <states>
        <state id="PATROL" display="Patrolling">
            <properties>
                <property name="moveSpeed" type="float">1.5</property>
            </properties>
        </state>
        <state id="ALERT" display="Alert">
            <properties>
                <property name="lookAroundTime" type="float">3.0</property>
            </properties>
        </state>
        <state id="CHASE" display="Chasing">
            <properties>
                <property name="moveSpeed" type="float">4.0</property>
            </properties>
        </state>
        <state id="ATTACK" display="Attacking"/>
    </states>
    <transitions>
        <transition from="PATROL" to="ALERT">
            <conditions><condition type="perception" target="player" op="lt" value="15"/></conditions>
        </transition>
        <transition from="ALERT" to="CHASE">
            <conditions><condition type="perception" target="player" op="lt" value="10"/></conditions>
        </transition>
        <transition from="CHASE" to="ATTACK">
            <conditions><condition type="distance" target="player" op="lt" value="2"/></conditions>
        </transition>
    </transitions>
</state-machine>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-guard-script', 'npc-guard-001', 'script', 1, 'text/x-lua',
'local GuardAI = {}
GuardAI.__index = GuardAI

function GuardAI:new(entity)
    local self = setmetatable({}, GuardAI)
    self.entity = entity
    self.patrolIndex = 1
    return self
end

function GuardAI:update(deltaTime)
    local state = self.entity:getCurrentState("ai_behavior")
    if state == "PATROL" then
        self:patrol(deltaTime)
    elseif state == "CHASE" then
        self:chasePlayer(deltaTime)
    end
end

function GuardAI:chasePlayer(deltaTime)
    local player = Scene.findEntity("player-001")
    if player then
        local dir = (player.position - self.entity.position):normalize()
        self.entity.position = self.entity.position + dir * 4.0 * deltaTime
    end
end

return GuardAI');

-- Ground Components
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-ground-transform', 'env-ground', 'transform', 1, 'application/xml',
'<transform>
    <position x="0" y="0" z="0"/>
    <rotation x="0" y="0" z="0" w="1"/>
    <scale x="100" y="1" z="100"/>
</transform>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-ground-mesh', 'env-ground', 'mesh', 1, 'application/xml',
'<mesh>
    <asset uuid="asset-mesh-plane" path="models/primitives/plane.gltf"/>
    <shadows cast="false" receive="true"/>
</mesh>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-ground-material', 'env-ground', 'material', 1, 'application/xml',
'<material>
    <asset uuid="asset-mat-grass" path="materials/terrain/grass.mat"/>
    <properties>
        <property name="tiling" type="vec2">50 50</property>
    </properties>
</material>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-ground-physics', 'env-ground', 'physics', 1, 'application/xml',
'<physics>
    <body-type>static</body-type>
    <collider type="box">
        <center x="0" y="-0.5" z="0"/>
        <size x="100" y="1" z="100"/>
    </collider>
    <physics-material>
        <friction>0.6</friction>
        <bounciness>0</bounciness>
    </physics-material>
</physics>');

-- Tree 1 Components
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-tree1-transform', 'tree-001', 'transform', 1, 'application/xml',
'<transform>
    <position x="-15" y="0" z="10"/>
    <rotation x="0" y="0.3" z="0" w="0.95"/>
    <scale x="1.2" y="1.2" z="1.2"/>
</transform>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-tree1-mesh', 'tree-001', 'mesh', 1, 'application/xml',
'<mesh>
    <asset uuid="asset-mesh-oak" path="models/nature/oak_tree.gltf"/>
    <shadows cast="true" receive="true"/>
</mesh>');

-- Tree 2 Components
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-tree2-transform', 'tree-002', 'transform', 1, 'application/xml',
'<transform>
    <position x="20" y="0" z="-8"/>
    <rotation x="0" y="0.7" z="0" w="0.71"/>
    <scale x="0.9" y="1.1" z="0.9"/>
</transform>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-tree2-mesh', 'tree-002', 'mesh', 1, 'application/xml',
'<mesh>
    <asset uuid="asset-mesh-oak" path="models/nature/oak_tree.gltf"/>
    <shadows cast="true" receive="true"/>
</mesh>');

-- Checkpoint Components
INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-checkpoint-transform', 'trigger-checkpoint', 'transform', 1, 'application/xml',
'<transform>
    <position x="25" y="1" z="0"/>
    <rotation x="0" y="0" z="0" w="1"/>
    <scale x="5" y="2" z="5"/>
</transform>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-checkpoint-physics', 'trigger-checkpoint', 'physics', 1, 'application/xml',
'<physics>
    <body-type>static</body-type>
    <collider type="box" trigger="true">
        <center x="0" y="0" z="0"/>
        <size x="1" y="1" z="1"/>
    </collider>
</physics>');

INSERT INTO components (uuid, entity_uuid, component_type, enabled, content_type, data_text)
VALUES ('comp-checkpoint-script', 'trigger-checkpoint', 'script', 1, 'text/x-lua',
'local Checkpoint = {}

function Checkpoint:onTriggerEnter(other)
    if other.tag == "player" then
        Game.setCheckpoint(self.entity.position)
        Audio.play("sfx/checkpoint.ogg")
    end
end

return Checkpoint');

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Count entities per type
-- SELECT entity_type, COUNT(*) as count FROM entities GROUP BY entity_type;

-- Show entity hierarchy
-- SELECT * FROM v_entity_tree;

-- Show all components for player
-- SELECT * FROM v_entities_with_components WHERE entity_uuid = 'player-001';
