# Hostile Territory: Vision

> **Status:** phases A–H done (POC), phase I in progress · **Parent:** none (top level) · **Next:** arena AR2; phase I in [enemy-balancing-plan.md](enemy-balancing-plan.md) · [Roadmap](roadmap.md)

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
| No nest next to target | ~~The enemy builds a staging nest during the warning phase.~~ **Changed (2026-10-12):** a territory without a nest is not a valid staging point. No valid one → no crusade (phase G, G-3). |
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
| Crusade numbers | POC defaults: **N = 10** enemies, **X = 60 s** hold, migration **max 5 min**, **15 min** cooldown (**starts when a crusade ends**, 2026-10-12), **one crusade at a time**. |
| Biter nests (Q12) | **Keep vanilla nest generation and expansion** (POC). |

## Confirmed facts

| Fact | Source |
|------|--------|
| `LuaTerritory.regenerate_segmented_units()` respawns the guardian and makes a cleared territory hostile again. | `territory-recapture-plan.md`, tested 2026-10-11, 2.0.77 |
| Per-territory colour works with `rendering.draw_rectangle{render_mode = "chart"}` per chunk. Force colour does not change the overlay. | `territory-recapture-plan.md`, tested 2026-10-11 |
| Territories already generate on Nauvis via map gen, with a safe starting area (384 tiles). | `territory-mapgen-plan.md` steps 1–6 |
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
| V6 | "Tactical" target choice needs a scoring rule. | E.g. border territories, near pollution, weakly defended, recently claimed. Must have a neighbouring hostile territory with a nest. **POC (2026-10-12):** the claimed territory furthest from spawn, ties random (phase F). |
| V7 | Demolishers on Nauvis terrain. | Still open from `territory-mapgen-plan.md` step 8 (water, trees, cliffs). |
| V8 | Migration "without going through the player base". | The engine pathfinder doesn't avoid player buildings; units attack what blocks them. Options: (a) route through hostile territories with waypoint commands, (b) spawn the units directly at the staging nest from the budget (no real walk), (c) a mix: units near the staging nest walk, the rest are spawned there. (b) is simplest and safest. **Decided:** (b) for the POC, (a) as end goal. |
| V9 | Where do the "biters that would normally attack" come from? | Phase E knows them exactly: the members of each cancelled group. POC removes them and keeps their pollution cost. **Phase G must bring them back** (send them to the staging nest, or respawn the same mix there from the budget). |
| V10 | Central spot and rally structure. | Need a rule for the centre (e.g. the chunk nearest the centroid of `get_chunks()`, snapped to buildable land) and a rally prototype (enemy-force entity, built over time). |
| V11 | ~~Measuring pollution absorbed by nests.~~ | Resolved: the budget comes from cancelled units' `absorptions_to_join_attack` (vanilla rule). `get_pollution_statistics(surface).output_counts` also works (headless: 2643 absorbed by `biter-spawner`). |
| V12 | Building enemy structures over time (rally; staging nest no longer needed, G-3). | Options: place a "construction site" entity and swap it for the real one after a timer, or grow health over time. To test. |
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
| T5 | Crusade starts without arming (phase I). | New freeplay with the mod; **don't** use the arm command. Build a normal polluting base, kill one guardian near spawn. Watch with `/ht-crusade` (budget, from-evolution part, target, cost). | Does a crusade start on its own? How many minutes after the claim? How much budget came from cancelled attacks vs. evolution? Is that pace fun, too slow or too fast? Budget sources: cancelled attacks (`attacks.lua`) + 10 000 per 1.0 time/spawner evolution; cost `400 × (1 + d/500) × (1 + 4 × evo)`. |

## Phases (draft, to refine)

Each phase starts with a small engine test before building on it.

- [x] **A. Territory state + overlay.** Done 2026-10-11 (headless + in game). Detailed steps below.
- [x] **B. Trigger detection.** Done 2026-10-11 (headless + in game, incl. fix B7). Details below.
- [x] **C. Challenge mode.** Done 2026-10-11 (C1 headless, C2–C6 in game). Spawn rate and difficulty to tune in phase I. Details below.
- [x] **D. Claim.** Guardian dies → territory becomes Claimed, and a running challenge ends as won. Covered by A2 and B5.
- [x] **E. Vanilla attacks off.** Done 2026-10-12 (option B, headless + in game E3). E1 skipped. Details below.
- [x] **F. Crusade budget.** Done 2026-10-12 (F1–F2 headless, F3 headless + in game). Details below.
- [x] **G. Target + migration + warning.** Pick target and staging nest (must already exist), spawn the army at the nest (POC), colour the target. Done 2026-10-12 (G0–G3 headless, G4 in game incl. two fixes). Details below.
- [x] **H. Assault + rally + hold.** Move to a spot on the patrol path, build the rally, check hold conditions (rally destroyed → timer reset), respawn the guardian. Done as POC 2026-10-12 (H0–H3 headless, H4 in game incl. squad fixes). Smarter AI later. Details below.
- [ ] **I. Balancing.** Known items: challenge spawn rate (C2) and difficulty in rings 1–2 (C4), crusade cost and budget speed (F), army cap and the early-kill cancel rule (G), guardian and rally strength (H-6), cutoff for straggler rebuilds (H-b). Enemy feel, speed and niches: see [enemy-balancing-plan.md](enemy-balancing-plan.md). Pace of crusades without arming: test T5.
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
- [x] **E3. Long run (in game).** Play 30+ min with a polluting base. Check: no attacks on the base, expansion still happens, budget grows, nests still defend themselves when you get close. **In game (2026-10-12, 2.0.77), 10+ min:** the "attack triggered by pollution" achievement fired, but **no attack reached the base**. Nests near the player still attack (vicinity aggro works). Accepted as working. Not checked in this run: expansion and budget growth (both confirmed headless).

**T1 commands** (throwaway save):
- Option A on: `/c game.map_settings.unit_group.max_gathering_unit_groups = 0 game.map_settings.unit_group.max_unit_group_size = 0 game.print("A: auto groups off")`
- Option B on (console version of the handler): `/c storage.t1 = {groups = 0, units = 0, pollution = 0} script.on_event(defines.events.on_unit_group_finished_gathering, function(e) local g = e.group if not (g.valid and not g.is_script_driven) then return end local c = g.command if c and c.type == defines.command.build_base then game.print("expansion group passes") return end local n, p = 0, 0 for _, u in pairs(g.members) do n = n + 1 p = p + (u.prototype.absorptions_to_join_attack and u.prototype.absorptions_to_join_attack.pollution or 0) u.destroy() end storage.t1.groups = storage.t1.groups + 1 storage.t1.units = storage.t1.units + n storage.t1.pollution = storage.t1.pollution + p game.print(string.format("cancelled attack: %d units, %d pollution (total %d groups)", n, p, storage.t1.groups)) end) game.print("B: intercept on")`
- Absorbed pollution per nest type: `/c local o = game.get_pollution_statistics("nauvis").output_counts game.print("absorbed: biter-spawner " .. math.floor(o["biter-spawner"] or 0) .. ", spitter-spawner " .. math.floor(o["spitter-spawner"] or 0))`
- Evolution: `/c local f = game.forces.enemy game.print(string.format("evolution %.3f (pollution part %.3f)", f.get_evolution_factor("nauvis"), f.get_evolution_factor_by_pollution("nauvis")))`
- Speed things up: `/c game.speed = 5` (back with `= 1`).

### Phase F in detail (approved and built 2026-10-12)

