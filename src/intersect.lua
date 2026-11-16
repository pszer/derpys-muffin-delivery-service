Intersect = {}
Intersect.__index = Intersect

local cpml = require 'cpml'

local dot   = cpml.vec3.dot
--local cross = cpml.vec3.cross
--local normalize = cpml.vec3.normalize
local abs   = math.abs

-- cross product of a and b stored in out
function Intersect.__cross(out, a,b)
	out.x = a.y*b.z - a.z*b.y
	out.y = a.z*b.x - a.x*b.z
	out.z = a.x*b.y - a.y*b.x
end

local __temp_t01 = cpml.vec3.new()
local __temp_t02 = cpml.vec3.new()
local __temp_t0p = cpml.vec3.new()
-- return whether point P is contained inside 3D region delimited by triangle t0,t1,t2 edges.
function Intersect.pointInsideTriangle(p, t0, t1, t2)
	-- Real-Time Collision Detection: 3.4: Barycentric Coordinates (pages 46-52).
	--
	-- The book also has a subsection dedicated to point inside triangle tests:
	-- Real-Time Collision Detection: 5.4.2: Testing Point in Triangle (pages 203-206).
	-- But those tests only work for CCW triangles. This seems to work for either orientation.
	--

	-- avoid cpml operators to save overhead
	local t01,t02,t0p = __temp_t01,__temp_t02,__temp_t0p
	t01.x = t1.x - t0.x
	t01.y = t1.y - t0.y
	t01.z = t1.z - t0.z
	t02.x = t2.x - t0.x
	t02.y = t2.y - t0.y
	t02.z = t2.z - t0.z
	t0p.x = p.x - t0.x
	t0p.y = p.y - t0.y
	t0p.z = p.z - t0.z

	local t01t01 = dot(t01,t01);
	local t01t02 = dot(t01,t02);
	local t02t02 = dot(t02,t02);
	local t0pt01 = dot(t0p,t01);
	local t0pt02 = dot(t0p,t02);
	local denom = t01t01*t02t02 - t01t02*t01t02;

	if denom <= Physics.epsilon then return false end

	-- Normally I would have to divide vd,wd by denom to get v,w. But divisions are
	-- expensive and cause troubles around 0. If denom isn't negative then we don't
	-- ever need to divide. If in the future it does turn out denom can be negative
	-- then we can always multiply by denom instead of dividing to keep sign the same.
	local vd = t02t02*t0pt01 - t01t02*t0pt02
	local wd = t01t01*t0pt02 - t01t02*t0pt01
	return vd >= 0 and wd >= 0 and vd + wd <= denom
end

local __temp_p3 = cpml.vec3.new()
-- Return whether point P is contained inside 3D region delimited by parallelogram P0,P1,P2 edges.
function Intersect.pointInsideParallelogram(p, p0, p1, p2)
	local p3 = __temp_p3
	p3.x = p2.x + (p1.x - p0.x)
	p3.y = p2.y + (p1.y - p0.y)
	p3.z = p2.z + (p1.z - p0.z)
	return Intersect.pointInsideTriangle(p,p0,p1,p2) or Intersect.pointInsideTriangle(p,p1,p3,p2)
end

-- point: point
-- a,b, three vertices defining the triangle faces of the prism
local __faces = {{},{},{},{},{}}
local __temp_norm = cpml.vec3.new()
local __temp_p01_2 = cpml.vec3.new()
local __temp_p02_2 = cpml.vec3.new()
function Intersect.pointInTriangularPrism(point, a0,a1,a2,b0,b1,b2)
	local faces = __faces

	--[[faces[1],faces[2],faces[3],faces[4],faces[5] =
	 {a0,a1,a2}
	,{b0,b2,b1}
	,{a0,b0,a1}
	,{a1,b1,a2}
	,{a2,b2,a0}--]]

	faces[1][1], faces[1][2], faces[1][3] = a0,a1,a2
	faces[2][1], faces[2][2], faces[2][3] = b0,b2,b1
	faces[3][1], faces[3][2], faces[3][3] = a0,b0,a1
	faces[4][1], faces[4][2], faces[4][3] = a1,b1,a2
	faces[5][1], faces[5][2], faces[5][3] = a2,b2,a0
	--faces[3][1], faces[3][2], faces[3][3] = a1,b0,a0
	--faces[4][1], faces[4][2], faces[4][3] = a2,b1,a1
	--faces[5][1], faces[5][2], faces[5][3] = a0,b2,a2

	local sign = nil
	-- if intersection happens, the sign for the dot product d will be
	-- the same for all five faces
	for i=1,5 do
		local p0,p1,p2 = faces[i][1],faces[i][2],faces[i][3]

		local p01 = __temp_p01_2
		local p02 = __temp_p02_2
		p01.x = p1.x-p0.x
		p01.y = p1.y-p0.y
		p01.z = p1.z-p0.z
		p02.x = p2.x-p0.x
		p02.y = p2.y-p0.y
		p02.z = p2.z-p0.z

		Intersect.__cross(__temp_norm, p01,p02) -- use pre-allocated
		local norm = __temp_norm

		local d = dot(norm, point - p0)

		if i==1 then sign = d end
		if sign*d <= 0 then return false end
	end
	return true
