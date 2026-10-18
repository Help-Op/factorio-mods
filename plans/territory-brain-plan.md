# Territory brain: from test mod into the mods

> **Status:** done, B1–B6 (2026-10-17); open notes B-I10–B-I12 · **Parent:** [hive-layout-plan.md](hive-layout-plan.md) (L4) and roadmap fog "Territory brain" · **Next:** none; brain strength goes to EB6 (B-I11), new challenge trigger and "dumb" units stay in roadmap fog · [Roadmap](roadmap.md)

## Goal

Move what L4 proved from the test mod (`tools/ht-layout-test`) into Hostile Territory and Hostile-fauna:

1. **Territories and bases from the same points**: one brain base per territory, placed by map gen.
2. **Brain**: a standing-still `segmented-unit` that is the territory's guardian, moved onto its base centre.
3. **Water → claimed**: if the brain can't be placed, no brain, no base leftovers, territory starts claimed.
4. **Regrowth**: a base grows back over time (after a won crusade).

Not in this plan: the new challenge trigger ("close to the brain"), "dumb units" after the brain dies, free territories as crusade targets (roadmap fog).

## Decisions (user, 2026-10-17)

| # | Decision | Source |
|---|----------|--------|
| B-D1 | Every territory has its own brain; **the brain is the guardian**. Killing it wins the territory | roadmap fog "Territory brain" |
| B-D2 | **One base per territory**: the brain base. No other enemy bases; vanilla nest and worm autoplace off on Nauvis | hive-layout L-b, L-c |
| B-D3 | **Own territory points** (L4): G = 384, J = 0.8, Manhattan. Map gen builds the base, script moves the brain into it | hive-layout L-g, L-h |
| B-D4 | Base = the L3 layout: worm core (1–4 worms by distance) + ring of 6–10 nests, biter and spitter spawners alternating, worm tier by distance | hive-layout L-e |
| B-D5 | Brain can't be placed (water) → destroy the unit, **remove the base leftovers**, territory starts **claimed**. Crusades may reclaim it on land later | hive-layout L-i, L-i1 |
| B-D6 | **Bases regrow over time** by script; map gen builds a base only once | hive-layout L-i3 |
| B-D7 | No walls | hive-layout Decisions |
| B-D9 | **The brain stands on the centre tile**, so the centre worm is gone: the core is 1–4 worms on 4 slots at radius 6 around the brain (was: centre worm + up to 3). Made in B3, so brain and worm don't overlap | Claude, 2026-10-17 (B3) |
| B-D8 | Q1–Q8 defaults (bold below): HT owns points, layout, placement, regrowth; HF owns the brain prototype. Brain head only, tinted earth-wyrm placeholder, small/medium/big by distance. Wyrms out of `territory_settings.units`. Base stays when the brain dies. Regrowth: every hostile territory refills one missing piece per 60 s, core first. Near-shore: strict | user, 2026-10-17 |

## Confirmed facts

| Fact | Source |
|------|--------|
| L4: exactly 1 base in each of 29 fully generated territories, the base point is always the territory's point, 0 stray enemies, same map-gen time as L3 | hive-layout L4b |
| L4: 9 of 29 points on water (seed 12345) | hive-layout L4b |
| `set_body_nodes` moves a unit exactly (head 0.0 tiles from target), also in game | hive-layout L4c, L4d |
| A dormant segmented unit (`patrolling_speed = 0`, `investigating_speed = 0`) stays in place and fights back when damaged by a cause. It **moves** when enraged or attacking (C1b: 48 tiles), unless those speeds are 0 too | EB3c C1, C1b |
| No guardian → `claimed` by default (`territories.lua` `default_state`); `destroy()` raises no died event, so script must set the state | HT code |
| Rally spot: `find_non_colliding_position` on the patrol path, which `patrol.lua` reroutes over land (D34) | `rally.lua`, `patrol.lua` |
| Won crusade: the rally becomes the guardian (`create_segmented_unit` at the rally spot) | `crusade.lua` |
| Staging: an existing nest in a neighbouring hostile territory; no nest → no crusade | `staging.lua` |
| Challenge: starts when a guardian is engaged with a player near; lost when no guardian is engaged for `LOSE_GRACE` | `challenge.lua` |
| Nest distance rules live in Hostile-fauna as `mod-data` `hf-nest-rules` (D24, D26), still empty | `nest-rules.lua` |
| Segment count: docs give only a maximum (63). Whether 0 or 1 segments loads is untested | prototype docs |

