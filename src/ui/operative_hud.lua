local Level = require("src.level")
local Hud = {}
Hud.__index = Hud

local compass = { "E", "N", "W", "S" }
local portraitSize = 90
local portraits = { { 160, 4 }, { 160, 318 }, { 160, 633 }, { 160, 945 } }
local noise = [[
    extern number frame;
    extern bool lettering;

    vec4 effect(vec4 color, Image image, vec2 uv, vec2 pixel) {
        vec2 cell = floor(pixel / vec2(2.0, 1.0));
        float grain = fract(sin(dot(cell + frame, vec2(12.9898, 78.233))) * 43758.5453);
        float scan = mix(0.68, 1.0, mod(cell.y, 2.0));
        float band = exp(-pow(mod(pixel.y + frame * 3.0, 104.0) / 8.0, 2.0));
        float signal = (0.10 + grain * 0.55 + band * 0.14) * scan;
        if (lettering) {
            float drop = step(0.10, fract(sin((cell.y + frame) * 11.83) * 43758.5453));
            return vec4((0.55 + 0.45 * grain) * vec3(1.0, 0.69, 0.49) * scan, Texel(image, uv).a * drop);
        }
        return vec4(signal * vec3(0.92, 1.0, 0.94), 1.0);
    }
]]

function Hud.new(atlas)
    local graphics = love.graphics
    local self = setmetatable({ atlas = atlas, portraits = {}, static = graphics.newShader(noise), miaFont = graphics.newFont(96) }, Hud)
    for index, position in ipairs(portraits) do
        self.portraits[index] = graphics.newQuad(position[1], position[2], portraitSize, portraitSize, atlas:getDimensions())
    end
    return self
end

function Hud:drawStatic(x, y, width, height, index)
    local graphics = love.graphics
    self.static:send("frame", (math.floor(love.timer.getTime() * 20) + index * 37) % 2048)
    self.static:send("lettering", false)
    graphics.setShader(self.static)
    graphics.rectangle("fill", x, y, width, height)
    self.static:send("lettering", true)
    graphics.printf("MIA", self.miaFont, x, y + (height - self.miaFont:getHeight()) / 2, width, "center")
    graphics.setShader()
end

function Hud:draw(player, index, x, y, nameFont, smallFont)
    local graphics = love.graphics
    graphics.setColor(0.17, 0.14, 0.11)
    graphics.rectangle("fill", x, y + 5, 44, 44)
    graphics.setColor(1, 1, 1)
    graphics.draw(self.atlas, self.portraits[index], x, y + 5, 0, 44 / portraitSize)
    graphics.setColor(unpack(player.color))
    graphics.print(string.format("%02d  %s  /  %s", index, player.name, player.role), nameFont, x + 56, y + 3)

    local hpX = x + 57
    graphics.setColor(0.29, 0.12, 0.10)
    graphics.rectangle("fill", hpX, y + 36, 114, 7)
    graphics.setColor(0.72, 0.32, 0.25)
    graphics.rectangle("fill", hpX, y + 36, 114 * player.health / 100, 7)
    graphics.setColor(0.74, 0.68, 0.60)
    graphics.print(string.format("%d HP", player.health), smallFont, hpX + 124, y + 29)
    local hand = player.inventory.hand
    if hand and hand.rounds then
        graphics.setColor(0.84, 0.68, 0.44)
        graphics.print(string.format("%02d RDS", hand.rounds), smallFont, hpX + 212, y + 29)
    end

    local dx, dy = Level.direction(player.heading)
    local cx, cy = x + 355, y + 27
    dy = -dy
    graphics.setColor(0.32, 0.27, 0.22)
    graphics.circle("line", cx, cy, 13)
    graphics.setColor(unpack(player.color))
    graphics.polygon("fill", cx + dx * 9, cy + dy * 9, cx - dx * 5 - dy * 5, cy - dy * 5 + dx * 5, cx - dx * 5 + dy * 5, cy - dy * 5 - dx * 5)
    graphics.print(compass[player.heading + 1], smallFont, cx + 20, y + 16)
end

function Hud:release()
    for _, portrait in ipairs(self.portraits) do
        portrait:release()
    end
    self.static:release()
    self.miaFont:release()
end

return Hud
