# Credits

Each entry identifies the source pack and the files used in the project. Record new downloads here, including packs evaluated without importing their assets.

## Textures and skybox

The files below are in `assets/textures/`. Level Eleven Games' pack description states CC0, and the asset metadata lists CC BY 4.0. The textures are unchanged apart from their names. [Quake-like Sci-Fi 64x64 Texture Pack](https://level-eleven-games.itch.io/quake-like-texture-pack), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

| In game | Original file |
| --- | --- |
| wall.png | ConcretePanel-01_64.png |
| floor.png | ConcreteFloor-02_64.png |
| ceiling.png | CorrugatedMetalPanel-01V_64.png |
| crate.png | MetalPanel-01_64.png |
| hazard.png | ConcreteFloor-Hazard-Full-01_64.png |
| lamp.png | Panel-001_Base-004.png |
| yard.png | ConcreteFloor-01_64.png |
| service.png | MetalGrateFloor-01_64.png |

`yard-sky.png` is `Panorama_Sky_22-512x512.png` from [Cloudy Skyboxes by Screaming Brain Studios](https://screamingbrainstudios.itch.io/cloudy-skyboxes-pack), released under CC0.

## Effects

- `assets/effects/blood.png` is the blood sprite by Korune. [Free pixel blood effects](https://korune9.itch.io/free-blood)
- `assets/effects/slash_arc_01.png` through `slash_arc_04.png` are by bobkingg, CC0. [Hit Impact Effect Sprites Pack](https://bobkingg.itch.io/blood-hit-effect-sprites)

## Audio

Combat filenames below are relative to `assets/audio/combat/`.

| In game | Original file and edits | Source |
| --- | --- | --- |
| `fire.wav` | `ar_single_near_01.wav` | [Military SFX Mini by hamsunqiu](https://hamsunqiu.itch.io/military-sfx-mini-free-12-cc0-gun-explosion-sounds), CC0 |
| `fire_pistol.wav` | `pi_hand_single_near_01.wav` | Military SFX Mini |
| `fire_shotgun.wav` | `sg_single_near_01.wav` | Military SFX Mini |
| `fireball_impact.wav` | `fx_exp_single_far_01.wav` | Military SFX Mini |
| `dry_fire.wav` | `pistol-dry-fire.wav` | [Free Gun Sounds by Outta This World Audio](https://moneywithjjcom.itch.io/free-guns-sounds) |
| `reload.wav` | `rifle-mag-insert.wav` | Free Gun Sounds |
| `reload_shotgun.wav` | `Pump Reload Full Fast WAV.wav`, trimmed | [Snake's Authentic Gun Sounds by SnakeF8](https://f8studios.itch.io/snakes-authentic-gun-sounds) |
| `item_pickup.wav` | `9mm Pistol Slide Release.wav`, trimmed | [Snake's SECOND Authentic Gun Sounds Pack by SnakeF8](https://f8studios.itch.io/snakes-second-authentic-gun-sounds-pack) |
| `item_drop.wav` | `wood_drop_01.wav`, trimmed | [Loot Satchel FREE Lite by yetiancai](https://yetiancai.itch.io/loot-satchel-item-sfx-free-lite) |
| `crate_move.wav` | `METLFric_Scraping Dragging Computer Case On Concrete Ground Sustained Long_WangleLine - Computer Case Carnage-3.flac`, shortened and pitched down | [Computer Case Carnage by WangleLine](https://wangleline.itch.io/shorts-computer-case-carnage), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| `door_open.wav`, `door_close.wav` | The same scrape as `crate_move.wav`, retimed and layered with synthesized start and stop impacts. The close scrape is reversed. | [Computer Case Carnage by WangleLine](https://wangleline.itch.io/shorts-computer-case-carnage), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| `monster_attack.wav` | `bugzy1Attack.wav` | [Monster Voice Pack by LAZY SPAR7AN GAMES](https://lazyspar7an.itch.io/free-monster-voice-pack-growls-grunts-death-sounds-wav) |
| `monster_hurt.wav` | `bugzy1Hurt.wav` | Monster Voice Pack |
| `monster_death.wav` | `bugzy1Death.wav` | Monster Voice Pack |
| `player_hurt.wav` | `male-pain-light-1.wav` | [Free Character Grunt Sounds by Outta This World Audio](https://moneywithjjcom.itch.io/free-character-grunts-sounds) |
| `rhea_hurt.wav` | `female-pain-light-1.wav` | Free Character Grunt Sounds |
| `player_death.wav` | `body-fall-on-gravel-1.wav` | [Free Gore Sounds by Outta This World Audio](https://moneywithjjcom.itch.io/free-gore-sounds) |

- `assets/audio/footsteps/armour_concrete_01.ogg` and `walk_concrete_02.ogg` retain their original filenames and play at alternating pitches in-game. [Footsteps SFX Free by heyheythere](https://heyheythere.itch.io/footsteps-sfx-free), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), [bundled license](assets/audio/footsteps/LICENSE.txt).

## Evaluated or replaced downloads

- The previous door sounds were `doorOpen_000.ogg` and `doorClose_000.ogg`, played at a speed matched to the animation. [Sci-Fi Sounds by Kenney](https://kenney.nl/assets/sci-fi-sounds), [OpenGameArt download](https://opengameart.org/content/sci-fi-sounds), [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).

- The previous shotgun reload used `reload_shotgun_01.wav`. [Firearms & Guns SFX Lite by VD Sounds](https://vdsounds.itch.io/firearms-guns-sfx-lite), [bundled license](assets/audio/combat/reload-license.txt).
- The previous item sounds used `armor_pickup_01.wav` and `armor_drop_01.wav` from Loot Satchel FREE Lite.
- The free skybox sample was evaluated for the loading yard. [Low-Res Retro Skyboxes by Lowbit Lab](https://lowbitlab.itch.io/retro-skyboxes)

## Libraries

- `src/vendor/g3d/` contains version 1.6.0 of g3d by groverburger. [g3d](https://github.com/groverburger/g3d), [MIT license](src/vendor/g3d/LICENSE).
- `src/vendor/baton.lua` contains Baton by tesselode. [Baton](https://github.com/tesselode/baton), [MIT license](src/vendor/baton-license.md).
