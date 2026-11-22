# Ring Feel

> **Status:** **Interview done** 2026-10-25 (RF-D1–D53): ring 2 = **power fantasy + war** (a war state instead of a challenge, an RTS hive, retake armies, forward outposts, nothing on the map); war AI on one shared hive-AI module with an influence map and combat prediction (RF-D34–D38). Effect on R2-E1 / 4e listed below · **Parent:** [ring2-challenge-plan.md](ring2-challenge-plan.md) (4e on hold), [challenge-feel-plan.md](challenge-feel-plan.md), [oil-ring-challenge-plan.md](oil-ring-challenge-plan.md) · **Next:** ring-2 session revisits the 4e spec with the effect list (step 5); open Q29–Q35 · [Roadmap](roadmap.md)

Started 2026-10-25 (game 2.1.21), side session. Ring 2's detail work (step 4e: district fight, fallen timer, counter-attacks; Q26–Q29) is on hold because the detail questions came before the big picture.

## Goal

- Decide what **ring 2 and beyond should feel like** for the player, starting from an honest summary of rings 0 and 1.
- Enough to revisit (or change) the 4e spec in [ring2-challenge-plan.md](ring2-challenge-plan.md), with a list of what R2-E1 / R2-D* the new decisions **confirm, change or question**.
- R2-D* count as decided unless the user reopens them. Conflicts are flagged here, not resolved.

## Step 1: rings 0 and 1 as the player experiences them

Sources: challenge-feel (CF-D*, E1–E9, PT1–PT9b), oil-ring-challenge (OR-D*, PT1–PT23, retros), ring-layout, roadmap, `waves.lua`, `brain-fight.lua`, `director.lua`.

### At a glance

| | Ring 0 (first ring, "skirmish") | Ring 1 (oil ring, "boss arena") |
|---|---|---|
| Territories | 4, touching the safe zone (radius 150) | 12, the band behind ring 0 |
| Gates | Nothing new: the safe zone holds only the starting ores; ring 0 is the first ground outside it | **Oil** (only ring 1+, one guaranteed patch ~56 tiles from the closest ring-1 brain) |
| Base | Brain + nest ring at 18 tiles (4–8 nests). No worms (since OR-D105) | Same core + **4 anchor nests at 32 tiles** (the shield links) |
| Brain | `hf-brain-small`: 1125 HP (150 yellow bullets), no regen, no fissures; ash-cloud shockwave slows you and its biters | `hf-brain-ring1`: 3000 HP, no regen; shockwave edge only, half the puffs |
| Enemies | Small biters only, one shot each | Small biters only (−20 % speed), plus **shield bearers** (big biter) and **queens** (behemoth body, spawn biters) |
| Kit / era | SMG + 100 yellow magazines (red-science start) | 2 stacks red ammo, 100 shells, 20 grenades, heavy armor, level-2 damage / speed research (pre-oil) |
| Length | ~1–2 min | ~150–200 s (target 150; PT23 194 s) |
| Last result | PT9b won, 35 of 100 magazines left | PT23 won, 128 of 250 HP left |
| Status | Done for now (2026-10-18) | Done for now (OR-D112, 2026-10-24); parked for a **tutorial pass** once every ring has its kit |

### Fight shape

| Phase | Ring 0 | Ring 1 | Player's verb |
|---|---|---|---|
| Approach | Quiet base; you scout | Same | Scout, set up |
| Siege | A hit on a nest starts it; small groups 4–7 / 10 s; base stops regrowing; leaving = lost | A hit on a nest or anchor starts it; the **first nest killed wakes the brain** | Clear the base or go for the brain |
| Links | — | Brain **shut (takes 10 %)** while any anchor link lives. Killing an anchor releases a bearer that walks in next to the brain; kill it to break that link | Break the shield |
| Wake | Brain engages: groups 11–17 / 8 s from the nests, max 70 | **4 queens** come out at once, hold 50–70 tiles around you, retreat if you close in; their stream ramps up while you're calm | Hold / hunt queens |
| Surge 1 | **Swarm at 60 %**: 250 biters, each runs a wide detour to its own spot around you, then attacks; every 3rd guards the brain's front | **Swarm at 80 %** from the nests | Hold |
| Surge 2 | — | **Encircle at 55 %**: a full ring at 16 tiles that steps in, rock **arena** at 28 tiles with 4 gaps | Break out |
| Surge 3 | **Last stand**: 5 / 2 s until the brain dies | **Frenzy at 30 %**: 250 + last stand ×3, brain always open | Burst race |
| Claim | Brain dies → territory yours | Same | "I earned that ground" |

