--
-- 
--
local clone
clone = function(t)
	if type(t)=="table" then
		local T = {}
		for i,v in pairs(t) do
			T[i]=clone(v)
		end
		return T
	end
	return t
end

return clone
