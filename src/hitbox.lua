require 'props.hitboxprops'

Hitbox = {__type=='hitbox'}
Hitbox.__index = Hitbox

function Hitbox:new(props)
	local this = {
		props = EntityPropPrototype(props),

		ent_moved = true,
		recalculate_bounds_flag = true
	}

	setmetatable(this,Entity)

	return this
end