Ring 1 also has a hidden layer: the **pressure director** (damage budget 8.3 HP/s over 3 s, so ~30 s of non-stop biting kills you), **squads with a tell** (gather, pause 1.5 s, charge from 2–3 sides), a **trap / lure** when you kite (the hive pulls back into a ring around you, the brain is bait, max 2 per fight), and a **chokepoint reaction** (stops feeding a kill zone, goes round).

### Win and lose (both rings)

- **Win:** the brain dies → territory claimed (crusades may take it back later).
- **Lose:** no participant within 100 tiles of the brain for 5 s (leave or die) → brain heals, base regrows. No other fail state.

### What the playtests said

| | Worked | Didn't / still open |
|---|---|---|
| Ring 0 | Biters clearly come **from the nests**; the **swarm surrounding you** "feels very good" (PT5); the ash cloud makes the swarm outrunnable but tense; the siege trigger + phase messages (PT9); one stack of ammo with slack = skill shows as ammo left | The brain could be burst before the swarm (fixed with guards + earlier swarm); a pile-up near the end (last stand, cap 120: left as a knob) |
| Ring 1 | Each surge asks a **different verb** (PT6, PT10.2); bearers make the unlock readable; **queens all around** = "huge improvement" (PT16); the trap finally worked (PT20); spikes on purpose land (T2); telemetry-first tuning found the real causes | **Mechanic churn**: rocks built twice then switched off, too many changes per PT; **length** sits in the wake after the last nest, not the brain's HP; danger comes in bursts (70–80 % of damage in 5–14 s); **terrain can decide the fight** (a cliff choke, PT10); the frenzy cap counted queen biters (felt fine by luck); the arena / encircle wasn't singled out in later PTs |

### What the two rings share (the "constants" so far)

- **One fight per territory, towards one brain**, from approach to claim; the base is the hive's body (F8).
- **Enemies come out of buildings you can see** (nests, anchors, queens); nothing spawns around you (F10, OR-D77).
- **Many weak enemies**, being surrounded is the threat; you **keep moving** (no worms, no slows that trap you, R2-D8).
- **Phases with a new verb each**, boss-fight style (OR-D33): break the shield → hold → break out → burst.
- **Siege trigger**: attacking the base starts it; leaving loses it.
- **Every pre-gate tool is a valid answer** (OR-D2): SMG alone is a struggle, area weapons / turrets / car make it easier.

### What changes from ring 0 to ring 1

| Axis | Ring 0 → ring 1 |
|---|---|
| Numbers | Swarm 250 → 750 over three surges; wake / last stand ×2 |
| Brain | 1125 → 3000 HP; adds a **shield** (links) |
| Structure | One swarm → **three surges**, each its own verb |
| Enemy types | Small biters → + bearers, queens (still no ranged units) |
| AI | Fixed groups → director, squads, trap, chokepoint |
| Base | Nest ring → + anchor ring |
| Length | ~1 min → ~2.5–3 min |

## Decisions (user)

