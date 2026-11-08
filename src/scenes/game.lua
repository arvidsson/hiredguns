local Level = require("src.level")
local Exploration = require("src.exploration")
local Monster = require("src.monster")
local Fireball = require("src.fireball")
local Hud = require("src.ui.operative_hud")
local Inventory = require("src.inventory")
local InventoryPanel = require("src.ui.inventory_panel")
local DepotMap = require("src.ui.depot_map")
local Viewport = require("src.viewport")
local World = require("src.world")
local Weapon = require("src.weapon")
local Game = {}

local steps = { up = 0, down = 2, strafeLeft = 1, strafeRight = 3, push = 0, pull = 2 }
local turns = { left = 1, right = -1 }
local keys = { w = "up", s = "down", a = "left", d = "right", q = "strafeLeft", e = "strafeRight", space = "fire" }
local cursorDirections = { "up", "down", "left", "right", "strafeLeft", "strafeRight", "push", "pull", "fire" }
local tabNames = { "View", "Map", "Inventory" }
local tabWidth, stripHeight = 108, 54
local viewTab, mapTab, inventoryTab = 1, 2, 3
local fireTop, fireBottom = 0.34, 0.66
local footstepFiles = {
    boots = "walk_concrete_02.ogg",
    armour = "armour_concrete_01.ogg",
}
local combatFiles = {
    dry_fire = 0.62,
    fire_pistol = 0.46,
    fire_shotgun = 0.48,
    reload = 0.53,
    fireball_impact = 0.37,
    fire = 0.48,
    monster_attack = 0.44,
    monster_hurt = 0.42,
    monster_death = 0.49,
    player_hurt = 0.43,
    rhea_hurt = 0.43,
    player_death = 0.58,
}

local function tabsLeft(panel)
    return panel.x + panel.w - #tabNames * tabWidth
end

local function panels()
    local width, height = Viewport.dimensions()
    local w, h = (width - 72) / 2, (height - 116) / 2
    return {
        { x = 24, y = 76, w = w, h = h },
        { x = 48 + w, y = 76, w = w, h = h },
        { x = 24, y = 92 + h, w = w, h = h },
        { x = 48 + w, y = 92 + h, w = w, h = h },
    }
end

local function pickupBounds(panel)
    return panel.x + 16, panel.y + panel.h - stripHeight - 100, 130, 84
end

local function hit(x, y, tabs, squad, crates, pickups)
    for index, panel in ipairs(panels()) do
        local u = (x - panel.x) / panel.w
        local viewHeight = panel.h - stripHeight
        local v = (y - panel.y) / viewHeight
        if squad[index].health > 0 and u >= 0 and u < 1 and v >= 1 and y < panel.y + panel.h then
            local tab = math.floor((x - tabsLeft(panel)) / tabWidth) + 1
            if tab >= 1 then
                return index, nil, tab
            end
        elseif squad[index].health > 0 and u >= 0 and u < 1 and v >= 0 and v < 1 then
            if tabs[index] == inventoryTab then
                return index, "inventory"
            elseif tabs[index] ~= viewTab then
                return
            end
            local left, top, width, height = pickupBounds(panel)
            if x >= left and x < left + width and y >= top and y < top + height and Level.occupantAt(pickups, squad[index].x, squad[index].y) then
                return index, "pickup"
            end
            local dx, dy = u * 2 - 1, v * 2 - 1
            if v >= 0.67 and math.abs(dx) >= 0.52 then
                return index, dx < 0 and "strafeLeft" or "strafeRight"
            end
            if math.abs(dx) > math.abs(dy) and math.abs(dx) > 0.32 then
                return index, dx < 0 and "left" or "right"
            end
            if v >= fireTop and v < fireBottom then
                return index, "fire"
            end
            if math.abs(dx) <= 0.32 and v >= 0.22 and v < 0.80 and Level.crateAhead(squad[index], crates) then
                return index, v < fireTop and "push" or "pull"
            end
            return index, v < fireTop and "up" or "down"
        end
    end
end

