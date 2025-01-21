--Get the relative coordinates of a vector3 based on a heading and offset
---@param coords vector3
---@param heading number
---@param offset vector3
---@return vector4 coords
function lib.getRelativeCoords(coords, heading, offset)
	local headingRad = math.rad(heading)

    local relativeX = offset.x * math.cos(headingRad) - offset.y * math.sin(headingRad)
    local relativeY = offset.x * math.sin(headingRad) + offset.y * math.cos(headingRad)

    return vec4(
		coords.x + relativeX,
		coords.y + relativeY,
        coords.z + offset.z,
        heading
	)
end

return lib.getRelativeCoords
