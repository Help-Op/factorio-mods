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
| V4 | ~~Turning off vanilla attacks.~~ | Resolved (phase E): attack groups are cancelled in `on_unit_group_finished_gathering`. |
| V5 | Detecting "guardian triggered". | Candidates: `on_segmented_unit_damaged` (exists), `on_built_entity` + `get_territory_for_chunk`. With the "real start = guardian can attack the player" rule, the AI state (V13) may be the only trigger we need. See test T3. |
| V6 | "Tactical" target choice needs a scoring rule. | E.g. border territories, near pollution, weakly defended, recently claimed. Must have a neighbouring hostile territory with a nest. |
| V7 | Demolishers on Nauvis terrain. | Still open from `plan.md` step 8 (water, trees, cliffs). |
| V8 | Migration "without going through the player base". | The engine pathfinder doesn't avoid player buildings; units attack what blocks them. Options: (a) route through hostile territories with waypoint commands, (b) spawn the units directly at the staging nest from the budget (no real walk), (c) a mix: units near the staging nest walk, the rest are spawned there. (b) is simplest and safest. **Decided:** (b) for the POC, (a) as end goal. |
| V9 | Where do the "biters that would normally attack" come from? | Phase E knows them exactly: the members of each cancelled group. POC removes them and keeps their pollution cost. **Phase G must bring them back** (send them to the staging nest, or respawn the same mix there from the budget). |
| V10 | Central spot and rally structure. | Need a rule for the centre (e.g. the chunk nearest the centroid of `get_chunks()`, snapped to buildable land) and a rally prototype (enemy-force entity, built over time). |
| V11 | ~~Measuring pollution absorbed by nests.~~ | Resolved: the budget comes from cancelled units' `absorptions_to_join_attack` (vanilla rule). `get_pollution_statistics(surface).output_counts` also works (headless: 2643 absorbed by `biter-spawner`). |
| V12 | Building enemy structures over time (rally, staging nest). | Options: place a "construction site" entity and swap it for the real one after a timer, or grow health over time. To test. |
| V14 | **Demolishers don't attack the player on sight**, only in revenge or when investigating buildings (T4). Rage lasts 30 s, then it keeps `attacking` player entities in reach. Resolved for the POC by the phase B rules. | `enraged_at_target` also has `last_damage_time` (writable) and `remaining_time`. The rule "the challenge starts when the guardian can attack the player" would mean: only after the player shoots it, or (to check) when it attacks a building near the player. And "lose = aggro lost" would mean: the challenge ends 30 s after the player stops hitting it, even while standing next to it. See open questions 3b and 5b. |
| V13 | Detecting guardian aggro: start (in range of the player) and end (aggro lost). | **Start confirmed (T4):** chasing the player gives `enraged_at_target` with `target = character`. See V14 for what that means. Likely solved: poll `get_ai_state()`. Start = `attacking`/`enraged_at_target` with a target that is a character (or near one). Lose = back to `patrolling`/`investigating`. Fallback: distance rule. See test T4. |

## Tests to run later

| # | Test | Command / steps | Check |
|---|------|-----------------|-------|
| T1 | Turn off vanilla pollution attacks (V4). | See "T1 commands" in phase E (options A and B). | Do attacks stop? Do nests still absorb pollution and fill with idle units? Does evolution still rise? Can we read how much pollution nests absorbed (V11)? |
| T2 | Lifelong slowdown sticker (V3). | Done headless in C1. | **Passed (2026-10-11):** still attached after 23 min; 50 % sticker halves the distance moved. Strength per ring via 5 sticker prototypes. |
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
- [x] **C. Challenge mode.** Done 2026-10-11 (C1 headless, C2–C6 in game). Spawn rate and difficulty to tune in phase I. Details below.
- [x] **D. Claim.** Guardian dies → territory becomes Claimed, and a running challenge ends as won. Covered by A2 and B5.
- [ ] **E. Vanilla attacks off.** Option B built 2026-10-11; headless pass; in-game long run (E3) open. Details below.
- [ ] **F. Crusade budget.** Turn pollution + evolution into a crusade trigger.
- [ ] **G. Target + migration + warning.** Pick target and staging nest (build one if missing), spawn the army at the nest (POC), colour the target.
- [ ] **H. Assault + rally + hold.** Move to the central spot, build the rally, check hold conditions (rally destroyed → timer reset), respawn the guardian.
- [ ] **I. Balancing.** Known items: challenge spawn rate (C2) and difficulty in rings 1–2 (C4).
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

