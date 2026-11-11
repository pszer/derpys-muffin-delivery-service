-- "physics"
-- there's no real physics, just sticking entities to the floor
--

require "gameinterface"

local physics = {}
physics.__index = physics

local CONSTS = require 'consts'

function physics.getHeightAt(map,x,z)
	local Xt,Zt = x/CONSTS.TILE_SIZE, z/CONSTS.TILE_SIZE	
end

return physics