| # | Topic | Decision |
|---|-------|----------|
| RF-D1 | Summary (step 1) | Summary of rings 0–1 **fine** (user, 2026-10-25) |
| RF-D2 | Ring 0 gate | Ring 0 gates **exploring the world**, nothing else (user, 2026-10-25) |
| RF-D3 | Rock arena | Ring 1's rock arena (surge 2) was **"meh at best"**: retweak later (tutorial pass), not part of the feel to carry on (user, 2026-10-25) |
| RF-D4 | Ring 0 role | **A problem and a relatively easy win early on**: shows the world works differently, and is a bit of a tutorial for it (user, 2026-10-25) |
| RF-D5 | Ring 1 role | The player has **progressed a bit**; still plays into the **power fantasy**: it's a **boss-fight arena** (user, 2026-10-25) |
| RF-D6 | Ring 2 role | **Power fantasy + war.** Taking the brain should feel like a **war**: the territory is fought over, and as long as the brain lives it **fights back for every inch**. Start exploring **RTS AI** aspects here (user, 2026-10-25) |
| RF-D7 | War shape (Q1) | **Campaign**: the territory is at war from your first hit until the brain dies or you pull out. Battles in bursts with lulls between them, where you build forward positions; the hive counter-attacks ground you hold. Confirms R2-D3 (user, 2026-10-25) |
| RF-D8 | RTS AI (Q2) | **All four**: (a) **economy**: the hive has an income from living districts / nests and spends it on units and rebuilding; taking a district cuts it. (b) **targets weak points**: scouts and raids what you leave behind (lone turrets, power, ammo supply, parked vehicles). (c) **front + reinforcements**: districts help each other; the hive pushes back into lost ground. (d) **retakes ground**: fallen districts are reclaimed by an army you can stop, not just a timer (user, 2026-10-25) |
| RF-D9 | Danger (Q3) | **You win fights, the war wears**: you (on foot or tank) win almost any single engagement; the danger is attrition, holding ground is the hard part. The **core fight is the one real boss fight** (user, 2026-10-25) |
| RF-D10 | Length (Q4) | **15–30 min** per ring-2 territory: 3–5 engagements (districts, counter-attacks, core) with building and resupply between them (user, 2026-10-25) |
| RF-D11 | RTS order (Q5) | **Retakes ground first**: a fallen district is reclaimed by a hive army you can stop. Then the other three (order open, Q9) (user, 2026-10-25) |
| RF-D12 | Core fight (Q6) | **The boss scales with the war**: a ring-1-style boss fight whose strength depends on what the hive has left (districts, economy). How you fought the war shows in the end fight (user, 2026-10-25) |
| RF-D13 | Per ring (Q7) | **Focus on rings 0, 1 and 2 for now.** Gating something per ring is good *if* there is something worth gating; no fixed "gate + enemy + behaviour" rule (user, 2026-10-25) |
| RF-D14 | Hive starts fights (Q8) | **Only via crusades**: a war only runs once you start it; the hive's own attacks stay crusades on claimed territories (user, 2026-10-25). **Clarified by RF-D17:** inside a war that's already running, the hive does act on its own |
| RF-D15 | Retake (Q10) | **A retake army replaces the fallen timer**: a fallen district stays fallen until a hive army reaches it and holds it; stop the army and it stays yours. **Changes R2-D25** (20 min fallen) (user, 2026-10-25) |
| RF-D16 | Army timing (Q11) | The retake army comes **when you leave** the fallen district: holding it means staying or building defences (user, 2026-10-25) |
| RF-D17 | War is not a challenge (Q12) | Leaving the territory **doesn't end or lose the war**: the brain keeps fighting to reclaim ground, so you need defences in place. A **war state** on the territory is fine. The war ends **only** when you kill the brain, or the brain **destroys your presence and rebuilds**. **Changes** today's lose rule (100 tiles / 5 s) for ring 2 and 4e's "lost: you leave → the district regrows" (user, 2026-10-25) |
| RF-D18 | Constants (Q13) | Every ring keeps: enemies **from visible buildings**, **keep moving**, **many weak enemies**, **boss phases with verbs**. And: **start introducing stronger enemies** (ring 2) (user, 2026-10-25) |
| RF-D19 | Presence (Q14) | **Any player building** in a fallen district holds it (a pole is enough); the retake army has to destroy them all (user, 2026-10-25) |
| RF-D20 | Stronger enemies (Q15) | All candidate roles are on the table: **ranged (spitters), brutes, siege breaker, evolution**. Key point: **a swarm and a horde, but not just more and extra units: attacks must give the impression that there is thought behind them** (user, 2026-10-25) |
| RF-D21 | Hive wins (Q16) | The hive wins the war when **all districts are back** (hearts rebuilt) and nothing of yours that holds ground is left: the territory is hostile and at peace again until your next hit (user, 2026-10-25) |
| RF-D22 | War feel (Q18) | **All four** make it a war: a **front**, **readable enemy intent**, **attrition on both sides**, **objectives besides the brain**. But **never by changing things on the map** (no overlays, tags, map markers); at most for debug or PTs. The war must read **in the world** (user, 2026-10-25) |
| RF-D23 | Thought (Q19) | **All four**: it **probes, then hits weak**; **combined arms** (roles that work together); **feints and diversions**; it **adapts to you** (remembers what beat it) (user, 2026-10-25) |
| RF-D24 | Visibility (Q20) | **Scout to know**: nothing of the hive's plan is shown; radar and your own eyes tell you (user, 2026-10-25) |
| RF-D25 | Your side (Q21) | **Forward outposts**: you build and supply outposts in taken districts (turrets, ammo, power, uranium miners). The war is won by pushing your supply forward (user, 2026-10-25) |
| RF-D26 | Map rule scope (Q22) | **War only**: nothing about the war goes on the map. Existing territory colours and crusade warning / staging tags stay; revisit separately later (user, 2026-10-25) |
| RF-D27 | Tells (Q23) | Intent reads in the world through **visible massing** (an army gathers at a heart / staging spot before a real attack) and **scouts first** (probing groups at your outposts before the main attack) (user, 2026-10-25) |
| RF-D28 | Tempo (Q24) | **Both**: you choose when to attack a district; the hive acts on its own clock in between (probes, retakes when you leave, raids). Lulls are the hive rebuilding its strength (user, 2026-10-25) |
| RF-D29 | Nests after the heart (Q17, 4e Q26) | The district's nests **stay but stop spawning**; you clear them to build there; **the retake army wakes them** (user, 2026-10-25) |
| RF-D30 | First retake army (Q25) | **Simple + tell**: it masses visibly at the core, marches to the fallen district once you've left, destroys every building there, then wakes the nests and rebuilds the heart. Probes, combined arms, feints, adapting come later, **one per PT** (user, 2026-10-25) |
| RF-D31 | Leaving a district fight (Q26) | **Heart heals, war goes on**: nothing lost or won; the heart heals over time, lost nests regrow as today, the territory stays at war (user, 2026-10-25) |
| RF-D32 | Help in a district fight (Q27, 4e Q28) | **None in the first PT**: only the district's own nests and heart. Reinforcements come as their own RTS step later (user, 2026-10-25) |
| RF-D33 | District units (Q28, 4e Q29) | **Small biters + medium biters** (brutes first) in the first PT; spitters and other roles later (user, 2026-10-25) |
| RF-D34 | Retake army = crusade | A retake army is a **crusade inside the territory**; the vision's smarter-crusade-AI ideas apply to the war AI (user, 2026-10-25). Answers RF-I3 |
| RF-D35 | Shared hive AI (Q36) | **One hive-AI module, war first**: the operational layer (armies, squads, influence map) is built for the war; crusades move onto it later in their own step, so today's crusade code stays untouched for now (user, 2026-10-25) |
| RF-D36 | Influence map (Q37) | **Yes, as the base**: a hidden per-chunk map of threat / value / control is the hive's memory; probing, hit-weak, adapting, feints and the front read from it. Debug view for PTs only (RF-D22) (user, 2026-10-25) |
| RF-D37 | Commit rule (Q38) | **Predict, then wait or switch**: the hive weighs its army against the threat at the target (Lanchester); too strong a defence → mass more (a lull) or pick a weaker target. Its strength grows over time, so a turtled outpost gets hit eventually (user, 2026-10-25) |
| RF-D39 | Playtest first (Q40) | **Playtest as soon as there is enough to play**, before building more. So the combat prediction (RF-D37) comes **after** the 4e2 PT, as the first "thought" step (user, 2026-10-25) |
| RF-D40 | Digestion pools (idea) | User idea (2026-10-25), from Warhammer's Tyranids (soldiers go into pools for material): when the hive predicts it **can't win** a battle, it can **melt down N small biters into something bigger**. A third answer next to "mass more" and "pick a weaker target" (RF-D37) |
| RF-D41 | Pool spot (Q41) | A **new digestion-pool building** next to each heart / the core (placeholder art): readable when scouted, and a target worth raiding (user, 2026-10-25) |
| RF-D42 | Pool output (Q42) | **Whatever wins**: the prediction picks the mix it needs (brutes vs turrets, ranged vs walls, siege breakers). Most "thought", most work. Tension with "many weak enemies" (RF-D18) left open: watch in the PT (user, 2026-10-25) |
| RF-D43 | Pool timing (Q43) | **With the prediction**, in the same "thought" step after the 4e2 PT: "can't win" → wait, switch target, or melt (user, 2026-10-25) |
| RF-D44 | Harder = costly (Q44a, ring-2 Q40) | A district fight is a **costly win**: with your ring-2 kit you win, but it costs real ammo, HP, maybe turrets and a retreat or two; **~3–5 min per district**. Keeps RF-D9 (user, 2026-10-25) |
| RF-D45 | District defence (Q44b) | **Garrison + rebuild**: a district holds a **visible standing garrison** around its heart (a real army); you beat the garrison while the nests and heart keep rebuilding it. Its size sets how hard the district is. Replaces timer waves as the main defence (user, 2026-10-25) |
| RF-D46 | Combat roles (Q44c) | **All four**, each answering something you do: **brute** (soaks turret / SMG fire for the swarm behind it), **spitter** (out-ranges turrets and campers; puddles hurry you), **hunter** (fast, fragile; chases kiters and the tank), **sapper** (ignores you, blows up on buildings: breaks outposts) (user, 2026-10-25) |
| RF-D47 | Functional hive roles (Q44c) | User (2026-10-25): **very functional roles** in the hive itself. **A brain may produce no units at all.** **Queens and nests need a clear relation.** A **unit that can found a nest**, and one that can found a **district heart**; likewise a **unit that becomes a brain** (building / guardian). The hive grows by units walking out and settling, not by things popping in. Details: Q46–Q49 |
| RF-D48 | Districts in the way (Q45, ring-2 Q41) | **Zone of control**: each live district senses you within ~80 tiles and sends its garrison after you. At 115 tiles out the zones touch, so slipping between two districts means fighting both. No wall (R2-D8): you can run through, it just costs (user, 2026-10-25) |
| RF-D49 | Production chain (Q46) | **Queens are founders**: nests make combat units and queens; a queen makes combat units while she moves and can **settle into a new nest**; a heart makes queens plus an **elder queen** that settles into a **heart**. Every building comes from a unit you can kill on the way (user, 2026-10-25) |
| RF-D50 | Regrowth by founders (Q47) | **Ring 2 first**: a lost nest / heart comes back because a queen / elder queen walks from a living piece and settles; the retake army brings an elder queen to rebuild the heart. Rings 0–1 keep pop-in regrowth until the tutorial pass (user, 2026-10-25) |
| RF-D51 | Brain seed (Q48) | **From a heart**: a district heart raises the brain seed a crusade carries (vision: the mobile brain unit that grows at the rally). Taking districts also stops the hive from founding new brains (user, 2026-10-25) |
| RF-D52 | Brain makes no units (Q49) | **Ring 2 now, rings 0–1 later**: ring 2's wake / core fight (4f) is built with it; rings 0–1 keep spawning from the brain once the nests are dead (OR-D30, D84) until the tutorial pass (user, 2026-10-25) |
| RF-D53 | Build order (Q50) | **Harder first**: next PT = **garrison + zone of control** (RF-D45, D48) with brutes (medium biters today). Then **4e2 retake army** with an elder queen rebuilding the heart (RF-D50), then **founders for regrowth**, then **new roles one per PT**; prediction + digestion pools after the retake PT (RF-D43) (user, 2026-10-25) |
| RF-D38 | First retake army (Q39) | Gets **leash + ignore decoys** and **retreat at half strength** (survivors return to the hive). Threat first and minimum guard come later (user, 2026-10-25) |

