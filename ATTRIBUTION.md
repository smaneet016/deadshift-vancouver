# Assets and provenance

## Poly Haven — CC0

**Powered by Poly Haven.** The visual upgrade includes actual downloaded materials and models, not screenshots of those assets. All are bundled locally and require no runtime network connection.

[Poly Haven asset license](https://polyhaven.com/license) · [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)

| Asset | Use | Resolution |
|---|---|---|
| [Asphalt 02](https://polyhaven.com/a/asphalt_02) | Wet roadway base, normal and roughness maps | 2K |
| [Brick Wall 04](https://polyhaven.com/a/brick_wall_04) | Building walls | 2K |
| [Concrete Wall 006](https://polyhaven.com/a/concrete_wall_006) | Concrete, weathered surfaces | 2K |
| [Rusty Metal 02](https://polyhaven.com/a/rusty_metal_02) | Damaged metal and debris | 2K |
| [Concrete Road Barrier](https://polyhaven.com/a/concrete_road_barrier) | Road cover | 1K |
| [Fire Hydrant](https://polyhaven.com/a/fire_hydrant) | Sidewalk prop | 1K |
| [Trashbag](https://polyhaven.com/a/trashbag) | Street clutter | 1K |
| [Metal Trash Can](https://polyhaven.com/a/metal_trash_can) | Street clutter | 1K |
| [Street Lamp 01](https://polyhaven.com/a/street_lamp_01) | Waterfront lamps | 1K |
| [Modular Urban Apartments Facade](https://polyhaven.com/a/modular_urban_apartments_facade) | Window frames, stone panels and cornices | 1K |
| [Modular Fire Escape](https://polyhaven.com/a/modular_fire_escape) | Exterior stairs and balconies | 1K |
| [Rollershutter Door](https://polyhaven.com/a/rollershutter_door) | Closed storefronts | 1K |

`assets/manifest.json` records sources and resolutions. `tools/fetch_visual_assets.py` downloads this explicit asset list and verifies the file checksums supplied by the API. The helper is for development only; it is never executed by the game.

## Project-authored and supplied content

- The original project/scripts and `art/visual_target.png` came from the user's DEADSHIFT_FPS_MVP.zip. Original rights remain unchanged.
- `art/vancouver_visual_target.png` was supplied in DEADSHIFT_VANCOUVER_CODEX_HANDOFF.zip. It is reference artwork only and is excluded from exports. No redistribution license is claimed for supplied concept artwork.
- Bus, skyline, landmark silhouettes, carbine, gloves, zombie geometry, procedural animation, signs, shaders and scene assembly were authored in this project. They are not photogrammetry character/vehicle assets.
- No AI-generated raster assets were used. Godot's bundled default font is used.
- Shop names and Coast Transit branding are fictional. This is a Vancouver-inspired block, not a geographic replica or official affiliation.
- Godot is MIT-licensed: https://godotengine.org/license/. No engine binary is bundled in the source archive.