### Phase C in detail (approved and built 2026-10-11)

Goal: a running challenge spawns waves of biters and spitters around the participants, Vampire Survivors style. Easy close to spawn, harder further out. Everything here is a POC that will evolve.

**Facts it builds on:**

| Fact | Source |
|------|--------|
| `StickerPrototype.duration_in_ticks` is a `uint32` (up to about 2 years of game time), so a slowdown sticker can last the unit's whole life. `target_movement_modifier < 1` slows the unit. Vanilla `slowdown-sticker` (base `entities.lua:8020`) can be copied for the graphics. | `prototype-api.json`, 2.0.77 |
| Units are commanded via `entity.commandable.set_command{...}` in 2.0. `LuaEntity.stickers` lists attached stickers. | `runtime-api.json`, 2.0.77 |
| `small-biter`: 15 HP, `movement_speed = 0.2`. `small-spitter`: 10 HP. `medium-biter`: 75 HP. | base `enemies.lua` |
| Evolution: `game.forces.enemy.get_evolution_factor(surface)`. | `runtime-api.json`, 2.0.77 |

**New prototypes (data stage):**

| Prototype | What |
|-----------|------|
| `ht-tiny-biter` | Copy of `small-biter`: 6 HP, half damage, smaller (scale 0.7), lighter tint. The weak tier below the small biter. |
| `ht-challenge-slow-50` … `-10` | 5 stickers that slow by 50 / 40 / 30 / 20 / 10 %, `duration_in_ticks = 4e9`. No graphics. |

