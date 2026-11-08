local Geometry = {}

function Geometry.contains(x, y, bounds)
    return x >= bounds.x and x <= bounds.x + bounds.w and y >= bounds.y and y <= bounds.y + bounds.h
end

return Geometry