local function createCursor(direction)
    local function arrow(x, y)
        if direction == "fire" then
            local radius = x * x + y * y
            return (radius >= 45 and radius <= 78)
                or (math.abs(x) <= 1 and math.abs(y) >= 5 and math.abs(y) <= 11)
                or (math.abs(y) <= 1 and math.abs(x) >= 5 and math.abs(x) <= 11)
                or radius <= 2
        end
        if direction == "push" or direction == "pull" then
            if direction == "pull" then
                y = -y
            end
            local crate = math.abs(x) <= 6 and y >= 2 and y <= 10 and (math.abs(x) >= 5 or y <= 3 or y >= 9)
            local head = y >= -10 and y <= -4 and math.abs(x) <= (y + 10) * 0.9
            local shaft = math.abs(x) <= 1 and y >= -4 and y < 2
            return crate or head or shaft
        end
        if turns[direction] then
            x = x * turns[direction]
            local radiusSquared = (x - 1) ^ 2 + (y - 4) ^ 2
            local arc = x >= -4 and y <= 7 and radiusSquared >= 49 and radiusSquared <= 121
            local head = x >= -11 and x <= -3 and math.abs(y + 5) <= (x + 11) * 0.75
            return arc or head
        end
        if direction == "down" then
            x, y = -x, -y
        elseif direction == "strafeLeft" then
            x, y = -y, x
        elseif direction == "strafeRight" then
            x, y = y, -x
        end
        return (y >= -10 and y <= 0 and math.abs(x) <= (y + 10) * 0.82) or (math.abs(x) <= 2 and y >= 0 and y <= 9)
    end
    local image = love.image.newImageData(25, 25)
    image:mapPixel(function(px, py)
        local x, y = px - 12, py - 12
        if arrow(x, y) then
            return 1, 0.81, 0.46, 1
        end
        if arrow(x - 1, y) or arrow(x + 1, y) or arrow(x, y - 1) or arrow(x, y + 1) then
            return 0.09, 0.06, 0.04, 1
        end
        return 0, 0, 0, 0
    end)
    local cursor = love.mouse.newCursor(image, 12, 12)
    image:release()
    return cursor
end

