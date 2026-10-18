# Hive layout in map gen

> **Status:** done (2026-10-17, 2.1.21): L1–L4 success, built into the mods by territory-brain-plan.md · **Parent:** "Territory brain" in [roadmap.md](roadmap.md) fog · **Next:** none · [Roadmap](roadmap.md)

## Goal

Find out whether map gen alone can make enemy bases **look** the way we want: exact shapes, not just denser or sparser nests. The first test is one worm in the middle with a ring of nests around it. Script layouts are assumed to work (user, 2026-10-17), so this plan only covers map gen.

## Decisions

- **One base per territory: the brain base** (L-b, user, 2026-10-17). Every enemy base on Nauvis is a territory's brain base; vanilla nest placement is off (L-c). The brain stands on any land point (L-d).

- One central building (the brain) with buildings around it. **No walls**: they'd block the enemy AI more than the player (user, 2026-10-17).
- Test the map-gen route first. Script layout is the fallback and handles regrowth after crusades.

## Confirmed facts

### Tested (L1, headless, 2026-10-17, 2.1.21)

| Fact | Detail |
|------|--------|
| **Exact placement works.** Probability 1 on one tile and 0 elsewhere gives exactly one entity on that tile | `(floor(x) == 200) * (floor(y) == 0)`: worm at 200.4, 0.4. Ring: all 8 spawners on their tile (centres at x.5) |
| An entity is **only placed if the planet allows it**: linked to one of Nauvis' `autoplace_controls` (e.g. `control = "enemy-base"`) or listed in its `autoplace_settings.entity`. Without a control, nothing is placed | First run: 0 entities. With `control = "enemy-base"`: placed. The slider only scales the result if the expression reads it, ours doesn't |
| **Trees beat enemies** in vanilla: tree order `a[tree]-…` < enemy order `b[enemy]-…`, so a spot in a forest stays empty | With `order = "b"`: 7/8 spawners, the 8th spot (200, −20) was in trees |
| An order before trees (`"!a"`, `"!b"`) **wins over trees** | 8/8 spawners; trees remain around it |
| Map-gen spawners come with their starting units | `unit` entities next to every spawner |
| Vanilla worms are `small/medium/big/behemoth-worm-turret`. There is no "spitter worm" | game files |

### Tested (L2, headless, 2026-10-17, 2.1.21)

| Fact | Detail |
|------|--------|
| **`voronoi_spot_noise` with the territory's input, seed, grid and jitter finds the territory's own point.** One worm per territory, never two, never outside a territory | `ht_test_centre_distance < 1` (named noise expression, distance in tiles) |
| Every territory whose point is on land outside the starting area got its worm | 12 of 17 fully generated territories. All 5 misses explained (below) |
| **The point is not the middle of the territory.** Worms sit 26–105 tiles from the chunk centroid and 13–98 tiles from the patrol-path centroid | Manhattan cells with `jitter = 1` are lopsided; territories are 50–162 chunks |
| **Near spawn, the point can lie inside the starting area.** The territory's chunks are outside, but its point was cut off with the starting area | 3 of 17 (points 322–374 tiles from the origin; starting radius 384) |
| A named noise expression can be read at runtime with `surface.calculate_tile_properties({name}, positions)` | Used to find the missing points |

### How territories and segmented units are generated (docs + what we saw, 2026-10-17)

| System | Unit of work | How | Collisions / order |
|--------|-------------|-----|--------------------|
| Entity autoplace (nests, worms, trees, rocks) | Every **tile**, while its chunk is generated | Noise gives a probability per tile | Yes: `order` decides who goes first, collisions decide the rest |
| Territories (`territory_settings`) | Every **chunk** | `territory_index_expression` (noise) groups chunks with the same value; groups under `minimum_territory_size` are deleted. The territory knows all its chunks, also ungenerated ones (`get_chunks`) | None, it isn't an entity |
| Segmented units (the guardian) | Once per **territory**, when it's created | The engine builds a patrol path with its own algorithm, picks the unit via `territory_variation_expression`, and spawns it on that path | Path ignores water; wyrms spawned on water before `patrol.lua` rerouted the path (EB3b, D34) |

- Only the first two run on noise. The unit's position comes from the engine's path algorithm, so map gen can't know it and can't build around it.
- Bridge between the systems: territories and autoplace can read the **same noise expressions**. If the territory index comes from points we compute (L-g c), map gen knows each territory's centre, and script only moves the brain there (dormant unit, `set_body_nodes` works, EB3c C5).

### From the docs, not yet tested

