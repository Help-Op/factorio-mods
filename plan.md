# Hostile Territory: Nauvis Territories

## Goal

Add enemy territories to Nauvis using Factorio's territory map-generation API, based on the system used by Vulcanus.

This means territory-based enemy placement—not copying Vulcanus's terrain or biome regions. Reproducing those would be a separate terrain/autoplace project.

## Decisions

- **Space Age is required.** `info.json` declares `"space-age"`. This unblocks the unit pool: the territory system only works with Space Age's `segmented-unit` prototypes (demolishers).
- **The mod targets Factorio 2.0** (`"factorio_version": "2.0"`, `"base >= 2.0"`). The installed game moved from 2.1.14 (experimental) back to 2.0.77 (stable), and the 2.1 target stopped the mod loading. The territory setup behaves identically on both: same headless test results on 2.0.77 and 2.1.14.
- **No runtime code.** `control.lua` and the `demolisher-nest` entity were deleted. Territories come entirely from map generation, and the engine manages the demolishers. Check them with the map view, `surface.get_territories()`, or the headless harness (step 5).

## Key facts (first checked against Factorio 2.1.14 data; the territory behaviour was re-tested on 2.0.77)

- Vulcanus's `territory_settings` lives in `space-age/prototypes/planet/planet-map-gen.lua`. It contains `units`, `territory_index_expression`, `territory_variation_expression` and `minimum_territory_size = 10`.
- The noise expressions live in `space-age/prototypes/planet/planet-vulcanus-map-gen.lua`, at about lines 891–921.
- `territory_settings.units` must name **`segmented-unit`** prototypes (`small-demolisher`, etc., defined in `space-age/prototypes/entity/enemies.lua`). Biters are `unit` prototypes and can't be used here. Biters on Nauvis come from spawner autoplace, which is a separate system.
- `base/prototypes/planet/planet.lua:20` builds Nauvis's map-gen settings by calling `planet_map_gen.nauvis()` before any mod's `data.lua` runs. Replacing that function afterwards has no effect.
- Vulcanus's starting-area exclusion uses `distance = 100 * vulcanus_starting_area_radius + 32`, where `vulcanus_starting_area_radius = 0.7 * 0.75`. That comes to roughly 84 tiles.
- Factorio 2.x renamed the persistent mod table from `global` to `storage`. `global` is now an ordinary Lua global and isn't saved.
- In 2.x, `rendering.draw_*` returns a `LuaRenderObject`, and you remove it with `obj.destroy()`. `rendering.destroy(id)` no longer exists.

## Issues found

### Data stage — `prototypes/planet/nauvis-territory.lua`

| # | Issue | Effect |
|---|-------|--------|
| D1 | `territory_settings` is added to a fresh copy from `planet_map_gen.nauvis()`, and then the helper function is replaced. | The settings are never applied to Nauvis. |
| D2 | `units = {"small-biter", "medium-biter", "big-biter"}` | These are `unit` prototypes, not `segmented-unit`. Once D1 is fixed, expect a load error or no territories. |
| D3 | `hostile_starting_area` uses `distance = 100 * 32 + 32` (3,232 tiles) at `angle = 0`. | The exclusion zone is about 3 km from spawn rather than near it. Mis-ported from Vulcanus, which uses about 84 tiles plus a terrain-based angle. |
| D4 | The variation expression returns 0–4, but there are only 3 units. | Vulcanus has the same thing. Check what the engine does with indices 3–4 (clamp, skip, or error). |
| D5 | `require("__base__/prototypes/planet/planet-map-gen")` is loaded twice and `planet_map_gen.nauvis()` is called. | Becomes unnecessary once D1 is fixed. |

### Runtime — `control.lua` (resolved: file deleted in step 6)

