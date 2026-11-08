local Inventory = require("src.inventory")
local Viewport = require("src.viewport")
local Panel = {}
Panel.__index = Panel
local iconBounds = {
    carbine = { 40, 95, 865, 285 },
    medkit = { 1090, 7, 560, 431 },
    carbineRounds = { 188, 459, 566, 413 },
    battery = { 1090, 476, 500, 407 },
}
local weaponIconBounds = {
    pistol = { 92, 101, 490, 367 },
    shotgun = { 618, 160, 884, 245 },
    pistolRounds = { 188, 591, 264, 386 },
    shotgunShells = { 724, 613, 692, 348 },
}

function Panel.new()
    local graphics = love.graphics
    local icons = {}
    local function loadAtlas(filename, bounds)
        local atlas = graphics.newImage("assets/sprites/" .. filename)
        atlas:setFilter("nearest", "nearest")
        local width, height = atlas:getDimensions()
        for kind, rect in pairs(bounds) do
            local x, y, w, h = unpack(rect)
            icons[kind] = { atlas = atlas, quad = graphics.newQuad(x, y, w, h, width, height) }
        end
        return atlas
    end
    return setmetatable({
        atlases = { loadAtlas("items.png", iconBounds), loadAtlas("weapon-items.png", weaponIconBounds) },
        icons = icons,
    }, Panel)
end

local function layout(x, y, w, h)
    local cell = math.floor(math.min((w - 92) / 9, (h - 92) / Inventory.rows))
    local left = x + (w - cell * 8.5 - 28) / 2
    local top = y + (h - cell * Inventory.rows) / 2 + 8
    return left, top, cell, left + cell * Inventory.columns + 28
end

local function overHand(x, y, handX, top, cell)
    return x >= handX and x < handX + cell * 2.5 and y >= top and y < top + cell * 2.4
end

local function floorBounds(handX, top, cell)
    return handX, top + cell * 2.67, cell * 2.5, cell * 1.33
end

local function overFloor(x, y, handX, top, cell)
    local left, floorY, width, height = floorBounds(handX, top, cell)
    return x >= left and x < left + width and y >= floorY and y < floorY + height
end

local function destination(drag, left, top, cell)
    return math.floor((drag.x - drag.offsetX - left) / cell + 1.5), math.floor((drag.y - drag.offsetY - top) / cell + 1.5)
end

function Panel.pick(inventory, px, py, x, y, w, h)
    local left, top, cell, handX = layout(x, y, w, h)
    if inventory.hand and overHand(px, py, handX, top, cell) then
        local hand = inventory.hand
        return { index = Inventory.handIndex, x = px, y = py, offsetX = hand.w * cell / 2, offsetY = hand.h * cell / 2 }
    end
    local index = Inventory.itemAt(inventory, math.floor((px - left) / cell) + 1, math.floor((py - top) / cell) + 1)
    if index then
        local item = inventory.items[index]
        return { index = index, x = px, y = py, offsetX = px - left - (item.x - 1) * cell, offsetY = py - top - (item.y - 1) * cell }
    end
end

function Panel.drop(inventory, drag, x, y, w, h, floorOccupied)
    local left, top, cell, handX = layout(x, y, w, h)
    if overFloor(drag.x, drag.y, handX, top, cell) then
        if not floorOccupied then
            return Inventory.take(inventory, drag.index)
        end
    elseif overHand(drag.x, drag.y, handX, top, cell) then
        if drag.index ~= Inventory.handIndex then
            return nil, Inventory.dropInHand(inventory, drag.index)
        end
    else
        Inventory.move(inventory, drag.index, destination(drag, left, top, cell))
    end
end

function Panel:drawIcon(kind, x, y, maxWidth, maxHeight, alpha)
    local g = love.graphics
    local icon = self.icons[kind]
    local quad = icon.quad
    local _, _, width, height = quad:getViewport()
    local scale = math.min(maxWidth / width, maxHeight / height)
    g.setColor(1, 1, 1, alpha)
    g.draw(icon.atlas, quad, x, y, 0, scale, scale, width / 2, height / 2)
end

