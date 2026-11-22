# Ring 2 Challenge

> **Status:** Brainstorm done (R2-D1–D18), interview done 2026-10-24 (R2-D19–D26: shrink-to-fit water bases in every ring, uranium in a district of the 3 closest territories, districts as shield links, 4 tanky-spawner districts at 115, 20 min fallen, creep blotches). **R2-E1 spec approved** 2026-10-24 · **Parent:** [ring-layout-plan.md](ring-layout-plan.md), [oil-ring-challenge-plan.md](oil-ring-challenge-plan.md), [challenge-feel-plan.md](challenge-feel-plan.md) · **Next:** 4a ✅, 4b ✅ (incl. B-I10 fix, in game 2026-10-25). **4c districts ✅** (headless + in game 2026-10-25). **4d uranium ✅** (headless + in game 2026-10-25). Ring feel done ([ring-feel-plan.md](ring-feel-plan.md): ring 2 is a **war**, R2-D27). **4e split: 4e1** war state + district fight ✅ built, **PT1 done** (2026-10-25: works, but too easy and taking a district means nothing yet → R2-D29: retake army + way harder). Q40 / Q41 answered by ring feel (RF-D44–D53 → R2-D30–D32): **4e1b PT2 done 2026-10-26**: works, far too easy (23–53 s per district, 0 HP lost), brutes don't read; crash on the last heart fixed; next: **4e1c big biters in the garrison** (R2-D34, spec drafted, waiting for go-ahead), then PT3, then 4e2 retake army, 4f core fight · [Roadmap](roadmap.md)

Started 2026-10-24 (game 2.1.21). Ring 2 in the code = the 20 territories behind the oil ring (RL-D4), cells 768–1150 tiles out.

## Goal

- Ring 2 **gates something** the player needs next, like ring 1 gates oil (RL-D2).
- The ring-2 base is **much bigger**: real distance to fight through before you reach the brain (user, 2026-10-24).
- Escalation from ring to ring: ring 0 = skirmish, ring 1 = boss arena (oil-ring challenge), ring 2 = siege.

## Decisions (user)

| # | Topic | Decision |
|---|-------|----------|
| R2-D1 | Gate (Q1) | **G1: uranium only from ring 2**, to start with (2026-10-24) |
| R2-D2 | Shape (Q3) | **S2: districts** linked to the brain, to start with (2026-10-24) |
| R2-D3 | Structure (Q5) | **C2: siege campaign**, to start with (2026-10-24) |
| R2-D4 | Size (Q4) | **Radius 150 tiles** to start (2026-10-24) |
| R2-D5 | Tank (Q2) | **Allowed** (2026-10-24) |
| R2-D6 | Rings beyond (Q7) | **Every ring further out gets bigger**, not just ring 2 (2026-10-24) |
| R2-D7 | Worms | User likes the *idea* of worm fields between parts of the base, but **dislikes worms** in the game. Discuss alternatives here (Q8) (2026-10-24) |
| R2-D8 | Why no worms (Q8) | The mod is balanced around **the player keeps moving**. Worms cut off movement. **Rule for every field idea: it may threaten or hurry you, never stop or block you** (2026-10-24) |
| R2-D9 | Hive belt (Q9) | **Try it**: ring 2 almost all base, narrow gaps, points near the cell centre (J ≈ 0–0.2) (2026-10-24) |
| R2-D10 | Rings beyond 2 (Q10) | **Probably bigger districts** (2026-10-24). See Q12 for what that means once the radius is capped |
| R2-D11 | Worms in rings 0–1 (Q11) | **Probably remove** them there too: they don't add much (2026-10-24). Touches the base layout every ring uses (Q13) |
| R2-D12 | Field (Q8) | **Try W1 + W2**: creep without slow (standing still hurts, draws squads; flamethrower burns it back) + egg pods. User unsure, so a first try to playtest (2026-10-24) |
| R2-D13 | Layers (Q12) | **Bigger districts in ring 3, a second layer of districts from ring 4** (2026-10-24) |
| R2-D14 | Worm core replacement (Q13) | **Nothing**: the brain + nest ring is enough (2026-10-24). Rings 0–1 already have no worm core (oil-ring OR-D105, built 2026-10-24); ring 2+ still has one, it goes with the ring-2 build |
| R2-D15 | Tank answer (Q14) | **None for now**: the tank is the reward (2026-10-24) |
| R2-D16 | Point offset (Q15) | **J 0.2** for ring 2+ points, to try (2026-10-24) |
| R2-D17 | Water (Q16) | **Territories with water get a base too**, with fewer districts (only on land). Today a point on water means claimed, no base (`brain.lua`); for ring 2+ the brain and districts move onto land instead (2026-10-24). Details: Q18, Q19 |
| R2-D18 | Uranium (Q17) | **Guaranteed uranium** in ring 2, plus no uranium before ring 2 (2026-10-24). Where exactly: Q20 |
| R2-D19 | Almost-all-water (Q18) | **Shrink to fit**: the brain moves to the biggest land spot in its territory and gets as many districts as fit, down to 0 (brain + nest ring only). No land at all → claimed, as today (2026-10-24) |
| R2-D20 | Water in rings 0–1 (Q19) | **Yes, now**: rings 0–1 water territories get their base on land too, same code, in the same build step as ring 2 (2026-10-24). Ends the "claimed only after exploring" behaviour (roadmap fog) except for territories with no land |
| R2-D21 | Uranium spot (Q20) | **Inside one district** of each of the **2–3 ring-2 territories closest to spawn**: take the district, get the ore (2026-10-24) |
| R2-D22 | Core opening | **Districts are shield links**, like the ring-1 anchors (E8-A2): each live district heart cuts the damage the brain takes; all down → fully open (2026-10-24) |
| R2-D23 | District heart (Q21) | **Big tanky spawner** (`ht-district-heart`, spawns units, placeholder: scaled + tinted biter spawner) (2026-10-24) |
| R2-D24 | District count (Q22) | **4** per ring-2 base, 90° apart at 115 tiles (2026-10-24) |
| R2-D25 | Fallen time (Q23) | ~~**20 min**, then the district regrows (2026-10-24)~~ → R2-D27 |
| R2-D27 | Ring 2 is a war (ring-feel) | From [ring-feel-plan.md](ring-feel-plan.md) (RF-D7–D33, 2026-10-25): a **war state** that leaving doesn't lose; a fallen district stays fallen until a **retake army** takes it back (no timer); its nests stay but go quiet; leaving a district fight → the heart heals, the war goes on; no core help in a district fight; small + medium biters; the 3-min counter-attacks are dropped (raids come later). 4e split into **4e1** (war state + district fight) and **4e2** (retake army) |
| R2-D29 | District meaning (Q39, after PT1) | **Retake army (4e2)** gives it meaning. Otherwise mostly unsure; either way a district must be **way harder** than PT1. Maybe enough: districts **physically in the way** of the brain. More units / roles could help, but only with a real purpose, not just extra units (user, 2026-10-25). Q40, Q41 |
| R2-D28 | 4e1 details (Q36–Q38) | **Timer waves** (every 8 s, 4–7; planned-looking behaviour comes as later RTS steps); **fixed ~30 % medium biters**; ring-feel's assumptions OK: burned creep may show on the map (4g), the core fight is lost by leaving while the war goes on (4f) (user, 2026-10-25) |
| R2-D30 | Harder districts (Q40 → ring-feel Q44) | From [ring-feel-plan.md](ring-feel-plan.md) RF-D44–D46 (2026-10-25): a district is a **costly win**, ~3–5 min with the ring-2 kit (ammo, HP, maybe turrets, a retreat or two), never a likely loss (RF-D9). Main defence = a **visible standing garrison** around the heart that the nests and heart rebuild during the fight; its size sets the difficulty; timer waves at most a supplement. Four combat roles with a purpose: **brute** (soaks fire for the swarm), **spitter** (out-ranges turrets / campers), **hunter** (fast, chases kiters and the tank), **sapper** (blows up buildings); **brutes first** (medium biters today), the others one per PT |
| R2-D31 | Districts in the way (Q41 → ring-feel Q45) | RF-D48: **zone of control**, no new layout. Each live district senses you within **~80 tiles** and sends its garrison after you; at 115 tiles out the zones touch, so slipping between two districts means fighting both. No wall (R2-D8): you can run through, it costs. R2-D24 layout (4 at 115) kept |
| R2-D32 | Functional hive + build order (ring-feel Q46–Q50) | RF-D47, D49–D53: every building comes from a unit you can kill. Nests make combat units and **queens** (settle into a nest); the heart makes queens, **elder queens** (settle into a heart) and **brain seeds** (crusades); the **brain makes no units** in ring 2 (4f). Ring-2 regrowth by **founders** (a queen walks out and settles), rings 0–1 keep pop-in. Order: **4e1b garrison + zone of control** → PT → **4e2** retake army with an elder queen → PT → **4f** core fight (moved up, R2-D33) → **4e3** founders → **4e4** new roles, one per PT; prediction + digestion pools after the 4e2 PT |
| R2-D33 | 4e1b details (Q42–Q49) | **Garrison exists** while a player character is near (~200 tiles) **or the heart's chunk is visible** to the player force (radar: `LuaForce.is_chunk_visible`), else it's kept as a count. **Heart killed stops the rebuild** (the heart is the goal: dive it or grind the garrison). **A share comes** when you enter the zone (half), the rest holds the heart and joins when you're within ~40 tiles. **Timer waves dropped.** On the heart's fall the rest of the garrison **walks to the nearest live district** (else the core). **Two zones → both** send their share. Balance against a **new `/cheat-kit ring2`** (blue era, no tank). **4f moves right after 4e2** (user, 2026-10-26) |
| R2-D34 | After PT2 (Q50, Q52) | **Tougher garrison by adding big biters** to the small + medium mix (one change for PT3). **`/cheat-kit ring2` is a fair baseline**, keep it (user, 2026-10-26). Q51 (brute look) answered with it: the big biter is the readable brute for now |
| R2-D26 | Creep (Q25) | **Map gen, noisy blotches** over ~50 % of the band 40–150 tiles, outside the district disks (2026-10-24) |