**Difficulty by ring** (distance from spawn to the guardian's head when the challenge starts; ring = `floor(distance / 500)`):

| Ring | Distance | Units | Slowdown | Wave size | Interval | Max alive |
|------|----------|-------|----------|-----------|----------|-----------|
| 0 | < 500 | tiny biter | 50 % | 3 | 10 s | 15 |
| 1 | 500–1000 | tiny + small biter | 40 % | 5 | 8 s | 25 |
| 2 | 1000–1500 | small biter + small spitter | 30 % | 8 | 8 s | 40 |
| 3+ | 1500+ | small + medium biter, small spitter | 20 % | 12 | 6 s | 60 |

- **Evolution:** each spawned unit gets upgraded one tier (tiny → small → medium biter, small → medium spitter) with chance = evolution factor.
- Max alive is per challenge. It's the main UPS guard (V2).

**Spawning and behaviour:**

| Item | Proposal |
|------|----------|
| Where | For each wave, pick a random participant near the guardian. Spawn each unit at a random angle **40–50 tiles** from them (just off-screen at normal zoom), via `find_non_colliding_position`. Skip a unit if no spot is found (water, cliffs). |
| Who they chase | `set_command{type = attack, target = participant's character or vehicle, distraction = by_enemy}`. They may get distracted by buildings and turrets on the way. |
| Slowdown | Sticker for the ring is attached right after spawning. |
| Tracking | `record.spawned[unit_number] = entity` in the challenge record; dead or invalid ones are dropped every check. |
| End: lost | All spawned units are removed (`destroy()`, no loot, no corpses). |
| End: won | **They flee** to the nearest other guarded territory (nearest guardian head), `go_to_location` with no distraction. Removed when they arrive (`on_ai_command_completed`) or after 60 s. No other guarded territory → removed at once. |
| Files | New `scripts/waves.lua` (spawn, track, clean up), called from `challenge.lua`. New `prototypes/entity/challenge-units.lua` and `prototypes/entity/challenge-stickers.lua`, required from `data.lua`. |
| Debug | `/ht-challenges` also shows ring, alive units and next wave in s. |

**Steps:**

**Approved (2026-10-11):** ring table as proposed; leftovers **flee to a nearby territory** on a win; slowdown invisible; spawn distance 40–50 tiles (POC).

**Built:** `prototypes/entity/challenge-units.lua`, `prototypes/entity/challenge-stickers.lua`, `locale/en/locale.cfg`, `scripts/waves.lua`; wired into `challenge.lua` and `control.lua`. The ring is set at challenge start from the guardian head's distance to the player force spawn position. Challenges saved before phase C get no waves (no ring).

- [x] **C1. Prototypes + sticker test (T2).** **Headless (2026-10-11, 2.0.77):** data stage loads; `ht-tiny-biter` has 6 HP. Two small biters given the same `go_to_location`: in 128 ticks the plain one moved 22.9 tiles, the one with `ht-challenge-slow-50` moved 10.7 (≈ 50 %). After **23 minutes** of game time the sticker is still attached. T2 passes. In game: check the tiny biter looks right. Add tiny biter + stickers. Headless: spawn a biter, attach `ht-challenge-slow-50`, check after 5 minutes of game time that the sticker is still there. In game: check it visibly walks slower.
- [x] **C2. Waves.** Spawn waves during a challenge (ring table, caps). In game: start a challenge near spawn (ring 0), see tiny biters come from all sides. **In game (2026-10-11, 2.0.77):** works. Mechanics fine; **spawn rate needs tuning** (phase I).
- [x] **C3. Clean-up.** Lose and win a challenge. Check: all spawned units disappear. **In game (2026-10-11, 2.0.77):** works (lost: removed; won: flee and vanish).
- [x] **C4. Rings.** Try a challenge in ring 1 and ring 2 (`/ht-challenges` shows the ring). Check: unit mix and wave size change. Give feedback on feel. **In game (2026-10-11, 2.0.77):** works, maybe too well: the player lost in ring 1–2 with the cheat kit. Cheat kit made stronger; difficulty tuning goes to phase I.
- [x] **C5. Evolution.** `/c game.forces.enemy.set_evolution_factor(0.5, "nauvis")`, then start a challenge. Check: more upgraded units. **In game (2026-10-11, 2.0.77):** works.
- [x] **C6. Save/load during waves.** Check: waves continue, clean-up still works. **In game (2026-10-11, 2.0.77):** works.

### Phase E in detail (approved and built 2026-10-11)

Goal: no more vanilla pollution attacks on the base. Pollution keeps spreading and being absorbed, evolution keeps rising, nests keep expanding (decision Q12). The attacks that would have happened become the budget for crusades (phase F).

**How vanilla attacks work** (base `enemies.lua`, 2.0.77): a nest absorbs pollution (`absorptions_per_second`) and spawns units (up to `max_count_of_owned_units`, 7 for a biter spawner). Each unit needs `absorptions_to_join_attack` pollution to join an attack group: small biter 4, medium 20, big 80, behemoth 400. Groups gather, then leave to attack.

**Engine hooks (`runtime-api.json`, 2.0.77):**

| Hook | Use |
|------|-----|
| `on_unit_group_finished_gathering {group}` | Fires when a group is about to set off. |
| `LuaCommandable.is_script_driven`, `.command`, `.members` | Tell engine groups from ours; read the command (`attack_area` vs `build_base` for expansion). |
| `game.map_settings.unit_group.max_gathering_unit_groups` / `max_unit_group_size` | Map-setting switch (the docs say it only affects automatic groups). |
| `game.get_pollution_statistics(surface).output_counts` | Pollution absorbed per prototype (e.g. `biter-spawner`), for V11. |

**Two options:**

| | A. Map settings | B. Intercept groups (recommended) |
|---|---|---|
| How | Set `max_gathering_unit_groups = 0` on init. | On `on_unit_group_finished_gathering`: if the group is engine-driven and its command is an attack (not `build_base`), cancel it. |
| Expansion | **Risk:** expansion also uses automatic groups and may stop too. To test. | Untouched: `build_base` groups pass. |
| Pollution economy | Unclear: full nests may stop absorbing. To test. | Unchanged: nests absorb, spawn and gather as in vanilla. |
| Crusade budget | Must be guessed from absorption statistics. | **Exact:** each cancelled unit adds its `absorptions_to_join_attack` to `storage.crusade_budget`. That's the vanilla rule (decision Q14). |
| Units that would attack (V9) | Stay at the nests. | Known exactly; phase G can take them over instead of removing them. |
| Cost | Nothing. | One event per group; units still spawn and gather (vanilla UPS). |

**What happens to a cancelled group (option B, POC):** members are removed (`destroy()`, no corpses) and their pollution cost goes into the budget. Nests then keep spawning and absorbing as normal. Phase G will later send them to the staging nest instead.

**Steps:**

**Approved (2026-10-11):** option **B** straight away (no A/B comparison). Removing cancelled attackers is fine for now, on condition that they **come back in phase G** as the crusade army. Biters attacking buildings near their own nest is fine (they defend their territory).

**Built:** `scripts/attacks.lua`, wired in `control.lua` (`on_unit_group_finished_gathering`, `/ht-attacks`). `storage.crusade_budget` = sum of `absorptions_to_join_attack.pollution` of cancelled units; `storage.cancelled_attacks = {groups, units}`.

**Headless test (2026-10-11, 2.0.77):** furnaces placed about 80 tiles from a nest, pollution pumped in at game speed 30.

| Run | Result |
|-----|--------|
| Expansion sped up (1 min cooldown) | 2 attack groups cancelled (61 units, budget 244). Nests 129 → 164, so **expansion still works**. But 7 of 10 furnaces died. |
| Killers logged | All killers were in engine groups with `attack_area`, not caught. Raw event log: 27 groups created, 15 finished gathering; the mod cancelled 2 of them and skipped 13 as `build_base` (expansion). So the killers were **expansion parties attacking buildings near the spot they settle** (vanilla behaviour). A sweep for groups that skip the event was tried and **caught nothing**, so it was removed again. |
| Expansion off | **24 groups / 3479 units cancelled**, budget 13916, evolution 0.172. 1 of 24 furnaces died, killed by a lone biter (no group) from a nest 62 tiles away: the "nest defends itself" case. |

Conclusion: every vanilla attack group fires `on_unit_group_finished_gathering` and is cancelled. Remaining damage comes from expansion parties (only near where they settle) and from biters next to their own nest.

- [ ] **E1. Test T1 (in game).** ~~Compare A and B.~~ Skipped: B chosen directly. The T1 commands below still work for checking evolution and absorption. Compare A and B on a polluting base (or `/c` a few boilers next to nests). See T1 commands below. Check: do attacks stop? Does expansion continue? Do nests keep absorbing (statistics)? Does evolution rise?
- [x] **E2. Build the chosen option.** Built and tested headless (see above). `/ht-attacks` shows cancelled groups, units and budget.
- [ ] **E3. Long run (in game).** Play 30+ min with a polluting base. Check: no attacks on the base, expansion still happens, budget grows, nests still defend themselves when you get close.

**T1 commands** (throwaway save):
- Option A on: `/c game.map_settings.unit_group.max_gathering_unit_groups = 0 game.map_settings.unit_group.max_unit_group_size = 0 game.print("A: auto groups off")`
- Option B on (console version of the handler): `/c storage.t1 = {groups = 0, units = 0, pollution = 0} script.on_event(defines.events.on_unit_group_finished_gathering, function(e) local g = e.group if not (g.valid and not g.is_script_driven) then return end local c = g.command if c and c.type == defines.command.build_base then game.print("expansion group passes") return end local n, p = 0, 0 for _, u in pairs(g.members) do n = n + 1 p = p + (u.prototype.absorptions_to_join_attack and u.prototype.absorptions_to_join_attack.pollution or 0) u.destroy() end storage.t1.groups = storage.t1.groups + 1 storage.t1.units = storage.t1.units + n storage.t1.pollution = storage.t1.pollution + p game.print(string.format("cancelled attack: %d units, %d pollution (total %d groups)", n, p, storage.t1.groups)) end) game.print("B: intercept on")`
- Absorbed pollution per nest type: `/c local o = game.get_pollution_statistics("nauvis").output_counts game.print("absorbed: biter-spawner " .. math.floor(o["biter-spawner"] or 0) .. ", spitter-spawner " .. math.floor(o["spitter-spawner"] or 0))`
- Evolution: `/c local f = game.forces.enemy game.print(string.format("evolution %.3f (pollution part %.3f)", f.get_evolution_factor("nauvis"), f.get_evolution_factor_by_pollution("nauvis")))`
- Speed things up: `/c game.speed = 5` (back with `= 1`).

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
11a. **Expansion parties** still attack player buildings near the spot where they settle (headless, phase E). Keep that as vanilla, or also cancel their attacks?
12. Do biter nests stay on Nauvis, and do they still expand?
13. ~~Do vanilla attacks stay?~~ Decided: turned off; pollution keeps working.
14. ~~Pollution budget?~~ Decided: pollution absorbed by nests, as in vanilla. Follow existing pollution rules wherever possible.
