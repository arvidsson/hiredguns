local Level = {}

-- Map tiles are one world unit on each axis.
Level.upperZ = 1
Level.fallTime = 0.42
Level.doorTime = 0.5

local stairs = {
    { row = 14, col = 23 },
    { row = 11, col = 4, indoor = true },
}

local doors = {
    { x = 7.5, y = 3.5, z = 0, angle = 0 },
    {
        x = 10.5,
        y = 5.5,
        z = 0,
        angle = math.pi / 2,
        switches = { { 9.5, 4.5, 1 }, { 9.5, 6.5, 3 } },
        locked = true,
    },
    { x = 21.5, y = 8.5, z = 0, angle = 0 },
    {
        x = 25.5,
        y = 12.5,
        z = Level.upperZ,
        angle = 0,
        switches = { { 24.5, 12.5, 3 }, { 26.5, 12.5, 3 } },
        locked = true,
    },
}

function Level.doorAt(x, y, z)
    local col, row = math.floor(x), math.floor(y)
    for _, door in ipairs(doors) do
        if door.z == (z or 0) and math.floor(door.x) == col and math.floor(door.y) == row then
            return door
        end
    end
end

function Level.eachDoor(visit)
    for _, door in ipairs(doors) do
        visit(door)
    end
end

function Level.resetDoors()
    Level.eachDoor(function(door)
        door.open = false
        door.travel = 0
        door.moving = nil
        door.locked = door.switches ~= nil
    end)
end

local function closedDoor(x, y, z)
    local door = Level.doorAt(x, y, z)
    return door and not door.open
end

local function stairAt(x, y)
    local col, row = math.floor(x), math.floor(y)
    for _, stair in ipairs(stairs) do
        if row == stair.row and col == stair.col then
            return stair
        end
    end
end

function Level.indoorStair(x, y)
    local stair = stairAt(x, y)
    return stair and stair.indoor
end

function Level.stairSideWall(x, y)
    return stairAt(x, y - 1) ~= nil or stairAt(x, y + 1) ~= nil
end

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
    "#...#..#.....#......##OBOOO###OBOOO#",
    "###.S#####.######.####OOOOOOOOOOOOO#",
    "#...#..#.....#......##OOOOO##OOOOOO#",
    "#..C...#.....#...C..##O#OOO##OOOOOO#",
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
    { 32.5, 13.5, "medkit", nil, Level.upperZ },
}

-- Each successive heading is a quarter turn to the left.
local headings = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }

function Level.dimensions()
    return #map[1], #map
end

function Level.direction(heading)
    return unpack(headings[heading % 4 + 1])
end

function Level.stairHeight(x, y)
    if stairAt(x, y) then
        return Level.upperZ / 2
    end
end

function Level.tile(x, y, z)
    if z == Level.upperZ then
        local col, row = math.floor(x), math.floor(y)
        if col <= 33 and ((row == 14 and col >= 24) or (row == 13 and col >= 29)) then
            return "O"
        end
        if (row == 11 and col >= 5 and col <= 22) or (row == 12 and col >= 22 and col <= 29) or (row == 10 and col >= 10 and col <= 12) then
            return "S"
        end
        return "#"
    end
    local row = map[math.floor(y) + 1]
    local col = math.floor(x) + 1
    return row and col >= 1 and col <= #row and row:sub(col, col) or "#"
end

function Level.upperWall(x, y, nextX, nextY)
    return Level.tile(x, y, Level.upperZ) == "S" and Level.tile(nextX, nextY, Level.upperZ) == "#" and not Level.indoorStair(nextX, nextY)
end

function Level.walkable(x, y, z)
    return not closedDoor(x, y, z) and Level.tile(x, y, z) ~= "#" and (z == Level.upperZ or not Level.stairHeight(x, y))
end

-- Combat traces stay horizontal, so a tread blocks a trace only if it reaches that height.
function Level.blocksShot(x, y, z, fromX, fromY)
    if closedDoor(x, y, z) then
        return true
    end
    if z == Level.upperZ then
        return Level.stairSideWall(x, y) or Level.upperWall(fromX, fromY, x, y) or Level.upperWall(x, y, fromX, fromY)
    end
    return Level.tile(x, y) == "#" or (Level.stairHeight(x, y) or 0) >= (z or 0) + 0.72
end

function Level.isOutside(tile)
    return tile == "O" or tile == "B"
end

function Level.eachTile(visit, z)
    for y, row in ipairs(map) do
        for x = 1, #row do
            visit(x - 1, y - 1, Level.tile(x - 1, y - 1, z))
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

function Level.livingAt(actors, x, y, z)
    for _, actor in ipairs(actors) do
        if actor.health > 0 and actor.x == x and actor.y == y and (actor.z or 0) == (z or 0) then
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

function Level.occupantAt(occupants, x, y, z)
    for index, occupant in ipairs(occupants) do
        if occupant.x == x and occupant.y == y and (occupant.z or 0) == (z or 0) then
            return occupant, index
        end
    end
end

function Level.pressDoorSwitch(player)
    for _, door in ipairs(doors) do
        if door.switches and door.z == (player.z or 0) then
            for _, switch in ipairs(door.switches) do
                if player.x == switch[1] and player.y == switch[2] and player.heading == switch[3] then
                    if not door.open and not door.moving then
                        door.locked = not door.locked
                    end
                    return true
                end
            end
        end
    end
