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
}
local legend = { { "#", "WALL" }, { "C", "CRATE" }, { "T", "HAZARD" }, { "O", "YARD" }, { "S", "SERVICE" } }

function DepotMap.draw(x, y, width, height, squad, crates, selected, font, explored)
    local graphics = love.graphics
    local columns, rows = Level.dimensions()
    local tileSize = math.floor(math.min((width - 64) / columns, (height - 70) / rows))
    local left = x + (width - columns * tileSize) / 2
    local top = y + (height - rows * tileSize) / 2

    graphics.setColor(0.061, 0.065, 0.059)
    graphics.rectangle("fill", x, y, width, height)
    graphics.setColor(0.69, 0.65, 0.55)
    graphics.print("DEPOT MAP", font, x + 18, y + 12)
    for index, entry in ipairs(legend) do
        local legendX, legendY = x + width - 559 + (index - 1) * 112, y + height - 27
        graphics.setColor(unpack(colors[entry[1]]))
        graphics.rectangle("fill", legendX, legendY + 4, 13, 13)
        graphics.setColor(0.69, 0.65, 0.55)
        graphics.print(entry[2], font, legendX + 19, legendY)
    end

    Level.eachTile(function(col, row, tile)
        if not Exploration.seen(explored, col, row) then
            return
        end
        local ground = tile == "C" and "." or tile == "B" and "O" or tile
        graphics.setColor(unpack(colors[ground]))
        graphics.rectangle("fill", left + col * tileSize, top + (rows - 1 - row) * tileSize, tileSize - 1, tileSize - 1)
    end)

    graphics.setColor(unpack(colors.C))
    for _, crate in ipairs(crates) do
        if Exploration.seen(explored, crate.x, crate.y) then
            local px = left + (crate.x - 0.5) * tileSize
            local py = top + (rows - crate.y - 0.5) * tileSize
            graphics.rectangle("fill", px, py, tileSize - 1, tileSize - 1)
        end
    end

    for index, player in ipairs(squad) do
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
    end
end

return DepotMap
