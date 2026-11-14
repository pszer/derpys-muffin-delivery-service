require "gameinterface"

require 'capsule'
require 'intersect'

Physics = {

	gravity = {0.0,3.0,0.0}

}
Physics.__index = physics

local CONSTS = require 'consts'

function Physics:applyGravity(hitbox, dt)
	hitbox:accelerate(gravity, dt)	
end

function Physics:commitVelocity(hitbox, dt)
	hitbox:translatePosition(hitbox:getVelocity(), dt)
end

function Physics:collideAgainstTriangle(hitbox, t1,t2,t3)
end
