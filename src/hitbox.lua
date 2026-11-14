local cpml = require 'cpml'
require 'props.hitboxprops'

Hitbox = {__type='hitbox'}
Hitbox.__index = Hitbox

function Hitbox:new(props)
	local this = {
		props = HitboxPropPrototype(props),
		recalculate_bounds_flag = true
	}

	setmetatable(this,Hitbox)
	this:modelMatrix()
	return this
end

function Hitbox:update(dt)
	self:translatePosition(self:getVelocity(), dt)

	if recalculate_bounds_flag then
		-- TODO recalculate bounding box
		recalculate_bounds_flag = false
	end
end

function Hitbox:type()
	return self.props.box_type
end

local __temp_mat4 = cpml.mat4.new()
local id = {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
local __p_temptable = {
{0,0,0,0},
{0,0,0,0},
{0,0,0,0},
{0,0,0,0},
{0,0,0,0},
{0,0,0,0},
{0,0,0,0},
{0,0,0,0}}
local __tempnewmin = {}
local __tempnewmax = {}
local __temp_a = {}
local __temp_b = {}
function Hitbox:updateBounds()
	if not self.recalculate_bounds_flag then return end

	local props = self.props
	if self:type()=="model" then
		self:modelMatrix()
		local model, instance_i = props.box_model, props.box_model_instance_i

		if not instance_i then -- non-instanced model
			local bounds = model:calculateBoundingBox()
			props.box_bounds.min[1] = bounds.min[1]
			props.box_bounds.min[2] = bounds.min[2]
			props.box_bounds.min[3] = bounds.min[3]
			props.box_bounds.max[1] = bounds.max[1]
			props.box_bounds.max[2] = bounds.max[2]
			props.box_bounds.max[3] = bounds.max[3]
		else
			local info = props.model_i_instances[props.box_model_instance_i]
			local model_m,norm_m = self.props.box_model_mat, self.props.box_normal_mat
			local bbox = model:getUnfixedModelReferenceBoundingBox()
			local min = bbox.min
			local max = bbox.max
			local p = __p_temptable
			p[1][1] = min[1]     p[1][2] = min[2]    p[1][3] = min[3]  p[1][4] = 1
			p[2][1] = max[1]     p[2][2] = min[2]    p[2][3] = min[3]  p[2][4] = 1
			p[3][1] = min[1]     p[3][2] = max[2]    p[3][3] = min[3]  p[3][4] = 1
			p[4][1] = max[1]     p[4][2] = max[2]    p[4][3] = min[3]  p[4][4] = 1
			p[5][1] = min[1]     p[5][2] = min[2]    p[5][3] = max[3]  p[5][4] = 1
			p[6][1] = max[1]     p[6][2] = min[2]    p[6][3] = max[3]  p[6][4] = 1
			p[7][1] = min[1]     p[7][2] = max[2]    p[7][3] = max[3]  p[7][4] = 1
			p[8][1] = max[1]     p[8][2] = max[2]    p[8][3] = max[3]  p[8][4] = 1
			local mat_vec4_mul = cpml.mat4.mul_vec4
			-- transform all 8 vertices by the model matrix
			for i=1,8 do
				local vec = p[i]
				mat_vec4_mul(vec, model_m, vec)
			--	local w = vec[4]
			--	vec[1] = vec[1] / w
			--	vec[2] = vec[2] / w
			--	vec[3] = vec[3] / w
			--	vec[4] = 1 
			end
			-- we find out the new min/max x,y,z components of all the
			-- transformed vertices to get the min/max for our new
			-- bounding box
			local new_min = __tempnewmin
			local new_max = __tempnewmax
			new_min[1],new_min[2],new_min[3] = 1/0,1/0,1/0
			new_max[1],new_max[2],new_max[3] =-1/0,-1/0,-1/0
			for i=1,8 do
				local vec = p[i]
				if vec[1] < new_min[1] then new_min[1] = vec[1] end
				if vec[2] < new_min[2] then new_min[2] = vec[2] end
				if vec[3] < new_min[3] then new_min[3] = vec[3] end
				if vec[1] > new_max[1] then new_max[1] = vec[1] end
				if vec[2] > new_max[2] then new_max[2] = vec[2] end
				if vec[3] > new_max[3] then new_max[3] = vec[3] end
			end
			props.box_bounds.min[1] = new_min[1]
			props.box_bounds.min[2] = new_min[2]
			props.box_bounds.min[3] = new_min[3]
			props.box_bounds.max[1] = new_max[1]
			props.box_bounds.max[2] = new_max[2]
			props.box_bounds.max[3] = new_max[3]
		end
		return
	--capsule
	elseif self:type() == "capsule" then
		local mat = self:modelMatrix()

		-- rotate the segment ab of the capsule
		local point_a,point_b = self.props.box_capsule.a, self.props.box_capsule.b
		local v_a = __temp_a 
		local v_b = __temp_b
		v_a[1],v_a[2],v_a[3],v_a[4] = point_a[1],point_a[2],point_a[3],1.0 
		v_b[1],v_b[2],v_b[3],v_b[4] = point_b[1],point_b[2],point_b[3],1.0 
		cpml.mat4.mul_vec4(v_a, mat, v_a)
		cpml.mat4.mul_vec4(v_b, mat, v_b)

		--min
		props.box_bounds.min[1] = math.min(v_a[1] - props.box_sphere.radius * props.box_scale[1], v_b[1] - props.box_sphere.radius * props.box_scale[1])
		props.box_bounds.min[2] = math.min(v_a[2] - props.box_sphere.radius * props.box_scale[2], v_b[2] - props.box_sphere.radius * props.box_scale[2])
		props.box_bounds.min[3] = math.min(v_a[3] - props.box_sphere.radius * props.box_scale[3], v_b[3] - props.box_sphere.radius * props.box_scale[3])

		--max
		props.box_bounds.max[1] = math.max(v_a[1] + props.box_sphere.radius * props.box_scale[1], v_b[1] + props.box_sphere.radius * props.box_scale[1])
		props.box_bounds.max[2] = math.max(v_a[2] + props.box_sphere.radius * props.box_scale[2], v_b[2] + props.box_sphere.radius * props.box_scale[2])
		props.box_bounds.max[3] = math.max(v_a[3] + props.box_sphere.radius * props.box_scale[3], v_b[3] + props.box_sphere.radius * props.box_scale[3])

	elseif self:type() == "sphere" then
		props.max_bounds.min[1] = props.box_position[1] + props.box_sphere.a[1] - props.box_sphere.radius * props.box_scale[1]
		props.max_bounds.min[2] = props.box_position[2] + props.box_sphere.a[2] - props.box_sphere.radius * props.box_scale[2]
		props.max_bounds.min[3] = props.box_position[3] + props.box_sphere.a[3] - props.box_sphere.radius * props.box_scale[3]
		props.max_bounds.max[1] = props.box_position[1] + props.box_sphere.a[1] + props.box_sphere.radius * props.box_scale[1]
		props.max_bounds.max[2] = props.box_position[2] + props.box_sphere.a[2] + props.box_sphere.radius * props.box_scale[2]
		props.max_bounds.max[3] = props.box_position[3] + props.box_sphere.a[3] + props.box_sphere.radius * props.box_scale[3]
	elseif self:type() == "box" then
		local mat = self:generateModelMat()

		local x,y,z,w,h,r = props.box_aabb[1], props.box_aabb[1], props.box_aabb[3], props.box_aabb[4]

		-- if negative
		if w<0 then x=x-w; w=-w end
		if h<0 then y=y-h; h=-h end
		if r<0 then z=z-r; r=-r end

		local p = __p_temptable
		p[1][1] = x     p[1][2] = y    p[1][3] = z    p[1][4] = 1
		p[2][1] = x+w   p[2][2] = y    p[2][3] = z    p[2][4] = 1
		p[3][1] = x     p[3][2] = y+h  p[3][3] = z    p[3][4] = 1
		p[4][1] = x+w   p[4][2] = y+h  p[4][3] = z    p[4][4] = 1
		p[5][1] = x     p[5][2] = y    p[5][3] = z+r  p[5][4] = 1
		p[6][1] = x+w   p[6][2] = y    p[6][3] = z+r  p[6][4] = 1
		p[7][1] = x     p[7][2] = y+h  p[7][3] = z+r  p[7][4] = 1
		p[8][1] = x+w   p[8][2] = y+h  p[8][3] = z+r  p[8][4] = 1
		local mat_vec4_mul = cpml.mat4.mul_vec4
		-- transform all 8 vertices by the model matrix
		for i=1,8 do
			local vec = p[i]
			mat_vec4_mul(vec, model_m, vec)
		--	local w = vec[4]
		--	vec[1] = vec[1] / w
		--	vec[2] = vec[2] / w
		--	vec[3] = vec[3] / w
		--	vec[4] = 1 
		end
		-- we find out the new min/max x,y,z components of all the
		-- transformed vertices to get the min/max for our new
		-- bounding box
		local new_min = __tempnewmin
		local new_max = __tempnewmax
		new_min[1],new_min[2],new_min[3] = 1/0,1/0,1/0
		new_max[1],new_max[2],new_max[3] =-1/0,-1/0,-1/0
		for i=1,8 do
			local vec = p[i]
			if vec[1] < new_min[1] then new_min[1] = vec[1] end
			if vec[2] < new_min[2] then new_min[2] = vec[2] end
			if vec[3] < new_min[3] then new_min[3] = vec[3] end
			if vec[1] > new_max[1] then new_max[1] = vec[1] end
			if vec[2] > new_max[2] then new_max[2] = vec[2] end
			if vec[3] > new_max[3] then new_max[3] = vec[3] end
		end
		props.box_bounds.min[1] = new_min[1]
		props.box_bounds.min[2] = new_min[2]
		props.box_bounds.min[3] = new_min[3]
		props.box_bounds.max[1] = new_max[1]
		props.box_bounds.max[2] = new_max[2]
		props.box_bounds.max[3] = new_max[3]
	end
	-- TODO
end

function Hitbox:modelMatrix()
	if not self.recalculate_bounds_flag then return self.props.box_model_mat, self.props.box_normal_mat end
	local props = self.props

	local model, instance_i = props.box_model, props.box_model_instance_i

	if not instance_i and self:type()=='model' then -- non-instanced model
		self.props.box_model_mat = model:modelMatrix()
	else

		local pos,rot,scale
		local dirfix
		if self:type()=='model' then--gpu instanced model
			local info = props.model_i_instances[props.box_model_instance_i]
			pos,rot,scale = info.position, info.rotation, info.scale
			dirfix = info:getDirectionFixingMatrix()
		else
			pos,rot,scale = props.box_position,props.box_rotation,props.box_scale
		end

		local mat = cpml.mat4.new()
		for i=1,16 do mat[i]=id[i] end

		local vec3 = cpml.vec3.new(scale)
		cpml.mat4.scale(mat, mat, vec3)
		rotateMatrix(mat,rot)
		vec3 = cpml.vec3.new(pos)
		cpml.mat4.translate(mat, mat, vec3)
		if dirfix then
			mat = cpml.mat.mul(mat, mat, dirfix)
		end

		local norm_m = cpml.mat4.new()
		norm_m = norm_m:invert(mat)
		norm_m = norm_m:transpose(norm_m)

		self.props.box_model_mat  = mat
		self.props.box_normal_mat = norm_m
	end
	return self.props.box_model_mat, self.props.box_normal_mat
end

function Hitbox:areBoundsChanged()
	return self.recalculate_bounds_flag
end
function Hitbox:informNewBoundsAreHandled()
	self.recalculate_bounds_flag = false
end

-- call if hitbox has moved, so that new bounds can be calculated
function Hitbox:moved()
	-- static hitboxes only get updated once.
	if not self.props.box_static then
		self.recalculate_bounds_flag = true
	end
end

function Hitbox:getPosition()
	return self.props.box_position end
function Hitbox:getRotation()
	return self.props.box_rotation end
function Hitbox:getScale()
	return self.props.box_scale end
function Hitbox:getVelocity()
	return self.props.box_velocity end
function Hitbox:getSpeed()
	local vel = self:getVelocity()
	return math.sqrt(vel[1]*vel[1] + vel[2]*vel[2] + vel[3]*vel[3])
end
function Hitbox:getBounds()
	return self.props.box_bounds.min, self.props.box_bounds.max
end

function Hitbox:setVelocity(vel)
	local v = self.props.box_velocity
	if vel[1]~=v[1]or vel[2]~=v[2] or vel[3]~=v[3] then
		self.props.box_velocity[1] = vel[1]
		self.props.box_velocity[2] = vel[2]
		self.props.box_velocity[3] = vel[3]
	end
end
local __temp_scvel_vec = {}
-- takes in a scalar to scale the entities velocity by
--  1.0 means no change
-- <1.0 decreases velocity over time
-- >1.0 increases velocity over time
function Hitbox:scaleVelocity(scale, dt)
	local diff = scale - 1.00
	local vel = self:getVelocity()
	__temp_scvel_vec[1] = vel[1] * diff
	__temp_scvel_vec[2] = vel[2] * diff
	__temp_scvel_vec[3] = vel[3] * diff
	self:accelerate(__temp_scvel_vec, dt)
end

local __temp_lmtspd_vec = {}
function Hitbox:limitSpeed( max_speed )
	local vel = self:getVelocity()
	local spd = self:getSpeed()
	if spd <= max_speed then return end

	local scale = max_speed / spd;
	__temp_lmtspd_vec[1] = scale * vel[1]
	__temp_lmtspd_vec[2] = scale * vel[2]
	__temp_lmtspd_vec[3] = scale * vel[3]
	self:setVelocity( __temp_lmtspd_vec )
end

local __temp_acc_vec = {}
-- adds an acceleration vector to the entity, scaled by
-- a given delta time step
function Hitbox:accelerate(vec, dt)
	local vel = self:getVelocity()
	__temp_acc_vec[1] = vel[1] + vec[1] * dt
	__temp_acc_vec[2] = vel[2] + vec[2] * dt
	__temp_acc_vec[3] = vel[3] + vec[3] * dt
	self:setVelocity(__temp_acc_vec)
end

function Hitbox:setPosition(pos)
	local v = self.props.box_position
	if pos[1]~=v[1]or pos[2]~=v[2] or pos[3]~=v[3] then
		self.props.box_position[1] = pos[1]
		self.props.box_position[2] = pos[2]
		self.props.box_position[3] = pos[3]
		self:moved()
	end
end
function Hitbox:setRotation(rot)
	local r = self.props.box_rotation
	if rot[1]~=r[1] or rot[2]~=r[2] or rot[3]~=r[3] or rot[4] ~= r[4] then
		self.props.box_rotation[1] = rot[1]
		self.props.box_rotation[2] = rot[2]
		self.props.box_rotation[3] = rot[3]
		self.props.box_rotation[4] = rot[4]
		self:moved()
	end
end
function Hitbox:setScale(scale)
	local s = self.props.box_scale
	if scale[1]~=s[1] or scale[2]~=s[2] or scale[3]~=s[3] then
		self.props.box_scale[1] = scale[1]
		self.props.box_scale[2] = scale[2]
		self.props.box_scale[3] = scale[3]
		self:moved()
	end
end
function Hitbox:translatePosition(vec, dt)
	if self.props.box_static then return end
	if vec[1]==0 and vec[2]==0 and vec[3]==0 then return end
	assert(dt)

	local v = self.props.box_position
	local new_pos = {
		v[1]+vec[1]*dt,
		v[2]+vec[2]*dt,
		v[3]+vec[3]*dt
	}
	self:setPosition(new_pos)
end

function Hitbox:testBoundsAgainst(hitbox2)
end
