local cpml = require 'cpml'

require 'shadersend'

Debug_3d = {
	capsule_hemisphere = nil, -- mesh
	capsule_cylinder   = nil, -- mesh
	capsule_texture    = nil, -- mesh
}

function Debug_3d:createDebugLineVerts(pos, dir)
	local perp = cpml.vec3.perpendicular(dir)
	perp = perp:normalize()

	local circ_points = {}

	for i = 0,math.pi*2,math.pi/4 do
		table.insert(circ_points, cpml.vec3.rotate(perp, i, dir))
	end

	local vert_count = 0
	local verts      = {}
	local vert_map   = {}

	for i=1,#circ_points do
		local j=i+1
		if j==#circ_points+1 then j=1 end -- wrap around

		local A = circ_points[i]
		local B = circ_points[j]

		local v1,v2,v3,v4 =
			pos + A,
			pos + A + dir,
			pos + B,
			pos + B + dir

		table.insert(verts, {v1.x,v1.y,v1.z})
		table.insert(verts, {v2.x,v2.y,v2.z})
		table.insert(verts, {v3.x,v3.y,v3.z})
		table.insert(verts, {v4.x,v4.y,v4.z})

		table.insert(vert_map, vert_count + 1)
		table.insert(vert_map, vert_count + 2)
		table.insert(vert_map, vert_count + 3)
		table.insert(vert_map, vert_count + 3)
		table.insert(vert_map, vert_count + 4)
		table.insert(vert_map, vert_count + 2)

		vert_count = vert_count+4

	end

	return verts, vert_map
end

function Debug_3d:combineVerts(v1,v_map1, v2,v_map2)
	local count = #v1
	for i=1,#v2 do
		table.insert(v1, v2[i])
	end
	for i=1,#v_map2 do
		table.insert(v_map1, v_map2[i] + count)
	end
end

function Debug_3d:initCapsuleMesh()
	local texture = love.graphics.newCanvas(64,64)
	love.graphics.setCanvas(texture)
	love.graphics.clear(0,1,0,1)
	love.graphics.setCanvas()
	self.capsule_texture = texture

	local segment_step = 1 / 5
	local step         = math.pi/12

	local vert_rings = {}

	local count=1
	for i = 1 - segment_step, 0, -segment_step do

		vert_rings[count] = {}

		local cos1,sin1 = math.cos(i*math.pi/2),math.sin(i*math.pi/2)
		
		for j = 0, math.pi-step, step do
			local pos = {math.cos(j),sin1,math.sin(j)}
			table.insert(vert_rings[count], pos)
		end

		count=count+1
	end

	local Verts, Vert_Map = {},{}

	local cylinder_Verts, cylinder_Vert_Map = {}, {}

	-- hemisphere
	for i = 1,#vert_rings-1 do
		for j = 1,#vert_rings[i]-1 do
			local v,v_map = self:createDebugLineVerts(
					cpml.vec3.new(vert_rings[i][j]),cpml.vec3.new(vert_rings[i][j+1]) - cpml.vec3.new(vert_rings[i][j])
				)
			self:combineVerts(Verts, Vert_Map, v,v_map)
			v,v_map = self:createDebugLineVerts(
					cpml.vec3.new(vert_rings[i][j]),cpml.vec3.new(vert_rings[i+1][j+1]) - cpml.vec3.new(vert_rings[i][j])
				)
			self:combineVerts(Verts, Vert_Map, v,v_map)
			v,v_map = self:createDebugLineVerts(
					cpml.vec3.new(vert_rings[i][j+1]),cpml.vec3.new(vert_rings[i+1][j+1]) - cpml.vec3.new(vert_rings[i][j+1])
				)
			self:combineVerts(Verts, Vert_Map, v,v_map)
		end
	end

	-- cylinder
	for i = #vert_rings,#vert_rings do
		for j = 1,#vert_rings[i]-1 do
			local v,v_map = self:createDebugLineVerts(
					cpml.vec3.new(vert_rings[i][j]),cpml.vec3.new(vert_rings[i][j+1]) - cpml.vec3.new(vert_rings[i][j])
				)
			self:combineVerts(cylinder_Verts, cylinder_Vert_Map, v,v_map)
			v,v_map = self:createDebugLineVerts(
					cpml.vec3.new(vert_rings[i][j]),cpml.vec3.new(vert_rings[i][j]) + cpml.vec3.new(0,1,0)
				)
			self:combineVerts(cylinder_Verts, cylinder_Vert_Map, v,v_map)
			v,v_map = self:createDebugLineVerts(
					cpml.vec3.new(vert_rings[i][j+1]),cpml.vec3.new(vert_rings[i][j+1]) + cpml.vec3.new(0,1,0)
				)
			self:combineVerts(cylinder_Verts, cylinder_Vert_Map, v,v_map)
		end
	end

	local mesh_format = {
	  {"VertexPosition", "float", 3},
	  {"VertexTexCoord", "float", 2},
	  {"VertexNormal"  , "float", 3},
	}
	local Mesh = love.graphics.newMesh(mesh_format, Verts, 'triangles', 'static')
	Mesh:setVertexMap(Vert_Map)
	Mesh:setTexture(self.capsule_texture)
	local CylinderMesh = love.graphics.newMesh(mesh_format, cylinder_Verts, 'triangles', 'static')
	CylinderMesh:setVertexMap(cylinder_Vert_Map)
	CylinderMesh:setTexture(self.capsule_texture)

	self.capsule_hemisphere = Mesh
	self.capsule_cylinder   = CylinderMesh