| Fact | Source |
|------|--------|
| Noise has `if()`, `==`, `<`, `>=`, `%`, `abs`, `sqrt`, `atan2`, `floor` | noise docs, vanilla expressions |
| `voronoi_spot_noise` = distance to the nearest Voronoi point, in grid units (× `grid_size` = tiles). Our territories use `voronoi_cell_id` on the same kind of grid | noise docs, `nauvis-territory.lua` |
| Spot noise only gives a **distance**, not the centre's coordinates. Distance ≈ 0 marks the centre; distance ≈ R/grid is a ring | noise docs |

## How each shape could be made

| Shape | Expression idea | Exact? |
|-------|-----------------|--------|
| One worm at a fixed world spot | `(floor(x) == cx) * (floor(y) == cy)` | ✅ Yes (L1) |
| Ring of N nests at fixed world spots | Lua builds the expression as a sum of N single-tile hits (positions from `cos`/`sin`) | ✅ Yes (L1) |
| Worm at each **territory point** | Spot noise (same seed, grid, jitter and offset as the territory) < 1 tile | ✅ Yes (L2), but the point is off-centre and can be on water or in the starting area |
| Ring around each territory centre | Spot noise distance ≈ R. Gives a band; nests pack into it by collision, so spacing is random | Shape yes, spacing no |
| Ring with exact angles around each centre | Direction to the centre from spot noise sampled at x+1 and y+1 (the gradient), then `atan2` | Maybe, a trick to test |

## Issues