## Ring roles (from the decisions)

| Ring | Role | Player feels | Fight model |
|---|---|---|---|
| 0 | Problem + easy win, tutorial; gates exploring (RF-D2, D4) | "This world works differently" | Challenge (one fight, ~1–2 min) |
| 1 | Progressed player, power fantasy, boss arena; gates oil (RF-D5) | "I beat the boss" | Challenge (one boss fight, ~2.5–3 min) |
| 2 | Power fantasy + **war**; gates uranium (RF-D6) | "I won a war: I took ground, held it, and the brain fought back for every inch" | **War state** (campaign, 15–30 min, 3–5 engagements), ending in a boss fight that scales with the war (RF-D7, D10, D12) |
| 3+ | Not now (RF-D13) | — | — |

### Ring 2 as a war (summary of RF-D7–D33)

- **War state.** Your first hit on a ring-2 base starts a war on that territory. It is **not a challenge**: leaving doesn't lose it. It ends when the **brain dies** (claimed) or the hive **retakes every district** and nothing of yours holds ground (RF-D17, D21).
- **Your side.** You take districts one at a time (you pick when) and build **forward outposts** there: turrets, power, ammo, uranium miners (RF-D25, D28). Any building holds a fallen district (RF-D19).
- **The hive's side.** It wants its ground back. When you leave a fallen district, a **retake army** masses visibly at the core, marches, destroys your buildings, wakes the quiet nests and rebuilds the heart (RF-D15, D16, D29, D30). No more fallen timer.
- **Thought, not numbers.** A swarm and a horde, but attacks must look planned: probe then hit weak, combined arms, feints, adapting. Added **one per PT**, after the retake army (RF-D20, D23).
- **Scout to know.** Nothing about the war goes on the map; you read intent in the world: armies massing, scouts probing your outposts (RF-D22, D24, D26, D27).
- **The end.** The core fight is the one real boss fight, and its strength **scales with what the hive has left** (RF-D12).
- **Same as rings 0–1:** enemies from visible buildings, keep moving, many weak enemies, boss phases with verbs; plus stronger enemies start here (RF-D18).

