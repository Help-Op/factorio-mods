# Hostile Territory: Vision

## Goal

Make territories the central mechanic on Nauvis.

- **Enemies defend territory.** They don't attack whatever is closest.
- **Taking territory is a challenge.** Attacking a territory starts a challenge mode (Vampire Survivors / bullet-hell style) that gets harder the further out you go.
- **Enemy attacks are crusades.** Pollution and evolution build up into a planned, announced attack to reclaim one specific territory.
- **Losing is recoverable.** A lost territory can be won back, so attacks can be dangerous without wiping the base.

### Problems this solves

| Vanilla problem | Our answer |
|-----------------|------------|
| Attacks settle into an equilibrium: every side is under constant attack, but nothing is ever really at risk. | Fewer, bigger, announced attacks on one target. |
| Making enemies stronger just wipes the base, which isn't fun. | The stake is one territory, not the whole base, and it can be retaken. |
| Expanding has no real cost besides more pollution. | Every new territory is a fight, and fights scale with distance. |

## Core loop

```
hostile ──(player triggers)──> challenge ──(guardian killed)──> claimed
   ^                               │                               │
   │                         (player fails)                (biters start migrating
   │                               v                         to a staging nest)
   │                            hostile                            v
   │                                                           warning (yellow/orange)
   │                                                               │
   │                                                     (critical mass reached)
   │                                                               v
   │                                                           crusade
   │                                                       │              │
   └──(rally built + no military + N enemies for X s)──────┘     (player holds)
        guardian respawns                                            v
                                                                  claimed
```

### Territory states

| State | Meaning | Map colour |
|-------|---------|-----------|
| Hostile | Has a guardian (demolisher or custom defender). | Default red |
| Challenge | Player triggered it; challenge is running. | TBD |
| Claimed | Guardian dead; player owns it. | None / TBD |
| Warning | Biters are migrating to a staging nest next to this territory. | Yellow / orange |
| Crusade | Crusade is attacking this territory. | TBD (e.g. bright orange) |
| Lost | Enemy reclaim succeeded; guardian respawns → back to Hostile. | Default red |

## Crusade flow

| Step | What happens | Ends when |
|------|--------------|-----------|
| 1. Budget | Pollution + evolution build up. | The budget is enough for a crusade. |
| 2. Pick target | Choose a claimed territory, and a biter nest in a neighbouring hostile territory as the staging point. | Instantly. |
| 3. Migration | Biters that would normally attack migrate to the staging nest **without passing through the player base**. Target territory turns yellow/orange. | Critical mass at the staging nest. |
| 4. Assault | The army attacks the target territory and heads for a central spot. | Units reach the central spot, or the army is wiped out (player holds). |
| 5. Rally | Enemies build a structure at the central spot (the "rally"). | Rally finished, or destroyed. |
| 6. Hold | Rally stands, no player military in the territory, at least N enemy units inside. | Held for X seconds → **territory lost**. |
| 7. Reclaim | Guardian respawns via `regenerate_segmented_units()`. Territory is Hostile again. | — |

Player buildings left in a lost territory get no special handling. The demolisher attacks them, and biters attack them if they aggro.

## Decisions

### First round (2026-10-11)

- Territories are the core mechanic; everything else hangs off territory state.
- **Challenge trigger:** anything that triggers the guardian counts: damaging it, or building inside its territory.
- **Challenge mode:** more enemies than vanilla. They may be slower to compensate. Difficulty depends on how far out the player is.
- **Crusades:** pollution + evolution trigger an attack on one claimed territory, chosen tactically.
- **Warning:** the target territory changes colour some time before the attack.
- **Recovery:** a lost territory becomes hostile again and can be recaptured.

### Second round (2026-10-11)

| Topic | Decision |
|-------|----------|
| Runtime code | `control.lua` is approved. |
| Challenge difficulty | **Distance from spawn** is the main driver. Evolution adds to it. |
| Vanilla attacks | **Turn off normal pollution attacks.** Pollution itself keeps working (it spreads, gets absorbed, drives evolution). |
| Slower enemies | Use a **slowdown sticker** on spawn. Its strength can fade as the player progresses. |
| Alternative / addition | A **wider arsenal of weaker enemies** for early challenges (e.g. tiny biters below small). To decide: does this replace the slowdown or add to it? |