end

local id = {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
function Debug_3d:generateModelMats(hitbox)
	if hitbox:type() == "capsule" then
		local mat = hitbox:modelMatrix()

		local d_ba = {}
		for i=1,3 do
			d_ba[i] = hitbox.props.box_capsule.b[i] - hitbox.props.box_capsule.a[i]
		end

		local radius = cpml.mat4.new()
		for i=1,16 do radius[i]=id[i] end
		radius:scale(radius, cpml.vec3.new(hitbox.props.box_capsule.radius,hitbox.props.box_capsule.radius,hitbox.props.box_capsule.radius))

		local to_a_mat = cpml.mat4.new()
		for i=1,16 do to_a_mat[i]=id[i] end
		to_a_mat:translate(to_a_mat, cpml.vec3.new(hitbox.props.box_capsule.a))

		local to_b_mat = cpml.mat4.new()
		for i=1,16 do to_a_mat[i]=id[i] end
		to_a_mat:translate(to_a_mat, cpml.vec3.new(hitbox.props.box_capsule.b))

		local point_mat = cpml.mat4.new()
		cpml.mat4.look_at(point_mat, cpml.vec3.new(00.01,0,0), cpml.vec3.new(d_ba), cpml.vec3(0,-1,0))
		local point_away_mat = cpml.mat4.new()
		cpml.mat4.look_at(point_mat, cpml.vec3.new(00.01,0,0), -cpml.vec3.new(d_ba), cpml.vec3(0,-1,0))

		local scale_cylinder = cpml.mat4.new()
		for i=1,16 do scale_cylinder[i]=id[i] end
		cpml.mat4.scale(scale_cylinder, scale_cylinder, cpml.vec3.new(1, cpml.vec3.new(d_ba):len() / hitbox.props.box_capsule.radius, 1))

		local mat_b = cpml.mat4.new()
		cpml.mat4.mul(mat_b, radius, mat_b)
		cpml.mat4.mul(mat_b, point_mat, mat_b)

		local mat_a = cpml.mat4.new()
		cpml.mat4.mul(mat_a, point_away_mat, radius)
		cpml.mat4.mul(mat_a, to_a_mat, mat_a)

		local mat_c = cpml.mat4.new()
		cpml.mat4.mul(mat_c, radius, mat_c)
		cpml.mat4.mul(mat_c, scale_cylinder, mat_c)
		cpml.mat4.mul(mat_c, to_a_mat, mat_c)

		cpml.mat4.mul(mat_a, mat, mat_a)
		cpml.mat4.mul(mat_b, mat, mat_b)
		cpml.mat4.mul(mat_c, mat, mat_c)

		return {mat_a, mat_b, mat_c}, {self.capsule_hemisphere, self.capsule_hemisphere, self.capsule_cylinder}
	end
end
