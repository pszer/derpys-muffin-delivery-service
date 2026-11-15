local cpml = require 'cpml'

Capsule = {}

require 'intersect'

-- capsule is pos,height,radius

--
-- to avoid creating vec3 objects that need to be garbage collected for later,
-- most calculations use pre-allocated objects
--
local __tempc_a = cpml.vec3.new()
local __tempc_b = cpml.vec3.new()
local __t0,__t1,__t2 =
{cpml.vec3.new(),cpml.vec3.new(),cpml.vec3.new()},
{cpml.vec3.new(),cpml.vec3.new(),cpml.vec3.new()},
{cpml.vec3.new(),cpml.vec3.new(),cpml.vec3.new()}

local __t0 = cpml.vec3.new()
local __t1 = cpml.vec3.new()
local __t2 = cpml.vec3.new()

--local __t0 = {cpml.vec3.new(),cpml.vec3.new(),cpml.vec3.new()}
--local __t1 = {cpml.vec3.new(),cpml.vec3.new(),cpml.vec3.new()}
--local __t2 = {cpml.vec3.new(),cpml.vec3.new(),cpml.vec3.new()}

local __t01 = cpml.vec3.new()
local __t02 = cpml.vec3.new()

local __b0 = cpml.vec3.new()
local __b1 = cpml.vec3.new()
local __b2 = cpml.vec3.new()

local __triangles = {{},{}}--2
local __parallelograms = {{},{},{}}--3
local __cylinders = {{},{},{},{},{},{},{},{},{}}--9
local __spheres = {{},{},{},{},{},{}}--6
local __triangle_normals = {cpml.vec3.new(),cpml.vec3.new()}
local __parallelograms_normals = {cpml.vec3.new(),cpml.vec3.new(),cpml.vec3.new()}

local __temp_t0c0 = cpml.vec3.new()
local __temp_t1c0 = cpml.vec3.new()

local __temp_p01 = cpml.vec3.new()
local __temp_p02 = cpml.vec3.new()
local __temp_n_parallelogram = cpml.vec3.new()
local __temp_p0c0 = cpml.vec3.new()
local __temp_c0d0n = cpml.vec3.new()

local __temp_cross_t01_t02 = cpml.vec3.new()
local __temp_cross_p01_p02 = cpml.vec3.new()

local __temp_velocity = cpml.vec3.new()

local __temp_c01 = cpml.vec3.new()
local __temp_normal2 = cpml.vec3.new()
local __temp_normal3 = cpml.vec3.new()

