local Level = require("src.level")
local Fireball = require("src.fireball")
local Monster = {}

local profiles = {
    melee = { health = 100, step = 0.34, windup = 0.32, strike = 0.18, recovery = 0.58, damage = 20 },
    ranged = { health = 100, step = 0.34, windup = 0.72, strike = 0.18, recovery = 1.12 },
    skitterer = { health = 30, step = 0.17, windup = 0.15, strike = 0.14, recovery = 0.26, damage = 12 },
}

function Monster.new(x, y, heading, kind, patrol)
    kind = kind or "melee"
    return {
        x = x,
        y = y,
        heading = heading,
        timer = 0,
        health = profiles[kind].health,
        hurt = 0,
        kind = kind,
        ranged = kind == "ranged",
        home = { x = x, y = y },
        patrol = patrol,
        waypoint = 1,
        detourDelay = 0,
    }
end

function Monster.hurt(monster, damage, attacker)
    monster.health = math.max(0, monster.health - damage)
    monster.hurt = 0.17
    if monster.health == 0 then
        monster.attack, monster.target, monster.shotBy = nil, nil, nil
        monster.collapse = 0
    elseif attacker then
        if not monster.target and not monster.attack then
            monster.timer = 0
        end
        monster.target, monster.shotBy = attacker, attacker
    end
end

local function distance(x, y, target)
    return math.abs(x - target.x) + math.abs(y - target.y)
end

local function firingLane(x, y, target)
    local d = distance(x, y, target)
    return d > 0 and d <= Fireball.range and (x == target.x or y == target.y)
end

local function canEnter(x, y, squad, crates, monsters)
    return Level.clearTile(x, y, crates) and not Level.livingAt(squad, x, y) and not Level.livingAt(monsters, x, y)
end

local function canSee(monster, player, crates)
    local dx, dy = player.x - monster.x, player.y - monster.y
    return dx * dx + dy * dy <= 81 and Level.hasLineOfSight(monster, player, crates)
end

local function nearestVisible(monster, squad, crates)
    local best, bestScore
    for _, player in ipairs(squad) do
        local d = distance(monster.x, monster.y, player)
        local score = monster.ranged and firingLane(monster.x, monster.y, player) and d - 20 or d
        if player.health > 0 and (not bestScore or score < bestScore) and canSee(monster, player, crates) then
            best, bestScore = player, score
        end
    end
    return best
end