## Confirmed facts (2026-10-24)

- **Base today** (`brain-bases.lua`): worm core at 6 tiles, nest ring at 18, anchor ring (ring 1+) at 32. Everything fits in a 32-tile radius.
- **Territory border** = nearest point by **Manhattan** distance (`nauvis-territory.lua`). Room from a brain to its border along an axis = half the gap to the neighbour's point. Points are offset up to ±J × G/2 (J = 0.8, G = 384), so the worst case is **G(1 − J)/2 = 38 tiles**. Diagonally the border is further (|x| + |y| = 384 → 271 tiles at 45° for centred points).
- Slots past the border just aren't placed (each tile computes from its *own* point), so a base too big for its room gets **cut off on that side**.
- **Ring-2 brain** is still "by distance" (medium / big); OR-D4 says one brain per ring → a `hf-brain-ring2` would follow. Medium and big brains out-regenerate railgun and nukes today (B-I11).
- **Tech tree** (vanilla `base/prototypes/technology.lua`, Space Age may shift some):

| Tech | Needs | Era |
|---|---|---|
| Flamethrower | flammables (oil), military science | Green + military, **right after oil** |
| Rocketry, land mines | explosives, military science | Green + military |
| Military 3 (poison, slowdown capsules) | chemical science | Blue |
| Laser turrets, personal shield | chemical science / military science | Blue |
| Tank | military 3, explosives | Blue |
| Uranium mining | chemical science, concrete; needs sulfuric acid (oil) | Blue |
| Uranium ammo | uranium processing, military 4, tank | Yellow (utility) |

So with G1 you arrive with blue-era tools: flamethrower, rockets, land mines, poison / slowdown capsules, modular armor + shield, laser turrets, tank.

## What 150 tiles means (headless ✅ 2026-10-24, 2.1.21, step 3)

Theory (worst case on paper): room to the border G(1 − J)/2 = 38 at J 0.8, 115 at 0.4, 154 at 0.2, 192 at 0. Measured with `tools/ht-ring2-check/` on seeds 12345 / 987654 / 555 (the real points; other J values rebuilt from the same per-cell offsets, check 0 tiles off):

| J | Room on the worst side, ring 2: min / median | Share of the 150-disk in a neighbour's territory: avg / worst | Gap between neighbouring bases: min / median | Overlapping base pairs (of 136) |
|---|---|---|---|---|
| 0.8 (today) | 54–113 / 122–146 | 1–7 % / 5–25 % | −178 / ~185 | 3–14 |
| 0.4 | 114–128 / 143–160 | 0.1–0.9 % / 2–4 % | −49 / ~180 | 1–5 |
| **0.2** | **146–152** / 164–175 | **0 %** / 0.1 % | **18–26** / ~205 | **0** |
| 0 | 192 / 192 | 0 % | 84 / 243 | 0 |

- **J 0.2 just fits** a 150-tile base: 0–3 of 72 directions per ring fall short by a few tiles, nothing clipped worth counting. **J 0.15** would give a safe margin; J 0 gives an even grid with 84+ tile gaps.
- Ring 3 looks the same (J 0.2: min room 146–150, 0 overlaps), so the same J works for every ring ≥ 2.
- **Water is the bigger problem.** Land share of the 150-disk per ring-2 territory: most 60–100 %, but **several 34–58 %**, and **1 per seed is almost all water** (1–4 %, starts claimed). Districts must be placed on land by script (like `oil.lua`), not by fixed noise slots.
- **Uranium today** (±1280 tiles generated):

| Seed | Patches ring 0 / 1 / 2 / 3 | Nearest | Ring-2 patches: distance to the brain |
|---|---|---|---|
| 12345 | 0 / 1 / 1 / 3 | 407 (ring 1) | 301 |
| 987654 | 1 / 2 / 4 / – | 491 (**ring 0**) | 61, 113, 248, 82 |
| 555 | 1 / 1 / 1 / 5 | 379 (**ring 0**) | 98 |

  Vanilla puts uranium in **ring 0 on 2 of 3 seeds** and in ring 1 on all 3, and ring 2 often has **just 1 patch**. So the gate needs both levers from oil: uranium × (ring ≥ 2) (R1-2) and a guaranteed patch (R1-3). Patches are big (400–860 ore tiles, 1.4–3.7 M each). Most ring-2 patches lie 60–250 tiles from the brain: **inside a 150-tile base**.

What follows for the design:

- A 150-tile base is ~300 tiles wide in a ~384-tile territory: **the base is most of the territory**. Ring 2 becomes an almost **continuous hive belt** with narrow gaps between bases.
- Ring-2 points need **J ≈ 0–0.2** (near the cell centre): the ring-2 grid looks regular. Ring is the cell layer, so J doesn't change which ring a territory is.
- **Uranium patch** (guaranteed, like R1-3) would sit **inside a base** almost by force. Fits the gate: take the district, get the ore.
- "150" can mean the **outer edge of the districts**, e.g. district centres at ~110–120 and district radius ~30.

## Districts (S2), first sketch

- **3–5 districts** around the brain, each a small nest ring around a **district heart** (lesser brain or queen nest), linked to the brain like the anchors (E8-A2).
- The core opens once **enough districts fall** (all? N − 1?). You choose the order.
- **Between districts:** a field that makes the open ground dangerous (worm fields in vanilla terms; Q8).
- **Siege (C2):** a fallen district stays fallen for a while, so you can pull back and resupply. The hive **counter-attacks your forward positions** and slowly regrows districts (`regrow.lua`). The brain fight at the end is ring-1-like.

## Worm fields without worms (Q8)

What a worm field does: **area denial** between parts of the base, readable from afar, cleared with the right tool. Why worms are out (R2-D8): they **stop you moving**. So the field must **hurry you, not halt you**: crossing is fine, lingering is not.

| # | Idea | What it is | Answer to it | Keep-moving check (R2-D8) |
|---|------|------------|--------------|---------------------------|
| W1 | **Creep ground** | Hive tiles between districts. ~~Slows you~~. Instead: **standing still on creep hurts** (like OR-D37 stand-still punish), biters on creep **sense you** (squads come) | **Flamethrower burns it back** for a while | ✅ once the slow is gone: punishes stopping, not moving. Slow for vehicles only = a tank answer, but also cuts movement (Q14) |
| W2 | **Egg pods** | Passive, low-HP pods over the field; burst into biters when you come close or shoot them, can chain | Run past before they hatch, or grenades, fire, rockets from range | ✅ hatching makes you move on. Breaks "nothing comes out of the ground" (OR-D28) only a little: the pods are there to see |
| W3 | **Wyrm field** | An earth wyrm patrols the field (script-controlled wyrms, EB3c) | Dodge its path, or bait and kill it | ✅ a moving threat you dodge |
| ~~W4~~ | ~~Spore mines~~ | ~~Hidden, burst when stepped on~~ | — | ❌ makes you walk slowly and scout: dropped |
| W5 | **Acid vents** | Static vents that spit acid puddles on a timer | Time your crossing | ⚠️ ok if puddles are small and short; a wall of puddles = a worm line |