local function drawItem(panel, item, x, y, cell, font, alpha)
    local g = love.graphics
    local width, height = item.w * cell, item.h * cell
    g.setColor(0.21, 0.19, 0.15, alpha)
    g.rectangle("fill", x + 2, y + 2, width - 4, height - 4)
    g.setColor(0.44, 0.37, 0.28, alpha)
    g.rectangle("line", x + 2, y + 2, width - 4, height - 4)
    panel:drawIcon(item.kind, x + width / 2, y + height * 0.40, width * 0.91, height * (item.h == 1 and 0.53 or 0.72), alpha)
    g.setColor(0.83, 0.75, 0.62, alpha)
    g.printf(item.count and string.format("%s ×%d", item.label, item.count) or item.label, font, x, y + height - font:getHeight() - 7, width, "center")
end

function Panel:draw(inventory, x, y, w, h, font, color, drag, floorOccupied)
    local g = love.graphics
    local left, top, cell, handX = layout(x, y, w, h)
    g.setColor(0.061, 0.065, 0.059)
    g.rectangle("fill", x, y, w, h)
    g.setColor(0.69, 0.65, 0.55)
    g.print("PACK", font, left, top - 29)
    g.print("IN HAND", font, handX, top - 29)
    g.setLineWidth(1)
    for row = 1, Inventory.rows do
        for col = 1, Inventory.columns do
            g.setColor(0.12, 0.12, 0.105)
            g.rectangle("fill", left + (col - 1) * cell + 1, top + (row - 1) * cell + 1, cell - 2, cell - 2)
        end
    end
    for index, item in ipairs(inventory.items) do
        drawItem(self, item, left + (item.x - 1) * cell, top + (item.y - 1) * cell, cell, font, drag and drag.index == index and 0.27 or 1)
    end

    local hand = inventory.hand
    local handWidth, handHeight = cell * 2.5, cell * 2.4
    g.setColor(0.16, 0.145, 0.12)
    g.rectangle("fill", handX, top, handWidth, handHeight)
    g.setColor(unpack(color))
    g.rectangle("line", handX, top, handWidth, handHeight)
    if hand and not (drag and drag.index == Inventory.handIndex) then
        self:drawIcon(hand.kind, handX + handWidth / 2, top + handHeight * 0.38, handWidth, handHeight * 0.73, 1)
        g.setColor(0.83, 0.75, 0.62)
        g.printf(hand.label, font, handX, top + handHeight * 0.66, handWidth, "center")
        if hand.rounds then
            g.printf(string.format("%02d / %02d", hand.rounds, hand.capacity), font, handX, top + handHeight * 0.82, handWidth, "center")
        elseif hand.count then
            g.printf(tostring(hand.count), font, handX, top + handHeight * 0.82, handWidth, "center")
        end
    end

    local floorX, floorY, floorW, floorH = floorBounds(handX, top, cell)
    local floorHovered = drag and overFloor(drag.x, drag.y, handX, top, cell)
    g.setColor(0.12, 0.115, 0.10)
    g.rectangle("fill", floorX, floorY, floorW, floorH)
    if floorHovered and floorOccupied then
        g.setColor(0.77, 0.29, 0.25)
    elseif floorHovered then
        g.setColor(unpack(color))
    else
        g.setColor(0.44, 0.37, 0.28)
    end
    g.rectangle("line", floorX, floorY, floorW, floorH)
    local cx, cy = floorX + floorW / 2, floorY + floorH * 0.39
    g.polygon("line", cx - 19, cy, cx, cy - 8, cx + 19, cy, cx, cy + 8)
    g.printf("FLOOR", font, floorX, floorY + floorH * 0.62, floorW, "center")

    if drag then
        local item = Inventory.get(inventory, drag.index)
        local col, row = destination(drag, left, top, cell)
        g.setColor(unpack(color))
        if overHand(drag.x, drag.y, handX, top, cell) then
            if drag.index ~= Inventory.handIndex and Inventory.canDropInHand(inventory, drag.index) then
                g.rectangle("line", handX + 3, top + 3, handWidth - 6, handHeight - 6)
            end
        elseif not floorHovered and Inventory.fits(inventory, drag.index, col, row) then
            g.rectangle("line", left + (col - 1) * cell, top + (row - 1) * cell, item.w * cell, item.h * cell)
        end
        Viewport.setScissor(x, y, w, h)
        drawItem(self, item, drag.x - drag.offsetX, drag.y - drag.offsetY, cell, font, 0.84)
        g.setScissor()
    end
end

function Panel:release()
    for _, icon in pairs(self.icons) do
        icon.quad:release()
    end
    for _, atlas in ipairs(self.atlases) do
        atlas:release()
    end
end

return Panel