-- returns true/false, and writes collision info in the out argument
-- {
--   time   = number
--   depth  = number
--   normal = vec3
--   point  = vec3
-- }
function Capsule:againstTriangle(out, pos,height,radius, vel, _t0,_t1,_t2)
	
	local dot   = cpml.vec3.dot
	local cross = cpml.vec3.cross
	local normalize = cpml.vec3.normalize
	local abs   = math.abs

	local velocity = __temp_velocity
	velocity.x = vel[1]
	velocity.y = vel[2]
	velocity.z = vel[3]

	-- place arguments into the pre-allocated cpml vec3s,
	local c0 = __tempc_a
	c0.x,c0.y,c0.z = pos[1],pos[2]-radius,pos[3]
	--
	local c1 = __tempc_b
	c1.x,c1.y,c1.z = pos[1],pos[2]-height+radius,pos[3]
	--
	local t0,t1,t2 = __t0,__t1,__t2
	--for i=1,3 do t0[i].x, t0[i].y, t0[i].z = _t0[i][1],_t0[i][2],_t0[i][3] end
	--for i=1,3 do t1[i].x, t1[i].y, t1[i].z = _t1[i][1],_t1[i][2],_t1[i][3] end
	--for i=1,3 do t2[i].x, t2[i].y, t2[i].z = _t2[i][1],_t2[i][2],_t2[i][3] end
	t0.x, t0.y, t0.z = _t0[1], _t0[2], _t0[3]
	t1.x, t1.y, t1.z = _t1[1], _t1[2], _t1[3]
	t2.x, t2.y, t2.z = _t2[1], _t2[2], _t2[3]

	-- triangle plane
	local t01 = __t01 -- use pre-allocated
	local t02 = __t02
	t01.x = t1.x - t0.x
	t01.y = t1.y - t0.y
	t01.z = t1.z - t0.z
	t02.x = t2.x - t0.x
	t02.y = t2.y - t0.y
	t02.z = t2.z - t0.z

	Intersect.__cross(__temp_cross_t01_t02, t01, t02) -- use pre-allocated
	local normal = __temp_cross_t01_t02
	--local normal = normalize(cross(t01,t02))
	local normal_length = normal:len()
	if normal_length > 0 then
		normal.x = normal.x / normal_length
		normal.y = normal.y / normal_length
		normal.z = normal.z / normal_length
	end

	-- triangle is extruded along the capsule direction c01
	--local c01 = c1 - c0
	local c01 = __temp_c01
	c01.x = c1.x-c0.x
	c01.y = c1.y-c0.y
	c01.z = c1.z-c0.z
	-- 
	local a0 = t0
	local a1 = t1
	local a2 = t2
	local b0,b1,b2 = __b0,__b1,__b2 -- use pre-allocated
	b0.x = t0.x + c01.x 
	b0.y = t0.y + c01.y 
	b0.z = t0.z + c01.z 
	--
	b1.x = t1.x + c01.x 
	b1.y = t1.y + c01.y 
	b1.z = t1.z + c01.z 
	--
	b2.x = t2.x + c01.x 
	b2.y = t2.y + c01.y 
	b2.z = t2.z + c01.z 

	-- test point against extruted triangular prism
	if Intersect.pointInTriangularPrism(c0, a0,a1,a2, b0,b1,b2) then

		local t0c0 = __temp_t0c0
		local t1c0 = __temp_t1c0

		t0c0.x = c0.x - t0.x
		t0c0.y = c0.y - t0.y
		t0c0.z = c0.z - t0.z

		t1c0.x = c0.x - t1.x
		t1c0.y = c0.y - t1.y
		t1c0.z = c0.z - t1.z


		local d0 = dot(normal, t0c0)	
		local d1 = dot(normal, t1c0)
		local d
		if abs(d0) <= abs(d1) then
			d=d0
		else
			d=d1
		end

		--local n = normal
		local n = __temp_normal2
		n.x = normal.x
		n.y = normal.y
		n.z = normal.z
		if d<0 then -- orient normal
			n.x = -n.x
			n.y = -n.y
			n.z = -n.z
		end

		out.time   = 0
		out.depth  = abs(d) + radius
		out.normal = n:clone()

		--out.point  = c0 + d0*normal
		if not out.point then
			out.point = cpml.vec3.new()
		end
		out.point.x = c0.x + d0*normal.x
		out.point.y = c0.y + d0*normal.y
		out.point.z = c0.z + d0*normal.z

		return true
	end

	local hit = false
	-- By the Minowski difference, sweeping a capsule against a triangle can be turned into a test that decomposes
	-- into testing against: 2 sphere->triangle + 3 sphere->parallelogram + 9 point->cylinder + 6 point->sphere tests

	-- re-use tables to avoid creating garbage
	local triangles, parallelograms, cylinders, spheres = __triangles,__parallelograms,__cylinders,__spheres
	local triangle_normals = __triangle_normals
	-- Two triangles
	triangles[1][1], triangles[1][2], triangles[1][3] = a0,a1,a2
	triangles[2][1], triangles[2][2], triangles[2][3] = b0,b1,b2
	-- Three parallelograms
	local parallelogram_normals = __parallelograms_normals
	parallelograms[1][1], parallelograms[1][2], parallelograms[1][3] = a0,a1,b0
	parallelograms[2][1], parallelograms[2][2], parallelograms[2][3] = a1,a2,b1
	parallelograms[3][1], parallelograms[3][2], parallelograms[3][3] = a2,a0,b2
	-- Nine cylinders
	cylinders[1][1], cylinders[1][2] = a0,a1
	cylinders[2][1], cylinders[2][2] = a1,a2
	cylinders[3][1], cylinders[3][2] = a2,a0
	cylinders[4][1], cylinders[4][2] = b0,b1
	cylinders[5][1], cylinders[5][2] = b1,b2
	cylinders[6][1], cylinders[6][2] = b2,b0
	cylinders[7][1], cylinders[7][2] = a0,b0
	cylinders[8][1], cylinders[8][2] = a1,b1
	cylinders[9][1], cylinders[9][2] = a2,b2
	-- Six spheres
	spheres[1], spheres[2], spheres[3], spheres[4], spheres[5], spheres[6] = a0,a1,a2,b0,b1,b2

	-- Sphere triangle sweep tests
	--
	for i=1,2 do
		local p0,p1,p2 = triangles[i][1], triangles[i][2], triangles[i][3]

		-- Triangle plane normal
		--local n = normal
		local n = __temp_normal3
		n.x = normal.x
		n.y = normal.y
		n.z = normal.z
		if dot(n, c0-p0) < 0.0 then
			n.x = -n.x
			n.y = -n.y
			n.z = -n.z
		end
		triangle_normals[i].x = n.x
		triangle_normals[i].y = n.y
		triangle_normals[i].z = n.z

		hit = hit or Intersect.sweepSphereTrianglePlane(out, c0, radius, velocity, p0,p1,p2, n)
	end

	-- Sphere sweep parallelogram tests
	for i=1,3 do
		local p0,p1,p2 = parallelograms[i][1], parallelograms[i][2], parallelograms[i][3]

		-- test if the quad is degenerate, we skip testing in these cases
		local p01, p02 = __temp_p01, __temp_p02
		p01.x = p1.x-p0.x
		p01.y = p1.y-p0.y
		p01.z = p1.z-p0.z
		p02.x = p2.x-p0.x
		p02.y = p2.y-p0.y
		p02.z = p2.z-p0.z

		--local c = cross(p01, p02)
		Intersect.__cross(__temp_cross_p01_p02, p01, p02) -- use pre-allocated
		local c = __temp_cross_p01_p02
		local len = c:len()

		if len <= Physics.epsilon then -- degenerate case
			parallelogram_normals[i].x = triangle_normals[1].x
			parallelogram_normals[i].y = triangle_normals[1].y
			parallelogram_normals[i].z = triangle_normals[1].z
		else
			-- otherwise, test as normal
			local n = __temp_n_parallelogram -- use pre-allocated
			n.x = c.x / len
			n.y = c.y / len
			n.z = c.z / len

			local p0c0 = __temp_p0c0
			p0c0.x = c0.x - p0.x
			p0c0.y = c0.y - p0.y
			p0c0.z = c0.z - p0.z
			if dot(n, p0c0) < 0 then -- orient normal
				n.x=-n.x
				n.y=-n.y
				n.z=-n.z
			end
			parallelogram_normals[i].x = n.x
			parallelogram_normals[i].y = n.y
			parallelogram_normals[i].z = n.z

			hit = hit or Intersect.sweepSphereParallelogramPlane(out, c0, radius, velocity, p0,p1,p2, n)
		end
	end

	-- Do point-cylinder sweep tests
	for i=1,9 do
		local p0 = cylinders[i][1]
		local p1 = cylinders[i][2]
		local n
		-- fallback normals (already calculated)
		if i<= 6 then
			n = triangle_normals[ math.floor((i-1)/3) + 1]
		else
			n = parallelogram_normals[ i-6 ]
		end
		assert(n)
	
		hit = hit or Intersect.sweepPointUncappedCylinder(out, c0, velocity, p0,p1,radius, n)
	end

	-- Do point-sphere sweep tests
	for i=1,6 do
		local c = spheres[i]
		local n = triangle_normals[ math.floor((i-1)/3) + 1]
		assert(n)
		hit = hit or Intersect.sweepPointSphere(out, c0, velocity, c, radius, n)
	end

	return hit
end