**Deeper layers** (asked 2026-10-24): when the radius can't grow, add **more rings of districts inside it** instead of more distance. E.g. ring 2: one ring of districts at ~110 → core. Ring 3: outer districts at ~130 + inner districts at ~70 → core. "Bigger" = **more stages to break through**, not more tiles walked. Bigger districts (R2-D10) = more nests and a stronger heart per district, same count of stages.

## Step 4 spec: R2-E1 (approved by the user 2026-10-24)

Numbers are first guesses to playtest. Choices made in the interview: R2-D19–D26.

### Map (ring ≥ 2)

| What | Rule | Where |
|---|---|---|
| Point offset | J 0.2 for ring ≥ 2 (R2-D16), rings 0–1 keep 0.8 | `nauvis-territory.lua` |
| Uranium | uranium ore × (ring ≥ 2), a Nauvis-only override like crude oil (R1-2) | `nauvis-territory.lua` |
| Core | brain + nest ring at 18 (as today). **No worm core** (R2-D14), **no anchor ring**: the districts are the shield links (R2-D22) | `brain-bases.lua` |
| Districts | **4** district slots at **115 tiles** from the brain (90° apart, base rotation), each a **district heart** (`ht-district-heart`, R2-D23) + a ring of **6 nests at 14 tiles**: outer edge ~135 + the nests' size ≈ 140–150. Placed **by script** (water, R2-D17) | new `scripts/districts.lua` |
| Field | creep + egg pods in the band 40–150 tiles, outside the district disks (see Field) | map gen tile + script |