end

local __temp_t0c = cpml.vec3.new()
local __temp_col = cpml.vec3.new()
-- returns true and fills out sweep info if collision happens.
function Intersect.sweepSphereTrianglePlane(sweep, c, r, v, t0,t1,t2, n)
	-- Real-Time Collision Detection 5.5.3: Intersecting Moving Sphere Against Plane (pages 219-223).
	local t
	local t0c = __temp_t0c
	t0c.x = c.x - t0.x
	t0c.y = c.y - t0.y
	t0c.z = c.z - t0.z
	local d = dot(n,t0c)
	local pen = r - d

	if pen > 0 then
		t = 0 -- Sphere already starts colliding with triangle plane.
	else
		-- Sphere isn't immediately colliding with the plane. Check if it's moving away.
		local denom = dot(n,v)
		if denom >= 0 then
			return false -- Sphere is moving away from plane.
		end
		
		-- Sphere will collide with plane at some point.
		t = (r - d)/denom
		pen = 0
	end

	if t > sweep.time or (t == sweep.time and pen < sweep.depth)then
		return false
	end

	-- Is the plane collision point inside the triangle?
	-- Real-Time Collision Detection: 5.4.2: Testing Point in Triangle (pg 203-206).
	--local collision = c + t*v - r*n
	local collision = __temp_col
	collision.x = c.x + t*v.x - r*n.x
	collision.y = c.y + t*v.y - r*n.y
	collision.z = c.z + t*v.z - r*n.z
	
	if (not Intersect.pointInsideTriangle(collision,t0,t1,t2)) then
		return false end
		
	-- Plane collision point is inside the triangle. So the sphere collides with the triangle.
	sweep.time = t
	sweep.depth = pen
	--sweep.point = collision:clone()
	--sweep.normal = n:clone()
	sweep.setPoint(collision)
	sweep.setNormal(n)
	sweep.winner = "sweepSphereTrianglePlane"
	return true
end

local __temp_t0c2 = cpml.vec3.new()
local __temp_col2 = cpml.vec3.new()
function Intersect.sweepSphereParallelogramPlane(sweep, c, r, v, t0,t1,t2, n)
	-- Real-Time Collision Detection 5.5.3: Intersecting Moving Sphere Against Plane (pages 219-223).
	local t
	local t0c = __temp_t0c2
	t0c.x = c.x - t0.x
	t0c.y = c.y - t0.y
	t0c.z = c.z - t0.z
	local d = dot(n,t0c)
	local pen = r - d

	if pen > 0 then
		t = 0 -- Sphere already starts coliding with triangle plane.
	else
		-- Sphere isn't immediately colliding with the plane. Check if it's moving away.
		local denom = dot(n,v)
		if denom >= 0 then
			return false -- Sphere is moving away from plane.
		end
		
		-- Sphere will collide with plane at some point.
		t = (r - d)/denom
		pen = 0
	end

	if t > sweep.time or (t == sweep.time and pen < sweep.depth) then
		return false
	end

	-- Is the plane collision point inside the triangle?
	-- Real-Time Collision Detection: 5.4.2: Testing Point in Triangle (pg 203-206).
	local collision = __temp_col2
	collision.x = c.x + t*v.x - r*n.x
	collision.y = c.y + t*v.y - r*n.y
	collision.z = c.z + t*v.z - r*n.z
	if (not Intersect.pointInsideParallelogram(collision,t0,t1,t2)) then
		return false end
		
	-- Plane collision point is inside the triangle. So the sphere collides with the triangle.
	sweep.time = t
	sweep.depth = pen
	--sweep.point = collision:clone()
	--sweep.normal = n:clone()
	sweep.setPoint(collision)
	sweep.setNormal(n)
	sweep.winner = "sweepSphereParallelogramPlane"
	return true
end

local __temp_c0c1 = cpml.vec3.new()
local __temp_c0p = cpml.vec3.new()
local __temp_collision = cpml.vec3.new()
local __temp_center = cpml.vec3.new()
local __temp_c0collision = cpml.vec3.new()
local __temp_nvec = cpml.vec3.new()

local __temp_k = cpml.vec3.new()