Goal: turn the budget into a crusade trigger. When the budget covers the cost of attacking the target, spend it and announce the crusade in chat. Phase G then does the actual attack.

**Decisions (2026-10-12):**

| Topic | Decision |
|-------|----------|
| Target | The **claimed territory furthest from spawn**. Ties: a random one. Replaces the "tactical" scoring of V6 for now. |
| Cost | Scales with the target's **distance from spawn** and with **evolution**. Higher on both = more points spent = stronger attack. Far territories are harder to keep. Once the player is pushed back, attacks get cheaper again, but stay stronger than at the start because evolution only goes up. |
| Evolution | Also **adds to the budget**, on top of the pollution from cancelled attacks. |
| Spending | Only the **cost** is taken from the budget. The rest stays for the next crusade. |
| Limits | One crusade at a time, 15 min cooldown (POC defaults). |
| Output | A chat message only. No colours yet; those come in phase G. |

**Proposals (approved 2026-10-12 as starting values; tune in phase I):**

| Topic | Proposal | Why |
|-------|----------|-----|
| Cost formula | `cost = BASE × (1 + distance / 500) × (1 + 4 × evolution)`. POC: `BASE = 400`. | One ring (500 tiles) further out adds 1× BASE. Evolution 1 makes it ×5. 400 is about 100 small biters or 20 medium ones. Examples: next to spawn at evo 0 → 400. 1000 tiles out at evo 0.5 → 3600. To tune in phase I. |
| Distance | In tiles from the player force spawn to the territory **centre** (average of its chunks, from `LuaTerritory.get_chunks()`), saved on the territory record. | Continuous, so there are no jumps at ring edges. Same spawn point as the challenge rings. |
| Evolution → budget | Every check, add `Δevolution × 10000`, counting only the **time** and **spawner-kill** parts of evolution. | The pollution part is already counted through cancelled attacks, so counting it again would double it. Evolution 0.1 from time and kills = 1000 points. |
| Check | Every 60 s (`on_nth_tick`). Trigger if: no cooldown, at least one claimed territory, and `budget ≥ cost`. | Cheap, and fast enough for a 15 min cooldown. |
| After trigger | `budget -= cost`, chat message (target, distance, cost, budget left), `storage.crusade = {target_id, cost, tick}` for phase G, start the cooldown. | |
| Code | New `scripts/crusade.lua`. `attacks.lua` stays as it is (cancelling + pollution budget). | Keeps one job per file. |
| Debug | `/ht-crusade`: budget, evolution part, next target, its distance and cost, cooldown left. | |

