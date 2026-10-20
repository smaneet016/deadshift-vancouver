# DEADSHIFT: VANCOUVER OUTBREAK

One playable downtown / False Creek zombie-survival block in **Godot 4.3+**. The visual upgrade replaces the flat blockout presentation with downloaded CC0 PBR materials, modular architectural assets, detailed props and Forward+ lighting/reflections.

## Play

Import this folder's **`project.godot`** in Godot and press **F5**. On the development Mac, double-click **`Run DEADSHIFT.command`** to use the available Godot installation or temporary validation engine.

| Control | Action |
|---|---|
| WASD / mouse | Walk / aim |
| Shift / Space | Sprint / jump |
| Left mouse / R | Fire / reload; unlimited reserve ammunition |
| Escape | Release/recapture mouse; does not pause |
| Enter after death | Restart |
| F3 (Fn+F3 if macOS intercepts it) | Balanced / Low graphics |

Clear waves to upgrade damage, magazine size and fire rate, and recover up to 24 health. There is one authored carbine visual; tiers improve the existing weapon rather than swapping to different weapon types. The original damage/ammunition/wave formulas remain intact. This is an endless survival loop with no final victory screen.

## Visual upgrade

- Scanned asphalt, brick, concrete and metal maps; real CC0 barriers, hydrants, trash props, lamps, facade modules and fire escapes.
- Screen-space reflections plus a static reflection probe, puddle roughness/normal variation, glow, ambient occlusion, volumetric fog and a procedural storm sky.
- Detailed bus, overhead Main St / BC Place signs, layered towers, waterfront dome lights, illuminated storefronts, cables, trees, litter and fire/smoke.
- Beveled first-person carbine, gloved hands, weapon-mounted lighting, rounded zombie bodies, face details and pivoted limb animation.
- Static geometry/material batching and instanced facade modules to keep the new detail affordable.

**Balanced:** native 1280×720 rendering, temporal AA, reflections, ambient occlusion, volumetric fog, directional shadows and 420 rain particles. **Low:** 70% internal 3D scale, temporal AA, reflection-probe fallback, ordinary fog, no SSR/SSAO/volumetric fog/directional shadows, and 160 rain particles. Both retain a 60 FPS cap and the same combat behavior. F3 does not switch renderer or persist a preference between sessions.

Forward+ requires a compatible Vulkan device in Godot 4.3; it was run on the M1 Pro through MoltenVK. Windows export presets remain included, but Windows execution/exported binaries are not verified. As a diagnostic fallback, Godot can be launched with `--rendering-method gl_compatibility`; this loses several of the new effects and was not the target of this visual pass.

## Actual images and validation

- [Current in-engine street view](tests/downtown_preview.png)
- [Live wave view](tests/combat_preview.png)
- [Visual upgrade report](VISUAL_UPGRADE_REPORT.md)
- [Asset sources and licenses](ATTRIBUTION.md)

The images in `art/` are the supplied concept references. They are not game screenshots. Characters, vehicles and distant buildings are still authored simplified meshes, not AAA production assets. Rain/fire are cosmetic. The static city collision/routing proxy does not make stairs, storefronts or interiors traversable.

```sh
godot --headless --path . --editor --import --quit
godot --path . --script res://tests/smoke.gd
godot --path . --script res://tests/capture.gd
godot --path . --script res://tests/performance.gd
```

The rendered regression suite opens a window and exits automatically. `tests/inspect_visuals.gd` produces a separately labeled **staged model review**, not a live gameplay screenshot. Performance sampling uses 24 active zombies and the same timed camera sweep for both profiles; it is a short local test, not a long-session thermal guarantee.

## Export and project history

Install matching Godot export templates, then use **Project → Export** with the Windows x86_64 or macOS universal preset. Reference art/tests are excluded. Native binaries, signing and notarization have not been produced. Assets are bundled locally; there are no paid or network runtime dependencies.

`MILESTONE_1_REPORT.md` records the earlier blockout baseline. The original source archive remains in `../vancouver_codex_handoff/`. The project has not been expanded to additional maps or characters.