- **Bad ground:** if the centre is water or a cliff, the worm isn't placed. Map gen can't move it; script would have to. Trees are solved by order (L1). Water and cliffs untested.
- ~~**Do spot noise and the territory find the same points?**~~ Yes (L2), with `distance_type = 'euclidean'` for the spot noise and `manhattan` for the territory.
- **The point is often far from the middle** (up to ~100 tiles) and **near spawn it can fall in the starting area**. Decision L-d.
- **Water at the point:** 2 of 17 (one deep water, one shore where the 3×3 worm doesn't fit). Map gen can't move the brain.
- **Vanilla nests** still place everywhere unless the test turns off the `enemy-base` slider or replaces their autoplace.

## Step-by-step checklist

Test mod: [tools/ht-layout-test/](../tools/ht-layout-test/) (copy into an isolated `--mod-directory`). Its `data-final-fixes.lua` clears all vanilla spawner and worm autoplace, then sets ours. `control.lua` checks on tick 2 and writes `script-output/l1-result.txt`.
Harness without a server: `--create l1.zip --map-gen-seed 12345`, then `--benchmark l1.zip --benchmark-ticks 5 --benchmark-runs 1` (runs `control.lua`, exits by itself, so no server to stop). Own `--config` with `write-data` in the scratchpad. Mods: base, space-age, quality, elevated-rails, test mod.

- [x] **L1. Fixed world spot.** One medium worm at (200, 0) plus 8 biter spawners in a ring of radius 20. **Done (headless, 2026-10-17, 2.1.21, seed 12345):** ✅ 1 worm and 8 spawners on their exact tiles, no other enemies on the map. Three runs:

  | Run | Change | Result |
  |---|---|---|
  | 1 | no `control` | 0 worms, 0 spawners |
  | 2 | `control = "enemy-base"`, order `a` / `b` | worm ✅, 7/8 spawners: (200, −20) blocked by trees |
  | 3 | order `!a` / `!b` (before trees) | worm ✅, 8/8 spawners ✅ (r = 19.5–20.5, angles 45° apart) |
- [x] **L2. Territory centre.** Worm where spot noise < 1 tile (same input as `hostile_territory_expression`), not in the starting area. **Done (headless, 2026-10-17, 2.1.21, seed 12345, Hostile-fauna + Hostile-territory + test mod, 65×65 chunks generated):** 53 territories, 23 worms, 0 outside a territory, never 2 in one territory. Of 17 fully generated territories: 12 with 1 worm, 5 without:

  | Territory | Point | Why no worm |
  |---|---|---|
  | #1, #4, #30 | (−319, −41), (300, −224), (−47, 346) | Point in the starting area (322–374 tiles from origin), outside its own territory. Ground was fine |
  | #3 | (156, −415) | Deep water |
  | #20 | (−651, −274) | Shore: 5 water tiles in the 5×5 around it, `can_place_entity` false |

  Result: [tools/ht-layout-test/l2-result.txt](../tools/ht-layout-test/l2-result.txt). Test mod: [tools/ht-layout-test/](../tools/ht-layout-test/) (L1 version in `l1/`).
- [x] **L3. Playable map: every enemy base is a worm core with a ring of nests** (user, 2026-10-17). Replaces the old L3 (ring around the territory point) and L4 (gradient trick). Not tied to territories (L-b, L-d stay open for later).
  - **How (draft):** a base grid of its own, **without jitter**, so map gen knows each base's exact centre:
    - Grid cell `G` tiles. Per cell, random values from `voronoi_cell_id{jitter = 0}` with different `seed1`s (constant over the whole cell): `r1` base or not, `r2`/`r3` offset of the centre inside the cell, `r4` rotation.
    - Centre `cx = floor((floor(x / G) + 0.5 + (r2 - 0.5) * k) * G)`, the same for `cy`. Then `dx = x - cx`, `dy = y - cy` per tile.
    - **Core:** worm on `dx, dy = 0, 0`, plus extra worms on exact spots at radius 6.
    - **Ring:** nearest slot `i = floor(angle * N / 2π + 0.5)`, slot position `(R cos, R sin)` of that slot (+ rotation). Hit when the tile is that slot's tile. Same trick as L1, but computed per base.
    - Order `!…` before trees. A slot on water or a cliff stays empty ("roughly").
  - **Steps:**
    - [x] L3a. Test mod v3 in [tools/ht-layout-test/](../tools/ht-layout-test/) (L1/L2 versions in `l1/`, `l2/`). Named noise expressions `ht_l3_*` in `data-final-fixes.lua`; `control.lua` has the headless check and the in-game commands. Junction `mods/ht-layout-test` → `tools/ht-layout-test` for the debug run (gitignored). **No junction in `%APPDATA%\Factorio\mods`**: there it would change map gen for new chunks in every save it's enabled for, so only add it on purpose.
    - [x] L3b. **Headless check (2026-10-17, 2.1.21, seed 12345, HT + HF + test mod, 81×81 chunks):** ✅ The pattern works. Result: [l3-result.txt](../tools/ht-layout-test/l3-result.txt).

      | Check | Result |
      |---|---|
      | Bases fully generated | 90 (of 103 described) |
      | Enemies in the starting area | 0 ✅ |
      | Enemies total / not part of a checked base | 568 / 48 (likely the 13 bases at the edge of the generated area, not checked) |
      | Perfect bases (every worm and nest) | 27 |
      | Empty bases (nothing placed) | 19. Sampled 16: **all centres on water or deep water** (lakes). Formula values are right there (`has_base = 1`, `core_hit = 1`) |
      | Ring slots filled | 408 / 658 overall, **408 / 521 in non-empty bases (78 %)**. Misses: 182 water, 15 cliff, ~53 land (probably shore: the 5×5 nest doesn't fit) |
      | Worms placed | 117 / 176 |

      Bugs found on the way:
      - **Operator precedence:** `ht_l3_core_hit * ht_l3_base_distance < 700` is read as `(… * …) < 700`, true almost everywhere → 17,003 small worms on the map. Fixed with parentheses. Always parenthesise comparisons in noise expressions.
      - Runtime check of named noise expressions with `calculate_tile_properties` works well for debugging (values at chosen tiles).
    - [x] L3c. **In game (user):** start a new map with the debug config (launch.json, `mods/` has the junction; check that `ht-layout-test` is enabled in the mod list). Commands: [docs/commands.md](../docs/commands.md) "Hive layout test (L3)". Look at the bases on the map and up close: does it read as "worm core with a ring of nests"? Is the spacing OK? Are lakes eating too many bases?
      - **Result (user, 2026-10-17, 2.1.21):** ✅ "Works exactly how I hoped it could work." Some rings not complete, which is completely acceptable; far and away most looked good. Test is a complete success.
- [x] **L4. One base per territory, from our own territory points** (L-g c, user 2026-10-17). Question: can map gen place exactly one base per territory, when the territories don't exist yet while chunks are generated?
  - **Idea:** the territories and the bases both come from the **same points**, which noise can compute on its own, so they can't disagree.
    - **Points:** one per grid cell of `G` tiles, moved inside the cell by per-cell random values (L3 trick, `voronoi_cell_id{jitter = 0}`). The offset is capped at ±`J`·G/2, so each point keeps a margin of (1 − J)·G/2 from its cell edge.
    - **Territory index (per chunk):** the id of the nearest point among the 3×3 surrounding cells (a 9-way min, written out with `if()`). Id = cell index, e.g. `(i + 500) * 1000 + (j + 500)`. This replaces `hostile_territory_expression`. It gives Voronoi cells like today, but around points we know.
    - **Base (per tile):** with G = 384 and J = 0.8 every point is ≥ 38 tiles from its cell edge, and the base (radius ~25) fits inside that. So each tile only needs its **own cell's** point, exactly like L3. Cheap: no 9-way search per tile.
    - **Why the point's chunk lands in its own territory:** neighbouring points are ≥ 76 tiles apart. A chunk sample is ≤ ~23 tiles from the point inside it, so its nearest point is always that point. (To verify, also with the Manhattan distance.)
    - **Starting area:** chunks whose nearest point lies within the starting radius join the starting area (index −1). So no territory loses its point to the starting area (the L2 problem), and no base is placed there.
  - **Steps:**
    - [x] L4a. Test mod v4 in [tools/ht-layout-test/](../tools/ht-layout-test/) (L3 version in `l3/`). Named expressions `ht_l4_*`: 9-way nearest point as a chain of named expressions (`ht_l4_bd1…9`, `if()` per step). Overrides `hostile_territory_expression` with `if((hostile_starting_area + ht_l4_near_start) > 0, -1, ht_l4_nid)`; HT untouched. Defaults from L-h (user, 2026-10-17).
    - [x] L4b. **Headless check (2026-10-17, 2.1.21, seed 12345, HT + HF + test mod, 81×81 chunks):** ✅ One base per territory works. Result: [l4-result.txt](../tools/ht-layout-test/l4-result.txt).

      | Check | Result |
      |---|---|
      | Territories / fully generated | 63 / 29 |
      | Bases per fully generated territory | **exactly 1 in all 29** ✅ (0 with none, 0 with two or more) |
      | Base point = its territory's point | 29 / 29 ✅ |
      | Points with a base but outside every territory | 0 ✅ |
      | Enemies in the starting area / not part of a base | 0 / 0 ✅ (255 enemies in total) |
      | Territories without a segmented unit | 0 ✅ |
      | Centre worm placed | 20 / 29. **9 points on water** (31 %, more than L3's lakes; this seed is wet). Then the territory has no base at all |
      | Territory size (chunks) | 108–201, avg 150 (before: 50–162). No small fragments now: every territory is a whole Voronoi cell |
      | Map-gen time | Same as L3: 44 s for create + 81×81 chunks + check, both runs |
    - [x] L4c. **Wyrm moved to the base centre:** 29 / 29, head 0.0 tiles from the point right after `set_body_nodes` ✅ (headless, same run). Not tested: what it does afterwards (a normal wyrm patrols again; the brain will be dormant).
    - [x] L4d. **In game (user):** new map with the debug config (`mods/ht-layout-test` now points to the L4 version). Commands: [docs/commands.md](../docs/commands.md) "Hive layout test (L3/L4)". Look at the territory colours on the map plus the bases: one base per territory, roughly in the middle? Shapes OK? Then `/ht-layout-move-brains` and look at a wyrm in its base.
      - **Partial result (user, 2026-10-17, 2.1.21):** `/ht-layout-move-brains` moves the wyrms to the centre (seen in at least one place) ✅. 
      - **Result (user, 2026-10-17, 2.1.21):** ✅ Each territory has one base, and the shapes look OK.


## Open questions

- ~~**L-a.** Which entities for the test?~~ Medium worm (no spitter worm exists) and biter spawners, radius 20, 8 nests (user, 2026-10-17).
- ~~**L-b.** How do hive bases relate to territories?~~ **b) Only the brain base: one base per territory** (user, 2026-10-17). (Reworded 2026-10-17; the old wording was unclear.) In L3 the bases sit on their **own 192-tile grid**, unrelated to the territories (Voronoi cells, ~384 tiles). So a territory holds anywhere from 0 to ~5 bases, a base can straddle a border, and none of them is "the brain's base". Options:
  - a) **One brain base per territory**, around the brain. The L3 bases stay as ordinary outer bases.
  - b) **Only the brain base**: one base per territory, nothing else.
  - c) **Keep them independent**: bases as in L3, the brain is placed separately.
