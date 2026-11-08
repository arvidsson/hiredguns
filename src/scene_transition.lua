local Transition = {}
Transition.__index = Transition

local function smooth(value)
    value = math.max(0, math.min(1, value))
    return value * value * (3 - 2 * value)
end

function Transition.new(scene)
    local width, height = love.graphics.getDimensions()
    local canvas = love.graphics.newCanvas(width, height)
    love.graphics.push("all")
    love.graphics.setCanvas({ canvas, stencil = true })
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 1)
    scene.draw()
    love.graphics.pop()
    local shader = love.graphics.newShader([[
        extern number progress;
        extern vec3 glowColor;
        float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
        float noise(vec2 p) {
            vec2 cell = floor(p), f = fract(p);
            f = f * f * (3.0 - 2.0 * f);
            return mix(mix(hash(cell), hash(cell + vec2(1, 0)), f.x),
                       mix(hash(cell + vec2(0, 1)), hash(cell + vec2(1, 1)), f.x), f.y);
        }
        vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
            float grain = noise(uv * vec2(12, 8)) * 0.07 + noise(uv * 48.0) * 0.018;
            float field = uv.x * 0.68 + uv.y * 0.32 + grain;
            float frontier = mix(-0.16, 1.24, progress);
            float mask = smoothstep(frontier - 0.10, frontier + 0.10, field);
            float rim = exp(-abs(field - frontier) * 95.0);
            vec4 old = Texel(texture, uv);
            float shadow = 1.0 - sin(progress * 3.14159265) * 0.40;
            vec3 ink = old.rgb * shadow + glowColor * rim * 0.21;
            return vec4(ink, old.a * mask) * color;
        }
    ]])
    return setmetatable({
        canvas = canvas,
        shader = shader,
        elapsed = 0,
        duration = 0.72,
        glow = { 0.48, 0.72, 0.78 },
    }, Transition)
end

function Transition:progress()
    return math.min(1, self.elapsed / self.duration)
end

function Transition:update(dt)
    self.elapsed = self.elapsed + math.max(0, dt)
    return self:progress() == 1
end

function Transition:draw(scene)
    local width, height = love.graphics.getDimensions()
    local progress = self:progress()
    local settle = 1 - smooth(progress)
    love.graphics.push("all")
    -- A small inward drift settles into the incoming screen's actual geometry.
    love.graphics.translate(width / 2, height / 2)
    love.graphics.scale(1 + settle * 0.025)
    love.graphics.translate(-width / 2, -height / 2 + settle * 7)
    scene.draw()
    love.graphics.pop()

    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setShader()
    local shade = math.sin(progress * math.pi)
    love.graphics.setColor(0.018, 0.023, 0.021, shade * 0.48)
    love.graphics.rectangle("fill", 0, 0, width, height)
    self.shader:send("progress", smooth(progress))
    self.shader:send("glowColor", self.glow)
    love.graphics.setShader(self.shader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvas, 0, 0, 0, width / self.canvas:getWidth(), height / self.canvas:getHeight())
    love.graphics.setShader()
    -- A handful of drifting flecks catch the light along the passing veil.
    for i = 1, 28 do
        local x = ((i * 0.61803398875) % 1) * width
        local y = ((i * 0.38196601125) % 1) * height - progress * height * 0.035
        local frontier = -0.16 + 1.40 * smooth(progress)
        local distance = math.abs(x / width * 0.68 + y / height * 0.32 + 0.04 - frontier)
        local alpha = math.max(0, 1 - distance / 0.11) * shade * 0.35
        love.graphics.setColor(self.glow[1], self.glow[2], self.glow[3], alpha)
        love.graphics.circle("fill", x, y, (0.6 + i % 3 * 0.35) * height / 1080)
    end
    love.graphics.pop()
end

function Transition:destroy()
    self.canvas:release()
    self.shader:release()
end

return Transition