## War AI from the crusade-AI ideas (step 6, started 2026-10-25)

User (2026-10-25): explore the concepts from [vision-plan.md](vision-plan.md) "Later: smarter crusade AI" (line 739) for the war AI too. A retake army is a **crusade inside the territory**, so they fit.

| Concept (vision) | What it gives the war | Serves |
|---|---|---|
| **Three layers** (strategic / operational / tactical, AI War) | Strategic = the hive's war brain: what to take back, when, with how much (economy). Operational = armies and squads: retake army, probes, raids. Tactical = Factorio unit groups + ring 1's squad tell / charge | RF-D8 (all four RTS parts get a home) |
| **Influence map** per chunk (Dave Mark) | The hive's hidden memory: **threat** (your turrets, where its units died, damage types), **value** (your buildings, fallen districts, uranium miners), **control** (hive vs you). Fed from `on_entity_damaged` / `on_entity_died`, not scans. Never drawn on the map (RF-D22) | Probe then hit weak, a front, adapting, feints (RF-D23) |
| **Combat outcome prediction** (Lanchester: strength ≈ count² × DPS) | Before committing, the hive compares its army with the threat at the target: attack, mass more (a lull, RF-D28), or pick a weaker target | "Thought" (RF-D20), attrition (RF-D22), lulls |
| **POC crusade fixes**: leash, threat first, several squads sized by threat, minimum guard, ignore decoys, retreat / regroup at half strength | The army doesn't get pulled away by a decoy, retreats instead of dying to the last unit, leaves a guard on a retaken district | Retake army that doesn't look dumb (RF-D30) |

