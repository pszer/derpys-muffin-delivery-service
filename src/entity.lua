require "props.entityprops"
require "event"
require "custommodel"
require "gameinterface"
require "hitbox"

Entity = {__type = "entity"}
Entity.__index = Entity

function Entity:new(props)
	local this = {
		props = EntityPropPrototype(props),
	}

	setmetatable(this,Entity)

	this:coupleHitbox()
	return this
end

function Entity:newFromPrototype(prototype, props)
	local this = {
		props = prototype(props),
	}

	setmetatable(this,Entity)
	this:coupleHitbox()
	return this
end

function Entity:coupleHitbox()
	if self.props.ent_couple_hitbox then
		self.props.ent_hitbox.props.box_position = self.props.ent_position
		self.props.ent_hitbox.props.box_rotation = self.props.ent_rotation
		self.props.ent_hitbox.props.box_scale = self.props.ent_scale
		self.props.ent_hitbox:moved()
		self:updateBounds()
	end
end

-- this function should not be treated as a virtual function to overwrite, thats the job of Entity:update
-- let this do what its gotta do
function Entity:internalUpdate(dt)
	assert(dt)

	for i,v in pairs(self.props.ent_current_states) do
		if v.state_update then
			v.state_update(self, v)
		end
	end

	self:updateHitbox(dt)

	if self.props.ent_model_inherit then
		self:updateModelPosition()
	end
	self.ent_moved = false
end

function Entity:areBoundsChanged()
	if not self.props.ent_hitbox then return false end
	return self.props.ent_hitbox:areBoundsChanged()
end
function Entity:updateBounds()
	if not self.props.ent_hitbox then return false end
	self.props.ent_hitbox:updateBounds()
end
function Entity:informNewBoundsAreHandled()
	if not self.props.ent_hitbox then return end
	self.props.ent_hitbox:informNewBoundsAreHandled()
end

function Entity:update()

end

function Entity:updateModelPosition()
	if not self.props.ent_model_inherit then
		return
	end

	local model = self.props.ent_model
	local hitbox = self.props.ent_hitbox
	if model and hitbox then
		local m_props = model.props

		model:setPosition(hitbox:getPosition())
		model:setRotation(hitbox:getRotation())
		model:setScale   (hitbox:getScale())
	end
end

function Entity:getHitbox()
	return self.props.ent_hitbox
end

function Entity:getPosition()
	local hitbox = self.props.ent_hitbox
	if not hitbox then return nil end
	return hitbox:getPosition() end

function Entity:getBounds()
	local hitbox = self.props.ent_hitbox
	if not hitbox then return nil end
	return hitbox:getBounds()	
end

function Entity:getRotation()
	local hitbox = self.props.ent_hitbox
	if not hitbox then return nil end
	return hitbox:getRotation() end

function Entity:getScale()
	local hitbox = self.props.ent_hitbox
	if not hitbox then return nil end
	return hitbox:getScale() end

function Entity:getVelocity()
	local hitbox = self.props.ent_hitbox
	if not hitbox then return nil end
	return hitbox:getVelocity() end

function Entity:getSpeed()
	local hitbox = self.props.ent_hitbox
	if not hitbox then return nil end
	return hitbox:getSpeed() 
end
-- uses manhattan distance instead of euclidian
function Entity:getApproximateSpeed()
	local vel = self:getVelocity()
	local abs = math.abs
	return abs(vel[1]) + abs(vel[2]) + abs(vel[3])
end

local __temp_lmtspd_vec = {}
function Entity:limitSpeed( max_speed )
	local hitbox = self.props.ent_hitbox
	if not hitbox then return nil end
	hitbox:limitSpeed(max_speed)
end

local __temp_scvel_vec = {}
-- takes in a scalar to scale the entities velocity by
--  1.0 means no change
-- <1.0 decreases velocity over time
-- >1.0 increases velocity over time
function Entity:scaleVelocity(scale, dt)
	local hitbox = self.props.ent_hitbox
	if not hitbox then return nil end
	hitbox:scaleVelocity(scale,dt)
end

function Entity:getModel()
	return self.props.ent_model end
function Entity:getIdentifier()
	return self.props.ent_identifier end

function Entity:setVelocity(vel)
	local hitbox = self.props.ent_hitbox
	if not self.props.ent_hitbox then return end
	hitbox:setVelocity(vel)
end

local __temp_acc_vec = {}
-- adds an acceleration vector to the entity, scaled by
-- a given delta time step
function Entity:accelerate(vec, dt)
	local hitbox = self.props.ent_hitbox
	if not self.props.ent_hitbox then return end
	hitbox:accelerate(vec,dt)
end

function Entity:setPosition(pos)
	if not self.props.ent_hitbox then return end
	self.props.ent_hitbox:setPosition(pos)
end
function Entity:setRotation(rot)
	if not self.props.ent_hitbox then return end
	self.props.ent_hitbox:setRotation(rot)
end
function Entity:setScale(scale)
	if not self.props.ent_hitbox then return end
	self.props.ent_hitbox:setScale(scale)
end

function Entity:translatePosition(vec, dt)
	if not self.props.ent_hitbox then return end
	self.props.ent_hitbox:translatePosition(vec,dt)
end

function Entity:updateHitbox(dt)
	if self.props.ent_hitbox then
		self.props.ent_hitbox:update(dt)
	end
end