local function route(start, goal, squad, crates, monsters, seekLane, maxSteps)
    local width = Level.dimensions()
    local function key(x, y)
        return math.floor(y) * width + math.floor(x)
    end
    local queue = { { x = start.x, y = start.y, steps = 0 } }
    local seen = { [key(start.x, start.y)] = true }
    local range = Level.livingAt(squad, goal.x, goal.y) and 1 or 0
    local head = 1
    while head <= #queue do
        local tile = queue[head]
        head = head + 1
        if seekLane and firingLane(tile.x, tile.y, goal) and canSee(tile, goal, crates) then
            return tile.first, tile.steps
        elseif not seekLane and distance(tile.x, tile.y, goal) <= range then
            return tile.first, tile.steps
        end
        if not maxSteps or tile.steps < maxSteps then
            for heading = 0, 3 do
                local dx, dy = Level.direction(heading)
                local x, y = tile.x + dx, tile.y + dy
                if not seen[key(x, y)] and canEnter(x, y, squad, crates, monsters) then
                    seen[key(x, y)] = true
                    queue[#queue + 1] = { x = x, y = y, first = tile.first or heading, steps = tile.steps + 1 }
                end
            end
        end
    end
end

local function chase(monster, squad, crates, monsters, seekLane)
    local goal = monster.target
    local shortest, length = route(monster, goal, squad, crates, monsters, seekLane)
    if monster.detourDelay > 0 then
        monster.detourDelay = monster.detourDelay - 1
        return shortest
    end
    if not shortest or length < 2 or love.math.random(6) ~= 1 then
        return shortest
    end

    local choices = {}
    for heading = 0, 3 do
        local dx, dy = Level.direction(heading)
        local x, y = monster.x + dx, monster.y + dy
        if heading ~= shortest and (x ~= monster.previousX or y ~= monster.previousY) and canEnter(x, y, squad, crates, monsters) then
            -- The occupied starting tile is excluded from the alternate route.
            local _, remaining = route({ x = x, y = y }, goal, squad, crates, monsters, seekLane, length + 1)
            if remaining then
                choices[#choices + 1] = heading
            end
        end
    end
    if #choices > 0 then
        monster.detourDelay = 4
        return choices[love.math.random(#choices)]
    end
    return shortest
end

local function idleHeading(monster, squad, crates, monsters)
    local patrol = monster.patrol
    if patrol then
        local point = patrol[monster.waypoint]
        if monster.x == point[1] and monster.y == point[2] then
            monster.waypoint = monster.waypoint % #patrol + 1
            point = patrol[monster.waypoint]
        end
        local heading = route(monster, { x = point[1], y = point[2] }, squad, crates, monsters)
        if not heading then
            monster.waypoint = monster.waypoint % #patrol + 1
        end
        return heading
    end

    local home = monster.home
    if distance(monster.x, monster.y, home) > 4 then
        return route(monster, home, squad, crates, monsters)
    end
    local choices, backtrack = {}, nil
    for heading = 0, 3 do
        local dx, dy = Level.direction(heading)
        local x, y = monster.x + dx, monster.y + dy
        if distance(x, y, home) <= 4 and canEnter(x, y, squad, crates, monsters) then
            if x == monster.previousX and y == monster.previousY then
                backtrack = heading
            else
                choices[#choices + 1] = heading
            end
        end
    end
    return #choices > 0 and choices[love.math.random(#choices)] or backtrack
end

function Monster.update(monster, squad, crates, monsters, dt)
    monster.hurt = math.max(0, monster.hurt - dt)
    if monster.health == 0 then
        monster.collapse = math.min(1, monster.collapse + dt / 0.45)
        return
    end
    local profile = profiles[monster.kind]
    monster.timer = monster.timer - dt
    if monster.timer > 0 then
        if monster.attack then
            local duration = monster.attack.released and profile.strike or profile.windup
            monster.attack.progress = 1 - monster.timer / duration
        end
        return
    end

    if monster.attack then
        local attack = monster.attack
        if not attack.released then
            attack.released = true
            attack.progress = 0
            monster.timer = profile.strike
            if monster.ranged then
                return "fireball"
            end
            local victim = Level.livingAt(squad, attack.x, attack.y)
            if victim then
                Level.hurtOperative(victim, profile.damage, true)
                return "swipe", victim
            end
            return "swipe"
        else
            monster.attack = nil
            monster.timer = profile.recovery
        end
        return
    end

    if monster.shotBy and monster.shotBy.health == 0 then
        monster.shotBy = nil
    end
    local player
    if monster.shotBy then
        if canSee(monster, monster.shotBy, crates) then
            player = monster.shotBy
        end
    else
        player = nearestVisible(monster, squad, crates)
    end
    if player then
        monster.target = player
        local inRange = monster.ranged and firingLane(monster.x, monster.y, player) or distance(monster.x, monster.y, player) == 1
        if inRange then
            if player.x == monster.x then
                monster.heading = player.y > monster.y and 1 or 3
            else
                monster.heading = player.x > monster.x and 0 or 2
            end
            monster.attack = { x = player.x, y = player.y, progress = 0 }
            monster.timer = profile.windup
            return
        end
    elseif monster.target and monster.target.health == 0 then
        monster.target = nil
    end

    -- Once alerted, follow the operative around cover. Only visible targets can be attacked.
    local heading
    if monster.target then
        heading = chase(monster, squad, crates, monsters, monster.ranged and player ~= nil)
    else
        heading = idleHeading(monster, squad, crates, monsters)
    end
    if heading then
        local dx, dy = Level.direction(heading)
        monster.previousX, monster.previousY = monster.x, monster.y
        monster.x, monster.y = monster.x + dx, monster.y + dy
        monster.heading = heading
        monster.timer = monster.target and profile.step or 0.65 + love.math.random() * 0.4
    else
        monster.timer = monster.target and 0.12 or 0.65
    end
end

return Monster
