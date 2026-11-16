require "vec3"

require "math"
require "angle"

local __tempvec = {}
local func = function(GameData)
	return function(ent, state, args)
		local walk_speed = state.state_walking_speed
		local walk_accel = state.state_walking_accel 
		local dt = GameData:getDt()

		walk_accel = walk_accel * (1.0 - 0.6 * (ent:getHorizontalSpeed() / walk_speed)^2 )

		local direction = args.dir
		__tempvec[1] = direction[1]
		__tempvec[2] = direction[2]
		__tempvec[3] = direction[3]

		local box = ent:getHitbox()
		-- project along ground plane (if grounded)
		if box.props.box_grounded then
			local n = box.props.box_ground_normal
			local d = __tempvec[1]*n[1] + __tempvec[2]*n[2] + __tempvec[3]*n[3]

			__tempvec[1] = __tempvec[1] - d*n[1]
			__tempvec[2] = __tempvec[2] - d*n[2]
			__tempvec[3] = __tempvec[3] - d*n[3]
			-- renormalise
			local len = math.sqrt(__tempvec[1]*__tempvec[1] + __tempvec[2]*__tempvec[2] + __tempvec[3]*__tempvec[3])
			if len>0 then
				__tempvec[1] = __tempvec[1] / len
				__tempvec[2] = __tempvec[2] / len
				__tempvec[3] = __tempvec[3] / len
			end
		end

		__tempvec[1] = __tempvec[1] * walk_accel
		__tempvec[2] = __tempvec[2] * walk_accel
		__tempvec[3] = __tempvec[3] * walk_accel
		ent:accelerate( __tempvec, dt )

		local dir_this_frame = state.state_walking_dir_this_frame
		dir_this_frame[1] = dir_this_frame[1] + direction[1]
		dir_this_frame[2] = dir_this_frame[2] + direction[2]
		dir_this_frame[3] = dir_this_frame[3] + direction[3]

		state.state_walking_deaccel = false
	end
end
return func
