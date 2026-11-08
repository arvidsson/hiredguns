# Hired Guns

A four-operative exploration prototype inspired by the Amiga game, with low-resolution 3D views, warm industrial lighting, and distance fog. Cinder Depot is a shared level, so each operative can see the others when they meet.

## Run

Open the project with LÖVE 11.5.

```powershell
love .
```

Choose **Play** or press **Enter**. Hover over a camera feed to control that operative.

Each living operative has **View**, **Map**, and **Inventory** tabs. Press **Tab** to cycle the panel under the pointer. The map fills in as the squad explores. Nearby visible tiles are recorded and shared across all four panels. Drag an item to the right-hand slot to equip it. The previous item goes into the pack if it fits. Drop matching ammo onto the equipped weapon to reload it.

Drag an equipped item back into a free area of the pack to stow it. Drag an item onto **Floor** to drop it on your current tile if the tile is empty. Stand on a supply tile and click the framed item in the lower-left corner of **View** to put it into the pack. The pickup stays on the floor if its footprint does not fit.

The squad starts together near the depot entrance. Five melee mutants, two fireball casters, and two fast, fragile Skitterers lurk across the depot. Alerted monsters pursue operatives around corners. The casters seek a clear tile lane, visibly charge, then fire straight down it. Fireballs jump one tile every 0.17 seconds, cast white light, and burst on impact. Each living operative's portrait, health, and compass heading stay visible on every tab. At zero HP, the entire panel turns to static and shows **MIA**. The body stays on the tile and can be walked over.

Before spotting the squad, monsters either patrol a fixed loop or wander near their spawn. During pursuit, they can take a short detour instead of always taking the shortest route.

- **W / S** step one tile forward or backward. **A / D** turn 90° left or right. **Q / E** sidestep one tile left or right.
- **Space** or clicking the center crosshair uses the item in hand. Right-click a **View** to reload from matching ammo in the pack. Guns fire straight ahead. Walls and crates stop their shots, and the first living operative or mutant in their path takes damage. Empty guns click when fired. An equipped medkit restores up to 40 HP and leaves the hand slot empty when consumed.

| Starting operative | Weapon | Ammo | Capacity | Damage | Range |
| --- | --- | --- | ---: | ---: | ---: |
| Rhea | Pistol | 9 mm | 9 | 22 | 9 tiles |
| Holt | Shotgun | 12 gauge | 4 | 60 | 5 tiles |
| Vesper and Kell | Carbine | 5.56 | 6 | 34 | 12 tiles |

All three weapons and their ammunition can be found in the depot.
- **Shift + W** pushes the crate directly ahead. **Shift + S** pulls it into the tile you just left. When facing a crate, click the upper or lower crate-and-arrow zone near the center to push or pull without Shift.
- **Left click** steps one tile or turns 90° as shown by the cursor. Hold to repeat. Curved arrows on the sides turn. Straight arrows in the lower corners strafe. The lower middle backs up, and the center and upper area advance.
- Stepping into another operative swaps your tiles. Both operatives keep their headings.
- **Esc** returns to the menu. **Alt+Enter** toggles fullscreen.

## Credits

- Reloads use `pump_action_01.wav` from [Firearms & Guns SFX Lite by VD Sounds](https://vdsounds.itch.io/firearms-guns-sfx-lite). The bundled license is in `assets/audio/combat/reload-license.txt`.
- Empty weapons use `pistol-dry-fire.wav` from [Free Gun Sounds by Outta This World Audio](https://moneywithjjcom.itch.io/free-guns-sounds).

- The loading yard uses panorama 22 from [Cloudy Skyboxes by Screaming Brain Studios](https://screamingbrainstudios.itch.io/cloudy-skyboxes-pack), CC0.

- Combat audio from [Military SFX Mini by hamsunqiu](https://hamsunqiu.itch.io/military-sfx-mini-free-12-cc0-gun-explosion-sounds) (CC0), [Monster Voice Pack by LAZY SPAR7AN GAMES](https://lazyspar7an.itch.io/free-monster-voice-pack-growls-grunts-death-sounds-wav), and Outta This World Audio's [Free Character Grunt Sounds](https://moneywithjjcom.itch.io/free-character-grunts-sounds) and [Free Gore Sounds](https://moneywithjjcom.itch.io/free-gore-sounds). The bundled WAVs were renamed for their game events.

- Blood sprites by Korune from [Free pixel blood effects](https://korune9.itch.io/free-blood). Slash sprites by bobkingg from [Hit Impact Effect Sprites Pack](https://bobkingg.itch.io/blood-hit-effect-sprites), CC0.
- [Footsteps SFX Free by heyheythere](https://heyheythere.itch.io/footsteps-sfx-free), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The two original clips play at alternating pitches in-game. The bundled license is in `assets/audio/footsteps/LICENSE.txt`.

- [g3d by groverburger](https://github.com/groverburger/g3d), version 1.6.0, MIT. The bundled license is in `src/vendor/g3d/LICENSE`.
- [Quake-like Sci-Fi 64x64 Texture Pack by Level Eleven Games](https://level-eleven-games.itch.io/quake-like-texture-pack). Six unmodified textures are included under descriptive filenames. The pack description states CC0 and the itch.io metadata lists CC BY 4.0, so the project preserves attribution and the source link. Original filenames are listed in `assets/textures/CREDITS.md`.

The VS Code template includes an **F5** launch configuration and a **Check formatting** task. To package the game, zip `main.lua`, `conf.lua`, `src/`, and `assets/` at the archive root and give the archive a `.love` extension.
