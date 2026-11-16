local cpml = require 'cpml'

require "gameinterface"

require 'capsule'
require 'intersect'
require 'grid'
require 'physicsmaterial'

local CONSTS = require 'consts'

Physics = {
	gravity = {0.0,600.0,0.0},
	epsilon = 0.000005,
	grid_slack = TILE_SIZE/24,
	max_iters = 16,
	default_friction = 0.8,

	__lookup_step=math.rad(1),
	__cos_lookup = {}
}
Physics.__index = Physics

-- updates the world
--
-- dt    -- last frames deltatime.
-- ents  -- table of ents.
-- props -- physics props.
-- boxes -- table of hitboxes not tied to an entity nor prop.
-- grid  -- map grid (grid.lua).
--
function Physics:update(dt, ents, props, boxes, grid)
	assert(dt, "Physics:update(): expected dt")
	assert(grid, "Physics:update(): expected map mesh")

	-- Resolve collisions of ents and props against map mesh.
	for i,ent in ipairs(ents or {}) do
		if not ent:isStatic() then
			self:resolveHitbox(ent:getHitbox(), dt, grid)
		end
	end
	--[[for i,prop in ipairs(props or {}) do
		if not prop:isStatic() then
			Physics:applyGravity(prop:getHitbox(), dt)
		end
	end--]]
	
	-- Apply gravity to ents and props (not boxes table).
	for i,ent in ipairs(ents or {}) do
		if not ent:isStatic() then
			Physics:applyGravity(ent:getHitbox(), dt)
		end
	end
	--[[for i,prop in ipairs(props or {}) do
		if not prop:isStatic() then
			Physics:applyGravity(prop:getHitbox(), dt)
		end
	end--]]
	-- Gravity end

end

-- populate cos_lookup
Physics.__cos_lookup[0] = math.cos(0)
for theta = Physics.__lookup_step, math.pi*2, Physics.__lookup_step do
	local i = math.floor(theta / Physics.__lookup_step)
	Physics.__cos_lookup[i]  = math.cos(theta)
	Physics.__cos_lookup[-i] = math.cos(theta)
end
function Physics:lookupCos(theta)
	if theta > math.pi*2 or theta < math.pi*2 then
		theta = math.fmod(theta, math.pi*2)
	end
	local result = Physics.__cos_lookup[math.floor(theta/Physics.__lookup_step)]
	assert(result, theta.." "..math.floor(theta/Physics.__lookup_step))
	return result
end

local __temp_g_n = {0,0,0}
function Physics:applyGravity(hitbox, dt)
	local props = hitbox.props
	local rules = props.box_apply_movement_rules

	local grav = self.gravity

	-- different rules for gravity are applied to movement depending on the angle
	-- of the slope the hitbox is standing on
	if not rules then
		hitbox:accelerate(grav, dt)	
	else
		if props.box_grounded then
			local n = props.box_ground_normal
			-- keep component of gravity parallel to the ground's normal
			-- that the hitbox is standing on, which keeps it from sliding off
			-- with friction and nothing more
			local G = __temp_g_n
			local gn = grav[1]*n[1] + grav[2]*n[2] + grav[3]*n[3] -- dot product
			G[1] = gn * n[1]
			G[2] = gn * n[2]
			G[3] = gn * n[3]
			hitbox:accelerate(G, dt)
		else
			hitbox:accelerate(grav, dt)	
		end
	end

	hitbox:accelerate(grav, dt)	
end