How the four kinds of thought (RF-D23) fall out of it:

- **Probe, then hit weak:** a probe squad's losses write threat into the map; the real army picks the target with the best value / threat.
- **Adapt:** threat remembers where and by what the hive lost units (flamethrower line, tank); the mix / route avoids it next time.
- **Feint:** a cheap squad at a high-threat spot to pull you, the army at a low-threat one.
- **Front:** the line where hive control meets yours; the hive pushes where control is contested and your threat is low.

Decided (RF-D34–D43): one shared hive-AI module, war first; the influence map is its base; the hive commits only on a predicted win; the first retake army leashes, ignores decoys and retreats at half strength. Playtest before building more (RF-D39). **Digestion pools** (Tyranid idea): a pool building next to each heart / the core melts small biters into whatever the prediction says wins; comes with the prediction step (RF-D40–D43).

War AI build order (proposal): **4e1** war state + district fight → PT → **4e2** influence map + retake army (leash, decoys, retreat) → PT → **thought 1** combat prediction + digestion pools → PT → then probes, combined arms, feints, adapting, economy, raids, reinforcements, one per PT.

## Harder districts, districts in the way (step 7, started 2026-10-25)

Asked by the ring-2 session after its **PT1 (4e1)**: "way too easy, fine as a draft"; the heart is neither a goal you need nor does killing it feel like anything; a second district isn't progress (R2-D29). Two questions from [ring2-challenge-plan.md](ring2-challenge-plan.md), numbered here **Q44** (= ring-2 Q40) and **Q45** (= ring-2 Q41).

Today (4e1): 4 districts at 115 tiles, 90° apart, so ~160 tiles between neighbours (~125 of open ground beside the district disks). A fight = timer waves every 8 s, 4–7 units (~30 % medium), max 40 alive.

**Tension:** RF-D9 says "you win almost any single engagement; the danger is attrition". "Way harder" fits that only if harder means **costly**, not **lost**. Answered: costly (RF-D44).

Decided (RF-D44–D48): a costly win (~3–5 min per district) against a **standing garrison** the district rebuilds; four combat roles (brute, spitter, hunter, sapper); **zone of control** puts districts in the way; and a **functional hive** where units found nests, hearts and brains, and the brain makes no units (RF-D47, details Q46–Q49).

### Hive life cycle (RF-D47, D49–D52)

| Piece | Makes | Becomes |
|---|---|---|
| Brain | **Nothing** (ring 2+; rings 0–1 later): thinks (strategic layer), shields, fights in the core fight | — |
| District heart | Queens, **elder queens**, **brain seeds** (for crusades) | — |
| Nest | Combat units (swarm, brute, spitter, hunter, sapper) and queens | — |
| Queen | Combat units while she moves (as in ring 1) | Settles into a **nest** |
| Elder queen | (Combat units, like a queen: open) | Settles into a **heart** |
| Brain seed | — | Grows into a **brain** (crusade rally) |
| Digestion pool | Melts units into what the fight needs (RF-D40–D43) | — |

Regrowth in ring 2 = a queen / elder queen walks out and settles (RF-D50). Kill her on the way and the piece doesn't come back.

### Effect on the ring-2 plan (for the ring-2 session)

| Item | Was | Now | By |
|---|---|---|---|
| Next step | 4e2 retake army | **Garrison + zone of control** first (its own PT), then 4e2 | RF-D53 |
| 4e1 timer waves (8 s, 4–7, max 40) | Main defence | A **standing garrison** around the heart (size = difficulty), rebuilt by nests + heart during the fight; waves at most a supplement | RF-D45 |
| Fight start | A hit within the heart's rim (18) | Also: you come **within ~80 tiles** of a live district → its garrison comes for you (zone of control) | RF-D48 |
| District target | — | Costly win, **~3–5 min** per district with the ring-2 kit | RF-D44 |
| R2-D24 / 4c layout | 4 districts at 115, 90° apart | **Kept**; the ~80-tile zones make them touch (no new layout) | RF-D48 |
| 4e2 retake army | Rebuilds the heart | Brings an **elder queen** that settles into the heart | RF-D50 |
| `regrow.lua` (ring 2) | Pop-in, 1 piece / min | **Founders**: a queen walks out and settles into a nest, an elder queen into a heart | RF-D50 |
| 4f core fight | Ring-1-style, wake / last stand from the brain | **Brain makes no units** in ring 2: units come from nests, queens, hearts | RF-D52 |
| New Hostile-fauna units | Medium biters only (R2-D28) | Brute, spitter, hunter, sapper (combat); queen (ring 2), elder queen, brain seed (life cycle). One per PT | RF-D46, D49, D51 |
| Crusades (later step) | Rally builds a brain | A heart raises the **brain seed** the crusade carries | RF-D51 |