**District placement** (like `oil.lua`, from the noise, so it works before the chunks exist): for each of the 4 slots try the angle ±15° / ±30° and radius 100–125; a spot fits if the heart and 8 points on the district's rim are land (elevation ≥ 2) and the nearest point is still this territory's. A slot with no fit is dropped (fewer districts). The district is built when its chunks are generated (`request_to_generate_chunks` when the base's chunk is, as `staging.ensure_base` does).

### Water: brain onto land (R2-D17, D19, D20; every ring)

- Today (`brain.lua`): water within 3 tiles of the point → brain destroyed, base removed, territory claimed.
- New: pick a **land spot** instead: sample the territory on a 16-tile grid from the noise (elevation, nearest point), score each land sample by its land samples within 30 tiles, take the best, closest to the point on ties. No land sample → claimed, as today.
- The brain moves there (`set_body_nodes`), the map-gen base at the point is removed, and a **full base is built by script** at the spot (`regrow.lua` already computes the layout in Lua: register + fill every slot at once). Ring 2+ then places districts around the spot.
- Follows: the territory's brain centre (`storage.bases`, challenge origin) is the spot, not the point. `oil.lua` aims at the point: its spot must follow a moved brain (pick from the brain centre). Ring-1 anchors come with the scripted base (regrow knows them).

### Uranium (R2-D18, D21)

- Guaranteed patch in **one district** of each of the **3 ring-2 territories closest to spawn**: the district **facing spawn** (the one you reach first).
- Patch centred on the district heart, radius ~12 (~450 tiles), ~1.5 M ore: the nests stand on it, so you clear the district to mine it.
- The district regrows after its fallen time (siege rules): miners there need defending, or you take the whole territory.

### Siege rules

| Part | Rule |
|---|---|
| War (R2-D27) | Your first hit on a district starts a **war** on the territory; leaving doesn't lose it. Ends on brain death, or when the hive has all districts back and nothing of yours holds ground (4e2) |
| District fight | Hitting anything of a district starts **that district's fight**: its nests send waves (small + medium biters; no core help, R2-D27). Won when the **heart dies**: the district's nests go quiet and its line to the brain breaks. Left (no one within 100 tiles for 5 s): the heart heals, lost nests regrow, the war goes on |
| Fallen district | Stays fallen until a **retake army** (4e2) reaches it once you've left: it destroys every player building there (any building holds it), wakes the nests, rebuilds the heart. No timer (R2-D27) |
| ~~Counter-attacks~~ | Dropped (R2-D27): the retake army is the hive's first action; weak-point raids are a later RTS step (ring-feel RF-D8) |
| Core fight | Ring-1-style brain fight (`brain-fight.lua`, director, queens) with a ring-2 entry. Shield: **each live district heart = 1 link**; the brain keeps `1 − shield × links / links_start` of every hit (first guess shield 0.9: 4 hearts → 10 %, 2 → 55 %). All hearts down → open. Starts as in ring 1 (a hit on the core within SIEGE_REACH, or the brain engages) |
| Brain | `hf-brain-ring2` (OR-D4: one brain per ring), first guess **5000 HP** and ring-1 regen (B-I11: medium / big out-regenerate everything today) |
| Win / lose | Brain dies → territory claimed (as today). Core fight lost → core regrows, the war goes on (fallen districts stay fallen) |

### Field (R2-D8, R2-D12)

| | Creep (W1) | Egg pods (W2) |
|---|---|---|
| What | A creep tile (placeholder: a tinted Gleba tile) in noisy blotches, ~50 % of the band 40–150 tiles, not on district disks | Low-HP pods, ~1 per 600 tiles of creep (~30 per base), placed by script on creep |
| Effect | Standing still on creep (< 1.5 tiles/s for 2 s, as the director's stand-still punish) hurts (~10 HP/s, rising); while you're on creep the nearest district sends a small squad (rate-limited, 1 per 20 s) | Player within 8 tiles, or the pod is hit → bursts after 1.5 s into 3–5 biters; pods within 6 tiles burst too (chain) |
| Answer | **Flamethrower / fire burns it back**: fire on creep turns it to scorched ground for 5 min, then it grows back | Run past before they burst, or grenades / fire / rockets from range |
| Build | Map-gen tile autoplace from the point's distance (cheap, no script). Map gen doesn't know where script puts a district, so it leaves out the 4 **default slot** disks (base rotation, 115 tiles); a district moved off its slot by water may sit partly on creep. Fire scan by script once per second in active territories | Script, with the districts. Pods don't regrow (for now) |

### Build steps (one at a time, headless ✅ before each PT)

- [x] 4a. Map: J 0.2 (ring ≥ 2), uranium × (ring ≥ 2), no worm core / anchors in ring 2. Headless: `tools/ht-ring2-check/` on the 3 seeds (room, overlaps, uranium per ring = 0 / 0 / ≥ 1). **Built + headless ✅ 2026-10-25 (2.1.21).**
  - **Built:** `nauvis-territory.lua`: `J_FAR = 0.2` for cells in ring ≥ 2 (ring from the cell indices, same formula as `hostile_point_ring`); `hostile_uranium_ore_probability` = vanilla × (ring ≥ 2), set as Nauvis' `entity:uranium-ore:probability`. `brain-bases.lua`: worm autoplace removed (**no worms in any ring now**, R2-D8 / D14; the `hostile_base_core_*` noise stays for `ht-map-check`), anchors only in ring 1 (`== 1`). `regrow.lua`: no worm core, anchors only in ring 1. Tools: `ht-ring2-check` reads the per-ring J and counts worms / core nests / anchors per ring; `ht-map-check` no longer prints worms.
  - **Headless** (seeds 12345 / 987654 / 555, `ht-ring2-check`, 40 chunks):

    | Check | 12345 | 987654 | 555 |
    |---|---|---|---|
    | Points rebuilt from the noise (off by > 1 tile) | 0 | 0 | 0 |
    | Ring 2 at J 0.2: worst-side room min / median | 146 / 175 | 152 / 166 | 152 / 164 |
    | Overlapping base pairs, ring 2 / ring 3 | 0 / 0 | 0 / 0 | 0 / 0 |
    | Gap between neighbouring bases, min | 26 | 18 | 18 |
    | Uranium patches ring 0 / 1 / 2 / 3 | 0 / 0 / 1 / 3 | 0 / 0 / 4 / – | 0 / 0 / 1 / 5 |
    | Worms (all rings) | 0 | 0 | 0 |
    | Anchors per base, ring 1 / ring 2 | 3.1 / 0 | 2.7 / 0 | 2.1 / 0 |

    Regression: `ht-map-check` (12345): 36 full territories, 1 base each, brains 0 tiles from their point, 7 water territories clean, 0 stray enemies, 0 core worms. `ht-ring-check` (12345, 987654): rings 4 / 12 / 20, oil only ring 1+, guaranteed wells 6 / 6. `--dump-data` + `check-paths.py`: 2517 paths, 0 missing.
  - Ring 2 still has **just 1 uranium patch** on 2 of 3 seeds (271 and 71 tiles from the brain): the guaranteed patches (4d) are needed. Anchor counts under 4 and core nests under 6 per base are water / cliff-blocked slots (as before).
  - **In game ✅** (user, 2026-10-25, new map): ring-2 bases have no worms or anchor rings; uranium fine. Ring-2 brains are still **unkillable**: expected, they are still the medium / big brains by distance (B-I11); the ring-2 brain comes in 4f.
- [x] 4b. Brain onto land, every ring (R2-D20). Headless: claimed-at-map-gen count before / after on the 3 seeds, scripted bases complete, oil spot follows a moved brain. **Built + headless ✅ 2026-10-25 (2.1.21).**
  - **Built:** [brain.lua](../mods/Hostile-territory/scripts/brain.lua): point with water within 3 tiles (real tiles, as before) → `land_spot` from the noise: 16-tile samples over the point's grid cell, ≥ 40 tiles inside the cell, in the point's own territory, elevation ≥ 2; the sample and its neighbours within 32 tiles must be land (else within 16), most land within 64 tiles wins, closest to the point on ties. Map gen's base around the point is cleaned (now and in every later chunk of the cell, radius 40); the spot's chunks (39 tiles around, always in the cell) are requested; once they exist the brain jumps there and `regrow.fill` builds the whole base at once (trees and rocks in a slot's way removed, as map gen places bases before trees). No spot, or real water at the spot → claimed (as before). `storage.brain.moved[cell] = {point, spot, id, done}`. `brain.home(surface, point)` = where a base stands, from the noise, before its chunks exist: used by [oil.lua](../mods/Hostile-territory/scripts/oil.lua) (spot 56 tiles from the brain, not the point) and [staging.lua](../mods/Hostile-territory/scripts/staging.lua) (`ensure_base` also generates the spot's chunks; "base can exist" = the territory still has its brain). Debug remote `brain_state`; `/ht-brains` counts moved bases; command in `docs/commands.md`. Tools: new [tools/ht-land-test/](../tools/ht-land-test/), `ht-map-check` counts enemies around moved spots as part of a base.
  - **Headless** (`ht-land-test`, 40 chunks, seeds 12345 / 987654 / 555):

    | | 12345 | 987654 | 555 |
    |---|---|---|---|
    | Territories claimed at map gen: before (water) → now (no land) | 7 → **0** | 5 → **0** | 12 → **0** |
    | Moved bases, ring 1 / ring 2 | 2 / 5 | 2 / 3 | 5 / 7 |
    | Distance point → spot | 82–243 | 71–193 | 60–244 |
    | Moved bases failing a check (brain on the spot, own cell + territory, no water at the spot, ≥ 1 nest, no map-gen leftovers at the point) | 0 | 0 | 0 |
    | Nests within 25 of a moved spot (6–8 slots by distance) | 5–8 | 6–7 | 5–8 |
    | Anchors per moved ring-1 base | 4, 4 | 4, 4 | 4 × 5 |
    | Guaranteed oil: distance to its brain | 58 | 56 | 56 |

    First try had 1–3 nests on some moved bases: trees blocked the scripted slots (fixed with the clearing). Missing nests now = cliffs. Regression: `ht-staging-test` ✅ (staging next door, base generated by the call), `ht-map-check` (555): 36 / 36 territories with 1 base, brains up to 244 tiles from their point, 0 stray enemies, 0 without a unit.
  - **Every** territory within 1280 tiles has a brain now on all 3 seeds: the almost-all-water ring-2 territory from step 3 (1–4 % land) still finds a land spot. A territory with no land at all would still start claimed (untested: none on these seeds).
  - **In game ✅** (user, 2026-10-25, new map): fine, except brains are found at their spawn spot before they jump to their base (B-I10 in territory-brain-plan.md, more often now that moved bases wait for their spot's chunks).
  - **Fix: brains out of sight (B-I10)**, user chose "jump + generate" (2026-10-25). Built + headless ✅:
    - A territory brain whose base isn't placed yet jumps at once to where its base will stand (`brain.home`, from the noise), usually into chunks not generated yet, and that base's chunks are requested. Chunk generation still decides with the real tiles (the noise check now uses the same 3-tile radius, so no second jump on the 3 seeds).
    - Hooked on `on_segmented_unit_created`, plus a **sweep every 60 ticks** (`brain.sweep`, each unit once, `storage.brain.seen`): brains made with the map (starting area) raise **no creation event**, and `on_init` runs before they exist.
    - The territory's point is read at one of the territory's chunks: the engine sometimes spawns a brain **outside its own territory** (first try put a ring-1 brain on a ring-0 point).
    - Only chunks within 39 tiles of the base **and in the brain's own territory** are requested. First try requested a 5 × 5 square: each base's chunks created the next territories, whose brains requested more (**chain over the whole map**, to ring 8).
    - Headless (`ht-land-test`, 4 chunks around spawn, check at tick 62 after the first sweep): every brain (16 / 22 / 10 on seeds 12345 / 987654 / 555) already stands where it ends, in generated chunks with its base; 0 jump again later; 0 moved bases failing a check; 0 territories with 2 brains; oil 56–58 from its brain. Regression: `ht-map-check` (71 territories, 36 full, 1 base each, 0 stray, 0 without a brain), `ht-staging-test` ✅, `ht-ring-check` (555) ✅.
    - **Cost:** the bases of every territory the generated area touches get generated too, which touches a few more: a decaying drift outward. At map start (4 chunks) that's 10–22 bases (up to ring 2); the 40-chunk test ends with 68–81 territories instead of ~64; the staging test's 441 chunks became 641. Watch for start-up time or save size in game.
  - **In game** (user, 2026-10-25): start not slower ✅. A brain far out came with its base when approached ✅ (feels fine). But one brain was **on the minimap and jumped again** when the user came closer: the noise (9 samples, elevation < 0) said its point was dry, the real tiles had water, so it jumped from the point to a land spot. "Feels kinda weird."
  - **Fix 2 (2026-10-25), built + headless ✅** (5 seeds: 12345, 987654, 555, 4242, 31337):
    - `brain.home` checks **every tile within 5** of the point and counts elevation < 1 as wet (margin over the real check: water within 3, elevation < 0). Doubtful points go to a land spot from the start.
    - Where a brain was hidden is stored (`storage.brain.homes`); a brain hidden on a land spot **keeps it** at chunk generation even if the point is dry. Only a point that turns out wet still makes a second jump (0 on 5 seeds).
    - A moved base waits only for **its own territory's chunks** around the spot (seed 31337: one base waited for a neighbour's chunk that is never requested, brain alone on its spot).
    - No land spot by the stricter check → the **point after all** (real tiles decide). Land spot rules get a last fallback: any land sample (R2-D19 shrink to fit); first try claimed 4 ring-3 territories with a few islands.
    - Results: 0 brains jumping again after tick 62; 102 moved bases, 0 failing a check, nests 4–10 (median 7–8); 1–4 moved bases per seed whose point was dry after all (the margin); claimed at map gen: 0 / 0 / 0 / 0 / 1 (12345 now 2: cells with 0 and 11 land samples, all near the cell edge). Oil 56–58 from its brain. Regression: `ht-map-check` (31337: 36 full, 1 base each, 0 stray), `ht-staging-test` ✅, `ht-ring-check` ✅.
  - **In game ✅** (user, 2026-10-25, new map): looks fine.
- [x] 4c. Districts: placement, heart prototype, nest ring, link lines, regrow knows districts. Headless: districts per ring-2 territory, all on land and in their territory; entity count (performance issue). **Built + headless ✅ 2026-10-25 (2.1.21).** Link lines moved to 4f (they belong to the shield).
  - **Built:** [prototypes/entity/district-heart.lua](../mods/Hostile-territory/prototypes/entity/district-heart.lua) (`ht-district-heart`, in data-final-fixes: biter spawner × 1.6, violet tint, 3000 HP, 6 HP/s regen, 14 owned units; placeholder art). [scripts/districts.lua](../mods/Hostile-territory/scripts/districts.lua): `districts.plan` runs when a ring-2+ brain stands on its base (`brain.lua`, on its point or a land spot). 4 slots at 115 tiles, 90° apart from the base rotation; per slot the first candidate (angle ±15° / ±30°, radius 100–125) whose heart and 8 rim points (18 tiles) are land (elevation ≥ 2) in the brain's own territory; no fit → slot dropped. A district is built once its own territory's chunks within 20 tiles exist: heart, then 6 nests at 14 (biter / spitter alternating); trees and rocks in the way removed, under a heart cliffs too. `regrow.lua` regrows hearts and nests as more slots of the base. `territories.own_chunks` / `request_own` shared with `brain.lua`. Debug remote `districts_state`, `/ht-brains` counts districts, command in `docs/commands.md`. Test mod [tools/ht-district-test/](../tools/ht-district-test/).
  - **Districts don't request their chunks**, unlike the brain's base (B-I10): requesting them generated new territories whose districts requested more, a chain that never ended (the headless run hung). They build when exploration generates their area; map gen runs ahead of the player, so they should be there before they're seen (in-game check).
  - **Headless** (`ht-district-test`, 40 chunks, seeds 12345 / 987654 / 555):

    | | 12345 | 987654 | 555 |
    |---|---|---|---|
    | Ring-2 territories with 4 / 3 / 2 / 1 / 0 districts | 10 / 6 / 2 / 0 / 2 | 11 / 6 / 2 / 0 / 1 | 9 / 6 / 2 / 2 / 1 |
    | Built districts failing a check (heart, own territory, ≥ 3 nests) | 2 of 90 | 1 of 90 | 0 of 85 |
    | Heart → its brain | 100–126 | 100–126 | 100–126 |
    | Nearest heart of another territory: min / median | 91 / 183 | 81 / 201 | 81 / 205 |
    | Ring 2 enemies (by position): nests / hearts | 484 / 60 | 511 / 67 | 472 / 60 |
    | Killed heart + nest regrown (40 rounds) | ✅ | ✅ | ✅ |

    Failing = fewer than 3 nests (cliffs). First run: ~30 of 75 ring-2 hearts missing, blocked by trees at the edge of the bigger heart (cleared 3 tiles, needs 5); then 5 blocked by cliffs (now cleared under hearts). Unbuilt districts in the test are ring 3+ (chunks outside the 40-chunk square). `--dump-data` + `check-paths.py`: 2536 paths, 0 missing.
  - **Performance:** ring 2 now has ~480–510 nests + 60–67 hearts on 20 territories (was ~150 nests). Idle spawners are cheap; UPS not measured separately (benchmark average is all chunk generation). Watch in game.
  - **In game ✅** (user, 2026-10-25, new map): hearts fine; districts are there and don't pop in; maybe slight lag, but okay. Uranium only found in ring 3 (→ 4d). Asked whether ore is less overall (harder to see with the districts on the map).
  - **Ore check** (new tool [tools/ht-ore-check/](../tools/ht-ore-check/), current mod vs HEAD, seeds 12345 / 555, 40 chunks): iron, copper, coal, stone **identical** per ring. Uranium: rings 0–1 gone (as R2-D21 wants), ring 2 has one small patch (~370–400 tiles) per seed, ring 3 unchanged. So no ore was lost; ring 2 uranium is thin until 4d. Ore tiles under spawners went up (208 → 328, 51 → 71): districts sit on some patches.
  - **Map toggle for districts:** not possible as one of the map's own toggles (engine-only; a mod can't hide enemy buildings from the map at runtime, `not-on-map` is a prototype flag). Options offered (ore map pins, startup setting); user chose **nothing for now** (2026-10-25).
- [x] 4d. Guaranteed uranium in the spawn-facing district of the 3 closest ring-2 territories. Headless. **Built + headless ✅ 2026-10-25 (2.1.21).**
  - **Built** ([scripts/districts.lua](../mods/Hostile-territory/scripts/districts.lua)): `districts.init` picks the 3 ring-2 territories whose points are closest to the origin from the noise (`storage.uranium_points`, like oil's ring-1 pick). When such a territory's districts are planned, the district closest to the origin gets `uranium = true`; when it's built, a uranium disc (radius 12, 1.5 M, weight 1 in the middle → 0.5 at the rim) is placed before the heart and nests, skipping water and tiles that already have ore. `/ht-brains` lists the patches with GPS links; debug remote `uranium_points`. New maps only (an old save keeps its districts without uranium).
  - **No fallback:** if one of the 3 territories has no districts (claimed, or no slot fits), it gets no patch. Didn't happen on the 3 seeds.
  - **Headless** (`ht-district-test`, now with a uranium section, 40 chunks):

    | | 12345 | 987654 | 555 |
    |---|---|---|---|
    | Patches placed | 3 / 3 | 3 / 3 | 3 / 3 |
    | Per patch: tiles / amount | 441 / 1.50 M | 441 / 1.50 M | 441 / 1.50 M |
    | In the spawn-facing district, heart + 6 nests on it | ✅ ✅ ✅ | ✅ ✅ ✅ | ✅ ✅ ✅ |
    | Points' distance to origin | 947–962 | 940–946 | 959–976 |
    | Uranium tiles ring 2 (by position): before → now | 374 → 1697 | (4 patches) → 3486 | 399 → 1722 |

    One patch (987654, district at x 742) lies in a ring-1 grid cell by position but in the ring-2 territory: districts reach 115 tiles out from a brain near the cell edge. Fine for the gate (you still take a ring-2 district). District checks unchanged (2 / 1 / 0 failing, as in 4c).
  - **In game ✅** (user, 2026-10-25, new map): the 3 uranium patches are there.
- [x] 4e1. **War state + district fight + fallen district** (revised 2026-10-25 from [ring-feel-plan.md](ring-feel-plan.md) RF-D7–D33; the first draft with a 20-min timer and counter-attacks is replaced). Headless + **PT**. Spec done (Q36–Q38 → R2-D28, 2026-10-25). **Built + headless ✅ 2026-10-25 (2.1.21); PT next.**
  - **New module** `scripts/war.lua`; `challenge.lua` stays as it is (the core fight changes in 4f).
  - **War state** (RF-D17): `storage.wars[territory id] = {started_tick, fights = {[slot] = fight}}`, kept apart from the territory record's `state` (challenge, overlay and crusade code stay untouched). Nothing about it goes on the map (RF-D22, D26). Starts on the first district fight. Ends when the brain dies (claimed). The hive-win end (RF-D21) comes with the retake army in 4e2; until then, fallen districts stay fallen.
  - **District fight start:** a player damages an enemy within the RIM (18 tiles) of a built, not fallen district's heart, the territory is hostile and no core challenge runs → that district's fight, and the war if it isn't running. Other players who hit it join.
  - **Waves:** every 8 s, 4–7 units out of the district's living nests (heart included) at the nearest participant, max 40 alive, slowed 20 % like the phased rings. Units: **small + medium biters** (RF-D33), ~30 % medium (R2-D28). No help from the core (RF-D32). Timer waves, not squads (R2-D28).
  - **Won:** the heart dies → the district is **fallen** (`fallen = true` on the district in `storage.districts`). Its nests **stay but go quiet** (RF-D29): `entity.active = false`, so they spawn nothing; you clear them to build. The fight's units flee. Fallen stays until the retake army (4e2); no timer (R2-D25 → R2-D27).
  - **Left** (RF-D31): no participant within 100 tiles of the heart for 5 s → the fight pauses: its units walk back to the heart, the heart heals (its own 6 HP/s), lost nests regrow as today. The war goes on; hitting it again resumes the fight.
  - **Regrow:** a district in a fight doesn't regrow; a fallen one never does (until 4e2). The core and the other districts keep regrowing 1 per minute, also during the war.
  - **Telemetry:** a CSV per district fight in `script-output/ht-telemetry/` (`<tick>-t<id>-d<slot>.csv`): second, participant, HP, heart %, alive, nests alive / quiet, units sent; summary line (outcome won / left, duration, deaths). Plus a war log `<tick>-t<id>-war.csv`, one row per event (war start, fight start / left / won, brain dead).
  - **Debug:** remote `wars`; `/ht-brains` lists wars and fallen districts.
  - **Headless:** a hit starts the war + fight; waves come from the district's nests with small + medium biters; heart killed → fallen, nests quiet (no units spawn for 2 min), no regrow; walking away pauses the fight, the heart heals and the war stays; a second district fight in the same war; brain death ends the war.
  - **Built** ([scripts/war.lua](../mods/Hostile-territory/scripts/war.lua)): as specced. Wired in `control.lua` (damage → `war.on_base_damaged` before the challenge, heart death → `war.on_nest_died`, claim → `war.on_won`, `every(30)`), `challenge.player_of` shared. `districts.lua`: `districts.RIM`, `districts.pieces`; `districts.slots` leaves out a fighting or fallen district (so regrow skips it). Differences from the spec:
    - **Participants are characters** of a player force within 100 tiles (not players), so a player-less character works headless. A turret's hit (player force) also starts a fight.
    - Quiet nests use `disabled_by_script` (`LuaEntity.active` is read-only in 2.1).
    - "Left" ends the fight (outcome `left`); hitting the district again starts a new fight (and a new CSV) in the same war.
  - **Headless ✅** (`tools/ht-war-test/`, 40 chunks, seeds 12345 / 987654 / 555; same result on all three):

    | Check | Result |
    |---|---|
    | Hit on a nest → war + fight | ✅ |
    | Units after 10 s (2 waves) | 7 / 4 / 5 sent, mediums among them (2 / 0 / 2) |
    | Heart killed → fallen, fight won, nests disabled | ✅ 6 of 6 disabled |
    | Regrow ×5 on the fallen district → heart back | no ✅ |
    | Second fight (B): regrow ×5 during it → killed nest back | no ✅ |
    | Walk 300 tiles away → fight left after the grace; war stays | ✅ |
    | Heart heals after leaving | 1741 → 1853 HP in ~17 s ✅ |
    | Regrow ×10 after leaving → B's nest back | ✅ (A's heart still not) |
    | Brain killed → war ends | ✅ |
    | Telemetry | `<tick>-t<id>-war.csv` (war_start, fight_start, fight_won, fallen, fight_left, war_end) + one `-d<slot>.csv` per fight with a `# outcome=…` line ✅ |

  - **PT1 (4e1)** hand-over:
    - **Changed since the last PT:** new: ring-2 district fights + war state (R2-D27, D28). Ring 2 had no fight before (brains unkillable, B-I11; the core fight comes in 4f).
    - **Headless:** start, waves, fallen + quiet nests, no regrow, leave → heal + regrow, war end on brain death, CSVs. **Only the PT shows:** how a district fight feels (waves every 8 s, 4–7, ~30 % medium, max 40), whether killing the heart feels like taking ground, whether quiet nests read as "beaten", how leaving and coming back feels.
    - **Test in this PT:** (1) Does a district fight feel like one engagement of a war (length, pressure)? (2) Is the heart a clear goal, and does "fallen" read in the world? (3) Leave mid-fight and come back: does the heart healing feel fair? (4) Take a second district: does it feel like progress?
    - **Setup:** new map; `/cheat-kit smg-red` (or your ring-2 kit); `/ht-goto-ring 2`, then the teleport-to-district command in `docs/commands.md`; `/ht-brains` shows wars and fallen districts.
    - **Send:** `script-output/ht-telemetry/<tick>-t<id>-war.csv` and the `-d<slot>.csv` files, plus feel notes.
  - **PT1 result** (user, 2026-10-25, 2.1.21; no CSVs sent):
    | Q | Answer |
    |---|---|
    | 1. One engagement of a war? | **Way too easy**, fine as a draft |
    | 2. Heart a clear goal, fallen reads? | **No**: the heart is neither a goal you need, nor does killing it feel like it accomplished anything |
    | 3. Leave and come back, heal fair? | Fine |
    | 4. Second district = progress? | **No** |
  - **Side fix** (2026-10-25): `/ht-goto-ring` generated every chunk out to the ring (~5300 chunks for ring 2, a second of lag). Now it picks the ring's territory points from the noise, nearest first, and generates only 6 chunks around the one it uses (~170 chunks plus the brain's own; next point if no brain or no free spot). Headless (seeds 12345 / 555 / 987654): spot 45 tiles from the brain, same territory, all ring-2 districts built, rings 0–2.
  - **Reading:** the mechanics work, the **meaning** is missing. Today a fallen district changes nothing that matters: the brain can't be killed yet (shield links come in 4f), nothing comes to take it back (4e2), and except the 3 uranium districts it holds nothing you want. Q39.
