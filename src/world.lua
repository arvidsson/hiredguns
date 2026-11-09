local Level = require("src.level")
local Fireball = require("src.fireball")
local World = {}
World.__index = World
World.muzzleTime = 0.10

local height = Level.upperZ
local lighting = [[
    varying vec4 worldPosition;
    varying vec4 viewPosition;
    varying vec4 vertexColor;
    uniform float fixture;
    uniform float exterior;
    uniform float lightCount;
    uniform vec4 localLights[8];
    uniform float hitFlash;

    vec4 effect(vec4 color, Image image, vec2 uv, vec2 pixel) {
        vec3 p = worldPosition.xyz;
        vec2 amber = mod(p.xy - vec2(3.5, 3.5) + vec2(4.0, 2.75), vec2(8.0, 5.5))
            - vec2(4.0, 2.75);
        vec2 blue = mod(p.xy - vec2(7.5, 6.0) + vec2(4.0, 2.75), vec2(8.0, 5.5))
            - vec2(4.0, 2.75);
        vec3 light = vec3(0.38, 0.33, 0.32);
        light += vec3(0.95, 0.57, 0.28) / (1.0 + 0.85 * dot(amber, amber));
        light += vec3(0.19, 0.50, 0.51) / (1.0 + 1.2 * dot(blue, blue));
        vec4 texel = Texel(image, uv);
        if (texel.a < 0.5) discard;
        light = mix(light, vec3(1.10, 0.80, 0.62), exterior);
        for (int i = 0; i < 8; i++) {
            if (float(i) >= lightCount) break;
            vec3 offset = p - vec3(localLights[i].xy, 0.72);
            float falloff = max(0.0, 1.0 - length(offset) / localLights[i].w);
            light += vec3(falloff * falloff * localLights[i].z);
        }
        vec3 surface = texel.rgb * vertexColor.rgb * color.rgb * light;
        surface = mix(surface, max(surface, vec3(0.98, 0.64, 0.27) * vertexColor.rgb), fixture);
        surface = mix(surface, max(surface, vec3(1.0, 0.93, 0.86)), hitFlash);
        float haze = min(0.88, smoothstep(1.1, mix(13.0, 24.0, exterior), length(viewPosition.xyz)));
        surface = mix(surface, mix(vec3(0.060, 0.045, 0.039), vec3(0.22, 0.12, 0.085), exterior), haze);
        return vec4(floor(surface * 44.0 + 0.5) / 44.0, 1.0);
    }
]]
local skyShader = [[
    extern Image panorama;
    extern vec2 resolution;
    extern vec2 forward;
    extern vec2 frustum;
    extern vec2 tilt;

    vec4 effect(vec4 color, Image image, vec2 uv, vec2 pixel) {
        vec2 screen = pixel / resolution * 2.0 - 1.0;
        vec2 right = vec2(forward.y, -forward.x);
        float up = -screen.y * frustum.y;
        vec3 ray = normalize(vec3(forward * (tilt.x - up * tilt.y) + right * screen.x * frustum.x, tilt.y + up * tilt.x));
        vec2 sky = vec2(atan(ray.y, ray.x) / 6.2831853 + 0.5, 0.5 - asin(ray.z) / 3.1415927);
        return vec4(Texel(panorama, sky).rgb * vec3(0.86, 0.83, 0.82), 1.0);
    }
]]
local flame = [[
    uniform float flicker;
    uniform float burst;

    vec4 effect(vec4 color, Image image, vec2 uv, vec2 pixel) {
        vec2 p = (floor(uv * 22.0) + 0.5) / 22.0 - 0.5;
        float ripple = sin(p.y * 29.0 + flicker) * cos(p.x * 23.0 - flicker);
        float radius = length(p) + ripple * 0.085;
        if (burst >= 0.0) {
            float ring = abs(radius - mix(0.11, 0.39, burst));
            float spokes = sin(atan(p.y, p.x) * 8.0 + flicker);
            float sparks = step(ring, 0.075 + 0.035 * spokes) * step(-0.28, spokes);
            float core = step(radius, mix(0.22, 0.05, burst)) * (1.0 - burst);
            float alpha = max(sparks, core) * (1.0 - burst);
            if (alpha < 0.03) discard;
            return vec4(1.0, 0.05 * core, 0.01, alpha);
        }
        if (radius > 0.43) discard;
        float red = radius < 0.29 ? 1.0 : 0.72;
        float alpha = radius < 0.20 ? 0.80 : radius < 0.33 ? 0.62 : 0.39;
        return vec4(red, 0.0, 0.0, alpha);
    }
]]

