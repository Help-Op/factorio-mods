# Enemy Balancing

Sub-plan of phase I in [vision-plan.md](vision-plan.md). Status: **D1–D28 decided, EB1c done (2026-10-15), next: EB2a** (started 2026-10-12, decisions 2026-10-12).

The work in this plan goes into the separate mod **`../Hostile-fauna`** (D10). This plan stays here for now; it can move to `Hostile-fauna` once that mod has its own repo.

## Goal

Make enemies feel right, not just bigger:
- A middle ground between "the player is overwhelmed and dies" and "the player kills everything at once".
- Stronger enemies should *feel* stronger without endless stat creep.
- A roster of enemies that fill **different niches** and combine into interesting groups.
- Do as much as possible in the **data stage** (prototypes), with control.lua only where data can't do it.

## Starting thoughts (user, 2026-10-12)

- Enemies are either too strong or too weak, with nothing in between.
- Likely cause: **they all move too fast**. The player can't run away, so a fight is "win fast or die".
- Slower enemies let the player retreat and **kite** when a group is too strong.
- "Stronger" ≠ only better stats. One thing that does feel stronger: **they live longer** and take more damage to kill.
- More enemy types, each with its own niche, that can be combined.

## Confirmed facts (game files, 2.0.77)

Full research notes: the tables below are from `data/base/prototypes/entity/enemies.lua`, `enemy-projectiles.lua`, `turrets.lua`, `data/space-age/prototypes/entity/enemies.lua` and `doc-html/prototype-api.json`.

### Speed: biters outrun the player

The character's `running_speed` is 0.15 tiles/tick (`base/prototypes/entity/entities.lua:726`), which is 9 tiles/s. Each exoskeleton adds +30 %.

| Unit | Speed (tiles/tick) | vs. character on foot |
|------|--------------------|-----------------------|
| small biter | 0.2 | 133 % |
| medium biter | 0.24 | 160 % |
| big biter | 0.23 | 153 % |
| behemoth biter | 0.3 | 200 % |
| small / medium / big / behemoth spitter | 0.185 / 0.165 / 0.15 / 0.15 | 123 / 110 / 100 / 100 % |

So without exoskeletons **every biter is faster than the player**. This supports the "can't run away" feeling.

### Vanilla stats

| Unit | HP | Damage | Range | Cooldown (ticks) | Resistances | Pollution to attack |
|------|----|--------|-------|------------------|-------------|---------------------|
| small biter | 15 | 7 phys | 0.5 | 35 | none | 4 |
| medium biter | 75 | 15 | 1 | 35 | phys 4/10 %, expl 10 % | 20 |
| big biter | 375 | 30 | 1.5 | 35 | phys 8/10 %, expl 10 % | 80 |
| behemoth biter | 3000 | 90 | 1.5 | 50 | phys 12/10 %, expl 12/10 % | 400 |
| small spitter | 10 | 12 acid (area) | 13 | 100 | none | 4 |
| medium spitter | 50 | 24 | 14 | 100 | expl 10 % | 12 |
| big spitter | 200 | 36 | 15 | 100 | expl 15 % | 30 |
| behemoth spitter | 1500 | 60 | 16 | 100 | expl 30 % | 200 |

- HP goes ×5 per tier for biters (15 → 75 → 375), ×8 to behemoth. That's the "power creep" curve.
- All of these: vision 30, chase for 600 ticks or 50 tiles.
- Gleba pentapods are much tankier: strafer 800–2400 HP, stomper 3500–15000 HP. They're `spider-unit`s, and their speed comes from their legs, not from `movement_speed`.

### What a unit prototype can do without control.lua

| Lever | Fields | Niche it enables |
|-------|--------|------------------|
| Speed | `movement_speed`, `rotation_speed`, `affected_by_tiles` | Slow tanks, fast flankers, units that are slower on certain tiles |
| Toughness | `max_health`, `resistances` per damage type, `healing_per_tick` (a negative value = it decays to death) | Tanks, units weak to one damage type, short-lived swarmers |
| Attack type | `attack_parameters` of type `projectile` (melee or shot), `stream` (spit), `beam` | Melee, ranged, artillery-like |
| Range behaviour | `range`, `min_range` (**the unit backs away if the target is closer**), `min_attack_distance`, `warmup`, `cooldown` | Kiting ranged units, slow wind-up heavy hitters |
| Strafing | `ai_settings.strafe_settings` (new in 2.0: ideal distance, circling direction) | Circling skirmishers. ⚠ Vanilla uses it only on `spider-unit`; unknown whether it works on `unit` |
| Effects on hit | Triggers: `damage`, `create-sticker`, `create-fire`, `push-back`, `create-entity`, `nested-result`, area/line/cluster deliveries | Slows, poison or acid over time, knockback, splash, spawning things on impact |
| Stickers | Movement and vehicle speed modifiers (ramping over time), hard speed cap `target_movement_max`, `damage_per_tick` | Slow, near-root (no true stun exists), poison |
| On death | `dying_trigger_effect` (e.g. `create-entity` units, area damage) | Splitters (Gleba strafers die into 5 wrigglers), explode on death, leave acid pools |
| On being hit | `attack_reaction` (range + trigger when damaged) | Thorns: melee attackers take damage back |
| Group role | `ai_settings.join_attacks = false` (stays home as a defender), `size_in_group`, `spawning_time_modifier` | Nest guards vs. attackers; heavy units cost more group space and spawn time |
| Leash | `min_pursue_time`, `max_pursue_distance`, `vision_distance` (≥ 50 makes units form groups on their own), `distraction_cooldown` | Units that give up quickly vs. relentless chasers |
| Spawn mix | `unit-spawner.result_units` `{name, {{evolution, weight}, ...}}`, `max_count_of_owned_units`, `spawning_cooldown` | When each unit type shows up, how many nests hold |

Other enemy entity types: `spider-unit` (legs walk over obstacles, strafing, leg-stomp area hits), `segmented-unit` (our demolishers), `turret` (worms; the only type with target masks), `unit-spawner`.

### Needs control.lua

- Changing the speed of one entity: `LuaEntity.speed` is writable at runtime. (We use stickers instead today, see `waves.lua`.)
- Retreating at low HP, phase changes, focus-fire, commands.
- **Target priority:** units have no field for it. Only turrets (worms) have target masks.
- `script` trigger effects (they only raise `on_script_trigger_effect`).

### What the mod uses today

- **Challenges:** our `ht-tiny-biter` plus vanilla small and medium biters and small spitters, all slowed by a sticker attached at spawn (`waves.lua`, `challenge-stickers.lua`).
- **Crusade armies:** plain vanilla biters (`army.lua`).

## Decisions (user, 2026-10-12)