### Third round (2026-10-11)

| Topic | Decision |
|-------|----------|
| Player military | **Anything that can damage enemies**: turrets, vehicles, combat robots, the character. Walls don't count. |
| Enemy holding | Baseline: **at least N enemy units inside**. May vary later. |
| Reclaim steps | Multi-step: reach a central spot → build a rally structure → no military + N enemies for X seconds → guardian respawns. The territory only counts as hostile again once the guardian is back. |
| Crusade source | Attacking biters **migrate to a nest in a neighbouring territory**, avoiding the player base. |
| Warning trigger | The target turns yellow/orange **when migration starts**. The crusade starts at **critical mass**. |
| Lost buildings | Nothing special. The demolisher and biters attack them as normal. |

### Fourth round (2026-10-11)

| Topic | Decision |
|-------|----------|
| Migration (V8) | **POC: spawn the army at the staging nest** from the budget (option b). **End goal: walk with waypoints through enemy-controlled territories** (option a). If the player kills migrating units on the way, that's fine. |
| Rally structure | A **new enemy building that takes time to build**. Destroying it **resets the hold timer**. |
| No nest next to target | The enemy **builds a staging nest** in the neighbouring hostile territory during the warning phase. |
| Pollution budget | **Pollution absorbed by nests**, as in vanilla. General rule: follow the existing pollution rules wherever we can. |

### Fifth round: challenge mode (2026-10-11)

Everything about challenge mode is a **POC description** and will evolve. Direction: **small, easy challenges close to base, more complex ones further out.**

| Topic | Decision |
|-------|----------|
| Enemies | Biters and spitters spawn in a **ring around the player, just off-screen**, plus the guardian. |
| Win | **Kill the guardian.** |
| Lose | **Anything that would normally make the guardian lose aggro** (player leaves, dies, …). Then waves stop, leftover challenge enemies despawn, guardian heals, territory resets to Hostile. |
| Trigger | Same events as Vulcanus (damage, building in territory), but the challenge **only really starts once the guardian is close enough to attack the player**. Before that, no spawning. |
| Remote building | Robots building in a territory with the player far away must **not** start spawning around the player. Needs a separate rule (Q5a). |
| Scaling | **Rings of about 500 tiles** from spawn. Each ring raises wave size and enemy tier. Evolution shifts the mix toward bigger enemies, like vanilla spawn tables. |
| Weak enemies vs. slowdown | **Both.** One or two weak tiers below the small biter for the first rings; slowdown on everything, fading as the rings go out. |

### Sixth round (2026-10-11)

| Topic | Decision |
|-------|----------|
| Remote building (Q5a) | **POC: plain vanilla.** The guardian destroys the buildings, no challenge. Revisit later. |
| Concurrency (Q6) | **One challenge per territory, one active challenge per player.** Several players can join the same challenge, or run different challenges at the same time. |
| Crusade numbers | POC defaults: **N = 10** enemies, **X = 60 s** hold, migration **max 5 min**, **15 min** cooldown, **one crusade at a time**. |
| Biter nests (Q12) | **Keep vanilla nest generation and expansion** (POC). |

## Confirmed facts

| Fact | Source |
|------|--------|
| `LuaTerritory.regenerate_segmented_units()` respawns the guardian and makes a cleared territory hostile again. | `territory-recapture-plan.md`, tested 2026-10-11, 2.0.77 |
| Per-territory colour works with `rendering.draw_rectangle{render_mode = "chart"}` per chunk. Force colour does not change the overlay. | `territory-recapture-plan.md`, tested 2026-10-11 |
| Territories already generate on Nauvis via map gen, with a safe starting area (384 tiles). | `plan.md` steps 1–6 |
| "A territory with no units will not appear on player's maps." A claimed territory loses the red overlay by itself. | `LuaTerritory` docs, 2.0.77 |
| `LuaTerritory` has no id, but it is a `RegistrationTarget`: `script.register_on_object_destroyed(territory)` returns a registration number we can use as a key. | `runtime-api.json`, 2.0.77 |
| `LuaSegmentedUnit.get_ai_state()` returns `{type = defines.segmented_unit_ai_state.*}`: `patrolling`, `investigating`, `attacking` (+ `target`), `enraged_at_target` (+ `target`, `attacked_me`), `enraged_at_nothing` (+ `remaining_time`). `set_ai_state()` also exists. | `runtime-api.json`, 2.0.77 |
| Events: `on_segmented_unit_damaged`, `on_segmented_unit_died`, `on_post_segmented_unit_died`, `on_segmented_unit_created`, `on_territory_created`, `on_territory_destroyed`. | `runtime-api.json`, 2.0.77 |

