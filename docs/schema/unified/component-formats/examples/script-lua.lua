-- Component: script
-- Content-Type: text/x-lua
-- Entity: player-001

local PlayerController = {}
PlayerController.__index = PlayerController

-- Properties (serialized in component)
PlayerController.moveSpeed = 5.0
PlayerController.jumpForce = 8.0
PlayerController.turnSpeed = 180
PlayerController.groundLayer = 1

function PlayerController:new(entity)
    local self = setmetatable({}, PlayerController)
    self.entity = entity
    self.velocity = Vec3(0, 0, 0)
    self.isGrounded = false
    return self
end

function PlayerController:update(deltaTime)
    -- Get input
    local moveX = Input.getAxis("Horizontal")
    local moveZ = Input.getAxis("Vertical")

    -- Calculate movement
    local move = Vec3(moveX, 0, moveZ):normalize() * self.moveSpeed

    -- Apply to transform
    local transform = self.entity:getComponent("transform")
    if transform then
        transform.position = transform.position + move * deltaTime
    end

    -- Jump
    if Input.getButtonDown("Jump") and self.isGrounded then
        self.velocity.y = self.jumpForce
    end

    -- State machine transition
    if move:length() > 0.1 then
        self.entity:requestStateTransition("movement", "CHARACTER_WALKING")
    else
        self.entity:requestStateTransition("movement", "CHARACTER_IDLE")
    end
end

function PlayerController:onCollisionEnter(other)
    if other.layer == self.groundLayer then
        self.isGrounded = true
    end
end

function PlayerController:onCollisionExit(other)
    if other.layer == self.groundLayer then
        self.isGrounded = false
    end
end

return PlayerController