| # | Issue | Effect |
|---|-------|--------|
| R1 | Uses `global` instead of `storage`, initialized at file scope (line 41). | The nest registry is lost on every save/load. This is the likely cause of the `registered_nests=0` runs in `overlay-debug-report.md`. |
| R2 | `script.on_init` is registered twice (lines 1 and 201). | The second call replaces the first, so the demolisher scan on init never runs. |
| R3 | The first `on_init` calls `register_nest` before its `local` declaration (line 101). | It would resolve to a nil global if it ran. It's hidden for now by R2. |
| R4 | `rendering.destroy(id)` is wrapped in `pcall` (`safe_destroy`). | It fails silently every time, so old overlays are never removed and pile up. |
| R5 | `ht-rebuild-nests` and `ht-clear-nests` are registered inside `on_init` → `on_nth_tick`. | These commands are missing after loading a save. Registering `on_nth_tick` in `on_init` without re-registering it in `on_load` is also a known cause of desyncs and "registered events differently" errors. |
| R6 | The scan/place-nest logic is copy-pasted three times. `ht-scan` searches for biters using a variable named `demolisher_names`. | Hard to maintain, and the copies are already out of sync. |
| R7 | The runtime "nest" and overlay system is separate from map-gen territories. | It can't show or confirm whether real territories exist. |

### Entities — `prototypes/entity/demolisher-nest.lua` (resolved: file deleted in step 6)

| # | Issue | Effect |
|---|-------|--------|
| E1 | A `simple-entity` that uses the small-biter icon as its sprite. It's only used by the debug code in `control.lua`. | Not part of the territory feature. Remove it or keep it as a debug-only marker. |

### Docs

| # | Issue | Effect |
|---|-------|--------|
| P1 | `nauvis-territories-plan.md` recommends the broken `planet_map_gen.nauvis()` approach and suggests biters or worms as units. | Misleading. Delete it or mark it as superseded by this file. |
| P2 | `overlay-debug-report.md` attributes the inconsistent overlays to rendering or client differences. | The real causes are R1, R4 and R5. Archive it once the runtime code is resolved. |

## Step-by-step plan

Each step is meant to be done and checked on its own, in order.

- [x] **1. Decide compatibility scope.** Space Age is required and declared in `info.json`.
- [x] **2. Apply territory settings to the real Nauvis prototype (D1, D5).**
  - Assigned `data.raw.planet.nauvis.map_gen_settings.territory_settings = {...}`.
  - Removed the `planet_map_gen` require and the function override.
  - Verified with `factorio.exe --dump-data`: Nauvis keeps all its existing map-gen keys and now also has `territory_settings`.
- [x] **3. Switch the unit pool to segmented units (D2).**
  - Now uses `{"small-demolisher", "medium-demolisher", "big-demolisher"}`. Custom segmented-unit prototypes are possible later.
  - Verified: the data stage loads with no prototype errors (Factorio 2.1.14 + Space Age).
  - Still open (check in step 8): can demolishers move across Nauvis terrain (water, trees, cliffs) properly?
- [x] **4. Fix the starting-area exclusion (D3).**
  - Finding: `starting_spot_at_angle` (`core/prototypes/noise-functions.lua`) is positive inside a circle centred `distance` tiles from spawn. Even Vulcanus's version only moves cell IDs inside that circle, so it doesn't by itself stop demolishers spawning near the start.
  - New approach, which doesn't depend on an angle and works with multiple starting positions:
    - `hostile_starting_area = distance < hostile_starting_area_radius`. `distance` is the built-in distance to the nearest starting position, and the radius is 384 tiles.
    - The territory index inside the starting area is forced to `-1`. That makes it a single territory of its own, separate from the voronoi cells, which use values 0–1.
    - The variation expression adds `-99 * hostile_starting_area`. A negative variation means an empty spawn location, per the `TerritorySettings` API docs.
  - Verified: a headless `--create` map generates with no noise-expression errors.
  - Verified on one seed in step 5's headless test: the nearest demolisher was 408 tiles from spawn. Still to check (step 8): more seeds, and how it looks in game. Tune `hostile_starting_area_radius` if needed.
