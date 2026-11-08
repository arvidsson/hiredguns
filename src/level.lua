local Level = {}

local map = {
    "####################################",
    "#......#.....#......#####SSSSSS#####",
    "#..C...#.....#...C..#####SCSSSS#####",
    "#.......................SSSSSSS#####",
    "#......#.....#......#####SSSSSS#####",
    "###.######.######.#########S########",
    "#......#.....#......##OOOOOOOOOOO###",
    "#..C...#..C..#...C..##OOO##OOOOOOOO#",
    "#......T.....T.........OOOOOOOBOOOO#",
    "#..C...#.....#...C..##OOOOO###OOOOO#",
    "#......#.....#......##OBOOO###OBOOO#",
    "###.######.######.####OOOOOOOOOOOOO#",
    "#......#.....#......##OOOOO##OOOOOO#",
    "#..C...#.....#...C..##OOOOO##OOOOOO#",
    "#......................OOOOOOOOOOOS#",
    "#......#.....#......########O####SS#",
    "##########S######S##########S####SS#",
    "##########SSSCSSSSSS#######SSSS#SS##",
    "##########SSSSS#SSSSSSSSSSSSSCSSSS##",
    "##########SSSSSSSCSS#######SSSTSSS##",
    "####################################",
}

Level.spawns = {
    { 2.5, 3.5, 0, "RHEA", "SCOUT", { 0.87, 0.60, 0.28 }, "pistol" },
    { 4.5, 3.5, 2, "HOLT", "BREACH", { 0.84, 0.39, 0.33 }, "shotgun" },
    { 2.5, 2.5, 1, "VESPER", "TECH", { 0.37, 0.75, 0.69 } },
    { 2.5, 4.5, 3, "KELL", "HEAVY", { 0.61, 0.69, 0.87 } },
}

Level.monsterSpawns = {
    { 28.5, 2.5, 2, "melee", { { 29.5, 2.5 }, { 29.5, 4.5 }, { 27.5, 4.5 }, { 27.5, 2.5 } } },
    { 16.5, 14.5, 2, "melee", { { 18.5, 14.5 }, { 18.5, 12.5 }, { 15.5, 12.5 }, { 15.5, 14.5 } } },
    { 29.5, 7.5, 1 },
    { 31.5, 13.5, 2 },
    { 13.5, 18.5, 0 },
    { 26.5, 3.5, 2, "ranged" },
    { 30.5, 11.5, 2, "ranged", { { 33.5, 11.5 }, { 33.5, 14.5 }, { 30.5, 14.5 }, { 30.5, 11.5 } } },
    { 11.5, 8.5, 2, "skitterer" },
    { 24.5, 13.5, 3, "skitterer" },
}

Level.lootSpawns = {
    { 3.5, 3.5, "medkit" },
    { 6.5, 3.5, "carbineRounds", 6 },
    { 10.5, 8.5, "carbineRounds", 12 },
    { 24.5, 11.5, "medkit" },
    { 32.5, 14.5, "carbineRounds", 12 },
    { 12.5, 18.5, "battery" },
    { 28.5, 18.5, "carbine" },
    { 9.5, 3.5, "pistol" },
    { 17.5, 14.5, "shotgun" },
    { 15.5, 8.5, "pistolRounds", 9 },
    { 25.5, 11.5, "shotgunShells", 8 },
    { 18.5, 18.5, "pistolRounds", 18 },
    { 31.5, 18.5, "shotgunShells", 8 },
}

-- Each successive heading is a quarter turn to the left.
local headings = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }

function Level.dimensions()
    return #map[1], #map
end

function Level.direction(heading)
    return unpack(headings[heading % 4 + 1])
end

function Level.tile(x, y)
    local row = map[math.floor(y) + 1]
    local col = math.floor(x) + 1
    return row and col >= 1 and col <= #row and row:sub(col, col) or "#"
end

function Level.walkable(x, y)
    return Level.tile(x, y) ~= "#"
end

function Level.isOutside(tile)
    return tile == "O" or tile == "B"
end

function Level.eachTile(visit)
    for y, row in ipairs(map) do
        for x = 1, #row do
            visit(x - 1, y - 1, row:sub(x, x))
        end
    end
end

function Level.newCrates()
    local crates = {}
    Level.eachTile(function(x, y, tile)
        if tile == "C" or tile == "B" then
            crates[#crates + 1] = { x = x + 0.5, y = y + 0.5 }
        end
    end)
    return crates
end

function Level.livingAt(actors, x, y)
    for _, actor in ipairs(actors) do
        if actor.health > 0 and actor.x == x and actor.y == y then
            return actor
        end
    end
end

function Level.hurtOperative(player, damage, clawed)
    player.health = math.max(0, player.health - damage)
    if player.health == 0 then
        player.hit = nil
    else
        player.hit = 0.42
        player.clawed = clawed
    end
end

function Level.occupantAt(occupants, x, y)
    for index, occupant in ipairs(occupants) do
        if occupant.x == x and occupant.y == y then
            return occupant, index
        end
    end
end

function Level.clearTile(x, y, crates)
    return Level.walkable(x, y) and not Level.occupantAt(crates, x, y)
end

function Level.hasLineOfSight(start, target, crates, seeBlocker)
    local x, y = start.x, start.y
    local dx, dy = target.x - x, target.y - y
    local sx, sy = dx < 0 and -1 or 1, dy < 0 and -1 or 1
    local unitX, unitY = 1 / math.abs(dx), 1 / math.abs(dy)
    local nextX, nextY = unitX / 2, unitY / 2
    while x ~= target.x or y ~= target.y do
        if math.abs(nextX - nextY) < 1e-9 then
            if not Level.clearTile(x + sx, y, crates) or not Level.clearTile(x, y + sy, crates) then
                return false
            end
            x, y = x + sx, y + sy
            nextX, nextY = nextX + unitX, nextY + unitY
        elseif nextX < nextY then
            x, nextX = x + sx, nextX + unitX
        else
            y, nextY = y + sy, nextY + unitY
        end
        if seeBlocker and x == target.x and y == target.y then
            return true
        end
        if not Level.clearTile(x, y, crates) then
            return false
        end
    end
    return true
end

function Level.crateAhead(player, crates)
    local dx, dy = Level.direction(player.heading)
    return Level.occupantAt(crates, player.x + dx, player.y + dy)
end

function Level.step(player, squad, crates, relativeHeading, shift, monsters)
    local dx, dy = Level.direction(player.heading + relativeHeading)
    local x, y = player.x + dx, player.y + dy
    if not Level.walkable(x, y) or Level.livingAt(monsters, x, y) then
        return
    end

    local teammate = Level.livingAt(squad, x, y)
    if teammate then
        teammate.x, teammate.y = player.x, player.y
        player.x, player.y = x, y
        return teammate
    end

    local movedCrate
    local crate = Level.occupantAt(crates, x, y)
    if crate then
        local nextX, nextY = x + dx, y + dy
        if
            not (shift and relativeHeading == 0 and Level.walkable(nextX, nextY))
            or Level.occupantAt(crates, nextX, nextY)
            or Level.livingAt(squad, nextX, nextY)
            or Level.livingAt(monsters, nextX, nextY)
        then
            return
        end
        crate.x, crate.y = nextX, nextY
        movedCrate = crate
    elseif shift and relativeHeading == 2 then
        local ahead = Level.crateAhead(player, crates)
        if ahead then
            ahead.x, ahead.y = player.x, player.y
            movedCrate = ahead
        end
    end
    player.x, player.y = x, y
    return nil, movedCrate
end

return Level
