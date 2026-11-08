local Level = require("src.level")
local Exploration = {}

local radius = 4

function Exploration.seen(explored, x, y)
    local row = explored[math.floor(y)]
    return row and row[math.floor(x)] == true
end

function Exploration.reveal(explored, squad, crates)
    local width, height = Level.dimensions()
    for _, player in ipairs(squad) do
        if player.health > 0 then
            local col, row = math.floor(player.x), math.floor(player.y)
            for y = math.max(0, row - radius), math.min(height - 1, row + radius) do
                explored[y] = explored[y] or {}
                for x = math.max(0, col - radius), math.min(width - 1, col + radius) do
                    if not explored[y][x] and (x - col) ^ 2 + (y - row) ^ 2 <= radius ^ 2 and Level.hasLineOfSight(player, { x = x + 0.5, y = y + 0.5 }, crates, true) then
                        explored[y][x] = true
                    end
                end
            end
        end
    end
end

return Exploration
