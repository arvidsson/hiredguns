local inside = require("src.ui.geometry").contains
local Viewport = require("src.viewport")

local Button = {}
Button.__index = Button

function Button.new(bounds, activate)
    return setmetatable({ bounds = bounds, activate = activate }, Button)
end

function Button.enabled()
    return true
end

function Button:reset()
    self.hover, self.pressed = false, false
end

function Button:update()
    local x, y = Viewport.mousePosition()
    self.hover = inside(x, y, self.bounds())
end

function Button:mousepressed(x, y, button)
    if button == 1 and inside(x, y, self.bounds()) then
        self.pressed = true
    end
end

function Button:mousereleased(x, y, button)
    if button ~= 1 then
        return
    end
    local activate = self.pressed and inside(x, y, self.bounds())
    self.pressed = false
    if activate then
        self.activate()
    end
end

function Button:draw(label, font)
    local b = self.bounds()
    local shade = self.pressed and 0.21 or self.hover and 0.37 or 0.29
    love.graphics.setColor(shade, shade + 0.13, shade + 0.17)
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 12, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(label, font, b.x, b.y + (b.h - font:getHeight()) / 2, b.w, "center")
end

return Button
