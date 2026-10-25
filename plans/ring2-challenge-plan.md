# Ring 2 Challenge

> **Status:** Brainstorm done (R2-D1–D18), interview done 2026-10-24 (R2-D19–D26: shrink-to-fit water bases in every ring, uranium in a district of the 3 closest territories, districts as shield links, 4 tanky-spawner districts at 115, 20 min fallen, creep blotches). **R2-E1 spec approved** 2026-10-24 · **Parent:** [ring-layout-plan.md](ring-layout-plan.md), [oil-ring-challenge-plan.md](oil-ring-challenge-plan.md), [challenge-feel-plan.md](challenge-feel-plan.md) · **Next:** build 4a (map: J 0.2, uranium ring ≥ 2, no worms / anchors in ring 2) · [Roadmap](roadmap.md)

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
| R2-D25 | Fallen time (Q23) | **20 min**, then the district regrows (2026-10-24) |
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
| District fight | Hitting anything of a district starts **that district's fight**: its nests send waves (a ring-2 entry in `waves.PHASES`, small and ring-0-like), the brain sends squads from the core. Won when the **heart dies**: the district's nests stop spawning and its line to the brain breaks. Lost (you leave, LOSE_GRACE): the district regrows as bases do today |
| Fallen district | Stays fallen **20 min** (R2-D25): no regrow. Then the heart comes back and the nests regrow 1 per minute (`regrow.lua`) |
| Counter-attacks | While ≥ 1 district has fallen and the territory isn't claimed: every **3 min** a squad from the core attacks the **player building nearest the brain** inside the territory (forward positions; turret creep counter). Size grows with live districts and evolution |
| Core fight | Ring-1-style brain fight (`brain-fight.lua`, director, queens) with a ring-2 entry. Shield: **each live district heart = 1 link**; the brain keeps `1 − shield × links / links_start` of every hit (first guess shield 0.9: 4 hearts → 10 %, 2 → 55 %). All hearts down → open. Starts as in ring 1 (a hit on the core within SIEGE_REACH, or the brain engages) |
| Brain | `hf-brain-ring2` (OR-D4: one brain per ring), first guess **5000 HP** and ring-1 regen (B-I11: medium / big out-regenerate everything today) |
| Win / lose | Brain dies → territory claimed (as today). Core fight lost → core regrows, fallen districts keep their timer |

### Field (R2-D8, R2-D12)

| | Creep (W1) | Egg pods (W2) |
|---|---|---|
| What | A creep tile (placeholder: a tinted Gleba tile) in noisy blotches, ~50 % of the band 40–150 tiles, not on district disks | Low-HP pods, ~1 per 600 tiles of creep (~30 per base), placed by script on creep |
| Effect | Standing still on creep (< 1.5 tiles/s for 2 s, as the director's stand-still punish) hurts (~10 HP/s, rising); while you're on creep the nearest district sends a small squad (rate-limited, 1 per 20 s) | Player within 8 tiles, or the pod is hit → bursts after 1.5 s into 3–5 biters; pods within 6 tiles burst too (chain) |
| Answer | **Flamethrower / fire burns it back**: fire on creep turns it to scorched ground for 5 min, then it grows back | Run past before they burst, or grenades / fire / rockets from range |
| Build | Map-gen tile autoplace from the point's distance (cheap, no script). Map gen doesn't know where script puts a district, so it leaves out the 4 **default slot** disks (base rotation, 115 tiles); a district moved off its slot by water may sit partly on creep. Fire scan by script once per second in active territories | Script, with the districts. Pods don't regrow (for now) |

### Build steps (one at a time, headless ✅ before each PT)

- [ ] 4a. Map: J 0.2 (ring ≥ 2), uranium × (ring ≥ 2), no worm core / anchors in ring 2. Headless: `tools/ht-ring2-check/` on the 3 seeds (room, overlaps, uranium per ring = 0 / 0 / ≥ 1).
- [ ] 4b. Brain onto land, every ring (R2-D20). Headless: claimed-at-map-gen count before / after on the 3 seeds, scripted bases complete, oil spot follows a moved brain.
- [ ] 4c. Districts: placement, heart prototype, nest ring, link lines, regrow knows districts. Headless: districts per ring-2 territory, all on land and in their territory; entity count (performance issue).
- [ ] 4d. Guaranteed uranium in the spawn-facing district of the 3 closest ring-2 territories. Headless.
- [ ] 4e. District fight, fallen timer, counter-attacks. Headless + **PT**.
- [ ] 4f. Core fight: ring-2 phases, districts as shield links, `hf-brain-ring2`. Headless + **PT**.
- [ ] 4g. Creep (W1). **PT**.
- [ ] 4h. Egg pods (W2). **PT**.
- [ ] 4i. Balance pass (as oil ring: one set per PT).

## Issues

- **Tank** (allowed, R2-D5) may make distance pointless (drive to the core). Possible answers: creep that slows vehicles (W1), wyrms that go for vehicles (W3), a hive that targets parked tanks.
- **Turret creep** becomes the intended tool in C2, so the hive needs a counter (forward-position attacks; later counter-artillery, [counter-artillery-plan.md](counter-artillery-plan.md)).
- **Every ring bigger (R2-D6)** hits a wall: at G = 384 a base can't go much beyond ~170 tiles (centred points). Ring 3+ needs bigger territories (Q10).
- **Worms in ring 0 and 1** (R2-D11): the worm core sits in every base (`brain-bases.lua`), which the oil-ring work is tuning right now. Removing it changes the ring-0 and ring-1 fights, so do it **after ring 1 is called done**, or as its own step in [oil-ring-challenge-plan.md](oil-ring-challenge-plan.md) (Q13).
- **Tank vs keep-moving:** the usual tank answers (slow ground, blocking) cut movement, which R2-D8 rules out. Tank answers must be threats, not walls (Q14).
- **Performance**: many more nests per ring-2 base × 20 territories. Check entity count headless.
- ~~**Ring 1 isn't finished.**~~ Done for now (OR-D112, 2026-10-24), so ring 2 can be built.
- **Moving water brains in rings 0–1** (R2-D20) changes ring 0–1 maps that the oil-ring tuning was played on: more territories with a base near spawn, and the guaranteed oil follows a moved ring-1 brain.
- **A district can be taken without the brain**: the uranium gate is "take one district". The regrow after 20 min and the counter-attacks are what push you on to the core.

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
- **Q24. Spec defaults still to playtest** (no decision needed before building): shield 0.9 split over the live hearts, counter-attack every 3 min at the player building nearest the brain, `hf-brain-ring2` 5000 HP, uranium patch ~1.5 M under the spawn-facing district, creep 10 HP/s standing still, ~30 pods per base.
