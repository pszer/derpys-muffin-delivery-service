local clone = require 'clone'

EYES_ATTRIBUTES = {
	["derpy_eyes"] = {
		eyes_filename = "models/pony/derpyeyes.png",
		eyes_dimensions = {96,96},
		eyes_radius = 36,
		eyes_poses = {
			{name="neutral"},
			{name="close_phase1"},
			{name="close_phase2"},
			{name="close_phase3"}
	  }
	 }
}

return EYES_ATTRIBUTES