| # | Topic | Decision |
|---|-------|----------|
| D1 | Scope | Slow down **all** enemies: our own units *and* vanilla nests and expansion (option (b): override in `data-updates`) |
| D2 | Player speed | Start by raising the character's `running_speed` from 0.15 to **0.25 tiles/tick** (15 tiles/s). That already puts the player ahead of most vanilla enemies and is the first test |
| D3 | Speed target | Then tune enemies relative to 0.25: small units ~**90 %** (0.225), heavy units ~**50 %** (0.125) |
| D4 | Stat curve | **Keep vanilla ×5 HP growth.** Balance mainly through *what we send* (mix, numbers). Extra mechanics per tier are welcome |
| D5 | Unlocks | **Distance is the main driver**, evolution plays a role too. Some enemy types should take a very long time before they show up near spawn |
| D6 | Demolishers | Keep the demolisher *territory* mechanic, but the demolisher unit itself stays on Vulcanus. Replace it on Nauvis with new `segmented-unit`s: wyrm variants without the magma theme (e.g. an earth wyrm and a sea wyrm), plus segmented units that don't look like a demolisher at all, for varied mini-boss fights |
| D7 | No Gleba units | Pentapods are not used on Nauvis. Mechanics may be borrowed |
| D8 | Graphics | Tinted vanilla sprites or white-square placeholders. Placeholders live in the mod folder so it's easy to see what still needs art (see Q-new 3) |
| D9 | Player tools | Out of scope for now (slow/knockback ammo is interesting for later) |
| D10 | Mod split | Split now. Enemy overhaul goes into **`Hostile-fauna`** (folder created by the user). Hostile Territory gets a hard dependency on it |
| D11 | Player speed home | The 0.25 `running_speed` lives in `Hostile-fauna` |
| D12 | Placeholders | `graphics/placeholder/` for our own white squares, plus one `placeholders.lua` list of every entity still on tinted vanilla art (referenced via `__base__/...`, not copied) |
| D13 | Speed table | The proposed table below is the EB3 starting point |
| D14 | Distance gating | Different nest types at different distances, placed by map gen (autoplace). Expansion handling: see "Expansion" below |
| D15 | Sea wyrm | Out of scope for now. Earth wyrm first |
| D16 | Expansion | Mostly option (a), swap on build. Also look into gating nests by **which units settle**: only certain enemies can build a certain nest (see "Settler-based gating") |
| D17 | Nest type rings | No fixed list. Add a nest type (and its distance) each time we need one |
| D19 | Checkpoint effort bands (2026-10-15) | 1× / 4–6× / 15–25× is the starting point. Expect heavy tuning through play tests |
| D20 | Checkpoint scope | Soften vanilla unit resistances too. Slightly stronger turrets are fine; other challenge sources come later |
| D21 | Checkpoint axes | Ammo tiers and weapon types (shotgun, flamethrower, rockets, ...). **Not** damage research |
| D22 | Side doors | Optional: some enemies get an early-tech weakness, not all |
| D23 | Checkpoint table | One table in `Hostile-fauna`: enemy → checkpoint weapon + band. Tuning reference for EB6 |
| D24 | Nest rule format (2026-10-15) | A `mod-data` prototype (`hf-nest-rules`) in `Hostile-fauna`, read at runtime via `prototypes.mod_data`. Other mods (Hostile Territory) can extend it at the data stage. Fields are filled in after EB2c. The D23 checkpoint table may use `mod-data` too |
| D25 | Game version (2026-10-15) | Switch to **2.1** (experimental, 2.1.21). Hostile Territory and cheating-mod bumped to `factorio_version 2.1`, `base >= 2.1`. Headless smoke test on 2.1.21 passed: data stage, map create, 7200 ticks without errors. In game on 2.1.21 (user, 2026-10-15): territories and challenges work; crusades work after the rally regen fix (see vision-plan H-6). `Hostile-fauna` starts on 2.1 |
| D26 | Distance swap target (2026-10-15) | Each nest type in `hf-nest-rules` has a `fallback` field: the nest it's swapped for when expansion builds it closer than `min_distance` |
| D27 | `Hostile-fauna` git (2026-10-15) | Own repo, `git init` done. User commits |
| D28 | Debugger on 2.1 | The `debugadapter` mod (2.0.14) is dead: FMTK ≥ 2.1.2 uses Factorio's native `LuaDebugAdapter`. The launch options `hookSettings` / `hookData` / `hookControl` are gone; `launch.json`: debugger `type` is now `"factorio"` (`"factoriomod"` is a leftover with no adapter: "Cannot find debug adapter"); options reduced to `type`, `request`, `name`, `factorioArgs`. All enabled mods are debuggable |
| D29 | Skirmisher niche (2026-10-15) | **Parked** until after EB4 (Q-EB2-2 option c). Kiter and strafer test units stay as they are for now |
| D30 | Medium biter speed (2026-10-15) | Briefly 0.175, **reverted to 0.2** (D13). Q-EB3-1 was a mix-up: the biter that was too hard to kite was a **big** biter, not a medium |
| D31 | Earth wyrm (2026-10-15) | Names `hf-earth-wyrm-small/medium/big` ("Small earth wyrm" etc.). Fissure revenge attack kept for now (Q-EB3b-2 a). Ash cloud kept as is (Q-EB3b-3). Patrol paths must stay off water (user) |
| D32 | Wyrms and water (2026-10-15) | **Wyrms make land instead of avoiding water** (user, replaces Q-EB3b-5). (A) Once all chunks under a territory's patrol path exist: every water tile in a strip along the **original** engine path (wyrm head width + margin) becomes land, one time. (B) While a wyrm is off patrol (attacking, enraged, investigating) and fully active: water under its head becomes land, so kiting it over a lake builds a causeway. Land tile = a land tile found nearby (natural look), fallback `landfill`. Lake territories (> 50 % water) are still destroyed. Snapping code removed |
| D33 | Water fix per chunk, no lake destroy (2026-10-15) | (A) no longer waits for the whole path: land is made **per chunk** as soon as the chunks under a part of the path exist (Q-EB3b-6 1a). **Lake territories are no longer destroyed**, they get filled like the rest (2b, "for now", user unsure: may mean big landfill areas in lakes). Replaces the lake rule of D32 |
| D34 | Reroute patrol paths with the elevation noise (2026-10-15) | (A) is replaced: on registration the patrol path is **rerouted over land** using `calculate_tile_properties({"elevation"})` (works on ungenerated chunks, 99.96 % match, Q-EB3b-8), then `set_patrol_path`. No more land strips, no waiting for chunks. Step 2c dropped. **(B) stays** (kiting a wyrm over water builds land) |
| D35 | Split and water territories (2026-10-15) | Split by water: keep the land part with the most path points, drop the rest (Q-EB3b-9 a). Almost all water (< 3 path points on land): keep the engine path, the wyrm walks over water and (B) makes land when a player is near |
| D18 | Hostile Territory units | Challenges and crusades **mix** `Hostile-fauna` units with vanilla ones. Mix templates are a Hostile Territory feature, see `vision-plan.md` "Later: challenge and army templates" |

## Ideas to discuss

### Weapon checkpoints: soft walls, not hard walls (user, 2026-10-15)

**Idea (from a talk with a friend):** weapons act as *checkpoints*. You unlock a weapon and an enemy type becomes easy. Keep that, and keep balancing it against the tech tree. What to change: today an enemy feels **impossible** before its weapon and **trivial** after. Better: before the checkpoint it's beatable with a lot of effort (or barely, and you're not sure), after it becomes easy. That turn from "struggle" to "easy" is the power fantasy, and it hides that it's purely a mechanics gate.

**Why vanilla has a hard wall: flat resistance.** Damage formula (Factorio wiki, ⚠ verify in EB2): `d − flat ≥ 1` → `(d − flat) × (1 − %)`; otherwise `1 / (2 + flat − d) × (1 − %)`. Once ammo damage drops below the flat value, damage collapses to a fraction of 1.

Shots to kill, no damage research (ammo: yellow 5, red 8, uranium 24 phys, `base/prototypes/item.lua`):

| Unit (HP, phys flat/%) | Yellow | Red | Uranium | Yellow → uranium |
|------------------------|--------|-----|---------|------------------|
| medium biter (75, 4/10 %) | 84 | 21 | 5 | 17× |
| big biter (375, 8/10 %) | **2084** | **834** | 27 | 77× |
| behemoth biter (3000, 12/10 %) | **~30000** | **~20000** | 278 | 108× |

Bold = the "impossible" zone. Physical damage research raises the base damage before resistances, so it moves the cliff; it's part of the checkpoint too.

**Soft-wall lever:** less flat, more percent. Same big biter (375 HP), alternatives:

| Phys resist | Yellow | Red | Uranium | Feel |
|-------------|--------|-----|---------|------|
| 8 / 10 % (vanilla) | 2084 | 834 | 27 | wall, then trivial |
| 4 / 30 % | 536 | 134 | 27 | very hard → hard → easy |
| 3 / 40 % | 313 | 125 | 30 | hard → doable → easy |

**Proposed effort bands** (shots/ammo/time vs. the checkpoint weapon):

