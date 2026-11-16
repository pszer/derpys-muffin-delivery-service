--[[ property table prototype for physics material
--]]
--

require "prop"

PhysMaterialPropPrototype = Props:prototype{

	-- prop      prop     prop default    prop input     prop      read
	-- name      type        value        validation     info      only
	--

	{"mat_solid"   , "boolean", true , nil         , "whether material is solid/non-solid"},
	{"mat_friction", "number" , 0.30  , PropMin(0.0), "materials friction"},
	{"mat_bounce"  , "number" , 0.0  , PropMin(0.0), "materials bounce"},

}
