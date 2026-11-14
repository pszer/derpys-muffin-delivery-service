local cpml = require 'cpml'

local Capsule = {}

local intersect = require 'intersect'

-- {a={x,y,z},b={x,y,z},radius=r}

local __tempc_a = cpml.vec3.new()
local __tempc_b = cpml.vec3.new()
local t1,t2,t3 =
{cpml.vec3.new(),cpml.vec3.new(),cpml.vec3.new()},
{cpml.vec3.new(),cpml.vec3.new(),cpml.vec3.new()},
{cpml.vec3.new(),cpml.vec3.new(),cpml.vec3.new()}

function Capsule:againstTriangle(cap, _t1,_t2,_t3)
	local c0 = __tempc_a
	cap_a.x,cap_a.y,cap_a_z = cap.a[1],cap.a[2],cap.a[3]   
	local c1 = __tempc_b
	cap_b.x,cap_b.y,cap_b_z = cap.b[1],cap.b[2],cap.b[3]

	local c01 = c1 - c0

	for i=1,3 do
		t1[i].x, t1[i].y, t1[i].z = _t1[i][1],_t1[i][2],_t1[i][3] end
	for i=1,3 do
		t2[i].x, t2[i].y, t2[i].z = _t2[i][1],_t2[i][2],_t2[i][3] end
	for i=1,3 do
		t3[i].x, t3[i].y, t3[i].z = _t3[i][1],_t3[i][2],_t3[i][3] end

	-- test point against extruted triangular prism
	if intersect.pointInTriangularPrism() then
	end
end

return Capsule