-- Sweep point P with velocity V against cylinder C0,C1,r, ignoring the endcaps.
function Intersect.sweepPointUncappedCylinder(sweep, p, v, c0, c1, r, fallback_normal)
	local n,d = __temp_c0c1, __temp_c0p -- use pre-allocated
	n.x = c1.x - c0.x
	n.y = c1.y - c0.y
	n.z = c1.z - c0.z
	--
	d.x = p.x - c0.x
	d.y = p.y - c0.y
	d.z = p.z - c0.z

	-- test if swept point is fully outside either endcap
	local dn = dot(d,n)
	local vn = dot(v,n)
	local nn = dot(n,n)

	if nn < Physics.epsilon then return false end

	if dn < 0 and dn+vn < 0 then return false end  -- outside c0 end
	if dn > nn and dn+vn > nn then return false end -- outside c1 end

	-- setup quadratic equation
	local t
	local vv = dot(v,v)
	local dv = dot(d,v)
	local dd = dot(d,d)
	local a = nn*vv - vn*vn
	local c = nn*(dd - r*r) - dn*dn

	-- sweep direction parallel with cylinder
	if a < Physics.epsilon then
		if c > 0 then
			return false end -- outside cylinder
		if dn < 0 then
			return false end -- outside endcap c0
		if dn > nn then
			return false end -- outside endcap c1
		t = 0
	else
		-- solve first point of contact
		local b = nn*dv - vn*dn
		local discr = b*b - a*c
		if discr < 0 then return false end -- misses
		t = (-b - math.sqrt(discr))/a -- root
	end

	-- missed/sooner collision exists
	if t < 0 or t >= sweep.time then
		return false
	end

	local collision = __temp_collision -- use pre-allocated
	collision.x = p.x + t * v.x
	collision.y = p.y + t * v.y
	collision.z = p.z + t * v.z

	local k = dn + t*vn
	if k < 0 or k > nn then
		return false
	end

	local center = __temp_center -- use pre-allocated
	if nn < Physics.epsilon then
		center = c0
	else
		local c0col = __temp_c0collision -- use pre-allocated
		c0col.x = collision.x - c0.x
		c0col.y = collision.y - c0.y
		c0col.z = collision.z - c0.z
		center.x = c0.x + n.x * (dot(c0col,n)/nn)
		center.y = c0.y + n.y * (dot(c0col,n)/nn)
		center.z = c0.z + n.z * (dot(c0col,n)/nn)
	end

	local vec = __temp_nvec
	vec.x = collision.x - center.x
	vec.y = collision.y - center.y
	vec.z = collision.z - center.z

	local len = vec:len()
	local depth = r - len

	-- fill out details
	sweep.time = t
	sweep.depth = (t > 0 and 0) or depth
	--sweep.point = collision:clone()
	sweep.setPoint(collision)
	if len >= Physics.epsilon then
		vec.x = vec.x / len
		vec.y = vec.y / len
		vec.z = vec.z / len
		--sweep.normal = vec:clone()
		sweep.setNormal(vec)
	else
		--sweep.normal = fallback_normal:clone()
		sweep.setNormal(fallback_normal)
	end
	sweep.winner = "sweepPointUncappedCylinder"
	return true
end

local __temp_sp = cpml.vec3.new()
-- sweep point p with velocity v against sphere c,r
function Intersect.sweepPointSphere(sweep, p, v, s, r, fallback_normal)
	-- Real-Time Collision Detection 5.3.2: Intersecting Ray or Segment Against Sphere (pages 177-179)
	--
	-- setup quadratic equation
	local d = __temp_sp -- use pre-allocated
	d.x = p.x - s.x
	d.y = p.y - s.y
	d.z = p.z - s.z

	local b = dot(d,v)
	local c = dot(d,d) - r*r

	if c>0 and b>0 then -- point starts outside sphere and moves away
		return false end

	local t
	local a = dot(v,v)

	if a < Physics.epsilon then -- no motion
		if c > 0 then return false end
		t = 0
	else
		local discr = b*b - a*c
		if discr < 0 then
			return false -- point misses sphere
		end
		-- find time of contact
		t = (-b - math.sqrt(discr))/a
	end

	-- ignore if different collision is sooner
	if t >= sweep.time then
		return false end

	t = math.max(t,0)
	local collision = __temp_collision -- use pre-allocated
	collision.x = p.x + t * v.x
	collision.y = p.y + t * v.y
	collision.z = p.z + t * v.z

	local vec = __temp_nvec -- use pre-allocated
	vec.x = collision.x - s.x
	vec.y = collision.y - s.y
	vec.z = collision.z - s.z
	local len = vec:len()

	sweep.time = t
	sweep.depth = (t>0 and 0) or r - len

	--sweep.point = collision:clone()
	sweep.setPoint(collision)
	if len >= Physics.epsilon then
		vec.x = vec.x/len
		vec.y = vec.y/len
		vec.z = vec.z/len
		sweep.setNormal(vec)
		--sweep.normal = vec:clone()
	else
		sweep.setNormal(fallback_normal)
		--sweep.normal = fallback_normal:clone()
	end
	sweep.winner = "sweepPointSphere"
	return true
end
