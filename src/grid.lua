require 'consts'

Grid = {}
Grid.__index = Grid

--
--
--
--
-- Contains 2-grid indexed [z][x], which contains
--
-- {
--    -- triangles listed plainly as an array
--    tri1, tri2, tri3, tri4..., tri{n},
--
--    -- the same triangles organised by whether they're part of the floor/wall and it's side.
--    tile = {tri1,tri2}, walls={ [1] = {tri1,tri2}, [2] = {tri1,tri2}, [5] = {tri1,tri2} }
-- }
--
--
--
--
--
function Grid:gridFromMesh(map_mesh)
	local w,h = map_mesh.width, map_mesh.height

	local t = {}
	local tiles = {}

	t.width  = w
	t.height = h

	for z=1,h do

		local Z_t = {}
		tiles[z] = Z_t

		for x=1, w do
			Z_t[x] = { tile={ Grid:getTileTriangles(map_mesh,x,z)}, walls={} }

			Z_t[x][1] = Z_t[x].tile[1]
			Z_t[x][2] = Z_t[x].tile[2]

			for i=1,5 do
				Z_t[x].walls[i] = { Grid:getWallVerts(map_mesh,x,z,i) }

				if Z_t[x].walls[i][1] then
					table.insert(Z_t[x], Z_t[x].walls[i][1])
				end
				if Z_t[x].walls[i][2] then
					table.insert(Z_t[x], Z_t[x].walls[i][2])
				end
			end
		end
	end

	t.tiles = tiles
	setmetatable(t, Grid)

	return t
end

function Grid:tile(x,z)
	if x<1 or x>w or z<1 or z>h then
		return nil end
	return self[z][x]
end

function Grid:tileWorld(x,z)
	local x = math.floor(x / TILE_SIZE)+1
	local z = math.floor(z / TILE_SIZE)+1
	return self:tile(x,z)
end

-- gets tiles that are inside of a given box of width w across the x-axis and h across the z-axis
function Grid:tilesInWorldBox(x,z,w,h)
	local tiles = {}

	for X = math.min(0,math.floor(x / TILE_SIZE)), math.min(self.width,math.ceil((x+w)/TILE_SIZE))-1 do
		for Z = math.min(0,math.floor(z / TILE_SIZE)), math.min(self.height,math.ceil((z+h)/TILE_SIZE))-1 do

			local tile = self:tile(X,Z)
			if tile then table.insert(tiles,tile) end

		end
	end
	return tiles
end

function Grid:tilesInWorldSphere(x,z,r)
	return self:tilesInWorldBox(x+r,z+r,r*2,r*2)
end

function Grid:getTileTriangles(map_mesh, x,z )
	local index, index_end = self:getTilesIndexInMesh( map_mesh, x,z )
	if not index then return nil,nil,nil,nil,nil,nil end

	local mesh = map_mesh.mesh
	local v = {}
	local norms = {}
	for i=index, index_end do
		v[i-index+1]     = {mesh:getVertexAttribute( i, 1 )}
		norms[i-index+1] = {mesh:getVertexAttribute( i, 3 )}
	end
	local tri1, tri2 = {}, {}

	tile_shape = map_mesh.tile_shapes[z][x]
	if tile_shape == 0 then
		tri1[1], tri1[2], tri1[3] = v[1], v[2], v[3]
		tri2[1], tri2[2], tri2[3] = v[3], v[4], v[1]
		tri1.normal = norms[1]
		tri2.normal = norms[4]

	elseif tile_shape > 0 then
		tri1[1], tri1[2], tri1[3] = v[1], v[2], v[3]
		tri2[1], tri2[2], tri2[3] = v[4], v[5], v[6]
		tri1.normal = norms[1]
		tri2.normal = norms[4]
	end

	return tri1, tri2
end
function Grid:getTilesIndexInMesh(map_mesh, x,z)
	local w,h = map_mesh.width, map_mesh.height
	if x<1 or x>w or z<1 or z>h then
		return nil end

	local vmap = map_mesh.tile_vert_map
	local index = vmap[z][x].first

	local tile_shape = map_mesh.tile_shapes[z][x]
	local count = 3
	if tile_shape > 0 then count = 5 end

	return index, index + count
end

function Grid:getWallsIndexInMesh(map_mesh, x,z , side )
	local w,h = map_mesh.width, map_mesh.height
	if x<1 or x>w or z<1 or z>h then
		return nil end

	assert(side>=1 and side<=5)
	local wmap = map_mesh.wall_vert_map

	if not wmap[z][x][side] then return nil end

	local index = wmap[z][x][side].first
	local last  = wmap[z][x][side].last
	return index,last
end

function Grid:getWallVerts(map_mesh, x,z , side )
	assert(x,z,side)
	local index = self:getWallsIndexInMesh(map_mesh, x,z,side)
	if not index then return nil,nil,nil,nil end

	local mesh = map_mesh.mesh
	local v1 = {mesh:getVertexAttribute( index+0, 1 )}
	local v2 = {mesh:getVertexAttribute( index+1, 1 )}
	local v3 = {mesh:getVertexAttribute( index+2, 1 )}
	local v4 = {mesh:getVertexAttribute( index+3, 1 )}

	local n1 = {mesh:getVertexAttribute( index+0, 3 )}
	local n2 = {mesh:getVertexAttribute( index+1, 3 )}
	local n3 = {mesh:getVertexAttribute( index+2, 3 )}
	local n4 = {mesh:getVertexAttribute( index+3, 3 )}

	if not (v1 and v2 and v3 and v4) then return false, nil end
	local tri1,tri2 = {},{}

	tri1[1], tri1[2], tri1[3] = v1, v2, v3
	tri2[1], tri2[2], tri2[3] = v3, v4, v1
	tri1.normal = v1
	tri2.normal = v4

	return tri1, tri2
end
