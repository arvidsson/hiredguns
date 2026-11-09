local Level = require("src.level")
local Weapon = {}

Weapon.types = {
    carbine = { label = "CARBINE", ammo = "carbineRounds", capacity = 6, w = 3, h = 2, damage = 34, range = 12, cooldown = 0.28, sound = "fire", flash = 4.2 },
    pistol = { label = "PISTOL", ammo = "pistolRounds", capacity = 9, w = 2, h = 1, damage = 22, range = 9, cooldown = 0.21, sound = "fire_pistol", flash = 3.2 },
    shotgun = { label = "SHOTGUN", ammo = "shotgunShells", capacity = 4, w = 4, h = 2, damage = 60, range = 5, cooldown = 0.52, sound = "fire_shotgun", flash = 5.2 },
}

function Weapon.fire(player, monsters, squad, crates)
    local hand = player.inventory.hand
    local weapon = hand and Weapon.types[hand.kind]
    if not weapon then
        return
    end
    if hand.rounds == 0 then
        return "empty"
    end
    if player.shot > 0 then
        return
    end
    hand.rounds = hand.rounds - 1
    player.shot = weapon.cooldown
    local dx, dy = Level.direction(player.heading)
    for tile = 1, weapon.range do
        local x, y = player.x + dx * tile, player.y + dy * tile
        if Level.blocksShot(x, y, player.z, x - dx, y - dy) or Level.occupantAt(crates, x, y, player.z) then
            break
        end
        local teammate = Level.livingAt(squad, x, y, player.z)
        if teammate then
            return "shot", teammate
        end
        local monster = Level.livingAt(monsters, x, y, player.z)
        if monster then
            return "shot", monster, true
        end
    end
    return "shot"
end

return Weapon
