local Level = require("src.level")
local Fireball = { range = 8, burstTime = 0.25 }
local tileTime = 0.17

function Fireball.new(caster)
    local dx, dy = Level.direction(caster.heading)
    return { x = caster.x, y = caster.y, dx = dx, dy = dy, time = 0, crossed = 0 }
end

local function impact(shot, squad, crates, monsters)
    local blocked = not Level.walkable(shot.x, shot.y) or Level.occupantAt(crates, shot.x, shot.y) or Level.livingAt(monsters, shot.x, shot.y)
    local victim = Level.livingAt(squad, shot.x, shot.y)
    if victim then
        Level.hurtOperative(victim, 24)
    end
    if blocked or victim then
        local x, y = shot.x - shot.dx * 0.57, shot.y - shot.dy * 0.57
        return false, victim, { x = x, y = y, age = 0 }
    end
    return true
end

function Fireball.update(shot, squad, crates, monsters, dt)
    if shot.crossed > 0 then
        local active, victim, burst = impact(shot, squad, crates, monsters)
        if not active then
            return false, victim, burst
        end
    end
    shot.time = shot.time + dt
    while shot.time >= tileTime do
        if shot.crossed == Fireball.range then
            return false
        end
        shot.time = shot.time - tileTime
        shot.x, shot.y = shot.x + shot.dx, shot.y + shot.dy
        shot.crossed = shot.crossed + 1
        local active, victim, burst = impact(shot, squad, crates, monsters)
        if not active then
            return false, victim, burst
        end
    end
    return true
end

return Fireball