- ~~**L-d.** Which point is "the centre" of a territory?~~ **Any point on land is fine** (user, 2026-10-17). Idea: a point on the guardian's patrol path.
  - Note: the patrol path only exists at runtime (`LuaTerritory.get_patrol_path`, built after the territory's chunks are generated). Map gen can't see it, so a patrol-path point means **script** places the brain (and anything tied to it). The other option: map gen uses the Voronoi point (L2) when it is on land, and script handles the rest.
  - Was:
  - a) The Voronoi point (map gen can use it, L2). Off-centre, sometimes water or in the starting area.
  - b) The middle of the territory's chunks, found by script after generation. Always central, needs script placement.
  - c) Change the territory shape so the point is central (e.g. less jitter, or a different distance type). Changes every map.
  - d) Mix: map gen for the outer rings around the point, script places the brain and moves it to land if needed.
- ~~**L-e. L3 defaults**~~ Accepted as below (user, 2026-10-17), confirmed in game (L3c):

  | Setting | Default |
  |---|---|
  | Vanilla nests and worms | Off: only our pattern places enemies |
  | Grid `G` | 192 tiles; a base in 50 % of cells near spawn, rising to 80 % far out |
  | Starting area | No bases within 384 tiles of spawn (same as `hostile_starting_area_radius`). **Since 2026-10-18:** safe zone 150, points closer than 200 pushed out to 200, every cell has a base ([challenge-feel-plan.md](challenge-feel-plan.md) E2) |
  | Core | 1 worm, plus 0–3 more at radius 6 the farther out the base is |
  | Worm tier by distance | small < 700 tiles < medium < 1400 < big < 2400 < behemoth |
  | Ring | Radius 18, 6 nests near spawn up to 10 far out, biter and spitter spawners alternating |
  | Rotation | Random per base |
  | Where the test mod lives | `tools/ht-layout-test/`, with a junction in `mods/` for the debug run (launch.json) and in `%APPDATA%\Factorio\mods` for normal play. Built: debug junction only, see L3a |