function Physics:resolveHitbox(hitbox, dt, grid)
	local min,max = hitbox:getBounds()
	local velocity = hitbox:getVelocity()
	if grid then
		local x,z,w,r = min[1], min[3], max[1]-min[1], max[3]-min[3]

		-- add slack for sliding across walls
		x=x-Physics.grid_slack
		z=z-Physics.grid_slack
		w=w+Physics.grid_slack*2
		r=r+Physics.grid_slack*2

		-- expand by velocity
		local vx,vz = velocity[1], velocity[3]
		if vx < 0 then
			x=x+vx
			w=w-vx
		else
			w=w+vx
		end
		if vz < 0 then
			z=z+vz
			r=r-vz
		else
			r=r+vz
		end

		local tiles, tiles_count, mx,mz,Mx,Mz = grid:populateTable_TilesInWorldBox(x,z,w,r)

		if hitbox:type() == "capsule" then
			self:resolveCollisionsCapsule(hitbox, dt, tiles, {}, 1,tiles_count)
		else
			error("Not implemented")
		end
	end
	hitbox:updateBounds()
end

local __temp_capsule = {}
local __temp_sweep   = {}
local __temp_u       = cpml.vec3.new()
local __temp_vec3_1  = cpml.vec3.new()
local __temp_vec3_2  = cpml.vec3.new()
local __temp_vec3_3  = cpml.vec3.new()
local __temp_vec3_vel = cpml.vec3.new()
local __temp_trans = {0,0,0}

local __sweep_point = cpml.vec3.new()
local __sweep_normal = cpml.vec3.new()

--
-- info contains time,depth,normal,point
-- the triangles between min_i and max_i are tested
-- if material is nil, default physics material values are used
local default_material = PhysMaterial:new()
function Physics:resolveCollisionsCapsule(hitbox, dt, triangles, materials, tri_min_i, tri_max_i)
	assert(hitbox:type() == 'capsule', "Physics:resolveCollisionsCapsule() got non-capsule hitbox")
	local boxprops = hitbox.props
	local velocity = boxprops.box_velocity
	local materials = materials or {}

	local box_material = hitbox.props.box_material

	local tri_min_i = tri_min_i or 1
	local tri_max_i = tri_max_i or #triangles

	local u = __temp_u
	u.x,u.y,u.z = velocity[1]*dt, velocity[2]*dt, velocity[3]*dt

	hitbox:resetFlags() -- resets flags like box_grounded

	local function translateCapsule(vec)
		__temp_trans[1]=vec.x
		__temp_trans[2]=vec.y
		__temp_trans[3]=vec.z
		hitbox:translatePosition(__temp_trans, 1.0)
	end

	local hit = false
	-- capped number of iterations
	local max_iters = self.max_iters
	for iter=1,max_iters do

		local sweep = __temp_sweep
		sweep.time   = 1.0
		sweep.depth  = nil
		sweep.normal = __sweep_normal
		sweep.point  = __sweep_point
		sweep.winner   = __sweep_normal
		sweep.material = default_material

		sweep.setPoint = function(v)
			sweep.point.x=v.x
			sweep.point.y=v.y
			sweep.point.z=v.z
		end
		sweep.setNormal = function(v)
			sweep.normal.x=v.x
			sweep.normal.y=v.y
			sweep.normal.z=v.z
		end

		for tri_i=tri_min_i,tri_max_i do
			local triangle = triangles[tri_i]
			local t0 = triangle[1]
			local t1 = triangle[2]
			local t2 = triangle[3]
			if Capsule:againstTriangle(sweep, boxprops.box_position, boxprops.box_capsule_height, boxprops.box_capsule_radius, u, t0,t1,t2) then
				sweep.material = materials[tri_i] or default_material -- use triangle material, or default material
			end
		end

		-- resolve intersection
		if sweep.depth and sweep.depth > 0.0 then
			local intersection = __temp_vec3_1
			intersection.x = (sweep.depth+Physics.epsilon) * sweep.normal.x
			intersection.y = (sweep.depth+Physics.epsilon) * sweep.normal.y
			intersection.z = (sweep.depth+Physics.epsilon) * sweep.normal.z
			translateCapsule(intersection)
		end

		-- advance cylinder until first contact time
		local dp = __temp_vec3_2
		dp.x=u.x * sweep.time
		dp.y=u.y * sweep.time
		dp.z=u.z * sweep.time
		translateCapsule(dp)

		-- no collisions, can end iteration
		if sweep.time >= 1.0 then
			break
		end

		hit = true

		-- avoiding cpml operators + results in fewer memory overhead
		u.x = u.x - dp.x
		u.y = u.y - dp.y
		u.z = u.z - dp.z

		local v = __temp_vec3_vel
		v.x = velocity[1]
		v.y = velocity[2]
		v.z = velocity[3]

		local n = sweep.normal
		local dot_un = cpml.vec3.dot(u, n)
		local dot_vn = cpml.vec3.dot(v, n)

		-- determine if the normal is a ground/ceiling/wall plane for
		-- player movement rules
		self:determineGroundedState(hitbox, n) 

		if dot_un < 0.0 then
			u.x = u.x - dot_un * n.x
			u.y = u.y - dot_un * n.y
			u.z = u.z - dot_un * n.z
		end

		if dot_vn < 0.0 then
			-- remove velocity component going into surface
			v.x = v.x - dot_vn * n.x
			v.y = v.y - dot_vn * n.y
			v.z = v.z - dot_vn * n.z

			-- coulomb friction
			--
			-- we use the minimum friction
			local boxf = box_material.props.mat_friction
			local matf = sweep.material.props.mat_friction
			local mu = math.min(boxf,matf)
			--
			local vt = math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
			if mu > 0 and vt > 0 then
				local scale = math.max(0.0, vt - mu * -dot_vn) / vt
				v.x = v.x*scale
				v.y = v.y*scale
				v.z = v.z*scale

				u.x = u.x*scale
				u.y = u.y*scale
				u.z = u.z*scale
			end
		end

		-- cancel motion parallel to the normal vector, such that the capsule
		-- slides across the surface
		--[[u.x = u.x - dot_un * sweep.normal.x
		u.y = u.y - dot_un * sweep.normal.y
		u.z = u.z - dot_un * sweep.normal.z
		hitbox:setVelocity(velocity[1] - dot_vn * sweep.normal.x,
		                   velocity[2] - dot_vn * sweep.normal.y,
											 velocity[3] - dot_vn * sweep.normal.z)--]]
		hitbox:setVelocity(v.x,v.y,v.z)

		-- avoid another collision by nudging an epsilon amount
		local offset = __temp_vec3_3
		offset.x = Physics.epsilon * sweep.normal.x
		offset.y = Physics.epsilon * sweep.normal.y
		offset.z = Physics.epsilon * sweep.normal.z

		translateCapsule(offset)
	end
