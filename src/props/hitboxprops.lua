--[[ property table prototype for a hitbox object
--]]
--

require "prop"

require 'physicsmaterial'

HitboxPropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only
	--
	{"box_position", "table", nil, PropDefaultTable{0,0,0}  , "hitbox position." },
	{"box_velocity", "table", nil, PropDefaultTable{0,0,0}  , "hitbox velocity." },
	{"box_rotation", "table", nil, PropDefaultTable{0,0,0, "rot"}  , "hitbox rotation. only for models." },
	{"box_scale"   , "table", nil, PropDefaultTable{1,1,1}, "hitbox scale." },

	{"box_material", "physmaterial", nil, PropDefaultObject(PhysMaterial, {})},

	{"box_type", "string", nil, PropIsOneOf{'box','capsule','sphere','model'}  , "hitbox type" }, -- done

	-- These define the shape of the hitbox, to transform the hitbox use the position/rotation/scale attributes.
	{"box_aabb"        , "table", nil, PropDefaultTable{0,0,0}, "hitbox AABB spec if of 'box' type. (w,h,d)"},

	--{"box_capsule"     , "table", nil, PropDefaultTable{a={0,0,0},b={0,0,0},radius=0}, "hitbox capsule spec if of 'capsule' type."},
	--
	{"box_sphere"      , "table", nil, PropDefaultTable{a={0,0,0},radius=0}, "hitbox sphere spec if of 'sphere' type."},
	{"box_model"       , nil, nil, nil, "model instance if of 'model' type."},
	{"box_model_instance_i"  , nil, nil, nil, "if GPU model instancing is used for this instance, this is the index for the particular instance."},

	{"box_capsule_height", "number", 0, nil, "capsule height, if capsule hitbox"},
	{"box_capsule_radius", "number", 0, nil, "capsule radius, if capsule hitbox"},

	{"box_model_mat"   , nil, nil, nil, "matrix that transforms by box_position,rotation, scale"},
	{"box_model_invmat", nil, nil, nil, "inverse matrix"},
	{"box_normal_mat", nil, nil, nil, "matrix that transforms the model's normals after box_rotation,scale"},

	{"box_bounds", "table", nil, PropDefaultTable{min={0,0,0}, max={0,0,0}}, "bounding box for this hitbox"},

	{"box_static", "boolean", false, nil, "if true the entity's bounds are calculated once, and velocity is always zero."},

	{"box_grounded", "boolean", false, nil, "is the hitbox touching a ground plane last frame."},
	{"box_ceiling" , "boolean", false, nil, "is the hitbox touching a ceiling plane last frame."},
	{"box_wall"    , "boolean", false, nil, "is the hitbox touching a wall plane last frame."},

	{"box_ground_normal" , "table", nil, PropDefaultTable{0,-1,0}, "(when box_grounded is true) normal vector of ground plane."},
	{"box_ceiling_normal", "table", nil, PropDefaultTable{0, 1,0}, "(when box_ceiling is true) normal vector of ceiling plane."},
	{"box_wall_normal"   , "table", nil, PropDefaultTable{0 ,0,1}, "(when box_wall is true) normal vector of wall plane."},

	{"box_ground_angle", "number", 60, nil, "maximum angle that counts as the ground"},
	{"box_ceiling_angle",  "number", 30, nil, "maximum angle that counts as the ground"},
	{"box_wall_angle",     "number", 45, nil, "maximum angle that counts as the ground"},

	{"box_apply_movement_rules", "boolean", false, nil, [[if true, player movement rules are applied to this hitbox. this includes
	calculating box_grounded etc. and changing gravity on slopes.]]}

}
