# Oil Ring Challenge

> **Status:** PT5 done (2026-10-23): numbers fine, feel off (surges alike, random movement, end drags). OR-E6 "a brain that thinks" specced (OR-D33–D43); queens + anchor ring drafted as OR-E8 (OR-D44–D45). **OR-E6 built + headless ✅**; PT6: surges + movement ✅, unlock unclear, kiting back, rocks irrelevant → **OR-E7 built + headless ✅** (OR-D47–D52: shield bearers, regroup, rocks that stay + arena). PT7: bearers clear ✅, lure not felt, rocks too much → OR-D53–D55 built (lure hold 6 s, walls off, first nest wakes the brain). PT8: early wake ✅, lure still not felt → 100 % pull back, arena 28 (OR-D56, D57). PT9: arena ✅, lure half-felt → **trap** (8 groups around you, OR-D58) + death log (OR-D59) built. PT10: a cliff choke made it useless for balance → **OR-E9 specced** (the brain sees a chokepoint, OR-D61). PT10.2: lure ✅, stages distinct ✅ → lure held 10 s, no lure in the frenzy (OR-D64, D65) built (2026-10-23). **OR-E9 built + headless ✅** (2026-10-24): the brain sees a chokepoint. PT11: lure enticing ✅, frenzy could be harder, balance still off; retro done (2026-10-24) · **Parent:** [challenge-feel-plan.md](challenge-feel-plan.md) (P2 arsenal, "rings beyond the first"), [ring-layout-plan.md](ring-layout-plan.md) · **Next:** OR-E8 (anchor ring + queens) in a new session; PT10.4 (a choke) open; later a balance pass · [Roadmap](roadmap.md)

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

## OR-E8 draft: queens + anchor ring (OR-D44, OR-D45; after OR-E7, renumbered 2026-10-23)

Not specced yet: the numbers below are first guesses for the interview after PT6 (Q31–Q34).

| Part | Draft | Engine / where |
|------|-------|----------------|
| Anchor ring | Ring 1+ brain bases get a second ring of nests at ~32–40 tiles (inner ring stays at 18). Map gen, so they exist from the start (nests take time to build) | `brain-bases.lua` (second ring hit, gated by `hostile_point_ring >= 1`); `waves.lua` `nest_radius` 25 → covers it; `regrow.lua` must know the outer ring |
| Shield link | Each living anchor nest makes the shield stronger or the openings shorter (E6-3), e.g. opening 8 s × share of anchors dead (min 4 s) | E6-3 code |
| Queen unit | New `hf-queen` (Hostile-fauna): slow (~0.1), tanky (medium-biter HP or more), placeholder: a tinted big biter. Nests make queens and biters; queens make only biters | Data: unit prototype; in challenges spawned by script like all phase units |
| Queen spots | Picked by the brain: your flanks / behind you, your side of the brain, or on screen (≤ ~30 tiles from you) but as far from you as possible. Re-picked when you move away | `director.lua` |
| Queen spawning | At its spot the queen stands and spawns a small group every few seconds (script, near the queen); its biters join squads (E6-2) | Script (no engine unit moves and spawns) |
| Escort | Every queen walks with its own squad that stays around it and fights anything that comes close | E6-2 squads, role "escort" |

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
- [ ] 19. **OR-E8** (queens + anchor ring, draft above): Q31–Q34, spec, go-ahead.

## Open questions

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
- **Q31. Queens: numbers.** How many alive at once (draft 2–3), HP (draft 300–500), spawn rate (draft 3 biters every 4 s), and do their biters count against the surge totals (draft: yes, so the numbers stay as OR-D40)?
- **Q32. Which surges have queens?** Draft: from surge 1, made by the nests; once the nests are dead, by the brain?
- **Q33. Anchor ring size:** how many outer nests (draft 4–6), at what distance (draft 32–40 tiles), and what's the shield link exactly (draft: opening length × share of anchors dead)?
- **Q34. Queen art:** placeholder (tinted big biter) until EB4 / art?
- **Q27. Rocks (OR-D37):** which surge (draft: from surge 3)? Do the E6-7 safety rules (≥ 4 tiles away, ≤ 90° covered, max 2 walls, gone after 15 s) feel safe enough? Can you shoot or mine them (vanilla rocks: mining yes, damage yes)?
- **Q28. Re-plan in ring 0 too?** The stale-waypoint cause is the same there. Draft: ring 1 only for now (ring 0 is "done for now").
- **Q29. Lull between surges (B1):** not picked. Leave it out of OR-E6 and see whether the openings already give enough rhythm?
- **Q30. Anchor nests (A2):** not picked for OR-E6. Keep as a later option if the openings aren't enough?
