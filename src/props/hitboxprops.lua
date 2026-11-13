--[[ property table prototype for a hitbox object
--]]
--

require "prop"

HitboxPropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only
	--
	{"box_position", "table", nil, PropDefaultTable{0,0,0}  , "hitbox position" },
	{"box_rotation", "table", nil, PropDefaultTable{0,0,0, "rot"}  , "hitbox rotation" },
	{"box_scale"   , "table", nil, PropDefaultTable{1,1,1}, "hitbox scale" },

	{"box_type", "string", nil, PropIsOneOf{'box','capsule','mesh'}  , "hitbox position" }, -- done

	{"box_static", "boolean", false, nil, "if true the entity's velocity is ignored"},

}
