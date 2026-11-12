-- edits facial animation data to create derpy eyes
--
--

-- face: face data (see cfg/face.lua)
-- name: animation name (see cfg/face.lua)
-- axis     : either 'y' or 'x', which are up/down and left/right respectively
-- amount   : how much offset is added, 1.0 is equal to the eye radius.
-- start/end_frame : only edit frames in this interval, if nil all frames are
--                   affected.
--
local function derpify(face, anim_name, axis, amount, start_frame, end_frame)
	require 'facialfeatures'
	local anim_data = face.animface_anims[anim_name]

	if not anim_data then
		error(string.format('derpify(): no face anim data \'%s\'', anim_name))
	end

	local start_frame = start_frame or -9999999999
	local end_frame   = end_frame   or  9999999999

	local eye_atts = require 'cfg.eyes'
	local eye_data = eye_atts[face.animface_eyesdata_name]
	local eye_radius = eye_data.eyes_radius

	local amount = amount * eye_radius
	local add = {0,0}
	local axis = axis or 'y'
	if axis=='x' or axis=='X' then
		add = {amount,0}
	else
		add = {0,amount}
	end

	for i=1,#anim_data do

		local frame = anim_data[i]

		if frame[1] >= start_frame and frame[1] <= end_frame then
			local right = frame.animface_righteye_dir
			local left = frame.animface_lefteye_dir

			if right then
				right[1] = right[1] + add[1]
				right[2] = right[2] + add[2]
			end
			if left then 
				left[1]  = left[1]  - add[1]
				left[2]  = left[2]  - add[2]
			end
		end

	end
end

return derpify
