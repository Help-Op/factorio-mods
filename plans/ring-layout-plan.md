# Ring Layout

> **Status:** R1 built + headless ✅ on 5 seeds (2026-10-18) · **Parent:** [territory-mapgen-plan.md](territory-mapgen-plan.md), [challenge-feel-plan.md](challenge-feel-plan.md) · **Next:** in-game check on a new map (user) · [Roadmap](roadmap.md)

Started 2026-10-18 (game 2.1.21), after the first ring was called done in [challenge-feel-plan.md](challenge-feel-plan.md).

## Goal

- Rings that read as **bands around the safe zone**: ring 0 first, then ring 1, and so on.
- **Oil only from ring 1 on**, so the player has to beat their way into ring 1 for it (user, 2026-10-18).

## Decisions (user, 2026-10-18)

| # | Topic | Decision |
|---|-------|----------|
| RL-D1 | Rings (Q1) | **(a) Ring 1 closer**: a clean band right after ring 0 |
| RL-D2 | Oil (Q2) | Oil **only inside ring-1-and-beyond territories** (L2). No oil in ring 0 or the safe zone |
| RL-D3 | Guarantee (Q3) | **One oil patch guaranteed in ring 1** |
| RL-D4 | Ring = grid layer (Q4) | **Yes**: ring 0 = the 4 territories touching the safe zone, ring 1 = the next 12, ring 2 = 20; nested squares |
| RL-D5 | Guaranteed patch (Q5) | In the **ring-1 territory closest to spawn** (~6 wells near its brain base) |

## Confirmed facts (headless, 2026-10-18, 2.1.21, 1280-tile radius)

- **Ring today** = `floor(brain distance / 500)` (`waves.lua` `RING_SIZE`). A brain stands on its territory's point, and since E2 every point is ≥ 200 tiles from spawn.
- **Territories** come from a 384-tile grid (`nauvis-territory.lua` `G`): about one territory per 384 × 384 tiles. One territory spans ~300–500 tiles, wider than a 500-tile ring is "deep" at the edges.

| Seed | Ring-0 territories | Ring 0 reaches | Ring 1 starts at | Oil patches in ring 0 (distance, wells) | First oil in ring 1 |
|---|---|---|---|---|---|
| 12345 | 6 | 728 | **314** | 173 (1), 201 (1), 437 (5), 514 (8) | 518 |
| 987654 | 4 | 599 | **336** | 253 (3), 416 (11), 456 (8) | 564 |
| 555 | 4 | 612 | **402** | 327 (8), 460 (4) | 575 |

- **Rings aren't bands.** Only 4–6 territories are ring 0. In some directions the first territory after the safe zone is already ring 1 (brain ≥ 500 tiles, chunks from 314 tiles).
- **Oil reaches into ring 0 on every seed**: 2–4 patches between 173 and 514 tiles, some tiny (1 well).
- Oil in "safe/none" at 867+ tiles = territories without a brain (water, claimed at map gen).
- **Layers (measured 2026-10-18, 3 seeds):** the territories touching the safe zone are **always the 4 grid cells that meet at spawn** (spawn sits on a cell corner): brains 199–384 tiles out, inner edge 137–182. The next layer starts at **314+** tiles (brains 446–770). Point distance : inner edge, seed 12345: 214:137, 274:144, 313:158, 350:182 | 446:323, 484:368, 518:314, 556:429, …
- Today's ring 0 (brain < 500) = those 4 + a few of the next layer (446 and 484 on seed 12345).
- Oil autoplace: `resource_autoplace.resource_autoplace_settings{name = "crude-oil", has_starting_area_placement = false, …}` (`base/prototypes/entity/resources.lua:265`): a noise `probability_expression` we can multiply by a ring condition (L2).

## Levers (to check against the game files before building)

| # | Lever | What | Note |
|---|-------|------|------|
| L1 | Oil by distance | Multiply the crude-oil autoplace by `distance > R` | Simple. Doesn't follow territory borders |
| L2 | Oil by ring | Multiply the crude-oil autoplace by "this tile's territory point is ≥ 500 tiles out" (`hostile_point_nearest_x/y`, already in the noise) | Follows the territory borders exactly: oil only inside ring ≥ 1 territories |
| L3 | Ring by layer | Ring = how many territories away from the safe zone (ring 0 = touching it) instead of brain distance | Clean bands; needs a definition both noise and `waves.lua` can compute |
| L4 | Ring by smaller distance | e.g. ring 0 = brain < 350 instead of 500 | Fewer ring-0 territories, ring 1 closer |
| L5 | Smaller territories further out | Denser grid in ring 1 | Hard: one grid size today; seams between grid sizes |

## R1. Rings as grid layers, oil from ring 1 (built 2026-10-18, headless ✅)