**Steps:**
- [x] **F1. Target + cost.** Territory centre and distance, target pick, cost formula, `/ht-crusade` (no spending yet). Headless: claim a few territories, check the pick and the cost.
  - **Built:** `scripts/crusade.lua` (`pick_target`, `cost`, `describe`; centre cached as `record.centre`), `/ht-crusade`, and remote `crusade` in the debug interface (console code can't `require`).
  - **Headless (2026-10-12, 2.0.77, seed 12345):** set states with the debug interface.

    | Claimed (distance) | Evolution | Target | Cost | Expected |
    |--------------------|-----------|--------|------|----------|
    | none | 0 | none | – | – |
    | 1 (411), 11 (671) | 0 | 11 | 937 | 937 |
    | 1, 11, 14 (918) | 0 | 14 | 1135 | 1135 |
    | 1, 11, 14 | 0.5 | 14 | 3405 | 3405 |
    | 1 only | 0.5 | 1 | 2187 | 2187 |

    Not tested: ties (random pick).
  - In game (optional): stand in a territory, `/ht-set-state claimed`, then `/ht-crusade`.
- [x] **F2. Evolution into budget.** Headless at high game speed: the budget grows from time evolution with no pollution.
  - **Built:** `crusade.on_tick` every 60 s adds `Δ(by_time + by_killing_spawners) × 10000` to `storage.crusade_budget` (also tracked as `storage.crusade_evolution_points`). The baseline is set in `on_init`/`on_configuration_changed`, or on the first check, so an existing save gets no lump sum.
  - **Headless (2026-10-12, 2.0.77, seed 12345, fresh map):**

    | Test | Result |
    |------|--------|
    | Time only (`time_factor` ×100, speed 60, ~47 game min) | Budget 0 → 11279 = Δtime 1.128 × 10000. ✓ |
    | Kill 10 spawners + set pollution part to 0.5 | +368 = 200 (kills 0.02) + 168 (time). Pollution added nothing. ✓ |

  - **Finding:** `get_evolution_factor_by_time/_by_killing_spawners/_by_pollution` return **raw counters**, not each part's share of the real evolution. They grow linearly and go past 1 (time 1.138 while evolution was 0.532). So the evolution budget doesn't slow down as evolution nears 1. See F-d.
  - **Default rates (raw):** time 0.000004/s → **~144 points per hour**. Spawner kill 0.002 → **20 points per spawner**. Both small next to pollution (headless phase E: 13916 points).
- [x] **F3. Trigger.** Spend, announce, cooldown. Headless: set the budget high, see one crusade per 15 min. Then in game.
  - **Built:** `try_trigger` in `crusade.on_tick` (every 60 s). If cooldown over, target exists, budget ≥ cost: spend, set `storage.crusade`, start 15 min cooldown, print to the player force. Until phase G, a new crusade replaces the old one (F-b). `/ht-crusade` also shows cooldown left and the last crusade.
  - **Headless (2026-10-12, 2.0.77, seed 12345, fresh map):** claimed territories 1 (411) and 14 (918), budget 5000, speed 60, 75 game min.

    | Game min | Event | Budget after |
    |----------|-------|--------------|
    | 1 | Crusade on 14, cost 1136 | ~3864 |
    | 16 | Crusade on 14, cost 1152 | ~2767 |
    | 31 | Crusade on 14, cost 1168 | ~1618 |
    | 46 | Crusade on 14, cost 1184 | ~472 |
    | 61–75 | Cooldown over, budget 540 < cost 1215: **no crusade** ✓ | 540 |

    Cost rises slowly with time evolution (0 → 0.018). Chat text is not in the headless log (no players): check in game.
  - [x] **In game:** check the chat message. **In game (2026-10-12, 2.0.77):** "Crusade ready: …" appears. ✓
    1. Stand in a territory: `/ht-set-state claimed`
    2. Fill the budget, clear the cooldown: `/c __Hostile-territory__ storage.crusade_budget = 5000 storage.crusade_cooldown_until = 0 game.print("budget 5000")`
    3. Within 60 s: chat shows "Crusade ready: …". Then `/ht-crusade` shows ~900 s cooldown and the last crusade.

**Resolved (2026-10-12):**
- F-a. ~~Budget cap?~~ **No cap.** If the budget fills very quickly early on, that means it grows too fast: tune the numbers (phase I), not a cap.
- F-b. ~~`storage.crusade` before phase G?~~ It just stays; the cooldown starts anyway.
- F-c. ~~Distance from centre or furthest chunk?~~ From the **centre**.

**Open (2026-10-12):**
- F-d. The evolution budget uses the **raw** time + kill counters (linear, never slows down). Fine as it is, or should it follow the real evolution (slows down near 1, so almost nothing late game)? Proposal: keep the raw counters (simpler, steady late-game pressure) and tune `EVOLUTION_POINTS` in phase I. At default settings, evolution adds very little.

### Phase G in detail (approved and built 2026-10-12)

Goal: turn an announced crusade (phase F) into a gathered army. Pick a staging territory and nest next to the target, colour the target (warning), spawn the army at the nest over time, and switch the target to `crusade` at critical mass. Moving the army and holding the territory are phase H.

**Already decided:** staging = a nest in a neighbouring hostile territory (4th round; "build if missing" dropped 2026-10-12, see G-3). Migration POC = spawn at the nest from the budget (V8 b). Warning colour starts when migration starts, crusade at critical mass (3rd round). Migration max 5 min, one crusade at a time (6th round). The units cancelled in phase E come back as this army (V9).

**Flow:**

| Step | What happens | Target state |
|------|--------------|--------------|
| 1. Trigger (F) | Budget pays the cost. | claimed |
| 2. Staging | Pick the staging territory and nest. Mark the nest on the map. Chat: "Enemies gather near territory X." | **warning** |
| 3. Migration | Spawn the army at the nest in batches, into one script-driven unit group that stays put. | warning |
| 4. Critical mass | All units spawned. Chat: "Crusade on territory X." | **crusade** |
| 5. (phase H) | Army moves to the target, rally, hold. | crusade |

**Proposals (approved 2026-10-12; G-3 changed):**

| Topic | Proposal | Why |
|-------|----------|-----|
| G-1 Staging territory | Hostile territories **touching** the target (a chunk of the target has a neighbouring chunk in it) **that have a nest**. Pick the one whose centre is **furthest from spawn**. If none touch: the **nearest hostile** territory with a nest, by centre. | "Furthest from spawn" keeps the army on the far side of the target, away from the base. The fallback covers gaps between territories. |
| G-2 Staging nest | The enemy spawner in the staging territory **closest to the target centre**. | Shortest walk for phase H. |
| G-3 No nest | **Decided (2026-10-12): never build one.** A territory without a nest is not a valid staging territory. If no valid staging territory exists, **no crusade**: the trigger (F3) checks staging first and doesn't spend the budget. | Very unlikely to happen, and skipping is fine. |
| G-4 Army mix | Vanilla: use the nest's `result_units` weighted at the current evolution (same as what the nest itself spawns). Each unit costs its `absorptions_to_join_attack`, spawned until the crusade cost is used up. | Follows the vanilla rules (Q14). It's the same mix as the attacks we cancelled. |
| G-5 Army size cap | Cap at **200 units** (POC). Leftover cost goes back to the budget. | Cost 1136 at evolution 0 = 284 small biters. Big armies are heavy on UPS and pathing. To tune in phase I. |
| G-6 Migration time | Spawn in batches every 10 s over **2 min**; critical mass when all are spawned. Never longer than 5 min. | Gives the warning time to be seen. |
| G-7 Army holds still | Members go in one `create_unit_group` group with no command, so they wait at the nest. Script-driven, so `attacks.lua` leaves it alone. | Needs the G0 test. |
| G-8 Cancel | The crusade is cancelled if the target is no longer `warning`/`crusade` (e.g. a debug change), or the **whole army is killed** during migration. Target → `claimed`, chat message. | The player can prevent a crusade by hitting the staging nest early. |
| G-9 End until phase H | The crusade stays in `crusade` state with the army waiting. Debug `/ht-crusade-cancel` ends it (target → `claimed`, army removed). No new crusade while one is active. | Lets us test G without H. |
| G-10 Code | Extend `scripts/crusade.lua` (state machine in `storage.crusade`). Stage + army helpers in a new `scripts/army.lua` if it gets big. | |

**Steps:**
- [x] **G0. Engine test (headless).** (a) Do the target's neighbouring chunks belong to other territories, or are there gaps? (b) Find spawners inside a territory. (c) `result_units` at a given evolution. (d) Spawn ~200 units into a script-driven group with no command: do they stay put for 5 min? Does `attacks.lua` ignore them?
  - **Headless (2026-10-12, 2.0.77, seed 12345, chunks ±40 around spawn):**

    | Test | Result |
    |------|--------|
    | (a) Adjacency | Territories **touch**: 64 territories, on average **5 neighbours**, none isolated. 16% of border chunk-edges have no territory (start area, map edge, ungenerated). Check = the 8 chunks around each chunk + `get_territory_for_chunk`. |
    | (b) Nests | `count_entities_filtered{area = chunk.area, type = "unit-spawner"}` per chunk. **52 of 64** territories have a nest (in generated chunks). |
    | (c) Spawn table | `prototypes.entity["biter-spawner"].result_units` = `{unit, spawn_points = {{evolution_factor, weight}}}`; weights interpolate between points. E.g. small-biter 0.3 @ 0 → 0 @ 0.6; medium 0 @ 0.2 → 0.3 @ 0.6 → 0.1 @ 0.7; big 0 @ 0.5 → 0.4 @ 1; behemoth 0 @ 0.9 → 0.3 @ 1. |
    | (d) Army holds | 200 small biters in a `create_unit_group` with no command: **all 200 stayed within 19 tiles for 6+ game min**. Group stays valid, `is_script_driven = true`, state 0 (gathering). `attacks.lua` cancelled nothing. ✓ |
- [x] **G1. Staging.** Pick the staging territory and nest (no nest → not valid; none valid → no crusade, budget kept). Map tag. `/ht-crusade` shows them. Headless.
  - **Built:** `scripts/staging.lua` (`pick`, `mark`, `unmark`, `on_chunk_charted`). `territories.centre` moved from `crusade.lua` to `territories.lua`. The F3 trigger now picks staging before spending; `storage.crusade` gets `staging_id`, `nest`, `nest_position`, `tag`. Map tag: the player force charts the nest chunk, then `add_chart_tag` (spawner icon, "Crusade staging"); retried from `on_chunk_charted` if the chunk isn't charted yet. A replaced crusade removes its old tag.
  - **Headless (2026-10-12, 2.0.77, seed 12345, fresh map, target = territory 14):**

    | Case | Result |
    |------|--------|
    | Neighbours of 14 | 3, 11, 45 (no nests), 15 (742 tiles), 40 (950), 49 (1138), **48 (1444)**, all hostile. Picked **48** with nest at 498,-1237 ✓ (furthest from spawn with a nest). |
    | Fallback: 15, 40, 48, 49 set to `warning` | Picked **51**, the nearest hostile territory with a nest (577 tiles from the target centre) ✓ |
    | Trigger (budget 5000) | Crusade on 14, staging 48, cost 1136. Map tag placed (1 tag; charting works headless) ✓ |
    | No hostile territory left | "Next staging: none", **no crusade**, budget kept (5007) ✓ |

  - Map tag looks: check in G4.
- [x] **G2. Warning + migration.** Target → `warning`, army spawns in batches into the group, budget refunds over the cap. Headless.
  - **Built:** `scripts/army.lua` (`plan`: weighted vanilla mix within the cost and the 200 cap; `spawn_batch`; `alive`). In `crusade.lua`: the trigger plans the army and spends only what it costs (rest stays in the budget), target → `warning`, chat "Crusade warning: …". `on_migration_tick` every 10 s spawns `ceil(units / 12)` units (2 min total), then phase `gathered`. **One crusade at a time is now enforced** (G-9 part): no trigger while a crusade has a phase other than `ended`. `/ht-crusade` shows phase, army progress and mix.
  - **Headless (2026-10-12, 2.0.77, seed 12345, fresh map, target 14, staging 48):**

    | Test | Result |
    |------|--------|
    | Evolution 0, budget 5000 (cost 1136) | 200 small biters (cap), spent 800, budget → 4200 ✓. Target `warning` ✓ |
    | Migration | 34 / 102 / 170 spawned at 20 / 60 / 100 s (17 per 10 s), then `gathered` with 200 ✓ |
    | Army waits | After ~19 game min: 200 alive, max 19 tiles from the nest ✓ |
    | One at a time | Territory 11 claimed, cooldown over: no new crusade while 14 is `gathered` ✓ |
    | Evolution 0.5, budget 5000 (cost 3405) | 163 medium + 36 small (18% small, as weights predict), spent 3404 ✓. Old map tag removed, new one placed ✓ |
- [x] **G3. Critical mass + cancel.** → `crusade` state, chat messages, cancel rules, `/ht-crusade-cancel`. Headless.
  - **Built:** phases `migration` → `crusade` → `ended`. Critical mass (all units spawned) → target `crusade`, chat "Crusade on territory X: N enemies are ready…". `crusade.finish(message)`: removes leftover units and the map tag, target → `claimed` (only if still `warning`/`crusade`). Checked every 10 s: target no longer `warning`/`crusade` → cancelled; every spawned unit dead → **cancelled** (migration) or **defeated** (crusade). `/ht-crusade-cancel` (admin) and remote `crusade_cancel`.
  - **Rule as built:** "army wiped out during migration" = all units spawned **so far** are dead. Killing the first batches early therefore cancels the crusade. **Kept for now (2026-10-12)**; revisit in phase I.
  - **Headless (2026-10-12, 2.0.77, seed 12345, fresh map, target 14):**

    | Case | Result |
    |------|--------|
    | 1. Critical mass | Phase `crusade`, target `crusade`, 200 alive, tag ✓ |
    | 2. Kill the gathered army | Phase `ended` (defeated), target `claimed`, tag removed ✓ |
    | 3. Kill the first 102 during migration | Cancelled, target `claimed`, tag removed ✓ |
    | 4. Target set to `hostile` during migration | Cancelled, army removed, target stays `hostile` ✓ |
    | 5. `crusade_cancel` during migration | Ended, 119 units removed, target `claimed`, tag removed ✓. Second call: "no active crusade" ✓ |
- [x] **G4. In game.** See the yellow-orange then bright-orange target, the army at the nest, the chat messages. Kill the army during migration → cancelled.
    1. Stand in a territory (it must be the furthest claimed one): `/ht-set-state claimed`
    2. Arm a crusade: `/c __Hostile-territory__ storage.crusade_budget = 5000 storage.crusade_cooldown_until = 0 game.print("armed")`
    3. Within 60 s: chat "Crusade warning: …", target **yellow-orange**, a **"Crusade staging"** map tag at the nest. `/ht-crusade` shows the army growing.
    4. After ~2 min: chat "Crusade on territory …", target **bright orange**. The army waits at the tag.
    5. Go to the tag and kill the army: chat "… defeated", target back to no colour, tag gone.
    6. Repeat 2, kill the first batch before the 2 min are up: chat "… cancelled: the gathering army was wiped out."
    7. Repeat 2, then `/ht-crusade-cancel`: army removed, target back to claimed.
    Check also: does the army react to you (chase, then return)? Do units leave the group?
  - **In game (2026-10-12, 2.0.77):** steps 1–4 and 7 ✓. Steps 5 and 6: chat and target colour correct, but **the "Crusade staging" tag stayed on the map**. Also found: **killing the staging territory's guardian did not cancel the crusade.**
  - **Fixes (2026-10-12):**
    - Tag: likely cause: `on_chunk_charted` re-added the tag after the crusade ended (it didn't check the phase), and the chunk gets re-charted while the player is near the nest. Now only handled for an active crusade. Step 7 worked because the player was far away.
    - Staging lost: cancel when the staging territory is no longer `hostile`/`challenge` (guardian killed → `claimed`, or gone). A running challenge there doesn't cancel. Chat "… cancelled: staging territory S was taken."
    - **Headless (2026-10-12, 2.0.77, seed 12345, isolated mods folder):** army killed → tags 0; nest area re-charted → still 0 ✓. Staging guardian killed (`die()`) during migration → staging `claimed`, crusade cancelled, target `claimed`, tags 0 ✓. (The headless run couldn't show the old bug happening, so the tag fix needs the in-game retest.)
  - [x] **Retest in game:** steps 5 and 6 (tag gone), and kill the staging guardian during migration → cancelled. **In game (2026-10-12, 2.0.77):** tag disappears ✓, killing the staging guardian cancels ✓. Old leftover tags: `/c for _, t in pairs(game.player.force.find_chart_tags(game.player.surface)) do if t.text == "Crusade staging" then t.destroy() end end`

**Resolved (2026-10-12):**
- G-a. ~~Mark the staging territory?~~ **Yes.** POC: a map tag (`force.add_chart_tag`, spawner icon, text "Crusade staging") at the staging nest, removed when the crusade ends. A tag doesn't clash with the territory colours.
- G-b. ~~Bigger units further out?~~ **No, follow vanilla** (evolution only) for the POC.
- G-c. ~~Nest type to build?~~ Not needed: no nest is built (G-3).

### Phase H in detail (approved 2026-10-12)

Goal: the gathered army (phase G) attacks the target, builds a rally on the guardian's patrol path and holds the territory. If it holds, the territory is lost: the guardian respawns and the territory is hostile again.

**Already decided:** reclaim steps = reach a spot → build the rally → no player military + N enemies for X s → guardian respawns (3rd round). Destroying the rally resets the hold timer (4th round). N = 10, X = 60 s (6th round). Military = anything that can damage enemies, not walls (7a). Lost buildings: nothing special.

**Early answers (2026-10-12):**

| Topic | Answer |
|-------|--------|
| Build time (7c) | Scales with distance from spawn, **5 to 30 min**, so the player has time to get there. |
| Toughness (7c) | Copies the stats of the **guardian that would spawn there**. Health scales from **×0 to ×0.75** while it is being built. |
| Looks (7c) | Placeholder: a **white rectangle**. No art. |
| Building (V12) | Similar to how vanilla nests are built. |
| Rally spot | A **random point on the guardian's patrol path**. Doesn't need to be central. |

**Confirmed facts (game files, 2.0.77):**

| Fact | Source |
|------|--------|
| Demolishers: small 30 000 HP / 40 HP per tick regen, medium 100 000 / 130, big 300 000 / 400. Shared `demolisher_resistances`. | `space-age/prototypes/entity/enemies.lua` 6629–6631 |
| Guardian per territory: `floor(clamp(distance / 576 - 0.25, 0, 2))` → small < 720 tiles, medium 720–1296, big beyond. | `prototypes/planet/nauvis-territory.lua` |
| Vanilla expansion: the group walks with `build_base`; `on_build_base_arrived` fires on arrival, then `on_biter_base_built` fires **once for every biter sacrificed** to build part of the base. Settler groups are 5–20 units. | `runtime-api.json`, `base/prototypes/map-settings.lua` |
| `LuaTerritory.get_patrol_path()` returns map positions, never empty; usually inside the territory, not guaranteed. | `runtime-api.json` |
| `__core__/graphics/white-square.png` exists (placeholder sprite). | `core/graphics` |
| `LuaSurface.create_segmented_unit{name, position, direction?, territory}` creates a guardian at a given spot, assigned to a territory (raises `on_segmented_unit_created`, cause `script_created`). `regenerate_segmented_units()` instead spawns where map gen would, and adds a new one on every call. | `runtime-api.json` |

**Flow:**

| Step | What happens | Ends when |
|------|--------------|-----------|
| 1. March | Army group gets `go_to_location` (rally spot, `distraction = by_enemy`): it fights what it meets on the way. Chat: "The crusade marches on territory X." | Group arrives (`on_ai_command_completed`), or timeout. |
| 2. Build | Rally placed with ~0 health, map tag on it. **Builders are sacrificed one by one** over the build time (like a settler group). Health cap grows to ×0.75 of the guardian. The rest of the army guards the spot. | Build time over → rally finished. Rally destroyed → rebuild (H-b). |
| 3. Hold | Every 10 s: rally alive, **no player military in the territory**, **≥ 10 army units in the territory**. | Held 60 s in a row → lost. A failed check resets the timer. Rally destroyed → rebuild (H-b). |
| 4. Lost | **The rally turns into the guardian:** rally removed, `create_segmented_unit` at its spot with the territory's guardian, **full health** → `hostile` (existing handler). Chat. | — |
| Player holds | Army wiped out → "defeated" (phase G rule). Rally removed. | — |

**Proposals (to confirm):**

| # | Topic | Proposal | Why |
|---|-------|----------|-----|
| H-1 | Build time | **Decided (H-c): by guardian size.** Small 5 min, medium 15 min, big 30 min. | Easier; follows the distance rings. |
| H-2 | Rally prototype | `simple-entity-with-force` per guardian size: `ht-rally-small/-medium/-big`. `max_health` = **0.75 ×** the demolisher's; `resistances` and `healing_per_tick` copied in data stage. White square sprite, about 6×6 tiles. `is_military_target = true` so turrets shoot it. | One prototype per size keeps the numbers exact. With max health at 0.75 ×, "×0 → ×0.75" is simply 0 → 100 % of the prototype. |
| H-3 | Which guardian | Save the guardian's prototype name on the territory record when it is seen (scan / unit created). Fallback: the distance formula above on the territory centre. | Exact for territories we saw with a guardian. |
| H-4 | Building | **Our own version of the vanilla mechanic**: on arrival, set aside **builders = 10% of the army (5–20, like settler groups)**. One builder is sacrificed (removed) every `build time / builders`; each one adds its share of health. | Same feel as expansion (biters turn into the base), but we control timing and the entity. Not `build_base` itself: the engine would build a vanilla nest. |
| H-5 | Health while building | Each sacrificed builder adds `max_health / builders` (clamped to max). Starts at ~0. | No regen (H0), so damage simply stays. |
| H-6 | Regen | **Decided: copy the guardian's stats plainly, nothing special.** `healing_per_tick` is copied but has no effect on `simple-entity-with-force` (H0); **no scripted regen** (2026-10-12). Guardians being far too strong is a known issue, to address later (phase I). **2.1 regression (user, 2026-10-15, 2.1.21):** `simple-entity-with-force` heals in 2.1 (confirmed in game: 1 → 3381 HP in under 1 s; the rally showed 75000/75000 at builders 3/19). **Fixed:** `healing_per_tick = 0` on the rally prototype. Retest passed in game (user, 2026-10-15, 2.1.21): crusades work as expected. | |
| H-7 | Army at the rally | Group command `wander` near the rally (radius ~20, `distraction = by_enemy`). | They defend the rally and attack players nearby. |
| H-8 | Military check | Every 10 s, per chunk of the target: `count_entities_filtered{force = "player", type = {character, ammo-turret, electric-turret, fluid-turret, artillery-turret, car, spider-vehicle, combat-robot, artillery-wagon}}`. Stop at the first hit. | Walls and normal buildings don't count (7a). |
| H-9 | Units inside | Army members whose chunk belongs to the target territory. | Matches "N enemy units inside". |
| H-10 | March timeout | If the group hasn't arrived after 5 min: send it again from where it is. After a 2nd timeout: build where the group stands if that is inside the target; otherwise defeated. | Groups can get stuck. |
| H-11 | After loss | Leftover army is **released** (group dissolved, units stay as normal biters). | "Lost buildings: nothing special." Biters and the guardian attack what's there. |
| H-13 | Map tag | Tag "Crusade rally" on the rally spot (like the staging tag), removed when the crusade ends. | Decided (H-e). |
| H-14 | Rally defence | **New (H0):** biters don't defend the rally by themselves. On `on_entity_damaged` of the rally, the army attacks `event.cause` (`attack` command, `distraction = by_enemy`), then returns to the rally. At most once per 10 s. | Without this, a turret out of their vision can kill the rally freely. |
| H-15 | Intruder squad | **New (H4, H-g):** every 10 s in build/hold, scan the target for player military (nearest to the rally). If found and no squad is out: the ~25 % of the army (min 5) nearest the intruder form a squad: attack it → walk back to the rally → wander. A new squad only when the last one's target is gone or the squad is dead. | The military check alone only reset the hold timer; the army never reacted to a player out of its sight. |
| H-12 | Code | New `scripts/rally.lua` (spot, build, hold checks) and `prototypes/entity/rally.lua` (data). `crusade.lua` gets phases `march` → `build` → `hold`. `on_ai_command_completed` is shared with `waves.lua`. | |

**Steps:**
- [x] **H0. Engine tests (headless).** (a) A unit group with `go_to_location` over ~300 tiles: does it arrive, and does `on_ai_command_completed` fire for the group? (b) Rally entity: can we set `health` freely, do player turrets shoot it, do biters defend it? (c) Patrol path points: inside the territory? (d) Cost of the military check on a big territory.
  - **Headless (2026-10-12, 2.0.77, seed 12345).** Test prototype `ht-test-rally` in a throwaway mod in the harness mods folder (not in the repo): `simple-entity-with-force`, white square ×6, small demolisher stats ×0.75 health.

    | Test | Result |
    |------|--------|
    | (a) March | 50 small biters, `go_to_location` 316 tiles, `distraction = by_enemy`: arrived in ~26 s. `on_ai_command_completed` fires with `unit_number` = group `unique_id`, `result` 2 (success) ✓. **2 of 50 units dropped out of the group** (alive, stayed behind). |
    | (b) Health | `health` can be set freely (100 → 100) ✓. |
    | (b) Regen | **`healing_per_tick` does nothing on `simple-entity-with-force`**: prototype says 40, health stayed at 100 for 189 ticks. |
    | (b) Turrets | A player `gun-turret` targets the rally (`shooting_target` = rally) ✓. Yellow ammo vs. demolisher resistances: ~25 HP/s. |
    | (b) Defence | **Biters don't defend it**: 10 idle biters 40 tiles away stayed put while the turret hit the rally. |
    | (c) Patrol path | 64 territories, 42–74 points each (median 56). **99.9 % of points lie in their own territory**; 62 of 64 paths fully inside, worst 96 %. |
    | (d) Military check | Largest territory (219 chunks), 9 types, `limit = 1`, no hits (worst case): **1.9 ms** per full scan. OK every 10 s. |

  - **Consequences for H1–H3:**
    - H-5/H-6: regen doesn't work on this type. **Decided (2026-10-12): fine, no scripted regen.** Stats stay plainly copied.
    - H-9: count the army from **our own unit list** (`storage.crusade.units`), not group members, since units can drop out of the group.
    - New **H-14 (defence)**: on `on_entity_damaged` of the rally (event filter on its name), send the army to attack `event.cause`. Without this, the army ignores attacks from outside its vision.
    - Spot pick (H-1 spot): only patrol points whose chunk is in the target territory.
- [x] **H1. Rally data + spot.** Prototypes, guardian per territory, build time, spot pick. `/ht-crusade` shows them. Headless.
  - **Built:** `prototypes/entity/rally.lua` (`ht-rally-small/-medium/-big`, `simple-entity-with-force`, white square ×6, demolisher `max_health` × 0.75, `resistances` + `healing_per_tick` copied, `is_military_target`), locale `ht-rally`. `territories.lua` remembers `record.guardian` (on record creation, scan, `on_segmented_unit_created`). `scripts/rally.lua`: `guardian_for` (remembered, else the map gen distance rule), `plan` (guardian, rally prototype, build time 5/15/30 min), `pick_spot`. The trigger plans the rally and stores `guardian`, `rally_name`, `build_time`, `rally_spot` on `storage.crusade`; no free spot → no crusade, budget kept. `/ht-crusade` shows "Next rally" and "Rally".
  - **Headless (2026-10-12, 2.0.77, seed 12345, isolated mods folder):**

    | Test | Result |
    |------|--------|
    | Prototypes | small 22 500 / medium 75 000 / big 225 000 HP (= 0.75 × 30k / 100k / 300k), 7 resistance types each ✓ |
    | Guardian per territory | Known for **64 of 64** territories (11 small, 24 medium, 29 big). Distance rule matches 63; the miss is at 719 tiles (rule edge 720) ✓ |
    | Fallback | Guardian cleared → "by distance", same result ✓ |
    | Spot pick | **Bug found:** `find_non_colliding_position` could move a patrol point out of the target (10 of 50). Fixed: the moved spot must still be inside. After fix: **50 of 50** spots inside the target and placeable ✓ |
    | Trigger | Crusade stores `ht-rally-big`, guardian big, 30 min, spot inside + placeable ✓ |

  - Note: this map's ids differ from earlier runs (no `cheating-mod` in the harness mods folder), e.g. territory 14 is at 1469 tiles here.
- [x] **H2. March + build.** Army walks, arrives, builders sacrificed, health grows. Headless.
  - **Built:**
    - Phases now `migration` → `march` → `build` → `hold` → `ended`. Critical mass starts the march right away (target → `crusade`, staging tag removed, chat). A save waiting in G's `crusade` phase starts marching.
    - `army.lua`: our own unit list `state.units`; `regroup`, `position`, `take_builder`, `destroy_all`.
    - `rally.lua`: `place` (stored spot, else nearest free spot inside, else a new patrol spot), `builder_count`, `spot_near`, map tag "Crusade rally" (`mark`/`unmark`/`on_chunk_charted`).
    - New `scripts/tags.lua`: shared map tag code (staging + rally). Staging tag retry only during migration.
    - `crusade.lua`: march (`go_to_location`, radius 8, `by_enemy`), arrival via `on_ai_command_completed`, timeouts (H-10), build (builders every `build time / builders`, nearest unit within 40 tiles, +`max_health / builders` each), rebuild/defeat (H-b/H-f), defence `on_entity_damaged` with rally name filters (H-14: attack cause → walk back → wander), `finish` also removes the rally and its tag. `/ht-crusade` shows march and build progress.
  - **Headless (2026-10-12, 2.0.77, seed 12345, isolated mods folder, target territory 1 = small guardian, 411 tiles, staging 19):**

    | Test | Result |
    |------|--------|
    | Trigger → migration | 182 small biters, cost 729 ✓ |
    | March | Staging tag removed ✓. ~500 tiles, arrived in < 80 s; build started ✓ |
    | Build | Rally at the stored spot, **18 builders** (10 % of 182), +1250 HP each, one every ~17 s; 22 500 / 22 500 after 5 min → phase `hold`, chat ✓. Rally tag placed ✓ |
    | Defence (H-14) | Turret 60 tiles away hits the rally (`damage` with cause): army reaches and kills it in ~12 s ✓. **Bug found:** they then wandered where the turret was. Fixed: attack → `go_to_location` rally → wander. After fix: group back in `wander_in_group` around the rally (spread 15–45 tiles) ✓ |
    | Rally destroyed, army 163 | **Rebuilt** at the same spot: build #2, 16 builders, starts at ~0 ✓ |
    | Rally destroyed, army 12 (< 10 + builders) | **Defeated**: units, rally and tags removed, target `claimed` ✓ |
    | March timeout ×1 | Sent again (try 2) ✓ |
    | March timeout ×2, army outside target | Defeated, army removed ✓ |

  - Not tested: second timeout with the army **inside** the target (builds where it stands); chat text (no players headless).
  - **Changed (2026-10-12): the 15 min cooldown starts when a crusade ends** (territory lost, defeated or cancelled), not at the trigger. Before, a crusade could start within a minute of the last one ending. Headless (2.0.77): no cooldown while active; cancelled at tick 6055 → 900 s cooldown; next crusade at tick 61200 (first check after it ran out) ✓.
- [x] **H3. Hold + lost.** Checks, timer, reset, guardian respawn, release army. Headless.
  - **Built:** `update_hold` every 10 s in phase `hold`: army units inside the target (`army.count_inside`) and player military (`rally.player_military_in`, H-8 types, `limit = 1` per chunk). Both OK → the hold timer starts (chat "… holds the territory. 60 s until it is lost."); a failed check resets it (chat "the hold is broken"); a rebuild resets it too. 60 s → `lose`: rally removed, `create_segmented_unit{name = guardian, position = rally, territory = target}`, `finish(message, lost = true)`: army **released** (`army.release`), tags removed, target → `hostile`, cooldown starts. `/ht-crusade` shows the hold progress and "ended, territory lost".
  - **Headless (2026-10-12, 2.0.77, seed 12345, target territory 1, small guardian):**

    | Test | Result |
    |------|--------|
    | Reach `hold` | Trigger → migration → march → build → hold in ~9 game min ✓ |
    | Player turret inside the target (260 tiles from the rally) | `military true`, not holding ✓ |
    | Turret removed | Hold starts (164 units inside) ✓ |
    | Turret placed during a running hold | Hold reset ✓ |
    | Removed, 60 s held | **Lost** ✓: target `hostile`; rally gone; a **small demolisher at the rally spot, 30 000 / 30 000 HP**, in the target territory; **163 biters stay** near the spot; no tags; cooldown 893 s ✓ |

  - The test territory also kept its original guardian (it was set to `claimed` by command, not by killing it). In play the original is dead, so there is one guardian.
  - Not tested: hold broken by **too few units** (same code path as military).
  - Cosmetic: after a loss `/ht-crusade` shows "0 alive" because released units are no longer tracked.
- [x] **H4. In game.** Full crusade: march, build, defend or lose. **Done as POC (2026-10-12, 2.0.77):** after the squad fixes below, attacks behave "way closer to expected". Good enough for the POC; further tuning goes to phase I and "Later: smarter crusade AI".
    Setup: kill the guardian of a territory near spawn (small guardian → 5 min build), so it is claimed and the furthest claimed one. Your **character counts as military**: standing in the target blocks the hold. Optional speed-up: `/c game.speed = 4` (back with `= 1`).
    1. Arm: `/c __Hostile-territory__ storage.crusade_budget = 5000 storage.crusade_cooldown_until = 0 game.print("armed")`
    2. Within 60 s: "Crusade warning", target yellow-orange, staging tag. After ~2 min: "… march from territory S", target bright orange, staging tag gone.
    3. On arrival: "… builds a rally at x,y (5 min)", white square + "Crusade rally" tag. `/ht-crusade` shows health growing per builder.
    4. **Defend run:** shoot the rally: the army comes for you. Destroy it: "… rebuilds it". Then kill the army: "… defeated", target back to no colour, tags and rally gone.
    5. **Lose run** (arm again after the 15 min cooldown, or reset with step 1): stay **outside** the target. After the build: "… holds the territory. 60 s until it is lost." → "Territory X is lost: the rally turned into a small-demolisher." Target turns red (guardian), leftover biters stay.
    6. During a hold, walk into the target: "the hold is broken"; walk out: the hold starts again.
    Check also: does the guardian patrol normally afterwards? Can the territory be challenged again?
  - **In game (2026-10-12, 2.0.77): mod failed to load**: "sprite rectangle 0x0–32x32 is outside the actual sprite size 10x10: `__core__/graphics/white-square.png`". The headless server doesn't load graphics, so H0–H3 missed it. Fixed: `size = 10`, `icon_size = 10`, `scale = 19.2` (still 6×6 tiles). Retest open.
  - **In game (2026-10-12, 2.0.77), after the sprite fix:** the crusade "seems to work pretty well". Found: entering the target during the hold prints "the hold is broken", but **the army doesn't come after the player**. It does when the player attacks the rally (H-14). Cause: the army only wanders near the rally (radius 20) and reacts to what it sees; the military check only resets the timer. See H-g.
  - **Built H-15 (2026-10-12):** `rally.find_player_military` (nearest to the rally, one candidate per chunk), `army.split`, `check_intruders` in build + hold. `/ht-crusade` shows the squad.
  - **Headless (2026-10-12, 2.0.77):** player turret placed in the target 392 tiles from the rally during the build. **Squad of 45** (25 % of 180) went for it, **135 stayed** at the rally, building went on. Turret destroyed after ~60 game s; squad walked back and wanders at the rally (172 of 172 near it) ✓.
  - [x] **Retest in game:** walk into the target during build/hold: a squad comes for you, the rest stay at the rally. Covered by the final H4 result.
  - **In game (2026-10-12, 2.0.77): no attack**, neither during build nor hold, while standing in the target.
  - **Headless repro (2026-10-12, 2.0.77):** a `character` (player force) placed in the target 80 tiles from the rally during the build → squad of 45 attacked and killed it within ~12 s. So the code works headless. Suspects: (1) the squad targets the military entity **nearest the rally**, which may be the cheat kit's **spidertron**, a turret or robots, not the player; (2) the save wasn't reloaded after the change (control.lua only reloads on load). `/ht-crusade` now also shows the squad's position and its target with position.
  - **In game (2026-10-12, 2.0.77), with the new output:** during the build the squad was sent `after character`, but its group **stood still at -187,361 for ~60 s** while the player moved. In the hold the army did attack the player.
  - **Cause (headless repro, character teleported away):** when the target moves, the group's attack ends early and the group sits **`finished`, no command**. The squad still counted as busy (target alive, members > 0), so no new command or squad was sent.
  - **Fix (2026-10-12):** every 10 s the squad gets a fresh command when it is idle (`finished` or no command) or a different intruder is nearest. No intruder left + idle squad → walks back to the rally.
  - **Headless after fix (2026-10-12, 2.0.77):** tough character, teleported ~100 tiles twice: the squad followed both times, reached it and attacked (`attacking_target`, 45 within 20 tiles) ✓. Character removed → squad walked back toward the rally ✓.
  - [x] **Retest in game:** stand in the target and move around during the build: the squad keeps coming. Covered by the final H4 result.
  - **Decided (2026-10-12): the squad prefers the player character** over other military (turrets, vehicles, robots). Other military only when no character is in the target. Built: `rally.find_player_military` scans characters first. Smarter AI ideas: see "Later: smarter crusade AI". Headless (2026-10-12, 2.0.77): turret 69 tiles from the rally, character 159 tiles: squad goes `after character` ✓.
  - **In game (2026-10-12, 2.0.77):** better during the build, but **after the rally was finished no attack**. `/ht-crusade`: squad at the rally, "sent 204 s → 344 s ago" (never re-sent), target the player 250 tiles away.
  - **Cause:** the squad had walked back and was **wandering** at the rally while its target was still alive; only `finished` counted as idle, so it stayed "busy".
  - **Fix (2026-10-12):** busy only while gathering, moving, pathfinding or attacking; otherwise idle → re-sent. Also re-sent every 60 s while the same intruder stays (`SQUAD_REFRESH`).
  - **Headless after fix (2026-10-12, 2.0.77), phase hold:** tough character teleported 3× to random spots 120–220 tiles from the rally: each time the squad was re-sent within 10 s, and it reached and attacked the character (`attacking_target`, 27 next to it) ✓.

**Resolved (2026-10-12):**
- H-a. ~~Rally health after the build?~~ The rally stays as it is (max ×0.75 of the guardian) while holding. When the territory is **lost, the rally disappears and turns into the guardian at full health**.
- H-b. ~~Rally destroyed?~~ **Keep rebuilding while there is sufficient budget.** Later maybe a cutoff, so a few lone stragglers don't keep trying in an annoying way.
- H-c. ~~Build time curve?~~ **By guardian size:** 5 / 15 / 30 min.
- H-d. ~~Builders?~~ 10 % of the army, 5–20. Good starting point.
- H-e. ~~Player info?~~ **A map tag** on the rally.
- H-6. ~~Regen?~~ Copy plainly for now; guardian strength to address later.

- H-g. ~~Should the army go after player military in the target?~~ **Decided (2026-10-12): a small squad** (~25 % of the army, at least 5) attacks the military entity nearest the rally, then returns; the rest guard the rally. In **build and hold**. See H-15.
- H-f. ~~What is the "budget" for rebuilding (H-b)?~~ **Decided: (1), the army itself.** (1) **The army itself** (it is the spent budget): rebuild while the army still has ≥ 10 + builders units; if not, the crusade is defeated. Or (2) **the global crusade budget**: each rebuild pays for new builders (spawned at the staging nest, they walk to the rally). Simpler, and it already stops lone stragglers from rebuilding.

### Later: smarter crusade AI (ideas, 2026-10-12)

The POC AI is easy to fool: a squad chases one target, so the player can use a character, vehicle or turret as a **decoy** to pull units away from the rally. Ideas to look at later (not planned yet):
- **Leash:** a squad stops chasing beyond N tiles from the rally and returns.
- **Threat first:** prefer whatever is damaging the rally or the army right now over the nearest target.
- **Several squads:** one per threat, sized by threat (a turret line needs more than a lone character).
- **Keep a minimum guard:** never send units below N at the rally (the hold needs 10 inside anyway).
- **Ignore decoys:** don't chase fast vehicles they can't catch; give up after a timeout without damage dealt.
- **Retreat / regroup:** pull back to the rally when a squad drops below half strength.

### Later: challenge and army templates (idea, 2026-10-12)

Not planned yet. Challenges and crusades will mix `Hostile-fauna` units with vanilla ones (`enemy-balancing-plan.md` D18). Idea: **templates** that define a mix-up (which units, which waves, which combination of challenge types) and **when** each template is used (distance, evolution, territory, maybe random weight). Today the mix is hard-coded in `waves.lua` and `army.lua`.

### Idea: challenge arena and player punch (2026-10-15)

**Goal:** a survivors-like feel **only inside a challenge**. Enemies keep their normal (rebalanced) speed everywhere else, and turret balance stays roughly intact. Two parts: (1) an **arena** that slows things inside it, (2) the player **packs more punch per bullet than a turret**.

Status: **decided (2026-10-15)**, next step AR1.

#### Decisions (2026-10-15)

| # | Topic | Decision |
|---|-------|----------|
| AR-a | Player slow | **No** for the first tests. Maybe later. |
| AR-b | Which enemies | **All enemy units** inside the arena (challenge waves, passing vanilla biters, crusade units). |
| AR-c | Turrets | **(a) Accept** that turrets in the arena profit from the slow. |
| AR-d | Edge | **The arena edge is the lose line.** The arena is **fixed** at the challenge start; it doesn't follow the player. |
| PP-a | Player punch method | **(b) Gun `damage_modifier`** first. (a) per-ammo later, for player-only effects. |
| PP-b | Strength | **2×** per bullet to start. |
| PP-c | When | **Always**, not only in the arena. |

POC defaults (proposed with the decisions, change freely): centre = the triggering participant's position at challenge start; radius **80 tiles** (waves spawn 40–50 tiles from the player, so mostly inside); outside the arena for `LOSE_GRACE` (5 s) = lose, on top of today's rules (guardian not engaged, nobody within 100 tiles of a guardian).

#### Confirmed facts (2.1.21 docs and game files)

| Fact | Source |
|------|--------|
| Stickers slow anything that takes them: `target_movement_modifier` (units, characters), `vehicle_speed_modifier` (vehicles). `duration_in_ticks` can be short, so a short sticker **refreshed every 30 ticks** acts as an area effect: leave the area and it wears off. | `prototype-api.json` |
| `LuaControl.character_running_speed_modifier` is a writable per-character modifier (−1 = stopped). | `runtime-api.json` |
| `LuaSegmentedUnit.speed` / `target_speed` exist, but the AI sets the speed. Slowing the guardian is not simple. | `runtime-api.json` |
| `AmmoItemPrototype.ammo_type` can be an **array** with `source_type` = `default` / `player` / `turret` / `vehicle`. Same magazine, different damage (or effects) per shooter. Vanilla uses it for cannon shells (`base/prototypes/item.lua:2842`). | `prototype-api.json`, base |
| Guns have `attack_parameters.damage_modifier`. Player guns (pistol, SMG, shotgun, …) are separate prototypes from turrets, so they can be scaled alone. | `prototype-api.json` |
| Flat resistance makes **per-bullet damage** count a lot: big biter takes 0.18 from 5 phys, 14.4 from 24 (EB D19). A player bullet that hits harder than a turret bullet gets through armour that turret bullets bounce off. | `enemy-balancing-plan.md` |

#### Part 1: arena (proposal)

| # | Topic | Proposal |
|---|-------|----------|
| AR-1 | Shape | Circle around the challenge start, radius ~60 tiles (POC). Visible ring via `rendering.draw_circle`. |
| AR-2 | Enemy slow | Every 30 ticks, enemy units inside get a short slow sticker (~1 s). Outside the arena: full speed within a second. **Replaces** the lifelong stickers on wave units (`waves.lua`). Strength per ring stays (50 % → 10 %). |
| AR-3 | Player slow | **Decided: not for now (AR-a).** Optional, smaller than the enemy slow, so kiting still works. Via `character_running_speed_modifier` (save and restore the old value) or a player sticker. |
| AR-4 | Which enemies | All enemy units inside (also passing vanilla biters and crusade units), or only challenge units. |
| AR-5 | Turrets | Turrets in the arena profit from slowed enemies. Options: (a) accept it; (b) no slow near player turrets; (c) arena switches off while non-character military (turrets, robots) is inside. |
| AR-6 | Edge | Today you lose at 100+ tiles. Option: the arena edge **is** the lose line (outside > 5 s = lose). |
| AR-7 | Guardian | Not slowed (POC). |

Cost: one `find_entities_filtered{position, radius, force = "enemy", type = "unit"}` per challenge every 30 ticks, ≤ 60 units each. Cheap.

#### Part 2: player punch (proposal)

| Option | How | Pro | Con |
|--------|-----|-----|-----|
| (a) `source_type` ammo | Each magazine gets a `player` entry (e.g. 2× damage) and a `turret` entry (vanilla). Loop in `data-final-fixes` | Exact per ammo; can add **player-only effects** (slow, knockback, pierce) | Every ammo, incl. other mods' ammo |
| (b) Gun `damage_modifier` | Raise it on player guns (pistol, SMG, shotgun, rocket launcher, flamethrower) | One number per gun, works with any mod's ammo | Same buff for every ammo tier |
| (c) Script on `on_entity_damaged` | Extra damage when the cause is a character | Could be arena-only | UPS, hacky. Not recommended |
| (d) Weaker turrets | Force turret modifiers | — | Fights with research |

**Recommendation:** start with (b), move to (a) when we want player-only effects. Lives in `Hostile-fauna` (player speed is there too, D11). Reopens EB D9 ("player tools out of scope") and changes the checkpoint math (D19–D23): the checkpoint table must use player damage, not turret damage.

#### Steps

- [x] AR0. Answer AR-a … PP-c. Done 2026-10-15, see decisions.
- [x] AR1. Headless: short refreshed sticker on a unit. Speed drops inside, back to normal ~1 s after leaving. (Character dropped: no player slow, AR-a.)
  - Added `ht-arena-slow-10` … `-50` to `prototypes/entity/challenge-stickers.lua`: `duration_in_ticks = 60`, no graphics.
  - **Headless (2026-10-15, 2.1.21), passed.** Three small biters (`speed` 0.225) walk east on flat grass, `go_to_location`, `distraction = none`. For 300 ticks: *refresh* gets `ht-arena-slow-50` every 30 ticks, *spam* gets it every tick, *control* gets nothing.

    | Biter | Ticks 0–300 | After the last sticker (tick 300) | Stickers attached |
    |-------|-------------|-----------------------------------|-------------------|
    | control | 13.4 tiles / 60 ticks | 13.4 | 0 |
    | refresh (every 30) | **6.6 / 60 = exactly 50 %** | 6.7 for ticks 300–360, then **13.4 from tick 360** | 1 |
    | spam (every tick) | 6.6 / 60, same as refresh | same | **1**: a second sticker of the same name refreshes it, it doesn't stack |

  - Result: refreshing every 30 ticks keeps the slow steady. Full speed returns **≤ 60 ticks** after the last refresh. Applying it more often than needed is harmless.
  - Harness note: an old headless server from another session (PID 14816, started 20:49) was still running and holding port 34299. Used ports 34391 / RCON 27191 instead; PID 14816 stopped afterwards on the user's request.
- [ ] AR2. Build the arena (new `scripts/arena.lua`, hooked into `challenge.lua`): ring drawn, slow sticker refresh for all enemy units inside, lose when every participant is outside the edge for 5 s. Drop the lifelong wave stickers.
- [ ] AR3. In game: feel test (user).
- [ ] PP1. Player guns `damage_modifier` × 2 in `Hostile-fauna` (PP-a/b): pistol, SMG, shotgun, combat shotgun, rocket launcher, flamethrower. Note in EB plan that D9 is partly reopened. Headless: SMG bullet vs. gun turret bullet on a big biter.
- [ ] PP2. Update the checkpoint table (EB D23) with player damage.

#### Open questions

- ~~AR-a … PP-c~~ Decided 2026-10-15.
- ~~AR-e. Radius 80, centre at the player's start position?~~ **OK to start (2026-10-15).**
- ~~AR-f. Leftovers still flee on a win (now at full speed once outside)?~~ **Yes, fine (2026-10-15).**

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
