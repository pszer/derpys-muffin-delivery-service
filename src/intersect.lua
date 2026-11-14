local Intersect = {}
Intersect.__index = Intersect

-- point: point
-- faces: 3 points for each face
function Intersect.pointInTriangularPrism(point, faces)
	local sign = nil
	-- if intersection happens, the sign for the dot product d will be
	-- the same for all five faces
	for i=1,5 do
		local p0,p1,p2 = faces[i][1],faces[i][2],faces[i][3]

		local p01 = p1-p0
		local p02 = p2-p0
		local norm = cpml.vec3.cross(p01,p02)
		local d = dot(norm, point - p0)

		if i==1 then sign = d end
		if sign*d <= 0 then return false end
	end
	return true
end

return Intersect
