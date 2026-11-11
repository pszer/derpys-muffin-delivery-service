require "animator"

local modelanimator = {}
modelanimator.__index = modelanimator

function modelanimator:new(model)
	local t = {
		anim1 = Animator:new(model),
		anim2 = Animator:new(model),
		interp = 0.0
	}

	setmetatable(t,modelanimator)
	return t
end

function modelanimator:setInterp(i)
	if i < 0.0 then i=0 end
	if i > 1.0 then i=1 end
	self.interp = i
end

function modelanimator:apply(outbuf1,outbuf2,out)
	Animator.applyTwoAnimators(self.anim1,self.anim2,self.interp,outbuf1,outbuf2,out)
end

function modelanimator:update()
	self.anim1:update()
	self.anim2:update()
end

return modelanimator
