local Viewport = {}

-- Keep UI measurements in design units while adapting to the window's aspect ratio.
function Viewport.scale()
    local width, height = love.graphics.getDimensions()
    return math.min(width / 1920, height / 1080)
end

function Viewport.dimensions()
    local width, height = love.graphics.getDimensions()
    local scale = Viewport.scale()
    return width / scale, height / scale
end

function Viewport.toLocal(x, y)
    local scale = Viewport.scale()
    return x / scale, y / scale
end

function Viewport.mousePosition()
    local x, y = require("src.input").position()
    if x then
        return x, y
    end
    return Viewport.toLocal(love.mouse.getPosition())
end

function Viewport.beginDraw()
    love.graphics.push("all")
    love.graphics.scale(Viewport.scale())
end

function Viewport.endDraw()
    love.graphics.pop()
end

-- Scissor rectangles use window coordinates and ignore the graphics transform.
function Viewport.setScissor(x, y, width, height)
    local scale = Viewport.scale()
    love.graphics.setScissor(x * scale, y * scale, width * scale, height * scale)
end

return Viewport
