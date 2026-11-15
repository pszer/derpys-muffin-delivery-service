-- material properties as to be used in physics calculations
--
require 'props.physicsmaterial'

PhysMaterial = {__type="physmaterial"}
PhysMaterial.__index = PhysMaterial

function PhysMaterial:new(props)
	local this = {
		props = PhysMaterialPropPrototype(props),
	}
	setmetatable(this,PhysMaterial)
	return this
end

function PhysMaterial:isSolid()
	return self.props.mat_solid == true end
function PhysMaterial:getFriction()
	return self.props.mat_friction end
function PhysMaterial:getBounce()
	return self.props.mat_bounce end

return PhysMaterial