## Issues

| # | Issue | Effect / plan |
|---|-------|---------------|
| B-I1 | The engine spawns the unit when the territory is created, usually long before the point's chunk exists | Move the brain when the point's chunk is generated (`on_chunk_generated`), not at creation |
| B-I2 | A base spans up to 2×2 chunks. Leftovers in chunks generated **after** the point's chunk would be missed | Keep a list of dead points; on every `on_chunk_generated`, remove enemies within the base radius of a dead point |
| B-I3 | ~~Resolved for now (B4, user 2026-10-17): challenges work with the brain.~~ Challenge logic depends on the guardian being "engaged". A brain with all speeds 0 may behave differently (never closes in, may never count as engaged) | Test in B4. May push the new challenge trigger forward |
| B-I4 | Territories got bigger (108–201 chunks, avg 150; before 50–162) | Fewer, bigger territories. Check the feel in B4 |
| B-I5 | Wyrms lose their guardian job. `patrol.lua` (reroute, make land) is built for them | Patrol path stays useful (rally spot). Wyrm role: Q4 |
| B-I6 | The test mod overrides HT's noise and turns off all enemy autoplace. Running both at once would double things up | Done (B2/B6): the `mods/ht-layout-test` junction is removed. `tools/ht-layout-test` stays as reference |
| B-I7 | ~~**Crusades no longer launch**~~ **Fixed (2026-10-17).** User's `/ht-crusade` with budget set to 1e6: target, staging nest and rally spot all found, budget ≫ cost, still no crusade, and "0 from evolution" at evolution 0.012 → `crusade.on_tick` never ran. **Cause (bug from B5):** `regrow.INTERVAL` = 3600 = `crusade.CHECK_INTERVAL`, and `script.on_nth_tick` keeps one handler per interval, so registering regrowth replaced the crusade check. Fix: first `regrow.INTERVAL` = 3601; then (user, 2026-10-17) a helper `every(interval, handler)` in `control.lua` that collects handlers per interval and registers one function per interval, so equal intervals can't replace each other. Regrowth back on 3600; headless again: both run ✅. Headless (seed 12345, 7310 ticks): evolution budget 0 → 4 (crusade check runs) and a removed nest regrew (regrowth runs) ✅. Still worth watching: `/ht-attacks` showed 0 cancelled attacks, so the pollution part of the budget may grow slowly now that fewer nests are near the base | Re-test in game (user) |
| B-I8 | **Brain stays enraged after a lost challenge** (user, in game). Headless (2026-10-17): with the challenge's rage refresh, the brain stays `enraged_at_nothing` ~25 s after its target is gone (`enraged_duration` 1800 from the wyrm); the challenge is lost after 5 s, so coming back within that window starts a new challenge at once. `set_ai_state{type = patrolling, waypoint = 1}` clears it immediately. A brain can't move, so it may also stay `attacking` player buildings in its territory (not reproducible headless, needs a real player) | **Fixed (2026-10-17):** `challenge.lua` `lose()` heals the brain and sets it to `patrolling` (waypoint 1). Headless smoke test passes (loads, 600 ticks, no errors); a lost challenge needs a real player, so not tested headless. In game (user): lose a challenge, come back: no instant restart? |
| B-I9 | **Crusade staged on the other side of the map** (user, in game, 2026-10-17). `staging.lua` wants a nest in a hostile territory touching the target; with one base per territory, a neighbour's base only exists once the chunks around its point are generated, so it fell back to the nearest generated base. **Fixed (2026-10-17, user chose option a):** `staging.pick` generates the 3×3 chunks around a touching territory's point when it has no nest yet (`ensure_base`: `request_to_generate_chunks` + `force_generate_chunk_requests`; map gen builds the base, brain.lua places the brain), skips points with water within 3 tiles (brain.lua claims those). `/ht-crusade` previews can trigger it too. Debug remote `staging_for(id)`. Headless (seed 12345, only 21×21 chunks around spawn, 0 nests on the map, one territory's brain killed → claimed): staging in a **touching** territory, its nest chunk was not generated before; the call generated 27 chunks (3 neighbours' bases, one of them water). Test mod: [tools/ht-staging-test/](../tools/ht-staging-test/) | **In game (user, 2026-10-17): ✅ crusades come from next door now.** More stress testing may be needed |
| B-I10 | **Brain seen outside its base** (user, in game, 2026-10-17). Before the chunk with its point is generated, the brain still stands where the engine spawned it (on the patrol path); once the player explores further and the base generates, it jumps there. Understood, but feels strange. Ideas for later (nothing decided): generate the point's chunks when the territory is created, or keep a not-yet-placed brain out of sight | Note only, nothing to do now (user) |
| B-I11 | **Medium and big brains can't be killed** (user, in game, 2026-10-17): they regenerate faster than railgun shots or a nuke take off. The brain copies the wyrm's (= demolisher's) health and regen: small 30000 HP / 40 regen, medium 100000 / 130, big 300000 / 400 (`SIZES` in `earth-wyrm.lua`). A head-only unit seems to keep all of it in one target. Belongs to roadmap fog "Guardian strength" / EB6 | Note only, nothing to do now (user) |
| B-I12 | **Crusades may take longer to start** (user's feeling, 2026-10-17, unconfirmed). Fits B-I7's watch item: `/ht-attacks` showed 0 cancelled attacks, so the budget comes mostly from evolution while fewer nests absorb pollution | Note only; check `/ht-attacks` over a longer game |

## Step-by-step checklist

- [x] **B1. Brain prototype (Hostile-fauna).** `hf-brain` (tiers: Q3), all speeds 0, head only (or 1 segment if 0 doesn't load), placeholder art (D8). Headless: loads with 0 / 1 segments? Placed by territory gen, stands still, fights back? In game (user): how does it look?
  - **Built:** [Hostile-fauna/prototypes/brain.lua](../mods/Hostile-fauna/prototypes/brain.lua): `hf-brain-small/medium/big`, deep copies of the earth wyrm heads, all four speeds 0, `segment_engine.segments = {}` (`SEGMENTS = 0`), pinkish tint `{0.75, 0.45, 0.7}` over the wyrm's sprites. Locale and `placeholders.lua` entries added. Not yet in `territory_settings.units` (that's B2).
  - **Headless (2026-10-17, 2.1.21, seed 12345, HT + HF + test mod [tools/hf-brain-test/](../tools/hf-brain-test/) that puts the brains in `territory_settings.units`, 49×49 chunks):** ✅ Result: [b1-result.txt](../tools/hf-brain-test/b1-result.txt).

    | Check | Result |
    |---|---|
    | Loads with 0 body segments | ✅ `LuaSegmentedUnit.segments` has 1 entry: the head itself |
    | Placed by territory map gen | ✅ 34 territories, 34 brains (11 small, 21 medium, 2 big, by HT's variation expression) |
    | Stands still | ✅ All 34 at full activity for 25 s: max drift 0.00 tiles |
    | Fights back | ✅ Damaged with a character as cause (15 tiles away): AI `enraged_at_nothing`, drift 0.00 tiles, character dead (wyrm's revenge attack) |
    | File paths (`--dump-data` + `check-paths.py`) | ✅ 2353 paths, 0 missing |
  - [x] **In game (user, 2026-10-17, 2.1.21):** spawned with the command in [docs/commands.md](../docs/commands.md) "Territory brain (B1)". Looks bad, but recognisable and OK as a placeholder ✅. AI state while fought: `enraged_at_target`. No brains in the bases yet: expected, map gen still spawns wyrms until B2.
- [x] **B2. Territory points + brain bases in map gen (Hostile Territory).** `nauvis-territory.lua` gets the L4 territory expression; new `prototypes/planet/brain-bases.lua` gets the base layout and turns off vanilla enemy autoplace. `territory_settings.units` = the brain. Headless (HT + HF only, no test mod): the L4 checks again (1 base per territory, 0 stray, 0 in the starting area).
  - **Built:** [nauvis-territory.lua](../mods/Hostile-territory/prototypes/planet/nauvis-territory.lua) (points `hostile_point_*`, territory index, units = brains), [brain-bases.lua](../mods/Hostile-territory/prototypes/planet/brain-bases.lua) (layout `hostile_base_*`, every enemy autoplace off), loaded from the new [data-final-fixes.lua](../mods/Hostile-territory/data-final-fixes.lua) so nests from other mods are turned off too. Bases also respect `no_enemies_mode`.
  - **Checker:** [tools/ht-map-check/](../tools/ht-map-check/), changes no data. Headless on tick 2; in game `/ht-map-check`, `/ht-map-nearest`. Junction `mods/ht-map-check` for debug runs (gitignored); the `mods/ht-layout-test` junction is removed (it would override HT's map gen).
  - **Headless (2026-10-17, 2.1.21, seed 12345, HT + HF + checker, 81×81 chunks):** ✅ Same numbers as L4. Result: [b2-result.txt](../tools/ht-map-check/b2-result.txt).

    | Check | Result |
    |---|---|
    | Bases per fully generated territory | exactly 1 in all 29 ✅ |
    | Base point = territory point | 29 / 29 ✅ |
    | Enemies stray / in the starting area | 0 / 0 ✅ (255 in total) |
    | Territories without a unit / units that aren't a brain | 0 / 0 ✅ |
    | Centre worm placed | 20 / 29, 9 on water (B3 handles these) |
    | **Brain distance from its point** | **72–333 tiles**: the engine places it on the patrol path. B3 moves it |
    | Time (create + 81×81 chunks + check) | 43 s (L4: 44 s) |
- [x] **B3. Brain placement (`scripts/brain.lua`).** On `on_chunk_generated` of a point's chunk: brain fits → move it onto the centre (`set_body_nodes`); doesn't fit → destroy it, mark the point dead, set the territory claimed. On every chunk: remove enemies near dead points (B-I2). Headless: brains on their centre, water territories claimed and empty.
  - **Built:** [scripts/brain.lua](../mods/Hostile-territory/scripts/brain.lua), wired in `control.lua` (`on_chunk_generated`; `brain.scan()` in `on_init` / `on_configuration_changed` for chunks generated before). "Doesn't fit" = any water tile within 3 tiles of the centre (`count_tiles_filtered`, `collision_mask = "water_tile"`). Leftovers: turrets, spawners and units within 40 tiles of the centre. A base lies in its point's grid cell and chunks never straddle cells, so every later chunk in a dead cell is cleaned too. `storage.brain = {placed, dead}` by grid cell. Debug: `/ht-brains`, remote `brains`. Layout change B-D9.
  - **Headless (2026-10-17, 2.1.21, seed 12345, HT + HF + checker, 81×81 chunks, check on tick 10):** ✅ Result: [b3-result.txt](../tools/ht-map-check/b3-result.txt).

    | Check | Result |
    |---|---|
    | Bases per fully generated territory | exactly 1 in all 29 ✅ |
    | Brains on their centre | 20 / 20 dry points, **0 tiles** off ✅ (B2: 72–333) |
    | Water points (water within 3 tiles) | 9: no unit, base area clean (0 enemies within 40 tiles) ✅ |
    | Core worms | 32 in 20 bases (1–4 each) |
    | Stray enemies / in the starting area | 0 / 0 ✅ (240 in total) |
    | Whole generated area (`/ht-brains`) | 29 brains placed, 11 territories claimed at map gen |
  - Not tested: `brain.scan()` on an existing save (players start new games, D36); the claimed state itself was set through `territories.set_state`, not read back.
- [x] **B4. In game (user): the loop still works.** Map: one base per territory, brain in the middle. Challenge: start it, kill the brain → claimed (B-I3). Crusade: staging nest in a neighbour's base, rally on land, lost territory gets a brain.
  - **In game (user, 2026-10-17, 2.1.21):**
    - Map: ✅ every base has its brain in the middle.
    - Water territories: show up as claimed only **after exploring** the area where the base would be (the claim happens when the point's chunk is generated). User doesn't like it, but accepts it for now. Side effect: crusades only go after explored claimed territories, which softens the "far-away free territory" problem (roadmap fog).
    - Challenge: ✅ still works, everything within expected parameters; killing the brain claims the territory (B-I3 resolved for now).
    - **Brain much harder to kill** than the wyrm was. Tweak later (roadmap fog "Guardian strength", EB6).
    - Territory size (B-I4): no complaint reported.
    - [x] Crusade (user): ✅ still works. **Bug:** the rally turned into a **wyrm**, not a brain.
      - Cause: `rally.lua` only knew wyrm and demolisher names; the territory remembers `hf-brain-*`, so it fell back to a wyrm by distance. The rally prototypes also copied their stats from the wyrms.
      - **Fix (2026-10-17):** `rally.guardian_for` always returns the brain of the remembered size (wyrm and demolisher names map to the same size); `prototypes/entity/rally.lua` copies health and resistances from `hf-brain-*`, name "Crusade rally (Small brain)" etc.
      - Headless (seed 12345): crusade preview says `Next rally: ht-rally-big (guardian hf-brain-big)`; rally health 22500 = 0.75 × brain 30000 ✅. In game (user): does a lost territory now get a brain? Not checked yet.
      - The new brain stands at the rally spot, without a base; B5 regrows the base around it.
- [x] **B5. Regrowth (`scripts/regrow.lua`).** Every hostile territory refills missing base slots one at a time around its brain (Q6, Q7), same layout as map gen. Headless: lose a territory by debug command, check the base grows back. In game (user): pacing.
  - **Built:** [scripts/regrow.lua](../mods/Hostile-territory/scripts/regrow.lua). Every 60 s each **hostile** territory with a registered base and a brain gets back its first missing piece: core worms, then ring nests. Same layout as map gen, computed in Lua on the same tile offsets (rotation read from the noise). A slot that's blocked (water, cliff, buildings) is skipped and tried again next time. Bases are registered by brain.lua (brain moved onto its point) and by crusade.lua (`lose`: the new brain at the rally spot gets a base that grows from nothing). `storage.bases[territory id]`. Debug remotes `regrow(n)` (n rounds now) and `place_brain(x, y)` (what a lost crusade does); `/ht-brains` also shows the regrowing bases.
  - **Headless (2026-10-17, 2.1.21, seed 12345, HT + HF + checker + [tools/ht-regrow-test/](../tools/ht-regrow-test/)):** ✅ Result: [b5-result.txt](../tools/ht-regrow-test/b5-result.txt).

    | Check | Result |
    |---|---|
    | Base with 1 worm + 2 nests removed | Round 1 rebuilt the **worm first** ✅; after 3 rounds all 7 pieces back on their tiles and types ✅ (the worm sits 0.3 tiles off inside the same tile: map gen places worms slightly off-centre) |
    | Bases nobody touched | Round 1 also built 8 pieces in other bases: slots on dry land where map gen had left a gap. Regrowth completes them over time |
    | New brain in a water territory (as after a lost crusade) | `hf-brain-small` at the spot; round 1: 1 worm; after 21 rounds 1 worm + 6 nests = complete base for its distance ✅ |
    | Registered bases | 30 (29 placed by brain.lua + 1 from `place_brain`) |
  - [x] In game (user, 2026-10-17, 2.1.21): one piece per minute is OK ✅; regrown pieces land in the right spot ✅; no regrowth during a challenge or crusade or once claimed: not conclusively tested, seems fine.
- [x] **B6. Clean up** (2026-10-17). `mods/ht-layout-test` junction removed in B2. `docs/commands.md`: the old "Hive layout test" section and the three brain sections merged into one "Territory brains and bases" section (plus a `staging_for` command); "Wyrm control" notes that the guardians are brains now. Test tools: **all kept** (the plans link their result files); [tools/README.md](../tools/README.md) says which are current (`ht-map-check`, `ht-regrow-test`, `ht-staging-test`, `check-paths.py`) and which are historical (`hf-brain-test`, `ht-layout-test`). The `mods/ht-map-check` junction **stays** for debug runs (`/ht-map-check`, `/ht-map-nearest`; gitignored). hive-layout plan closed.

## Open questions

Q1–Q8: **defaults in bold accepted** (user, 2026-10-17); also listed as B-D8 in Decisions.

- **Q1. Who owns what?** **HT: territory points, base layout, brain placement, regrowth. HF: the brain prototype. Nest and worm types per slot stay a simple distance table in HT for now; later from `hf-nest-rules`.**
- **Q2. Brain look:** **head only (0 segments if it loads, else 1), tinted placeholder from the earth wyrm head**, or something else?
- **Q3. Brain tiers:** one brain, or **small / medium / big by distance** (like the wyrms today, via `territory_variation_expression`)?
- **Q4. Wyrms:** **out of `territory_settings.units`, prototypes stay in HF unused** (later: mini-bosses, crusade siege units), or keep them as extra guardians next to the brain?
- **Q5. Brain dies (territory claimed):** what happens to its base? **Stays as is** (dumb: no challenge or crusade AI from it, vanilla attacks stay cancelled), or removed?
- **Q6. Regrowth pace:** **one piece every 60 s, core first, then the ring** (a full base in ~10 min)?
- **Q7. Regrowth scope:** only after a won crusade, or **every hostile territory refills missing pieces** (also when the player knocks out nests without killing the brain)?
- **Q8. Near-shore points:** **strict as decided** (doesn't fit at the point → claimed), or first try `find_non_colliding_position` within a few tiles and only claim if that fails too? (A shifted brain sits off-centre in its ring.)