end

function Level.toggleDoor(player, squad, crates, monsters)
    local dx, dy = Level.direction(player.heading)
    local door = Level.doorAt(player.x + dx, player.y + dy, player.z)
    if not door or door.moving or door.locked then
        return
    end
    local x, y, z = door.x, door.y, door.z
    if door.open and (Level.livingAt(squad, x, y, z) or Level.livingAt(monsters, x, y, z) or Level.occupantAt(crates, x, y, z)) then
        return
    end
    door.moving = door.open and -1 or 1
    door.open = false
    return door.moving == 1 and "door_open" or "door_close"
end

function Level.updateDoors(dt)
    local opened = false
    for _, door in ipairs(doors) do
        if door.moving then
            door.travel = math.max(0, math.min(1, door.travel + door.moving * dt / Level.doorTime))
            if door.travel == 0 or door.travel == 1 then
                door.open = door.travel == 1
                door.moving = nil
                opened = opened or door.open
            end
        end
    end
    return opened
end

function Level.clearTile(x, y, crates, z)
    return Level.walkable(x, y, z) and not Level.occupantAt(crates, x, y, z)
end

function Level.hasLineOfSight(start, target, crates, seeBlocker)
    local z = start.z or 0
    if not seeBlocker and z ~= (target.z or 0) then
        return false
    end
    local function clear(x, y, fromX, fromY)
        if seeBlocker then
            return Level.tile(x, y, z) ~= "#" and not closedDoor(x, y, z) and not Level.occupantAt(crates, x, y, z)
        end
        return not Level.blocksShot(x, y, z, fromX, fromY) and not Level.occupantAt(crates, x, y, z)
    end
    local x, y = start.x, start.y
    local dx, dy = target.x - x, target.y - y
    local sx, sy = dx < 0 and -1 or 1, dy < 0 and -1 or 1
    local unitX, unitY = 1 / math.abs(dx), 1 / math.abs(dy)
    local nextX, nextY = unitX / 2, unitY / 2
    while x ~= target.x or y ~= target.y do
        local fromX, fromY = x, y
        if math.abs(nextX - nextY) < 1e-9 then
            if not clear(x + sx, y, x, y) or not clear(x, y + sy, x, y) then
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
        if not clear(x, y, fromX, fromY) then
            return false
        end
    end
    return true
end

function Level.crateAhead(player, crates)
    local dx, dy = Level.direction(player.heading)
    return Level.occupantAt(crates, player.x + dx, player.y + dy, player.z)
end

local function stepHeight(player, x, y)
    local z = player.z or 0
    local fromStair, toStair = stairAt(player.x, player.y), stairAt(x, y)
    if fromStair then
        if y == player.y then
            return math.floor(x) < fromStair.col and 0 or Level.upperZ
        end
        return
    end
    if toStair and y == player.y then
        local fromCol = math.floor(player.x)
        if (fromCol == toStair.col - 1 and z == 0) or (fromCol == toStair.col + 1 and z == Level.upperZ) then
            return Level.stairHeight(x, y)
        end
    end
    if Level.walkable(x, y, z) then
        return z
    end
    if z == Level.upperZ and Level.isOutside(Level.tile(player.x, player.y, z)) and Level.isOutside(Level.tile(x, y, 0)) and Level.walkable(x, y, 0) then
        return 0, true
    end
end

function Level.visualHeight(actor)
    if actor.fall then
        local progress = 1 - actor.fall / Level.fallTime
        return Level.upperZ * (1 - progress * progress)
    end
    return actor.z or 0
end

function Level.step(player, squad, crates, relativeHeading, shift, monsters)
    if player.fall then
        return
    end
    local dx, dy = Level.direction(player.heading + relativeHeading)
    local x, y = player.x + dx, player.y + dy
    local z, falling = stepHeight(player, x, y)
    if not z or Level.livingAt(monsters, x, y, z) then
        return
    end

    local teammate = Level.livingAt(squad, x, y, z)
    local crate = Level.occupantAt(crates, x, y, z)
    if falling and (teammate or crate) then
        return
    end
    if teammate then
        if teammate.fall then
            return
        end
        teammate.x, teammate.y, teammate.z = player.x, player.y, player.z
        player.x, player.y, player.z = x, y, z
        return teammate
    end

    local movedCrate
    if crate then
        local nextX, nextY = x + dx, y + dy
        if
            not (shift and relativeHeading == 0 and Level.walkable(nextX, nextY, z))
            or not Level.walkable(x, y, z)
            or Level.occupantAt(crates, nextX, nextY, z)
            or Level.livingAt(squad, nextX, nextY, z)
            or Level.livingAt(monsters, nextX, nextY, z)
        then
            return
        end
        crate.x, crate.y = nextX, nextY
        movedCrate = crate
    elseif shift and relativeHeading == 2 and z == (player.z or 0) and Level.walkable(player.x, player.y, z) then
        local ahead = Level.crateAhead(player, crates)
        if ahead then
            ahead.x, ahead.y = player.x, player.y
            movedCrate = ahead
        end
    end
    player.x, player.y, player.z = x, y, z
    player.fall = falling and Level.fallTime or nil
    return nil, movedCrate
end

return Level
