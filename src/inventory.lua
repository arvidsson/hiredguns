local Weapon = require("src.weapon")
local Inventory = { columns = 6, rows = 4, handIndex = 0 }

local items = {
    carbineRounds = { label = "5.56", count = 6, w = 1, h = 2, ammoStack = true },
    pistolRounds = { label = "9MM", count = 9, w = 1, h = 1, ammoStack = true },
    shotgunShells = { label = "12GA", count = 4, w = 1, h = 2, ammoStack = true },
    medkit = { label = "MEDKIT", w = 2, h = 2 },
    battery = { label = "CELL", w = 1, h = 1 },
}

function Inventory.newItem(kind, count, x, y)
    local weapon = Weapon.types[kind]
    if weapon then
        return { kind = kind, x = x, y = y, label = weapon.label, ammo = weapon.ammo, capacity = weapon.capacity, rounds = weapon.capacity, w = weapon.w, h = weapon.h }
    end
    local item = { kind = kind, x = x, y = y }
    for key, value in pairs(items[kind]) do
        item[key] = value
    end
    item.count = count or item.count
    return item
end

function Inventory.new(kind)
    local hand = Inventory.newItem(kind or "carbine")
    return {
        hand = hand,
        items = {
            Inventory.newItem(hand.ammo, hand.capacity * 2, 1, 1),
            Inventory.newItem(hand.ammo, hand.capacity, 2, 1),
            Inventory.newItem("medkit", nil, 4, 1),
            Inventory.newItem("battery", nil, 1, 4),
        },
    }
end

function Inventory.itemAt(inventory, x, y)
    for index, item in ipairs(inventory.items) do
        if x >= item.x and x < item.x + item.w and y >= item.y and y < item.y + item.h then
            return index
        end
    end
end

local function fits(inventory, item, x, y, skip)
    if x < 1 or y < 1 or x + item.w - 1 > Inventory.columns or y + item.h - 1 > Inventory.rows then
        return false
    end
    for otherIndex, other in ipairs(inventory.items) do
        if otherIndex ~= skip and x < other.x + other.w and x + item.w > other.x and y < other.y + other.h and y + item.h > other.y then
            return false
        end
    end
    return true
end

local function firstSpace(inventory, item, skip)
    for y = 1, Inventory.rows - item.h + 1 do
        for x = 1, Inventory.columns - item.w + 1 do
            if fits(inventory, item, x, y, skip) then
                return x, y
            end
        end
    end
end

function Inventory.hasSpace(inventory, item)
    return firstSpace(inventory, item) ~= nil
end

function Inventory.add(inventory, item)
    local x, y = firstSpace(inventory, item)
    if x then
        item.x, item.y = x, y
        inventory.items[#inventory.items + 1] = item
        return true
    end
    return false
end

function Inventory.fits(inventory, index, x, y)
    return fits(inventory, Inventory.get(inventory, index), x, y, index)
end

function Inventory.get(inventory, index)
    if index == Inventory.handIndex then
        return inventory.hand
    end
    return inventory.items[index]
end

function Inventory.take(inventory, index)
    if index == Inventory.handIndex then
        local item = inventory.hand
        inventory.hand = nil
        return item
    end
    return table.remove(inventory.items, index)
end

function Inventory.move(inventory, index, x, y)
    if Inventory.fits(inventory, index, x, y) then
        local item = Inventory.get(inventory, index)
        item.x, item.y = x, y
        if index == Inventory.handIndex then
            inventory.items[#inventory.items + 1] = Inventory.take(inventory, index)
        end
    end
end

local function reload(inventory, index)
    local item, hand = inventory.items[index], inventory.hand
    local rounds = math.min(item.count, hand.capacity - hand.rounds)
    hand.rounds, item.count = hand.rounds + rounds, item.count - rounds
    if item.count == 0 then
        table.remove(inventory.items, index)
    end
    return rounds
end

function Inventory.reloadFromPack(inventory)
    local hand = inventory.hand
    if not hand or not hand.ammo then
        return 0
    end
    local before = hand.rounds
    local index = 1
    while index <= #inventory.items and hand.rounds < hand.capacity do
        local item = inventory.items[index]
        if item.kind == hand.ammo then
            reload(inventory, index)
        end
        if inventory.items[index] == item then
            index = index + 1
        end
    end
    return hand.rounds - before
end

local function stowPosition(inventory, index)
    local item, hand = inventory.items[index], inventory.hand
    if fits(inventory, hand, item.x, item.y, index) then
        return item.x, item.y
    end
    return firstSpace(inventory, hand, index)
end

function Inventory.canDropInHand(inventory, index)
    local item, hand = inventory.items[index], inventory.hand
    if not hand then
        return true
    end
    if hand.ammo and item.ammoStack then
        return item.kind == hand.ammo and hand.rounds < hand.capacity
    end
    return stowPosition(inventory, index) ~= nil
end

function Inventory.dropInHand(inventory, index)
    local item, hand = inventory.items[index], inventory.hand
    if not hand then
        inventory.hand = table.remove(inventory.items, index)
        return
    end
    if hand.ammo and item.ammoStack then
        if item.kind == hand.ammo then
            return reload(inventory, index)
        end
        return
    end
    local x, y = stowPosition(inventory, index)
    if x then
        hand.x, hand.y = x, y
        inventory.items[index] = hand
        inventory.hand = item
    end
end

function Inventory.useMedkit(player)
    local inventory = player.inventory
    if not inventory.hand or inventory.hand.kind ~= "medkit" or player.health <= 0 or player.health >= 100 then
        return false
    end
    inventory.hand = nil
    player.health = math.min(100, player.health + 40)
    return true
end

return Inventory