- ~~**L-f.** Water~~: accepted as is, incomplete rings are fine (user, 2026-10-17). Was: 19 of 90 bases are lost to lakes and ~1 in 5 ring slots to water or shore. Accept, or: script moves blocked pieces to land after generation, or skip cells whose centre is low (needs a way to read `elevation` at the centre, not at the tile; unknown if noise can).
- ~~**L-c.** Should all nests come from our own expressions, with vanilla nest autoplace off on Nauvis?~~ **Yes** (user, 2026-10-17). In game, all vanilla placement was gone, even far out. Expansion parties (vanilla building new bases) are a separate question, still in the roadmap fog "Vanilla nests on Nauvis".
- ~~**L-g.** Who places the brain base?~~ **c) Our own territory points** (user, 2026-10-17): map gen builds the base, script moves the brain into it. Needs a test: L4. Map gen knows exact positions only on a grid it can compute (L3); our territories are Voronoi cells with random points (L2), and the patrol path is runtime only (L-d).
  - a) **Script, around the brain.** The engine already places a territory's segmented unit (today the wyrm) when the territory is generated. If that unit is the brain (dormant, EB3c), script builds the base around wherever it stands. Full control, can move pieces to land. Map gen places no enemies.
  - b) **Map gen around the territory's Voronoi point.** Ring as a band (L2), so spacing is random. A point on water loses the whole base; script would still have to place the brain.
  - c) **Our own territory points.** Territories built from L3-style points that map gen can compute exactly (nearest of the 9 surrounding cells' points), so map gen knows each centre and can lay out the base exactly, like L3. Shapes stay Voronoi-like. Needs a test; a point on water still needs script.
- ~~**L-h. L4 grid**~~ Accepted (user, 2026-10-17): G = 384 (same as `hostile_territory_radius` today), J = 0.8, Manhattan distance for the territory shape (like today; Euclidean gives rounder cells). Base = the L3 base (1–4 worms, ring of 6–10 nests).
- ~~**L-i. Point on water.**~~ Decided (user, 2026-10-17), see below. L4b: 9 of 29 territories (31 %) lose their only base to water on this seed. **Direction (user, 2026-10-17):** destroy the territory's segmented unit and count the territory as **claimed**. Crusades can later build on land and reclaim it.
  - Fits today's code: a territory without guardian is `claimed` by default (`territories.lua` `default_state`); the rally spot is found with `find_non_colliding_position` on the land-rerouted patrol path (`rally.lua`); a won crusade turns the rally into the guardian there (`crusade.lua`).
  - `destroy()` raises no `on_segmented_unit_died`, so the script must set the state itself (`territories.set_state`) or let `territories.scan` recompute it.
  - Detection: when the point's chunk is generated, `can_place_entity` for the brain at the point. If false → destroy the unit, set claimed.
  - ~~**L-i1.** Leftover ring nests around a water point?~~ **Remove them**: if the brain can't be placed, the territory is clean (user, 2026-10-17).
  - ~~**L-i2.** Far-out free territories as first crusade targets?~~ Unsure yet → roadmap fog "Free territories as crusade targets" (user, 2026-10-17).
  - ~~**L-i3.** Base after a won crusade?~~ **Bases regrow over time** by script (user, 2026-10-17), for every lost territory, not only water ones. Roadmap fog "Hive base layout", lever (3).
- ~~**L-j. Wyrm as brain stand-in**~~ Yes (user, 2026-10-17), done in L4c.
