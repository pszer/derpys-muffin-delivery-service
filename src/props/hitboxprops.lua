--[[ property table prototype for a hitbox object
--]]
--

require "prop"

HitboxPropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only
	--
	{"box_position", "table", nil, PropDefaultTable{0,0,0}  , "hitbox position." },
	{"box_velocity", "table", nil, PropDefaultTable{0,0,0}  , "hitbox velocity." },
	{"box_rotation", "table", nil, PropDefaultTable{0,0,0, "rot"}  , "hitbox rotation." },
	{"box_scale"   , "table", nil, PropDefaultTable{1,1,1}, "hitbox scale." },

	{"box_type", "string", nil, PropIsOneOf{'box','capsule','sphere','model'}  , "hitbox type" }, -- done

	-- These define the shape of the hitbox, to transform the hitbox use the position/rotation/scale attributes.
	{"box_aabb"        , "table", nil, PropDefaultTable{0,0,0,0}, "hitbox AABB spec if of 'box' type. (x,y,w,h)"},
	{"box_capsule"     , "table", nil, PropDefaultTable{a={0,0,0},b={0,0,0},radius=0}, "hitbox capsule spec if of 'capsule' type."},
	{"box_sphere"      , "table", nil, PropDefaultTable{a={0,0,0},radius=0}, "hitbox sphere spec if of 'sphere' type."},
	{"box_model"       , nil, nil, nil, "model instance if of 'model' type."},
	{"box_model_instance_i"  , nil, nil, nil, "if GPU model instancing is used for this instance, this is the index for the particular instance."},

	{"box_model_mat", nil, nil, nil, "matrix that transforms by box_position,rotation, scale"},
	{"box_normal_mat", nil, nil, nil, "matrix that transforms the model's normals after box_rotation,scale"},

	{"box_bounds", "table", nil, PropDefaultTable{min={0,0,0}, max={0,0,0}}, "bounding box for this hitbox"},

	{"box_static", "boolean", false, nil, "if true the entity's bounds are calculated once, and velocity is always zero."},

}
