# Challenge Feel

> **Status:** **First ring done for now** (2026-10-18): E1–E9, PT1–PT9; PT9b won with 35 of 100 magazines left · **Parent:** phase I in [vision-plan.md](vision-plan.md) · **Next:** **first ring done for now** (user, 2026-10-18). Later: P2 arsenal, other rings · [Roadmap](roadmap.md)

Started 2026-10-18 (game 2.1.21). Work is driven by **problems**, not features: we describe how a challenge should feel, playtest, and solve the gaps. Units, arena, player punch etc. are possible **answers**, picked per problem.

## Goal

A challenge that leaves the player with: **"I earned that ground."**

**Scope for now: the first ring of territories only** (user, 2026-10-18), right next to the safe area. In the code that's **ring 0** (CF-D7); this plan says "first ring". Other rings wait until the first ring is built and feels right.

## The loop

**Feel target → playtest → gap ("it felt X, I wanted Y") → likely cause → smallest experiment → playtest again**

- The feel target may change after any playtest. Record the change and why in the feel target table (date + reason).
- One problem at a time. Each problem gets a row in **Problems** and a section with causes, experiment and result.
- A solution only counts once a playtest confirms the gap is closed.

## Feel target

| # | Aspect | Target | Since |
|---|--------|--------|-------|
| F1 | Result | "I earned that ground." | 2026-10-18 |
| F2 | Arc | Phases, not one steady fight. Draft below is OK to start with (user) | 2026-10-18 |
| F3 | Player role | Hero on foot should be able to win, but **everything is allowed**. The arsenal Factorio lets you build should be *useful* in a challenge. Today it feels like it isn't | 2026-10-18 |
| F4 | Losing | Both answers are valid: **more skill** or **more preparation/equipment** | 2026-10-18 |
| F5 | Length | Close rings: ~1 minute. Far rings: longer, later | 2026-10-18 |
| F6 | Difficulty | Between "overwhelmed and dead" and "kill everything at once". You can retreat and kite (enemy-balancing Goal) | 2026-10-12 |
| F7 | Weapon checkpoints | Before the right weapon: beatable with effort. After: easy (enemy-balancing D19–D23) | 2026-10-15 |
| F8 | Direction | You fight *towards* something (the brain), part of a hive | 2026-10-17 |
| F9 | Enemy numbers | **Many weak enemies**, not a few strong ones. Mostly in the last phase, which is where the challenge lies | 2026-10-18 |
| F10 | Where enemies come from | **From a nest**, then they try to surround you. Not spawned in around you | 2026-10-18 |
| F11 | World layout | A **safe zone** around spawn with only the starting resources (water, coal, iron, copper, stone). **Everything outside it is some form of fight**: territories start right at its edge (PT1, screenshot) | 2026-10-18 |

### Phases (draft, OK to start with)

| Phase | What happens | Player's job |
|-------|--------------|--------------|
| 1. Approach | You enter the territory. The hive is quiet. | Scout, choose an approach, set up |
| 1b. Siege (E9, "phase 0") | You attack a nest or worm of the brain base: the challenge starts (the base stops regrowing). Small groups from the nests. | Clear the base, or go for the brain |
| 2. Wake-up ("phase 1") | The brain engages (you attack it or come close). Groups come out of the nests. | Hold your ground or fall back |
| 3. Push | You move in on the brain base and kill nests; fewer nests = fewer enemies. | Break through, keep moving forward |
| 4. Swarm ("climax" until E8) | The big swarm pours out of the nests and tries to surround you; guards block the brain's front; a last stand keeps coming until the brain dies. | Survive, kill the brain |
| 5. Claim | The territory turns yours. | Feel the reward (F1) |

## Decisions (user, 2026-10-18)