Open (first guesses for the spec): garrison size per district, how fast it rebuilds, zone radius (~80), whether the garrison of a neighbouring district joins when you're in both zones.

## Effect on R2-E1 / R2-D* / 4e (step 3)

For the ring-2 session. Nothing here is edited in [ring2-challenge-plan.md](ring2-challenge-plan.md); that session owns it.

### Confirms

| Item | By |
|---|---|
| R2-D1 uranium gate, R2-D18 / D21 guaranteed uranium inside a district | RF-D6, D13; uranium is an **objective besides the brain** (RF-D22) and a reason for an outpost (RF-D25) |
| R2-D2 districts, R2-D3 siege campaign, R2-D24 4 districts | RF-D7 (campaign) |
| R2-D5 / D15 tank allowed, "the tank is the reward" | RF-D6, D9 (power fantasy, you win the single fights) |
| R2-D8 keep moving, R2-D7 / D14 no worms | RF-D18 |
| R2-D22 districts are the brain's shield links | RF-D12 (a first form of "the boss scales with the war") |
| R2-D23 heart spawns units | RF-D18 (enemies from visible buildings) |
| 4e start: a hit within the rim of a heart starts that district's fight; waves come out of the district's nests | RF-D7, D18 |
| 4e Q26 (nests after the heart) → **stay, stop spawning** | RF-D29 |
| 4e Q28 (brain squads in a district fight) → **none** in the first PT | RF-D32 |
| 4e Q29 (district units) → **small + medium biters** | RF-D33 |

### Changes