- [ ] 4e1b. **Garrison + zone of control** (R2-D30, D31; RF-D44, D45, D48, D53). Headless + **PT2**. **Spec done 2026-10-26** (Q42–Q49 → R2-D33). **Built + headless ✅ 2026-10-26 (2.1.21); PT2 done 2026-10-26: works, far too easy (23–53 s, 0 HP lost), brutes don't read → Q50–Q52.** Goal: a district is a **costly win, ~3–5 min**, and the districts are **in the way** of the core. Builds on 4e1 (`war.lua`); the war state, fallen + quiet nests and "left" stay as they are.
  - **Garrison** (RF-D45): each live district has a standing army that stands around its heart (idle, spread on a ring ~20–30 tiles out, so you see it when you scout). Size `GARRISON` (first guess **80**: ~60 % small, ~40 % brutes). Spawned when a player character comes within `WAKE` (~200 tiles) of the heart **or the heart's chunk is visible** to a player force (radar); despawned (kept as a number) once neither holds for a minute, so 20 territories × 4 districts don't keep ~6400 units alive (R2-D33).
  - **Brutes** (RF-D46, first role): **medium biters** today, slowed like the rest. When the garrison attacks, brutes **lead**: they get the attack command first, the small biters ~1.5 s later, so the swarm comes in behind the soak. Own unit later (4e4).
  - **Zone of control** (RF-D48): every `CHECK_INTERVAL`, a player character within **`ZONE` (~80 tiles)** of a live, built, not fallen district heart (territory hostile, no core challenge) **starts that district's fight** (and the war), the same as a hit does today. Two zones touching → both fights start, both send their share (R2-D33).
  - **Attack:** on fight start **half** the garrison goes after the nearest participant, the rest holds the heart and joins once a participant is within ~40 tiles of it (R2-D33); units that lose their target pick the next nearest participant. **Leash:** a unit more than `LEASH` (~120 tiles) from its heart turns back home. Brutes first, as above.
  - **Rebuild** (RF-D45): during a fight the district's living nests and heart refill the garrison towards `GARRISON`, `REBUILD` (first guess 1 unit per nest per 10 s, ~40 / min with 6 nests + heart); new units join the attack. Out of a fight the garrison refills the same way, so leaving and coming back costs you. **Timer waves are dropped** (R2-D33).
  - **Heart killed → fallen** (as 4e1): nests quiet, **rebuild stops** (R2-D33): the garrison left is the last of it. The rest walks to the **nearest live district** and joins its garrison (else the core).
  - **Left** (as 4e1): no participant within 100 tiles for 5 s → the fight ends, the garrison walks home and refills; the heart heals.
  - **Telemetry:** the district CSV gets `garrison` (alive), `rebuilt` (units added this fight) and `trigger` (`zone` / `hit`) in the summary; war log gets `zone_enter`.
  - **Kit:** new `/cheat-kit ring2` in `cheating-mod` (blue era: flamethrower, rockets, modular armor + shield, turrets; no tank) to balance the 3–5 min against.
  - **Debug:** `/ht-brains` shows garrison size per district; a command to put a district's garrison to full at once (for PT setup).
  - **Headless** (`tools/ht-war-test/`, 3 seeds): garrison spawns when a character comes within `WAKE` or the chunk is charted visible (`force.chart`) and despawns when neither; walking into the 80-tile zone starts the fight without a hit; standing between two districts starts both; the garrison attacks with brutes first; a unit chased past `LEASH` goes home; rebuild refills to `GARRISON` (rate per minute); half comes, the rest joins within 40 tiles; heart killed → rebuild stops, the rest walks to the next district; leaving → garrison home and refilled; entity count with a garrison near each of the 4 districts. Check: does `find_entities_filtered{type = "character"}` find a character driving the **tank** (else the zone misses a tank)?
  - **Built** ([scripts/war.lua](../mods/Hostile-territory/scripts/war.lua), 2026-10-26): as specced, timer waves removed. Knobs: `GARRISON` 80, `BRUTE` 0.4, posts 20–30 tiles, `WAKE` 200, `DESPAWN_AFTER` 60 s, `ZONE` 80, `HOLD` 40, `LEASH` 120 (back in the fight within `RETURN` 60), `REBUILD` 1 unit per nest per 10 s, `BRUTE_LEAD` 1.5 s. Debug: `/ht-garrison-fill`, remote `garrison_fill(x, y)`; `/ht-brains` lists garrisons on the map. Kit: `/cheat-kit ring2` ([cheating-mod](../mods/cheating-mod/control.lua); tier kits can now fill an armor grid, normal quality). Differences from the spec:
    - **Vehicles with a driver count as participants**: `find_entities_filtered{type = "character"}` doesn't find a character inside a vehicle, so the zone would miss the tank. The units attack the vehicle.
    - A garrison can grow past 80 when a fallen district's units join; the rebuild stops at 80, and the extra units are kept when it goes off the map.
    - The zone works across territory borders: a district's zone can reach into the neighbour's territory (seen in the test: a spot 150 out of one district was 56 tiles from a neighbour's district).
  - **Headless ✅** (`tools/ht-war-test/`, rewritten for 4e1b, seeds 12345 / 987654 / 555; same result on all three):

    | Check | Result |
    |---|---|
    | Garrisons on the map before anyone comes near | 0 ✅ |
    | Character 150 out (in `WAKE`, outside the zone) | garrison on the map: 80 (32 brutes), no war ✅ |
    | 70 out → zone of control | war + fight, trigger `zone`, 40 sent, rest held ✅ |
    | Brute lead | at 0.5 s 16 brutes / 0 small attacking; at 2 s 16 / 24 ✅ |
    | 30 out → hold released | 80 sent ✅ |
    | Leash: unit moved 130 out / back within 60 | drops out, goes home / joins again ✅ |
    | Rebuild after 30 kills | 6 units in 10 s (7 pieces × 0.1 / s; steps every 0.5 s) ✅ |
    | Heart killed | fallen, fight won, 6 nests disabled; 56 of 56 units walk to the nearest district (80 → 136) ✅ |
    | Tank in B's zone | fight by zone, 69 sent, brutes on the tank ✅ (only with the vehicle fix) |
    | Tank 400 away | fight left; a minute later B's garrison off the map, kept as 136 ✅ |
    | Brain killed | war ends ✅ |
    | Radar visibility | **not testable headless** (no charting): PT |

    Tick time without chunk generation ~2 ms (whole run). Note: ~8–9 k enemy units stand on the 40-chunk map after 90 s (1.1 k at the start), all vanilla spawner idle units, not garrisons (none on the map then). Worth a look in a performance pass (Issues).
  - **PT2 (4e1b)** hand-over:
    - **Changed since the last PT (PT1):**
      - Timer waves (8 s, 4–7, max 40) → **standing garrison** of 80 (~40 % brutes = medium biters), rebuilt by nests + heart at ~0.7 / s during and after a fight (R2-D30, D33).
      - Fight start: hit within 18 tiles → also **walking within 80 tiles** of a live district (zone of control, R2-D31).
      - Whole fight at once → **half the garrison comes**, the rest holds the heart until you're within 40 tiles; brutes lead by 1.5 s (R2-D33).
      - Heart killed: units flee → **rebuild stops**, the garrison walks to the nearest live district (R2-D33).
      - Kit: `smg-red` → **`/cheat-kit ring2`** (R2-D33).
    - **Headless:** everything in the table above. **Only the PT shows:** how long a district takes and what it costs, whether brutes read as the front, how the zones feel when you try to slip between two districts, whether the heart now feels like the goal, whether radar shows the garrison (and spawns it), and whether 80 + rebuild is in the right range.
    - **Test in this PT:**
      1. (garrison + rebuild) Does a district cost about 3–5 min and real ammo / HP with the ring-2 kit? Too easy, right, too hard?
      2. (brute lead) Do the brutes read as a front line with the swarm behind?
      3. (zone of control) Try to walk between two districts to the core: do both come, and does it feel like a cost, not a wall?
      4. (heart stops rebuild) Is the heart now a goal: dive it, or grind the garrison?
      5. (garrison joins neighbour) After a heart falls, do you notice its units walking to the next district?
      6. (radar) Put a radar near a district: does the garrison show up on the map?
    - **Setup:** new map; `/cheat-kit ring2`; `/ht-goto-ring 2`; then the teleport-to-district command in `docs/commands.md` (now 120 tiles out, just outside the zone); `/ht-brains` lists wars, fallen districts and garrisons; `/ht-garrison-fill` fills the nearest garrison.
    - **Send:** `script-output/ht-telemetry/<tick>-t<id>-war.csv` (now with `zone_enter`) and the `-d<slot>.csv` files (new columns `garrison`, `rebuilt`; summary `trigger=`), plus feel notes.
  - **PT2 result** (user, 2026-10-26, 2.1.21, `/cheat-kit ring2`; telemetry `2010-t30-war.csv` + 5 district CSVs). Ended by a crash when the last heart fell (below).

    | Q | Answer | Telemetry |
    |---|---|---|
    | 1. 3–5 min, costly? | "Faster than 3 min" | **23–53 s** per district (target 180–300). **0 HP lost** in every fight (HP 250 all along; shields weren't logged). Garrison 80 → 0 in **12–15 s** (~5–7 kills / s); heart 100 → 0 in ~10 s once the garrison is gone. Rebuild (0.7 / s) dies as it spawns |
    | 2. Brutes read as the front? | **Barely** distinguishable from small biters | — |
    | 3. Two zones, cost not wall? | Both come; "at best slightly alarming" | Zone triggers at 73–79 tiles, as designed |
    | 4. Heart a goal? | Fine, reads as a goal, "but not by a lot" | — |
    | 5. Garrison to the next district? | Not noticed: everything was dead by then | `fallen` rows: 0–1 units moved |
    | 6. Radar | Not tested | — |

  - **Bug (PT2):** the last district falling crashed (`LuaSegmentedUnit doesn't contain key position`): with no live district left, the garrison walks to the brain, and `relocate` read `.position` on the segmented unit instead of its head segment. **Fixed** (`brain.segments[1].position`); the headless test now kills every heart with all garrisons on the map (the last 296 units walk to the brain), ✅ 3 seeds. Also fixed: the participant column was empty (a player named ""), and the fight CSV gets a **`shield`** column (armor shield left) so the next PT shows whether units reach you at all.
  - **Reading:** the mechanics work (zone, hold, lead, rebuild, fall); the **threat** is missing. Melee small + medium biters, slowed 20 %, can't reach a player with a flamethrower and rockets, so a garrison is a pile of kills, not a cost. More of the same raises the time but probably not the cost (Lanchester with area damage favours the player). Q50–Q52.
- [ ] 4e1c. **Big biters in the garrison** (R2-D34). Headless + **PT3**. **Spec drafted 2026-10-26, waiting for the go-ahead.**
  - **Mix** of the 80: **50 % small, 30 % medium, 20 % big** (16 big biters: 375 HP, vanilla resistances, speed 0.16 in Hostile-fauna, × 0.8 slow). Rebuild keeps the shares.
  - **Lead:** big + medium attack first, small biters 1.5 s later (as today).
  - Everything else as 4e1b (80, 0.7 / s rebuild, zone 80, hold 40, leash 120).
  - **Risk:** big biters are the slowest unit (~0.13 tiles / tick with the slow), so even with the lead they may arrive last and not read as a front. PT3 tells; a fix would be "small biters wait until the brutes are within ~15 tiles of you".
  - **Headless:** mix on the map (40 / 24 / 16), rebuild keeps the shares, lead counts per kind.
  - **PT3** questions (draft): does a district now cost HP / shield (new `shield` column), how long, do big biters read as the front?
- [ ] 4e2. **Retake army** (RF-D15, D16, D19, D21, D30; built on a new shared hive-AI module with a hidden per-chunk influence map, RF-D34–D38: a crusade inside the territory, leash, ignores decoys, retreats at half strength): simple + tell. Once you've left a fallen district, an army masses visibly at the core, marches there, destroys every player building in the district (any building holds it), wakes the quiet nests and brings an **elder queen** that settles into the heart (RF-D50). All districts back and nothing of yours holding ground → the war ends (hive win). Headless + its own **PT**. Spec after 4e1's PT. Later (ring-feel RF-D39–D43, after 4e2's PT): win prediction before committing, digestion pools. Open: ring-feel Q33 (when a district counts as left), Q34 (army size, massing time), Q35 (after the hive wins).
- [ ] 4f. Core fight: ring-2 phases, districts as shield links, `hf-brain-ring2`; the **brain makes no units** (RF-D52): units come from nests, queens and hearts. Headless + **PT**. Moved right after 4e2 (R2-D33).
- [ ] 4e3. **Founders for regrowth** (RF-D49, D50; ring 2 only): a lost nest comes back because a queen walks out from a living piece and settles; a heart because an elder queen does. Kill her on the way and it doesn't come back. Replaces pop-in regrow in ring 2. Headless + PT.
- [ ] 4e4. **New combat roles, one per PT** (RF-D46): spitter, hunter, sapper (and a real brute unit) in Hostile-fauna.
- [ ] 4g. Creep (W1). **PT**.
- [ ] 4h. Egg pods (W2). **PT**.
- [ ] 4i. Balance pass (as oil ring: one set per PT).

## Issues

- **Tank** (allowed, R2-D5) may make distance pointless (drive to the core). Possible answers: creep that slows vehicles (W1), wyrms that go for vehicles (W3), a hive that targets parked tanks.
- **Turret creep** becomes the intended tool in C2, so the hive needs a counter (forward-position attacks; later counter-artillery, [counter-artillery-plan.md](counter-artillery-plan.md)).
- **Every ring bigger (R2-D6)** hits a wall: at G = 384 a base can't go much beyond ~170 tiles (centred points). Ring 3+ needs bigger territories (Q10).
- **Worms in ring 0 and 1** (R2-D11): the worm core sits in every base (`brain-bases.lua`), which the oil-ring work is tuning right now. Removing it changes the ring-0 and ring-1 fights, so do it **after ring 1 is called done**, or as its own step in [oil-ring-challenge-plan.md](oil-ring-challenge-plan.md) (Q13).
- **Tank vs keep-moving:** the usual tank answers (slow ground, blocking) cut movement, which R2-D8 rules out. Tank answers must be threats, not walls (Q14).
- **Performance**: many more nests per ring-2 base × 20 territories. Check entity count headless. 4e1b headless (2026-10-26): ~8–9 k vanilla idle units from spawners on a 40-chunk map after 90 s; garrisons only exist near players (R2-D33).
- ~~**Ring 1 isn't finished.**~~ Done for now (OR-D112, 2026-10-24), so ring 2 can be built.
- **Moving water brains in rings 0–1** (R2-D20) changes ring 0–1 maps that the oil-ring tuning was played on: more territories with a base near spawn, and the guaranteed oil follows a moved ring-1 brain.
- **A district can be taken without the brain**: the uranium gate is "take one district". ~~The regrow after 20 min and the counter-attacks~~ The retake army (4e2) and the shield links (4f) are what push you on to the core (R2-D27, D29).

## Steps

- [x] 1. Brainstorm: gate, shape, structure, size, tank, rings beyond (2026-10-24).
- [x] 2. Brainstorm: field, map, rings beyond, worms elsewhere, layers, tank (R2-D8–D15, 2026-10-24).
- [x] 3. Headless facts: room per ring-2 base at J = 0 / 0.2, gaps between bases, uranium positions today (seeds 12345, 987654, 555). Done 2026-10-24 (2.1.21) with `tools/ht-ring2-check/` (~3 min per seed, `--benchmark-ticks 20`): J 0.2 fits, water is the bigger problem, uranium is in ring 0–1 today.
- [x] 4. Spec: district layout, siege rules, field, uranium lever (decisions table, build steps). R2-E1 written and **approved 2026-10-24** (R2-D19–D26). Build steps 4a–4i in the spec.

## Open questions

- ~~**Q1.**~~ → R2-D1. ~~Tech gate~~
- ~~**Q2.**~~ → R2-D5. ~~Tank yes or no~~ (rest of the kit: blue-era tools, see facts)
- ~~**Q3.**~~ → R2-D2. ~~Shape~~
- ~~**Q4.**~~ → R2-D4. ~~Size~~
- ~~**Q5.**~~ → R2-D3. ~~Structure~~
- **Q6. Enemy mix:** ring 2 is where EB4 niche units (ranged, mediums, spitters) come in?
- ~~**Q7.**~~ → R2-D6. ~~Only ring 2?~~
- ~~**Q8.**~~ → R2-D8, R2-D12. ~~Which field~~
- ~~**Q9.**~~ → R2-D9. ~~Hive belt~~
- ~~**Q10.**~~ → R2-D10. ~~Rings beyond 2~~
- ~~**Q11.**~~ → R2-D11. ~~Worms in rings 0–1~~
- ~~**Q12.**~~ → R2-D13. ~~Layers~~
- ~~**Q13.**~~ → R2-D14. ~~Worm core replacement~~
- ~~**Q14.**~~ → R2-D15. ~~Tank answer~~
- ~~**Q15.**~~ → R2-D16. ~~Point offset~~
- ~~**Q16.**~~ → R2-D17. ~~Water in a base~~
- ~~**Q17.**~~ → R2-D18. ~~Guaranteed uranium~~
- ~~**Q18.**~~ → R2-D19. ~~Almost-all-water territory~~
- ~~**Q19.**~~ → R2-D20. ~~Water in rings 0–1~~
- ~~**Q20.**~~ → R2-D21. ~~Where the uranium goes~~
- ~~**Q21.**~~ → R2-D23. ~~District heart~~
- ~~**Q22.**~~ → R2-D24. ~~District count~~
- ~~**Q23.**~~ → R2-D25. ~~Fallen time~~
- ~~**Q25.**~~ → R2-D26. ~~Creep coverage~~
- ~~**Q26.**~~ → RF-D29 (nests stay, go quiet). ~~**Q27.**~~ obsolete (counter-attacks dropped). ~~**Q28.**~~ → RF-D32 (no core help). ~~**Q29.**~~ → RF-D33 (small + medium biters).
- ~~**Q36–Q38.**~~ → R2-D28.
- ~~**Q39.**~~ PT1: taking a district feels like nothing. What should give it meaning first: the brain's shield (4f, each heart a link: needed), the retake army (4e2, the hive wants it back), a reward per district (resources, a foothold), a visible change in the world when it falls, or a mix? Decides the next step. → R2-D29.
- ~~**Q40.**~~ → R2-D30. ~~How to make a district way harder, which unit roles~~
- ~~**Q41.**~~ → R2-D31. ~~Physically in the way~~
- ~~**Q42–Q49**~~ → R2-D33 (2026-10-26).
- ~~**Q42. Garrison presence** (4e1b): spawn when a player comes near (~200 tiles) and despawn when far (proposed, cheap), or always on the map from map gen (~6400 units for ring 2)?~~
- ~~**Q43. Garrison size and rebuild rate:** first guess 80 units (~40 % brutes), refilled 1 per nest per 10 s (~40 / min). The 3–5 min target depends on the ring-2 kit: which kit do we test with?~~
- ~~**Q44. How much of the garrison comes:** all of it at once, or a share (e.g. half) while the rest holds the heart, with more sent as you close in?~~
- ~~**Q45. Timer waves:** drop them (garrison + rebuild only, proposed) or keep a small supplement?~~
- ~~**Q46. The heart's role:** does killing the heart stop the rebuild (the heart makes the garrison faster, so diving it is a real choice vs grinding the garrison)? Gives the heart a meaning before 4e2 (PT1 Q2).~~
- ~~**Q47. Garrison when its heart falls:** flees to the core (4e1 today), joins the nearest live district, or fights to the death?~~
- ~~**Q48. Two zones at once:** both garrisons come (RF-D48 as written), or only the closer one plus a share of the other?~~
- ~~**Q49. Order of 4f:** the core fight (shield links, brain makes no units) after 4e4 as listed, or right after 4e2, so the districts get their main meaning (the shield) sooner?~~
- ~~**Q50–Q52**~~ → R2-D34 (2026-10-26).
- ~~**Q50. Main lever for "costly"** (PT2: 23–53 s, 0 HP lost; one change per PT): (a) many more units (garrison ~250, rebuild ~2 / s); (b) tougher, readable brutes now (big-biter body: bigger, ~375 HP, fire / explosion resistance); (c) the **spitter** role next (ranged damage that gets through and out-ranges turrets, RF-D46); (d) a mix?~~
- ~~**Q51. Brute look:** big biter as the brute now (readable at once), or a scaled + tinted Hostile-fauna unit of its own?~~
- ~~**Q52. Kit check:** is `/cheat-kit ring2` what you'd really have at ring 2 (flamethrower + rockets + shields at once), or too strong a baseline?~~
- **Q24. Spec defaults still to playtest** (no decision needed before building): shield 0.9 split over the live hearts, counter-attack every 3 min at the player building nearest the brain, `hf-brain-ring2` 5000 HP, uranium patch ~1.5 M under the spawn-facing district, creep 10 HP/s standing still, ~30 pods per base.
