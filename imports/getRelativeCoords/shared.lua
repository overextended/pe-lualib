local glm_sincos = require 'glm'.sincos --[[@as fun(n: number): number, number]]
local glm_rad = require 'glm'.rad --[[@as fun(n: number): number]]

---Get the relative coordinates of a vector3 based on rotation and offset
---@param coords vector3 The base coordinates
---@param rotation number | vector3 Either a heading (number) or full rotation (vector3)
---@param offset vector3 The offset to apply
---@return vector3
function lib.getRelativeCoords(coords, rotation, offset)
    if type(rotation) == 'number' then
        local sin, cos = glm_sincos(glm_rad(rotation))
        local relativeX = offset.x * cos - offset.y * sin
        local relativeY = offset.x * sin + offset.y * cos

        return vec3(
            coords.x + relativeX,
            coords.y + relativeY,
            coords.z + offset.z
        )
    end

    local pitch = glm_rad(rotation.x)
    local roll = glm_rad(rotation.y)
    local yaw = glm_rad(rotation.z)

    local sp, cp = glm_sincos(pitch)
    local sr, cr = glm_sincos(roll)
    local sy, cy = glm_sincos(yaw)

    local rotatedX = offset.x * (cy * cr) + offset.y * (cy * sr * sp - sy * cp) + offset.z * (cy * sr * cp + sy * sp)
    local rotatedY = offset.x * (sy * cr) + offset.y * (sy * sr * sp + cy * cp) + offset.z * (sy * sr * cp - cy * sp)
    local rotatedZ = offset.x * (-sr) + offset.y * (cr * sp) + offset.z * (cr * cp)

    return vec3(
        coords.x + rotatedX,
        coords.y + rotatedY,
        coords.z + rotatedZ
    )
end

return lib.getRelativeCoords