- [x] **5. Check the variation range (D4).**
  - The variation is now clamped to `0..2` explicitly, matching the 3 units, so it no longer depends on engine clamping. Tiers: small up to 720 tiles from spawn, medium from 720, big from 1,296. Distances are measured where the variation is sampled; demolishers wander inside their territory.
  - Verified with a headless server test on seed 12345, using a 97×97-chunk area (about ±1,550 tiles):
    - **Default settings:** 97 territories, all with a demolisher. 66 demolisher entities were found in the generated area: 11 small (408–784 tiles from spawn), 24 medium (599–1,451) and 31 big (1,165–2,003). The nearest demolisher was 408 tiles from spawn, so step 4's 384-tile safe zone holds.
    - **`no_enemies_mode = true`:** 99 territories, none with units, and 0 demolishers. The territories still exist but stay empty.
  - Territory chunks can reach within about 362 tiles of spawn (chunk centre), because territories are chunk-based while the radius check is per tile. That's fine for now; raise `hostile_starting_area_radius` if a wider buffer is wanted.
  - Open design question: turning Nauvis "Enemy bases" down to none in the map settings does **not** set `no_enemies_mode`, so demolishers would still spawn. Decide whether territories should also follow the `enemy-base` autoplace control.
  - Test harness, not part of the mod: `--create` with `--map-gen-settings`, then `--start-server` with RCON, then `request_to_generate_chunks` + `force_generate_chunk_requests`, then count with `find_entities_filtered{type="segmented-unit"}` and `surface.get_territories()`. Reuse it in step 8.
- [x] **6. Decide what to do with the runtime code (R1–R7, E1).**
  - Chose option A: deleted `control.lua` (every `/ht-*` command, the overlays and the nest scans) and `prototypes/entity/demolisher-nest.lua`, and removed its require from `data.lua`.
  - Map-gen territories need no runtime code. If debug tooling is wanted later, write a small new command on top of `surface.get_territories()` rather than restoring the old code.
  - Also retargeted `info.json` to Factorio 2.0 after the game moved to 2.0.77.
  - Verified on 2.0.77 with the headless harness. Default settings: 97 territories, 66 demolishers, nearest 408 tiles from spawn. No enemies: 98 territories, 0 demolishers. This matches 2.1.14.
- [ ] **7. Clean up the docs (P1, P2).**
- [ ] **8. Validate in Factorio.** In progress.
  - [x] The mod loads in the normal game client (2.0.77) with Space Age, with no errors.
  - [x] On a new game, territories appear on the map.
  - [x] At least one demolisher appears inside a territory.
  - [ ] Small, medium and big demolishers all appear, at roughly the intended distances (small up to 720 tiles, medium from 720, big from 1,296). The headless test showed this for seed 12345; confirm in game.
  - [ ] Spawn-area safety: no territory or demolisher reaches the start area (headless: nearest demolisher 408 tiles). Try several seeds.
  - [ ] The no-enemies map setting gives territories with no demolishers (headless: confirmed).
  - [ ] Demolisher behaviour on Nauvis terrain, the open question from step 3. Do they move properly across or around water, trees and cliffs, or get stuck?
  - [ ] Gameplay feel. Do they react to buildings in their territory and attack as on Vulcanus? Does the difficulty curve feel right next to biters?
  - Useful console command to list demolishers and their distance from spawn (chart or explore further out first):
    `/c for _,e in pairs(game.player.surface.find_entities_filtered{type="segmented-unit"}) do game.print(e.name.." @ "..math.floor((e.position.x^2+e.position.y^2)^0.5)) end`

## Acceptance criteria

- Nauvis's existing map-gen settings are preserved, with `territory_settings` added.
- New Nauvis chunks get demolisher territories from the selected unit pool.
- The starting area and no-enemies behavior match the intended design.
- The mod loads with Space Age and doesn't load without it.
- Any runtime code that's kept is diagnostic only, persists correctly across save/load, and doesn't drive territory generation.
