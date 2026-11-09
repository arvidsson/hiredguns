local Level = require("src.level")
local Exploration = require("src.exploration")
local DepotMap = {}

local colors = {
    ["#"] = { 0.27, 0.24, 0.20 },
    ["."] = { 0.13, 0.15, 0.14 },
    O = { 0.25, 0.27, 0.19 },
    S = { 0.16, 0.20, 0.23 },
    C = { 0.42, 0.27, 0.17 },
    T = { 0.57, 0.42, 0.19 },
    R = { 0.32, 0.54, 0.56 },
    D = { 0.68, 0.43, 0.22 },
}
local legend = { { "#", "WALL" }, { "C", "CRATE" }, { "T", "HAZARD" }, { "O", "YARD" }, { "S", "SERVICE" }, { "R", "STAIRS" }, { "D", "DOOR" } }

function DepotMap.draw(x, y, width, height, squad, crates, selected, font, explored)
    local graphics = love.graphics
    local upper = squad[selected].z == Level.upperZ
    local floor = upper and Level.upperZ or 0
    local columns, rows = Level.dimensions()
    local tileSize = math.floor(math.min((width - 64) / columns, (height - 70) / rows))
    local left = x + (width - columns * tileSize) / 2
    local top = y + (height - rows * tileSize) / 2

    graphics.setColor(0.061, 0.065, 0.059)
    graphics.rectangle("fill", x, y, width, height)
    graphics.setColor(0.69, 0.65, 0.55)
    graphics.print(upper and "DEPOT MAP / UPPER" or "DEPOT MAP / GROUND", font, x + 18, y + 12)
    for index, entry in ipairs(legend) do
        local legendX, legendY = x + 18 + (index - 1) * (width - 36) / #legend, y + height - 27
        graphics.setColor(unpack(colors[entry[1]]))
        graphics.rectangle("fill", legendX, legendY + 4, 13, 13)
        graphics.setColor(0.69, 0.65, 0.55)
        graphics.print(entry[2], font, legendX + 19, legendY)
    end

    Level.eachTile(function(col, row, tile)
        local stair = Level.stairHeight(col, row)
        if stair and Exploration.seen(explored, col, row, 0) then
            tile = "R"
        elseif (upper and tile == "#") or not Exploration.seen(explored, col, row, floor) then
            return
        end
        local ground = tile == "C" and "." or tile == "B" and "O" or tile
        graphics.setColor(unpack(colors[ground]))
        graphics.rectangle("fill", left + col * tileSize, top + (rows - 1 - row) * tileSize, tileSize - 1, tileSize - 1)
        local door = Level.doorAt(col, row, floor)
        if door then
            graphics.setColor(unpack(colors.D))
            graphics.rectangle(door.open and "line" or "fill", left + col * tileSize + 2, top + (rows - 1 - row) * tileSize + 2, tileSize - 5, tileSize - 5)
        end
    end, floor)

    graphics.setColor(unpack(colors.C))
    for _, crate in ipairs(crates) do
        if (crate.z or 0) == floor and Exploration.seen(explored, crate.x, crate.y, floor) then
            local px = left + (crate.x - 0.5) * tileSize
            local py = top + (rows - crate.y - 0.5) * tileSize
            graphics.rectangle("fill", px, py, tileSize - 1, tileSize - 1)
        end
    end

    for index, player in ipairs(squad) do
        if (player.z == Level.upperZ) ~= upper then
            goto continue
        end
        local px, py = left + player.x * tileSize, top + (rows - player.y) * tileSize
        local dx, dy = Level.direction(player.heading)
        dy = -dy
        graphics.setColor(unpack(player.color))
        if selected == index then
            graphics.setLineWidth(1)
            graphics.circle("line", px, py, tileSize * 0.47)
        end
        local tip, back, wing = tileSize * 0.37, tileSize * 0.24, tileSize * 0.25
        graphics.polygon("fill", px + dx * tip, py + dy * tip, px - dx * back - dy * wing, py - dy * back + dx * wing, px - dx * back + dy * wing, py - dy * back - dx * wing)
        ::continue::
    end
end

return DepotMap
