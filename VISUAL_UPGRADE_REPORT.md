# Visual upgrade — 2026-10-19

This pass responds to the request to bring the playable level much closer to the supplied Vancouver reference. It replaces the earlier flat blockout presentation while retaining the same level and survival loop. It is an actual 3D Godot level, not the reference image used as a background.

## What changed

- **Renderer and lighting:** Forward+ on the M1 Pro through Vulkan/MoltenVK, screen-space reflections, a one-time reflection probe, ambient occlusion, volumetric fog, bloom/glow, temporal anti-aliasing and a procedural storm sky. Warm street/storefront/fire light contrasts with blue night lighting. No baked lightmaps or ray tracing.
- **Real asset detail:** 12 CC0 Poly Haven asset packages: four PBR surface sets and eight model kits/props. These add real textured barriers, hydrants, bins, lamps, roller shutters, window frames, cornices and fire escapes. Source links and license information are in [ATTRIBUTION.md](ATTRIBUTION.md) and `assets/manifest.json`.
- **Street composition:** rebuilt bus with round tires, hubs, windows, wipers, seats, roof vents and headlights; overhead Main St/BC Place signage; layered glass towers; facade lighting; cables, litter, trees, fire and smoke; dome point lights and stadium accent lights.
- **Wet surfaces:** asphalt albedo/normal/roughness maps with patchy puddles, animated micro-normal variation and actual reflection sources. SSR is limited to information visible on screen; the probe supplies a less accurate offscreen fallback.
- **Foreground:** beveled carbine receiver, barrel, muzzle brake, rail, sight, magazine, bolts, gloved hands and visible muzzle flash. A small fill light and weapon-mounted spotlight improve readability. The weapon is now labeled **Service Carbine**. Damage, ammunition, rate-of-fire and wave upgrade formulas are unchanged; no weapon-type swaps were introduced.
- **Enemies:** rounded bodies, face details, fingers, boots, clothing/wound variation and animated limb pivots replace the original cube figures. These remain authored simplified meshes, not scanned/skinned AAA characters.
- **Optimization:** static geometry is combined by material; repeated facade modules use MultiMesh instances; weapon and limb meshes are combined where animation allows. Existing staggered navigation and 24-living-zombie cap remain.

## Images

- [Previous blockout for comparison](tests/blockout_before.png)
- [Actual in-engine street view](tests/downtown_preview.png)
- [Actual live wave view, with a shot fired through the real weapon code](tests/combat_preview.png)
- `tests/zombie_visual_review.png`, if present, is explicitly labeled as a **staged close-up** used to inspect the model. It is not evidence of a particular live combat situation.

The camera is stationary for the capture scripts. The wave screenshots use the real wave spawner and enemy movement, not a composed crowd or image backdrop. Supplied concept artwork stays in `art/` and is excluded from exports.

## Validation and performance

Official Godot **4.3.stable.official.77dcf97d8**, actual **Apple M1 Pro**, Forward+ / Vulkan 1.2.283.

The rendered regression suite covers 44 checks: mouse look, movement/sprint, jump/landing, hit damage and ammunition, reload and fire cooldowns, melee obstruction/cooldown, physically walking around the bus, wave transitions, stat upgrades, death/restart and queued enemy completion behind the 24-active limit. The final rendered run passed **44 checks with zero failures**, with no script errors or shutdown warnings. Its result is retained in `tests/visual_validation.log`.

Final 24-AI timing sample (`tests/visual_performance.log`):

| Profile | Output / internal 3D scale | Average FPS | p95 frame interval |
|---|---|---:|---:|
| Balanced | 1280×720 / 100% | 59.95 | 17.28 ms |
| Low | 1280×720 / 70% | 59.94 | 18.24 ms |

Both use a 60 FPS cap. Each sample has 2 s warmup and 8 s measurement with a matched timed camera sweep and reset enemy positions. This is a short local load sample, not a minimum-FPS guarantee, thermal endurance test or Windows benchmark. The final muzzle flare is normally hidden and was added after this non-firing load sample.

Godot's static allocator reported approximately 104 MiB during this test. This excludes GPU memory and other process allocations and must not be read as total RAM usage. Downloaded source assets occupy approximately 72 MiB on disk.

The renderer ran and captures were inspected at native 1280×720. Import succeeded. Godot emitted a source-face warning during automatic LOD generation for an imported asset; it did not prevent import or rendering. A first-run MoltenVK pipeline-cache write diagnostic also appeared once during development; subsequent captures and the performance run completed without it. First import/launch may take longer while caches compile.

## Files

| Files | Purpose |
|---|---|
| `assets/materials/`, `assets/models/`, `assets/manifest.json` | Bundled CC0 PBR maps, glTF models and provenance |
| `scripts/downtown.gd` | Forward+ environment, textured surfaces, profile settings, facade metadata |
| `scripts/city_detail.gd` | Detailed architecture/props, skyline, bus, scene dressing and batching |
| `scripts/visual_meshes.gd` | Beveled shapes and material-based mesh consolidation |
| `scripts/weapon_visual.gd`, `scripts/zombie_visual.gd` | New foreground/enemy geometry |
| `scripts/player.gd`, `scripts/zombie.gd` | Visual integration, lighting, muzzle flare and limb motion |
| `scripts/game.gd` | Carbine label and smaller HUD typography |
| `shaders/` | PBR wet ground, sky, window lighting, fire and muzzle flare |
| `project.godot` | Forward+ renderer, TAA and bounded fog/shadow settings |
| `tests/` | Gameplay regression, native captures, model review and comparable quality-profile sampler |
| `tools/fetch_visual_assets.py` | Explicit asset downloader with upstream checksum validation; no runtime dependency |
| `README.md`, `ATTRIBUTION.md`, this report | Launch instructions, sources and truthful status |

The original source archive and earlier milestone ZIP remain available. No additional levels or playable characters were added.

## Remaining gap to the reference

This is a substantial visual upgrade, not an exact cinematic match. The carbine, bus, skyline and zombies remain simplified authored models. There is no skeletal character animation, film-quality destruction, full vehicle interiors, physically simulated rain/fire, audio pass, baked GI or high-end cinematic composition. Street fire is cosmetic. The collision proxy remains simple; facade fire escapes/interiors are decorative, not traversable content.

SSR can lose reflections at screen edges or when objects leave view. Low deliberately drops SSR, SSAO, volumetric fog and directional shadows while retaining the probe and ordinary fog. Rain may pass through structures. Quality selection is not persistent. Long-session playtesting, Windows execution, native exports/signing and thermal/memory soak tests remain unfinished.

Next priority: human playtesting of this single level, followed by better rigged enemy assets, animation and audio—not additional maps.