| Item | Was | Now | By |
|---|---|---|---|
| R2-D25 fallen time | Fallen 20 min, then regrow | **No timer**: fallen until a **retake army** takes it back; the army comes when you leave | RF-D15, D16 |
| R2-E1 counter-attacks | Every 3 min a core squad at the player building nearest the brain | **Dropped as specced.** The retake army is the first hive action; weak-point raids are a later RTS step. 4e Q27 is obsolete | RF-D8, D11 |
| 4e "Lost: you leave → the district regrows" | District regrows normally | **Heart heals, lost nests regrow, war goes on** | RF-D31 |
| Territory state for ring 2 | Challenge (lost by leaving: 100 tiles / 5 s) | A **war state** that leaving doesn't end; ends on brain death or hive win (all districts back, nothing of yours holding ground) | RF-D17, D21 |
| R2-E1 "Core fight lost → core regrows, fallen districts keep their timer" | Timer | No timer; the war goes on (core fight's own lose rule: Q31) | RF-D15, D17 |
| 4e step order | One step: district fight + fallen timer + counter-attacks | Suggest **4e1** war state + district fight + fallen (quiet nests), **4e2** retake army (simple + tell, leash / decoys / retreat, its own PT) on a new **shared hive-AI module** with the influence map; crusades move onto it in a later step of their own | RF-D11, D30, D35–D38, one change per PT |
| Length target (4i) | Not set | **15–30 min per territory**, 3–5 engagements | RF-D10 |
| R2-Q6 enemy mix | Open | Stronger enemies start in ring 2; mediums first (RF-D33), other roles later | RF-D18, D20 |

### Questions (for the ring-2 session, or a next round here)

- **Q29. District waves vs "thought".** 4e's waves are "every 8 s, 4–7 units at the nearest participant": a timer, not a plan. Fine for 4e1 (thought comes later, RF-D23), or should district fights already use ring 1's squads with a tell?
- **Q30. Creep fire vs the map rule.** RF-D22 / D26 is about markers, overlays and tags. Creep burned back by fire (W1) changes tiles, which also shows on the map. Assumed OK (it's the world, not a marker). Confirm.
- **Q31. Core fight lose rule.** Ring-1-style (leave → the brain heals) while the war goes on? Assumed yes.
- **Q32. What scales the boss (RF-D12)?** R2-D22's shield per live heart is one lever. Others: surge sizes from the hive's strength, queens per live district. Decide in 4f.
- **Q33. When is a district "left" (RF-D16)?** First guess: no player within 100 tiles of the heart spot for 30 s, then the army starts massing.
- **Q34. Retake army size and massing time** (first guesses for 4e2): size from live districts (as the dropped counter-attack: 10 + 5 × live districts), massing ~60 s at the core, so radar or eyes can catch it.
- **Q35. After the hive wins the war (RF-D21):** does the brain heal, and do player buildings outside the districts stay (they don't hold ground)?
- ~~**Q40.**~~ → RF-D39 (prediction after the 4e2 PT).

## Confirmed facts (2026-10-25)

- **Ring 2 today** (built, [ring2-challenge-plan.md](ring2-challenge-plan.md) 4a–4d): J 0.2 points (a near-continuous hive belt), uranium only ring 2+, water bases move onto land (every ring), **4 districts per base** at ~115 tiles (violet `ht-district-heart` + 6 nests), guaranteed uranium under the spawn-facing district of the 3 closest ring-2 territories. Ring-2 brains are still the unkillable medium / big brains (B-I11) until 4f.
- **Ring 2 as specced (R2-E1, approved 2026-10-24):** siege campaign (C2): a district fight per district, fallen 20 min, counter-attacks every 3 min at your forward buildings, creep + egg pods between districts, then a ring-1-style core fight with the hearts as shield links.
- **Kit era at ring 2** (vanilla tech tree): flamethrower, rockets, land mines, poison / slowdown capsules, modular armor + personal shield, laser turrets, **tank** (allowed, R2-D5; "the tank is the reward", R2-D15).
- **Rings beyond:** every ring bigger (R2-D6); ring 3 bigger districts, ring 4 a second layer of districts (R2-D13). Base radius is capped near ~170 tiles at G = 384.
- **Ring 1 lessons for ring 2** (oil-ring retro 2): find the slow phase in telemetry before cutting HP; check what a cap counts; one change per PT; same PT hand-off shape.

## Issues

| # | Issue | Note |
|---|-------|------|
| RF-I1 | Rings 0–1 may change in the tutorial pass | Whatever ring 2+ needs the player to know, rings 0–1 should teach later (roadmap fog, OR-D112). New from this plan: rings 0–1 never ask you to **hold ground or defend buildings**, which ring 2's war needs (RF-D25) |
| RF-I2 | Ring 2 is a new fight model | Rings 0–1 are challenges (one fight, lost by leaving); ring 2 is a war state. `challenge.lua`, `regrow.lua` and the territory states in the vision assume challenges. Touches the vision's core loop |
| RF-I3 | ~~Crusade vs retake army~~ | ~~Two systems that both reclaim ground should feel related.~~ Answered: a retake army is a crusade inside the territory, on one shared hive AI (RF-D34, D35) |
| RF-I6 | "Brain makes no units" vs ring 1 | Ring 1's last stand and wake come out of the brain once the nests are dead (OR-D30, D84). Kept until the tutorial pass (RF-D52) |
| RF-I7 | Many new units | Brute, spitter, hunter, sapper, queen (ring-2 version), elder queen, brain seed: Hostile-fauna prototypes, placeholder art. One per PT means a long road; order in Q50 |
| RF-I5 | Crusade code moves later | RF-D35 means `crusade.lua` / `rally.lua` / `army.lua` get ported onto the hive-AI module in their own step (vision / territory-recapture), not part of ring 2 |
| RF-I4 | RTS scope | All four RTS parts (RF-D8) + four kinds of "thought" (RF-D23) is a lot of mechanics. One per PT (retro lesson), retake army first (RF-D11) |

## Steps

- [x] 1. Summary of rings 0 and 1 (2026-10-25). Checked by the user (RF-D1–D3).
- [x] 2. Interview: ring roles, war shape, RTS AI, war feel, first retake army, district fight details: RF-D4–D33 (2026-10-25).
- [x] 3. Effect list on R2-E1 / R2-D* / 4e: confirms, changes, questions (2026-10-25, above).
- [x] 4. Hand-over note for the ring-2 session (2026-10-25): `side-session-notes/local_6d995a27-…/ring-feel-handover.md`.
- [ ] 5. Ring-2 session revisits the 4e spec (4e1 / 4e2 split suggested) and answers Q29–Q35 there or here.
- [x] 6. War AI from the vision's crusade-AI ideas: RF-D34–D38; playtest first, digestion pools: RF-D39–D43 (2026-10-25). Hand-over note updated.
- [x] 7. Harder districts, districts in the way, functional hive (ring-2 Q40 / Q41 after PT1): RF-D44–D53 (2026-10-25). Hand-over note updated.

## Open questions

- ~~**Q17.**~~ → RF-D29.
- **Q9. Order of the other RTS parts** after retakes: economy, weak-point raids, front + reinforcements. Later.
