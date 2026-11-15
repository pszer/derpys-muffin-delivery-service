local cpml = require 'cpml'

require "gameinterface"

require 'capsule'
require 'intersect'
require 'grid'

local CONSTS = require 'consts'

Physics = {
	gravity = {0.0,3.0,0.0},
	epsilon = 0.00005,
	max_iters = 8,
}
Physics.__index = physics

function Physics:applyGravity(hitbox, dt)
	hitbox:accelerate(gravity, dt)	
end

function Physics:resolveHitbox(hitbox, dt, grid)
	hitbox:updateBounds()
	local min,max = hitbox:getBounds()

	if grid then
		local x,z,w,r = min[1], min[3], max[1]-min[1], max[3]-min[3]
		local tiles, tiles_count, mx,mz,Mx,Mz = grid:populateTilesInWorldBox(x,z,w,r)

		if mx then
			print(mx..","..mz.." "..Mx..","..Mz)
		end

		if hitbox:type() == "capsule" then
			self:resolveCollisionsCapsule(hitbox, dt, tiles, 1,tiles_count)
		else
			error("Not implemented")
		end
	end
end

local __temp_capsule = {}
local __temp_sweep   = {}
local __temp_u       = cpml.vec3.new()
local __temp_vec3_1  = cpml.vec3.new()
local __temp_vec3_2  = cpml.vec3.new()
local __temp_vec3_3  = cpml.vec3.new()
local __temp_vec3_vel = cpml.vec3.new()
local __temp_trans = {0,0,0}
--
-- info contains time,depth,normal,point
-- the triangles between min_i and max_i are tested
function Physics:resolveCollisionsCapsule(hitbox, dt, triangles, tri_min_i, tri_max_i)
	assert(hitbox:type() == 'capsule', "Physics:resolveCollisionsCapsule() got non-capsule hitbox")

	local boxprops = hitbox.props
	local velocity = boxprops.box_velocity

	local tri_min_i = tri_min_i or 1
	local tri_max_i = tri_max_i or #triangles

	--local capsule = __temp_capsule
	--hitbox:__getTransformedCapsule(__temp_capsule)

	local u = __temp_u
	u.x,u.y,u.z = velocity[1]*dt, velocity[2]*dt, velocity[3]*dt

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
		sweep.normal = nil
		sweep.point  = nil
		sweep.winner = nil

		for tri_i=tri_min_i,tri_max_i do
			local triangle = triangles[tri_i]
			local t0 = triangle[1]
			local t1 = triangle[2]
			local t2 = triangle[3]
			Capsule:againstTriangle(sweep, boxprops.box_position, boxprops.box_capsule_height, boxprops.box_capsule_radius, velocity, t0,t1,t2)
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

		print("")
		print(sweep.time)
		print(sweep.depth)
		print(sweep.normal)
		print(sweep.point/TILE_SIZE)
		print(sweep.winner)

		-- avoiding cpml operators + results in fewer memory overhead
		u.x = u.x - dp.x
		u.y = u.y - dp.y
		u.z = u.z - dp.z

		local v = __temp_vec3_vel
		v.x = velocity[1]
		v.y = velocity[2]
		v.z = velocity[3]

		local dot_un = cpml.vec3.dot(u,sweep.normal)
		local dot_vn = cpml.vec3.dot(v,sweep.normal)

		-- cancel motion parallel to the normal vector, such that the capsule
		-- slides across the surface
		u.x = u.x + dot_un * sweep.normal.x
		u.y = u.y + dot_un * sweep.normal.y
		u.z = u.z + dot_un * sweep.normal.z
		hitbox:setVelocity(velocity[1] + dot_vn * sweep.normal.x,
		                   velocity[2] + dot_vn * sweep.normal.y,
											 velocity[3] + dot_vn * sweep.normal.z)
		--velocity[1] = velocity[1] + dot_vn * sweep.normal.x
		--velocity[2] = velocity[2] + dot_vn * sweep.normal.y
		--velocity[3] = velocity[3] + dot_vn * sweep.normal.z

		-- avoid another collision by nudging an epsilon amount
		local offset = __temp_vec3_3
		offset.x = Physics.epsilon * sweep.normal.x
		offset.y = Physics.epsilon * sweep.normal.y
		offset.z = Physics.epsilon * sweep.normal.z

		translateCapsule(offset)
		velocity[1] = velocity[1] + offset.x
		velocity[2] = velocity[2] + offset.y
		velocity[3] = velocity[3] + offset.z
		u.x = u.x + offset.x
		u.y = u.y + offset.y
		u.z = u.z + offset.z
	end
end