| Player has | Target effort | Feel |
|------------|---------------|------|
| The checkpoint weapon | 1× | Easy, power fantasy |
| One tier below | ~4–6× | Hard but clearly doable |
| Two tiers below | ~15–25× | Huge effort, "maybe possible" |
| Vanilla today | 30–100×+ | Impossible |

**Supporting levers:**
- **Slow enemies (D2/D3) are a precondition.** A 5× longer fight only works if the player can kite and survive it. Without EB3 the soft wall still feels like a wall.
- **Side doors:** a weakness to an early damage type (fire, explosive, poison) lets a clever player win before the checkpoint. Feels earned, not mechanical.
- **Telegraphed hits** (long `warmup`) make long fights about skill, not just ammo count.

### Expansion: how it works (2.1.21: docs, game files, changelog, FFF-445)

- **Trigger:** every 4–60 min (`min/max_expansion_cooldown`) the enemy force picks a candidate chunk at least `min_expansion_distance` (new) and at most `max_expansion_distance` chunks from its furthest base. The planner was rewritten in 2.1: it avoids already infested areas and prefers open and cleared areas.
- **Group size:** `random(settler_group_min_size, settler_group_max_size) × evolution_group_size_factor ^ evolution` (new). Early game max 10, late game up to 80.
- **Building:** on arrival (`on_build_base_arrived`) units are sacrificed one by one, one entity every 30 s (was 5 ticks per HP). `on_biter_base_built` fires once per built entity. New: an "expansion base built" alert if the chunk has radar coverage.
- **What gets built: the settlers decide.** 2.1 removed `build_base_evolution_requirement`. Each unit now has `buildable_entities` (also on `spider-unit`), and each settler builds one entity from its own list. Duplicate entries act as weights (confirmed EB2c). Vanilla (`base/prototypes/entity/enemies.lua:104,347,407,468`):

| Settler | `buildable_entities` |
|---------|----------------------|
| small biter / small spitter | biter-spawner, spitter-spawner, small worm ×2 |
| medium biter | biter-spawner, spitter-spawner, small worm, medium worm |
| big biter | biter-spawner, spitter-spawner, big worm, medium worm ×2 |
| behemoth biter | biter-spawner, spitter-spawner, big worm ×2, behemoth worm |

  So evolution gating now works **through the settlers**: higher evolution → bigger units → bigger worms.
- **Distance:** expansion still knows nothing about distance from spawn. A far-only nest type could be built near spawn by any settler that has it in its list.
- **Our options** (decided: mostly (a), D16):
  - (a) **Replace on build:** a small `control.lua` in `Hostile-fauna` handles `on_biter_base_built`: if the built nest is wrong for its distance, swap it for the right type. Robust, works whatever the engine picks.
  - (b) ~~Evolution only via `build_base_evolution_requirement`~~: removed in 2.1. The data-only equivalent now is: only put far nest types in the lists of units that show up late (high evolution).
  - (c) Turn expansion off for some types. Not possible per prototype; only `enemy_expansion.enabled` for the whole map.
- Expansion creeps outward slowly; near spawn, the nests come from expansion, not map gen. That's exactly where (a) matters.

### Settler-based gating (D16)

Idea: a nest type can only be built by certain settler units (e.g. only an "armoured biter" settler builds an armoured nest).

