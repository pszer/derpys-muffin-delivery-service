require "vec3"

require "math"
require "angle"

local __tempvec = {}
local func = function(GameData)
	return function(ent, state, args)
		local walk_speed = state.state_walking_speed
		local walk_accel = state.state_walking_accel 
		local dt = GameData:getDt()

		local direction = args.dir
		__tempvec[1] = direction[1] * walk_accel
		__tempvec[2] = direction[2] * walk_accel 
		__tempvec[3] = direction[3] * walk_accel 
		ent:accelerate( __tempvec, dt )

		local dir_this_frame = state.state_walking_dir_this_frame
		dir_this_frame[1] = dir_this_frame[1] + direction[1]
		dir_this_frame[2] = dir_this_frame[2] + direction[2]
		dir_this_frame[3] = dir_this_frame[3] + direction[3]

		state.state_walking_deaccel = false
	end
end
return func