end

-- this function checks if the plane a hitbox is contacting is a
-- ground/ceiling/wall plane based on the normal, then the appropiate
-- details are filled out. (e.g. box_grounded, box_ground_normal)
function Physics:determineGroundedState(hitbox, normal)
	local props = hitbox.props
	if not props.box_apply_movement_rules then -- skip
		return
	end

	local ground_a  = props.box_ground_angle
	local ceiling_a = props.box_ceiling_angle
	local wall_a    = props.box_wall_angle

	ground_a  = Physics:lookupCos(math.rad(ground_a))
	ceiling_a = Physics:lookupCos(math.rad(ceiling_a))
	wall_a   = Physics:lookupCos(math.rad(wall_a))
	--wall_a2   = Physics.lookupCos(math.rad(ground_a))
	if -normal.y >= ground_a then
		props.box_grounded = true
		props.box_ground_normal[1] = normal.x
		props.box_ground_normal[2] = normal.y
		props.box_ground_normal[3] = normal.z
		return true
	end
	if normal.y >= ceiling_a then
		props.box_ceiling = true
		props.box_ceiling_normal[1] = normal.x
		props.box_ceiling_normal[2] = normal.y
		props.box_ceiling_normal[3] = normal.z
	end
	if math.abs(normal.y) <= wall_a then
		props.box_wall = true
		props.box_wall_normal[1] = normal.x
		props.box_wall_normal[2] = normal.y
		props.box_wall_normal[3] = normal.z
	end
end
