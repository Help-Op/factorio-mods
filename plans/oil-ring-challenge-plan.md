# Oil Ring Challenge

> **Status:** Ring 1 done for now (PT23 won, OR-D112, 2026-10-24) · **Parent:** [challenge-feel-plan.md](challenge-feel-plan.md), [ring-layout-plan.md](ring-layout-plan.md) · **Next:** parked until the tutorial pass (step 46): revisit rings 0–1 once every ring has its kit · [Roadmap](roadmap.md)

Started 2026-10-20 (game 2.1.21). The challenge for **ring 1 in the code**: the 12 territories right behind the first ring, where oil starts (RL-D2). This plan says "oil ring" to avoid the ring 0 / ring 1 naming mix-up (CF-D7).

## Goal

- The oil ring is fought with the **weapons you have right before oil**.
- **Way more enemies** than the first ring, without becoming overwhelming.
- The arsenal pays off (challenge-feel P2, F3): the SMG alone is a struggle; area weapons, turrets and the car make it feel powerful (weapon checkpoints, enemy-balancing D19).

## Decisions (user)

| # | Topic | Decision |
|---|-------|----------|
| OR-D1 | Scope | "Ring 1" = the **oil ring** (code ring 1, RL-D4) |
| OR-D2 | Tools | **All pre-oil tools are valid answers**: SMG, shotgun, grenades, turrets + walls, car, … None is the single "right" one |
| OR-D3 | Overwhelm | Try a **pressure director** (below) to keep "many enemies" from turning into "overwhelmed" (2026-10-20) |
| OR-D4 | Brain (Q5) | **One brain per ring**, so it scales with the rest of the challenge. Ring 1 gets a new brain, ~2× the small one (~2250 HP), no regen (2026-10-23) |
| OR-D5 | Scale (Q2) | Swarm ×3 (250 → 750), wake and last stand ×2 (2026-10-23) |
| OR-D6 | Enemy mix (Q3) | New enemies come to this ring later. **PT1: small biters only**, so few parameters change at once (2026-10-23) |
| OR-D7 | Siege | Same as ring 0: attacking the base starts the challenge. Probably true for every ring (2026-10-23) |
| OR-D8 | Budget (Q1) | Start with **1 stack of red ammo + 1 stack of shotgun shells + 20 grenades** (2026-10-23) |
| OR-D9 | Research | The kit assumes **level 2** of physical projectile damage, weapon shooting speed and stronger explosives (2026-10-23) |
| OR-D10 | Gun buffs (Q4, Q7) | Shotgun gets `damage_modifier = 3`. Turrets and the car gun stay vanilla for PT1 (2026-10-23) |
| OR-D11 | Director timing | **PT1 without the director** as a baseline; build it after PT1 only if you get overwhelmed. Thresholds come from PT1 (2026-10-23) |
| OR-D13 | Escape (Q9) | Start with **X3 melee slots (as the pressure director), X6 shotgun, X2 repulse capsule** (2026-10-23) |
| OR-D14 | Damage budget | The director keeps the damage you take from the swarm at **max 1 % of your health per second = 2.5 HP/s**. What matters is damage per second and the feeling of still being surrounded, not a fixed number of attackers (2026-10-23) |
| OR-D15 | Repulse capsule (Q10) | **Kit only** for PT2: test whether it's wanted at all. Recipe and unlock later (2026-10-23) |
| OR-D16 | Shotgun (Q11) | **Faster reload only**: 40 → 20 ticks (2026-10-23) |
| OR-D17 | Budget (Q12, changes OR-D14) | Rolling **3 s** window. Balance around **~30 s of being attacked non-stop** before you die: budget = max health / 30 per second = **8.3 HP/s** (3.3 %/s), about 7 small biters biting in heavy armor. OR-D14's 1 %/s (100 s) felt too long (2026-10-23) |
| OR-D18 | Telemetry (Q13) | Yes: CSV per challenge to `script-output` from the mod (2026-10-23) |
| OR-D19 | Brain time-to-kill (Q14) | Ring-1 brain **5000 HP** (was 2250), swarm at **80 %** (was 60 %) (2026-10-23) |
| OR-D20 | Director slots (Q15) | Slots count units **within ~6 tiles**; slots **grow while you take < 60 % of the budget, shrink when over**, never below budget ÷ damage per biter (2026-10-23) |
| OR-D21 | Shotgun (Q16) | Reload **back to 40**, damage **×2** (was ×3) (2026-10-23) |
| OR-D22 | Slower challenge biters (Q17) | **−20 %** for every unit the phases spawn (ring 0 and 1, `ht-challenge-slow-20`), not all small biters. Ring 0 may need rebalancing after (2026-10-23) |
| OR-D23 | Anti-kite (Q18) | All three: **re-surround** chasers onto your sides / ahead, **holding ring follows you**, **rebuild** (release 20 when nothing is near) (2026-10-23) |
| OR-D24 | Repulse capsule (Q19) | Push **6** tiles, **stun 3 s** (2026-10-23) |
| OR-D25 | Telemetry (Q20) | Count the cursor stack (2026-10-23) |
| OR-D26 | Brain shockwave | User likes the outer edge, the effects inside the ring are distracting: **remove the lingering ash clouds inside**, keep the edge and the slow (rings 0–1 brains) (2026-10-23) |
| OR-D27 | Ash cloud speed (Q21) | Keep the slowdown (it's there to give you time to shoot), but **keep the biter : player speed ratio** in the cloud and **slow the player too**: the player gets the same ×0.45 as the biters instead of the 0.15 cap → 0.1125 vs biter 0.081 (72 %, as outside: 0.18 vs 0.25) (2026-10-23) |
| OR-D28 | Surges (Q22) | Ring 1's brain fight in **three surges**: 80 % swarm from the nests (350), 55 % **encircle** (250), 30 % **frenzy** (150 + the last stand doubled, extra shockwave pulses) (2026-10-23). Assumption from Q23: nothing appears out of the ground, so the encircle units come out of the nests and walk to a ring around you |
| OR-D29 | Intercept anti-kite (Q23) | Replaces re-surround: while you circle the brain, a group **walks to where you'll be** ~4 s ahead (no spawning in front of you). Keep the following holding ring and the rebuild (2026-10-23) |
| OR-D30 | Never run dry (Q24) | Ring 1's last stand keeps coming until the brain dies, out of the brain once the nests are dead; telemetry gets nests alive and swarm left (2026-10-23) |
| OR-D31 | Shockwave (Q25) | Half the edge puffs (12 → 6), no idle ash trail around the brain (2026-10-23) |
| OR-D32 | Repulse capsule (Q26) | **Deleted** (2026-10-23) |
| OR-D33 | Brain-fight shape (PT5) | **Each surge asks for a different verb**, as in top-down boss fights (Hades, Enter the Gungeon, Isaac: new move per phase, add phase ↔ boss phase, tempo change at the end): surge 1 **Hold**, surge 2 **Break out**, surge 3 **Burst race**. The brain gains **one new reaction per surge** (2026-10-23) |
| OR-D34 | Openings (A1) | The ring-1 brain is **shielded (takes 10 %)** while a surge is out and **opens for ~8 s once the surge is broken** (~70 % of its units dead). Shown by a tint / glow on the brain + a message. Frenzy: always open (2026-10-23) |
| OR-D35 | Shorter (A4) | **Through the openings only**: brain keeps 5000 HP; burst windows make the total shorter. Tune after PT6 (2026-10-23) |
| OR-D36 | Strategic movement (C0 + C1) | **Re-plan** routes around where you are now (PT5: waypoints fixed at spawn made units walk to stale spots), and **squads with roles**: pin, flank, cut-off, reserve / guard. A squad **gathers, pauses ~1.5 s (the tell), then charges together**, from 2–3 sides at once (2026-10-23) |
| OR-D37 | Brain reactions (A3) | **Guard rush** (from surge 1: shoot the brain → the reserve charges you), **stand-still punish** (from surge 2: standing still > 2 s → squads close in), **terrain**: the brain raises rocks in your path (user idea), but it must **never lock you in** (2026-10-23) |
| OR-D38 | Break out (surge 2) | The encircle units hold on a full ring at **16 tiles**, then **step in 2 tiles every 3 s**: punch a hole and get out (2026-10-23) |
| OR-D39 | Aura (PT5) | Constant area effect (psychic aura / moss) instead of the pinging shockwave: later, needs art → roadmap fog (2026-10-23) |
| OR-D40 | Numbers (PT5) | Damage budget, brain HP, unit counts **stay**: the feel is what's off (2026-10-23) |
| OR-D41 | Rocks (Q27) | From **surge 3**; the E6-7 safety rules as drafted (2026-10-23) |
| OR-D42 | Re-plan (Q28) | **Ring 1 only** for now (2026-10-23) |
| OR-D43 | Lull (Q29) | Not in OR-E6: see first whether the openings give enough rhythm (2026-10-23) |
| OR-D44 | Anchor nests (Q30) | **No nests that appear during the fight**: nests should take time to build. Instead (user idea): an **outer ring of anchor nests** around ring-1+ brains in general (map gen), and **queen / spawner units** that hold strategic spots where biters come from. Nests make queens and biters; queens make only biters. Details: OR-D45, OR-E8 (2026-10-23) |
| OR-D45 | Queens + anchor ring | **Anchor ring shields the brain**: while outer nests live, the brain's shield is stronger / openings shorter. **Queens:** slow, tanky, a priority target, **escorted** by their own squad. Spots: your flanks / behind you, your side of the brain, or **on screen but as far from you as possible**. Built **after PT6 as OR-E8**, so OR-E6 is tested on its own (2026-10-23) |
| OR-D46 | Kit (after OR-E6) | `/cheat-kit ring1` gets **2 stacks of red ammo** (200, was 100; OR-D8). Shells and grenades unchanged (2026-10-23) |
| OR-D47 | Unlock (PT6) | **Shield bearers** replace "kill 70 % of the surge": **3 per surge** (surges 1 and 2), a new **tanky unit based on the big biter** (~375 HP, slow, own tint), standing **6–10 tiles from the brain**, each with a **line to the brain**. You push in to kill them (2026-10-23) |
| OR-D48 | Open time (PT6) | Bearers dead → the brain is **open until the next surge**. No timer, no re-opening rule (2026-10-23) |
| OR-D49 | Regroup (PT6, user idea) | Kiting means the brain **lost its grip** on you. Then: **pull back > 90 %** of the biters to the brain base, **expose the brain as a lure**, then **surround you again** the way the swarm does at the start. Trigger: you move > 3 tiles/s for 5 s while nothing reaches you (< 3 biters within 6 tiles). The swarm comes back when you get within 25 tiles of the brain or hit it, or after 20 s anyway (2026-10-23) |
| OR-D50 | Rocks (PT6) | **From surge 1** (not just the frenzy), and they **stay for good** (also after the challenge). **Vanilla loot** (stone + coal) is fine (2026-10-23) |
| OR-D51 | Arena (PT6) | At **surge 2** a **broken ring of rock walls 22 tiles** around where you stand (outside the closing ring at 16), **4 gaps of ~4 tiles**: breaking out through a gap = a shotgun chokepoint (2026-10-23) |
| OR-D52 | Kiting (PT6) | No extra cut-off squads, no speed change: bearers, regroup and rocks first (2026-10-23) |
| OR-D53 | Lure (PT7) | The hive stays pulled back **at least 6 s** (brain open: free shots, the bait), then re-swarms when you come **within 15 tiles** of the brain, or after 20 s. Hitting the brain no longer ends it (2026-10-23) |
| OR-D54 | Rocks (PT7) | **Wall rocks off for now** (one parameter too many); **the arena stays** (2026-10-23) |
| OR-D55 | Shockwave in the siege (PT7) | The **first nest destroyed in the siege wakes the brain**: wake phase, the brain is enraged, so its shockwave starts. Ring 1 only for now (ring 0 is "done for now"; one flag, `wake_on_nest`) (2026-10-23) |
| OR-D56 | Pull back (PT8, changes OR-D49) | **100 %** of the biters pull back (was 90 %); the bearers stay at their spots (2026-10-23) |
| OR-D57 | Arena (PT8, changes OR-D51) | Radius **22 → 28** tiles (2026-10-23) |
| OR-D58 | Trap (PT9, changes OR-D49) | Pull back **not to the brain** but into **~8 groups ~30 tiles around you**, following you; the directions **towards the brain and your heading stay open** (the road to the bait). New last-stand units **join the groups**. Bait taken (or 20 s) → **all groups charge at once**, each from its own side (2026-10-23) |
| OR-D59 | Death log (PT8, PT9) | Telemetry logs the **biggest hit per second and what dealt it**, and the death line lists the biggest hits of the last 3 s (2026-10-23) |
| OR-D60 | Bearers (PT9) | They **hit hard up close** (big biter bites); not necessarily bad, keep for now (2026-10-23) |
| OR-D61 | Chokepoints (PT10) | The brain **recognises a chokepoint** you hold (kill zone + stalemate) and reacts: **stops feeding** biters into it (squads wait out of your range) and **goes the long way round** (squads walk around the cliff / water to your other sides) (2026-10-23) |
| OR-D62 | Ranged pressure (PT10) | **Not now**: small biters only; ranged units come with EB4 (2026-10-23) |
| OR-D63 | Messages (PT10) | Keep the player messages ("The hive …") **for testing**; before shipping, **remove all messages** (OR-I12) (2026-10-23) |
| OR-D64 | Lure hold (PT10.2, changes OR-D53) | The lure worked; hold it **longer** to make it more enticing: at least **10 s** (was 6) before going for the bait springs it, time out **25 s** (was 20). The 15-tile trigger stays (2026-10-23) |
| OR-D65 | Frenzy (PT10.2) | **No lure in the frenzy**: the brain is open anyway, so a pull-back there only gave free shots. A trap still running when the frenzy starts springs at once (2026-10-23) |
| OR-D66 | Anchor ring (Q33) | **4 anchor nests at 32 tiles** around ring-1+ brains (map gen, 45° off the inner ring). 32 + nest size stays inside the 38-tile cell margin (2026-10-24) |
| OR-D67 | Shield link (Q33) | Living anchors make **openings weaker**: open brain takes 100 % × (1 − 0.5 × share of anchors alive). A line from each anchor to the brain. Shut stays 90 % (2026-10-24) |
| OR-D68 | Siege rules | A hit on an anchor **starts the siege**, killing one **doesn't wake** the brain: clearing the outer ring is a deliberate prep step during the siege (2026-10-24) |
| OR-D69 | Anchor spawns | Anchors **don't spawn** waves or surges (shield only, one change per PT); they make queens in E8-B (2026-10-24) |
| OR-D70 | Queens (Q31) | **2 alive · 500 HP · speed 0.1 · 3 biters per 4 s**; their biters count against the surge totals (OR-D40 numbers stay) (2026-10-24) |
| OR-D71 | Queen surges (Q32) | **Surges 1 and 2**, queens walk out of **living anchors**; none in the frenzy; anchors dead = no queens (2026-10-24) |
| OR-D72 | Queen art (Q34) | Placeholder `ht-queen`: **behemoth-biter body, purple tint** (the bearer is the blue big biter) (2026-10-24) |
| OR-D73 | OR-E8 order | Two parts, a PT after each: **E8-A anchor ring + shield link → PT12**, then **E8-B queens + escort → PT13** (retro, 2026-10-24) |
| OR-D74 | One shield mechanic (PT12) | Anchors and bearers are **one mechanic**: each anchor is a **shield link** (blue dashed line to the brain). Killing an anchor **releases a bearer** out of it that **walks in** to a spot 6–10 tiles from the brain on its side and holds there; the line now runs from the bearer. A link is broken when its bearer dies too. Replaces "3 bearers out of the brain per surge" (OR-D47) (2026-10-24) |
| OR-D75 | Links = phase 1 (PT12) | The brain is **shut from the start of the fight** (siege incl.) while **any link lives**; all 4 broken → **open for good**. The fight reads: break the links → swarm (80 %) → encircle (55 %) → frenzy (30 %). Surges no longer bring bearers (2026-10-24) |
| OR-D76 | 50 % rule (PT12) | **Dropped** (OR-D67): anchors act through their bearers only (2026-10-24) |
| OR-D77 | Feel (PT12) | Recreate **boss phases** from other games while everything feels **natural**: enemies come from the base, nothing appears out of nowhere (2026-10-24) |
| OR-D78 | Queen source (Q35, PT12.2) | **Any nest death** (inner or anchor, **siege too**) makes the living nests release queens: up to **2 alive** (OR-D70), **one every 20 s** while fewer live. **No nests left → no queens.** Replaces OR-D71 (2026-10-24) |
| OR-D79 | Queen phases (PT12.2) | Queens from the **siege / wake on** through every surge and the frenzy, as long as nests live (2026-10-24) |
| OR-D80 | Queen biters (PT12.2) | OR-D70's numbers (2 · 500 HP · 0.1 · 3 per 4 s), but their biters come **on top of** the surge totals: more biters, the director caps the damage. Changes OR-D70's "count against the totals" (2026-10-24) |
| OR-D81 | Order (PT12.2) | **E8-B queens next** (PT13); "the director keeps up the pressure in siege / wake" is its **own step after PT13** (Q36) (2026-10-24) |
| OR-D82 | Queen distance (PT13) | Queens hold **40–50 tiles** from you (was 20–28: too easy to pick off), on your flanks (2026-10-24) |
| OR-D83 | Queen retreat (PT13) | You within **25 tiles** of a queen → she **retreats** to 40–50 tiles from you, while her **escort stays and attacks you** (2026-10-24) |
| OR-D84 | Director from the wake (Q36, PT13.2) | The director runs from the **wake** on (siege stays quiet prep). The wake **no longer starves**: once the nests are dead its groups come out of the brain, as the last stand does (OR-D30) (2026-10-24) |
| OR-D85 | Continuous stream (Q36, PT13.2) | While **calm**, no form → ready → tell rhythm: squads **trickle in non-stop** from 2–3 sides. Over the budget → back to the rhythm (2026-10-24) |
| OR-D86 | Calm (Q36) | Units dealt you **< 30 % of the budget** (2.5 HP/s) over the **last 5 s** (2026-10-24) |
| OR-D87 | Where the stream should come from (later) | User's plan: the stream comes **from the queens**, with **more queens further away**. Too much for this PT; after PT14 (Q37) (2026-10-24) |
| OR-D88 | More queens, further (Q37, PT14) | **4 queens** at once, holding **50–70 tiles** from you (was 2 at 40–50); they still retreat when you come within 25 (2026-10-24) |
| OR-D89 | The director ramps the queens (Q37, PT14) | Base **3 biters per 4 s** per queen. While you're **calm** (OR-D86), every **5 s** of calm adds **+1 biter per spawn**, up to **12 per 4 s**; over the budget → back to the base. Queen biters run **straight at you**. The squad stream (OR-E10, E10-4) goes **off**; squads keep the tell / charge rhythm (2026-10-24) |
| OR-D90 | Queens without nests (Q37) | **As now**: no nests → no new queens; the ones alive keep streaming until you kill them (2026-10-24) |
| OR-D91 | Queens all around (PT15) | Queen spots spread over the **full circle** around you (4 queens ~90° apart), not only your flanks (2026-10-24) |
| OR-D92 | Spawn while walking (PT15) | A queen spawns at her rate **whether she holds or walks** (2026-10-24) |
| OR-D93 | Re-spot less (PT15) | A new spot only when you're **out of her band (40–80 tiles)**, not each time you move 20 tiles (2026-10-24) |
| OR-D94 | Trap closes the circle (PT15) | During the lure hold the trap packs **spread into an even ring** around you (no huddles; only the road to the brain stays open) and the ring **tightens from 30 to ~20 tiles**; take the bait → it springs from all sides (2026-10-24) |
| OR-D95 | Order (PT15) | **OR-E12 queens first → PT16**, then **OR-E13 trap → PT17** (2026-10-24) |
| OR-D96 | Trap far side (Q39) | New biters during the lure hold (queens, last stand) join the **emptiest** pack of the ring, not the nearest: the hive closes the ring from outside (2026-10-24) |
| OR-D97–D111 | Balance pass (PT17–PT22) | ~150 s, spikes on purpose, 4 queens at the wake start + cap 800, trap ring to 12 tiles / hold 8 s / follows you, frenzy 250 / ×3, brain 4000 HP; one set per PT; PT18: no worms in rings 0–1, no head crush; PT19: a surge waits for the trap: see **Balance pass** (2026-10-24) |
| OR-D12 | Armor (Q8) | **Heavy armor** in the ring-1 kit: it's pre-oil, so balance around it. PT1 shows whether lots of small biters still work with it or whether other enemies are needed (2026-10-23) |

## Confirmed facts (code, 2026-10-20)

| Fact | Value | Source |
|------|-------|--------|
| Oil-ring challenge today | Old waves: tiny/small biters **spawned around you** (40–50 tiles), 5 every 8 s, max 25 alive, slow sticker (40). No siege / wake / swarm / last stand | `scripts/waves.lua` `RINGS[1]`, `SPAWN_MIN/MAX` |
| First-ring reference | Siege 4–7 / 10 s, wake 11–17 / 8 s (max 70), swarm 250 in ~10 s, last stand 5 / 2 s (max 120). Won with ~35 of 100 magazines left (PT9b) | `scripts/waves.lua` `RING0`, challenge-feel |
| Brain size | By **distance**, not ring: small (1125 HP, no regen) up to 720 tiles, then medium (100 000 HP, 130 HP/tick regen) stepping every 576 tiles. Same resistances for all: 50 % physical, 60 % explosion, 100 % fire / impact | `nauvis-territory.lua:103` (`hostile_territory_variation`), `Hostile-fauna/prototypes/brain.lua` |
| Oil-ring brains (headless, 5 seeds, 2026-10-23) | 7–10 of the 12 ring-1 territories have a brain (the rest are water). **5–6 small, 2–4 medium (unbeatable)** per seed. Brains at 444–973 tiles. Seed 77 has a medium at 630 tiles, so size isn't strictly by brain distance (the game evaluates the variation at another spot than where the brain ends up) | `tools/ht-oil-ring-test` |
| Player gun buff | Pistol + SMG `damage_modifier = 3` (CF-D8). **Not buffed:** shotgun, gun turret, car gun (`vehicle-machine-gun`) | `Hostile-fauna/data-updates.lua`, dump |
| Enemies | Small biter 15 HP, speed 0.225, 7 dmg. Medium 75 HP, 4 flat / 10 % physical, 10 % explosion, speed 0.2, 15 dmg. Tiny 6 HP. Small spitter 10 HP. Player 0.25, 250 HP | `--dump-data` |
| Cheat kits | `ring0` (SMG + 100 yellow), `smg-red` (400 red), `shotgun` (200 shells) exist | `cheating-mod/control.lua:116` |

### Pre-oil arsenal (verified 2026-10-23, game 2.1.21)

Source: `--dump-data` with our mods (final prototypes). "Pre-oil" = techs whose prerequisites never reach `oil-processing` and that use no chemical or later pack. Runtime numbers from `tools/ht-oil-ring-test` (headless, seed 12345). Numbers without tech upgrades.

| Tool | Tech | Numbers | Role in a horde fight |
|------|------|---------|-----------------------|
| SMG + piercing ammo | military (SMG), military 2 (piercing: steel + logistic pack) | 10 shots/s, 8 × 3 = 24 dmg: **1 shot per small**, 5 per medium (18 after resist) | Single target |
| Shotgun + shells | military | 1 shot per 40 ticks (**1.5/s**), **10 shots per shell item**, 12 pellets × **8** dmg, range 15. **2 pellets per small**, 21 per medium (3.6 after resist) | Cone. Headless: **2–5 kills per shot** into 20 packed small biters (mostly 4) |
| Grenades | military 2 | **35 explosion in radius 6.5**, one throw per 30 ticks, range 15. Recipe 5 iron + 10 coal | Headless: **every small in a radius-5 pack dies**, mediums drop to 44 / 75 HP (3 grenades per medium) |
| Gun turrets + walls | gun-turret, stone-wall (red pack only) | Turret 400 HP, 10 shots/s, **8 dmg (no ×3)**, range 18. Wall 350 HP. Gate needs military 2 | Turret line, but each bullet does a third of the player's SMG |
| Car | automobilism (logistics 2 + engine) | 450 HP, top speed **0.43 tiles/tick (93 km/h)** after ~20 s, gun 15 shots/s × 8 dmg (no ×3). Headless at top speed: 10 tiny in a line all die (−18 HP); **10 small in a line all die** (−22 HP, slows to 0.17); **20 packed small: 8 die** (−78 HP, slows to 0.24); **10 medium: 2 die, car stops** (−175 HP) | Outruns everything (small 0.225). Runs over fodder, not mediums or dense packs |
| Heavy armor | heavy-armor (military + steel, red pack only) | Physical 6 flat / 30 %: a small biter's 7 dmg becomes 0.7 (light armor: 3.2). No equipment grid | Small biters barely hurt you |
| **Defender capsules** | defender (**military science pack**, itself pre-oil: piercing ammo + grenade + walls) | Recipe 3 piercing mags + 3 circuits + 3 gears. Robot 60 HP, 8 dmg every 20 ticks, lives 45 s, max 4 (follower count 1–2 add 5 + 10 → 19, also pre-oil) | Extra guns that follow you |
| Upgrades | physical-projectile-damage 1–4, weapon-shooting-speed 1–4, stronger-explosives 1–2 (3+ need the chemical pack) | Bullets and shells +60 % damage and +80 % fire rate at level 4; grenades +45 % | |
| ❌ Needs oil | | Flamethrower (flammables → oil processing), land mines, rockets, cluster grenades (explosives → sulfur), poison / slowdown capsules and piercing shells (military 3, chemical pack), combat shotgun (military 4), modular armor (advanced circuit) | |

## Issues

| # | Issue | Note |
|---|-------|------|
| OR-I1 | Oil ring still runs the old "spawn around you" waves | Breaks F10 (enemies come from the nest). Needs the ring-0 phases as a base |
| OR-I2 | Medium brains in the oil ring are unbeatable | Answer: OR-D4 (brain per ring), built in OR-E1 |
| OR-I3 | ~~UPS with many hundreds of biters alive~~ | Measured: 2.7 ms per tick with ~1360 enemy units (OR-E1 results). Check in game during PT1 |
| OR-I5 | **Trapped in the swarm** (PT1) | The swarm surrounds you so tightly that you can't move: biters body-block the character. SMG can't kill them fast enough, the shotgun is too slow between shots. The user likes many small biters and being surrounded, but there's no good way out. Options: Q9 |
| OR-I6 | Held units must ignore enemies | With `distraction.by_damage` on the wait, held units next to you kept biting; a held unit whose walk fails (stuck in the crowd) falls back to attacking unless it gets a stop command. Both fixed (headless, 2026-10-23) |
| OR-I7 | Held units ignore you completely | You can walk into the holding ring without them reacting, and they body-block. Fine for PT2? |
| OR-I8 | Wake isn't directed | Headless (target never shoots back) the wake reached 10–16 HP/s. In play you kill the wake groups; check in PT2 telemetry |
| OR-I9 | Telemetry misses the cursor | Items held in the cursor (a grenade stack you're throwing) aren't counted in the ammo columns |
| OR-I10 | Kiting beats the swarm (PT3) | The swarm chases you as one trailing blob; held units wait where you were when they got held (20 s), so after you kill the blob nothing rebuilds |
| OR-I11 | ~~Telemetry loses the end of a run (PT5 ring 0)~~ | Rows were flushed every 30 s and on finish; a run that ended without `finish` (game closed) lost up to 30 s, incl. the death line. Fixed in OR-E6: flush on `on_player_died` too |
| OR-I12 | Player messages are a test aid | "The hive swarms!", "The brain shields itself…" etc. help testing; the shipped mod shouldn't print them (OR-D63). Remove before release |
| OR-I13 | Terrain decides the fight (PT10) | A cliff next to the brain gave a chokepoint: 160 s without a biter touching you. Answer: OR-E9 (OR-D61) |
| OR-I4 | Turrets and the car gun don't get the ×3 gun buff (CF-D8 only touches pistol + SMG) | A turret bullet does a third of the player's SMG bullet. Design choice or buff them too? (Q7) |

## Balance model: kill capacity vs arrival rate

You get overwhelmed when enemies **reach you** faster than you kill them, for long enough. Total count isn't the problem.

| Lever | Draft |
|-------|-------|
| Kill capacity | SMG: max 10 kills/s, ~6–7 real. Shotgun: 2–5 per shot on a packed group at 1.5 shots/s → ~6 kills/s (verified). Grenade: a whole pack, 2 throws/s. Steady flow **below** SMG capacity, bursts **above** it → area weapons, turrets, car pay off |
| Slow fodder | Fodder clearly slower than you (e.g. 0.15 vs 0.25): kiting always works, the danger is being **cut off** (surround). Today a small biter is 0.225 vs your 0.25, before the challenge slow sticker |
| Low damage per hit | A few biters touching you cost HP slowly; death comes from volume over time |
| Packs + lulls | Tight packs (area weapons pay) with breathers between them |
| Nests set the pressure | Already built (group size × share of nests alive). Clear the base first, or rush the brain |
| **Pressure director** (OR-D3) | See below |
| Performance cap | Alive cap ~300–400 to start; measure UPS (OR-I3) |

## Pressure director (draft, OR-D3)

Hidden throttle against death spirals. Runs on the challenge check (every 30 ticks).

| Part | Draft |
|------|-------|
| Pressure | Enemies of the challenge within **12 tiles** of the nearest participant. Optional: × (1 + missing HP share) |
| Calm (pressure < low, e.g. 15) | Normal spawning. Held groups released one pack at a time |
| Busy (low … high) | Normal spawning, no releases |
| Full (pressure > high, e.g. 40) | New groups don't attack: they run to a **holding ring** ~30 tiles from you, wander there, and wait. Visible as "they circle you" |
| Release | When pressure drops to calm: the oldest held pack attacks (with the surround routes) |
| Safety | Held units that wait longer than ~20 s attack anyway (no endless stalling). Phase messages unchanged |
| Debug | `/ht-challenges` shows pressure, state and held count; test tool logs pressure per second |

Fits P12 (last-stand pile-up near the end of the first ring) too. Could later run on the first ring as well (Q6).

## OR-E1 build spec (go-ahead 2026-10-23, built 2026-10-23)

Smallest build for PT1. Rings 2+ keep today's old waves and distance-sized brains.

| # | Part | What | Where |
|---|------|------|-------|
| E1-1 | Ring-1 brain | `hf-brain-ring1`: copy of `hf-brain-small` (no regen, no fissures, same ally slow), **2250 HP**. Own tint so you can tell it apart. A rally `ht-rally-ring1` (× 0.75 like the others = 1688 HP, build time 10 min: between small 5 and medium 15) | `Hostile-fauna/prototypes/brain.lua`, `placeholders.lua`, locale; HT `prototypes/entity/rally.lua`, `scripts/rally.lua` (`GUARDIANS`, `SIZE`) |
| E1-2 | Brain by ring | `hostile_territory_variation`: ring 0 → small, **ring 1 → `hf-brain-ring1`** (new 4th entry in `units`), ring 2+ → by distance as today. Uses `hostile_point_ring`, so the medium at 630 tiles goes away | `nauvis-territory.lua` |
| E1-3 | Per-ring phases | `RING0` becomes `PHASES[0]`; `PHASES[1]` = the same with: siege 8–14 (max 60), wake 22–34 / 8 s (max 140), swarm **750** at 25 per check (~15 s), last stand 10 / 2 s (max 240). Unit `small-biter`. Siege ×2 confirmed (user, 2026-10-23) | `scripts/waves.lua` |
| E1-4 | Siege in ring 1 | The siege trigger works for every ring that has `PHASES` (OR-D7) | `scripts/challenge.lua:194` |
| E1-5 | Shotgun ×3 | `damage_modifier = 3` on the shotgun (OR-D10) | `Hostile-fauna/data-updates.lua` |
| E1-6 | Kit | `/cheat-kit ring1`: SMG + 100 piercing, shotgun + 100 shells, 20 grenades, heavy armor (OR-D12); researches damage / shooting speed / explosives level 2 for the player's force | `cheating-mod/control.lua`, `docs/commands.md` |
| E1-7 | Finder | Changed: no mod code. `/ht-brains` doesn't list brains; a `/c` command in commands.md ("Oil ring") generates chunks and teleports you next to the nearest `hf-brain-ring1` | `docs/commands.md` |
| E1-8 | Headless | `ht-oil-ring-test`: every ring-1 brain is `hf-brain-ring1` (5 seeds). `ht-challenge-test`: ring-0 regression + ring-1 phases via `waves_step` (now one run per brain). **UPS at the alive cap** (OR-I3). `check-paths.py` after the prototype changes | `tools/` |

### OR-E1 results (headless, 2026-10-23, 2.1.21)

| Check | Result |
|-------|--------|
| Prototypes (`--dump-data`) | `hf-brain-ring1` 2250 HP, no regen, no fissures; `ht-rally-ring1` 1688 HP; shotgun `damage_modifier` 3, turret 1; `units` has the 4th brain; variation expression by ring. `check-paths.py`: 2395 paths, 0 missing ✅ |
| Brain per ring (`ht-oil-ring-test`, 5 seeds) | Ring 0: only small. **Ring 1: only `hf-brain-ring1`** (7–10 per seed, incl. the one at 630 tiles that was medium). Ring 2: medium / big as before ✅ |
| Ring-0 regression (`ht-challenge-test`, seed 12345) | Same as E9: siege → wake → swarm 250 → last stand, surround 8 / 8 sectors, ash cloud slows 279 ✅ |
| Ring-1 phases (same run) | Brain at 446 tiles, 4 nests (2 destroyed at 10 s). Siege groups 10, 7; wake 15 (22–34 × half the nests); swarm **750 in 15 s** (25 per check); last stand 5 every 2 s (10 × half). Surround 8 / 8 sectors, ash cloud slows 776 at once ✅ |
| UPS (OR-I3) | Average tick time (wall clock, headless): no challenge 1.8 ms (83 enemy units); ring-0 swarm 1.1 ms (~840 enemy units on the map); **ring-1 swarm 2.7 ms (~1360 enemy units)**. 60 UPS needs < 16.7 ms, so fine; rendering in game comes on top ✅ |
| Siege in ring 1 | `challenge.lua` uses `waves.PHASES` (code change only; the test drives `waves_step`, so the trigger itself is checked in PT1) |
| Kit | `cheating-mod` loads; tech names exist. The kit itself needs a player → checked in PT1 |

Files: `waves.lua` (`PHASES`, `update_phased`), `challenge.lua`, `rally.lua`, `prototypes/entity/rally.lua`, `nauvis-territory.lua`; Hostile-fauna `brain.lua`, `data-updates.lua`, `placeholders.lua`, locale; `cheating-mod/control.lua`; `tools/ht-challenge-test` (results `or-e1-result.txt`, `or-e1-ups.txt`).

## Escape options (OR-I5, draft 2026-10-23)

Goal: many small biters on screen and around you, but being surrounded is a situation you can break out of, not a death sentence.

| # | Option | What | Engine / cost |
|---|--------|------|---------------|
| X1 | **Panic grenade** | Make the grenade-at-your-feet escape obvious and quick: a hotkey that throws a grenade at your own position, and/or a hint when you get surrounded | Script: custom input + `create_entity{name = "grenade"}` at the player. Small |
| X2 | **Repulse capsule** | New pre-oil capsule: throw at your feet, pushes everything within ~5 tiles back 4 tiles (+ small damage). The discharge defense's push-back effect, made into a capsule | Data only: `push-back` effect exists (discharge defense: distance 4). Small |
| X3 | **Melee slots** (light director) | Only N biters (e.g. 8–12) may attack you at once; the rest circle at 5–8 tiles. Still surrounded on screen, never crushed solid. Same mechanism as OR-E2's holding ring, tuned for "surround but leave room" | Script, the planned OR-E2. Medium |
| X4 | **Push through biters** | The character can shove through small biters (they get pushed aside or take damage when you walk into them) | Collision is engine-side; script push = teleport units out of your path each tick. Unclear, needs a test |
| X5 | **Dash** | A hotkey dash: a few tiles in your move direction, through biters, with a cooldown (survivors-like) | Script: custom input + teleport to a free spot. Small–medium |
| X6 | **Shotgun as a crowd weapon** | Faster recharge (40 → ~20 ticks) and/or pellets that pierce (one pellet through 2–3 smalls). Gives the "mow them down" feel | Data only. Small |
| X7 | **Gaps in the surround** | Swarm routes leave 1–2 open lanes (e.g. the flank arc skips a sector), so there's always a way out if you see it | `waves.lua` flank arc. Small |


## OR-E2 spec: pressure director + telemetry (decided 2026-10-23: OR-D13–D18, built 2026-10-23)

Replaces the earlier draft above for the swarm. Runs every challenge check (30 ticks) for every participant.

**Why a damage budget, not a slot count.** A small biter does 7 per hit every 35 ticks. Heavy armor (6 flat, 30 %) turns that into 0.7, so **one biter = 1.2 HP/s and the 8.3 HP/s budget ≈ 7 biters biting**. Without armor one biter is already 12 HP/s. A fixed slot count would be wrong for one of the two, so the director measures the damage you actually take. The character heals 9 HP/s, but only after 10 s without damage, so at a steady 8.3 HP/s you die after ~30 s of never breaking free (OR-D17).

| Part | Draft |
|------|-------|
| Measure | Damage to each participant from challenge units (`on_entity_damaged`, character filter), rolling window (Q12) → HP/s. Also: enemy units within 3 tiles ("touching") and 3–10 tiles ("ring") |
| Budget | max health / 30 per second (OR-D17): 8.3 HP/s at 250 HP, measured over a rolling 3 s |
| Slots (as built) | allowed biters = (budget − damage from the brain / worms) ÷ damage per biter. Damage per biter is learned from what units deal you (unit damage ÷ units biting, smoothed), starting at 1.2 (small biter vs heavy armor) |
| Cap (as built) | Of the challenge units within **24 tiles** that aren't held, the nearest `allowed` attack; the rest are held: they walk to a **holding ring 7–11 tiles** out on their own side of you and wait there ignoring enemies. Catching them at 24 tiles (beyond the flank ring) holds new arrivals before they reach you |
| Release (as built) | Under budget: held units fill free slots, 4 per check, nearest first. A hold lasts 20 s, then the unit counts against the cap again (held anew or attacks if there's a slot), so there's no mass charge |
| Feel | The ring stays visible (7–11 tiles), the gap to you is what lets you move. Held units ignore you, even if you walk into them (see OR-I7) |
| Scope (as built) | Swarm and last stand of **ring 1** (`director = true` in `PHASES[1]`); ring 0 is Q6. Not wake / siege (OR-I8). Base defenders (units not from the challenge) aren't held |
| Debug | `/ht-challenges`: HP/s (and from units), budget, slots, biting (+ not ours), touching, ring, held |

**Telemetry (Q13).** One CSV per challenge, a row per second per participant, written to `script-output/ht-telemetry/<map tick>-t<territory>.csv` when the challenge ends (and every 30 s while it runs, so a crash keeps the data). Columns: second, phase, brain %, player HP, HP/s taken, touching, ring, held, alive, kills in that second by damage type (physical / explosion / impact), ammo left (red, shells, grenades, repulse). A summary line at the end: won/lost, time per phase, peak HP/s, longest time with HP/s over budget. Lets PT2 answer "how close to death, how often, and what got me out" without you taking notes.

**Repulse capsule (X2).** Not in vanilla as an item. The effect is: the **discharge defense** (personal equipment) does a radius-8 pulse with `stun-sticker` + `push-back` 4 tiles, but it needs an equipment grid and oil-tier research, so it's out of reach before oil. New item `ht-repulse-capsule`: thrown at your feet, radius ~6, push-back 4 + stun 0.5 s + a little damage, using those vanilla effects. Kit only for now, no recipe (OR-D15).

**Shotgun (X6):** reload 40 → 20 ticks (OR-D16).

## OR-E6 spec: a brain that thinks (OR-D33–D38, go-ahead + built 2026-10-23; deviations in step 15)

Ring 1 only; ring 0 stays as it is. Numbers stay (OR-D40). The director's damage budget and slots still decide **how many** units may reach you; OR-E6 changes **how they move and what the brain does**.

### Beats

| Surge (brain %) | Verb | Brain | Units |
|-----------------|------|-------|-------|
| Wake (100–80) | as now | Open | Wake groups as now |
| 1 Swarm (80) | **Hold** | Shielded until the surge is broken, then open ~8 s. New: **guard rush** | Squads: pin + flank + reserve |
| 2 Encircle (55) | **Break out** | Same openings. New: **stand-still punish** | Closing ring (OR-D38), then squads |
| 3 Frenzy (30) | **Burst race** | **Always open**, extra pulses (built). New: **rocks** (Q27) | Fast cut-off squads, reserve rushes back |

### Parts

| # | Part | Draft | Where |
|---|------|-------|-------|
| E6-1 | Re-plan (C0) | Every 2 s, a unit on its way to a flank or encircle point whose route was planned more than 6 tiles from where you are now gets a new point around your current position. Squads (E6-2) replace most of this for ring 1; re-plan covers whatever isn't in a squad | `waves.lua` (`flank_route`, encircle), `storage.flankers` |
| E6-2 | Squads (C1) | During the swarm, free challenge units (not biting, not in a squad) within 30 tiles are grouped into squads of 15–30, nearest to a free role. Roles, as slots around you, re-placed every 2 s while you move: **pin** (between you and the brain, ~9 tiles), **flank** left / right / back (~12 tiles), **cut-off** (on your path 4 s ahead: today's intercept, but it waits), **reserve** (6–10 tiles from the brain, on your side). States: **form** (walk to the slot, ignore enemies) → **ready** (stand) → **tell** 1.5 s → **charge** (attack). A charge starts when ≥ 2 squads are ready and the director has free slots; those squads charge together. Over budget: squads stay ready (this **replaces the holding ring**: held units become squads). Rebuild = a charge. Plain commands to a shared slot per unit (no `LuaUnitGroup`, unless a test shows it's better) | `director.lua` |
| E6-3 | Openings (A1) | Shield: in `on_segmented_unit_damaged` (check the 2.1 event name and fields first) refund 90 % of each hit on the ring-1 brain while shielded. Shield goes up when a surge starts; it opens for **8 s** once 70 % of that surge's units are dead. After that it opens again for 8 s each time fewer than 15 challenge units are within 25 tiles of you. Frenzy: open. Show it: a tint / glow on the brain if the runtime allows it, otherwise `rendering` (light / circle on the head) + "The brain is exposed!" | `waves.lua` or new `scripts/brain-fight.lua`, `control.lua` |
| E6-4 | Guard rush (surge 1+) | You damage the brain while the reserve squad is ready → it charges you (cooldown 6 s) | `director.lua` |
| E6-5 | Stand-still punish (surge 2+) | You move < 1 tile in 2 s → every ready squad does its tell and charges | `director.lua` |
| E6-6 | Closing ring (surge 2) | Encircle units go to a full ring at 16 tiles around you and hold until the surge is out; then the ring, centred on you each time, steps in 2 tiles every 3 s; at 6 tiles they charge. Units over the director's slots stay on the ring | `waves.lua`, `director.lua` |
| E6-7 | Rocks (terrain, Q27) | Draft: from surge 3, every ~8 s the brain raises a short wall of 3 rocks (`big-rock` / `huge-rock`) across your path 6–10 tiles ahead. **Never lock you in:** never within 4 tiles of you; rocks at 6–12 tiles may cover at most 90° of the circle around you; max 2 walls alive; each wall crumbles after 15 s. A visible tell first (dust / cracks, ~1 s). Rocks block biters too (chokepoints) | `director.lua` or `brain-fight.lua` |
| E6-8 | Telemetry | + shield (open / shut), squads by state, charges, reactions fired, rocks alive. OR-I11: flush on `on_player_died` | `telemetry.lua` |
| E6-9 | Headless | `ht-challenge-test` ring 1: shield refund (90 % shut, 0 % open); openings after 70 % of a surge die; squads form, pause and charge together; a moving target gets re-planned slots (no stale points: distance from each squad slot to its role's spot < 4 tiles); stand-still and guard-rush triggers; the closing ring steps in; rocks never cover > 90°, never within 4 tiles, vanish after 15 s; director still on budget (≤ 8.3 avg when the target doesn't shoot); ring 0 unchanged; UPS | `tools/` |

## OR-E7 spec: bearers, regroup, rocks that stay (OR-D47–D52, go-ahead + built 2026-10-23; deviations in step 17)

Ring 1 only. Changes OR-E6's shield rule (E6-3) and rocks (E6-7); squads, reactions and the closing ring stay.

| # | Part | Draft | Where |
|---|------|-------|-------|
| E7-1 | Bearer unit | `hf-shield-bearer` (Hostile-fauna): copy of `big-biter` (375 HP, its resistances), speed × 0.6, own tint (shield blue). Placeholder art = tinted big biter. Red bullet: ~19 after resist → ~20 bullets; shotgun ~3–4 shots; grenades work. `check-paths.py` after | `Hostile-fauna/prototypes/`, locale |
| E7-2 | Bearers in the fight | At the start of surges 1 and 2: 3 bearers come out of the brain, walk to spots **6–10 tiles from the brain, 120° apart** (random rotation), and stand there (fight back if you come close). A **dashed line** from each bearer to the brain (rendering, goes when the bearer dies). Not recruited into squads, not pulled back by the regroup | `brain-fight.lua`, `waves.lua` (spawn) |
| E7-3 | Shield rule | Surge 1 / 2 start: shield up while any of its bearers lives. All dead → "The shield bearers are dead: the brain is exposed!" → open **until the next surge**. Frenzy: open. Bearers that can't be placed → open. Replaces kill-70 % and the re-opening (OR-D34 timing) | `brain-fight.lua` |
| E7-4 | Regroup | **Trigger:** swarm phase, not during a closing ring or a regroup, 30 s since the last one; your smoothed speed > 3 tiles/s for 5 s with < 3 challenge units within 6 tiles the whole time. **Pull back:** all challenge units except the 10 % nearest you and the bearers leave their squads and run (ignoring enemies) to spots 8–16 tiles from the brain; "The hive pulls back…". **Lure:** the brain is open while the hive is pulled back. **Re-swarm:** you get within 25 tiles of the brain, or hit it, or 20 s pass → they come at you on the swarm's surround routes (flank ring + detour, waves.lua) planned from where you are then; "The hive swarms!". Shield back to the bearer rule | `director.lua`, `waves.lua` (surround routes as a function) |
| E7-5 | Rocks from surge 1 | Every 8 s a wall of 3 across your path (as E6-7), from surge 1 on. Walls **stay** (no crumble, also after the challenge). Same safety rules at placement (≥ 4 tiles from you, ≤ 90° covered within 12 tiles, counting the rocks of this fight). At most 30 walls per fight | `brain-fight.lua` |
| E7-6 | Arena (surge 2) | When surge 2 starts: brown circles for 1 s, then huge rocks on a ring of 22 tiles around you, every ~3 tiles, except **4 gaps of ~4 tiles** (90° apart, random rotation). A spot that doesn't fit (water, a nest) is left out. Stays | `brain-fight.lua` |
| E7-7 | Telemetry | + bearers alive, regroup state (off / pulled back / re-swarm), arena rocks | `telemetry.lua` |
| E7-8 | Headless | Bearers: 3 at surges 1 and 2, shield shut while alive (probe), open after killing them and still open until surge 2; regroup fires for the kiting target, not for the standing one; ≥ 90 % pulled back; re-swarm when the target comes within 25 tiles / after 20 s; rocks from surge 1, still there after their old 15 s; arena ring with 4 gaps (largest angular gaps ≈ 4 tiles); director budget; ring 0 unchanged; `check-paths.py`; UPS | `tools/ht-challenge-test` |

## OR-E9 spec: the brain sees a chokepoint (OR-D61–D63, go-ahead 2026-10-23, built 2026-10-24; deviations in step 18h)

Ring 1 only (director). Comes from PT10 (OR-I13): one cliff turned the fight into 160 s of feeding biters into your guns.

| # | Part | Draft | Where |
|---|------|-------|-------|
| E9-1 | Kill log | Positions of challenge-unit deaths (`on_entity_died`, already used by telemetry) per record, last 15 s | `director.lua` (+ `control.lua`) |
| E9-2 | Detect | Every 2 s per participant, in the swarm: **kill zone**: ≥ 20 deaths within 20 tiles of you in 15 s, ≥ 70 % of them inside one 60° arc; **stalemate**: you moved < 5 tiles in 20 s and units dealt you < 25 % of the budget over the last 10 s. Both → **choke**, with its direction (the arc's centre). Ends when you move > 10 tiles or the kill zone is gone for 10 s | `director.lua` |
| E9-3 | Stop feeding | While choked: **no charges** through the choke arc (± 30°); squads whose slot lies in it wait **out of range** (> 20 tiles, beyond the SMG's 18) on that side. No regroup (it needs you to run, so they can't both happen) | `director.lua` |
| E9-4 | Long way round | The other squads get slots **opposite and beside** the choke (outside the arc) and walk there with normal pathfinding, which finds the way around the cliff / water if there is one. A squad charges only from a slot outside the arc. A squad whose walks keep failing (no way round) gives up its slot and waits out of range too | `director.lua` |
| E9-5 | Telegraph | "The hive won't walk into your guns." when a choke starts, "The hive comes around!" when the first squad is in place on another side (OR-D63: messages for testing) | `director.lua` |
| E9-6 | Telemetry | + choke (off / on), choke direction | `telemetry.lua` |
| E9-7 | Headless | Target inside a ring of huge rocks with a 60° gap (biters don't attack rocks), killing 4 per check: choke detected, no charges through the gap, squads out of range; with a second gap behind the target: squads come round through it. A target in the open (existing runs): no choke | `tools/ht-challenge-test` |

## OR-E8 spec: anchor ring + queens (OR-D66–D73, specced 2026-10-24; E8-A go-ahead + built 2026-10-24, deviations in step 20)

Ring 1+ (map gen) / ring 1 (fight). Built in **two parts, a PT after each** (retro: one mechanic per PT): **E8-A anchor ring + shield link → PT12**, then **E8-B queens + escort → PT13**. Numbers stay (OR-D40); a balance pass comes after OR-E8.

Facts that shaped it (code, 2026-10-24): brain points keep **38 tiles** from their cell edge and `brain.lua` relies on a base never leaving its cell, so anchors fit at **≤ 34** tiles (nest half-size 2.5); the guaranteed oil sits **45 ± 9** tiles from one ring-1 brain (`oil.lua`); the siege starts on a hit within **30** tiles (`BASE_REACH`), waves use nests within **25** (`nest_radius`).

### E8-A: anchor ring + shield link (built 2026-10-24)

| # | Part | Spec | Where |
|---|------|------|-------|
| A1 | Map gen | Ring 1+ bases (`hostile_point_ring >= 1`) get **4 anchor nests** (biter spawners) at **32 tiles**, 90° apart, turned **45°** off the base rotation. Same slot trick as the inner ring | `brain-bases.lua` |
| A2 | Regrow | `regrow.lua` knows the 4 anchor slots (ring ≥ 1, after core and inner ring), so a lost anchor regrows too. Also lets `regrow run` build anchors on bases generated before OR-E8 (old PT saves) | `regrow.lua` |
| A3 | Oil | Oil spot **45 → 56** tiles (wells 47–65, clear of anchors at ≤ 35) | `oil.lua` |
| A4 | Siege | A hit on an anchor **starts the siege** (reach 30 → 36), but killing one **doesn't wake** the brain (wake stays at 30) | `challenge.lua` |
| A5 | Waves | Anchors **don't spawn** waves or surges: `nest_radius` stays 25 | — |
| A6 | Anchor list | At challenge start: the spawners 29–36 tiles from the brain = `record.anchors`, `anchors_start`. An **orange dashed line** from each anchor to the brain while the challenge runs (goes with the anchor) | `brain-fight.lua` |
| A7 | Shield link | Whenever the brain is **open** (bearers dead, lure, frenzy), it gets back **50 % × share of anchors alive** of each hit: all 4 alive → takes 50 %, 2 alive → 75 %, none → 100 %. Shut stays 90 %. Message when the last anchor dies: "The anchors are down: the brain is fully exposed!" | `brain-fight.lua` |
| A8 | Telemetry | + `anchors` alive, `brain_take` (share of a hit the brain keeps now) | `telemetry.lua` |
| A9 | Headless | Map check: every ring-1 brain has 4 spawners at 29–36 tiles (minus blocked slots), ring 0 none, inner ring unchanged, no well within 6 tiles of a nest; regrow rebuilds a destroyed anchor. Challenge test: anchors registered, refund open = 50 / 25 / 0 % with 4 / 2 / 0 alive, shut 90 %; a hit on an anchor starts the siege, killing it doesn't wake; ring 0 unchanged; `check-paths.py` | `tools/ht-map-check`, `tools/ht-challenge-test` |

Headless can't judge: whether clearing anchors in the siege feels like a choice, whether the lines read in game, fight length.

### E8-A2: anchors are the shield links (OR-D74–D77, go-ahead + built 2026-10-24; deviations in step 21a)

Changes E8-A's A6 / A7 and OR-E7's E7-2 / E7-3 (bearers per surge). Map gen, regrow, oil, siege rules (A1–A5) stay.

| # | Part | Spec | Where |
|---|------|------|-------|
| A2-1 | Links | At the fight's start (siege or wake): each anchor = one link, **blue dashed line** to the brain (bearer colour, was orange) | `brain-fight.lua` |
| A2-2 | Bearer from an anchor | An anchor in `fight.anchors` dies → a `ht-shield-bearer` is created **at the anchor**, walks (distraction none) to a spot **6–10 tiles from the brain on the anchor's side**, then holds there as now. Its line replaces the anchor's. "An anchor falls: its bearer runs to the brain." | `brain-fight.lua`, `control.lua` (`on_entity_died` for nests) |
| A2-3 | Shield | **Shut** while any link lives (anchor or its bearer), from the start; all broken → **open for good**: "The links are broken: the brain is exposed!". Frenzy opens it anyway; the lure (regroup) still opens it while pulled back. A base with **no anchors** (old save, water) → open, as before when bearers couldn't be placed | `brain-fight.lua` |
| A2-4 | Removed | Bearers out of the brain at surges 1 and 2 (`spawn_bearers`), the 50 % anchor rule (`anchor_link`) | `brain-fight.lua`, `waves.lua` |
| A2-5 | Telemetry | `anchors`, `bearers`, + `links` (alive); `brain_take` stays | `telemetry.lua` |
| A2-6 | Headless | `ht-anchor-test`: 4 links at start, shut from the siege (200 hit → 20 HP); kill an anchor → a bearer appears at it and ends 6–10 tiles from the brain on that side, still shut; kill all anchors and bearers → open for good (200 HP), no new bearers at surges. `ht-challenge-test`: probes shut until the links are broken; ring 0 unchanged | `tools/` |

Headless can't judge: whether "break the links first" reads as a boss phase, whether the walk-in looks natural, balance.

### E8-B: queens + escort (OR-D70, OR-D72, OR-D78–D81; respecced after PT12.2, go-ahead + built 2026-10-24; deviations in step 22)

Ring 1 (`P.queens`). The queens are the base's **stream of biters**: they keep coming while nests live, on top of the surges, and the director caps the damage (from the swarm on). Marked *(mine)*: picked by me, not asked.

| # | Part | Spec | Where |
|---|------|------|-------|
| B1 | Unit | `ht-queen` next to the bearer: a big biter (its resistances) with **500 HP**, speed **0.1**, drawn at **behemoth size, purple tint**. Doesn't fight: walks and holds, like the bearer *(mine)* | `challenge-units.lua`, locale, `check-paths.py` |
| B2 | Release | From the **first nest death of the fight** (any nest within 36 tiles, inner or anchor, **siege too**): while **fewer than 2 queens** live, a living nest releases one, the first at once, then **one every 20 s**. The queen appears at the nest. **No nest left → no new queens.** "A queen crawls out of a nest!" | `brain-fight.lua` (new `queens` part), `control.lua` (`on_entity_died`) |
| B3 | Spot | The queen walks (distraction none) to a spot **20–28 tiles from you**, on your side **away from the brain** (a half circle behind you, seen from the brain), and holds there. A new spot when you're more than **20 tiles** from where the spot was picked, or after a failed walk *(mine: one rule out of the draft's three, so it reads)* | `brain-fight.lua` |
| B4 | Spawning | From the moment it holds: **3 small biters every 4 s** next to it, **on top of** the surges. They act like the phase's own units: siege / wake → attack you; swarm → the director takes them into squads. Paused while the challenge has **≥ 300 units alive** *(mine: a safety cap)* | `brain-fight.lua`, `waves.lua` (spawn helper) |
| B5 | Escort | **8 small biters** come out with each queen *(mine)*, stay within ~6 tiles of it (re-sent each check while it walks) and attack anything that comes within 8 tiles. Not taken into squads, not pulled back by the regroup. A dead queen's escort joins the rest | `brain-fight.lua`, `director.lua` (leave escorts alone, like bearers) |
| B6 | Telemetry | + `queens` alive, `queen_spawned` (running total) | `telemetry.lua` |
| B7 | Headless | `ht-anchor-test` (or a queen run): no queens before a nest dies; 1 at once after the first nest death (siege), 2 after 20 s, never 3; a killed queen replaced 20 s later; none once all nests are dead; queen holds 20–28 tiles from the target on its far side from the brain; 3 per 4 s; escort within ~6 tiles; cap at 300. `ht-challenge-test` regression + UPS; `check-paths.py` | `tools/` |

Headless can't judge: whether a queen reads as a priority target, whether the stream feels like pressure or a chore, balance.

## OR-E10 spec: the hive keeps up the pressure (Q36, OR-D84–D86; go-ahead + built 2026-10-24; results in step 24)

Ring 1 (director). From PT13.2: after the first 30 s you took ~0 HP/s for 2 minutes with 200–450 alive; 943 units charged but you killed 10–24 per second, so each charge died on the way in; the wake starved once the nests were dead. Marked *(mine)*: picked by me, not asked.

| # | Part | Spec | Where |
|---|------|------|-------|
| E10-1 | Wake doesn't starve | Wake groups keep their full size (no nest share); with no nest left they come out of the brain (`P.wake_from_brain`, like `last_stand_from_brain`) | `waves.lua` |
| E10-2 | Director from the wake | `active` from the wake on: budget, slots, squads (and the stream) in the wake too. Regroup, chokepoint, closing ring, guard rush and stand-still punish keep their current gates (swarm / surges) *(mine: one change at a time)* | `director.lua` |
| E10-3 | Calm | Units' damage to you averaged over the last **5 s** < **30 %** of the budget → `calm` (telemetry `director` = calm already exists for the slot growth; this is a new `stream` flag) | `director.lua` |
| E10-4 | Stream | While calm: no tell, no waiting for 2 ready squads. Every check (0.5 s) the **3 biggest squads** each send their **2 members nearest you** straight at you *(mine: 12 units/s, about what you killed in PT13.2)*, so something is always arriving from 2–3 sides. Squads keep recruiting as now. Out of calm: the old rhythm; over budget: slots shrink as now | `director.lua` |
| E10-5 | Telemetry | + `stream` (on / off), `streamed` (running total) | `telemetry.lua` |
| E10-6 | Headless | `ht-challenge-test` (target never shoots / kills 4 or 8 per check): in the wake with all nests dead, groups still come (out of the brain); director active in the wake; while calm the stream sends ~12/s from ≥ 2 squads; damage rises towards the budget but the 3 s average stays ≤ budget (+ margin) for the standing target; regroup / choke runs unchanged; ring 0 unchanged; UPS | `tools/` |

Headless can't judge: whether a stream reads as "the hive pushes" or as a trickle you farm, balance.

## OR-E11 spec: the stream comes from the queens (Q37, OR-D88–D90; go-ahead + built 2026-10-24; results in step 26)

Ring 1. From PT14: the squad stream arrived one by one and died on arrival (you killed 10.8/s, it sent 8.3/s); 0.3 HP/s in the swarm against a budget of 8.3. Now the **queens are the stream** and the director turns it up until it hurts. Marked *(mine)*: picked by me, not asked.

| # | Part | Spec | Where |
|---|------|------|-------|
| E11-1 | Queens | `QUEENS` 2 → **4**; spot **50–70 tiles** from you on your flanks; the retreat spot 50–70 too. Release rules as now (any nest death, one per 20 s, none without nests) | `brain-fight.lua` |
| E11-2 | Rate | Per record: `queen_level` 0..9 → biters per spawn = 3 + level, every 4 s per holding queen. The director's calm flag (OR-D86) for **5 s** → level +1 (max 9 = 12 per spawn); over the budget → level 0 *(mine: back to the base, not a pause)* | `director.lua` (calm, level), `brain-fight.lua` (spawn) |
| E11-3 | Straight at you | Queen biters attack you and the squads leave them alone while they run in (marked as charging for 10 s; at 50–70 tiles they need ~6 s) | `brain-fight.lua`, `director.lua` |
| E11-4 | Squad stream off | `P.stream = false` (OR-E10 E10-4 stays in the code); squads keep the rhythm | `waves.lua` |
| E11-5 | Cap | Queen spawns pause at **500** units alive (was 300: the swarm alone is 200–400) *(mine)* | `brain-fight.lua` |
| E11-6 | Telemetry | + `queen_level` (0–9) | `telemetry.lua` |
| E11-7 | Headless | `ht-anchor-test`: 4 queens, holding 50–70 tiles out; the level climbs while the target is calm (spawns 3 → 12 per 4 s) and drops to 0 when it's over budget; queen biters aren't put into squads; retreat to 50–70. `ht-challenge-test` regression + UPS (up to 4 × 3 = 12 biters/s more) | `tools/` |

Headless can't judge: whether 4 streams from off screen feel dangerous or unfair, whether you can still find and kill queens, balance.

## OR-E12 spec: queens all around (OR-D91–D93; go-ahead + built 2026-10-24; results in step 28)

From PT15: the director had the queens at level 9 from 96 s on, but they brought only 141 biters (1.8/s, could be 12/s): they spawn only while holding, and every 20 tiles you moved they all walked to new spots (up to 20 s each). Marked *(mine)*.

| # | Part | Spec | Where |
|---|------|------|-------|
| E12-1 | Spots all around | 4 slots around you, 90° apart, starting 45° off "away from the brain" *(mine: so none sits right on the road to the brain)*; a queen takes the **free slot nearest her own angle** around you (± 20° jitter), 50–70 tiles out | `brain-fight.lua` (`queen_spot`) |
| E12-2 | Spawn while walking | Every 4 s per queen, in **any** state (walk, hold, flee), at her position; rate and cap as now (3 + level, cap 500) | `brain-fight.lua` |
| E12-3 | Re-spot | A new spot only when she's **closer than 40 or further than 80** tiles from you (and not fleeing); the old "you moved 20 tiles" rule goes. Retreat at 25 stays | `brain-fight.lua` |
| E12-4 | Headless | `ht-anchor-test`: 4 queens on 4 different sides (angles ~90° apart); spawns go on while walking; a target that moves 30 tiles doesn't make every queen re-spot; queen biters per second at level 9 close to 4 × 12 / 4 s while under the cap. Regression + UPS | `tools/` |

Can't judge headless: whether streams from all sides feel like being surrounded or like unfair chip damage.

## OR-E13 spec: the trap closes the circle (OR-D94, OR-D96; go-ahead + built 2026-10-24; results in step 30)

| # | Part | Spec | Where |
|---|------|------|-------|
| E13-1 | Even ring | During the lure hold, the trap's 8 packs take **evenly spaced spots on a ring** around you (the arc towards the brain stays open, the rest evenly filled), spread out along their part of the ring instead of one clump each | `director.lua` (trap) |
| E13-2 | Tighten | The ring radius goes **30 → 20 tiles** over the hold (10 s), re-placed as you move | `director.lua` |
| E13-3 | Spring | As now: take the bait (within 15 tiles of the brain) or time out → all charge from all sides | `director.lua` |
| E13-4 | Headless | Kiting target that takes the lure: packs cover the ring evenly (no 45° sector empty except the brain road), radius shrinks to ~20 | `tools/ht-challenge-test` |

## Balance pass (BP, OR-D97–D112, done 2026-10-24 after PT23; go-ahead 2026-10-24; BP-1, BP-2, OR-D107 kept after PT18–PT20, BP-3 + BP-4 after PT22 tuned by OR-D109, D110; results in steps 34–43)

Numbers only, no new mechanics, **one parameter set per PT** (retro). Interview done (2026-10-24, OR-D97–D104); go-ahead (user, 2026-10-24); **BP-1 built + headless ✅**, next PT18 (step 35).

### Telemetry PT15–PT17 (`20117-t6`, `10635-t2`, `1943-t8`)

| | PT15 (t6) | PT16 (t2) | PT17 (t8) |
|---|---|---|---|
| Length (siege / wake / s1 / s2 / frenzy) | 157 s (32 / 65 / 20 / 17 / 23) | 231 s (11 / 144 / 38 / 18 / 21) | 199 s (2 / 99 / 27 / 33 / 39) |
| Links all broken at | 89 s | 127 s | 55 s |
| Links broken → brain 80 % | 8 s | 28 s | 46 s |
| Damage wake | 29 HP (0.45/s) | 172 HP (1.2/s) | 148 HP (1.5/s) |
| Damage surges 1 + 2 | 31 HP | **3 HP** | **1 HP** |
| Damage frenzy | 0 | 16 HP | 71 HP (all in the frenzy-sprung trap, 3 s) |
| End HP | 190 | 57 | 30 |
| Share of all damage in burst seconds (> 4 HP/s) | 83 % (5 s) | 71 % (12 s) | 82 % (14 s) |
| Worm / acid hits in the opening | 28 HP | 80 HP | 44 HP |
| Queens (max alive) / queen biters | 4 / 153 | 4 / 1577 | **2** / 587 |
| Alive in surges 1–2 | 250–470 | **480–630** | **380–575** |
| Director | calm almost always (budget 8.3 never reached on average) | same | same |
| Pull-backs | 1 (surge 1) | 2 (surges 1, 2) | 2 (surge 1, surge 2 → sprung by the frenzy) |

### Findings

- **F1. Surges 1 and 2 are safe.** 400–600 alive, the director calm, yet 0–31 HP over 35–56 s. Each one starts with a pull-back 5–17 s in (kiting), so ~15 s of each surge is a hold whose bait spring did nothing (PT16, PT17: ≤ 6 touching).
- **F2. The queen cap is hit in the surges.** The cap (500) counts every challenge unit, so the surge units alone stop the queens: queen biters drop from 8.4/s (PT16 wake) to ~4/s in the swarm.
- **F3. Queens run out.** One queen per 20 s, none once the nests are dead: in PT17 the nests were gone at 34 s, so only 2 queens ever came (PT15 / PT16: 4, nests lasted 83–88 s).
- **F4. The only frenzy damage is the frenzy-sprung trap** (PT17: the 150 frenzy units come out next to the brain, where you stand for the bait). Without it the frenzy is safe (PT15: 0, PT16: 16 HP).
- **F5. Danger comes in bursts:** 70–80 % of all damage in 5–14 seconds (worm / acid hits at the start, one swarm on top of you). The director's 3 s budget never caps anything because the average stays far below it.
- **F6. Fight length is set by the wake:** 65–144 s, mostly the links (55–127 s) and then 1000 brain HP under the queen stream.

### Why the trap struggles to circle you (code + OR-E13 headless, answer to the user, 2026-10-24)

1. **The hive starts on one side.** At the pull-back everything is chasing you, so it's all behind you (towards the brain). A pack for your far side walks **round the ring** (a waypoint every 60°, so it doesn't run through you): at 25–30 tiles that's 80–95 tiles, **7–9 s** for a slowed small biter (~11 tiles/s), most of the 10 s hold.
2. **The ring moves with you.** Spots are around *you* and re-sent only every **3 s** once you moved **8 tiles** (`TRAP_REPLACE*`). Each re-send re-paths every pack; while you move, the far spots move away as fast as the packs walk.
3. **The bait pulls you out of the ring.** Taking the bait means walking 15–25 tiles to the brain through the open road. The ring lags behind, so at the spring most packs are **behind you, 25–40 tiles out**, and arrive one after another: the "dies on arrival" problem again (PT17: 6 touching). The frenzy-sprung trap bit because the 150 frenzy units spawned **next to the brain, where you stood**, plus a ring only 3 s old (still close to the hive's clump).
4. Headless (step 30): lure-taking target at +9 s: packs only in the 4 sectors on the brain side, average **25–29 tiles**, never the 20 it aims for.

So the numbers that help: a **smaller ring** (shorter walk round, shorter charge), and a ring that **follows you more often** (packs stay on you when you go for the bait).

### Targets (user, 2026-10-24)

| # | Target | Now (PT15–17) |
|---|--------|---------------|
| T1 | Fight **~150 s** | 157–231 s |
| T2 | **Spikes on purpose**: surges 1, 2 and the frenzy each have **one moment that really hurts (20–40 HP in ≤ 5 s)**; calm between spikes is fine. End at ~30–100 HP | surges 1–2: 0–31 HP, frenzy 0–71 |
| T3 | **4 queens from the wake** in every fight; queen biters keep coming through the surges | 2–4 queens; queens stall at the cap in the surges |
| T4 | **≤ 2 pull-backs** per fight (as now) | 1–2 |

### Decisions

| # | Topic | Decision |
|---|-------|----------|
| OR-D97 | Fight length | Target **~150 s** (user, 2026-10-24) |
| OR-D98 | Danger shape | **Spikes on purpose**: one 20–40 HP moment per surge (1, 2, frenzy), calm between is fine (user, 2026-10-24) |
| OR-D99 | Queen release | **When the wake starts, all 4 queens come out at once**; then a dead one is replaced **20 s** later while a nest lives. Replaces "1 at the first nest death, then 1 per 20 s" (OR-D78, OR-D88); siege anchor kills no longer release queens (user, 2026-10-24) |
| OR-D100 | Queen cap | **500 → 800** units alive (user, 2026-10-24) |
| OR-D101 | Trap spring | Ring tightens to **12 tiles** (was 20), hold **8 s** (was 10). User also wanted to know why the ring is hard to close (answer above) (user, 2026-10-24) |
| OR-D102 | Frenzy | Surge 3 **150 → 250** units, last stand in the frenzy **×2 → ×3** (user, 2026-10-24) |
| OR-D103 | Length lever | Brain **5000 → 4000 HP** (user, 2026-10-24); pull-backs stay at up to 2 (`REGROUP_GAP` 30 s) |
| OR-D105 | No worms (PT18) | **No worm core** in ring 0 and ring 1 bases (map gen + regrow); ring 2+ unchanged (user, 2026-10-24) |
| OR-D106 | No head crush (PT18) | The brain's head crush (500 impact round the head) **does no damage**, every brain size: not telegraphed (user, 2026-10-24) |
| OR-D107 | Trap before the surge (PT19) | A surge whose threshold falls **during a pull-back** waits until **5 s after the spring** (PT19: trap + encircle surge = 102 touching, dead in 7 s) (user, 2026-10-24) |
| OR-D108 | Frenzy cap (BP-3) | In the frenzy the last stand spawns while fewer than **800** are alive (was 240: PT20's ~580 alive stopped it); surges 1–2 keep 240 *(mine, 2026-10-24)* |
| OR-D112 | Ring 1 done for now (PT23) | PT23 won (194 s, 128 HP left), frenzy felt fine. Stop tuning here; the rest is parked for a **tutorial pass**: once every ring has its kit, revisit rings 0–1 so they teach what later rings need (they may change). Parked: length (the wake gap after the last nest), the frenzy cap counting queen biters, Q42–Q44 (user, 2026-10-24) |
| OR-D109 | Frenzy cap (PT22) | `frenzy_max_alive` **800 → 400**: 740–800 alive held the brain at 20 % for 50 s (user, 2026-10-24) |
| OR-D110 | Shorter (PT22) | Brain **4000 → 3000 HP** (user, 2026-10-24) |
| OR-D111 | Own damage in the log (PT22) | Damage from your own force (grenades) is logged as "own <type>" in the telemetry, outside the director's budget (user, 2026-10-24) |
| OR-D104 | Trap follows you (BP-2) | The ring is also re-sent after **4 tiles / 1 s** (was 8 tiles / 3 s), so the packs stay on you when you go for the bait; part of BP-2 (user, 2026-10-24) |

### Parameter sets (one per PT)

| Set | PT | Parameter | Old → new | Where |
|-----|----|-----------|-----------|-------|
| **BP-1 queens** | PT18 | Queen release | 1 at the first nest death (siege too), +1 per 20 s → **all 4 at the wake start**, then +1 per 20 s while nests live (`QUEENS`, `QUEEN_EVERY` stay 4, 20 s) | `brain-fight.lua` (`update_queens`, `on_nest_died`) |
| | | `QUEEN_CAP` | 500 → **800** | `brain-fight.lua:63` |
| **BP-2 trap** | PT19 | `TRAP_INNER` | 20 → **12** | `director.lua:131` |
| | | `REGROUP_HOLD` | 10 s → **8 s** | `director.lua:140` |
| | | `TRAP_REPLACE`, `TRAP_REPLACE_TICKS` (OR-D104) | 8 tiles, 3 s → **4 tiles, 1 s** (ring follows you to the bait) | `director.lua:135` |
| **BP-3 frenzy** | PT20 | `surges[3].total` | 150 → **250** | `waves.lua:81` |
| | | `frenzy_last_stand` | 2 → **3** | `waves.lua:83` |
| **BP-4 length** | PT21 | Brain `max_health` | 5000 → **4000** | `Hostile-fauna/prototypes/brain.lua` |

Order: queens first (T3 changes the wake and the surges, the base for the rest), then the trap (the spike of surges 1–2), the frenzy, and the length last (it shifts every phase, so judge it on the final danger). After each PT: check T1–T4 in the telemetry, keep or roll back the set.

Headless can't judge: the spikes (the test target kills a fixed number per check), the feel. It can check: queens released at the wake start (4 at once, replacement 20 s, none without nests), the cap (alive up to 800, UPS), the trap radius reaching ~12, the frenzy totals, brain HP.

## Steps

- [x] 1. Ideas + OR-D1–D3 (user, 2026-10-20).
- [x] 2. Verify the pre-oil arsenal (2026-10-23, 2.1.21): `--dump-data` with our mods + headless `tools/ht-oil-ring-test` (brains per ring on 5 seeds, car top speed + run-over, one shotgun shot, grenade). Table filled in. Changed from the draft: defender capsules are pre-oil, pellets do 8 (not 5), the shotgun fires 1.5/s with 10 shots per shell item, turrets and the car gun don't get ×3 (OR-I4), mediums can appear below 720 tiles.
- [x] 3. Q1–Q5, Q7, Q8 answered → OR-D4–D12 (user, 2026-10-23). OR-E1 spec written and approved. Open: Q6 (after PT1).
- [x] 4. **OR-E1** (spec above): ring-1 brain, brain by ring, per-ring phases, siege, shotgun ×3, kit, finder. Headless incl. UPS ✅ (2026-10-23, results above).
- [x] 5. **PT1 (user, in game, 2026-10-23, 2.1.21):** **lost.** Shotgun barely used (SMG felt strong enough). Overwhelmed in the swarm: enemies trap you and you can't move (OR-I5). Game never slowed down (OR-I3 ✅). User likes the swarm overwhelming you (a better player might manage with grenades) but sees no good way to escape. Follow-up headless (2026-10-23): **a grenade at your own feet kills all 48 small biters within ~3 tiles and costs 10.5 of 250 HP** in heavy armor, so an escape exists but isn't obvious or quick.
- [x] 6. **OR-E2** (spec above): director (`scripts/director.lua`), telemetry (`scripts/telemetry.lua`), repulse capsule (`prototypes/item/repulse-capsule.lua`), shotgun reload 20, kit + 10 repulse capsules. Headless ✅ (2026-10-23, 2.1.21, seed 12345, results below).

  | Check | Result |
  |-------|--------|
  | Ring-1 swarm, target in heavy armor that never shoots back (`ht-challenge-test`) | **Director off: 17.5 HP/s avg, 28.2 max, over budget 39 / 40 checks. On: 7.0 avg, 10.7 max, over budget 5 / 40**, budget 8.3. Up to 467 held, ~100 within 10 tiles: still surrounded (7 / 8 sectors) |
  | Ring 0 (no director) | Unchanged |
  | UPS | Ring-1 swarm with director 2.7 ms per tick (~1360 enemy units), without 2.8 |
  | Repulse capsule (scratch test) | 48 small biters around you: within 3 tiles 41 → **0**, avg distance 1.7 → 5.7 tiles, 47 stunned 1 s; back on you ~1 s after the stun |
  | Prototypes | Shotgun cooldown 20, modifier 3; capsule + projectile + `ht-repulse-stun` (60 ticks); `check-paths.py` 2415 paths, 0 missing |
  | Telemetry | CSV per (debug) challenge in `script-output/ht-telemetry/` ✅ |
  | Iterations | 1) cap from touching biters: no effect (arrivals bite before the next check). 2) slots + 14-tile intercept: 10.4 avg, held units stuck in the crowd still bit. 3) 24-tile intercept, stop on failed walk, ring 7–11, brain damage split off: still 11.9, held units kept biting via `by_damage`. 4) wait ignores enemies: on budget |
- [x] 7. **PT2 (user, in game, 2026-10-23, 2.1.21):** **won, far too easily.** The shotgun let you kill the brain before the swarm took effect; even the SMG killed it before the swarm did anything; the swarm didn't feel powerful at all. User: let more enemies attack at once (you kill them, so the damage you actually take stays below what the director plans for); shotgun a bit slower again; brain more HP and/or the swarm earlier in its HP.

  Telemetry (`%APPDATA%\Factorio\script-output\ht-telemetry`):

  | Challenge | Weapon on the brain | Brain 100 → 0 % | After the swarm started | Damage taken | Director |
  |-----------|---------------------|-----------------|-------------------------|--------------|----------|
  | t8 (ring 1) | Shotgun: 2 shell items (20 shots), 7 red mags | ~5 s | **2 s**, brain dead | 0 HP/s | busy, held 5 |
  | t17 (ring 1) | SMG: 22 red mags | ~16 s | **9 s**, brain dead | peak 7.2 (in the siege), 0 in the swarm | busy, **held 148 while you took 0 damage** |
  | t5, t4, t1 (ring 0) | SMG, red ammo + research | 6–33 s | | ≤ 3.6 | (off in ring 0) |

  Diagnosis: (1) the brain dies within seconds of the swarm starting (time-to-kill below); (2) the director throttled the swarm although you took no damage: slots = budget ÷ damage per biter ≈ 6, counted over 24 tiles, so only ~6 units could approach at once, and you shot those before they bit (the user's point).

  **Brain time-to-kill** (`--dump-data` values; research level 2: +20 % damage, +30 % fire rate; brain 50 % physical resistance; the whole shotgun cone hits the brain):

  | Weapon | Per hit on the brain | DPS on the brain | Ring-1 brain (2250) | of which after the swarm starts (60 %) |
  |--------|----------------------|------------------|---------------------|----------------------------------------|
  | SMG, red, ×3 | 8 × 1.2 × 3 × 0.5 = 14.4 | × 13 / s = **187** | **12 s** (PT2: 16 s) | 7 s |
  | Shotgun ×3, reload 20 | 12 pellets × 14.4 = 173 per shot | × 3.9 / s = **674** | **3.3 s** (PT2: ~5 s) | 2 s |
  | Shotgun ×3, reload 40 | 173 per shot | × 1.95 / s = 337 | 6.7 s | 4 s |
  | Shotgun ×2, reload 40 | 115 per shot | 225 | 10 s | 6 s |
  | Grenade | 35 × 1.45 × 0.4 = 20 | 41 (2 throws / s) | 55 s | |
  | Ring-0 reference: SMG, yellow ×3, no research, small brain 1125 | 7.5 | 75 | 15 s | 9 s (PT9: felt right) |

- [x] 8. **OR-E3:** OR-D19–D21 + teleport fix. Headless ✅ (2026-10-23, 2.1.21).
  - Built: ring-1 brain 5000 HP (`brain.lua`), `swarm_at = 0.8` in `PHASES[1]` (`waves.lua`), shotgun ×2 / reload 40 (`Hostile-fauna/data-updates.lua`), director slots (`director.lua`: count within 6 tiles, +2 per check below 60 % of the budget, cut to slots × budget / measured when over, floor = budget ÷ damage per biter, packs of 6), `/ht-goto-ring [ring]` (PT2: the `/c` teleport 60 tiles east could land next to a ring-0 brain; now picks brains by ring and puts you 45 tiles from the brain on the spawn side, inside its territory) + debug call `goto_spot`.
  - Deviation from Q15's draft: when over budget, slots are cut in proportion (slots × budget / measured) instead of −2 per check; with up to 200 slots, −2 per check would take many seconds to react.

  | Check | Result |
  |-------|--------|
  | Prototypes | Ring-1 brain 5000 HP, shotgun cooldown 40 / modifier 2, SMG 3; `check-paths.py` 2415 paths, 0 missing |
  | `/ht-goto-ring` (3 seeds) | Ring 0 and ring 1: spot 44–45 tiles from the nearest brain of that ring, in the brain's territory ✅ |
  | Ring-1 swarm, target never shoots back | Director off 17.5 HP/s avg / 28.2 max; **on 8.3 avg / 10.7 max** (budget 8.3), slots stay at 6–8, up to 266 held |
  | Ring-1 swarm, target kills the 4 nearest units per check (~8/s) | **avg 3.7 HP/s, max 13.8, slots grow to 56**, 181 killed in 20 s: when you kill fast, the swarm comes in |
  | Ring 0, UPS | Unchanged; ring-1 swarm 2.1–2.8 ms per tick |
- [x] 9. **PT3 (user, in game, 2026-10-23, 2.1.21):**
  - Try 1: **lost**, the swarm reached you. "The swarming felt really good": dangerous, a full-on attack, and hard to tell the director was holding it back. "A really good balance of feeling dangerous while not actually being dangerous (even though it was quite dangerous enough)." Damage to the player is about right.
  - Try 2: **won by kiting** the biters, then killing the kite group with ~3 shotgun shells. User doesn't like kiting: it cheats the system; the biters should keep trying to surround you. After the kite group was gone, the group didn't rebuild fast enough.
  - Repulse capsule: a temporary push-back, but it didn't create a real opportunity to do anything.
  - Idea: biters a bit slower (ring 0 too, may need rebalancing there), so you kill more of them as they approach.

  | Telemetry | Lost (t4, 6429) | Won (t4, 19590) |
  |-----------|-----------------|-----------------|
  | Duration | 79 s (swarm 63 s) | 123 s (swarm 105 s) |
  | Damage | 250 → 3 HP over ~36 s, peak 14.2 HP/s, over budget at most 4 s in a row | peak 17.3 HP/s, HP down to 5 at 84 s |
  | Director | slots full / calm cycling, up to 326 held | up to 314 held; at 54–60 s held 176 → 0 (holds expired), then 40 s with 30–70 biters within 10 tiles but almost no damage: the kite |
  | Kills | SMG ~13 / s max (one bullet per small) | same; a grenade volley killed 22 |
  | Note | Grenades / repulse jump 20 → 0 → 12: items in the cursor aren't counted (OR-I9) | |

- [x] 10. **OR-E4:** OR-D22–D26 built (2026-10-23, 2.1.21): `slow = 20` in the phase config (`ht-challenge-slow-20` on every phase unit, ring 0 and 1); repulse push 6 / stun 180 ticks; telemetry counts the cursor; small-family shockwave without `demolisher-ash-cloud-visual-dummy` (edge + slow kept, medium / big untouched); director anti-kite: holding ring follows you (> 8 tiles, 60 per check), rebuild (20 when nothing within 10 tiles), re-surround (every 2 s while you move > 2 tiles per check: up to 40 chasers between 6 and 25 tiles in your trailing half run to points 8–14 tiles around a spot 10 tiles ahead, 40–120° off your heading). Debug switch `antikite = false` on `waves_step`.

  | Headless (seed 12345) | Result |
  |-----------------------|--------|
  | Prototypes | `check-paths.py` 2415 / 0 missing; shockwave stage: edge + stickers, no inner cloud; medium keeps it |
  | Ring-1 swarm, target never shoots | director on: 8.1 avg / 9.3 max (budget 8.3) |
  | Target kills 4 per check | 2.6 avg / 14.0 max, slots up to 69 |
  | **Target kites** (circle r 20, 4 tiles/s, no killing) | Swarm falls behind: 0 units within 10 tiles while 400+ alive. **Anti-kite on: 37 % of the units 8–25 tiles away ahead / beside, off: 30 %**; damage 1.6 HP/s both. Re-surround fires (7–20 units per 2 s) but the units can't get ahead |
  | Kite at 8 tiles/s | Nothing ever catches up (0 damage), on or off |

  Why anti-kite can't work yet: inside the brain's ash cloud a challenge biter runs 0.225 × 0.8 (OR-D22) × 0.45 (`hf-ash-sticker-ally`, E3) = **0.081 tiles/tick (4.9 tiles/s)**; you're capped at 0.15 (9 tiles/s) by `demolisher-ash-sticker`. Outside the cloud: biter 0.18 (10.8 tiles/s), you 0.25 (15). A unit that slow can't cut you off whatever route it gets. Q21.
  - **OR-D27 built** (2026-10-23): `hf-ash-sticker-enemy` (copy of `demolisher-ash-sticker`, no 0.15 cap, ×0.45) replaces the vanilla sticker in the small family's effects (`Hostile-fauna/prototypes/brain.lua`), so in the ring-0 / ring-1 brain's cloud you run 0.1125 and its biters 0.081 (72 %, as outside). Headless: medium / vanilla demolisher clouds unchanged, the test target gets the new sticker, 2417 paths / 0 missing. Kite at your in-cloud speed (6.75 tiles/s): **anti-kite on 1.8 HP/s, 37 % of the swarm ahead / beside; off 3.3 HP/s, 45 %**: re-surround pulls chasers off your tail without getting them ahead; a circle is a crude kite, so PT4 compares in game. `/ht-antikite on|off` switches it (default on).
- [x] 11. **PT4 (user, in game, 2026-10-23, 2.1.21):** won all (ring 1 ×3, ring 0 ×1).
  - Slower biters: not sure you kill more, but it feels fine.
  - Anti-kite on: didn't surround you much; off: you couldn't tell the difference.
  - Repulse capsule: still not liked → **drop it for now**.
  - Shockwave: looks better, could do with even fewer clouds.
  - Ring 0: slightly easier, still fine.
  - You'll always kite around the brain in a rough circle → predict where you're going and put biters there before you arrive.
  - Question: why do you manage to eliminate all enemies by the end?
  - Overall: you need the shotgun to win, and the shotgun is fine. **The final part is too long: the same kite and shoot the brain.** Even if the player resorts to that, keep switching things up; no part should feel like a grind or a slog.

  | Telemetry | t2 (196 s) | t10 (151 s) | t4 (88 s) |
  |-----------|------------|-------------|-----------|
  | Swarm phase | 163 s | 121 s | 72 s |
  | Brain from swarm start to death | 61 → 0 % over ~150 s; **47 → 15 % took 100 s** | 73 → 0 % over ~110 s, mostly shotgun (red stuck at 44 mags from 56 s) | |
  | Enemies alive | 632 peak, **stays ≥ 240 until ~144 s, then 242 → 11** | 585 peak → 2 at the end | |
  | Ammo | red 98 → **0** at 144 s, then shotgun | red 96 → 44, shells 100 → 86 | |
  | Damage | peak 15.2, over budget ≤ 4 s | peak 21.8, ≤ 7 s | peak 13.1, ≤ 3 s |

  Why the enemies run out: the swarm is a fixed 750. The last stand only adds a group while fewer than 240 are alive, and its size is 10 × the share of nests still alive, so with the nests dead it adds nothing. Once the swarm is killed, nothing refills it: it ends as you vs the brain.

- [x] 12. **OR-E5:** OR-D28–D32 built (2026-10-23, 2.1.21).
  - `waves.lua`: `surges` in `PHASES[1]` (80 % surround 350, 55 % encircle 250, 30 % frenzy 150; ring 0 keeps one swarm), spawn mode `encircle` (points on a full ring 16–20 tiles around you, golden-ratio angles), `last_stand_from_brain` (no nest share; out of the brain when the nests are gone), frenzy: last stand ×2 and an extra shockwave every 20 s (script plays the 30 stages, one per 10 ticks, `every(10, waves.on_pulse_tick)`, source = the brain's head entity). `/ht-challenges` shows the surge.
  - `director.lua`: re-surround replaced by **intercept**: angle around the brain, angular speed; circling > 2 tiles/s along the circle for 3 s → every 2 s up to 15 units within 30 tiles of the spot where you'll be in 4 s walk there (nothing spawns). Follow + rebuild unchanged.
  - Telemetry: + surge, swarm_left, nests, intercepted. Shockwave (small family): edge puffs halved (stage 1: 12 → 6), no idle ash trail on the small / ring-1 brain. Repulse capsule deleted (prototype, locale, kit, telemetry).

  | Headless (seed 12345) | Result |
  |-----------------------|--------|
  | Prototypes | 2397 paths / 0 missing; no repulse capsule; medium brain keeps its trail and puffs |
  | Surges | 75 % → surge 1, 50 % → surge 2 (encircle), 25 % → surge 3 + frenzy, each with its message ✅ |
  | Never run dry | All nests dead at the clear: last stand keeps coming, **20 every 2 s** (frenzy ×2) out of the brain ✅ |
  | Frenzy pulse | Script-played shockwave stages near the brain ✅ |
  | Director | 8.0 HP/s avg (budget 8.3); director off 17.0 |
  | **Kite around the brain** (35 tiles, 6.75 tiles/s) | **Intercept on: 35 % of the swarm ahead / beside, 2.7 HP/s; off: 20 %, 1.5 HP/s.** Packs of 15 most of the time |
  | Ring 0 | Unchanged (with all nests dead its last stand stops, as before) |
  | UPS | 2.3–3.2 ms per tick |
- [x] 13. **PT5 (user, in game, 2026-10-23, 2.1.21):** ring 1 won (t10, 167 s); ring 0 lost afterwards (`/cheat-kit ring0`, t5).
  - The three surges **don't really break up the fight**.
  - You can't kite anymore, but the enemies **feel like they walk around randomly**. Wanted: movement that looks strategic, as if the brain is thinking.
  - **The end still drags**: the long kite-and-shoot-the-brain part.
  - Shockwave looks fine for now. Later idea: a constant area effect during the fight (psychic aura, moss / fungus) instead of on/off pings. Needs new art → roadmap fog.
  - Numbers (damage budget, HP, counts) seem fine. **The feel is what's off.**

  | Telemetry t10 (ring 1, `807-t10.csv`) | Value |
  |---------------------------------------|-------|
  | Phases | siege 8 s, wake 10 s, swarm 150 s (surges at 18 s / 96 s / 135 s) |
  | Damage | 249 → 133 HP, **almost all of it at 36–57 s** (peak 13.3 HP/s, ≤ 4 s over budget). **From 60 s to the end (107 s): ≤ 1 HP/s** |
  | Director | held units only at 39–57 s (max 45); **0 held from 60 s on**, state "busy" with ~0 HP/s: you kill everything before it arrives, the director has nothing to do |
  | Brain | 71 % flat from 24 to 72 s, 61 % at 84–93 s, 43 % at 99–120 s, then 28 → 6 % in the last 30 s: you clear the adds, then burst the brain, repeat |
  | Ammo | red 100 → 42 (all used by 57 s), then **shotgun only**: 21 shell items (210 shots) in 110 s |
  | Alive | 60–300, 10–88 units within 10 tiles, rarely touching |

  Ring 0 (t5, `14733-t5.csv`, no armor in the ring-0 kit): lost 100 HP at 15–17 s in the **wake** (peak 31 HP/s ≈ 3 unarmored small biters at 12 HP/s each), swarm at 27 s (brain 55 → 35 % in 2 s), HP 149 at 29 s. **The CSV ends at 29 s** with no death line and no summary: the rows after the last 30-s flush were never written (game closed before the challenge was lost?). Likely: the swarm caught you at 149 HP, unarmored; ring 0 has no director. → OR-I11.

  Diagnosis:
  1. **Danger is front-loaded.** Surge 1 is the only real threat; surges 2 and 3 arrive into a player who already kills faster than units arrive. They differ in route, not in what you have to do.
  2. **"Random" movement has a concrete cause:** flank and encircle waypoints are fixed **at spawn**, around where you were then (`waves.lua` `flank_route`, encircle spot). You move, so units walk to stale points, then turn. Guards wander. The holding ring hardly ran after 60 s.
  3. **The drag is a loop, not a length:** clear adds → shoot brain → next surge, with no change in what the brain does.
- [x] 14. **Brainstorm (user, 2026-10-23):** options A (brain end: anchor nests, openings, reactions, shorter), B (surge beats: lull + warning, different jobs, built against your weapon), C (movement: re-plan, squads, herding, react to you), and common patterns from top-down boss fights. Picked → OR-D33–D40; OR-E6 spec written (above).
- [x] 15a. Q27–Q30 answered → OR-D41–D45 (user, 2026-10-23). Queens + anchor ring drafted as OR-E8 (after PT6).
- [x] 15. **OR-E6** (spec above): go-ahead (user, 2026-10-23); built + headless ✅ (2026-10-23, 2.1.21, seed 12345).
  - Files: new `scripts/brain-fight.lua` (shield, openings, guard-rush trigger, rocks, stats); `director.lua` rewritten around squads (holding ring, follow and intercept removed; slots, budget, rebuild kept); `waves.lua` (`squads`, `shield` in `PHASES[1]`, surge units, encircle units handed to the director); `challenge.lua`, `control.lua` (`on_segmented_unit_damaged`, debug `waves_step` returns shield / squads / closing / rocks / slot error); `telemetry.lua` (new columns, flush on death: OR-I11); `docs/commands.md`; `tools/ht-challenge-test` (results `or-e6-result.txt`, `or-e6-ups.txt`).
  - Deviations from the spec:
    - **Closing ring centre stays fixed** where you stood when it formed (spec: "centred on you each time"): a ring that follows you can't be broken out of. Leave it (> radius + 3 tiles) and it breaks up into squads ("You broke out of the ring!").
    - **Re-openings need 8 s shut first**, otherwise a thin trickle keeps the brain open for good.
    - **A charge sends at least 12 in total**: at the swarm start only ~6 slots are free, which is 2 biters per squad, not a charge. Reactions send at least 8 per squad, even over the slots.
    - **E6-1 re-plan = recruiting:** every challenge unit within 40 tiles that isn't on you joins a squad (squads follow you). Units further out still walk their route from spawn until they're in range.
    - **No "fast" frenzy squads** (beats table): would change the speed numbers (OR-D40).
    - Shield shown as a ring on the ground around the brain (blue shut / red open): segments have no runtime tint.
    - Rocks are vanilla `huge-rock`: mining one (3 s) gives 24–50 stone + coal. Own loot-free rock later if it matters.
    - `/ht-antikite off` now means: squad slots stay where they were first placed.
    - Test timeline for ring 1 is longer (surge 3 at +32 s, clear at +40 s, was +14 / +20 s), so the ring has time to close; ring-0 averages run over a longer window too.

  | Headless (seed 12345) | Result |
  |-----------------------|--------|
  | Shield | 200 damage on the brain: **20 lost while shut** (surge 1), **200 after breaking surge 1** (opening), **200 in the frenzy** ✅ |
  | Openings | 2 per run: after killing 80 % of surge 1, and the frenzy. No re-opening (too many units near the target) |
  | Squads, target never shoots | Form → ready → tell → charge works: **44 charges (314 units), 11 from 2+ squads at once**; up to 448 units waiting in squads |
  | Director budget | Never shoots: **8.2 avg / 11.2 max** (budget 8.3), over budget 40 of 80 checks (OR-E5: 8.0 avg; charges overshoot briefly). Kills 4 per check: 1.3 avg, slots up to 151. Director off: 17.2 |
  | Reactions | Guard rush 2 (from the probes on the brain); stand-still 8 when the target stands still, **0 when it kites** ✅ |
  | Closing ring | Standing target: 250 units at 16 tiles, closing from 44.5 s, 16 → 8, then charged at 6 ✅. Kiting target: breaks out at once (stays 16) ✅ |
  | Rocks (frenzy, kiting) | 3 placed, at most 2 walls; nearest to the target **4.8 tiles** (≥ 4), at most **34°** of the circle covered (≤ 90°), none left past 15 s ✅. Standing target: no rocks (no heading) ✅ |
  | Slot error (members' distance from their role's slot now) | Standing 8.2 tiles; **kiting: re-placed 29.1 vs stale 34.2**; units ahead or beside 34 % vs 28 %. A target kiting at in-cloud speed (6.75 tiles/s) still outruns biters (4.9) and takes ~0 damage headless; PT5 says kiting no longer works in game, so PT6 decides |
  | Ring 0 | Same spawns as before (270); no squads / shield (ring 0 has no `squads`) ✅ |
  | UPS | Ring-1 swarm 1.3–1.6 ms per tick (~1030 enemy units); baseline 1.9 |
- [x] 16. **PT6 (user, in game, 2026-10-23, 2.1.21):** won (t3, 248 s; kit with 200 red, OR-D46).
  - **The surges feel different** ✅.
  - **Movement looks planned** ✅, but **kiting feels feasible again**. It always was; random movement just made it feel less like a cheat. Still better than the start.
  - **Openings are fine, but unlocking the brain felt like a slog**: it wasn't clear what unlocks it. At times few biters were on screen and the shield was still up. Idea: **shield units that must be killed**.
  - **Rocks felt irrelevant at best.** Do way more with them, and leave them in place.

  | Telemetry t3 (`1908-t3.csv`) | Value |
  |------------------------------|-------|
  | Phases | siege 7 s, wake 12 s, swarm 230 s; surges at 19 s / 146 s / 200 s |
  | Surge 1 | **127 s**, brain 79 → 72 %. Shield shut 19–67 s (48 s), open 67–75 s (brain −1 %), **shut again 75–141 s (66 s)** |
  | Why | The re-opening needs < 15 challenge units within 25 tiles, but the squads keep 70–150 units waiting within ~12 tiles of you. **The director keeps units alive near you; the shield wants them dead** |
  | Openings | 5: 67 s, 141 s (72 → 54 %), 159 s (surge 2 broken), 196 s (45 → 28 %), 200 s (frenzy, open for good) |
  | Danger | HP 250 → 128 over the whole fight, peak 11.9 HP/s, ≤ 3 s over budget; director "calm" almost all the time |
  | Squads | 164 charges (1749 units), 20 guard rushes, 2 stand-still punishes; closing ring up to 117 units, then you got out |
  | Frenzy | 48 s with 30–90 alive, brain 28 → 3 % |
  | Rocks | 14 placed in the frenzy |
  | Ammo | red 200 → 153 (none used after 56 s), shells 100 → 64 |
- [x] 16a. PT6 options discussed → OR-D47–D52 (user, 2026-10-23). OR-E7 spec written. Queens + anchor ring renumbered to OR-E8.
- [x] 17. **OR-E7** (bearers, regroup, rocks that stay; spec above): go-ahead (user, 2026-10-23: "sounds okay to test"); built + headless ✅ (2026-10-23, 2.1.21, seed 12345).
  - Files: `prototypes/entity/challenge-units.lua` (`ht-shield-bearer`) + locale; `scripts/brain-fight.lua` (bearers, shield rule, lure, rocks from surge 1 that stay, arena); `director.lua` (regroup, bearers / pulled-back units left alone); `waves.lua` (`waves.surround`; OR-E6's surge-unit tracking removed); `telemetry.lua` (bearers, regroup, regroups, arena); `control.lua`; `docs/commands.md`; `tools/ht-challenge-test` (+ a run where the kiting target takes the lure; results `or-e7-result.txt`, `or-e7-ups.txt`).
  - Deviations from the spec:
    - The bearer lives in **Hostile Territory** (`ht-shield-bearer`, next to `ht-tiny-biter`), not Hostile-fauna: it's a challenge unit.
    - Bearers **appear at their spot** and **don't fight** (distraction none): walking out of the brain, one took the long way round through the base and ended up 22 tiles out; with `by_enemy` they chased you from their 30-tile vision.
    - **Regroup trigger:** "units deal you < 25 % of the budget" (3 s window) instead of "< 3 biters within 6 tiles" (one moment with 3 close reset the 5 s, so a kite never triggered it), plus **≥ 20 enemy units within 25 tiles** (otherwise it fired right after a surge started, while the swarm was still on its way). `/ht-antikite off` switches the regroup off too.
    - Arena spots that don't fit (nests, worms, water) are left out, so there are more and wider gaps than 4 (below).
  - Headless:

  | Check | Result |
  |-------|--------|
  | Prototype | `ht-shield-bearer` 375 HP, speed 0.138, big biter resistances; `check-paths.py` 2457 / 0 missing ✅ |
  | Bearers | 3 per surge (1 and 2), 2.9–9.3 tiles from the brain ✅ |
  | Shield | 200 damage on the brain: **20 lost** with surge 1's bearers alive, **200** after killing them (open until surge 2), **20** with surge 2's new bearers, **200** in the frenzy ✅ (every run) |
  | Regroup | Kiting target: **90 % pulled back** (495 of 553), re-swarm after 20 s (target stays 35 tiles out). Target that takes the lure: 2 regroups, **re-swarm when it came within 24 tiles** both times. Standing / killing targets: none. `antikite off`: none ✅ |
  | Rocks | From surge 1, still standing at the end (34 of 34; one run 35 of 36). At placement: nearest **4.2 tiles**, at most **46°** of the circle covered ✅ |
  | Arena | 25–33 rocks on a ring of ~22 tiles; every run has **4+ gaps of 4–14 tiles** ✅ |
  | Director budget | Never shoots: 8.4 avg / 11.9 max (budget 8.3); kills 4 per check: 4.7 avg |
  | Ring 0 | Unchanged (270 spawned, 15.4 avg) ✅ |
  | UPS | Ring-1 swarm 2.1–2.9 ms per tick (~1030–1370 enemy units) |
- [x] 18. **PT7 (user, in game, 2026-10-23, 2.1.21):** won (t11, 242 s).
  - **It's clear that the bearers unlock the brain** ✅.
  - The regroup didn't work as much as expected: **you never felt the lure**.
  - The rocks change how you move, but they're **one parameter too many** for now: keep the arena, switch the other rocks off (OR-D54).
  - New: the brain should start its shockwave as soon as one nest is destroyed in the siege (OR-D55).

  | Telemetry t11 (`1381-t11.csv`) | Value |
  |--------------------------------|-------|
  | Phases | siege 13 s, wake 8 s, swarm 222 s; surges at 21 s / 104 s / 202 s |
  | Bearers | Surge 1: 21 → 93 s to kill all 3 (brain open 93–104 s, 75 → 53 %). Surge 2: 104 → 181 s |
  | Regroup | **6 regroups** (40, 80, 115, 145, 175, 232 s), **each over in < 1 s**: you kite within 25 tiles of the brain and keep shooting it, so the re-swarm triggered the moment the hive pulled back → OR-D53 |
  | Rocks | 25 wall rocks, 33 arena rocks |
  | Danger | HP 250 → 62, peak 10.5 HP/s, ≤ 3 s over budget |
- [x] 18a. **OR-D53–D55 built** (2026-10-23, 2.1.21): `director.lua` (`REGROUP_HOLD` 6 s, `REGROUP_LURE` 15, no re-swarm on a hit), `waves.lua` (`rock_walls = false`, `wake_on_nest = true` in `PHASES[1]`), `brain-fight.lua` (walls only with `rock_walls`), `challenge.lua` (`on_nest_died`), `control.lua` (`on_entity_died` also for nests). Headless ✅ (seed 12345, `or-e7b-result.txt`): ring 1 goes to **wake right after its first nests die**, ring 0 stays in siege; the lure-taking target re-swarmed **7 s after the pull-back, 14 tiles from the brain**; the kiting target after 20 s; no wall rocks, arena 26–34 rocks; director 8.5 HP/s avg (budget 8.3); ring 0 unchanged.
- [x] 18b. **PT8 (user, in game, 2026-10-23, 2.1.21):** **died** at 155 s (t15; user: probably an oversight on their end).
  - **Still don't feel the lure.** Try **100 % pull back** (OR-D56).
  - **Early wake is perfect**: it feels much smarter that the brain takes over directly ✅.
  - Arena is fine-ish: **a bit bigger** (OR-D57).

  | Telemetry t15 (`1266-t15.csv`) | Value |
  |--------------------------------|-------|
  | Phases | siege 1 s (the first nest woke the brain, OR-D55 ✅), wake 21 s, swarm from 22 s; surges at 22 / 83 / 148 s |
  | Lure | 3 regroups that **now hold**: 49–69 s (20 s, ran out), 99–115 s (16 s), 148–154 s (6 s) |
  | Bearers | Surge 1: 22 → 74 s; surge 2: 83 → 129 s |
  | Death | 154 s: 101 HP, 14–23 biters touching, 0.5–0.9 HP/s; 155 s: dead. 100+ HP in under a second doesn't fit small biters in heavy armor (~1.2 HP/s each): most likely a hit by the brain itself (9 % HP, frenzy, you next to it). Not confirmed |
- [x] 18c. **OR-D56, OR-D57 built** (2026-10-23, 2.1.21): `REGROUP_KEEP` 0 (`director.lua`), `ARENA_RADIUS` 28 (`brain-fight.lua`). Headless ✅ (seed 12345, `or-e7c-result.txt`): regroup pulls back **100 %** (600 of 603 units; the 3 left are the bearers), lure-taking target re-swarmed 7 s later at 14 tiles; arena 38–42 rocks on a ring of ~27.5 tiles, 4+ gaps of 4–16 tiles every run; director 8.5 HP/s avg.
- [x] 18d. **PT9 (user, in game, 2026-10-23, 2.1.21):** **died** again (t2, 145 s).
  - The **shield bearers pack more damage**; this may explain the PT8 jump too. Not necessarily bad (OR-D60).
  - You **kind of feel the lure, but not entirely right.** At one point 2 biters stayed after you, and the lure may have ended when you killed them (or that was just a feeling). The pull-back shouldn't crowd around the base: **pull back in ~8 directions around you** (minus where you're predicted to go), so after the bait they're already set to surround you (OR-D58).
  - **Arena at 28 tiles is fine for now** ✅.

  | Telemetry t2 (`7477-t2.csv`) | Value |
  |------------------------------|-------|
  | Bearers | 60–62 s: −35 HP with only 1–2 units touching while the hive was pulled back: the bearers you were killing |
  | Lure | 55–75 s (20 s, ran out), 106–121 s (15 s); you never came within 15 tiles, both ended on time. The "2 that stayed": the last-stand trickle kept spawning at the brain during the lure, and the squads sent it at you |
  | Death | 145 s: 66 HP, 12 touching, 2.1 HP/s, dead within the second: same pattern as PT8, cause unknown → OR-D59 |
- [x] 18e. **OR-D58, OR-D59 built** (2026-10-23, 2.1.21): `director.lua` trap: one **unit group** per direction (8 at 45°, 0 towards the brain; within 40° of the brain or your heading left open), 30 tiles around you, equal shares, walking round you (waypoints every 60°), re-sent when you moved 8 tiles (at most every 3 s); new units join the groups; spring = groups disbanded, every unit charges; `director.disband` on won / lost / debug reset. `waves.surround` removed (unused). Telemetry `max_hit`, `max_hit_by`, death line with the 5 biggest hits of the last 3 s.
  - Iterations (headless): (1) per-unit commands, nearest direction: everyone waited in the 1–2 directions next to the brain (they come from there); (2) equal shares + routes round you: units still didn't get anywhere while the target kited (600 re-paths every 2 s); (3) unit groups: spread out.
  - Headless ✅ (seed 12345, `or-e7d-result.txt`): target that takes the lure, 6 s after the pull-back: **470 of 809 units 22–38 tiles from it, in 5 directions** (sector counts towards the brain → round: 174 134 22 76 2 3 1 58; the brain sector still holds units on their way), trap sprang 7 s after the pull-back at 14 tiles from the brain. **Kiting target: the groups can't set up** (48 of 600 in the band): biters run 4.9 tiles/s in the ash cloud vs your 6.75, so a trap 30 tiles out only forms once you stop running for the bait. Telemetry hit columns filled (`small-biter`). Director 8.5 HP/s avg; ring 0 unchanged; 2.0–2.9 ms per tick.
- [x] 18f. **PT10 (user, in game, 2026-10-23, 2.1.21):** won (t12, 229 s), but **useless for balance**: a **cliff right next to the brain** gave a huge chokepoint and easy defence. "An interesting fight." The **end frenzy still felt slightly challenging**; the rest was fun, but not the biggest challenge. Retest on normal ground → PT10.2.

  | Telemetry t12 (`5986-t12.csv`) | Value |
  |--------------------------------|-------|
  | Chokepoint | 18–180 s: **HP flat at 214, 0 biters touching**, steady ~13 kills/s (the SMG's maximum, one bullet each) |
  | Ammo | **All 200 red magazines used** (0 at 180 s); brain at **1 %** from 174 to 228 s; 2 shells used |
  | Bearers | Surge 1 dead in 15 s, surge 2 in 32 s (from the safe spot) |
  | Trap | Only 1 regroup before the end (186 s); it sprang at 193 s: **80 touching, 20.5 HP/s**, the peak of the fight. Second at 223 s |
  | Hits | Worm 22 (wake); otherwise small biters |
- [x] 18g. **PT10.2 (user, in game, 2026-10-23, 2.1.21):** won (t2, 163 s, no deaths).
  - **You felt the lure; it worked pretty well like this.** Maybe hold it even longer to make it more enticing (OR-D64).
  - **The 3 stages feel more distinct now** ✅.
  - The **frenzy may still be a bit too easy**: you can keep shooting the brain with the shotgun and win (maybe luck on this run).

  | Telemetry t2 (`11631-t2.csv`) | Value |
  |-------------------------------|-------|
  | Phases | siege 2 s, wake 23 s, swarm 139 s; surges at 25 / 94 / 151 s |
  | Lure | 53–65 s (12 s; you killed the last surge-1 bearer during it), 108–115 s (7 s), 156–163 s |
  | Danger | HP 250 → 173, peak 9.6 HP/s (surge 1's charges, 42–46 s) |
  | Frenzy | **151 → 163 s (12 s), brain 28 → 2 %** (~1400 HP at ~120 HP/s, shotgun). A **regroup fired inside the frenzy** (156 s): the hive pulled back while the open brain took free shots → not just luck (OR-D65) |
- [x] 18i. **OR-D64, OR-D65 built** (2026-10-23, 2.1.21, `director.lua`): `REGROUP_HOLD` 10 s, `REGROUP_MAX_TICKS` 25 s; no regroup while `record.frenzy`; a running trap springs when the frenzy starts. Headless ✅ (seed 12345, `or-e7e-result.txt`): lure-taking target springs the trap **10 s** after the pull-back (10 tiles from the brain); the kiting target's trap **sprang at the frenzy** (brain set to 25 %); no regroup in the frenzy any more (the lure run had a second one at 71 s before). The trap's spread 6 s in varies between runs (2–5 directions with 5+ units). Director 8.5 HP/s avg; ring 0 unchanged.
- [x] 18j. **PT11 (user, in game, 2026-10-24, 2.1.21; was called PT10.3):** won (t5, 314 s, no deaths).
  - **The lure is enticing** ✅.
  - **The frenzy could be harder.**
  - Didn't find a good chokepoint to test (PT10.4 still open).
  - Overall: **the balance still doesn't feel good**, but each phase now feels distinct to some degree.

  | Telemetry t5 (`5306-t5.csv`) | Value |
  |------------------------------|-------|
  | Phases | siege 2 s, wake 28 s, swarm 285 s; surges at 30 / 167 / 284 s. **314 s in total** (PT10.2: 163 s) |
  | Danger | **Front-loaded**: 250 → 151 HP in the wake (worm acid, peak 22.2 HP/s at 22 s), → 67 by 60 s (surge 1 charges). Then **64 → 50 HP over 250 s**: the rest of the fight was safe |
  | Lure | **7 pull-backs** (76, 116, 156, 196, 240, 246, 250 s): you kept kiting, the brain kept luring; the fight dragged on |
  | Bearers | Surge 1: 30 → 53 s; surge 2: 167 → 250 s |
  | Frenzy | 284 → 314 s (30 s), brain 27 → 0 %, ~0 damage taken |
  | Choke | Never seen (open ground) |
- [x] 18h. **OR-E9** (chokepoint reaction, spec above): go-ahead (user, 2026-10-23); built + headless ✅ (2026-10-24, 2.1.21, seed 12345).
  - Files: `director.lua` (kill log, `update_choke`, choke slots / charges, learning), `control.lua` (`on_entity_died` → `director.on_unit_died`, `waves_step` returns choke + blocked), `telemetry.lua` (`choke`, `choke_dir`, `blocked`), `docs/commands.md`, `tools/ht-challenge-test` (2 runs: target in a ring of rocks with a 60° gap towards the brain, and with a second gap behind; it kills 8 per check; results `or-e9-result.txt`, `or-e9-ups.txt`).
  - Deviations from the spec / iterations (headless):
    - **Kill zone counts only attacking units** (not squad / trap / ring members): you shoot waiting units over the cliff too, all around; with every death the gap's arc held only 35–55 %.
    - **Calm = 10 s average** of the units' damage **< 35 %** of the budget (spec: < 25 % the whole time; one moment over reset it).
    - **Waiting slots during a choke are 22 tiles out** (all of them, not 12): at 12 you'd shoot them over the cliff.
    - **Learning "no way round":** a squad also counts as blocked when ≥ 5 of its charging units die in the choke arc (≥ 60 %): with the rocks closed all round, the "way round" still led through the gap.
    - **Recruits from 3 × 40 tiles** while choked: units spawned further out walked their spawn route straight into the choke.
    - **The choke ends** when you move 10 tiles, or after **30 s** without a kill zone (spec: 10 s): the zone goes away *because* the brain stops feeding it.
    - "The hive comes around!" fires once charging units die within 6 tiles of you outside the arc. Known false positive in the one-gap test: units that came *through* the gap spread round inside the rock ring.

  | Headless (seed 12345) | Result |
  |-----------------------|--------|
  | Detection | One gap: choke at **44 s, 179°** (brain at 180°); two gaps: 44 s, 184°. **7 open-ground runs: no choke** ✅ |
  | Stop feeding | Attackers dying in the choke arc per 15 s: one gap **128–131 → 37–43**; two gaps **111 → 14–34** (down ~70–85 %, not to 0: units already charging, plus the last stand) |
  | Long way round | Two gaps: **49 unit-checks inside the ring from behind**; one gap: **0**. 5 squads learned "no way round" in both |
  | Damage | One gap 0.5 HP/s avg, two gaps 1.3 (target kills 8 per check) |
  | Rest | Director, trap, bearers, nest wake, arena as before; ring 0 unchanged; 1.5–3.0 ms per tick |
- [ ] 18k. **PT10.4 (user, in game):** find a cliff / water choke next to a ring-1 brain (the cliff count command) and hold it: does the brain stop feeding ("The hive won't walk into your guns.") and come round? **Open** (PT11 found no choke).
- [x] 18l. **Retro** (2026-10-24, below). This session ends here. Next: a new session for **OR-E8** (extra ring of anchor nests + queens / spawners), started from the OR-E8 draft and Q31–Q34.

## Retro (2026-10-24, after PT11)

The ring-1 brain-fight work from PT5 (2026-10-23) to PT11 (2026-10-24): OR-E6 (squads, shield, closing ring, reactions, rocks), OR-E7 (shield bearers, regroup, arena) + its follow-ups OR-D53–D60, OR-E9 (chokepoint).

**Where we are.** The three surges feel distinct (PT6, PT10.2), movement looks planned (PT6), the bearers make the unlock clear (PT7), the early wake feels smart (PT8), the lure is enticing (PT11). **Balance still doesn't feel good**: danger is front-loaded (wake + surge 1), the middle and the frenzy are safe, and fights got long (PT10.2 163 s, PT11 314 s, with 7 pull-backs).

**Went well**
- Every PT was read from telemetry first, and that found concrete causes the feel alone didn't: stale spawn waypoints (PT5), the director keeping alive the units the shield wanted dead (PT6), every lure taken instantly (PT7), the last-stand trickle spawning at the bait (PT9), the lure firing inside the frenzy (PT10.2), the cliff choke (PT10).
- The headless test caught problems before the user played: bearers chasing from 30 tiles, a regroup trigger that never fired, the trap clustering next to the brain, 600 units re-pathing and going nowhere (→ unit groups), a choke detector fooled by shots over the rocks.
- Short loop: small decisions per PT, built and tested the same day.

**Went less well**
- **Too many mechanics changed per PT**, so balance couldn't be judged (the opposite of OR-D6's "few parameters at once"). Rocks were built twice and then switched off (PT7).
- **The headless target isn't a player**: it teleports through rocks that stay, never shoots (or kills a fixed number per check), and kites faster than biters can follow. The trap vs a kiting target and the rock safety could only be measured indirectly.
- **Two deaths went unexplained** (PT8, PT9) until the death log (OR-D59); the cause still isn't confirmed.
- **One PT was lost to terrain** (PT10 cliff): there's no way yet to pick a "neutral" brain for balance tests except the cliff count command.
- Tooling slips: shell heredoc quoting and patch scripts failing on rewrapped comments cost several retries; the plan file grew long (steps 13–18l).

**For next time**
- **OR-E8 (queens + anchor ring)** next, in its own session: one mechanic at a time, a PT after each.
- Then a **balance pass on its own** (no new mechanics): fight length, danger after surge 1, a harder frenzy, how many pull-backs a fight may have.
- Keep a **neutral test brain** per seed (no cliffs / water within 50 tiles), so PTs compare.
- Make the headless target more player-like where it matters (walks, collides, shoots a fixed DPS), or mark which results it can't judge.
- Consider moving PT1–PT9 detail into an archive section so the plan stays readable.
- [x] 19. **OR-E8 spec** (above): Q31–Q34 answered → OR-D66–D73 (user, 2026-10-24). User has reviewed the OR-E6 / E7 / E9 working tree (2026-10-24).
- [x] 20. **E8-A** (anchor ring + shield link, spec above): go-ahead (user, 2026-10-24); built + headless ✅ (2026-10-24, 2.1.21, seed 12345).
  - Files: `brain-bases.lua` (`hostile_base_anchor_*` noise, biter spawner autoplace + anchors), `regrow.lua` (anchor slots, ring ≥ 1, after the inner base), `oil.lua` (`SPOT_DISTANCE` 56), `challenge.lua` (`SIEGE_REACH` 36; wake still 30), `waves.lua` (`anchor_link = 0.5` in `PHASES[1]`), `brain-fight.lua` (`find_anchors`, lines, `brain_fight.take`, refund in `on_damaged`, "anchors are down" message), `telemetry.lua` (`anchors`, `brain_take`), `control.lua` (`waves_step` returns anchors + take), `docs/commands.md`. Tools: new `tools/ht-anchor-test` (`or-e8a-result.txt`), `ht-map-check` counts nests up to 36 tiles from a base point as part of the base, `ht-challenge-test` rerun (`or-e8a-result.txt`, `or-e8a-ups.txt`).
  - Clarification of A7: "open" includes **before surge 1** (siege, wake: the brain had no shield there), so with all anchors alive the early brain also takes 50 %.

  | Headless (seed 12345) | Result |
  |-----------------------|--------|
  | Map gen | Ring 1: **5 of 7 bases 4 anchors**, 2 with 3 (one slot on water, one lost to a forest at a chunk edge; regrow doesn't clear trees). Anchors at **31.4–32.5 tiles**, all biter spawners. Ring 0: **0 anchors**. Inner nests as before (4–7), nothing at 25–29 / 36–45 |
  | Oil | Spot 57.5 tiles from its brain, 6 wells, **no nest within 20 tiles of a well** |
  | Regrow | A destroyed anchor is **back on its tile** after 3 rounds |
  | Shield link | Siege record: a 200 hit costs **100 / 150 / 200 HP with 4 / 2 / 0 anchors** ✅ |
  | Wake | Killing anchors in the siege: **still siege** ✅; then one inner nest: **wake** ✅ |
  | Regression (`ht-challenge-test`, 9 runs) | Shut probe 20 HP (unchanged); open and frenzy probes **200 → 100** (anchors alive, as specced); director 8.2 HP/s avg (budget 8.3); chokes at 52 / 44 s, came round only with 2 gaps (as OR-E9); ring 0 unchanged; 1.6–3.4 ms per tick |
  | Can't judge headless | The **siege start on an anchor hit** (needs a player); whether the lines read in game; whether clearing anchors in the siege feels like a choice; fight length |
- [x] 21. **PT12 (user, in game, 2026-10-24, 2.1.21):** anchors spawn **around ring-1 brains and not ring 0** ✅. Still unsure about the balance overall. **Bearers and anchors feel like two mechanics trying to do the same thing**, and bearers appearing from nowhere felt off. User idea: blue lines from the anchors to the brain, a dying anchor spawns a bearer → OR-D74–D77, E8-A2 specced.
- [x] 21a. **E8-A2** (anchors are the shield links, spec above): go-ahead (user, 2026-10-24); built + headless ✅ (2026-10-24, 2.1.21, seed 12345).
  - Files: `brain-fight.lua` (links: `find_anchors`, `release_bearer`, `walk_in`, `update_bearers`, `links_alive`, shield from the start; `spawn_bearers` and the 50 % rule gone), `control.lua` (`on_entity_died` for nests → `brain_fight.on_nest_died`; `waves_step` returns links + bearer spots), `waves.lua` (`anchor_link` gone), `telemetry.lua` (`links`), `docs/commands.md`. Tools: `ht-anchor-test` rewritten for links (`or-e8a2-result.txt`), `ht-challenge-test` kills the anchors + their bearers at its old bearer step and puts the anchors back at each run's start (runs reuse brains) (`or-e8a2-result.txt`, `or-e8a2-ups.txt`).
  - Deviation: **walk-in fallback.** One bearer's path to its spot went all the way round the brain (spot behind the brain's body / worms). Now a bearer still walking after **12 s** gets a new spot 6–10 tiles in on the side it's on; after another 12 s it holds where it is.

  | Headless (seed 12345) | Result |
  |-----------------------|--------|
  | Links at start | 4 links (anchors), **shut from the siege**: a 200 hit costs **20 HP** |
  | Bearer from an anchor | Appears **at the anchor** (36 tiles), walks in on its side: **10.1 tiles after ~6 s**. Of the other 3, two reach **10.4–11.3** tiles (~12 s), one gets stuck ~20 tiles out on the far side (re-spotted, then holds) |
  | Shield | Shut (20) until all anchors **and** bearers are dead, then **open for good (200)**, also in surge 1, surge 2 and the frenzy; **no bearers at surges** |
  | Wake | Anchors killed in the siege: still siege; an inner nest: wake ✅ |
  | Regression (`ht-challenge-test`) | Shut probe 20 while links live, 200 after; director 8.4 HP/s avg (budget 8.3); ring 0 unchanged; chokes at 44 s; 1.6–3.1 ms per tick. One-gap choke run says "came round: true" with **0** units from behind: the known false positive (OR-E9 notes) |
  | Can't judge headless | Whether "break the links" reads as a boss phase, whether the walk-in looks natural, fight length / balance (PT11: the wake was the most dangerous part, and the link phase now overlaps it) |
- [x] 21b. **PT12.2 (user, in game, 2026-10-24, 2.1.21):** **links feel okay** ✅. Consequence: you **kill all nests before the next stage** comes. The siege has a **limited number of biters** (code: no director before the swarm, siege / wake groups shrink with the nests alive, so clearing the nests dries them up). User: the director should keep watching damage per second but otherwise **keep up the pressure**; with damage capped anyway, try **more biters**, e.g. a near-continuous stream in the frenzy; but **queens first** → OR-D78–D81, E8-B respecced.
- (21b test plan, done) links = phase 1. **New map** (or run the regrow command until the anchor count says 4). `/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and no cliffs. Check:
  - Do the 4 blue lines read as "these shield the brain"? Does hitting an anchor start the siege, and killing one **not** wake the brain?
  - When an anchor dies: does the bearer walking in from it look natural? Does any bearer get stuck far out?
  - Does "break the links → swarm → encircle → frenzy" feel like boss phases? Is the link phase too long or too dangerous (it overlaps the wake)?
  - Fight length vs PT11 (314 s); telemetry `links`, `bearers`, `anchors`, `brain_take`.
- [x] 22. **E8-B** (queens + escort, spec above): go-ahead (user, 2026-10-24); built + headless ✅ (2026-10-24, 2.1.21, seed 12345).
  - Files: `prototypes/entity/challenge-units.lua` (`ht-queen`), `locale/en/locale.cfg`, `brain-fight.lua` (queens: `release_queen`, `send_queen`, `arrive`, `update_queens`, `brain_fight.reserved`, nest deaths start them), `waves.lua` (`queens = true`, `waves.spawn_from`), `director.lua` (leaves queens + escorts alone via `brain_fight.reserved`), `telemetry.lua` (`queens`, `queen_spawned`), `control.lua` (`waves_step` returns queens + escorts), `docs/commands.md`. Tools: `ht-anchor-test` (queen timeline, speed check, neutral test brain; `or-e8b-result.txt`), `ht-challenge-test` rerun (`or-e8b-result.txt`, `or-e8b-ups.txt`). `check-paths.py`: 2517 paths, 0 missing.
  - Deviations from the spec (headless):
    - **Spot on your flanks** (60–120° off "away from the brain"), not the half circle behind you: from behind, a queen coming out of the base walked straight through the target.
    - **Released by the nest nearest to you**, not a random one (shorter walk).
    - **Queen + escort walk as one unit group** to her spot: alone, the escort crowded her (half her speed) or fell 12–15 tiles behind. The group ends when she's there, after **20 s** (cliffs / forest: one walked around a cliff line away from her spot), or when **you come within 8 tiles** of her: she holds and her escort attacks you.
    - A holding queen gets her hold command back each check: the engine sometimes sends an idle unit back to a nest.

  | Headless (seed 12345, cliff-free brain) | Result |
  |-----------------------------------------|--------|
  | Release | None before a nest dies; **1 at the first nest death (siege)**, 2nd **20 s** later, **never 3**; a killed queen **replaced 20.0 s** later; **none once all nests are dead** ✅ |
  | Walk | Queen speed 0.09 tiles/tick on open ground; with her escort as a group the escort stays **3–9 tiles** from her while walking, **2–5** while holding |
  | Spots | Held 21–25 tiles from the target at ~80–110° off "away from the brain"; once 8 tiles (her route passed next to the target: she stopped and her escort attacked) |
  | Spawning | **3 small biters per 4 s** while holding, until the **300-unit cap** (the test's surges fill it, so few queen biters there) |
  | Regression (`ht-challenge-test`) | Shield probes unchanged (20 / 200); director **8.9 HP/s** avg (budget 8.3; 8.4 before); ring 0 unchanged; 2 queens per ring-1 run; 1.3–3.3 ms per tick. **Open:** the two-gap choke run no longer "comes round" (1 unit from behind, was 88–89; choke seen at 61.5 s, was 44): maybe queen biters attacking straight through the gap; watch in PT10.4. **Resolved in 23a** (queens 40–50 tiles out: 115 from behind) |
  | Can't judge headless | Whether a queen reads as a priority target, whether the stream feels like pressure or a chore, whether stopping when you come close feels right, balance |
- [x] 23. **PT13 (user, in game, 2026-10-24, 2.1.21):** queens **spawn roughly when expected** ✅, but they should stay **way further** from you: **too easy to pick them off** → OR-D82, OR-D83.
- [x] 23a. **OR-D82, OR-D83 built** (2026-10-24, 2.1.21, `brain-fight.lua`): `QUEEN_MIN, QUEEN_MAX` 40, 50; `retreat`: you within `QUEEN_FLEE` 25 → her group goes, her escort attacks you and leaves her for good, she walks alone (no distractions) to a spot 40–50 tiles from you **straight away from you (± 30°)** (deviation: a spot on her flank had her walk past you first), then holds. Telemetry stats `queen_retreats`. The old "stop when you come within 8" is gone. Headless (`ht-anchor-test`, `or-e8b2-result.txt`): the target jumps to 15 tiles from a holding queen → she retreats **15 → 30 → 42.5 tiles in ~8 s** and holds there; the other queen within 25 retreated too; escorts released; queens before that held **36–38** tiles out (their walk ended on the 20 s limit before the 40–50 spot); release / replacement / no-nests rules unchanged. Regression (`ht-challenge-test`, `or-e8b2-result.txt`): shield probes unchanged; director **8.6 HP/s** avg (budget 8.3); ring 0 unchanged; 1.1–3.1 ms per tick; the two-gap choke run **comes round again** (115 unit-checks from behind, choke at 44 s), so step 22's open item is gone (queens near the rock ring were the likely cause). Can't judge headless: whether she's now hard enough to reach, whether chasing her feels good.
- [x] 23b. **PT13.2 (user, in game, 2026-10-24, 2.1.21):** won (t16, 155 s, no deaths). A push **can still kill a queen** ✅; queens feel **mostly irrelevant**; **not noticeably more** biters than before.

  | Telemetry t16 (`3852-t16.csv`) | Value |
  |--------------------------------|-------|
  | Phases | siege 9 s, wake 75 s, swarm 72 s |
  | Danger | **All damage in the first 30 s** (250 → 125 HP), then ~0 HP/s to the end |
  | Queens | 1–2 alive from 10 s to the end, but only **72 biters** in 155 s (~0.5/s); a surge brings 250–350 |
  | Wake | Nests 6 → 0 by 70 s: only **5–20 alive**, the wake starves (queens don't make up for it) |
  | Swarm | 190–450 alive, director **calm** throughout, **41 charges / 943 units charged**, at most 10 touching you; you killed **10–24 per second**, so charges died on the way in (form → ready → 1.5 s tell between them) |

  → Next: **Q36** (director pressure), user's pick; queens stay as they are for now. Q36 answered → OR-D84–D87, **OR-E10 specced** (above).
- [x] 24. **OR-E10** (the hive keeps up the pressure, spec above): go-ahead (user, 2026-10-24); built + headless ✅ (2026-10-24, 2.1.21, seed 12345).
  - Files: `waves.lua` (`wake_from_brain`, `director_wake`, `stream` in `PHASES[1]`; wake share 1), `director.lua` (`active` from the wake, regroup / choke / closing ring swarm-only, `calm_hist`, `entry.stream`, the stream in `update_squads`), `telemetry.lua` (`stream`, `streamed`), `docs/commands.md`. Tools: `ht-challenge-test` ring-1 runs now kill **every** inner nest at the early nest step (PT13.2: you clear them before surge 1), ring 0 still half (`or-e10-result.txt`, `or-e10-ups.txt`).

  | Headless (seed 12345) | Result |
  |-----------------------|--------|
  | Wake without nests | Groups keep coming out of the brain: **6–64 alive** in the wake (was starving) |
  | Stream | **Off** for the standing target (8.6 HP/s, not calm); **on** 13–33 s of the 35 s swarm for the target that kills 4 per check and the kiting ones, and in the wake. It sends **2.5–9 units/s**, not 12: the squads empty faster than they recruit, so in practice everything that reaches a squad goes straight in |
  | Director | Standing target **8.6 HP/s** avg (budget 8.3), as before; kills-4 target 5.4 (was 5.2) |
  | Rest | Shield probes unchanged; ring 0 unchanged; 1.1–3.1 ms per tick |
  | **Regression** | Two-gap choke run: choke **never** detected (was at 44 s). The stream feeds both gaps, so the deaths split over two arcs and the "70 % of kills in one 60° arc" rule never fires. One-gap run: choke at 44 s as before. Not fixed (one mechanic per PT); test PT14 on open ground, look at it with PT10.4 / Q38 |
  | Can't judge headless | The target kills a fixed number per check, so whether the stream feels like pressure (or like farming) and the real damage you take only show in game |
- [x] 25. **PT14 (user, in game, 2026-10-24, 2.1.21):** won (t14, 162 s, 149/250 HP, no deaths). User: the **wake still comes** ✅; things keep spawning, **a better feel**, but it **didn't increase the danger much**, "a little".

  | Telemetry t14 (`3981-t14.csv`) | Siege | Wake | Swarm |
  |--------------------------------|-------|------|-------|
  | Time | 9 s | 66 s | 88 s |
  | Alive (avg) | 10 | 23 (5–45: no longer runs dry ✅) | 243 |
  | Damage taken | 2.2 HP/s | **0.7 HP/s** | **0.3 HP/s** (budget 8.3) |
  | Stream on / sent | – | 64 s / 4.2 per s | 84 s / 8.3 per s |
  | You killed | 2/s | 4.2/s | **10.8/s** |

  Most damage again in the first 20 s (247 → 183), then 34 HP in 140 s; at most 18 touching you. The stream works but **arrives one by one and dies on arrival**: you out-kill it. Danger needs many at once or more than you can kill → next: **Q37** (the stream from more queens, further away), user's pick. Q37 answered → OR-D88–D90, **OR-E11 specced** (above).
- [x] 26. **OR-E11** (the stream comes from the queens, spec above): go-ahead (user, 2026-10-24); built + headless ✅ (2026-10-24, 2.1.21, seed 12345).
  - Files: `brain-fight.lua` (`QUEENS` 4, spot 50–70, cap 500, spawn 3 + `record.queen_level`, queen biters marked as charging for 10 s), `director.lua` (`entry.quiet` = calm over 5 s, `record.queen_level` +1 per 5 s quiet, 0 over budget), `waves.lua` (`stream = false`), `telemetry.lua` (`queen_level`), `control.lua` (`waves_step` returns it), `docs/commands.md`. Tools: `ht-anchor-test` (queen level logged, queen killed at 70 s, nests at 100 s; `or-e11-result.txt`), `ht-challenge-test` (`or-e11-result.txt`, `or-e11-ups.txt`).
  - Bug found by the regression run and fixed: the new calm flag first reused `entry.calm`, the chokepoint's 10 s average (debug); renamed `entry.quiet`.

  | Headless (seed 12345) | Result |
  |-----------------------|--------|
  | Queens | **4 at once** (one per 20 s); a killed queen replaced **20.0 s** later; most hold **50–63 tiles** out, some **~35** (the 20 s walk ends first); retreat to 52.9 tiles |
  | Level | Climbs while the target is calm: **up to 8** (kiting), 5 (kills 8 per check), 4–5 (choke runs); **0** for targets over budget (standing: 8.8 HP/s avg, budget 8.3) |
  | No nests | No release from dead nests; one release after the nests died came from a nest that **regrew** (the debug record leaves the territory hostile: test artifact, a real challenge doesn't regrow) |
  | Rest | Shield probes unchanged; ring 0 unchanged; 1.1–3.5 ms per tick |
  | Chokes (Q38) | Squad stream off → the **two-gap** choke is seen again (60.5 s); the **one-gap** choke is now **never** seen (was 44 s): queen biters run straight into the gap |
  | Can't judge headless | Whether four off-screen streams feel dangerous or unfair, whether you still find and kill queens, the real damage you take (the test target kills a fixed number) |
- [x] 27. **PT15 (user, in game, 2026-10-24, 2.1.21):** won (t6, 157 s, 190/250 HP, no deaths). User: **felt fine** in general; the **lure and trap should work way better**; queens **stay at a safe distance well**, so they could spawn **from all around**; in the ~10 s lure window the biters **shouldn't stay huddled** but **close the circle** around you.

  | Telemetry t6 (`20117-t6.csv`) | Siege | Wake | Swarm |
  |-------------------------------|-------|------|-------|
  | Time | 32 s | 65 s | 60 s |
  | Damage | 0 | 0.5 HP/s | 0.5 HP/s |
  | You killed | 1.4/s | 4.3/s | **12.3/s** |
  | Queen biters | 0 | 33 (0.5/s) | 108 (1.8/s) |
  | Queen level | 0 | **9 from 96 s** | 9 |

  4 queens alive from 64 s and the level at max, yet only 141 queen biters: they spawn only while **holding**, and each 20 tiles you moved sent them **walking** again. One pull-back (112–122 s), then the trap sprang. → OR-D91–D95, OR-E12 + OR-E13 specced.
- [x] 28. **OR-E12** (queens all around, spec above): go-ahead (user, 2026-10-24); built + headless ✅ (2026-10-24, 2.1.21, seed 12345).
  - Files: `brain-fight.lua` (`queen_spot` with slots, re-spot band 40–80, spawn in any state, retreat into her slot), `docs/commands.md`. Tools: `ht-anchor-test` (target indestructible so the level climbs, queen spread, spawns while walking; `or-e12-result.txt`), `ht-challenge-test` (`or-e12-result.txt`, `or-e12-ups.txt`).
  - Deviation: the **retreat** goes to her slot's spot (away from you on her side), not straight away from you (OR-D83 build): straight away ignored the slots and the queens bunched up (smallest angle between two queens 6°).

  | Headless (seed 12345) | Result |
  |-----------------------|--------|
  | Spread | With 4 queens the smallest angle between two of them: **avg 67°, best 86°** (was 6° before the retreat fix); holding at e.g. 27°, 122°, −61°, −146° around the target, 53–65 tiles out |
  | Spawning | **379 queen biters while a queen walked**; level climbs to **9** (indestructible target = calm); 3 queens at level 9 gave ~5.4 biters/s, at times paused by the 500 cap |
  | Release / retreat | 4 queens, replaced 20.0 s after a kill, retreats work. A newly released queen walking out of the base can pass within 25 tiles of you and retreats then |
  | Regression | Director **8.8 HP/s** avg (budget 8.3); shield probes and ring 0 unchanged; 1.1–3.4 ms per tick; **both choke runs see the choke again** (44 s, 60.5 s) |
  | Can't judge headless | Whether streams from all sides feel like being surrounded or like chip damage |
- [x] 29. **PT16 (user, in game, 2026-10-24, 2.1.21):** won (t2, 231 s, ended at 57/250 HP, no deaths). User: queens **spread around and keep streaming**, a **huge improvement in challenge feel** ✅; some feeling of being surrounded by the constant streams; the **lure and trap still don't feel like circling you**.

  | Telemetry t2 (`10635-t2.csv`) | Siege | Wake | Swarm |
  |-------------------------------|-------|------|-------|
  | Time | 11 s | **144 s** | 77 s |
  | Alive (avg) | 16 | 151 | 496 |
  | Queen biters | 6 | **1208 (8.4/s)** | 312 (4.1/s: the 500 cap) |
  | Damage | 0.2 HP/s | **1.2 HP/s, 248 → 76 HP** | 0.2 HP/s, 76 → 57 |
  | You killed | 1.5/s | 8.7/s | 11.7/s |

  First fight with **danger past the opening** (the whole wake). Swarm quiet again (cap). Two pull-backs (160–172 s, 202–211 s): ≤ 3 touching, no damage, packs wait in clumps. Fight long (231 s, the wake 144 s): balance pass. → OR-E13 (the trap closes the circle) next.
- (PT16 test plan, done) queens all around. Same setup (new map or regrow, `/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and no cliffs). Check:
  - Do the queens spread around you and keep streaming while you move?
  - Does it feel like being surrounded? Danger vs PT15 (0.5 HP/s in the swarm); telemetry `queen_level`, `queen_spawned`.
- [x] 30. **OR-E13** (the trap closes the circle, spec above): go-ahead (user, 2026-10-24); built (2026-10-24, 2.1.21); headless **partly** ✅ (the far side can't be shown headless, see below).
  - Files: `director.lua` (`TRAP_GROUPS` 12, only the brain road open (your heading no longer), `trap_radius` 30 → 20 over the hold, packs `wander` over `TRAP_FILL` of their arc, re-sent when the ring tightened 3 tiles, `group.start_moving()`), `tools/ht-challenge-test` (trap shape at +3 / +6 / +9 s: units 12–40 tiles per 45° sector and their average distance; `or-e13-result.txt`, `or-e13-ups.txt`).

  | Headless (seed 12345) | Before (OR-E12) | OR-E13 |
  |-----------------------|-----------------|--------|
  | Kiting target, +6 s | sectors 0–1 only (60 / 49), 2 with 5+ | sectors 0–1 only (111 / 180), avg 34 tiles |
  | Lure-taking target, +9 s | 4 sectors with 5+ (brain side) | 4 sectors (0, 1, 6, 7: the brain side), avg **25–29 tiles** (tightens ✅) |
  | Far side (sectors 3–5) | empty | **still empty** ❌ |
  | Rest | – | shield probes, director, ring 0 unchanged; 1.1–3.3 ms per tick |

  **Why:** at the pull-back all units are between you and the brain; the far side of a 25-tile ring is about half the circle away, more than the 10 s hold allows (and the test target kites at 6.75 tiles/s). `start_moving()` (no gathering) made no difference. Queen biters from all sides (OR-E12) join the nearest pack and could fill the far side in game; headless can't show that (the test target is far from the queens' spots). → user decision (Q39) → **OR-D96**: new biters during the hold (queens, last stand) join the **emptiest** pack (`join_trap(..., emptiest)`; a pack that died out is re-formed from them and sent to its spot). Headless (rerun): little change, few new biters arrive in a 9 s hold in these runs (636 → 700 units) and the test's queens are few and far; some reach the far side (sector 5: 9 units at +6 s). In PT16 the queens sent **8.4 biters/s** (~80 per hold): that's the case it's built for, only a PT can show it. Rest unchanged (shield probes, director, ring 0; 1.1–3.3 ms per tick).
- [x] 31. **PT17 (user, in game, 2026-10-24, 2.1.21):** won (t8, 199 s, ended at **30/250 HP**, no deaths). User: spread and close **feels better**; far side fills **kind of**; spring from all sides **kind of**.

  | Telemetry t8 (`1943-t8.csv`) | Wake | Swarm |
  |------------------------------|------|-------|
  | Time | 99 s | 99 s |
  | Damage | 1.3 HP/s, **250 → 102** | 0.7 HP/s, **102 → 30** |
  | You killed | 5.2/s | 10.9/s |
  | Queen biters | 2.5/s (2 queens) | 3.4/s |

  **First fight with the danger spread over the whole fight.** Trap: pull-back at 118 s, hold 10 s, bait taken → **no damage** (6 touching); pull-back at 158 s, **sprung by the frenzy after 3 s** → **82 touching, 101 → 32 HP in 5 s** (peak 21 HP/s). So the ring bites while it's close and full; after the full 10 s hold the bait spring didn't land.
- [x] 32. **Balance pass: telemetry + interview** (2026-10-24): PT15–PT17 analysed (F1–F6), targets T1–T4, OR-D97–D103, sets BP-1..BP-4 (section "Balance pass" above).
- [x] 33. **Go-ahead** on the balance spec (user, 2026-10-24): BP-1 first; the BP-2 extra (`TRAP_REPLACE*`) is in (OR-D104). Clarified: the wake starts when an **inner nest** (≤ 30 tiles) dies or the brain engages you; anchors (32 tiles) only start the siege, so **no queens in the siege** (user's pick).
- [x] 34. **BP-1 queens** built + headless ✅ (2026-10-24, 2.1.21, seed 12345).
  - Files: `brain-fight.lua` (`QUEEN_CAP` 800; `update_queens` starts the queens when the phase leaves the siege and releases all `QUEENS` at once, one message "The queens crawl out of the nests!"; `on_nest_died` no longer starts them; `release_queen(..., quiet, used)`), `tools/ht-anchor-test` (BP-1 summary line; `or-bp1-result.txt`), `tools/ht-challenge-test` rerun (`or-bp1-result.txt`, `or-bp1-ups.txt`), new `tools/ht-telemetry-summary.py` (PT analysis, in `docs/commands.md` + `tools/README.md`).
  - Deviation *(mine)*: the 4 burst queens come from the nests **furthest from you**, one per nest (the replacement still from the nearest). From the nearest nest (first headless run) all 4 came out next to you, since you've just killed the nest beside it: **5 retreats** at once, their 32 escorts on you, one queen stuck holding at 26 tiles. Furthest: **2 retreats**, none stuck.

  | Headless (seed 12345) | Result |
  |-----------------------|--------|
  | Siege | 4 anchors + 4 bearers killed in the siege: **0 queens** ✅ |
  | Wake start (inner nest) | **4 queens at once** (0.0 s after the wake) ✅; holding 30 s later at **53–63 tiles**, at −139°, −42°, 73°, 175° around the target (smallest gap 46°; OR-E12 run: 86° best, avg 67°, but its queens came one by one) |
  | Replacement | Killed queen replaced **20.0 s** later ✅; none from dead nests (one release from a nest that **regrew**: debug-record artifact, as in OR-E11) |
  | Cap | Up to **701** (anchor test) / **800** (challenge test, ring-1 runs reach the cap in surge 2, was 500) |
  | Regression (`ht-challenge-test`) | Director unchanged (standing 8.8 HP/s, budget 8.3; kills-4 5.8, was 5.6); shield probes 20 / 200 unchanged; ring 0 unchanged; **1.1–3.7 ms per tick** (was 1.1–3.3; ~1780 enemy units on the map); chokes swapped: the **one-gap** choke seen again (44 s, came round), the **two-gap** one not (was 68.5 s): Q38 noise, as in OR-E10 / OR-E11 |
  | Can't judge headless | Whether 4 queens at once feel like the wake's opening or too much, whether the stream at the cap (800) is a spike or chip damage, T1–T2 |
- [x] 35. **PT18 (user, in game, 2026-10-24, 2.1.21):** **died** at 236 s (t6, brain at 43 %, in surge 2). User: **felt harder**, not sure how or why, the **circle never really felt like it worked**; lost a lot of HP early to a worm.

  | Telemetry t6 (`8794-t6.csv`) | Siege | Wake | Surge 1 | Surge 2 |
  |------------------------------|-------|------|---------|---------|
  | Time | 9 s | **170 s** | 41 s | 17 s (died) |
  | Damage | 17 HP | **214 HP** (230 → 16) | 5 HP | 0 |
  | Alive (avg) | 6 | 269 | 711 | 795 |
  | Most touching | 0 | 12 | 16 | 1 |
  | Queens / queen biters | 0 | **4 from the wake start ✅ / 9.2 per s** | 4 / 11.1 per s | 4 / 5.6 per s |

  - **Worms: 164 HP in 15 s** (17–31 s, eight `small-worm-turret` hits of 21–37 HP, nothing touching you). Down to 46 HP by 48 s, so the rest was played at 15–45 HP. PT15–PT17 had 28–80 HP from worms.
  - **The wake was 170 s**: the brain stayed at 98–99 % from 20 to 140 s, the links broke only at 120 s and the last nest died at 142 s (low HP, so careful play).
  - **Queens (T3) ✅**: 4 from the wake start, 2148 queen biters, about 800 alive in the surges (the cap holds), queen level 9 from 70 s. They still **die on arrival**: at most 16 touching, ~0 HP/s in the surges.
  - **Trap**: pull-back at 184 s (sprang at 194 s: 16 touching, 2 HP), second one at 227 s. **Death at 236 s during that pull-back: 500 impact from `hf-brain-ring1`**, the vanilla demolisher **head crush** (500 in a 5-tile area round the head, `space-age/.../enemies.lua`): at 11 HP you went for the bait and were run over. This likely also explains the PT8 / PT9 deaths (OR-D59).
  - T1: no (died, 236 s). T2: the only spike was the worms; surges still no spike → BP-2 (the trap) is the right next set. T3 ✅. T4 ✅ (2 pull-backs).
- (PT18 test plan) BP-1: queens at the wake. Same setup (new map or regrow, `/cheat-kit ring1`, `/ht-goto-ring`, a brain with **4 anchors** and **no cliffs**: the cliff and anchor count commands). Play as in PT17. Check:
  - Clear anchors in the siege: **no queen** should come. Kill the first inner nest (or hit the brain): **"The queens crawl out of the nests!"**, 4 queens from the far side of the base.
  - Do 4 queens at once feel like the wake's opening (a spike), or too much? Can you still pick one off?
  - In surges 1 and 2: does the queen stream keep coming (no stall at the cap)? Do the surges hurt more than PT17 (0–3 HP)?
  - Fight length vs PT17 (199 s); end HP (PT17: 30). Send the CSV name.
- [x] 35a. PT18 discussed (user, 2026-10-24): **keep BP-1**, build BP-2; **no worms** in ring 0 and ring 1 (OR-D105); the brain's **head crush does no damage** (OR-D106, not telegraphed). Both go into PT19 with BP-2: they only change the opening (worms) and the bait (crush), the trap shows in the surges, so the telemetry keeps them apart.
- [x] 36. **BP-2 trap + OR-D105 + OR-D106** built + headless (2026-10-24, 2.1.21, seed 12345).
  - Files: `director.lua` (`TRAP_INNER` 12, `REGROUP_HOLD` 8 s, `TRAP_REPLACE` 4 tiles / `TRAP_REPLACE_TICKS` 1 s), `brain-bases.lua` (worm autoplace × `hostile_point_ring >= 2`), `regrow.lua` (no core worm slots below ring 2), `Hostile-fauna/prototypes/brain.lua` (`no_crush`: the impact damage goes from every brain size's `update_effects`; an entry left empty is dropped, since an empty `target_effects` list doesn't load). Tools: `ht-anchor-test` counts worms per base and at the end (`or-bp2-result.txt`), `ht-challenge-test` rerun (`or-bp2-result.txt`, `or-bp2-ups.txt`). `--dump-data` + `check-paths.py`: 2517 paths, 0 missing.

  | Headless (seed 12345) | BP-1 | BP-2 |
  |-----------------------|------|------|
  | Worms (map gen) | – | **0** in all 4 ring-0 and 7 ring-1 bases, 0 after regrow ✅ (ring 2+ not in the test area: there the autoplace is unchanged) |
  | Head crush | 500 impact | **0 impact effects** on `hf-brain-small` / `-ring1` / `-medium` / `-big` (dump); `hf-earth-wyrm-small` keeps its 1 ✅ |
  | Lure-taking target, trap +3 / +6 s | avg 23.4 / 25.6 tiles, 5 / 4 sectors with 5+ | avg **23.5 / 25.2** tiles, 5 / 4 sectors; springs at 44.5 s, 11 tiles from the brain (was 46.5 s: hold 8 s) |
  | Kiting target, trap +3 / +6 / +9 s | avg 32.9 / 33.2 / 31.7; 421 / 325 / 205 units 12–40 tiles out | avg **32.0 / 32.7 / 31.3**; 558 / 334 / **168** |
  | Rest | – | director, shield probes, ring 0 unchanged; 1.0–3.7 ms per tick |

  - ❌ **The ring doesn't get tighter headless**: the packs never reach their spots (still 23–33 tiles on average, mostly on the brain side), so the ring radius isn't what limits it. The faster re-send even leaves a few fewer units in range for the kiting target (more re-paths). This matches the "why" above (points 1–3): numbers alone may not close the circle → **Q42**. PT19 shows whether a real player (who stops to pick the bait) sees a difference.
- [x] 37. **PT19 (user, in game, 2026-10-24, 2.1.21):** **lost** at 151 s (t16, brain at 52 %, 3 s into surge 2), but **felt quite okay**. No worms ✅; slightly better, hard to say; the circle: unsure, look at the data.

  | Telemetry t16 (`4321-t16.csv`) | Siege | Wake | Surge 1 | Surge 2 |
  |--------------------------------|-------|------|---------|---------|
  | Time | 13 s | 116 s | 14 s | 8 s (died) |
  | Damage | 18 HP | 129 HP (1.1/s) | 0 | **93 HP in 7 s** |
  | Most touching | 2 | 31 | 9 | **102** |
  | Queens / biters per s | 0 | 4 / 5.0 | 4 / 8.3 | 4 / 7.0 |

  - **Wake spikes come from biters now** (no worms): 56–63 s **87 HP** (16–31 touching, a charge), 94–95 s 19 HP. The rest of the wake is calm. That's the "spike on purpose" shape (T2) ✅.
  - **The circle closed this time**: during the pull-back (134–142 s) **68–184 units within 3–10 tiles** of you (the headless kiting target never had that), at most 3 touching. Headless can't show it because its target kites away.
  - **The trap spring and surge 2 came together**: you shot the brain while it was open during the lure (78 → 58 %), took the bait at the end of the 8 s hold, and the brain crossed 55 % a second later. The trap charged from all sides **and** the encircle surge (250) came out round you: 13 → 58 → **102 touching**, 102 → 9 HP in 7 s, dead at 151 s (small-biter hits, 1 HP each through heavy armor). PT17's frenzy-sprung trap was the same stack.
  - **T1 length**: 151 s, on target, but a loss. T2: wake spike ✅, trap spike too big because it stacks (93 HP, target 20–40). T3 ✅. T4: 1 pull-back.
- (PT19 test plan) **New map** (worms are map gen). `/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and no cliffs. Check:
  - No worms at the ring-1 brain (and at ring-0 brains). Standing next to the brain's head doesn't hurt.
  - When the hive pulls back: does the ring close in to ~12 tiles and stay on you while you walk to the bait? Does the spring land (a 20–40 HP moment)?
  - Danger per phase vs PT18; length; end HP. Send the CSV name.
- [x] 37a. PT19 discussed (user, 2026-10-24): **keep BP-2**; the trap and the next surge must not stack → **OR-D107**; **BP-3 waits** until a fight reaches the frenzy (PT18, PT19 didn't).
- [x] 37b. **OR-D107 built + headless ✅** (2026-10-24, 2.1.21, seed 12345): `waves.lua` (`SURGE_AFTER_TRAP` 5 s: no new surge while `record.regroup` or within 5 s of `record.trap_sprung_tick`), `director.lua` (sets `trap_sprung_tick` at the spring). Result `tools/ht-challenge-test/or-d107-result.txt`, `or-d107-ups.txt`.

  | Headless | BP-2 | OR-D107 |
  |----------|------|---------|
  | Kiting run (brain set to 25 % during its pull-back) | the frenzy sprang the trap at 57 s, surge 3 at 57 s (stacked) | trap held to its **25 s time-out (65 s)**, surge 3 at **70.0 s** ✅ |
  | Lure run | spring 44.5 s (bait), surge 3 57 s | unchanged |
  | Other runs | surges at 33 / 57 s | unchanged; damage per run within ±0.3 HP/s; 1.0–3.8 ms per tick |

  - Side effect: the frenzy no longer springs a running trap (OR-D65), since the frenzy surge itself waits for the spring. A pull-back that runs into the frenzy threshold now holds until the bait or the 25 s time-out (`REGROUP_MAX_TICKS`).
- [x] 38. **PT20 (user, in game, 2026-10-24, 2.1.21):** **won** (t5, 318 s, ended at **93/250 HP**, no deaths). User: unsure about the timing, but **the first time the trap felt like it worked well**; survived the spring; the **frenzy felt nothing special**.

  | Telemetry t5 (`978-t5.csv`) | Siege | Wake | Surge 1 | Surge 2 | Frenzy |
  |-----------------------------|-------|------|---------|---------|--------|
  | Time | 6 s | 136 s | 20 s | 81 s | 75 s |
  | Damage | 2 HP | 66 HP (0.5/s) | 5 HP | 58 HP | **11 HP (0.15/s)** |
  | Most touching | 0 | 34 | 11 | 85 | 18 |
  | Queens / biters per s | 0 | 4 / 6.7 | 4 / 9.6 | 4 / 8.7 | 3 / 5.8 |

  - **Spikes (T2)**: wake 88–90 s **44 HP** (34 touching); third trap spring 239–242 s **65 HP in 4 s** (85 touching). 109 of 156 HP lost in those 7 seconds. ✅
  - **Trap**: 3 pull-backs (149, 187, 230 s; 30 s apart). Hold: 110–180 units within 3–10 tiles (149 s), 75–95 (230 s): the ring closes in game. Springs 1 and 2 (157, 200 s): ≤ 11 touching, ≤ 4 HP; spring 3: the spike.
  - **OR-D107 ✅**: spring at 238 s with the brain already below 30 %, the frenzy came at **243 s** (5 s later), so the spike was the trap alone.
  - **Frenzy weak**: 75 s, 11 HP, at most 18 touching → BP-3.
  - **Length (T1) ❌ 318 s**: wake 136 s (links broken at 63 s, last nest 99 s, the brain at 100 % until ~100 s); the brain sat at 47 % for 40 s in surge 2 and took 75 s from 24 to 1 % → BP-4.
  - T3 ✅ (4 queens). **T4 ❌ 3 pull-backs** (target ≤ 2) → Q43.
- (PT20 test plan) Same setup as PT19 (new map, `/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and no cliffs). Play as in PT19 (shooting the brain during the lure is fine). Check:
  - When you take the bait after shooting the brain past a threshold: the trap springs first, the surge message comes **~5 s later**. Does that read, or does the surge feel late?
  - Is the spring alone a spike you can survive (20–40 HP)?
  - Do you reach the frenzy now? Length, end HP. Send the CSV name.
- [x] 39. **BP-3 frenzy** built + headless ✅ (2026-10-24, 2.1.21, seed 12345): `waves.lua` (`PHASES[1]`: surge 3 `total` 150 → 250, `frenzy_last_stand` 2 → 3, new `frenzy_max_alive = 800`; the last stand uses it while `record.frenzy`). Result `tools/ht-challenge-test/or-bp3-result.txt`, `or-bp3-ups.txt`.
  - Deviation *(mine)*, **OR-D108**: the last stand stops at `last_stand_max_alive` (240) units alive. In PT20's frenzy ~580 were alive (mostly queen biters), so the frenzy's last stand never spawned, and ×3 alone would have changed nothing. In the frenzy it now stops at **800** (the queen cap); surges 1–2 keep 240.

  | Headless | OR-D107 | BP-3 |
  |----------|---------|------|
  | Frenzy last-stand group | 20 | **30** ✅ |
  | Frenzy units spawned per run (surge + last stand + queens, until the test ends) | 286–362 | **436–534** |
  | Most units alive | 951 | 1051 (surge units aren't capped) |
  | Damage per run | – | within +0.9 / −0.5 HP/s; 1.0–3.8 ms per tick (unchanged) |
  | Can't judge headless | The 800 cap: the test clears all units before its last stand, so it never runs at ~580 alive as in game |
- [x] 40. **PT21 (user, in game, 2026-10-24, 2.1.21):** **lost** at 220 s (t3, brain at **31 %**, surge 2: the frenzy, and so BP-3, was never reached). User: go for BP-4 now to make the fight shorter.

  | Telemetry t3 (`1418-t3.csv`) | Siege | Wake | Surge 1 | Surge 2 |
  |------------------------------|-------|------|---------|---------|
  | Time | 6 s | 143 s | 35 s | 37 s (died) |
  | Damage | 0 | 86 HP (0.6/s) | 19 HP | 135 HP |
  | Most touching | 0 | 28 | 15 | **102** |

  - Spikes: wake 69–76 s (56 HP); surge 2 190–191 s (30 HP, the encircle ring closing: 54 touching); **216–220 s: 92 → 10 HP in 4 s, 91–102 touching → dead**.
  - The death came **10 s after the second spring** (207 s), not at it: sprung units are marked charging for `RESWARM_TICKS` (15 s), and the director leaves charging units alone, so its budget (8.3 HP/s) can't cap them; it only went "full" at 218 s. Same as PT19's death (102 touching). → **Q44**.
  - Wake 143 s again (T1).
- [x] 41. **BP-4 length** built + headless ✅ (2026-10-24, 2.1.21, seed 12345): `Hostile-fauna/prototypes/brain.lua` `RING1_HEALTH` 5000 → **4000** (thresholds stay 80 / 55 / 30 %). `ht-challenge-test` (sets the brain by %): brain at 75 % = **3000** HP; everything else identical to BP-3 (damage per run, shield probes 20 / 200, 1.0–3.8 ms per tick). Result `or-bp4-result.txt`, `or-bp4-ups.txt`. Can't judge headless: length (the test sets the brain %).
- [x] 42. **PT22 (user, in game, 2026-10-24, 2.1.21):** **died** at 209 s (t4, brain at **20 %**, in the frenzy). User: each phase **feels shorter**, could go **shorter still**; the frenzy **might make the last part hard to kill**; died pushing with grenades (biter or grenade?).

  | Telemetry t4 (`853-t4.csv`) | Siege | Wake | Surge 1 | Surge 2 | Frenzy |
  |-----------------------------|-------|------|---------|---------|--------|
  | Time | 9 s | **86 s** (was 136–143) | 34 s | 31 s | 50 s (died) |
  | Damage | 0 | 30 HP | **86 HP** | 2 HP | 129 HP |
  | Most touching | 0 | 13 | 75 | 9 | 2 |
  | Alive (avg) | 6 | 177 | 356 | 419 | **737** |

  - Spikes: surge 1 97–101 s **78 HP** (49–75 touching: the swarm itself). Traps (109, 147 s): no damage. OR-D107: surge 3 came 5 s after the second spring (155 → 160 s) ✅.
  - **Frenzy = a wall**: the brain stayed at **20 % for 50 s** (160–209 s), 740–800 alive (the 800 cap full), 60–85 within 10 tiles, no damage to the brain.
  - **Death = your own grenades**: 206–209 s, **0 touching** and **no enemy hit logged** (the log only took enemy damage) while 14 grenades were thrown in 6 s (`grenades` 20 → 6, explosion kills 27–110 per s): 22, 21, 43, 43 HP. → OR-D111.
  - T1: wake ✅ shorter; the fight 209 s (died). BP-3: too much (frenzy cap) → OR-D109.
- [x] 42a. PT22 discussed (user, 2026-10-24): frenzy cap **800 → 400** (OR-D109), brain **4000 → 3000 HP** (OR-D110), **log own damage** (OR-D111). One PT for all three: the cap only acts in the frenzy, the HP is length, the log changes no gameplay.
- [x] 43. **OR-D109–D111** built + headless ✅ (2026-10-24, 2.1.21, seed 12345): `waves.lua` (`frenzy_max_alive` 400), `Hostile-fauna/prototypes/brain.lua` (`RING1_HEALTH` 3000), `director.lua` (`on_character_damaged` also logs own-force damage as `"own <damage type>"` with a 5th field `true`; `hp_per_s` leaves it out of the budget), `tools/ht-challenge-test` (30 own explosion on the target at the shut probe). Result `or-pt22-result.txt`, `or-pt22-ups.txt`.
  - Headless: the probe shows in the telemetry as `max_hit_by` **"own explosion"** (30 → 7 HP through heavy armor) and `hp_per_s` stays **0.0** for the calm run ✅; brain at 75 % = **2250** HP ✅; damage per run identical to BP-4 except one run (2.3 → 3.0 HP/s, noise); 1.0–3.7 ms per tick. Can't judge headless: the frenzy cap (the test clears its units before the last stand), length.
- [x] 44. **PT23 (user, in game, 2026-10-24, 2.1.21):** **won** at 194 s (t7), **128 / 250 HP** left. User: the frenzy **felt fine**.

  | Telemetry t7 (`20323-t7.csv`) | Siege | Wake | Surge 1 | Surge 2 | Surge 3 (frenzy) |
  |-------------------------------|-------|------|---------|---------|------------------|
  | Time | 6 s | **108 s** | 6 s | 45 s | 29 s |
  | Brain | 100 % | 100 → 82 % | 74 → 59 % | 54 → 35 % | 28 → 3 % |
  | Damage | 0 | 60 HP | 2 HP | **55 HP** | 2 HP |
  | Most touching | 0 | 17 | 6 | 52 | 10 |
  | Alive (avg) | 7 | 174 | 521 | 718 | 650 |

  - **T1 length 194 s** (target ~150) ❌, but the brain is no longer what's slowing it: it only took fire for ~20 s in total (100 → 54 % in 10 s at 110–120 s, 24 → 3 % in 3 s at 190–193 s). The time goes into the **wake** (all nests dead at 70 s, the brain untouched until 110 s) and the stalls in surge 2 (54 % for 18 s, the pull-back) and the frenzy (24 % for 23 s).
  - **T2** ✅: the wake 47 HP at 49–60 s (killing nests, 7–17 touching); the trap spring at 138–142 s **33 HP** (173 → 140, 52 touching, peak 15 HP/s) = Q44's spike, inside the 20–40 HP target. 78 of the 122 HP lost came in 10 spike seconds.
  - **T3** ✅ 4 queens at 6–10 s. **T4** ✅ 1 pull-back (129–137 s).
  - **Frenzy (OR-D109)**: alive stayed **560–760 > 400** (queen streams + the surge's 250), so the frenzy last stand **never spawned**; the frenzy = only surge 3's 250. 2 HP in 29 s. The brain sat at 24 % for 23 s, then went quickly.
  - No own damage (no grenades thrown).
- (PT23 test plan) Same setup as PT22 (`/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and no cliffs). Check:
  - Frenzy: still a final push, but can you get shots on the brain? How long from 30 % to dead?
  - Length vs PT22 (209 s, died at 20 %). Careful with grenades at close range: they hurt you (heavy armor: ~7 per grenade, more when several land).
  - Send the CSV name.
- [x] 45. PT23 discussed (user, 2026-10-24): **ring 1 done for now** (OR-D112). Ring 2 starts in its own session ([ring2-challenge-plan.md](ring2-challenge-plan.md)).
- [ ] 46. **Tutorial pass** (after every ring has its kit): revisit rings 0–1 as a tutorial for later rings. Candidates: (a) length: at the last nest's death all queens release at once, or queens die with their nest (PT23: nests dead at 70 s, brain untouched until 110 s); (b) frenzy: leave queen biters out of `frenzy_max_alive` (PT23: 560–760 alive > 400, so the frenzy last stand never spawned); (c) Q44 trap spike ceiling (PT23: 33 HP, on target); (d) Q43 pull-backs; (e) Q42 trap circle.
- (PT22 test plan) Same setup as PT21 (`/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and no cliffs). Check:
  - Fight length vs PT20 (318 s) / PT21 (220 s, died). Does each phase feel shorter, or only the brain part?
  - Do you reach the frenzy now, and how does it feel (BP-3: 250 units, last stand ×3)?
  - Deaths: what hit you (telemetry death line). Send the CSV name.
- (PT21 test plan) Same setup as PT20 (new map or the same map with another ring-1 brain, `/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and no cliffs). Check:
  - From "The brain goes into a frenzy!": do more biters keep coming out of the brain (30 every 2 s) until it dies? Does it feel like a last push or like a slog?
  - Is there a spike in the frenzy (20–40 HP), and can you still finish the brain?
  - Fight length vs PT20 (318 s), end HP vs 93. Send the CSV name.
- (PT17 test plan, done) trap closes the circle. Same setup (new map or regrow, `/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and no cliffs). Kite until the hive pulls back ("The hive pulls back..."), then watch the 10 s hold before going for the bait. Check:
  - Do the packs spread round you and close in (30 → 20 tiles) instead of waiting in clumps?
  - Does your far side fill up (queen biters joining the emptiest packs), so it feels like being circled?
  - Does the spring (bait or 25 s) come from all sides? Telemetry `regroup`, `regroups`.
- (PT15 test plan, done) queens as the stream. Same setup (new map or regrow, `/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and **no cliffs**). Check:
  - Do 4 queens come and stay off screen (50–70 tiles)? Can you find and kill them, or do they feel unfair?
  - When you're on top of things, does the stream from the queens grow until it hurts (`queen_level` in telemetry)?
  - Danger over the whole fight vs PT14 (0.3 HP/s in the swarm).
- (PT14 test plan, done) Same setup as PT13 (new map or regrow, `/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and **no cliffs**). Check:
  - After you've cleared the nests, does the wake keep coming (out of the brain)?
  - When you're on top of things, does the stream make something always arrive? Does it feel like pressure or like farming?
  - Danger over the whole fight vs PT13.2 (all damage in the first 30 s); telemetry `stream`, `streamed`, `hp_per_s`.
- (PT13 test plan, done) queens. **New map** (or the regrow command until the anchor count says 4). `/cheat-kit ring1`, `/ht-goto-ring`, a brain with 4 anchors and no cliffs. Check:
  - After the first nest dies: do queens come out with their escort and walk to your flanks? Do they read as a priority target?
  - Does the stream (3 biters per 4 s per queen) keep the pressure up in the siege / wake once you've cleared nests? Is "no nests → no queens" a good payoff?
  - Escort: does it stay with her, and does it attack when you come close?
  - Fight length vs PT11 (314 s); telemetry `queens`, `queen_spawned`.

## Retro 2 (2026-10-25, balance pass PT17–PT23)

**Went well**
- **Telemetry found the causes**: the worm early on, the head crush at the bait (OR-D106), trap spring + surge stacking (OR-D107), the frenzy wall at 800 alive, own grenades (OR-D111). `tools/ht-telemetry-summary.py` made each PT a 1-minute read.
- Headless regression before every PT; the plan stayed current, so the context reset cost nothing.
- **User (2026-10-25):** the clear overview of what was built and what to test in the PT helped most; sometimes it got less clear (bundled changes, mixed test lists).
- Result: lost PT19, PT21, PT22 → **won PT23** with 128 / 250 HP; the trap felt right from PT20; spikes on target (T2).

**Went less well**
- **Length was blamed on the wrong lever**: brain HP cut twice (5000 → 3000), but in PT23 the brain only took fire ~20 s. The time is in the wake after the last nest and the stalls between surges; PT20 / PT22 data already showed it. T1 (~150 s) missed: 194 s.
- **The frenzy cap was set without checking what it counts**: 400 vs PT22's 737 alive, but queen biters count too, so the frenzy last stand never spawned in PT23. It felt fine by luck.
- **More than one change per PT**: BP-3 stayed unjudged from PT20 to PT22; PT22 → PT23 changed three things.
- **Headless can't judge the important parts**: trap circle, frenzy (the test clears units before the last stand), length.
- Tooling slips: PowerShell `&` detaching factorio, a run on pre-edit code, a dropped heading, CRLF patches, the first queen burst from the nearest nest.

**For next time (also ring 2)**
- Before cutting HP or time: find in the telemetry **which phase is slow** and whether the player was hitting the target there.
- Before setting a cap: check **what it counts** against the live numbers of the last CSV.
- One change per PT unless the user chooses to bundle.
- Every PT hand-off in the same shape: changed since the last PT (ID, old → new), headless ✅ / not judged, test in this PT (one question per change + setup), send.
- Extend `tools/ht-challenge-test` to run through the frenzy, so the last stand is covered headless.

## Open questions

- **Q44. The trap spike has no ceiling (PT19, PT21):** sprung units charge for 15 s (`RESWARM_TICKS`) and the director doesn't cap charging units, so a spring can stack to 100 touching (both deaths). Options (numbers): `RESWARM_TICKS` 15 → 5 s (the director takes them back sooner), or the director may hold back charging units once over budget.
- **Q43. Pull-backs per fight (PT20: 3, target ≤ 2):** `REGROUP_GAP` 30 → 45 s, or a cap of 2 per fight? Longer fights (PT20: 318 s) get more; BP-4 (shorter) may fix it on its own.
- **Q42. The trap circle (BP-2 headless, 2026-10-24; PT19: in game it did close, 68–184 units within 10 tiles, so maybe no mechanic needed; watch in PT20):** the packs never reach their spots within the hold (23–33 tiles out, brain side), whatever the radius. If PT19 confirms it, this needs a mechanic, not a number (outside the balance pass). Options: the ring forms where the hive already is (spots shifted towards the hive's side), new units (queens, last stand) **spawn** into the far side, or the hold lasts until the ring is closed.

- ~~**Q1. Budget**~~ → OR-D8. Note: 1 stack of shells = 100 × 10 = 1000 shots; trim after PT1 if it's far too much.
- ~~**Q2. "Way more"**~~ → OR-D5.
- ~~**Q3. Enemy mix**~~ → OR-D6 (smalls only for PT1; later: mediums as brutes, small spitters, new enemies → EB4).
- ~~**Q4. Shotgun ×3**~~ → OR-D10 (yes).
- ~~**Q5. Oil-ring brain**~~ → OR-D4 (one brain per ring).
- **Q6. Director on the first ring too?** Or oil ring only until it's proven? (After PT1, see OR-D11.)
- ~~**Q7. Turrets and car gun ×3?**~~ → OR-D10 (vanilla for PT1).
- ~~**Q8. Armor in the kit?**~~ → OR-D12 (heavy armor). Heavy turns a small biter's 7 dmg into 0.7.
- ~~**Q9. Escape from the swarm**~~ → OR-D13.
- ~~**Q10. Repulse capsule unlock**~~ → OR-D15 (kit only for now).
- ~~**Q11. Shotgun**~~ → OR-D16 (reload 20 ticks).
- ~~**Q12. Budget window**~~ → OR-D17 (3 s, 8.3 HP/s).
- ~~**Q13. Telemetry**~~ → OR-D18 (yes).
- ~~**Q14–Q16**~~ → OR-D19–D21.
- **Q14. Brain time-to-kill:** draft **5000 HP** (was 2250) and **swarm at 80 %** (was 60 %). SMG at PT2's real ~140 DPS: 7 s before the swarm, then ~28 s of pure brain shooting (more, since you also fight the swarm). Shotgun (Q16 draft): ~18 s after the swarm starts.
- **Q15. Director lets more in:** draft: slots only count units **within ~6 tiles** (not 24), and slots grow while you take less than the budget (+2 per check below 60 % of it, −2 when over, never below budget ÷ damage per biter). If you kill fast, the whole swarm comes; if you get bitten, it backs off.
- **Q16. Shotgun:** draft **reload back to 40** and **×2 instead of ×3**. One pellet still kills a small biter (8 × 2 = 16 ≥ 15 HP), and on the brain the shotgun (225 DPS) is close to the SMG (187) instead of 3.6× it.
- ~~**Q17–Q20**~~ → OR-D22–D25.
- **Q17. Slower challenge biters:** how much, and where? Today a small biter runs 0.225 (90 % of your 0.25). Kill window crossing the SMG's 18 tiles: 1.3 s now; −20 % (0.18): 1.7 s; −30 % (0.16): 1.9 s. Draft: **−20 %, challenge units only** (the existing permanent `ht-challenge-slow-*` sticker on every unit the phases spawn, ring 0 and 1), not all small biters (crusades and the world stay as they are). Note: slower biters also make kiting easier, so Q18 matters more.
- **Q18. Anti-kite (OR-I10):** draft three parts: (a) **re-surround**: every 2 s, units chasing you from behind (in the trailing half of your movement) get new flank points on your sides and ahead of you, using the swarm's surround routes; (b) the **holding ring follows you**: held units get a new spot when you've moved > 8 tiles from where they were held; (c) **rebuild**: when nothing is within 10 tiles of you and units are held, release a big pack (20) at once.
- **Q19. Repulse capsule:** drop it, or make it an opening: e.g. push 6 tiles + **stun 3 s** (a stunned ring around you is free shotgun / SMG kills), or push + a 50 % slow for 5 s?
- **Q20. Telemetry (OR-I9):** count the cursor stack too (no question really, just fix it?).
- ~~**Q21**~~ → OR-D27.
- **Q21. Biter speed in the ash cloud:** E3 slows the brain's own biters ×0.45 in its cloud (so the climax swarm couldn't outrun you when you're capped at 0.15). With OR-D22's −20 % they're now at 0.081, about half your speed in the cloud: kiting is trivial and anti-kite can't catch you. Options: (a) ally slow ×0.45 → **×0.75** (0.135 = 90 % of your 0.15: still slower, but close enough that re-surround and the following ring can cut you off); (b) drop the ally slow (0.18, faster than you in the cloud: the E3 problem comes back); (c) keep it and try PT4 as is. Draft: (a).
- ~~**Q22–Q26**~~ → OR-D28–D32.
- **Q22. End-phase variety (the slog):** split the brain fight into beats instead of one swarm + trickle. Draft: **three surges** at brain 80 % / 55 % / 30 %, each one different: (1) the swarm from the nests as now (~350); (2) an **ambush ring**: biters burst out of the ground in a ring around you (~250); (3) **frenzy**: the brain's shockwave pulses twice as often and the last stand doubles until it dies (~150 + trickle). Each surge announced. Same 750 in total, so it isn't harder, just not the same thing for 100 s.
- **Q23. Ambush anti-kite (replaces re-surround):** track your angle around the brain; while you circle it (steady angular speed for ~3 s), put a pack of 10–20 biters on the circle **~4 s ahead of you**, coming out of the ground 10–14 tiles ahead, taken from the remaining swarm / last-stand budget. Keep the following holding ring and the rebuild; drop re-surround (no visible effect in PT4).
- **Q24. Never run dry:** the last stand keeps coming until the brain dies: no longer 0 when the nests are dead (they come out of the brain then), and the director decides how many reach you. Also add nests alive and swarm left to the telemetry.
- **Q25. Fewer shockwave clouds:** the edge is 12 puffs per stage × 30 stages, plus the brain's idle ash trail cloud. Draft: **half the edge puffs (12 → 6)** and **no idle ash trail** around the brain; check in game.
- **Q26. Repulse capsule:** dropped for now (PT4): out of the kit; keep the prototype file so it can come back, or delete it?
- ~~**Q27–Q30**~~ → OR-D41–D45.
- ~~**Q31–Q34**~~ → OR-D66–D72 (2026-10-24).
- ~~**Q39**~~ → OR-D96. **Q39. Trap far side (OR-E13):** units can't walk round to your far side within the 10 s hold. Options: PT17 as is (queen biters fill it), the bait opens only once the ring is closed, or spawns (queens / last stand) go straight to the empty far side.
- **Q38. Stream vs chokepoint (OR-E10 regression; OR-E11: two gaps seen again, one gap now never):** biters that come straight in (the squad stream, now queen biters) aren't stopped by the choke reaction. Options: stream only from squads outside a kill-zone arc, or count kills per arc instead of one 60° arc.
- ~~**Q37**~~ → OR-D88–D90. **Q37. The stream from the queens (OR-D87, after PT14):** more queens, further away, as the source of the stream: how many, how far, and does the director then steer the queens' rate instead of squads?
- ~~**Q36**~~ → OR-D84–D86. **Q36. Director keeps up the pressure (PT12.2, after PT13):** the director only runs from the swarm on; siege / wake are fixed groups that shrink with the nests. Idea: the director runs from the siege on, keeps watching damage per second, and otherwise **sends more** while you take little. Also: a near-continuous stream in the frenzy (queens may already give it).
- ~~**Q35**~~ → OR-D78. **Q35. Queens after OR-D75?** E8-B has queens walk out of **living anchors at surges 1–2** (OR-D71), but with links = phase 1 the anchors are usually dead by surge 1. Options: queens from the inner nests, from the brain, or queens are what an anchor becomes in a later ring. Decide before E8-B.
- **Q27. Rocks (OR-D37):** which surge (draft: from surge 3)? Do the E6-7 safety rules (≥ 4 tiles away, ≤ 90° covered, max 2 walls, gone after 15 s) feel safe enough? Can you shoot or mine them (vanilla rocks: mining yes, damage yes)?
- **Q28. Re-plan in ring 0 too?** The stale-waypoint cause is the same there. Draft: ring 1 only for now (ring 0 is "done for now").
- **Q29. Lull between surges (B1):** not picked. Leave it out of OR-E6 and see whether the openings already give enough rhythm?
- **Q30. Anchor nests (A2):** not picked for OR-E6. Keep as a later option if the openings aren't enough?

## Old header line (moved here 2026-11-22)

The header now holds the current state only (planning skill); this is the header as it stood before, kept for its history.

**Status:** PT5 done (2026-10-23): numbers fine, feel off (surges alike, random movement, end drags). OR-E6 "a brain that thinks" specced (OR-D33–D43); queens + anchor ring drafted as OR-E8 (OR-D44–D45). **OR-E6 built + headless ✅**; PT6: surges + movement ✅, unlock unclear, kiting back, rocks irrelevant → **OR-E7 built + headless ✅** (OR-D47–D52: shield bearers, regroup, rocks that stay + arena). PT7: bearers clear ✅, lure not felt, rocks too much → OR-D53–D55 built (lure hold 6 s, walls off, first nest wakes the brain). PT8: early wake ✅, lure still not felt → 100 % pull back, arena 28 (OR-D56, D57). PT9: arena ✅, lure half-felt → **trap** (8 groups around you, OR-D58) + death log (OR-D59) built. PT10: a cliff choke made it useless for balance → **OR-E9 specced** (the brain sees a chokepoint, OR-D61). PT10.2: lure ✅, stages distinct ✅ → lure held 10 s, no lure in the frenzy (OR-D64, D65) built (2026-10-23). **OR-E9 built + headless ✅** (2026-10-24): the brain sees a chokepoint. PT11: lure enticing ✅, frenzy could be harder, balance still off; retro done (2026-10-24). **OR-E8 specced** (OR-D66–D73: anchor ring, then queens, a PT after each); **E8-A anchor ring + shield link built + headless ✅** (2026-10-24). PT12: anchors ✅, but anchors + bearers feel like two mechanics for one job, bearers from nowhere feel off → **E8-A2 built + headless ✅** (2026-10-24, OR-D74–D77: anchors are the shield links, each releases a bearer that walks in; links = phase 1). PT12.2: links ✅, nests all die before surge 1, siege runs dry → **E8-B queens built + headless ✅** (2026-10-24, OR-D78–D81). PT13: queens come on time ✅, but too easy to pick off → **queens hold 40–50 tiles out and retreat** when you come close (OR-D82, OR-D83, built + headless ✅). PT13.2: queens mostly irrelevant, no pressure after 30 s → **OR-E10 built + headless ✅** (OR-D84–D87; regression: the stream hides a two-gap choke, Q38). PT14: the wake comes ✅, more spawning feels better, danger only up a little (0.3 HP/s in the swarm) → **OR-E11 built + headless ✅** (OR-D88–D90: the stream comes from the queens). PT15: fine; queens mostly walking (1.8 biters/s at level 9), trap packs huddle → **OR-E12** (queens all around) + **OR-E13** (trap closes the circle) specced; **OR-E12 built + headless ✅**. PT16: queens all around = huge improvement ✅, danger lasts through the wake; trap still doesn't circle → **OR-E13 built** (headless partly: the ring tightens, the far side relies on new biters, OR-D96). PT17: feels better, danger spread over the whole fight (ended at 30 HP); the bait spring doesn't land yet. **Balance pass specced** (2026-10-24, OR-D97–D103: ~150 s, spikes on purpose, 4 queens from the wake, cap 800, trap to 12 tiles, frenzy 250 / ×3, brain 4000 HP; sets BP-1..BP-4, one per PT); **BP-1 built + headless ✅**. PT18: died at 236 s (worms 164 HP early, head crush at the bait); queens ✅, circle still not felt → BP-1 kept; **BP-2 trap + no worms (rings 0–1) + no head crush built** (headless: the ring still doesn't tighten, Q42). PT19: lost at 151 s but felt okay; the **circle closed in game** (68–184 within 10 tiles), but trap + surge 2 stacked (102 touching) → BP-2 kept, **OR-D107 built + headless ✅** (a surge waits 5 s after the spring). PT20: **won** (318 s, 93 HP); the **trap worked well** for the first time; frenzy nothing special (11 HP in 75 s); too long, 3 pull-backs (Q43) → **BP-3 frenzy built + headless ✅** (250 units, last stand ×3, frenzy cap 800, OR-D108). PT21: lost at 220 s (brain 31 %, frenzy not reached; 102 touching 10 s after a spring, Q44) → **BP-4 built** (brain 4000 HP). PT22: phases shorter ✅ (wake 86 s), frenzy a wall (brain at 20 % for 50 s, 800 alive), died to own grenades → **OR-D109–D111 built + headless ✅** (frenzy cap 400, brain 3000 HP, own damage logged). PT23 **won** (194 s, 128 HP left, frenzy fine) → **ring 1 done for now** (OR-D112, 2026-10-24) · **Parent:** [challenge-feel-plan.md](challenge-feel-plan.md) (P2 arsenal, "rings beyond the first"), [ring-layout-plan.md](ring-layout-plan.md) · **Next:** parked until the tutorial pass (step 46): revisit rings 0–1 once every ring has its kit · [Roadmap](roadmap.md)