-- returns {x,y,z}, {dx,dy,dz}
function Entity:getWorldHitboxPosSize()
	local min,max = self:getBounds()

	if not min then return nil, nil end

	return { min[1]          , min[2],           min[3] },
		     { max[1] - min[1] , max[2] - min[2] , max[3] - min[3] }
end

-- returns {x,y,z}
function Entity:getWorldHitboxCentre()
	return self:getHitboxPointByRelativeCoord{0.5,0.5,0.5}
end

-- returns a point inside the entities hitbox, queried by an
-- argument coord with range 0.0 < coord.xyz < 1.0
-- coord = {0,0,0} would give the minimum point of the hitbox
-- coord = {1,1,1} would give the maximum point of the hitbox
-- coord = {0.5,0.5,0.5} would give the middle of the hitbox
-- etc.
--
function Entity:getHitboxPointByRelativeCoord(coord)
	local pos,size = self:getWorldHitboxPosSize()

	return {
		pos[1] + size[1]*coord[1],
		pos[2] + size[2]*coord[2],
		pos[3] + size[3]*coord[3]
	}
end

--[[
--
--
--
--
--
-- State functions
--
--
--
--
--
--]]

function Entity:getStateByName(name)
	if not name then return nil end

	local states = self.props.ent_states
	return states[name]
end

function Entity:getStateParent(state)
	if state then
		local parent_name = state.state_parent
		if parent_name then
			return self:getStateByName(parent_name)
		end
	end

	return nil
end

-- returns a command and the state it belongs to
function Entity:getCommand(command_name)
	local function traverse(state, recur)
		if not state then return nil, nil end

		local command = state.state_commands[command_name]
		if command then
			return command, state
		else
			local parent = self:getStateParent(state)
			return recur(parent, recur)
		end
	end

	for i,v in pairs(self.props.ent_current_states) do
		local found, state = traverse(v, traverse)
		if found then return found, state end
	end
	return nil, nil
end

function Entity:enableState(state)
	if state then
		if self:isStateEnabled(state) then
			print(string.format("Entity:changeState: tried to enter already enabled state"))
			return
		end

		local enter = state.state_enter
		table.insert(self.props.ent_current_states, state)
		if enter then
			enter(self, state)
		end
	else
		print(string.format("Entity:changeState: tried to enter non-existant state"))
	end
end

function Entity:enableStateByName(name)
	local state = self:getStateByName(name)
	if state then
		self:enableState(state)
	end
end

function Entity:disableState(state)
	if state then
		local enabled, index = self:isStateEnabled(state)
		if not enabled then
			print(string.format("Entity:changeState: tried to exit disabled state"))
			return
		end

		local exit = state.state_exit
		table.remove(self.props.ent_current_states, index)
		if exit then
			exit(self, state)
		end
	else
		print(string.format("Entity:changeState: tried to exit non-existant state"))
	end
end

function Entity:disableStateByName(name)
	local state = self:getStateByName(name)
	if state then
		self:disableState(state)
	end
end

function Entity:stateFromPrototype(GameData, prototype)
	local state = prototype()

	local proto_update = state.state_update
	local proto_enter  = state.state_enter
	local proto_exit   = state.state_exit

	local proto_comms  = state.state_commands
	for i,v in pairs(proto_comms) do
		proto_comms[i] = v(GameData)
	end
	if state.state_update then state.state_update = state.state_update(GameData) end
	if state.state_enter  then state.state_enter = state.state_enter(GameData) end 
	if state.state_exit   then state.state_exit = state.state_exit(GameData) end

	return state
end

-- returns true/false, and index of state in ent_current_states
function Entity:isStateEnabled(state)
	for i,v in pairs(self.props.ent_current_states) do
		if v == state then return true, i end
	end
	return false, nil
end


--
--
--
--
--
--
--
--
--

function Entity:toBeDeleted()
	return self.props.ent_delete_flag
end
function Entity:delete()
	self.props.ent_delete_flag = true
end

function Entity:callCommand(command_name, args)
	--local args = {...}
	prof.push("call_command")
	local command, state = self:getCommand(command_name)

	if not command then
		return
	end

	command(self, state, args)
	prof.pop("call_command")
end

function Entity:isModelAnimated()
	local model = self:getModel()
	if not model then return false end
	if not model:getAnimator() then return false end
	return true
end

--[[
--
--
--
--
--
-- Animation functions
--
--
--
--
--
--
---]]
function Entity:getAnimationByName(name)
	local model = self:getModel()
	if not model then
		error(string.format("Entity:getAnimationByName(): entity "%s" has no model", self:getIdentifier())) end
	return model.props.model_i_reference:getAnimation( name )
end

function Entity:setAnimationTime(time, which_animator)
	if not (which_animator == 1 or which_animator == 2) then
		error(string.format("Entity:setAnimationTime(): which_animator argument expected to be 1 or 2, got %s",
			tostring(which_animator), self:getIdentifier())) end
	local anim1, anim2 = self:getAnimator()

	if which_animator == 1 then
		anim1:setTime(time)
	else
		anim2:setTime(time)
	end
end

--
--
--
--
--
--
--
--
--
--

-- takes in established hooks from Prov:establishEntityHooks()
function Entity:addHook( hook )
	table.insert(self.props.ent_hooks, hook)
end

function Entity:clearHooks()
	for i,hook in ipairs(self.props.ent_hooks) do
		hook:clear()
	end
end

function Entity:getHooksInfo()
	return self.props.ent_hooks_info
end

