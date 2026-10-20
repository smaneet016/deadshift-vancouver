# Milestone 1 — Vancouver arena implementation

> Historical blockout baseline. The current project is described in [VISUAL_UPGRADE_REPORT.md](VISUAL_UPGRADE_REPORT.md).

Date: 2026-10-19 (America/Vancouver)

## Scope and baseline

Read the complete supplied `CODEX_VANCOUVER_HANDOFF.md`, README, project settings, main scene and all three original gameplay scripts before implementation. Inspected the supplied Vancouver concept image. The source archive remains unchanged in `../vancouver_codex_handoff/DEADSHIFT_FPS_MVP.zip`.

The original MVP did **not** compile in Godot 4.3: zombie `target` had no declared type, so inferred `toward`, `dist` and `dir` variables failed. Declaring `target: CharacterBody3D` fixed the baseline before the level replacement.

## Implemented and verified

- One bounded 64×64 m fictional downtown / False Creek level, replacing randomly scattered arena blocks.
- Modular storefront rows, procedural masonry, lit window variation, roof equipment, sidewalks, dashed centre markings, crosswalks, traffic lights and Pacific Boulevard signs.
- Abandoned fictional transit bus, bus shelter, Canadian flags, concrete barriers and small decorative rubble.
- Waterfront, distant triangulated dome, oval stadium roof/masts, skyline towers and low-poly mountain silhouettes.
- Cool night lighting, six warm unshadowed street lights, one optional directional shadow, wet surface shader and player-local CPU rain. Standard fog configured where supported; no volumetric dependency.
- Shared AStarGrid2D routing derived from inflated collision footprints; all 2,497 walkable grid cells connect to the arena. Six clear spawn points choose locations more than 15 m from the player.
- Walk, mouse look, sprint, jump, shooting, real hitscan damage, fire cooldown, timed/manual/empty-mag reload code, zombie pursuit, melee cooldown, death and Enter restart retained. Obstacle line checks prevent melee through barriers.
- Compatibility-friendly material flash on hit and original shrinking/sinking death stand-in. Dead zombie collision is removed immediately.
- Original sidearm progression: +10 damage, +5 magazine, fire delay ×0.84 down to 0.075 s, and up to +24 health after a wave. Original small gun scale change remains. Upgrade HUD displays actual damage/magazine/RPM changes rather than implying modeled weapon swaps.
- Scene-owned wave/spawn/banner timers prevent a timer leak when restarting during a spawn sequence. Wave completion is guarded against duplicate upgrades.
- Escalating wave totals remain intact, with a maximum of 24 living zombies at once. Waiting enemies count toward completion; the next queued enemy enters when a slot opens.
- Balanced/Low profiles on F3, 60 FPS cap, mesh batching, staggered path requests and no physics for distant scenery.
- HUD scale and centre positioning adapt to viewport size; reload and location objective are visible.
- Windows x86_64 and macOS universal export presets included. Assets/tests excluded from exports as documented; no paid or network runtime dependencies.

## Test evidence

Engine: official Godot **4.3.stable.official.77dcf97d8**, downloaded to a temporary folder for validation. Actual rendered device: **Apple M1 Pro**, Compatibility / OpenGL 4.1 Metal.

- Project import: passed after fixes.
- Final rendered integration suite: **44 checks, 0 failures**, exit 0, no script errors, MSAA warnings or ObjectDB leak warnings.
- Final headless integration suite: **43 checks, 0 failures**, exit 0. Captured mouse look is intentionally skipped without a display. Godot's dummy renderer prints null-mesh diagnostics from `servers/rendering/dummy/storage/mesh_storage.h` while freeing procedural meshes. These diagnostics do not occur in the rendered suite; headless output is therefore not warning/error-free.
- Real physics checks include: floor contact, WASD/sprint, jump/landing, shot damage and ammo consumption, reload timing and fire lockout, cover blocking melee, melee cooldown, physically routing around the bus, wave clear and actual upgrade math, second wave, death/restart, and a 27-enemy wave exercising the 24-active-enemy cap and queued completion.
- `tests/downtown_preview.png`: captured from the actual renderer, visually inspected. The final level is clearly a procedural prototype, not the supplied cinematic artwork.
- `tests/performance.gd`: short 24-AI load sample at 1280×720, with 2 s warmup + 8 s measurement per profile. Before enabling the 60 FPS cap, measured about 118.3 FPS Balanced / 119.2 FPS Low, with p95 frame intervals 10.9 / 12.0 ms. These are short local samples, not minimum FPS claims or sustained thermal tests. Godot static memory reported about 38 MiB; this is **not** total process RAM or GPU memory.