## Issues / risks

| # | Issue | Notes |
|---|-------|-------|
| V1 | ~~Needs `control.lua` again.~~ | Resolved: approved 2026-10-11. |
| V2 | UPS with many enemies. | Bullet-hell numbers of biters, and big staging armies, can tank performance. Needs caps and a test. |
| V3 | Unit speed is fixed per prototype. | Decided: slowdown sticker on spawn. See test T2. |
| V4 | Turning off vanilla attacks. | Candidate: map settings `unit_group.max_gathering_unit_groups = 0` / `max_unit_group_size = 0`. See test T1. |
| V5 | Detecting "guardian triggered". | Candidates: `on_segmented_unit_damaged` (exists), `on_built_entity` + `get_territory_for_chunk`. With the "real start = guardian can attack the player" rule, the AI state (V13) may be the only trigger we need. See test T3. |
| V6 | "Tactical" target choice needs a scoring rule. | E.g. border territories, near pollution, weakly defended, recently claimed. Must have a neighbouring hostile territory with a nest. |
| V7 | Demolishers on Nauvis terrain. | Still open from `plan.md` step 8 (water, trees, cliffs). |
| V8 | Migration "without going through the player base". | The engine pathfinder doesn't avoid player buildings; units attack what blocks them. Options: (a) route through hostile territories with waypoint commands, (b) spawn the units directly at the staging nest from the budget (no real walk), (c) a mix: units near the staging nest walk, the rest are spawned there. (b) is simplest and safest. **Decided:** (b) for the POC, (a) as end goal. |
| V9 | Where do the "biters that would normally attack" come from? | With auto attacks off, nests may hold idle units. Either collect those (recruit them into our group) or spawn new ones from the budget. Depends on T1. |
| V10 | Central spot and rally structure. | Need a rule for the centre (e.g. the chunk nearest the centroid of `get_chunks()`, snapped to buildable land) and a rally prototype (enemy-force entity, built over time). |
| V11 | Measuring pollution absorbed by nests. | With auto attacks off, does the engine still count absorbed pollution anywhere we can read (e.g. `game.get_pollution_statistics(surface)` per entity)? Part of T1. |
| V12 | Building enemy structures over time (rally, staging nest). | Options: place a "construction site" entity and swap it for the real one after a timer, or grow health over time. To test. |
| V14 | **Demolishers don't attack the player on sight**, only in revenge or when investigating buildings (T4). Rage lasts 30 s, then it keeps `attacking` player entities in reach. Resolved for the POC by the phase B rules. | `enraged_at_target` also has `last_damage_time` (writable) and `remaining_time`. The rule "the challenge starts when the guardian can attack the player" would mean: only after the player shoots it, or (to check) when it attacks a building near the player. And "lose = aggro lost" would mean: the challenge ends 30 s after the player stops hitting it, even while standing next to it. See open questions 3b and 5b. |
| V13 | Detecting guardian aggro: start (in range of the player) and end (aggro lost). | **Start confirmed (T4):** chasing the player gives `enraged_at_target` with `target = character`. See V14 for what that means. Likely solved: poll `get_ai_state()`. Start = `attacking`/`enraged_at_target` with a target that is a character (or near one). Lose = back to `patrolling`/`investigating`. Fallback: distance rule. See test T4. |

## Tests to run later