function Game.new(scenes)
    local scene = {}
    local graphics = love.graphics
    local squad, crates, monsters, pickups, fireballs, fireballBursts, explored, world, hud, inventoryArt, views, cursors, tabs
    local footsteps, combat = {}, {}
    local titleFont, textFont, smallFont
    local hovered, action, held, holdDelay, focused
    local tabPanel, tabHovered
    local inventoryPanel, drag
    local pickupCursor

    local function playCombat(event)
        local source = combat[event]
        source:stop()
        source:play()
    end

    local function playInjury(victim)
        playCombat(victim.name == "RHEA" and "rhea_hurt" or "player_hurt")
        if victim.health == 0 then
            playCombat("player_death")
        end
    end

    local function command(index, direction)
        local player = squad[index]
        if player.health == 0 then
            return
        end
        if direction == "fire" then
            local hand = player.inventory.hand
            if not hand then
                return
            end
            if hand.kind == "medkit" then
                if Inventory.useMedkit(player) then
                    player.healed = 0.28
                end
                return
            end
            local result, target, isMonster = Weapon.fire(player, monsters, squad, crates)
            if result == "empty" then
                playCombat("dry_fire")
            elseif result == "shot" then
                local profile = Weapon.types[hand.kind]
                local dx, dy = Level.direction(player.heading)
                player.muzzle = { x = player.x + dx * 0.34, y = player.y + dy * 0.34, remaining = World.muzzleTime, strength = profile.flash }
                playCombat(profile.sound)
                if isMonster then
                    Monster.hurt(target, profile.damage, player)
                    playCombat(target.health == 0 and "monster_death" or "monster_hurt")
                elseif target then
                    Level.hurtOperative(target, profile.damage)
                    playInjury(target)
                end
            end
            return
        end
        local turn = turns[direction]
        if turn then
            player.heading = (player.heading + turn) % 4
        else
            local x, y = player.x, player.y
            local moveCrate = direction == "push" or direction == "pull" or love.keyboard.isScancodeDown("lshift", "rshift")
            Level.step(player, squad, crates, steps[direction], moveCrate, monsters)
            if player.x ~= x or player.y ~= y then
                Exploration.reveal(explored, squad, crates)
                player.foot = -player.foot
                local voices = footsteps[player.role == "HEAVY" and "armour" or "boots"]
                local source = voices[player.foot]
                source:stop()
                source:play()
            end
        end
    end

    function scene.reset()
        squad = {}
        crates = Level.newCrates()
        pickups = {}
        for index, spawn in ipairs(Level.lootSpawns) do
            local x, y, kind, count = unpack(spawn)
            pickups[index] = { x = x, y = y, item = Inventory.newItem(kind, count) }
        end
        drag = nil
        monsters = {}
        fireballs = {}
        fireballBursts = {}
        for index, spawn in ipairs(Level.monsterSpawns) do
            monsters[index] = Monster.new(unpack(spawn))
        end
        tabs = {}
        for i, spawn in ipairs(Level.spawns) do
            local x, y, heading, name, role, color, startingWeapon = unpack(spawn)
            squad[i] = {
                x = x,
                y = y,
                heading = heading,
                name = name,
                role = role,
                color = color,
                foot = 1,
                health = 100,
                shot = 0,
                inventory = Inventory.new(startingWeapon),
            }
            tabs[i] = viewTab
        end
        explored = {}
        Exploration.reveal(explored, squad, crates)
    end

    function scene.load()
        inventoryArt = InventoryPanel.new()
        world = World.new(inventoryArt)
        hud = Hud.new(world.atlas)
        for event, volume in pairs(combatFiles) do
            local source = love.audio.newSource("assets/audio/combat/" .. event .. ".wav", "static")
            source:setVolume(volume)
            if event == "fireball_impact" then
                source:setPitch(1.3)
            end
            combat[event] = source
        end
        for kind, filename in pairs(footstepFiles) do
            local left = love.audio.newSource("assets/audio/footsteps/" .. filename, "static")
            left:setVolume(0.38)
            left:setPitch(0.96)
            local right = left:clone()
            right:setPitch(1.04)
            footsteps[kind] = { [-1] = left, [1] = right }
        end
        titleFont, textFont, smallFont = graphics.newFont(31), graphics.newFont(23), graphics.newFont(18)
        views, cursors = {}, {}
        for i = 1, #Level.spawns do
            local canvas = graphics.newCanvas(400, 180, { dpiscale = 1 })
            canvas:setFilter("nearest", "nearest")
            views[i] = canvas
        end
        if love.mouse.isCursorSupported() then
            pickupCursor = love.mouse.getSystemCursor("hand")
            for _, direction in ipairs(cursorDirections) do
                cursors[direction] = createCursor(direction)
            end
        end
        scene.reset()
    end

    local function pointer(x, y)
        hovered, action, tabPanel, tabHovered = nil, nil, nil, nil
        inventoryPanel = nil
        if love.window.hasMouseFocus() then
            local localX, localY = Viewport.toLocal(x, y)
            if drag then
                drag.x, drag.y = localX, localY
            end
            local index, direction, tab = hit(localX, localY, tabs, squad, crates, pickups)
            if tab then
                tabPanel, tabHovered = index, tab
            elseif direction == "inventory" then
                inventoryPanel = index
            elseif index then
                hovered, action = index, direction
            end
        else
            held = nil
        end
        if action == "pickup" and pickupCursor then
            love.mouse.setCursor(pickupCursor)
        elseif action and cursors[action] then
            love.mouse.setCursor(cursors[action])
        else
            love.mouse.setCursor()
        end
    end

    function scene.focus(value)
        focused = value
        held, hovered, action = nil, nil, nil
        tabPanel, tabHovered = nil, nil
        inventoryPanel, drag = nil, nil
        love.mouse.setCursor()
    end

    function scene.mousemoved(x, y)
        if focused then
            pointer(x, y)
            if held ~= hovered or action == "pickup" then
                held = nil
            end
        end
    end

    function scene.mousepressed(x, y, button)
        if focused and button == 2 then
            pointer(x, y)
            if hovered and Inventory.reloadFromPack(squad[hovered].inventory) > 0 then
                playCombat("reload")
            end
        elseif focused and button == 1 then
            pointer(x, y)
            if tabPanel then
                tabs[tabPanel] = tabHovered
                held = nil
                return
            end
            if inventoryPanel then
                local panel = panels()[inventoryPanel]
                local localX, localY = Viewport.toLocal(x, y)
                drag = InventoryPanel.pick(squad[inventoryPanel].inventory, localX, localY, panel.x, panel.y, panel.w, panel.h - stripHeight)
                if drag then
                    drag.owner = inventoryPanel
                end
                held = nil
                return
            end
            if action == "pickup" then
                local player = squad[hovered]
                local pickup, index = Level.occupantAt(pickups, player.x, player.y)
                if pickup and Inventory.add(player.inventory, pickup.item) then
                    table.remove(pickups, index)
                end
                held = nil
                pointer(x, y)
                return
            end
            held, holdDelay = hovered, 0.30
            if held then
                command(held, action)
            end
        end
    end

    function scene.mousereleased(x, y, button)
        if button == 1 then
            held = nil
            if drag then
                pointer(x, y)
                if inventoryPanel == drag.owner then
                    local panel = panels()[drag.owner]
                    local player = squad[drag.owner]
                    local floorOccupied = Level.occupantAt(pickups, player.x, player.y) ~= nil
                    local dropped, loaded = InventoryPanel.drop(player.inventory, drag, panel.x, panel.y, panel.w, panel.h - stripHeight, floorOccupied)
                    if dropped then
                        pickups[#pickups + 1] = { x = player.x, y = player.y, item = dropped }
                    end
                    if loaded and loaded > 0 then
                        playCombat("reload")
                    end
                end
                drag = nil
            end
        end
    end

    function scene.update(dt)
        for _, player in ipairs(squad) do
            player.shot = math.max(0, player.shot - dt)
            if player.muzzle then
                player.muzzle.remaining = player.muzzle.remaining - dt
                if player.muzzle.remaining <= 0 then
                    player.muzzle = nil
                end
            end
            if player.healed then
                player.healed = player.healed - dt
                if player.healed <= 0 then
                    player.healed = nil
                end
            end
            if player.hit then
                player.hit = player.hit - dt
                if player.hit <= 0 then
                    player.hit = nil
                end
            end
        end
        if not focused then
            return
        end
        for index = #fireballBursts, 1, -1 do
            local burst = fireballBursts[index]
            burst.age = burst.age + dt
            if burst.age >= Fireball.burstTime then
                table.remove(fireballBursts, index)
            end
        end
        for index = #fireballs, 1, -1 do
            local active, victim, burst = Fireball.update(fireballs[index], squad, crates, monsters, dt)
            if not active then
                table.remove(fireballs, index)
            end
            if burst then
                fireballBursts[#fireballBursts + 1] = burst
                playCombat("fireball_impact")
            end
            if victim then
                playInjury(victim)
            end
        end
        for _, monster in ipairs(monsters) do
            local attack, victim = Monster.update(monster, squad, crates, monsters, dt)
            if attack then
                playCombat("monster_attack")
            end
            if attack == "fireball" then
                fireballs[#fireballs + 1] = Fireball.new(monster)
            end
            if victim then
                playInjury(victim)
            end
        end
        if drag and squad[drag.owner].health == 0 then
            drag = nil
        end
        pointer(love.mouse.getPosition())
        if held and held == hovered and action ~= "pickup" and love.mouse.isDown(1) then
            holdDelay = holdDelay - dt
            if holdDelay <= 0 then
                command(held, action)
                holdDelay = 0.20
            end
        end
    end

    local function drawPanel(panel, index)
        local x, y, w, h = panel.x, panel.y, panel.w, panel.h
        local viewHeight = h - stripHeight
        local player, view = squad[index], views[index]
        if player.health == 0 then
            hud:drawStatic(x, y, w, h, index)
            return
        end
        if tabs[index] == viewTab then
            graphics.setColor(1, 1, 1)
            graphics.draw(view, x, y, 0, w / view:getWidth(), viewHeight / view:getHeight())
            if player.hit then
                world:drawHit(x, y, w, viewHeight, player.hit, player.clawed)
            end
            if player.healed then
                graphics.setColor(0.22, 0.59, 0.36, player.healed * 0.8)
                graphics.rectangle("fill", x, y, w, viewHeight)
            end
            local pickup = Level.occupantAt(pickups, player.x, player.y)
            if pickup then
                local left, top, width, height = pickupBounds(panel)
                local item = pickup.item
                graphics.setColor(0.067, 0.06, 0.049, 0.94)
                graphics.rectangle("fill", left, top, width, height)
                if hovered == index and action == "pickup" then
                    if Inventory.hasSpace(player.inventory, item) then
                        graphics.setColor(unpack(player.color))
                    else
                        graphics.setColor(0.77, 0.29, 0.25)
                    end
                else
                    graphics.setColor(0.54, 0.45, 0.32)
                end
                graphics.setLineWidth(2)
                graphics.rectangle("line", left, top, width, height)
                inventoryArt:drawIcon(item.kind, left + width / 2, top + 32, width - 14, 50, 1)
                graphics.setColor(0.85, 0.75, 0.60)
                local label = item.count and string.format("%s ×%d", item.label, item.count) or item.label
                graphics.printf(label, smallFont, left, top + 58, width, "center")
            end
        elseif tabs[index] == mapTab then
            DepotMap.draw(x, y, w, viewHeight, squad, crates, index, smallFont, explored)
        else
            local floorOccupied = Level.occupantAt(pickups, player.x, player.y) ~= nil
            inventoryArt:draw(player.inventory, x, y, w, viewHeight, smallFont, player.color, drag and drag.owner == index and drag, floorOccupied)
        end
        local stripY = y + viewHeight
        graphics.setColor(0.095, 0.084, 0.076)
        graphics.rectangle("fill", x, stripY, w, stripHeight)
        graphics.setColor(unpack(player.color))
        graphics.rectangle("fill", x, stripY, 5, stripHeight)
        hud:draw(player, index, x + 14, stripY, textFont, smallFont)
        local tabStart = tabsLeft(panel)
        for tab, name in ipairs(tabNames) do
            local tabX = tabStart + (tab - 1) * tabWidth
            local selected = tabs[index] == tab
            if selected or (tabPanel == index and tabHovered == tab) then
                graphics.setColor(0.19, 0.16, 0.13)
                graphics.rectangle("fill", tabX + 1, stripY, tabWidth - 1, stripHeight)
            end
            if selected then
                graphics.setColor(unpack(player.color))
                graphics.rectangle("fill", tabX + 1, stripY, tabWidth - 1, 2)
            else
                graphics.setColor(0.67, 0.62, 0.55)
            end
            graphics.printf(name, smallFont, tabX, stripY + (stripHeight - smallFont:getHeight()) / 2, tabWidth, "center")
        end
        if hovered == index then
            graphics.setColor(unpack(player.color))
        else
            graphics.setColor(0.29, 0.25, 0.21)
        end
        graphics.setLineWidth(2)
        graphics.rectangle("line", x, y, w, h)
    end

    function scene.draw()
        local layout = panels()
        world:setLights(fireballs, fireballBursts, squad)
        for i, panel in ipairs(layout) do
            if tabs[i] == viewTab and squad[i].health > 0 then
                world:render(views[i], squad[i], squad, crates, panel.w / (panel.h - stripHeight), monsters, pickups, fireballs, fireballBursts)
            end
        end
        graphics.clear(0.038, 0.035, 0.032)
        Viewport.beginDraw()
        local width = Viewport.dimensions()
        graphics.setColor(0.87, 0.70, 0.48)
        graphics.print("HIRED GUNS", titleFont, 24, 17)
        graphics.setColor(0.68, 0.63, 0.56)
        graphics.printf("FIELD TEST 01   /   CINDER DEPOT", textFont, 24, 22, width - 48, "right")
        for i, panel in ipairs(layout) do
            drawPanel(panel, i)
        end
        Viewport.endDraw()
    end

    function scene.keypressed(key, scancode, isrepeat)
        if key == "escape" and not isrepeat then
            scenes:switch("menu")
        elseif key == "tab" and focused and not isrepeat and love.window.hasMouseFocus() then
            local mouseX, mouseY = love.mouse.getPosition()
            local x, y = Viewport.toLocal(mouseX, mouseY)
            for index, panel in ipairs(panels()) do
                if squad[index].health > 0 and x >= panel.x and x < panel.x + panel.w and y >= panel.y and y < panel.y + panel.h then
                    tabs[index] = tabs[index] % #tabNames + 1
                    held, drag = nil, nil
                    pointer(mouseX, mouseY)
                    break
                end
            end
        elseif focused and keys[scancode] then
            pointer(love.mouse.getPosition())
            if hovered then
                command(hovered, keys[scancode])
            end
        end
    end

    function scene.gamepadpressed(button)
        if button == "b" or button == "start" then
            scenes:switch("menu")
            return true
        end
    end

    function scene.quit()
        scene.focus(false)
        hud:release()
        world:release()
        inventoryArt:release()
        for _, view in ipairs(views) do
            view:release()
        end
        for _, cursor in pairs(cursors) do
            cursor:release()
        end
        for _, voices in pairs(footsteps) do
            for _, source in pairs(voices) do
                source:stop()
                source:release()
            end
        end
        for _, source in pairs(combat) do
            source:stop()
            source:release()
        end
        titleFont:release()
        textFont:release()
        smallFont:release()
    end

    return scene
end

return Game