| # | Part | Draft |
|---|------|-------|
| R1-1 | Ring = grid layer | Ring of a territory = how many grid cells its cell is from the 4 cells around spawn: `max(layer(i), layer(j))` with `layer(i) = i ≥ 0 ? i : -i - 1` and `i, j = floor(point / 384)`. **Ring 0 = the 4 cells around spawn** (always exactly the territories touching the safe zone), ring 1 = the next 12 cells, ring 2 = 20, … Nested squares: ring 1 reaches 768 tiles on the axes, ~1086 at the corners. Same formula in noise (oil) and `waves.lua` (challenges) |
| R1-2 | Oil from ring 1 | Crude-oil `probability_expression` × (ring of the tile's territory point ≥ 1). The safe zone counts as ring 0 (its nearest point is a ring-0 cell) |
| R1-3 | Guaranteed patch | Script, once per map: the ring-1 territory whose brain is closest to spawn gets ~6 wells, ~40 tiles from its brain (outside the base), on land and inside the same territory, when that chunk is generated |
| R1-4 | Check | Headless: ring per territory (bands), oil patches per ring (none in ring 0 / safe zone), guaranteed patch present; first-ring challenge still ring 0 |

**As built:**
- R1-1: `hostile_point_ring` noise expression (`nauvis-territory.lua`) and `waves.ring_at` (`scripts/waves.lua`, `RING_SIZE` removed). Grid layers count from the map origin (spawn on a default map).
- R1-2: Nauvis `property_expression_names["entity:crude-oil:probability"]` = `hostile_crude_oil_probability` = vanilla oil probability × (`hostile_point_ring` ≥ 1). The crude-oil prototype is unchanged (other planets unaffected).
- R1-3: `scripts/oil.lua` (new): picks the spot once from the noise (`on_init` / `on_configuration_changed`): ring-1 points closest first, 8 directions 45 tiles out (outward first), the spot must still belong to that point's territory and have land (`elevation` ≥ 2) under it and the patch's corners. Places **6 wells × 450 000** (150 %) when the spot's chunk is generated. `storage.oil`; `/ht-brains` shows it with a GPS link; remote `oil`.
- R1-4: `tools/ht-ring-check/` (headless, writes `script-output/ring-check-result.txt`).

**Headless (2026-10-18, 2.1.21, 1280-tile radius):**

| Seed | Ring 0 / 1 / 2 territories | Ring 0 chunks | Ring 1 chunks | Oil patches r1 / r2 / r3 (ring 0 + safe zone) | Guaranteed patch |
|---|---|---|---|---|---|
| 12345 | 4 / 12 / 20 | 137–588 | 314–1176 | 7 / 1 / 2 (**0**) | 6 wells, 479 tiles out ✅ |
| 987654 | 4 / 12 / 20 | 137–599 | 323–1176 | 6 / 5 / – (**0**) | 6 wells, 619 ✅ (closest ring-1 territory had no dry spot → next) |
| 555 | 4 / 12 / 20 | 137–612 | 339–1200 | 3 / 6 / 1 (**0**) | 6 wells, 589 ✅ |
| 4242 | 4 / 12 / 20 | 137–551 | – | 6 / 5 / – (**0**) | 6 wells, 461 ✅ |
| 77 | 4 / 12 / 20 | 137–572 | – | 5 / 3 / – (**0**) | 6 wells, 504 ✅ |

- Lua and noise agree on every territory's ring (no mismatch).
- First try placed 0 wells on seed 987654 (spot in water) → land check added; all 5 seeds then ✅.
- First-ring challenge test (`ht-challenge-test`, seed 12345): nearest brain still ring 0, siege → wake → swarm unchanged ✅.

## Steps

- [x] 1. Facts measured, Q1–Q5 answered (2026-10-18).
- [x] 2. R1 built, headless ✅ on 5 seeds (2026-10-18).
- [ ] 3. **In game (user), new map:** no oil in the 4 first territories or the safe zone? `/ht-brains` → GPS link to the guaranteed patch: does it look natural, on land, outside the base? Is ring 1 the band right behind ring 0? Knobs: `WELLS` (6), `AMOUNT` (450 000), `SPOT_DISTANCE` (45) in `scripts/oil.lua`.

Effects: territories with a brain under 500 tiles that are not in the 4 spawn cells become ring 1 (their challenge switches to the old waves, which ring 1 still uses). Brain size stays by distance (small < ~720), unchanged.

## Open questions

- ~~**Q4.**~~ → RL-D4. ~~Ring = grid layer (R1-1)?~~
- ~~**Q5.**~~ → RL-D5. ~~Guaranteed patch: closest ring-1 territory or random?~~


- ~~**Q1.**~~ → RL-D1. ~~"Condense ring 1": what do you mean?~~
  - (a) ring 1 **closer**: a clean band right after ring 0 (L3/L4);
  - (b) ring 1 territories **smaller**, so more of them in the band (L5, hard);
  - (c) ring 0 **one layer only** (the territories touching the safe zone), everything behind it ring 1 (L3).
- ~~**Q2.**~~ → RL-D2. ~~Oil:~~ only inside ring-1+ territories (L2), or just beyond a distance (L1)? Does the safe zone keep no oil at all?
- ~~**Q3.**~~ → RL-D3. ~~Oil amount:~~ move only (fewer patches near spawn), or also add a guaranteed patch in ring 1 so it's always reachable early?
