require "props.tileprops"

TILE_SIZE   = CONSTS.TILE_SIZE
TILE_HEIGHT = CONSTS.TILE_HEIGHT

Tile = {__type = "tile",

	--[[atypes = {
		{"TextureScale",    "float", 2},
		{"TextureOffset",   "float", 2}
	}--]]

}
Tile.__index = Tile

function Tile.tileCoordToWorld(x,y,z)
	return x * TILE_SIZE, y*TILE_HEIGHT, -z*TILE_SIZE
end

function Tile.worldCoordToTile(x,y,z)
	return x / TILE_SIZE, y/TILE_HEIGHT, -z/TILE_SIZE
end