- **Engine (2.1): native.** Put the nest only in that unit's `buildable_entities`. No script needed for this part.
- **Script:** only distance (option (a)). `pick_nest(position, built_name)` swaps a nest that is wrong for its distance. Settler and evolution rules live in data (`buildable_entities` + spawner `result_units`).
- The D24 rule table (`hf-nest-rules`) shrinks to `{name, min_distance, fallback}` per nest type. ⚠ Open: what to swap to when a nest is too close (the settler's nearest allowed alternative?).

### What makes an enemy feel strong (besides stats)

| Idea | How (data stage) |
|------|------------------|
| Takes long to kill | High HP, but low speed and damage to match. Resistances that reward the right ammo |
| Telegraphed big hits | Long `warmup` and `cooldown` with high damage: the player sees it coming and can dodge |
| Controls space | Area attacks, acid pools (`create-fire`), stomp |
| Forces movement | Knockback, a slow sticker, ranged units that keep their distance (`min_range`) |
| Threat on death | Splits into smaller units, explodes, leaves a hazard |
| Presence | Bigger sprite (`scale`), sound, `warcry` |

### Possible niches (examples, not decided)

| Niche | Sketch |
|-------|--------|
| Swarmer | Very weak and fast, dies over time (negative `healing_per_tick`). Comes in large numbers |
| Brute / tank | Slow, very high HP, physical resistance. Soaks damage for the others |
| Skirmisher | Ranged, keeps its distance (`min_range`), maybe strafing |
| Artillery | Long range, slow cooldown, area hit, very fragile |
| Disabler | Weak attack that applies a strong slow, so other units can catch the player |
| Splitter | Dies into several swarmers |
| Bomber | Explodes on contact or death, damaging walls and turrets |
| Healer / buffer | ⚠ No data-only way to heal or buff allies found. Needs control.lua, or skip it |

### Speed direction: decided (b), see D1

Speeds at player 0.25 tiles/tick (EB3 starting point, D13):

| Unit | Vanilla | vs. 0.25 | Proposed | vs. 0.25 |
|------|---------|----------|----------|----------|
| small biter | 0.2 | 80 % | 0.225 | 90 % |
| medium biter | 0.24 | 96 % | 0.2 | 80 % |
| big biter | 0.23 | 92 % | 0.16 | 65 % |
| behemoth biter | 0.3 | **120 %** | 0.125 | 50 % |
| spitters (S/M/B/Beh) | 0.185 / 0.165 / 0.15 / 0.15 | 74 / 66 / 60 / 60 % | keep | |

- With D2 alone, only the behemoth biter still outruns the player on foot.
- Each exoskeleton gives `movement_bonus = 0.3` (`base/prototypes/equipment.lua:361`), so +30 % on top of 0.25. Vehicles stay far faster.
- The challenge slow stickers (`waves.lua`) may become unnecessary once units are slow by default (E2).

## Issues

| # | Issue | Notes |
|---|-------|-------|
| E1 | Slower enemies change the vanilla balance too | Turret defences become stronger. Only an issue if we change vanilla units (b) |
| E2 | Slower units make crusade armies and challenge waves take longer to arrive | Migration and march timeouts may need tuning |
| E3 | More HP per unit and more units means the player needs more ammo/time | Check that fights don't drag on |
| E4 | New sprites | Reusing vanilla biter or Gleba graphics with a tint and scale is cheap. New art is not |
| E5 | UPS (V2) | Swarmers and splitters add many entities |
| E6 | `strafe_settings` on `unit` | **Tested EB2 (2026-10-15): doesn't strafe.** Same for `min_range` kiting: backs off, then stops firing |
| E7 | Distance gating isn't a vanilla spawner feature | `result_units` only knows evolution. Decided: spawner variants placed by distance (D14). Expansion ignores distance, see "Expansion" |
| E8 | Sea wyrm (parked, D15) | Segmented units collide with water by default. Would need a collision-mask test |
| E9 | Vanilla art in the mod folder | Copying base-game sprites into a published mod redistributes Wube assets. Solved by D12: reference, don't copy |
| E11 | Softer resistances on vanilla units change turret balance | Yellow-ammo gun turrets would start killing big biters by volume. Same trade-off as E1 |
| E10 | Two mods in the test setup | Headless harness `--mod-directory` and `mod-list.json` need a junction to `Hostile-fauna` too. Debug launch in `.vscode/launch.json` must enable both |

## Steps

- [x] **EB1. Brainstorm, round 1.** Scope, speed, curve, unlocks, demolishers, graphics decided (D1–D9).
- [x] **EB1b. Mod split.** Decided: `Hostile-fauna` (D10–D15).
- [x] **EB1c. Set up `Hostile-fauna`** (on 2.1, D25). Sub-steps:
  - [x] **1. Skeleton.** `info.json` (`name = "Hostile-fauna"`, `version = "0.1.0"`, `factorio_version = "2.1"`, deps `base >= 2.1`, `space-age`). Empty `data.lua` and `data-updates.lua` with a header comment (the speed change comes in EB2a). No `control.lua` yet (first needed in EB2c).
  - [x] **2. Placeholders (D12).** `graphics/placeholder/` with `white-square.png`, 64×64 px, generated by us (not copied from `__core__`, E9). `placeholders.lua`: an empty list `{}` with a comment explaining its purpose.
  - [x] **3. Nest rules stub (D24, D26).** `prototypes/nest-rules.lua`: a `mod-data` prototype `hf-nest-rules` with `data = {nests = {}}` and a comment on the fields (`name`, `min_distance`, `fallback`). Empty until there are nest types.
  - [x] **4. Dependency.** Hostile Territory `info.json`: add `"Hostile-fauna >= 0.1.0"` (hard, D10).
  - [x] **5. Test setup (E10).** `.vscode/launch.json`: migrated to FMTK 2.1 (D28), no per-mod hook list any more. Headless harness: add a junction to `Hostile-fauna` and an entry in its `mod-list.json`.
  - [x] **6. Check.** Headless: both mods load, `prototypes.mod_data["hf-nest-rules"]` is readable, 7200 ticks without errors. In game (user): both mods load, territories still work.
    - **Headless (2026-10-15, 2.1.21): passed.** Both mods load (Hostile-fauna before Hostile-territory), `hf-nest-rules` reads `{nests = {}}` at runtime, 7305 ticks without errors.
    - **In game (user, 2026-10-15, 2.1.21): passed.** Both mods load, everything works, debug launch works (D28). A console command that hits a Lua error stops in the debugger, not a real crash.
- [x] **EB2a. Player speed test.** `running_speed = 0.25` in `Hostile-fauna/data-updates.lua`. **Done + headless check (2026-10-15, 2.1.21):** `prototypes.entity["character"].running_speed` = 0.25. In game (user, **without** the cheat kit, see EB2a-k): does it feel OK; can you outrun vanilla groups?
    - **In game (user, 2026-10-15, 2.1.21):** 15 tiles/s feels right. Medium biters: barely outrun, sometimes they catch up (vanilla 0.24 = 96 % of 0.25, expected). Behemoths: faster (0.3, expected). Both get fixed by the EB3 speed pass (medium → 0.2, behemoth → 0.125).
  - [x] **EB2a-k. Test kits in `cheating-mod`** (needed from now on: exoskeletons and mech armor distort speed and fight tests). Approved and built 2026-10-15:
    - Runtime-global mod setting `cheating-mod-auto-kit` (default **off**): give the demolisher kit on spawn/respawn only when on. Charting the start area stays as is.
    - `/cheat-kit [name]`: `demolisher` (today's kit, default), plus tiered kits for the weapon checkpoints (D19–D23): e.g. `pistol`, `smg-yellow`, `smg-red`, `smg-uranium`, `shotgun`, `flamethrower`, `rockets`. Plain character, no armor, enough ammo.
    - `/cheat-clear`: empty inventory, guns, armor (back to a bare character).
    - Tier kits use normal quality and reset the health bonus. Rockets kit: rockets in the slot, explosive rockets in the inventory.
    - **Headless (2026-10-15, 2.1.21): loads**, setting defaults to off, both commands registered. **In game (user, 2026-10-15): works** (spawn without armor, `smg-yellow`, `/cheat-clear`, demolisher kit).
- [ ] **EB2. Engine tests.** One test unit per uncertain lever, headless + in game. Plan (2026-10-15, fields checked in the 2.1.21 docs), approved 2026-10-15:

  | Unit | Base (deepcopy, tinted) | Lever | Expected | Vanilla use |
  |------|------------------------|-------|----------|-------------|
  | `hf-test-kiter` | medium spitter | `attack_parameters.min_range = 8`, `range = 14` | Backs away when the target is closer than 8, then spits | None on units (docs: "the unit will attempt to move away") |
  | `hf-test-strafer` | medium spitter | `ai_settings.strafe_settings = {ideal_distance = 10, max_distance = 16, face_target = true}` | Circles the target at ~10 tiles instead of standing still | Only pentapods (`spider-unit`), E6 |
  | `hf-test-thorns` | big biter | `attack_reaction = {range = 4, action = 15 physical damage to the attacker}` (no `damage_type` filter, so fire counts too) | Attackers within 4 tiles (shotgun, flamethrower, melee) take damage back; rifle at range doesn't | None (commented out in `entities.lua:3435`) |
  | `hf-test-splitter` | medium biter | `dying_trigger_effect` = `create-entity` ×4 small biters (offsets) | 4 small biters appear on death and join the fight | Gleba strafers (spider-unit) |

  - Test units live in `Hostile-fauna/prototypes/test-units.lua`, always loaded (not in any spawner, hidden from Factoriopedia), removed or promoted after EB2. Tints: kiter green, strafer cyan, thorns yellow, splitter magenta.
  - Base unit speed stays vanilla (EB3 does speed).
  - **Resistance formula check** (no new unit): `big_biter.damage(5, "player", "physical")` should take 0.18 HP (flat 8 > damage), `damage(24, ...)` 14.4. Confirms the checkpoint math (D19).
  - **Headless:** spawn each next to a player-less `character` entity, log distance / health / unit count per second over RCON. Kiter: teleport the character into 5 tiles, check the distance grows. Strafer: check the angle around the character changes. Thorns: damage the unit with the character as `cause` at 2 and 10 tiles, check the character's health. Splitter: kill it, count small biters.
  - **In game (user):** spawn command per unit in `commands.md`; judge whether it *feels* like a niche.
  - Steps:
    - [x] 1. `test-units.lua`, load check headless (2026-10-15, 2.1.21): OK.
    - [x] 2. Headless measurements (2026-10-15, 2.1.21), 3 rounds. Targets: player-less `character` entities with +1e6 health.

      | Lever | Result | Verdict |
      |-------|--------|---------|
      | Resistance formula | Big biter: 5 phys → **0.180**, 24 phys → **14.400** | ✅ Confirmed exactly: `1/(2+flat−dmg)` below flat, then × (1−%). D19 math holds |
      | Thorns (`attack_reaction`) | Attacker at 2 tiles: −15 HP for physical **and** fire. At 12 tiles: 0. Damage without a `cause`: 0 | ✅ Works. Range-limited, needs a cause (any real attack has one) |
      | Splitter (`dying_trigger_effect`) | 0 small biters before death, 4 after | ✅ Works. Do they join the fight? In game |
      | Kiter (`min_range = 8`) | Target teleported to 4 tiles: the kiter first walks *into* it (0.7), then backs off to 6–8 tiles and **hovers there without firing again** (no damage for 600+ ticks). Vanilla spitter in the same setup keeps firing. `range_mode = "center-to-center"` changes nothing (reverted) | ⚠ Backs off, but then stops attacking. Not usable data-only. Check in game with a moving player |
      | Strafer (`strafe_settings` on `unit`, E6) | Destructible target at 12 tiles: no strafing, behaves like a vanilla spitter. Started at 25 tiles: never approaches, never fires. Indestructible target: circles ~40° at 10–16 tiles, then walks off to 60–70 tiles | ⚠ Erratic. Circling only shows up in odd cases. Not usable data-only. Check in game |

      Takeaway: thorns, splitter and the resistance math are reliable data-only levers. Kiting and strafing on `unit` need either the in-game check to look better, or script help (e.g. a periodic "step back" command), or another unit type.
    - [x] 3. In-game feel test (user, 2026-10-15, 2.1.21):
      - **Kiter (green):** moves around erratically when you come close, then never shoots again, until you move far enough away; then it attacks again. Matches headless.
      - **Strafer (cyan):** never strafes. Stands still while you are in range, walks closer when you leave range, then stands still again. Plain spitter behaviour.
      - **Thorns (yellow):** damages you only when close. ✅
      - **Splitter (magenta):** the small biters join the fight. ✅
      - **Verdict:** thorns, splitter, resistance math = usable data-only levers. `min_range` and `strafe_settings` on `unit` don't give kiting or strafing (E6 answered: no). Open: Q-EB2-2.
- [x] **EB2c. Expansion test (rewritten for 2.1).** Two test units with different `buildable_entities` (unit a: `{nest-a}`, unit b: `{nest-a, nest-b, nest-b}`). Spawn a group of each by script and give it a `build_base` command; log `on_build_base_arrived` and `on_biter_base_built`. Check: (1) unit a only ever builds nest-a; (2) unit b's split is ~1:2 (duplicates = weights); (3) a mixed group builds per settler. Also log how many entities a group of N builds. Record results; this fixes the D24 table fields.
  - Setup: test prototypes in `Hostile-fauna/prototypes/test-units.lua`: `hf-test-settler-a` (`{nest-a}`), `hf-test-settler-b` (`{nest-a, nest-b, nest-b}`), `hf-test-nest-a/b` (copies of the vanilla spawners, no autoplace). Groups made by script with a `build_base` command, logged from the console (no `control.lua` needed). 3 rounds, `game.speed` 20–50.
  - **Results (headless, 2026-10-15, 2.1.21):**

    | Settlers | Built (totals) | Expected from list | Verdict |
    |----------|----------------|--------------------|---------|
    | settler a ×(10 + 5×5) | nest-a **23 / 23** | only nest-a | ✅ A unit only builds what's in its own list |
    | settler b ×5 per group, 6 groups | nest-a 6, nest-b **13** | 1 : 2 | ✅ Duplicates are weights |
    | mixed 5 a + 5 b | nest-a 6, nest-b 2 | a → a; b → a/b | ✅ Each settler builds from its own list |
    | small biter (vanilla) | biter-spawner 5, spitter-spawner 4, small worm 11 | 1 : 1 : 2 | ✅ Matches `enemies.lua:104` |
    | medium biter (vanilla) | biter-spawner 7, spitter-spawner 4, small worm 3, medium worm 7 | 1 : 1 : 1 : 1 | ✅ Roughly (small sample) |

    - **Count:** at most one entity per settler. Groups of 5 built 2–5; settlers that find no room build nothing.
    - **Failures depend on the place, not the unit:** a destination in or next to water (or otherwise blocked) makes the command fail before `on_build_base_arrived`; any unit type works on open land. A group of 30 also failed (same cause most likely, not retested).
    - **Consequence for D16/D24:** settler and evolution gating = data only (`buildable_entities` with weights). The script only does distance (`hf-nest-rules`: `min_distance`, `fallback`). Confirmed.
- [x] **EB3. Speed pass.** Applied 2026-10-15 in `Hostile-fauna/data-updates.lua` (D13 table): small 0.225, medium 0.2 (D30: briefly 0.175, reverted), big 0.16, behemoth 0.125; spitters vanilla. `distance_per_frame` scaled by the same factor (no sliding legs).
  - **Headless (2026-10-15, 2.1.21):** runtime speeds read back exactly as set. Note: the EB2 test units are copied in `data.lua` (before `data-updates`), so they keep vanilla speeds.
  - [x] In game (user): can you run away from and kite a group of each tier? Do the legs look right? Do challenges and crusades still feel OK (E2: slower arrival; the challenge slow stickers may now be too much)?
    - **In game (user, 2026-10-15, 2.1.21)**, bare character with `/cheat-kit smg-red`, rows of 5 small / 5 medium / 3 big / 2 behemoth:
      - Outrunning: feels OK for every tier. ✅
      - Kiting small: a bit tricky, but works. ✅
      - Kiting "medium": the speed helps, but still too hard to shoot them down before they reach you. **Correction (user, same day):** this was most likely the big biter.
      - Retest, one biter per tier, `smg-red`: **1 big biter: just doable to kill, OK to run away from.** Data point for D19: red ammo is one tier below the big's checkpoint (uranium), and it already feels like "possible with effort", even with vanilla resistances (8 flat → 0.45 per bullet). Medium was not consciously noticed, so 0.2 is kept.
      - Animations: look normal. ✅
      - Challenges / crusades (user, 2026-10-15): crusades still feel fine. Not a real test yet: crusades get retuned per checkpoint anyway (D19–D23).
- [ ] **EB3b. Demolisher replacement.** First non-magma wyrm `segmented-unit`, wired into `territory_settings.units`. Sub-plan (draft 2026-10-15), **awaiting go-ahead**:
  - **Facts (game files 2.1.21):** Space Age defines a global `make_demolisher(base_name, order, scale, damage_multiplier, health, regen, speed_multiplier, factoriopedia_simulation, sounds)` (`space-age/prototypes/entity/enemies.lua:2936`). It builds the head, the segments, the corpse and the effects (fissures, ash clouds). Vanilla calls: small 30000 HP / regen 40, medium 100000 / 130, big 300000 / 400 (`:6500–6502`). Magma theme lives in: `update_effects` (ash-cloud trail, lava particles), `update_effects_while_enraged`, the revenge attack (fissures → magma eruption), and `draw_as_glow` layers in the animations.
  - **Approach:** call `make_demolisher("hf-earth-wyrm-small", ...)` etc. in `Hostile-fauna`, then patch the result: tint all animation layers earth-brown, drop the glow layers, remove ash-cloud and lava `update_effects`. Revenge attack: see Q-EB3b-2.
  - **Wiring (Hostile Territory):** `nauvis-territory.lua` `units` → the three earth wyrms; `scripts/rally.lua` `GUARDIANS` / `SIZE` → new names; `prototypes/entity/rally.lua` copies the guardian stats → from the new names.
  - **Stats:** same as the demolishers for now (D4: keep the curve; "guardians too strong" is EB6).
  - **Patrol paths and water (measured 2026-10-15, 2.1.21):** paths are loops of ~55 points, ~25 tiles apart. **18.6 % of points and 18.8 % of segment samples are on water** (5616 points, 101 territories). Demolishers' collision mask has no water layer, so they walk over it. Tested: adding `water_tile` to the wyrm's collision mask does **not** change path generation (still 24 %, reverted; the wyrm would likely get stuck instead). Fix needs script, Q-EB3b-4.
  - Steps:
    - [x] 1. Earth wyrm prototypes (3 sizes) in `Hostile-fauna/prototypes/earth-wyrm.lua` (+ locale), load check headless (2026-10-15, 2.1.21): OK.
      - **In game: failed to load** (user, 2026-10-15): `__space-age__/graphics/icons/hf-earth-wyrm-small-remains.png` not found. `make_demolisher()` builds icon paths from the unit name. Fixed: `fix_paths` points them back to the vanilla demolisher files; icons tinted. New check `tools/check-paths.py` on a `--dump-data` dump: 2246 paths, 0 missing.
    - [x] 2. Wired into Hostile Territory (`nauvis-territory.lua` units, `rally.lua` guardians — old demolisher names kept in `SIZE` for older saves — rally prototype). **Headless (2026-10-15, 2.1.21):** 101 territories within 1600 tiles, 78 wyrms (10 small, 26 medium, 42 big), no demolishers.
    - [ ] 2b. **Wyrms and water** (D32). `scripts/patrol.lua`: territories queued on registration, (A) runs once all chunks under the path exist (2 fixes / 10 checks per second); (B) every 31 ticks (30 is taken by challenges) for wyrms that are fully active and not patrolling.
      - First attempt (snap path points to land, 2026-10-15): points on water 0, but straight segments still crossed lakes (2.3 % of samples, crossings up to 306 tiles). Dropped for D32.
      - **Headless (2026-10-15, 2.1.21, seed 12345, 1600-tile radius):** 98 territories → 7 lakes destroyed; 5 dry, 43 got land (78 500 tiles, ~1800 per territory), 43 still waiting for chunks at the map edge. **Path on water afterwards: 2 of 69 363 one-tile samples (~0 %).** Tiles under path points: natural dirt / grass / sand / red desert, `landfill` for 292 of 2 589 (mid-lake, no land within 16 tiles).
      - **(B) headless:** a small wyrm forced to `enraged_at_nothing` towards a lake: 90 water tiles turned into land along its route in 25 s; head ended on `dirt-5`.
      - [ ] In game (user): do the causeways look OK? Kite a wyrm over water: does it leave land behind? Any hitches when a territory gets its land (UPS)?
        - **In game (user, 2026-10-15, 2.1.21):** (B) kiting over water leaves land behind ✅. No UPS hitch noticed ✅. **Found a place where the patrol path still crosses water with no land** ❌, see Q-EB3b-6.
    - [ ] 2c. **Water fix per chunk, no lake destroy** (D33). Draft 2026-10-15, **awaiting go-ahead**:
      - On registration: cut the path into samples (as now) and bucket the **water candidates** by chunk: `record.patrol_todo["cx,cy"] = {samples}`, plus an index `storage.patrol_by_chunk["cx,cy"] = {[id] = true}`.
      - A sample is ready when every chunk its land circle touches is generated (otherwise map gen would overwrite our tiles later). Ready samples on water → `make_land` (as now).
      - Triggers: right after registration (all chunks that already exist), and `on_chunk_generated` on Nauvis (look up the index, retry that chunk's samples and the neighbours' edge samples). Same budget as now (a few territories per tick via the pending queue), so no spikes.
      - Territory done when `patrol_todo` is empty → `record.patrol.result = "land"`/`"dry"`, index entries removed.
      - Lake rule removed (`LAKE_SHARE`, `territory.destroy()`). `record.patrol.water` still counts the share, for the debug output.
      - Chunk request on chart stays (so a seen territory gets its whole path fixed).
      - Migration: existing records with `patrol` already set are left alone; pending ones get bucketed on load (`territories.scan`).
      - Check headless: on the seed 12345 map, generate only the start area, check partly generated territories already have land in their generated chunks; then generate the rest, check water on paths ~0 % and no territory destroyed. In game (user): no wyrms on water near you, no vanishing territories.
      - **In game (user, 2026-10-15, 2.1.21):** challenges and crusades still work ✅. **A wyrm spawned from a lost rally showed some glow** (name correct), see Q-EB3b-7.
      - Superseded by D34 / step 2d: the per-chunk code (`patrol_todo`, `patrol_by_chunk`, chunk requests on chart) gets removed there.
    - [ ] 2d. **Reroute patrol paths over land** (D34, D35). Built 2026-10-15 in `scripts/patrol.lua`, headless ✅, **in game open**.
      - **Land grid** per territory: elevation at **integer** positions on a 4-tile grid over the territory's chunks (`territory.get_chunks()`, 64 points per chunk). Land = elevation > `SHORE` (1.0, keeps ~1–2 tiles off the shore).
      - **One job at a time** (`storage.patrol_job`), spread over ticks, stages: `fetch` (8 chunks per tick, one `calculate_tile_properties` call) → `label` (connected land parts, flood fill) → `snap` (points on water → nearest land cell, search capped at 256 cells ≈ 32 tiles, deeper points dropped; then keep the part with the most points, D35) → `route` (straight if clear, else A*, then shortened to the corners it needs; A* and corners resumable). `label`/`snap`/`route` share 600 cells per tick. Then `set_patrol_path`.
      - Fewer than 3 points left on land → `result = "water"`, engine path kept (D35). Nothing changed → `"dry"`.
      - `record.patrol = {v = 2, points, snapped, dropped, detours, chunks, ticks, result}`. Old records (no `v`) get rerouted on load; `patrol.migrate()` clears `patrol_by_chunk` / `patrol_todo` (old land strips stay, harmless).
      - **Removed:** per-chunk fix (`patrol_todo`, `patrol_by_chunk`, `on_chunk_generated` hook, chart-triggered chunk requests, `patrol_charted`). Remote interface: `reroute(id)` (runs a job in one go) and `patrol()` (stats per id).
      - **(B) unchanged.**
      - **First tries (headless, same day):** one territory per tick was far too slow: 60 ms median, 714 ms worst per territory. Causes: each `calculate_tile_properties` call costs ~0.7 ms extra (so fetch per chunk was bad), ~3 µs per point incl. Lua, and uncapped lake snaps (up to 690 ms). Fixed by batching, budgets and resumable stages.
      - **Headless (2026-10-15, 2.1.21, Hostile-fauna + Hostile Territory, 1600 tiles):**

        | | Seed 12345 | Seed 987654 |
        |---|---|---|
        | Territories / wyrms | 98 / 98 | 100 / 100 |
        | Path on water, engine path (1-tile steps, real tiles) | 21.9 % | 23.9 % |
        | **Path on water, rerouted** (without `water` territories) | **0.06 %** | **0.06 %** |
        | `water` territories (engine path kept) | 1 | 1 |
        | Path points outside the territory | 3 of 6008 | 2 of 5970 |
        | Wyrms after `set_patrol_path` | all `patrolling` | all `patrolling` |

        - Time per tick while a job runs (seed 12345, 927 ticks): median 1.6 ms, p95 3.6 ms, p99 6.6 ms, max 8 ms; the first call ever takes ~21 ms (noise warm-up, once). CPU per territory ≈ 50 ms total, ≈ 30 ticks (0.5 s). ~100 territories queued at once (1600-tile radius) take ~50 s.
        - Knobs if it hitches: `FETCH_CHUNKS`, `WORK` (lower = smoother, slower).
      - [x] **In game (user, 2026-10-15, 2.1.21), new map:** some wyrms start on water (they spawn before their territory's job has run), then their path gets rerouted and they keep off water from then on. "Fine enough for now" (user) ✅.
        - Possible later fix if it bothers: move a wyrm to its first new path point when its path gets rerouted (only if no player sees it).
      - [ ] Old save: loads, territories get rerouted, no errors. Not reported yet.
- [ ] **EB3c. Wyrm control tests** (started 2026-10-15, user: "start the headless test"). Goal: find out how a script can keep a wyrm in place and move it only when we want. Segmented units are **not commandable** (no `set_command`). Levers (2.1.21 docs): `set_ai_state`, `speed` (writable, the AI accelerates back to `target_speed`), `move_forward`, `set_body_nodes`, `minimum_activity_mode`, per-unit territory + `set_patrol_path`, and prototype speeds (`patrolling_speed`, `investigating_speed`, …, may be 0).
  - Harness: test mod `ht-wyrm-control-test` (data stage: `hf-earth-wyrm-small` copy `hfc-dormant` with `patrolling_speed = 0`, `investigating_speed = 0`). Each wyrm in its own script territory on a generated chunk, `minimum_activity_mode = full` (headless has no players, so units would sleep). Log head position + AI state every second over RCON.
  - Small earth wyrm speeds (tiles/tick): patrol 0.018, investigate 0.037, attack 0.064, enraged 0.092; acceleration 0.00015 (~2 min from 0 to enraged speed in theory, in practice ~10 s to patrol speed); `enraged_duration` 1800 (30 s).
  - **Headless results (2026-10-15, 2.1.21, Hostile-fauna + test mod only, seed 12345, 2 runs of 100 s):**

    | Test | Result |
    |---|---|
    | C1 Dormant (`patrolling_speed = 0`, `investigating_speed = 0`) | ✅ Loads. Stays exactly in place (0.0 tiles in 100 s), state stays `patrolling`, `target_speed` 0 |
    | C1 + `damage()` without `cause` | ❌ No reaction: stays `patrolling`, doesn't move (and regenerates) |
    | C1b + damage with `cause` = character 25 tiles away | ✅ `enraged_at_target` → kills the character → `enraged_at_nothing` → `patrolling` after the rage (test copy: 10 s), then **stops where it is** (48 tiles from where it started). It does **not** go back home |
    | C1c + `set_ai_state{enraged_at_nothing, destination, last_damage_time = game.tick}` | ✅ Runs at enraged speed towards the destination, stops when the rage ends (45 tiles away) |
    | C1d + `set_ai_state{attacking, target = character}` | ✅ Goes for it at attack speed, kills it, then stops |
    | C1e + `set_ai_state{investigating}` | Holds the state, but doesn't move (`investigating_speed` 0), as expected |
    | C2 Speed clamp (`speed = 0` every tick, normal wyrm) | ✅ Held: 0.2 tiles of drift in 20 s. After release it speeds up again and patrols normally |
    | C3 Forced `investigating`, 150 tiles away (outside its territory) | ✅ Goes there at investigate speed (~2.2 tiles/s), holds the state until it arrives (~68 s), then `patrolling` back to its path |
    | C3b Same, 63 tiles away inside the territory | ✅ Same, arrives after ~28 s |
    | C4 One-point patrol path | Circles the point forever, up to ~20 tiles away from it. Never stands still |
    | C5 `set_body_nodes` on an asleep wyrm (+20 tiles in x) | ✅ Accepted, head moves exactly 20 tiles, stays `patrolling`. Wakes it briefly (`minimal`, `full`), then it falls asleep again |
    | C6 Asleep vs full | An **asleep** wyrm does not move at all. Without players, a wyrm with no `minimum_activity_mode` goes `full` → `minimal` (~6 s) → `asleep` (~12–16 s). `minimal` still moves |

  - **What this means:**
    - "Stays put until we decide" works best with the **dormant prototype**: no per-tick script, and it still fights back when a player attacks it. To move it, use `set_ai_state` `enraged_at_nothing` (with a destination) or `attacking`. `investigating` doesn't move it.
    - A dormant wyrm **doesn't return home** after a fight. A script must bring it back (e.g. `enraged_at_nothing` towards home, or `set_body_nodes` while no player can see it).
    - With a normal wyrm, `investigating` + `destination` is a clean "go to X" order: it holds the state until it arrives, then patrols again.
    - The speed clamp works too, but costs a script call per wyrm per tick.
    - Scripted movement away from players needs `minimum_activity_mode` (asleep wyrms don't move).
  - [x] C1. **Dormant prototype.** Loads? Head moves < 1 tile in 20 s? Then damage it: does it get enraged and move? After the rage: stops again? → yes; only damage with a `cause` enrages it; stops where the rage ends.
  - [x] C2. **Speed clamp.** → holds, released fine.
  - [x] C3. **Forced `investigating`** → goes there, holds until it arrives, then patrols.
  - [x] C4. **One-point patrol path** → circles, ~20 tiles out.
  - [x] C5. **`set_body_nodes` on a sleeping wyrm** → works, stays `patrolling`.
  - [x] C6. **Asleep vs full** → asleep = frozen.
  - [ ] In game (user): commands in [commands.md](commands.md) "Wyrm control". Check how it looks: does a dormant wyrm look natural standing still (animation, idle effects)? Does a `set_body_nodes` jump look bad when you see it? Does a forced `investigating` look natural?
- [ ] **EB4. First niche units.** Build 2–3 units. In game: do they feel different, and do they combine well?
- [ ] **EB5. Plug into the mod.** Use them in challenge rings and crusade armies, and possibly in spawners (`result_units`).
- [ ] **EB6. Tune.** HP, damage, numbers per ring and evolution. Resistances per the weapon-checkpoint effort bands.

## Open questions

Answered 2026-10-12: rounds 1–3 (D1–D18).

1. **Play-session telemetry** (raised 2026-10-15): collect data (kills, damage, deaths, time per fight) while the user plays, to tune effort bands (D19). Via a joinable headless server + RCON, or in-mod logging. Needs its own short plan.


### 2.1 changelog review (2026-10-15, 2.1.7 → 2.1.21)

Done: D25 is complete. Hostile Territory and cheating-mod use **none** of the removed APIs (checked: `LuaEntity.active`/`minable` writes, `neighbors`, `fluidbox`, recipe `category`, `build_base_evolution_requirement`, `map_settings.steering`, `create_profiler`).

| Change | Effect on us |
|--------|--------------|
| `healing_per_tick` now works on any entity with health | Caused the rally regen bug. Fixed (vision-plan H-6) |
| `build_base_evolution_requirement` removed (prototype + runtime read) | Expansion section and EB2c rewritten. Evolution gating now goes through the settlers' `buildable_entities` |
| `UnitPrototype` / `SpiderUnitPrototype::buildable_entities` | Native settler gating (D16) |
| `UnitPrototype::steering` (moved from `MapSettings`) | Per-unit steering: a new lever for swarmers vs. brutes. Undocumented fields, test before use |
| `EnemyExpansionSettings::evolution_group_size_factor`, `min_expansion_distance` | Map settings we can tune in `Hostile-fauna` |
| `EnemySpawnerPrototype::spawn_blocked_trigger`. Vanilla spawners spit acid when blocked | Walling in a nest now hurts. Note for crusade staging (we spawn by script, not affected) |
| Shotgun pellets briefly slow enemies | Relevant to checkpoints (D21): the shotgun already has a niche |
| `ScriptTriggerEffectItem::custom_event` | Script triggers can raise our own event. Cleaner control hooks (death effects, healer idea) |
| `LuaForce::add_alert` / `add_custom_alert` | Possible crusade and challenge alerts in the alert bar |
| `LuaTerritory::visibility_condition` (`never` / `has-unit` / `always`) | Could control how territories show on the map. Look at with the overlay (plan.md) |
| `"+"` dependency modifier (optional but on by default) | Option for the Hostile-fauna dependency if it shouldn't be hard |
| Bugfix 2.1.21: unit groups set to wander could ignore new commands | Our crusade guard uses `wander`; this fix helps us |

3. ~~**Q-EB2-2: kiting / skirmisher niche.**~~ Decided D29 (parked). Data-only kiting doesn't work. Options: (a) script in `Hostile-fauna`: kiter units tracked in a list, every ~0.5 s a unit closer than X to its target gets a short "step back" command, then attacks again; (b) use the `min_range` behaviour as its own niche: a ranged unit that can't shoot up close, so rushing it is the answer; (c) park the skirmisher niche until after EB4.

4. ~~**Q-EB3-1: medium biters too hard to kite with red ammo.**~~ Decided D30 (a). Red ammo is roughly the medium's checkpoint weapon, so it should feel manageable. Math: red ammo does 3.6 per bullet → 21 bullets per medium (~2 s of SMG fire); closing speed while backing off is only 0.05 tiles/tick (3 tiles/s). Options: (a) medium → 0.175 (70 %); (b) keep, fewer mediums per group (balance through the mix, D4); (c) keep and wait for EB6 tuning.

5. ~~**Q-EB3b-1: names.** `hf-earth-wyrm-small/medium/big`? Display name "Small earth wyrm" etc.?~~ D31.
6. ~~**Q-EB3b-2: revenge attack.** The demolisher's revenge hit creates magma fissures. For the earth wyrm: (a) keep the fissure mechanic, just retinted (cheapest); (b) swap it for a non-magma effect, e.g. a rock burst (physical area damage + a slow sticker); (c) no revenge attack for now.~~ D31.
7. ~~**Q-EB3b-3: ash cloud.** Vulcanus demolishers leave damaging ash clouds. Drop entirely, or replace with a dust cloud (no damage, just looks)?~~ D31.

8. **Q-EB3b-4: how to keep patrol paths off water.** (a) **Snap + subdivide** (in `territories.lua` when a territory is registered): walk each path segment in ~4-tile steps, move every water sample to the nearest land tile within ~48 tiles, drop samples with no land nearby, then `set_patrol_path`. Wyrms also teleported off water if they spawned on it. Check headless with the same water metric. (b) Also delete territories that are mostly water (e.g. > 50 % of samples), since a lake territory makes a poor fight. (c) Accept water.

9. ~~**Q-EB3b-5: route patrol segments around water.**~~ Replaced by D32 (make land). Snapping fixes points but not the lines between them. Options: (a) **pathfinder**: for each segment that still crosses water, `surface.request_path` between its land ends with a water-only collision mask; the returned waypoints go around the lake (async: `on_script_path_request_finished`, a few requests per territory); (b) accept short crossings (≤ 3 tiles = narrow streams) and destroy territories that still have long ones (would remove many territories on default Nauvis); (c) accept the current state.

10. **Q-EB3b-6: patrol over water with no land** (user, 2026-10-15). Unknown which case: (a) territory still pending ((A) never ran: chunks under the path missing, or the chart-triggered request didn't fire); (b) (A) ran, but the wyrm's real route leaves the strip (corner cutting while patrolling); (c) something else. Next: stand in that territory and run the "patrol result" command in `commands.md` (`nil` = pending).
    - **In game (user, 2026-10-15, 2.1.21):** count = `{dry = 1, land = 9, pending = 21}`. So most territories near the player are still pending, and their wyrms walk on water: (a) is the likely cause. Also seen: wyrms walking on a lake vanished when the user came closer, and the region then "behaved weird". Most likely the lake rule: charting requested the missing chunks, (A) ran, > 50 % water → `territory.destroy()` in front of the player. Works as designed, but looks broken. "Weird" (user): the wyrm and the territory vanished and came back several times. Likely loop: destroy frees the chunks → neighbouring chunks get generated (partly our own requests) → the engine builds a new territory there → registered, still a lake → destroyed again. Decided D33 (per-chunk fix, no lake destroy), step 2c.

11. **Q-EB3b-7: glow on a rally-spawned wyrm** (user, 2026-10-15). Head and segment sprites have no glow layers (checked `enemies.lua`). Likely sources the retint doesn't touch: shared Vulcanus particles in `update_effects` (`vulcanus-blood-particle-lower-layer-small`, lava particles), and the ash cloud in `update_effects_while_enraged` (kept on purpose, D31). A wyrm fresh out of a crusade fight is probably enraged, which would explain why only that one looked different. Needs the user to describe it (glowing body vs. orange splashes/smoke).

Answered 2026-10-15: checkpoint questions → D19–D23, nest rule format → D24, distance swap target → D26.

12. **Q-EB3b-8: route patrol paths around water using the map-gen noise** (raised 2026-10-15). The engine builds the path from the territory's chunks only (`create_territory` docs: "generated … based on `chunks`"); no prototype or noise hook steers it, and most chunks under it don't exist yet when it's made. But Nauvis water is `water_base(...)` = `elevation < 0` (`base/prototypes/tile/tiles.lua:963,1061`), and `surface.calculate_tile_properties({"elevation"}, positions)` evaluates that noise **for ungenerated chunks**. So the path could be rerouted over land at registration (snap + detours via a coarse grid search on elevation, then `set_patrol_path`), no waiting for chunks, no landfill strips. Would replace (A) of D32/D33; (B) (kiting builds land) can stay.
    - **Headless check (2026-10-15, 2.1.21, vanilla Space Age, ±1040 tiles, every 4th chunk = 1.08 M tiles per seed):** `elevation < 0` vs. tile `collides_with("water_tile")`:

      | Seed | Sample at | Match | Elev. water, tile land | Elev. land, tile water |
      |------|-----------|-------|------------------------|------------------------|
      | 12345 | tile centre (+0.5) | 99.73 % | 1205 | 1769 |
      | 1 | tile centre | 99.72 % | 1315 | 1729 |
      | 987654 | tile centre | 99.72 % | 1494 | 1590 |
      | 12345 | **tile corner (integer)** | **99.96 %** | 153 | 316 |
      | 1 | tile corner | **99.95 %** | 176 | 343 |
      | 987654 | tile corner | **99.96 %** | 203 | 239 |

      - Sample at **integer positions** (map gen evaluates tile corners).
      - Mismatches are almost all shoreline tiles (|elevation| < 1). A few water tiles have elevation up to ~4 (short diagonal runs, e.g. seed 12345 around (-767,-128)): thin water lines the elevation doesn't show. A margin of ~1 elevation (or 1–2 tiles) covers nearly all of it, and (B) catches the rest.
      - Cost: ~1.15 µs per tile (1.08 M tiles in ~1.2 s). One path at 1-tile steps (~1 400 tiles) ≈ 2 ms; a 4-tile grid over a 384×384 territory (~9 000 points) ≈ 10 ms. Fine if spread over ticks.
      - Not checked: map presets or settings that override `elevation` (e.g. island). `calculate_tile_properties` should use the surface's settings; check if we support them.
    - **Verdict: works.** Decided D34 (user, 2026-10-15): reroute with the noise, keep (B). Step 2d.

13. ~~**Q-EB3b-9: territories with no land route** (step 2d). A river or a big lake can split a territory, or it can be mostly water. Options: (a) **keep the land part with the most path points**, drop the rest of the path (recommended; the territory keeps its chunks, the wyrm just patrols one side); (b) keep the engine path in that case and let (B) make land when a player is near; (c) both: (a), but if that land part is tiny (< ~25 % of the territory's land cells or < 4 path points), fall back to (b). And for a territory that is **almost all water** (island or no land at all): keep the engine path (wyrm swims, (B) builds land when seen), or destroy it (rejected in D33)?~~ Decided D35.

14. **Q-EB3b-10: wyrms spawn on water** (user, 2026-10-15). How spawning works: the engine creates the wyrms with the territory (`territory_settings.units`); no prototype or noise setting controls where. **Headless (2026-10-15, 2.1.21, seed 12345)**, 92 wyrms a few seconds after creation, before their reroute: all within 32 tiles of a point on the **original engine path** (52 within 8 tiles), already `patrolling` towards the next waypoint, at random places along the loop. **19 of 92 heads on water** (~20 %, same as the path's water share). So they spawn somewhere on the engine path, which is why some start on water. Script tools: no teleport, but `LuaSegmentedUnit.set_body_nodes(nodes)` lays the whole body anew (106 nodes for these wyrms) and `set_ai_state{type = patrolling, waypoint = i}` picks the next path point.
    Options: (a) **when a reroute finishes, move its wyrms onto the new path**: body nodes laid back along the new path from the point nearest to the head, waypoint = the next point. Only for wyrms no player can see (`activity_mode` not `full`), so nothing visibly jumps. Needs a headless test first (does `set_body_nodes` work on a sleeping wyrm, does it keep patrolling); (b) only set the waypoint to the nearest new point: still starts on water but heads to land at once (about what happens now); (c) leave it.
    - **Discord claim checked (2026-10-15):** "wyrms have noise expressions for spawning". Game files: `TerritorySettings` has only `units`, `territory_index_expression`, `territory_variation_expression`, `minimum_territory_size`; `SegmentedUnitPrototype` has no autoplace; Vulcanus uses the same two expressions as we do (`planet-vulcanus-map-gen.lua:891-920`); the only demolisher `autoplace` is the corpse rock (`probability_expression = "0"`). So the noise is the **variation** expression (which unit, negative = none).
    - **Headless test (2026-10-15, 2.1.21, seed 12345, 1600 tiles):** a throwaway test mod appended `- 99 * (elevation < 0)` to `hostile_territory_variation`. Same 98 territories in both runs.

      | | Baseline | Elevation gate |
      |---|---|---|
      | Wyrms | 98 | 88 |
      | Heads on water | 20 | 13 |
      | Per territory | | 86 same spot, 1 moved ~24 tiles (big → medium), **10 lost their wyrm** (7 had spawned on water, 3 on land) |

      - The gate **removes** wyrms, it does **not move** them. Wyrms with heads deep in water (elevation down to −26) stayed, while 3 on land were lost. So the variation expression is evaluated at some other point of the territory, not where the wyrm appears. Noise can't steer the spawn spot.
      - Conclusion: no map-gen fix. Option (a) (move wyrms onto the rerouted path) remains the way.