| # | Test | Command / steps | Check |
|---|------|-----------------|-------|
| T1 | Turn off vanilla pollution attacks (V4). | `/c game.map_settings.unit_group.max_gathering_unit_groups = 0 game.map_settings.unit_group.max_unit_group_size = 0 game.player.print("Auto attacks off")` then pollute near a nest. | Do attacks stop? Do nests still absorb pollution and fill with idle units? Does evolution still rise? Can we read how much pollution nests absorbed (V11)? |
| T2 | Lifelong slowdown sticker (V3). | To write. | Can a sticker last for the unit's whole life? Can strength vary per challenge (several sticker prototypes)? |
| T3 | Trigger detection (V5). | Use a throwaway save: these console handlers replace the scenario's own handlers for these events until you reload. Start: `/c local function terr(ent) local q = ent.position local t = ent.surface.get_territory_for_chunk{x = math.floor(q.x / 32), y = math.floor(q.y / 32)} return t and (#t.get_segmented_units() .. " guard(s)") or "none" end script.on_event(defines.events.on_segmented_unit_damaged, function(e) game.print("unit damaged: " .. e.segmented_unit.prototype.name .. " by " .. (e.cause and e.cause.valid and e.cause.name or "?") .. " for " .. math.floor(e.final_damage_amount)) end) script.on_event(defines.events.on_entity_damaged, function(e) if e.entity.type == "segment" or e.entity.type == "segmented-unit" then game.print("entity damaged: " .. e.entity.name .. " (" .. e.entity.type .. ")") end end) script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function(e) game.print("built " .. e.entity.name .. ", territory: " .. terr(e.entity)) end) game.print("T3 handlers on")` Then: (1) shoot a demolisher's head, then its tail; (2) build something inside a territory and outside one; (3) let robots build inside a territory. Stop: `/c script.on_event(defines.events.on_segmented_unit_damaged, nil) script.on_event(defines.events.on_entity_damaged, nil) script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, nil) game.print("T3 handlers off")` | **Result (2026-10-11, 2.0.77):** (1) **Both fire.** `on_entity_damaged` for each hit segment (head is type `segmented-unit`, body and tail are type `segment`), and `on_segmented_unit_damaged` with `cause = character`. Many hits show 0 damage after rounding (`final_damage_amount` < 1, pistol vs. resistances). (2) Building inside a territory reports it; outside reports none. The first command only printed the guard count. **Retest with the id version (2026-10-11): works**, e.g. `built stone-furnace, territory: id 7, 1 guard(s)`. (3) **Robot building also fires** (`on_robot_built_entity`). **Still open:** does the demolisher react to the building? Id version of the build handler: `/c script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function(e) local q = e.entity.position local t = e.entity.surface.get_territory_for_chunk{x = math.floor(q.x / 32), y = math.floor(q.y / 32)} game.print("built " .. e.entity.name .. ", territory: " .. (t and ("id " .. script.register_on_object_destroyed(t) .. ", " .. #t.get_segmented_units() .. " guard(s)") or "none")) end) game.print("T3 build handler on")` (same id as `/ht-territory`). |
| T4 | Guardian aggro (V13). | Snapshot: `/c local p = game.player local u, best for _, x in pairs(p.surface.get_segmented_units()) do local h = x.segments[1] and x.segments[1].position or {x = 1e9, y = 1e9} local d = (h.x - p.position.x)^2 + (h.y - p.position.y)^2 if not best or d < best then u, best = x, d end end if not u then p.print("No demolisher") return end local s = u.get_ai_state() local n = "?" for k, v in pairs(defines.segmented_unit_ai_state) do if v == s.type then n = k end end game.player.print(n .. " target=" .. (s.target and s.target.valid and s.target.name or "none"))` Tracker (prints every state change): `/c local last script.on_nth_tick(30, function() local p = game.players[1] local u, best for _, x in pairs(p.surface.get_segmented_units()) do local h = x.segments[1] if h then local d = (h.position.x - p.position.x)^2 + (h.position.y - p.position.y)^2 if not best or d < best then u, best = x, d end end end if not u then return end local s = u.get_ai_state() local n = "?" for k, v in pairs(defines.segmented_unit_ai_state) do if v == s.type then n = k end end local line = n .. " target=" .. (s.target and s.target.valid and s.target.name or "none") if line ~= last then last = line p.print(string.format("[%.1fs] %s dist=%d", game.tick / 60, line, math.sqrt(best))) end end) game.print("T4 tracker on")` Stop: `/c script.on_nth_tick(30, nil) game.print("T4 tracker off")` | **Result (2026-10-11, 2.0.77):** the demolisher **never attacks the player on its own**, at any distance (it patrolled past at 39 tiles). Only after being shot: `patrolling` → `enraged_at_target` (`target = character`, 16 tiles) → `patrolling` again about 26 s later at 186 tiles. Matches the prototype: `enraged_duration = 30 * 60` (30 s after the **last damage**), `vision_distance = 64`, `ticks_per_scan` (it scans its territory for things to attack). **Still open:** does building in the territory make it `investigating` / `attacking` the building (T3 step 2)?
**Second run (2026-10-11):** observed in game: the demolisher **seems to stay enraged while the player is nearby** and only calms down after the player runs away. The 30 s isn't proven either way. When the demolisher came straight for a newly built stone furnace, **the tracker printed nothing** (no state change seen). Possible reasons: it attacks while still `patrolling`, the state change was shorter than 0.5 s, or the tracker watched another demolisher (it shows the nearest one).
**Tracker v2** (adds demolisher number and `remaining_time`, printed every 2 s while enraged): `/c local last script.on_nth_tick(30, function() local p = game.players[1] local u, best for _, x in pairs(p.surface.get_segmented_units()) do local h = x.segments[1] if h then local d = (h.position.x - p.position.x)^2 + (h.position.y - p.position.y)^2 if not best or d < best then u, best = x, d end end end if not u then return end local s = u.get_ai_state() local n = "?" for k, v in pairs(defines.segmented_unit_ai_state) do if v == s.type then n = k end end local line = n .. " target=" .. (s.target and s.target.valid and s.target.name or "none") local rest = s.remaining_time and string.format(" left=%.0fs", s.remaining_time / 60) or "" if line ~= last or (s.remaining_time and game.tick % 120 == 0) then last = line p.print(string.format("[%.1fs] #%d %s%s dist=%d", game.tick / 60, u.unit_number, line, rest, math.sqrt(best))) end end) game.print("T4 tracker v2 on")`
Tests: (a) shoot once, then stand still about 20 tiles away without shooting. Does `left=` count down to 0, or does it reset while you're near? (b) Build next to its patrol path with the tracker on. Does any line appear? Is the `#number` the demolisher that comes?
**Tracker v2 results (2026-10-11, 2.0.77):**
- (a) Shot from a spidertron: `enraged_at_target target=spidertron`, `left=` counts down 30 → 0 and does **not** reset while the player is near. After the countdown it switches to **`attacking target=spidertron`** and keeps fighting, so vanilla "aggro" lasts as long as a player entity is in reach. On foot and running away (first run), it went back to `patrolling`.
- (b) Building in the territory: about 10 s after the furnace was placed, `investigating target=none` → about 10 s later `attacking target=stone-furnace` → `patrolling` after it was destroyed. The delay comes from `ticks_per_scan`.
- Runtime API: `LuaSegmentedUnit.health` is writable (for healing on fail); `LuaEntityPrototype.vision_distance` and `enraged_duration` are readable. |