local function quad(vertices, a, b, c, d, shade, verticalRepeat)
    local function vertex(point, u, v)
        return { point[1], point[2], point[3], u, v, 0, 0, 1, shade, shade, shade, 1 }
    end
    local v = verticalRepeat or 1
    vertices[#vertices + 1] = vertex(a, 0, v)
    vertices[#vertices + 1] = vertex(b, 1, v)
    vertices[#vertices + 1] = vertex(c, 1, 0)
    vertices[#vertices + 1] = vertex(a, 0, v)
    vertices[#vertices + 1] = vertex(c, 1, 0)
    vertices[#vertices + 1] = vertex(d, 0, 0)
end

local function slab(vertices, x, y, x2, y2, z, shade)
    quad(vertices, { x, y, z }, { x2, y, z }, { x2, y2, z }, { x, y2, z }, shade)
end

local function wall(vertices, x, y, x2, y2, low, high, shade, repeatV)
    quad(vertices, { x, y, low }, { x2, y2, low }, { x2, y2, high }, { x, y, high }, shade, repeatV)
end

local function box(vertices, x, y, x2, y2, low, high)
    slab(vertices, x, y, x2, y2, high, 0.95)
    slab(vertices, x, y, x2, y2, low, 0.50)
    wall(vertices, x, y, x2, y, low, high, 0.92)
    wall(vertices, x2, y, x2, y2, low, high, 0.75)
    wall(vertices, x2, y2, x, y2, low, high, 0.92)
    wall(vertices, x, y2, x, y, low, high, 0.75)
end

local function buildGeometry()
    local tiles = { wall = {}, floor = {}, ceiling = {}, crate = {}, hazard = {}, lamp = {}, yard = {}, service = {}, yardWall = {}, yardDeck = {} }
    box(tiles.crate, -0.48, -0.48, 0.48, 0.48, 0, 0.89)
    tiles.door, tiles.doorFrame, tiles.switch = {}, {}, {}
    box(tiles.door, -0.04, -0.219, 0.04, 0.219, 0, height - 0.055)
    box(tiles.doorFrame, -0.08, -0.50, 0.08, -0.44, 0, height)
    box(tiles.doorFrame, -0.08, 0.44, 0.08, 0.50, 0, height)
    box(tiles.doorFrame, -0.08, -0.44, 0.08, 0.44, height - 0.055, height)
    box(tiles.switch, -0.025, -0.075, 0.025, 0.075, 0.60, 0.78)
    local edges = {
        { 0, -1, 0, 0, 1, 0, 0.92 },
        { 1, 0, 1, 0, 1, 1, 0.75 },
        { 0, 1, 1, 1, 0, 1, 0.92 },
        { -1, 0, 0, 1, 0, 0, 0.75 },
    }
    local upperCeiling = Level.upperZ + height
    local deckBottom = Level.upperZ - 0.06
    local function ceiling(x, y, z, lit, covered)
        if not covered then
            slab(tiles.ceiling, x, y, x + 1, y + 1, z, 0.64)
        end
        if lit then
            box(tiles.lamp, x + 0.17, y + 0.43, x + 0.83, y + 0.57, z - 0.04, z - 0.001)
        end
    end
    Level.eachTile(function(x, y, tile)
        if tile ~= "#" then
            local stair = Level.stairHeight(x, y)
            local shaft = Level.indoorStair(x, y)
            if stair then
                local steps = shaft and tiles.service or tiles.yardDeck
                for tread = 1, 5 do
                    local front = x + (tread - 1) / 5
                    local rise = Level.upperZ / 6
                    slab(steps, front, y, x + tread / 5, y + 1, tread * rise, 0.95)
                    wall(steps, front, y + 1, front, y, (tread - 1) * rise, tread * rise, 0.75, rise)
                end
                if shaft then
                    wall(tiles.wall, x, y + 1, x, y, height, upperCeiling, 0.75, upperCeiling - height)
                else
                    wall(steps, x + 1, y, x + 1, y + 1, 0, Level.upperZ, 0.75, Level.upperZ)
                end
            end
            if Level.isOutside(tile) then
                slab(tiles.yard, x, y, x + 1, y + 1, 0, 0.87)
            else
                local floor = tile == "T" and tiles.hazard or tile == "S" and tiles.service or tiles.floor
                slab(floor, x, y, x + 1, y + 1, 0, 0.87)
                local lit = (x % 8 == 3 and (y == 3 or y == 9 or y == 14)) or (tile == "S" and (x + y) % 5 == 0)
                local covered = Level.tile(x, y, Level.upperZ) ~= "#"
                ceiling(x, y, covered and deckBottom or shaft and upperCeiling or height, lit, covered)
            end
        else
            local stairSide = Level.stairSideWall(x, y)
            local bordersYard = false
            local wallHeight = stairSide and upperCeiling or height
            for _, edge in ipairs(edges) do
                local dx, dy, ax, ay, bx, by, shade = unpack(edge)
                local adjacent = Level.tile(x + dx, y + dy)
                if adjacent ~= "#" then
                    local outside = Level.isOutside(adjacent)
                    bordersYard = bordersYard or outside
                    wall(outside and tiles.yardWall or tiles.wall, x + ax, y + ay, x + bx, y + by, 0, wallHeight, shade, wallHeight)
                end
            end
            local covered = wallHeight == Level.upperZ and Level.tile(x, y, Level.upperZ) ~= "#"
            if (stairSide or bordersYard) and not covered then
                slab(tiles.yardWall, x, y, x + 1, y + 1, wallHeight, 0.66)
            end
        end
    end)
    Level.eachTile(function(x, y, tile)
        if tile ~= "#" then
            local outside = Level.isOutside(tile)
            local deck = outside and tiles.yardDeck or tiles.service
            slab(deck, x, y, x + 1, y + 1, Level.upperZ, 0.95)
            slab(deck, x, y, x + 1, y + 1, deckBottom, 0.50)
            for _, edge in ipairs(edges) do
                local dx, dy, ax, ay, bx, by, shade = unpack(edge)
                if Level.tile(x + dx, y + dy, Level.upperZ) == "#" and not Level.stairHeight(x + dx, y + dy) then
                    wall(deck, x + ax, y + ay, x + bx, y + by, deckBottom, Level.upperZ, shade, Level.upperZ - deckBottom)
                end
            end
            if not outside then
                ceiling(x, y, upperCeiling, (x + y) % 4 == 0)
                for _, edge in ipairs(edges) do
                    local dx, dy, ax, ay, bx, by, shade = unpack(edge)
                    if Level.upperWall(x, y, x + dx, y + dy) then
                        wall(tiles.wall, x + ax, y + ay, x + bx, y + by, Level.upperZ, upperCeiling, shade, height)
                    end
                end
            end
        end
    end, Level.upperZ)
    return tiles
end

local function buildSprites(g3d, atlas, rows, spriteHeight)
    -- Trim the vertical gutters so the four views share a floor-level baseline.
    local sprites = {}
    local width, height = atlas:getDimensions()
    for row, bounds in ipairs(rows) do
        local top, bottom, cuts = unpack(bounds)
        local v0, v1 = top / height, bottom / height
        sprites[row] = {}
        for column = 1, 4 do
            local u0, u1 = (column - 1) / 4, column / 4
            if cuts then
                u0, u1 = cuts[column] / width, cuts[column + 1] / width
            end
            local halfWidth = spriteHeight * (u1 - u0) * width / (bottom - top) / 2
            local vertices = {}
            quad(vertices, { 0, halfWidth, 0 }, { 0, -halfWidth, 0 }, { 0, -halfWidth, spriteHeight }, { 0, halfWidth, spriteHeight }, 1)
            for _, vertex in ipairs(vertices) do
                vertex[4] = u0 + (0.5 - vertex[2] / (2 * halfWidth)) * (u1 - u0)
                vertex[5] = v0 + (1 - vertex[3] / spriteHeight) * (v1 - v0)
            end
            sprites[row][column] = g3d.newModel(vertices, atlas)
        end
    end
    return sprites
end

local function spriteView(viewer, player)
    -- The sprite plane is parallel to the camera, so use its facing axis.
    return (viewer.heading + 2 - player.heading) % 4 + 1
end

function World.new(itemArt)
    local graphics = love.graphics
    -- g3d enables depth testing on load. Scope it to the world render passes.
    graphics.push("all")
    local g3d = require("src.vendor.g3d")
    graphics.pop()
    local shader = graphics.newShader(lighting, g3d.shaderpath)
    local self = setmetatable({ camera = g3d.camera, shader = shader, models = {}, images = {} }, World)
    local sharedTextures = { yardWall = "wall", yardDeck = "service", door = "crate", doorFrame = "hazard", switch = "crate" }
    for name, vertices in pairs(buildGeometry()) do
        local textureName = sharedTextures[name] or name
        local texture = graphics.newImage("assets/textures/" .. textureName .. ".png")
        texture:setFilter("nearest", "nearest")
        texture:setWrap("repeat", "repeat")
        self.images[name] = texture
        self.models[name] = g3d.newModel(vertices, texture)
    end
    self.atlas = graphics.newImage("assets/sprites/operatives-psx.png")
    self.atlas:setFilter("nearest", "nearest")
    local operativeCuts = { 65, 342, 625, 915, 1205 }
    self.sprites = buildSprites(g3d, self.atlas, {
        { 4, 309, operativeCuts },
        { 318, 628, operativeCuts },
        { 633, 941, operativeCuts },
        { 945, 1259, operativeCuts },
    }, 0.84)
    local enemyArt = {
        melee = { "monster-psx.png", 0.92, { { 13, 347 }, { 762, 1071, { 0, 302, 735, 1070, 1448 } } } },
        ranged = { "caster-psx.png", 0.89, { { 13, 360 }, { 735, 1080 } } },
        skitterer = { "skitterer-psx.png", 0.62, { { 128, 382 }, { 573, 822, { 0, 392, 900, 1333, 1774 } } } },
    }
    self.enemyAtlases, self.enemySprites = {}, {}
    for kind, art in pairs(enemyArt) do
        local filename, spriteHeight, rows = unpack(art)
        local atlas = graphics.newImage("assets/sprites/" .. filename)
        atlas:setFilter("nearest", "nearest")
        self.enemyAtlases[kind] = atlas
        self.enemySprites[kind] = buildSprites(g3d, atlas, rows, spriteHeight)
    end
    self.corpseImage = graphics.newImage("assets/sprites/corpse.png")
    self.corpseImage:setFilter("nearest", "nearest")
    local corpse = {}
    quad(corpse, { 0, 0.52, 0 }, { 0, -0.52, 0 }, { 0, -0.52, 0.29 }, { 0, 0.52, 0.29 }, 0.94)
    local corpseWidth, corpseHeight = self.corpseImage:getDimensions()
    for _, vertex in ipairs(corpse) do
        vertex[4] = (60 + vertex[4] * 1990) / corpseWidth
        vertex[5] = (158 + vertex[5] * 530) / corpseHeight
    end
    self.corpse = g3d.newModel(corpse, self.corpseImage)
    self.pickups = {}
    for kind, icon in pairs(itemArt.icons) do
        local atlasWidth, atlasHeight = icon.atlas:getDimensions()
        local x, y, width, height = icon.quad:getViewport()
        local scale = math.min(0.48 / width, 0.30 / height)
        local halfWidth, top = width * scale / 2, 0.035 + height * scale
        local vertices = {}
        quad(vertices, { 0, halfWidth, 0.035 }, { 0, -halfWidth, 0.035 }, { 0, -halfWidth, top }, { 0, halfWidth, top }, 1)
        for _, vertex in ipairs(vertices) do
            vertex[4] = (x + vertex[4] * width) / atlasWidth
            vertex[5] = (y + vertex[5] * height) / atlasHeight
        end
        self.pickups[kind] = g3d.newModel(vertices, icon.atlas)
    end
    self.blood = graphics.newImage("assets/effects/blood.png")
    self.blood:setFilter("nearest", "nearest")
    self.bloodSplat = graphics.newQuad(64, 0, 16, 16, self.blood:getDimensions())
    self.scratch = graphics.newQuad(0, 16, 16, 16, self.blood:getDimensions())
    self.slashes = {}
    for frame = 1, 4 do
        local image = graphics.newImage(string.format("assets/effects/slash_arc_%02d.png", frame))
        image:setFilter("nearest", "nearest")
        self.slashes[frame] = image
    end
    local slash = {}
    quad(slash, { 0, 0.30, 0.29 }, { 0, -0.30, 0.29 }, { 0, -0.30, 0.89 }, { 0, 0.30, 0.89 }, 1)
    self.swipe = g3d.newModel(slash, self.slashes[1])
    local fireball = {}
    quad(fireball, { 0, 0.43, -0.43 }, { 0, -0.43, -0.43 }, { 0, -0.43, 0.43 }, { 0, 0.43, 0.43 }, 1)
    self.fireball = g3d.newModel(fireball)
    self.fireShader = graphics.newShader(flame, g3d.shaderpath)
    self.spriteShader = graphics.newShader(lighting, "src/sprite.vert")
    self.spriteShader:send("fixture", 0)
    self.sky = graphics.newImage("assets/textures/yard-sky.png")
    self.sky:setFilter("nearest", "nearest")
    self.sky:setWrap("repeat", "clamp")
    self.skyShader = graphics.newShader(skyShader)
    self.skyShader:send("panorama", self.sky)
    return self
end

function World:drawActor(sprite, actor, cameraAngle)
    self.spriteShader:send("collapse", actor.collapse or 0)
    self.spriteShader:send("exterior", Level.isOutside(Level.tile(actor.x, actor.y, actor.z)) and 1 or 0)
    sprite:setTranslation(actor.x, actor.y, Level.visualHeight(actor))
    sprite:setRotation(0, 0, cameraAngle)
    sprite:draw(self.spriteShader)
end

function World:drawCorpse(actor, cameraAngle)
    self.shader:send("exterior", Level.isOutside(Level.tile(actor.x, actor.y, actor.z)) and 1 or 0)
    self.corpse:setTranslation(actor.x, actor.y, Level.visualHeight(actor) + 0.012)
    self.corpse:setRotation(0, 0, cameraAngle)
    self.corpse:draw(self.shader)
end

function World:setLights(fireballs, bursts, squad, viewer)
    local lights = {}
    local z = viewer.z or 0
    for _, player in ipairs(squad) do
        local muzzle = player.muzzle
        if muzzle and (muzzle.z or 0) == z then
            local strength = muzzle.strength * muzzle.remaining / World.muzzleTime
            lights[#lights + 1] = { muzzle.x, muzzle.y, strength, 4.3 }
        end
    end
    for _, burst in ipairs(bursts) do
        if #lights == 8 then
            break
        end
        if (burst.z or 0) == z then
            lights[#lights + 1] = { burst.x, burst.y, 3.6 * (1 - burst.age / Fireball.burstTime), 2.5 }
        end
    end
    for _, shot in ipairs(fireballs) do
        if #lights == 8 then
            break
        end
        if (shot.z or 0) == z then
            lights[#lights + 1] = { shot.x, shot.y, 2.2, 2.5 }
        end
    end
    for _, shader in ipairs({ self.shader, self.spriteShader }) do
        shader:send("lightCount", #lights)
        if #lights > 0 then
            shader:send("localLights", unpack(lights))
        end
    end
end

function World:render(target, viewer, squad, crates, aspect, monsters, pickups, fireballs, bursts)
    self:setLights(fireballs, bursts, squad, viewer)
    local graphics = love.graphics
    graphics.push("all")
    graphics.origin()
    graphics.setCanvas({ target, depth = true })
    graphics.clear(0.06, 0.045, 0.039, 1, false, true)
    graphics.setDepthMode()
    graphics.setColor(1, 1, 1)
    self.camera.fov = math.rad(61)
    local halfFrustum = math.tan(self.camera.fov / 2)
    local width, height = target:getDimensions()
    self.skyShader:send("resolution", { width, height })
    local forwardX, forwardY = Level.direction(viewer.heading)
    local downhill = Level.stairHeight(viewer.x, viewer.y) and forwardX < 0
    local pitch = downhill and -0.55 or -0.015
    local eyeHeight = downhill and 0.64 or 0.72
    self.skyShader:send("forward", { forwardX, forwardY })
    self.skyShader:send("frustum", { halfFrustum * aspect, halfFrustum })
    self.skyShader:send("tilt", { math.cos(pitch), math.sin(pitch) })
    graphics.setShader(self.skyShader)
    graphics.rectangle("fill", 0, 0, width, height)
    graphics.setShader()
    graphics.setDepthMode("lequal", true)
    self.camera.nearClip = 0.04
    self.camera.aspectRatio = aspect
    self.camera.updateProjectionMatrix()
    local cameraAngle = viewer.heading * math.pi / 2
    self.camera.lookInDirection(viewer.x, viewer.y, Level.visualHeight(viewer) + eyeHeight, cameraAngle, pitch)
    for name, model in pairs(self.models) do
        if name ~= "crate" and name ~= "door" and name ~= "doorFrame" and name ~= "switch" then
            self.shader:send("fixture", name == "lamp" and 1 or 0)
            self.shader:send("exterior", (name == "yard" or name == "yardWall" or name == "yardDeck") and 1 or 0)
            model:draw(self.shader)
        end
    end
    self.shader:send("fixture", 0)
    Level.eachDoor(function(door)
        self.shader:send("exterior", Level.isOutside(Level.tile(door.x, door.y, door.z)) and 1 or 0)
        local frame = self.models.doorFrame
        frame:setTranslation(door.x, door.y, door.z)
        frame:setRotation(0, 0, door.angle)
        frame:draw(self.shader)
        if not door.open then
            local panel = self.models.door
            panel:setRotation(0, 0, door.angle)
            local travel = door.travel or 0
            local offset = 0.221 + 0.44 * travel * travel * (3 - 2 * travel)
            local dx, dy = -math.sin(door.angle) * offset, math.cos(door.angle) * offset
            graphics.setColor(0.78, 0.90, 1)
            panel:setTranslation(door.x + dx, door.y + dy, door.z)
            panel:draw(self.shader)
            panel:setTranslation(door.x - dx, door.y - dy, door.z)
            panel:draw(self.shader)
            graphics.setColor(1, 1, 1)
        end
        if door.switches then
            local button = self.models.switch
            if door.locked then
                graphics.setColor(1, 0.30, 0.22)
            else
                graphics.setColor(0.30, 1, 0.48)
            end
            for _, switch in ipairs(door.switches) do
                local dx, dy = Level.direction(switch[3])
                button:setTranslation(switch[1] + dx * 0.475, switch[2] + dy * 0.475, door.z)
                button:setRotation(0, 0, switch[3] * math.pi / 2)
                button:draw(self.shader)
            end
            graphics.setColor(1, 1, 1)
        end
    end)
    for _, crate in ipairs(crates) do
        self.shader:send("exterior", Level.isOutside(Level.tile(crate.x, crate.y, crate.z)) and 1 or 0)
        self.models.crate:setTranslation(crate.x, crate.y, crate.z or 0)
        self.models.crate:draw(self.shader)
    end
    for _, pickup in ipairs(pickups) do
        local sprite = self.pickups[pickup.item.kind]
        self.shader:send("exterior", Level.isOutside(Level.tile(pickup.x, pickup.y, pickup.z)) and 1 or 0)
        sprite:setTranslation(pickup.x, pickup.y, pickup.z or 0)
        sprite:setRotation(0, 0, cameraAngle)
        sprite:draw(self.shader)
    end
    for index, player in ipairs(squad) do
        if player ~= viewer then
            if player.health == 0 then
                self:drawCorpse(player, cameraAngle)
            else
                local view = spriteView(viewer, player)
                self:drawActor(self.sprites[index][view], player, cameraAngle)
            end
        end
    end
    for _, monster in ipairs(monsters) do
        if monster.collapse == 1 then
            self:drawCorpse(monster, cameraAngle)
        else
            self:drawMonster(monster, viewer, cameraAngle)
        end
    end
    for _, shot in ipairs(fireballs) do
        local depth = (shot.x - viewer.x) * forwardX + (shot.y - viewer.y) * forwardY
        if depth >= 0.35 then
            self:drawFireball(shot.x, shot.y, shot.z, cameraAngle, 1)
        end
    end
    for _, burst in ipairs(bursts) do
        local progress = burst.age / Fireball.burstTime
        self:drawFireball(burst.x, burst.y, burst.z, cameraAngle, 0.54 + 0.37 * progress, progress)
    end
    graphics.pop()
end

function World:drawFireball(x, y, z, angle, scale, burst)
    self.fireShader:send("flicker", (love.timer.getTime() * 18) % (2 * math.pi))
    self.fireShader:send("burst", burst or -1)
    self.fireball:setTranslation(x, y, (z or 0) + 0.72)
    self.fireball:setRotation(0, 0, angle)
    self.fireball:setScale(scale)
    love.graphics.setDepthMode("lequal", false)
    self.fireball:draw(self.fireShader)
    love.graphics.setDepthMode("lequal", true)
end

function World:drawMonster(monster, viewer, cameraAngle)
    local graphics = love.graphics
    local view = spriteView(viewer, monster)
    local attack = monster.attack
    local pose = 1
    if attack and (monster.ranged or attack.released) then
        pose = 2
    end
    self.spriteShader:send("hitFlash", math.min(1, monster.hurt / 0.12) * 0.88)
    local sprites = self.enemySprites[monster.kind]
    self:drawActor(sprites[pose][view], monster, cameraAngle)
    self.spriteShader:send("hitFlash", 0)
    if monster.ranged and attack and not attack.released then
        local dx, dy = Level.direction(monster.heading)
        self:drawFireball(monster.x + dx * 0.36, monster.y + dy * 0.36, monster.z, cameraAngle, 0.38 + attack.progress * 0.53)
    elseif not monster.ranged and pose == 2 then
        local frame = math.min(#self.slashes, math.floor(attack.progress * #self.slashes) + 1)
        self.swipe.mesh:setTexture(self.slashes[frame])
        self.swipe:setTranslation((monster.x + attack.x) / 2, (monster.y + attack.y) / 2, monster.z or 0)
        self.swipe:setRotation(0, 0, cameraAngle)
        self.swipe:setScale(monster.kind == "skitterer" and 0.58 or 1)
        graphics.setColor(0.95, 0.76, 0.69)
        self.spriteShader:send("fixture", 0.27)
        self.swipe:draw(self.spriteShader)
        self.spriteShader:send("fixture", 0)
        graphics.setColor(1, 1, 1)
    end
end

function World:drawHit(x, y, width, height, remaining, clawed)
    local graphics = love.graphics
    local fade = math.min(1, remaining / 0.32)
    graphics.setColor(0.48, 0.02, 0.03, fade * 0.32)
    graphics.rectangle("fill", x, y, width, height)
    graphics.setColor(1, 0.82, 0.78, fade)
    graphics.draw(self.blood, self.bloodSplat, x + width * 0.58, y + height * 0.54, 0, height / 32, height / 32, 8, 8)
    if clawed then
        for mark = -1, 1 do
            graphics.draw(self.blood, self.scratch, x + width * 0.49 + mark * height * 0.06, y + height * 0.48 + mark * height * 0.025, 0, height / 29, height / 29, 8, 8)
        end
    end
end

function World:release()
    for name, model in pairs(self.models) do
        model.mesh:release()
        self.images[name]:release()
    end
    local function releaseSprites(sprites)
        for _, row in ipairs(sprites) do
            for _, sprite in ipairs(row) do
                sprite.mesh:release()
            end
        end
    end
    releaseSprites(self.sprites)
    for kind, atlas in pairs(self.enemyAtlases) do
        releaseSprites(self.enemySprites[kind])
        atlas:release()
    end
    self.atlas:release()
    self.corpse.mesh:release()
    self.corpseImage:release()
    for _, sprite in pairs(self.pickups) do
        sprite.mesh:release()
    end
    self.bloodSplat:release()
    self.scratch:release()
    self.blood:release()
    self.swipe.mesh:release()
    self.fireball.mesh:release()
    self.fireShader:release()
    for _, slash in ipairs(self.slashes) do
        slash:release()
    end
    self.shader:release()
    self.spriteShader:release()
    self.skyShader:release()
    self.sky:release()
end

return World