| # | Topic | Decision |
|---|-------|----------|
| CF-D1 | Scope | Ring 1 only until it's built and feels right |
| CF-D2 | One-shot | **One small biter = one shot of the weakest ammo** (yellow) **for the player**. Turrets keep the current balance |
| CF-D3 | Ammo budget | A ring-1 territory is beatable with **1 stack of yellow ammo** |
| CF-D4 | Ring 1 distance | **Much closer** to spawn than today |
| CF-D5 | Spawning | Challenge enemies come **out of the base's nests**, not in around the player (F10) |
| CF-D6 | Numbers | Many more, weaker enemies; most of them in the last phase (F9) |
| CF-D7 | Ring naming (Q5) | Fine to keep calling it **ring 0**, as long as territories start **right next to the safe area that holds the starting resources**. Today they do (384 tiles); check that the starting resources sit inside it |
| CF-D8 | One-shot method (Q6) | Pistol + SMG `damage_modifier = 3`. **Replaces PP-b (2×)** in the vision plan. Accepted side effect: ×3 against nests, worms, bigger biters too |
| CF-D9 | Gun (Q7) | **SMG** for the first ring (1000 bullets = 100 s of fire) |
| CF-D10 | Brain (Q8) | The first ring gets its own weak brain, no regen. Size: **100 or 150 bullets** (user unsure). Started with 100 (750 HP); **150 (1125 HP) since PT5** (CF-D20) |
| CF-D11 | Climax trigger (Q9) | **Brain below 50 % HP** |
| CF-D12 | Safe zone (Q11, P6) | **Option A**: safe radius 150; points closer than 200 pushed out to 200 |
| CF-D13 | Fissures (Q12, P7) | Removed from the **small** brain only; medium and big keep them for now. Shockwave stays |
| CF-D14 | Surround (Q14, P8) | **Climax only** for now: batches run to left / right / behind you first, then attack |
| CF-D16 | Cloud slow + climax size (Q15) | Biters **slower** in the cloud (×0.45, was 0.5) **and more** of them in the climax (250, was 200) |
| CF-D17 | Surround (Q16) | Every climax biter runs to **its own point on a ring** around you (12–18 tiles, over your sides and back), then attacks |
| CF-D18 | Wake (Q17) | Groups of **7–13** (was 5–10), max **50** alive (was 40) |
| CF-D19 | Detour + wake (PT4) | Try a **very wide detour** for the climax swarm (user: focus fire keeps it under control, without it it's very tense; a detour may even that out). Wake a bit busier: groups **9–15**, max **60** |
| CF-D20 | After PT5 | Wake slightly busier again: **11–17**, max **70**. Brain **150 bullets** (1125 HP; CF-D10 settled). Keep the pressure after the swarm: **last-stand trickle** (user's pick of 3: trickle / second swarm at 25 % / longer swarm) |
| CF-D21 | Brain guards (Q18) | No damage tricks: it's fine that bullets can't be blocked. Just **more biters walk in front of the brain**, so auto-target / clicking hits them first (it already felt like that for the few in PT6) |
| CF-D22 | After PT7 | Rename the phase **"climax" → "swarm"** (user: something else than climax; matches "The hive swarms!"). Swarm starts **earlier, at 60 %** brain HP (guards in place sooner). Last stand **slightly more**: groups of **12** |
| CF-D23 | After PT8 | Last stand **5 every 2 s** (2.5/s, steadier; was 12 / 4 s). New **phase 0 "siege"**: attacking a base piece (nest, worm) around the brain starts the challenge, so **no regrowth while it runs**; phase 1 = attacking the brain (wake), phase 2 = brain below 60 % (swarm). Siege has **small groups** (4–7 every 10 s). Leaving during siege **counts as lost** |
| CF-D15 | Shockwave (PT2) | **Keep** the ash cloud ("shockwave"), but the challenge must be tuned around its speed effect. First try (user's idea): it **slows the biters too**, so you can outrun them again (E3) |

## Confirmed facts (game files + code, 2026-10-18, 2.1.21)

| Fact | Value | Source |
|------|-------|--------|
| Yellow ammo | 5 physical per bullet, 10 per magazine, **stack 100 = 1000 bullets** | `base/prototypes/item.lua:4051` |
| Small biter | 15 HP, no resistances | `base/prototypes/entity/enemies.lua:77` |
| Biter spawner | 350 HP, physical 2 flat / 15 % | `enemies.lua:137` |
| Small worm | 200 HP | `enemies.lua:592` |
| Pistol / SMG | cooldown 15 / 6 ticks = **4 / 10 shots per second** | `item.lua:4282`, `:4315` |
| Gun turret | own `attack_parameters`, so a `damage_modifier` on the pistol/SMG doesn't touch turrets | `turrets.lua:458` |
| Small brain | copy of the small earth wyrm head: **30 000 HP, regen 40 per tick (2400/s), physical 50 %** | `Hostile-fauna/prototypes/brain.lua`, `earth-wyrm.lua:14`, `space-age/.../enemies.lua:331, 484` |
| Safe area | 384 tiles around spawn (points < 420 join it) | `nauvis-territory.lua:11, 17` |
| Territory grid | 384-tile cells, so the first territories sit at roughly 384–770 tiles | `nauvis-territory.lua:9` |
| Brain size | small up to ~720 tiles, then medium, big | `nauvis-territory.lua:82` |
| Challenge ring | `floor(distance / 500)` from the brain: the first territories are mostly **ring 0** today | `waves.lua:7, 42` |

### Budget math (draft)

With the player's pistol/SMG at **`damage_modifier = 3`** (one way to get CF-D2, see Q6):

| Target | Damage per yellow bullet | Bullets to kill |
|--------|--------------------------|-----------------|
| Small biter (15 HP) | 15 | **1** |
| Biter spawner (350 HP) | (15 − 2) × 0.85 = 11 | 32 |
| Small worm (200 HP, resistances not checked yet) | ≤ 15 | ≥ 14 |
| Small brain today (30 000 HP, 50 %, 2400 HP/s regen) | 7.5 | **never** (SMG does 75 dps) |
| First-ring brain (CF-D10: 750 HP, no regen) | 7.5 | 100 |

Draft split of 1000 bullets for a first-ring win:

| Part | Bullets |
|------|---------|
| Small biters, all phases | ~450 (= ~450 biters) |
| 4 nests + worms | ~200 |
| Brain | ~100 (CF-D10) |
| Slack (misses, shooting buildings, nerves) | ~250: skill shows as ammo left over |

Fight time at full fire: 1000 bullets = 100 s with the SMG, 250 s with the pistol. ~450 biters is ~45 s of SMG fire, which fits "about a minute" (F5) only with the SMG.

## How a challenge works today (code, 2026-10-18)

- **Start:** the brain is engaged while a player is within 100 tiles. No phases; waves start **2 s** after the start.
- **Waves:** spawned **around the player** (all sides), slowed by a ring sticker, ordered to attack. Ring 0: 3 tiny biters every 10 s (max 15). Ring 1: 5 tiny/small every 8 s (max 25).
- **Also present:** the brain base's own nests and worms, the brain.
- **Win:** brain dead (territory claimed). **Lose:** for 5 s no brain engaged or no participant within 100 tiles.

## Problems

| # | Problem (gap) | Feel | Status |
|---|---------------|------|--------|
| P1 | Enemies in general overwhelm you too easily early on (not only in challenges) | F6 | Answer chosen: CF-D2 one-shot + CF-D6 more, weaker enemies. Check in PT1 |
| P2 | Your arsenal can't really be used in a challenge | F3 | Later, after PT1 |
| P3 | The first-ring brain can't be beaten with 1 stack (30 000 HP, 2400 HP/s regen) | CF-D3 | Found 2026-10-18. Answer: CF-D10, built in E1 |
| P4 | Challenge enemies appear around you instead of coming from the hive | F10 | Answer in E1 |
| P5 | Ring 1 is too far from spawn | CF-D4 | Replaced by P6 (PT1: the safe area itself is too big) |
| P6 | Safe zone far bigger than the starting resources, and a free band before the first territories | F11 | **Solved**: CF-D12 (E2), confirmed in PT2 ✅ |
| P7 | The brain's lava fissures are too strong for the first ring (they killed you in PT1, Q13) | F6 | **Solved**: CF-D13 (E2); PT2 lost to the swarm, not fissures |
| P8 | Climax too strong, yet you want *more* biters; no surrounding | F9, F10 | Surround works (PT2 ✅) but overwhelms: see P9 |
| P9 | Climax swarm surrounds and overwhelms you: you can't outrun it inside the brain's ash cloud | F6, F10 | **Solved** for now: PT4 outrunnable and tense ✅ (E3 + E4) |
| P10 | Surround reads as 3 "jets" of attacks, not as being surrounded | F10 | **Solved**: PT5 "swarm feels very good now", later arrival fine (E5) |
| P11 | Wake/push phase needs slightly more biters | F9 | **OK for now** (PT6): could take more, but it should ramp up from here |
| P12 | After the swarm the brain is easy, and it can be killed before the swarm is in full effect | F2, F9 | PT9: near the end (brain almost dead) overwhelmed, had to run; cause unclear. Likely the last stand piling up while you focus the brain (it keeps coming until 120 are alive). Q22 |
| P13 | A base you attack regrows during the fight (one piece came back almost at once): the challenge only starts when the brain engages, so the territory is still "hostile" and regrows every 60 s | F1 | **Solved** (E9): all notifications appear in PT9 ✅ |
| P14 | Only the first base you take gets all phase messages; later "first ring" bases only print "Challenge started" and are much weaker (user, 2026-10-18; PT9b fits too) | F2, CF-D7 | **Likely cause:** those bases are **ring 1** in the code. Ring = grid layer of the brain's cell (`waves.ring_at`), but territories are nearest-point regions, so a ring-1 territory can reach the safe-zone edge (e.g. a point at (422, 38) is closer to (150, 0) than any ring-0 point). Ring 1 has no siege, no wake/swarm messages, and the old "5 around you every 8 s" waves. Check with `/ht-challenges` (shows `ring N, phase …`). Q23 |

P2 first thoughts: no time to set up before the fight starts, waves follow you, and you must stay within 100 tiles of the brain. Phase 1 "Approach" may be part of the answer.

### P6. Safe zone and the first territories (PT1, 2026-10-18)

User: the safe zone should be only the area with the starting resources (green circle in the PT1 screenshot); everything outside it is a fight.

Measured headless (2026-10-18, 2.1.21):

| | Seed 12345 | Seed 987654 | Seed 555 |
|---|---|---|---|
| Starting patches (iron, copper, coal, stone): farthest tile | 92 | 99 | — |
| Next patches (not starting resources) | 172, 310, 357… | 215, 261, 268… | — |
| First territory tile from spawn, per 15° (min / median / max) | 360 / 400 / 592 | 368 / 448 / 592 | 360 / 448 / 592 |
| Nearest brain | 445 | 574 | 640 |

Causes:
- **Safe area is 384 tiles**, but the starting resources end at ~100. Patches at 170–380 are free today.
- **Points closer than 420 join the starting area** (`POINT_START`, so a brain base never stands inside it). That frees their whole cell, so the free band reaches up to ~590 tiles in places.

Options:

| | What | + | − |
|---|---|---|---|
| **A (recommended)** | Safe radius ~150 (starting patches + margin). A point closer than ~200 is **pushed outward** to ~200 along its direction from spawn, instead of freeing its cell | Territories start right at the safe edge, every direction. Every cell keeps its brain. Pushed points stay in their cell (cells are 384, points start at the spawn corner) | First brains can be only ~200 tiles from spawn. Same formula must change in `regrow.lua` (Lua copy of the layout) |
| B | Safe radius ~150, keep "join the starting area" with a smaller threshold | Smallest change | A cell whose point lands near spawn still frees ~a quarter of the map around it (likely in 1 of 4 directions per map) |
| C | Safe radius ~150; near-start points don't count, neighbouring territories grow inward | No brain close to spawn | Odd, very large first territories with their brain far away |

### P7. Fissures (PT1, 2026-10-18)

The brain inherits the demolisher's **revenge attack** (`revenge_attack_parameters`): fissures → magma eruption, range 64 tiles for the small size, every 20 ticks. The shockwave stays (maybe reflavoured later). Answer: `revenge_attack_parameters = nil` on `hf-brain-small` only.

### P8. Climax too strong, but more biters wanted (PT1, 2026-10-18)

- "Brain enraged phase felt a bit too strong", yet "if bullets allow it, even more of them".
- Likely cause: the fissures (P7) on top of 200 biters, not the biter count. Check after P7 is fixed.
- Biter budget: ~450 bullets (= biters) in the draft split, today wake ~7 per 8 s + climax 200.
- Surrounding is missing (user). → E2.

### P9. Can't outrun the swarm in the ash cloud (PT2, 2026-10-18)

- PT2: lost on the climax, twice (again after respawn), **61 of 100 magazines left**: ammo is not the limit, speed is.
- The "shockwave" is the enraged brain's **ash cloud**: expanding clouds that put `demolisher-ash-sticker` on the brain's *enemies* only (`target_enemies = true`): speed capped at **0.15** (player normally 0.25), ×0.9, 2 s, refreshed while inside (`space-age/.../enemies.lua:1817, 2786`).
- Small biters run 0.225 and have no slow in ring 0 since E1-6. In the cloud they are ~50 % faster than you.

## E9. Siege phase, steadier last stand (built 2026-10-18, headless ✅, waiting for PT9)

| # | Part | Build | File(s) |
|---|------|-------|---------|
| E9-1 | Siege trigger (CF-D23) | `on_entity_damaged` (filtered to `unit-spawner` and `turret`): a player (character, or driver of a car / spidertron) damaging an enemy nest or worm **within 30 tiles of a ring-0 brain** of a **hostile** territory starts the challenge in phase **"siege"** (state "challenge", so `regrow.lua` skips it). In a running challenge it adds the player | `scripts/challenge.lua`, `control.lua` |
| E9-2 | Siege rules | No `keep_engaged` on the brain during siege (it joins in by itself). Lose: only "no participant within 100 tiles of the brain for 5 s" (counts as lost: brain healed, message). Brain engages → `waves.wake`: phase "wake", first group after 2 s, "The brain wakes!" | `scripts/challenge.lua`, `scripts/waves.lua` |
| E9-3 | Siege groups | **4–7 every 10 s** × share of nests alive, max 30 alive, from the nests (no surround) | `scripts/waves.lua` |
| E9-4 | Last stand (CF-D23) | **5 every 2 s** (was 12 / 4 s) | `scripts/waves.lua` |
| E9-5 | Test | `waves_step(x, y, target, {phase, wake})`; the test runs siege → wake (15 s) → swarm (25 s) → clear → last stand | `control.lua`, `tools/ht-challenge-test` |

The engaged-brain start (phase wake) is unchanged, so walking up to the brain without touching the base still starts at wake. Other rings: unchanged (no siege).

**Headless (2026-10-18, 2.1.21, seeds 12345 + 987654):** siege groups 7 / 4 at 2 s, then 2 / 3 after half the nests died (12 s) ✅; wake 2 s after the brain engages (10 / 9) ✅; swarm at 55 % ✅; last stand **3 every 2 s** (5 × 3/5, 5 × 3/6) ✅. Not headless-testable (needs a player): the siege trigger itself, no regrowth during it, leaving during siege → lost. → PT9.

## E8. Swarm earlier, more last stand, rename (built 2026-10-18, headless ✅, waiting for PT8)

| # | Part | Build | File(s) |
|---|------|-------|---------|
| E8-1 | Rename (CF-D22) | Phase `"climax"` → `"swarm"`; `climax_*` → `swarm_*` (`swarm_at`, `swarm_total`, `swarm_per_check`, `swarm_left`, `swarm_index`). A running challenge from before E8 is converted on its next check. `/ht-challenges` shows "phase swarm" | `scripts/waves.lua` |
| E8-2 | Earlier (CF-D22) | `swarm_at` 0.5 → **0.6**: the swarm starts after ~60 of the 150 brain bullets (was ~75) | `scripts/waves.lua` |
| E8-3 | Last stand (CF-D22) | `last_stand_group` 10 → **12** (every 4 s) | `scripts/waves.lua` |
| E8-4 | Test | Brain set to **55 %** (between old and new threshold); labels "swarm" | `tools/ht-challenge-test` |

**Headless (2026-10-18, 2.1.21, seeds 12345 + 987654):** brain at 55 % → phase **swarm** starts ✅ (it wouldn't have at 50 %); 12 per 0.5 s, 250 total ✅; guards in front unchanged (18 / 24 at +4 s) ✅; after the swarm is cleared, last-stand groups of **7 / 6** every 4 s (12 × 3/5 and 12 × 3/6 nests alive) ✅. Output: `tools/ht-challenge-test/e8-result.txt`.

## E7. Brain guards (built 2026-10-18, headless ✅, waiting for PT7)

| # | Part | Build | File(s) |
|---|------|-------|---------|
| E7-1 | Guards (CF-D21) | Every **3rd** swarm / last-stand biter (~80 of the 250) runs to a spot **between the brain and you**: 5–10 tiles from the brain, up to ±6 tiles sideways, no distractions. Holds there **10 s** (wanders in a 3-tile radius, attacks you if you come close), then attacks. The other 2/3 keep the wide-detour surround | `scripts/waves.lua` |
| E7-2 | Test | Counts climax units in the line of fire (3–14 tiles from the brain towards the target, ≤ 7 sideways) every second | `tools/ht-challenge-test` |

**Headless (2026-10-18, 2.1.21, static target 35 tiles from the brain):**

| Climax + | 2 s | 4 s | 6 s | 8 s | 10 s | 12 s | 14 s |
|---|---|---|---|---|---|---|---|
| In front of the brain, **E7** seed 12345 | 10 | 18 | 19 | 31 | 21 | 11 | 13 |
| In front of the brain, **E7** seed 987654 | 7 | 24 | 36 | 40 | 32 | 35 | 20 |
| Same, **guards off** (baseline, seed 12345) | 1 | 4 | 4 | 4 | 1 | 0 | 1 |

- About **10× more bodies** in the line of fire for the first ~12 s of the climax. They thin out as the 10 s holds end.
- Surround still forms with the other 2/3 (6–7 of 8 directions at once, was 8). Last stand unchanged (groups every 4 s after the swarm is cleared).
- Knobs: `guard_every` (3), `guard_hold` (10 s), `guard_min/max` (5–10), `guard_spread` (6).

## E6. More pressure (built 2026-10-18, headless ✅, waiting for PT6)

| # | Part | Build | File(s) |
|---|------|-------|---------|
| E6-1 | Wake (CF-D20) | Groups **11–17**, max **70** alive | `scripts/waves.lua` |
| E6-2 | Brain (CF-D20) | `SMALL_HEALTH` 750 → **1125** (150 yellow bullets; the climax still starts at half, ~75 bullets) | `Hostile-fauna/prototypes/brain.lua` |
| E6-3 | Last stand (CF-D20) | Once the 250 are out: every **4 s** a group of **10** × share of living nests, with surround routes, until the brain dies. Paused while 120+ are alive. `/ht-challenges` shows "last stand" | `scripts/waves.lua` |
| E6-4 | Test | Clears the swarm 15 s into the climax, then expects last-stand groups | `tools/ht-challenge-test` |

**Headless (2026-10-18, 2.1.21, seeds 12345 + 987654):** small brain 1125 HP, no fissures ✅; first wake group 17 / 11 ✅; swarm unchanged ✅. With ~280 alive the last stand waits (cap 120) ✅; after the swarm is cleared: groups of **6 / 5 every 4 s** (half the nests destroyed in the test, so 10 × 3/5 and 10 × 3/6) ✅. Output: `tools/ht-challenge-test/e6-result.txt`.

Knobs: `last_stand_group` (10), `last_stand_interval` (4 s), `last_stand_max_alive` (120).

## E5. Wide detour, busier wake (built 2026-10-18, headless ✅, waiting for PT5)

| # | Part | Build | File(s) |
|---|------|-------|---------|
| E5-1 | Wide detour (CF-D19) | Each climax biter keeps its own ring point (angle θ from your back). Route: if θ is within 90° of your back, first your side (±90°) at **35 tiles**, then its angle at 35 tiles, then in to the ring point (12–18), then attack. Straight legs stay ~25 tiles from you. Waypoints fixed at spawn (`detour_radius`) | `scripts/waves.lua` |
| E5-2 | Wake (CF-D19) | Groups **9–15**, max **60** alive | `scripts/waves.lua` |

**Headless (2026-10-18, 2.1.21, seeds 12345 + 987654, test run 25 s past the climax):** first wake groups 15 / 9 ✅; 273–280 spawned ✅; up to 276 slowed in the cloud ✅; 8 of 8 directions held at once ✅. Climax biters per direction, seed 12345 (same setup as E4):

| After climax start | Your back (sectors 7, 0, 1) | Sides (2, 6) | Towards the brain (3, 4, 5) | Within 8 tiles (attacking) |
|---|---|---|---|---|
| +5 s | 0 (E4: 4) | 2 (E4: 7) | 61 (E4: 62) | 16 (E4: 21) |
| +10 s | 6 (E4: 9) | 10 (E4: 20) | 81 (E4: 114) | 23 (E4: 61) |
| +15 s | 11 (E4: 22) | 34 (E4: 28) | 37 (E4: 79) | 49 (E4: 137) |
| +20 s | 21 | 23 | 20 | 131 |
| +25 s | 31 | 15 | 17 | 195 |

- The swarm reaches you **later and from all sides**: at +15 s about a third as many biters are on you as in E4 (49 vs 137), and by +20 s the back, sides and front are about even.
- Seed 987654 shows the same shape (even by +23 s).
- Knob: `detour_radius` (35).

## E4. Tuning after PT3 (built 2026-10-18, headless ✅, waiting for PT4)

| # | Part | Build | File(s) |
|---|------|-------|---------|
| E4-1 | Cloud slow (CF-D16) | `ALLY_SLOW` 0.5 → **0.45**: small biter ~0.10 in the cloud, you 0.15 | `Hostile-fauna/prototypes/brain.lua` |
| E4-2 | Climax size (CF-D16) | `climax_total` 200 → **250**, 12 per check (still ~10 s) | `scripts/waves.lua` |
| E4-3 | Ring surround (CF-D17) | Per climax unit: angle = back of the target ± 135°, stepped by the golden ratio (any run of units spreads evenly), radius 12–18. Replaces the 3 shared points | `scripts/waves.lua` |
| E4-4 | Wake (CF-D18) | `wave_min/max` 7/13, `max_alive` 50 | `scripts/waves.lua` |
| E4-5 | Test | Counts climax units per 45° sector around the target, every second | `tools/ht-challenge-test` |

**Headless (2026-10-18, 2.1.21, seeds 12345 + 987654):** first wake group 13 / 7 ✅; climax 250 spawned ✅; up to 288 biters slowed in the cloud ✅; all **8 of 8** directions held 2+ biters at the same moment on both seeds ✅. Spread over time (seed 12345, sectors 0 = your back … 4 = front, towards the brain … 7; static target 35 tiles from the brain):

| After climax start | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | Within 8 tiles (attacking) |
|---|---|---|---|---|---|---|---|---|---|
| +5 s | 1 | 2 | 7 | 26 | 34 | 2 | 0 | 1 | 21 |
| +10 s | 1 | 6 | 13 | 50 | 51 | 13 | 7 | 2 | 61 |
| +15 s | 6 | 11 | 16 | 42 | 19 | 18 | 12 | 5 | 137 |

- The ring forms, but **the front-side sectors (3–5) carry most of the swarm for the first ~10 s**: slowed biters come from the brain's side and walk around you, so your back closes last.
- If PT4 still feels like "they come from the front": route each biter wide (first a waypoint ~30 tiles out at its side, then its ring point), or let the climax also come out of nests/ground behind you.

## E3. The ash cloud slows the brain's biters too (built 2026-10-18, headless ✅, waiting for PT3)

| # | Part | Build | File(s) |
|---|------|-------|---------|
| E3-1 | Ally sticker | New sticker `hf-ash-sticker-ally`: copy of the ash sticker, no speed cap, speed **×0.5** (`ALLY_SLOW`). Small biter 0.225 → ~0.11, you 0.15 in the cloud: you outrun them by ~2 tiles/s | `Hostile-fauna/prototypes/brain.lua` |
| E3-2 | Second area | Next to every ash-sticker area in the small brain's effects: the same area for its **own force** (`force = "same"`, ground units only) that gives `hf-ash-sticker-ally`. The cloud prototypes belong to the small earth wyrm (the brain copies its head), so the unused small wyrm gets it too | `Hostile-fauna/prototypes/brain.lua` |
| E3-3 | Test | `ht-challenge-test` enrages the brain at the climax and counts slowed biters | `tools/` |

**Headless (2026-10-18, 2.1.21, seeds 12345 + 987654):** first biters slowed 1.5 s after the brain is enraged; up to **233 / 235** small biters slowed at once (climax + the nests' own biters); the target still gets `demolisher-ash-sticker` ✅. Small brain fissures none, medium yes ✅. Flank arrivals unchanged ✅. `check-paths.py`: 2355 paths, 0 missing ✅. Output: `tools/ht-challenge-test/e3-result.txt`.

Knob: `ALLY_SLOW` (0.5). Outside the cloud the biters run 0.225 and you 0.25, unchanged.

## E2. Safe zone, no fissures, surround (built 2026-10-18, headless ✅, waiting for PT2)

| # | Part | Build | File(s) |
|---|------|-------|---------|
| E2-1 | Safe zone (CF-D12) | `hostile_starting_area_radius` 384 → **150**. A point closer than 200 is pushed out to 200 along its direction from spawn (new `hostile_point_raw_*`, `hostile_point_r*`). "Points near spawn join the starting area" removed; every cell has a base (`hostile_base_exists` = not no-enemies mode). Base growth still starts at 420 (`FAR_START`, renamed from `POINT_START`), so bases further out are unchanged | `prototypes/planet/nauvis-territory.lua`, `brain-bases.lua`, `scripts/regrow.lua` |
| E2-2 | No fissures (CF-D13) | `hf-brain-small.revenge_attack_parameters = nil` | `Hostile-fauna/prototypes/brain.lua` |
| E2-3 | Surround (CF-D14) | Each climax batch of 10 picks the next side (left, right, behind; seen from the brain, 15 tiles from you), runs there with no distractions, then attacks. A failed run → plain attack (`storage.flankers`, `on_ai_command_completed`) | `scripts/waves.lua` |
| E2-4 | Tools | `ht-challenge-test` also checks the territory edge per 15°, brain distances, fissures, flank arrivals; `ht-map-check` counts enemies inside 150 | `tools/` |

**Headless (2026-10-18, 2.1.21, 3 seeds)**, full output for seed 12345 in `tools/ht-challenge-test/e2-result.txt`:

| Check | 12345 | 987654 | 555 |
|-------|-------|--------|-----|
| Resources inside 150 tiles | iron, copper, coal, stone ✅ | same ✅ | same ✅ |
| First territory tile, per 15° (min / median / max) | 128 / 148 / 188 ✅ | same | same |
| Nearest brains (tiles from spawn) | 214, 273, 313, 351 | 199, 264, 300, 384 | 200, 241, 302, 374 |
| Small brain fissures / medium | none ✅ / yes | same | same |
| Climax units at a flank point at once (left / right / behind) | 11 / 11 / 12 ✅ | 9 / 10 / 9 ✅ | 10 / 19 / 10 ✅ |
| Map check: 1 base per territory, on its point, no stray, nothing in the safe zone | ✅ (33 territories) | ✅ (32) | — |

The territory edge is per chunk (32 tiles), so it lies at 128–188 instead of exactly 150. Wake groups and the E1 checks unchanged ✅.

## E1. First-ring challenge (built 2026-10-18, headless ✅, waiting for PT1)

The smallest build that lets PT1 test F1, F2, F9, F10 and CF-D2/D3 together. Only ring 0 changes; other rings keep today's waves.

| # | Part | Build | File(s) |
|---|------|-------|---------|
| E1-1 | One-shot (CF-D8) | Pistol + SMG `attack_parameters.damage_modifier = 3` | `Hostile-fauna/data-updates.lua` |
| E1-2 | Brain (CF-D10) | `hf-brain-small`: 750 HP, `healing_per_tick = 0`. Small brains are only used up to ~720 tiles, so that's the first ring. Side effect: the small rally (crusade) copies it, 750 × 0.75 = 562 HP | `Hostile-fauna/prototypes/brain.lua` |
| E1-3 | Phases (CF-D11) | Ring 0 record gets a `phase`: **wake** from challenge start, **climax** once the brain drops below 50 % HP | `scripts/waves.lua` |
| E1-4 | Wake / push | Every 8 s a group of 5–10 small biters, split over the **living nests** of the brain base (CF-D5), sent at a participant. Group size × share of nests still alive (all dead = no more groups); max 40 alive | `scripts/waves.lua` |
| E1-5 | Climax | A swarm of ~200 small biters from the living nests, spread over ~10 s (UPS). No nest left → they come out at the brain | `scripts/waves.lua` |
| E1-6 | Ring 0 cleanup | Ring 0: only small biters, **no** evolution upgrade (keeps the one-shot promise), **no** slow sticker, no spawning around the player | `scripts/waves.lua` |
| E1-7 | Kit | New `/cheat-kit ring0`: SMG + **100** yellow magazines (`smg-yellow` gives 400) | `cheating-mod/control.lua` |
| E1-8 | Check headless | Damage per bullet on a small biter (15) and a spawner (11); brain HP 750, no regen; ring-0 challenge spawns at nest positions; climax fires at < 50 %; starting resources inside 384 tiles | harness |

Not in E1: surrounding (E2), tuning the vanilla defenders that nests send on their own when attacked (note them in PT1).

Also added: debug remote `waves_step(x, y, target)` in `control.lua` (one wave check against any entity, no player needed), test mod `tools/ht-challenge-test/`, commands in [commands.md](../docs/commands.md) "Challenge feel: first-ring test".

**Headless (2026-10-18, 2.1.21, seed 12345, HF + HT + test mod)**, full output in `tools/ht-challenge-test/e1-result.txt`:

| Check | Result |
|-------|--------|
| Gun `damage_modifier` | pistol 3, SMG 3, gun turret 1 ✅ |
| 15 physical on a small biter / spawner | biter dead ✅ / spawner loses 11.05 of 350 ✅ |
| Brains | small 750 HP, regen 0 ✅; medium unchanged (100 000, 130) ✅ |
| Starting resources | inside 384 tiles: iron, copper, coal, stone, a little oil ✅. Uranium only outside |
| Territory next to the safe area | nearest territory chunk 363 tiles from spawn ✅ (CF-D7) |
| Nearest brain | small, 446 tiles from spawn → **ring 0** ✅, 4 nests in its base |
| Wake | first group of 7 after 2 s, all at a nest ✅ |
| Nests die | 2 of 4 destroyed → next groups 3 and 5 (half of 5–10) ✅ |
| Climax | brain set to 40 % → "climax", 10 per 0.5 s, 200 in 10 s, all at nests ✅ |

Not testable headless (no players): the real challenge start, the "The hive swarms!" message, how it feels. → PT1.


## Playtest log

| # | Date / version | Setup (ring, gear, kit) | What happened | Gap found |
|---|----------------|-------------------------|---------------|-----------|
| PT1 | 2026-10-18, 2.1.21 | First ring, `/cheat-kit ring0`, own map | **Lost.** Wake/push phase felt OK. Climax (brain enraged) a bit too strong: the brain still has its shockwave and lava fissures. Wants even more biters if the ammo allows. Brain 100 vs 150 bullets: unsure. Biters clearly come out of the nests ✅; being surrounded is missing. Safe zone too big (screenshot) | P6, P7, P8 |
| PT2 | 2026-10-18, 2.1.21 | First ring, new map (E2), `/cheat-kit ring0` | **Lost on the climax**, again after respawn. **61 magazines left.** Safe zone good ✅. Swarm surrounds ✅ and overwhelms: you can't outrun it, the shockwave slows you but not the biters. Keep the shockwave, tune the challenge's speed around it | P9 |
| PT3 | 2026-10-18, 2.1.21 | First ring, PT2 map + E3, `/cheat-kit ring0` | **Won, 41 magazines left** (590 bullets used). Outrunning the swarm in the cloud works, maybe slightly too easy. Surround feels threatening, but like 3 "jets" of attacks rather than being surrounded. Wake phase: slightly more biters | P9, P10, P11 |
| PT4 | 2026-10-18, 2.1.21 | PT2 map + E4, `/cheat-kit ring0` | **Won, 37 magazines left.** Wake phase can be a bit busier. Outrunnable in the cloud and tense ✅. With focus fire it stays under control, without it very tense. Surround: mostly from the front, but getting there. Wants to try a very wide detour | P10, P11 |
| PT5 | 2026-10-18, 2.1.21 | PT2 map + E5, `/cheat-kit ring0` | **Won, 35 magazines left** after also clearing the remaining bases. Wake: slightly busier again. Swarm feels **very good**, later arrival fine. Good build-up, but after the swarm the brain is easy; the brain can also be killed early, before the swarm is in full effect → 150 bullets | P11, P12 |
| PT6 | 2026-10-18, 2.1.21 | PT2 map + E6, `/cheat-kit ring0` | Brain killed with **50+ magazines** to spare. Wake OK for now (could take more, but it should ramp up from there). Brain still killed early, so the last stand barely got tested. Idea: the swarm walks in front of the brain and blocks direct fire | P12 |
| PT8 | 2026-10-18, 2.1.21 | PT2 map + E8, `/cheat-kit ring0` | **Won, ~20 magazines left.** Guards sort of okay. Last stand on the edge of too much (smaller steps instead of 12 / 4 s). A base piece regrew almost at once while attacking the base: phase 0 = attacking the base, phase 1 = the brain, phase 2 = swarm; no regrowth during a challenge. "Getting close to done" | P12, P13 |
| PT9b | 2026-10-18, 2.1.21 | Second nest, re-equipped | Killed more nests first, then the brain: **won, 35 magazines left** | — |
| PT9 | 2026-10-18, 2.1.21 | PT2 map + E9, `/cheat-kit ring0`, game restarted | All notifications appear ✅ (siege, brain wakes, swarm). With the brain almost dead got a bit overwhelmed, couldn't kill the biters fast enough, had to run away (not sure what caused it). "Very close to a right balance, might even be okay" | P12 |
| PT7 | 2026-10-18, 2.1.21 | PT2 map + E7, `/cheat-kit ring0` | **Won, ~31 magazines left; 23 after clearing the remaining bases.** Guards could arrive slightly earlier → start the swarm earlier. Last-stand pressure could be slightly more, overall pretty good. Rename "climax" | P12 |

## Steps

- [x] 1. Feel target written (2026-10-18).
- [x] 2. Q1–Q4 answered, ring-1 decisions CF-D1–D6 (2026-10-18).
- [x] 3. Q5–Q9 answered, E1 settled (2026-10-18).
- [x] 4. E1-1 … E1-7 built, headless check E1-8 passed (2026-10-18).
- [x] 5. **PT1 (user, in game, 2026-10-18):** lost; see Playtest log. Asked for: fresh map, `/cheat-kit ring0`, go to the nearest brain (commands in [commands.md](../docs/commands.md) "Challenge feel: first-ring test"). Record:
  - won or lost; magazines left; rough time per phase; deaths
  - how each phase felt (approach, wake/push, climax)
  - did the nests' own vanilla defenders matter?
  - brain: 100 bullets right, or should it be 150?
  - spawning from nests: does it read as "the hive sends them"? Is surrounding (E2) the next thing missing?
- [x] 6. Q11–Q14 answered (CF-D12–D14), E2 settled (2026-10-18).
- [x] 7. E2 built, headless ✅ on 3 seeds (2026-10-18).
- [x] 8. **PT2 (user, in game):** **new map** (map gen changed), `/cheat-kit ring0`, nearest brain. Record:
  - does the safe zone match your green circle, with a fight right outside it?
  - won or lost, magazines left
  - climax without fissures: too strong, right, or too easy? Room for more biters?
  - does the swarm feel like it surrounds you?
  - the brain's shockwave: OK to keep?
  - **Done 2026-10-18:** see Playtest log PT2.
- [x] 9. E3 (biters slowed in the ash cloud) built, headless ✅ (2026-10-18).
- [x] 10. **PT3 (user, in game, 2026-10-18):** won, see Playtest log. same setup (existing E2 map is fine, prototype change only). Record:
  - won or lost, magazines left
  - in the cloud: can you outrun the swarm now? Too easy, right, too slow?
  - does surrounding still feel threatening?
  - if it's fine: more biters (P8, ammo allows it)?
- [x] 11. Q15–Q17 answered (CF-D16–D18), E4 built, headless ✅ (2026-10-18).
- [x] 12. **PT4 (user, in game):** the PT2 map is fine (prototype + script changes only), `/cheat-kit ring0`. Record:
  - won or lost, magazines left
  - wake phase: busy enough now?
  - climax in the cloud: outrunnable but tense?
  - does it feel like being surrounded now, or still mostly from the front?
  - **Done 2026-10-18:** won, see Playtest log PT4.
- [x] 13. E5 (wide detour, busier wake) built, headless ✅ (2026-10-18).
- [x] 14. **PT5 (user, in game):** PT2 map is fine, `/cheat-kit ring0`. Record:
  - won or lost, magazines left
  - wake phase busy enough?
  - surround: from all sides now? Does the detour even out "focus fire vs no focus fire"?
  - the swarm arrives later (~15–20 s after the climax starts): too slow, or good build-up?
  - **Done 2026-10-18:** won, see Playtest log PT5.
- [x] 15. E6 (busier wake, brain 150, last stand) built, headless ✅ (2026-10-18).
- [x] 16. **PT6 (user, in game, 2026-10-18):** see Playtest log. PT2 map is fine, `/cheat-kit ring0`. Record:
  - won or lost, magazines left (does 1 stack still fit with the 150-bullet brain?)
  - wake phase busy enough?
  - brain: can you still kill it early? Does it last into the swarm now?
  - last stand: does the pressure hold until the brain dies? Too much, right, too little?
- [x] 17. Q18 answered (CF-D21), E7 built, headless ✅ (2026-10-18).
- [x] 18. **PT7 (user, in game):** PT2 map is fine, `/cheat-kit ring0`. Record:
  - can you still burst the brain before the swarm arrives, or do the guards soak your fire?
  - does the last stand now get a chance: does the pressure hold until the brain dies?
  - won or lost, magazines left
  - **Done 2026-10-18:** won, see Playtest log PT7.
- [x] 19. E8 (swarm at 60 %, last stand 12, rename) built, headless ✅ (2026-10-18).
- [x] 20. **PT8 (user, in game, 2026-10-18):** won, see Playtest log PT8.
- [x] 21. Q19–Q21 answered (CF-D23), E9 built, headless ✅ (2026-10-18).
- [x] 22. **PT9 (user, in game, 2026-10-18):** see Playtest log.
- [x] 23. **First ring done for now** (user, 2026-10-18). Next problems here: P2 (arsenal), rings beyond the first. restart the game (script change), PT2 map is fine, `/cheat-kit ring0`. Record:
  - shooting a nest first: does "Challenge started" appear, and does the base stay down (no regrowth) until the end?
  - siege groups: right amount while you clear the base?
  - brain wakes ("The brain wakes!") when you go for it?
  - last stand 5 / 2 s: better than 12 / 4 s?
  - walk away during siege: "Challenge lost" after ~5 s?
  - won or lost, magazines left; anything left before the first ring is done?

## Possible answers (pool)

| Answer | From | May help |
|--------|------|----------|
| Groups go to the player's sides before attacking (surround) | this plan | F10, E2 |
| Arena (slow inside), arena edge = lose line | vision AR | F6 |
| Niche units: brute/shield (thorns), splitter, disabler, bomber, artillery | enemy-balancing EB4 | Phase roles, P2 |
| Counter-artillery | counter-artillery-plan | F3 |

## Open questions

- **Q23. P14: what counts as "first ring"?** First confirm with `/ht-challenges` in a weak challenge. Options: (a) **ring 0 = every territory that touches the safe zone** (computed once per territory, e.g. any of its chunks within SAFE + margin of spawn), used by waves, siege and the oil rule; (b) keep the grid rings but move ring-1 points out so they can't reach the safe zone; (c) leave it, and give ring 1 the ring-0 phases too.
- ~~**Q15.**~~ Answered → CF-D16. ~~Cloud slow (P9): `ALLY_SLOW` 0.5 → **0.6**? Biters 0.135 vs you 0.15 in the cloud: you still outrun them, but only by ~1 tile/s (now ~2.3).~~
- ~~**Q16.**~~ Answered → CF-D17. ~~Surround (P10): instead of 3 shared points, **every climax biter gets its own point on a ring around you** (12–18 tiles, angles spread over your sides and back), so they close in as a ring. Or more directions (e.g. 6) as a smaller step?~~
- ~~**Q17.**~~ Answered → CF-D18. ~~Wake (P11): groups of 5–10 → **7–13** every 8 s (~+35 %), max alive 40 → 50?~~
- ~~**Q18. Protect the brain (P12).**~~ Answered → CF-D21 (more biters in front, no damage tricks). Fact: yellow ammo is a `direct` + `instant` hit on the target (`item.lua:4051`), and Factorio has no line of sight for guns, so units can't physically block bullets. Script can: `on_segmented_unit_damaged` gives every hit on the brain, and its `health` is writable (refund part of a hit). Options:
  - **A. Guard wall** (recommended, closest to the idea): ~40 of the swarm run to the brain's side facing you (4–8 tiles from it) and stay. Each guard within 10 tiles of the brain blocks ~4 % of each hit (max 90 %). Kill the wall to expose the brain. Also fits the "shield units guard the brain" idea (roadmap fog).
  - B. Shield until the swarm arrives: from the climax start the brain takes ~10 % damage until N swarm biters are dead (or 20 s). Simpler, less physical.
  - C. Climax earlier (at 75 % instead of 50 %). Simplest, no blocking feel.
- ~~**Q22. First ring done?**~~ **(a) Done for now** (user, 2026-10-18). Last-stand cap left at 120 (knob if the end pile-up comes back). PT9: "very close, might even be okay". Options: (a) call the first ring **done for now** (keep the knobs; revisit after other work); (b) one more small tweak first: last-stand cap 120 → ~60 alive (likely cause of the pile-up near the end), then PT10.
- ~~**Q19–Q21** (2026-10-18): last-stand rhythm, what siege does, leaving during siege~~ Answered → CF-D23 (5 every 2 s; small groups; counts as lost).
- Q3 (far-ring length): later.
- **Q11. Safe zone (P6):** option A (radius ~150, push near points out to ~200)? Is ~150 right for your green circle, and is a brain ~200 tiles from spawn OK?
- **Q12. Fissures (P7):** remove only from the small brain (first ring), medium and big keep them for now?
- **Q13. What killed you in PT1:** fissures, the swarm, or the brain's shockwave/body? And roughly how many magazines did you have left (decides how many more biters fit)?
- **Q14. Surround (E2):** first try: the climax swarm splits into 3 groups that first run to points ~15 tiles left, right and behind you (seen from the brain), then attack. Also for wake groups, or only the climax?
- Q10. Wake/push group size and interval (E1-4) and climax size (~200, E1-5) are first guesses: tune in PT1.