## Phases (draft, to refine)

Each phase starts with a small engine test before building on it.

- [x] **A. Territory state + overlay.** Done 2026-10-11 (headless + in game). Detailed steps below.
- [x] **B. Trigger detection.** Done 2026-10-11 (headless + in game, incl. fix B7). Details below.
- [ ] **C. Challenge mode.** Spawn waves around the player; scale by distance; cap counts; end conditions.
- [x] **D. Claim.** Guardian dies → territory becomes Claimed, and a running challenge ends as won. Covered by A2 and B5.
- [ ] **E. Vanilla attacks off.** Run T1 and apply the settings.
- [ ] **F. Crusade budget.** Turn pollution + evolution into a crusade trigger.
- [ ] **G. Target + migration + warning.** Pick target and staging nest (build one if missing), spawn the army at the nest (POC), colour the target.
- [ ] **H. Assault + rally + hold.** Move to the central spot, build the rally, check hold conditions (rally destroyed → timer reset), respawn the guardian.
- [ ] **I. Balancing.**
- [ ] **J. Waypoint migration.** Replace spawned armies with biters walking through enemy-controlled territories (V8 a).

`territory-recapture-plan.md` becomes the engine-test notes for phases A and H.

### Phase A in detail (approved and built 2026-10-11)

Scope: only **Hostile** and **Claimed** are set automatically. The others come with later phases; for now they can only be set with the debug command, to test the colours.

