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

The depot has stairs inside the building and along the edge of the yard. Each staircase occupies one tile between two wall tiles. Both lead to the same upper floor, with an enclosed corridor connecting to the yard walkway. Use the usual movement controls to climb or descend. You can also step off an open edge of the walkway to drop into the yard below. Each operative's map shows their current floor.

Before spotting the squad, monsters either patrol a fixed loop or wander near their spawn. During pursuit, they can take a short detour instead of always taking the shortest route.

- **W / S** step one tile forward or backward. **A / D** turn 90° left or right. **Q / E** sidestep one tile left or right.
- **F** or middle-click operates the door or wall switch directly ahead. Red switches indicate a locked door and green switches indicate an unlocked one. Use the switch to unlock the door, then face the door to open it. Close it before locking it again. A living operative, mutant, or crate in the doorway keeps it open.
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

See [CREDITS.md](CREDITS.md) for asset sources and licenses.

The VS Code template includes an **F5** launch configuration and a **Check formatting** task. To package the game, zip `main.lua`, `conf.lua`, `src/`, `assets/`, and `CREDITS.md` at the archive root and give the archive a `.love` extension.