Final capped sample (same 24-AI test):

| Profile | Average FPS | p95 frame interval | Draw calls at sample end |
|---|---:|---:|---:|
| Balanced | 60.0 | 21.0 ms | 882 |
| Low | 57.8 | 17.6 ms | 631 |

Timing uses monotonic wall-clock timestamps, not headless speed. The two samples rotate through different views and include OS scheduling; this is not a controlled profile comparison. Neither sample establishes a locked 60 FPS minimum. A longer in-game profiling pass is still needed.

## Changed files

| File | Change |
|---|---|
| `project.godot` | Title, window defaults, 60 FPS cap; Compatibility retained |
| `scripts/game.gd` | Downtown integration, spawn budget, scene-owned timers, safe wave transitions, objective/stats/reload/quality HUD |
| `scripts/player.gd` | Dead-state shooting/reload guards; original FPS mechanics preserved |
| `scripts/zombie.gd` | Baseline parse fix, obstacle routing, attack visibility, portable hit flash and dead collision removal |
| `scripts/downtown.gd` | Procedural city, landmark silhouettes, weather, batching, collision and routing |
| `shaders/wet_surface.gdshader` | World-space asphalt/water aggregate and roughness variation |
| `shaders/facade.gdshader` | Procedural masonry and weathering |
| `tests/*.gd` | Engine-level regression suite, real-render screenshot and load sampler |
| `tests/downtown_preview.png` | Actual in-engine preview |
| `art/vancouver_visual_target.png` | Supplied reference copied into project; never used as scene geometry/textures |
| `export_presets.cfg` | Windows/macOS export configuration; not validated native builds |
| `Run DEADSHIFT.command` | Mac launcher locating Godot in standard locations or the temporary validation folder |
| `README.md`, `ATTRIBUTION.md`, `.gitignore` | Run/verification guidance, provenance and generated-file exclusions |

`main.tscn` remains the original entry scene. No additional maps or characters were introduced.

## Unfinished / limitations

- Art is low-poly procedural geometry. Photorealistic buildings, detailed vehicles, skeletal zombies, realistic first-person arms and modeled weapon tiers are not present.
- Puddles use PBR roughness/specular and sky lighting; they do not reflect local buildings or zombies. Rain is cosmetic, may pass through structures, and has no splashes or surface accumulation. Fog appearance depends on the renderer/version; volumetric fog, bloom, SSR and GI are not implemented.
- No audio, hit marker, full recoil/sway polish, directional damage feedback or new animation system. These belong to Milestone 2; existing muzzle light/kick/bob and death stand-ins remain.
- Zombies can overlap each other (original collision approach retained). The route grid is static and does not support moving obstacles or interiors.
- Escape releases the mouse without pausing. Graphics choice is session-only. There is no save system, settings menu, minimap or finite win condition.
- One completed survival loop is implemented and automatically tested. Multi-wave human playtesting, difficulty tuning and enjoyment assessment remain necessary.
- Windows execution, exported binaries, controller input and long-duration thermal/memory behavior are unverified. Matching export templates, signing and notarization were not installed or performed.
- The temporary validation engine is outside the project and may be removed by macOS. Install Godot normally for ongoing development.

## Next action

Play this single block for several full waves on the target Mac and a Windows PC; record readability, routes, spawn pressure and frame times. Address any playtest findings, then start Milestone 2 combat/audio feedback. Do not expand to additional maps or characters yet.