**States you can set:** `hostile`, `challenge`, `claimed`, `warning`, `crusade`. "Lost" isn't stored: it's the moment a crusade wins, and the territory goes straight back to `hostile` when the guardian respawns.

| Item | Built |
|------|-------|
| Files | `control.lua` (event wiring, debug commands), `scripts/territories.lua` (registry + state), `scripts/overlay.lua` (map drawing). |
| Key | `script.register_on_object_destroyed(territory)`. It returns the same number when called again, so the id comes straight from the object. No chunk lookup table was needed. |
| Storage | `storage.territories[id] = {id, territory, state, overlay = {["x,y"] = LuaRenderObject}}`. |
| Surfaces | Nauvis only (POC). |
| Hostile ↔ Claimed | Claimed when the last guardian dies (`on_segmented_unit_died`; the dying unit is not counted). Hostile when a guardian is created in a claimed territory (`on_segmented_unit_created`). Other states are left alone by the scan on load. |
| Overlay | Hostile / claimed: none (the engine draws red only while there's a guardian). `challenge` purple, `warning` yellow-orange, `crusade` bright orange. Only chunks charted by the `player` force; more are added on `on_chunk_charted`. Visible to the `player` force only. |
| Debug | `/ht-territory`: id, state, guardians and chunks of the territory you stand in. `/ht-set-state <state>` (admin only). Remote interface `hostile-territory-debug.set_state(id, state)` for the headless harness. |

**Headless test (2026-10-11, 2.0.77, fresh map, Space Age + cheating-mod):**

| Check | Result |
|-------|--------|
| Registry matches engine | 71 engine territories → 71 records, all `hostile`. After generating more chunks: 140 → 140. |
| Kill the only guardian (`die()`) | `hostile` → `claimed` |
| `regenerate_segmented_units()` | `claimed` → `hostile` |
| Set `warning` with nothing charted | 0 overlay objects, as intended |
| Change state back to `hostile` | All overlay objects destroyed (49 → 0) |
| Save, restart server, load | 71 records, all ids still match, forced `challenge` state kept |
| Errors in server log | None |

Found and fixed during the test: `LuaForce.is_chunk_charted` takes `(surface, chunk)`. My doc dump had listed the parameters alphabetically.

Not testable headless: **a headless server never charts chunks** (`force.chart` has no effect, `is_chunk_charted` stays false). Drawing and `on_chunk_charted` need the in-game test below.

Harness notes: headless needs a server-settings file with `auto_pause = false` (copy `data/server-settings.example.json`), or the game stays paused without players. In Git Bash, set `MSYS_NO_PATHCONV=1`, or `/c ...` gets turned into a file path.

- [x] **A1. Skeleton.** Headless: registry complete, ids stable through save/load.
- [x] **A2. Claimed on guardian death.** Headless: correct. **In game (2026-10-11, 2.0.77): works.** `claimed`, red overlay gone.
- [x] **A3. Hostile on respawn.** Headless: correct.
- [x] **A4. Overlay per state.** **In game (2026-10-11, 2.0.77):** `warning`, `crusade` and `challenge` show the right colour, only on explored chunks; the old colour is removed each time. Newly explored chunks get coloured while in `warning`.
  - `hostile` showed no colour. Expected: hostile has no script overlay, and the engine draws red only while the territory has a guardian. The test territory probably had no guardian (killed in A2), so forcing `hostile` changed only the label. In normal play `hostile` is only set when a guardian respawns, so the red comes back. To confirm: respawn the guardian and check that the red returns.
- [x] **A5. Save/load in game.** **In game (2026-10-11, 2.0.77): works.** Colour and id kept.

### Phase B in detail (approved and built 2026-10-11)

Goal: detect when a challenge starts and ends, and set the territory state. No enemy spawning yet (that's phase C). A running challenge shows purple on the map, and the players taking part get chat messages.

**Facts it builds on (T3, T4):**

| Guardian AI state | Meaning |
|-------------------|---------|
| `patrolling` | Calm. |
| `investigating` | Noticed something in its territory (e.g. a new building), going to look. |
| `attacking` (+ `target`) | Fighting a target it found: a building, or a player entity after the rage ends. |
| `enraged_at_target` (+ `target`, `remaining_time`) | Was shot; 30 s of rage from the last hit. |
| `enraged_at_nothing` | Was shot but has no target. |

**Rules:**

| Item | Proposal |
|------|----------|
| How we detect | Every 30 ticks, check every guardian on Nauvis with `get_ai_state()` (a few hundred units; cheap). No event is needed for detection. Damage and build events are not used yet. |
| "Engaged" | State is `enraged_at_target`, `enraged_at_nothing` or `attacking` (any target). `investigating` doesn't count yet: it's the warning sign. |
| "Nearby" | A player character (or the vehicle they're in) within **R = 100 tiles** of the guardian's head. About 1.5× the small demolisher's `vision_distance` of 64. Tunable. |
| Start | Guardian engaged + at least one player nearby → challenge starts for its territory. Players nearby join (one active challenge per player). |
| Join | Another player who comes near an engaged guardian of a running challenge joins it. |
| Win | Last guardian dies → state `claimed` (phase A already does this) → challenge ends as **won**. |
| Lose | For **5 s in a row**, no guardian of the territory is engaged, **or** no participating player is alive within R. Then: challenge ends as **lost**, the territory goes back to `hostile`, guardians heal to full. |
| Remote building | Guardian attacking a robot-built building with no player nearby → no challenge (POC decision 5a). |
| Storage | `storage.challenges[territory_id] = {territory_id, players = {[index] = true}, started_tick, lose_since_tick}`; `storage.player_challenge[player_index] = territory_id`. |
| Files | New `scripts/challenge.lua`. `control.lua` adds `on_nth_tick(30)`. `territories.on_segmented_unit_died` tells the challenge it was won. |
| Debug | `/ht-challenges` lists running challenges with players and time. |

**Steps:**

**Approved (2026-10-11):** R = 100 tiles, 5 s grace, heal to full on a loss. `investigating` triggers nothing yet (the chat warning idea is postponed).

**Headless test (2026-10-11, 2.0.77):** headless has no players, so the challenge record was created by hand.

| Check | Result |
|-------|--------|
| Lose: no engaged guardian, no participant for 5 s | After 7 s: challenge gone, state `challenge` → `hostile`, guardian health 15000 → 30000 (full) |
| Win: kill the only guardian during a challenge | Challenge gone, state `claimed` |
| Errors in server log | None |

- [x] **B1. Start.** Shoot a guardian. Check: chat says the challenge started, the territory turns purple, `/ht-challenges` lists it. **In game (2026-10-11, 2.0.77):** works.
- [x] **B2. Start by building.** Build in a territory and stay near. Check: the challenge starts once the guardian goes `attacking`. Use robots far away: no challenge. **In game (2026-10-11, 2.0.77):** **issue.** The challenge starts, but the guardian is only `attacking` the building, not enraged at the player. Once the building is gone it goes back to `patrolling`, and the challenge is lost unless the player attacks it. See B7. **Retest with B7 (2026-10-11, 2.0.77): works.** Remote building: the spidertron (player 100+ tiles away) builds in a territory, the guardian gets enraged at it, and **no challenge starts**, as intended.
- [x] **B3. Lose by leaving.** Start a challenge, then run away. Check: about 5 s after it calms down (or you're 100+ tiles away), the challenge is lost, the territory is red again, and the guardian is back at full health. **In game (2026-10-11, 2.0.77):** works.
- [x] **B4. Lose by dying.** Check: lost, same as B3. **In game (2026-10-11, 2.0.77):** works. The "lost" message isn't instant but shows up eventually (5 s grace; the character is gone while dead). Acceptable.
- [x] **B5. Win.** Kill the guardian during a challenge. Check: won, state `claimed`, no purple. **In game (2026-10-11, 2.0.77):** works.
- [x] **B6. Save/load during a challenge.** Check: still running after load and ends correctly. **In game (2026-10-11, 2.0.77):** works.
- [x] **B7. Keep the guardian engaged during a challenge** (fix for B2, approved and built 2026-10-11). On start, and on every check while a participant is within R: if the guardian isn't `enraged_at_target` at a participant, set `enraged_at_target` with `target` = the nearest participant's character (or their vehicle) and `last_damage_time = game.tick`, using `set_ai_state`. The guardian then hunts the player for as long as the challenge runs. Losing then effectively means: every participant is out of range or dead for 5 s. Check: build-triggered challenge, the guardian destroys the building, then comes for you; the challenge keeps running. **Built:** every check, each guardian of a running challenge with a participant within R is set to `enraged_at_target` at the nearest participant (vehicle if they're in one). It's only rewritten when it isn't already enraged at a participant, or when less than 15 s of rage is left, so the vanilla AI isn't touched every 0.5 s. **Headless (2026-10-11, 2.0.77):** `set_ai_state{type = enraged_at_target, target = character, attacked_me = true, last_damage_time = game.tick}` is accepted; read back as `enraged_at_target target=character left=30s`. **In game:** build in a territory, stay near, let the guardian destroy the building. Check: it then comes for you and the challenge keeps running; you lose only after leaving (100+ tiles) or dying. **In game (2026-10-11, 2.0.77): works.** After destroying the building, the guardian comes for the player and the challenge keeps running.

## Open questions

### Challenge mode (all POC, see fifth round)
1. ~~How far out?~~ Decided: distance from spawn in rings of ~500 tiles, evolution shifts the mix.
1a. What changes per ring beyond wave size and tier? (e.g. more spitters, extra mechanics further out, "more complicated" challenges.)
1b. ~~Weak enemies vs. slowdown?~~ Decided: both.
2. ~~What spawns, where?~~ Decided: biters/spitters in a ring just off-screen.
3. ~~How does it end?~~ Decided: win = guardian dead; lose = guardian loses aggro.
3b. ~~Lose after 30 s?~~ **No (T4 v2, 2026-10-11):** after the rage it keeps `attacking` player entities in reach. "Aggro lost" = the guardian goes back to `patrolling`. Phase B uses that, with a short grace period.
4. ~~Reset on fail?~~ Decided: yes, guardian heals and territory resets.
5. ~~Trigger timing?~~ Decided: real start when guardian can attack the player.
5b. ~~What starts the challenge?~~ **Decided (2026-10-11): (a) + (b).** The challenge starts when the guardian is **enraged** (from being shot) **or reacting to a building**, and a player is nearby. Walking through a territory stays safe. States and range: see the phase B proposal.
5a. ~~Remote building?~~ Decided: plain vanilla for the POC; revisit later.
6. ~~Concurrency?~~ Decided: one challenge per territory, one active challenge per player.

### Crusades
7. ~~Win condition?~~ Decided: rally + no military + N enemies for X seconds.
7a. ~~What counts as military?~~ Decided: anything that can damage enemies, not walls.
7b. Values for N and X? Do they scale with evolution or distance?
7c. ~~Rally structure?~~ Decided: new enemy building, built over time; destroying it resets the hold timer. Still open: how long to build, how tough, how it looks.
8. How long can migration take at most before the crusade starts anyway (or is cancelled)?
9. ~~Crusade source?~~ Decided: a nest in a neighbouring territory; built during warning if missing.
9a. ~~Migration method?~~ Decided: spawn at nest (POC), waypoints later.
10. Is there a cooldown between crusades, and can two run at once late game?
11. ~~Lost buildings?~~ Decided: nothing special.

### Vanilla
12. Do biter nests stay on Nauvis, and do they still expand?
13. ~~Do vanilla attacks stay?~~ Decided: turned off; pollution keeps working.
14. ~~Pollution budget?~~ Decided: pollution absorbed by nests, as in vanilla. Follow existing pollution rules wherever possible.
