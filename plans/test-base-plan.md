# Test base plan

> **Status:** Interview (Q1, Q4, Q9, Q10 decided), nothing built · **Parent:** [vision-plan.md](vision-plan.md) (crusades, phase I) · **Next:** TS-Q3, Q5–Q8, Q12–Q14 (launch config) · [Roadmap](roadmap.md)

## Goal

Get a defensible base on **any new map in seconds**, so crusade work doesn't need a hand-built base or old saves kept alive with migration scripts. One command, `/cheat-base <tier>`, stamps a stored blueprint and makes it ready to fight. A separate **crusade-test launch config** starts the game with gear for building fast (power armor, bots) and research for the ring under test.

## Decisions

| # | Decision | Date |
|---|----------|------|
| TS-D1 | Re-create the base per map instead of keeping saves. Old-save support stays out of scope (EB D36) | 2026-10-23 |
| TS-D2 | Approach: **blueprint stamp** in `cheating-mod` (stored blueprint strings, built instantly by script). Scripted extras (clear area, fill ammo) where a blueprint can't do it | 2026-10-23 |
| TS-D3 | Blueprints live as files in `mods/cheating-mod/` (versioned in git). The user builds and exports them in game | 2026-10-23 |
| TS-D4 | **Keep it simple (main rule).** A compromise between automating and building by hand: no clever auto-building. When a feature gets complicated, do that part by hand in game instead (TS-Q1, user) | 2026-10-23 |
| TS-D5 | **Resource based, not infinite.** Ammo and power come from a real supply chain, so ammo drain is part of the test. No script top-ups (TS-Q1, user) | 2026-10-23 |
| TS-D6 | **Normal crusade trigger.** In these playtests we wait for the regular budget and target pick: no forced target, no budget cheat. TS-Q4 options (a)–(c) dropped (user) | 2026-10-23 |
| TS-D7 | **Placement by hand.** The user stands in the territory `/ht-crusade` names as the next target and stamps there. `/cheat-base` builds at the player's position; no target logic in the command (TS-Q9 (a), user) | 2026-10-23 |
| TS-D8 | **Blueprint scope:** defence + ammo assembly + power, fed from input chests the stamp fills with plates once. The user adds miners on the local ore by hand (TS-Q10 (a), user) | 2026-10-23 |
| TS-D9 | **Crusade-test launch config** in `.vscode/launch.json`, next to "Factorio Mod Debug". You start with: strong power armor with personal roboports, construction robots and logistic (supply) robots, so setting up the base is quick. Research is unlocked automatically depending on the ring under test (user) | 2026-10-23 |

Options weighed and dropped (2026-10-23): fixed-seed save (breaks with every map-gen or mod change), building by hand in `/editor` (slow), pure scripted turret ring with infinite ammo (doesn't play like a base; ruled out by TS-D5).

## Confirmed facts

- **Crusade target** = the claimed territory **furthest** from the player force spawn, ties random (`scripts/crusade.lua`, `pick_target`).
- A crusade needs a **staging nest** in a neighbouring territory (`staging.lua`; vision G-3: no nest, no crusade).
- Forcing a crusade already works: `/ht-set-state claimed` in a territory near nests, then `storage.crusade_budget = 1e6; storage.crusade_cooldown_until = 0` ([docs/commands.md](../docs/commands.md) "Crusades"). `/ht-crusade-cancel` ends one.
- `cheating-mod` already has `/cheat-kit` and `/cheat-clear` (player gear). `/cheat-base` fits there.
- `.vscode/launch.json` today: one config, "Factorio Mod Debug" (`type: "factorio"`, `--mod-directory E:/dev/factorio/mods --load-scenario base/freeplay`).
- `cheating-mod` already does what the launch config needs, in pieces: the `cheating-mod-auto-kit` map setting (bool) gives the demolisher kit on spawn; kits are given once the character exists (freeplay intro); `on_init` skips the intro and crash site and charts 480 tiles; **tier kits can set research** (`research = {...}`, e.g. `ring1` unlocks damage 1–2). The demolisher kit already has legendary mech armor with 2 personal roboports and 50 construction robots.
- Supply (logistic) robots only work inside a logistic network: they need a roboport and storage or provider chests, not just the personal roboport. Requester chests and personal logistics need the matching research (exact tech names: check in TS1).
- Not yet checked against the 2.1 docs (TS1): `LuaItemStack.import_stack`, `LuaItemStack.build_blueprint` (build mode, return value), `LuaEntity.revive`, a script inventory (`game.create_inventory`) to hold the blueprint, `set_tiles` for landfill.

## Issues

| # | Issue |
|---|-------|
| TS-I1 | **Target may not be the base.** Water territories turn claimed once explored, and they are often further out than the base. Then the crusade goes there, not to the test base. With the normal trigger (TS-D6) the base has to sit where the crusade will go. Handled by placing it by hand in the next target (TS-D7); the target can still change if a further territory gets claimed before the crusade starts |
| TS-I5 | ~~Real supply needs ore, and ore patches differ per map.~~ Mining is done by hand (TS-D8) |
| TS-I2 | The base territory needs a neighbour with a nest to stage from. Placing the base deep inside claimed land gives no crusade |
| TS-I3 | Terrain varies per map: water, cliffs, trees, rocks, maybe enemy entities inside the footprint |
| TS-I4 | Headless runs only load `Hostile-territory` + `Hostile-fauna` today; headless use needs `cheating-mod` in the isolated mod directory |
| TS-I6 | Both launch configs share `mods/` as mod directory, so they share `mod-settings.dat`. A crusade config that changes a setting would leave it changed for the normal debug config. See TS-Q12 |

## Steps

- [ ] **TS0** Interview: answer the open questions, write decisions here.
- [ ] **TS1** API check against the installed 2.1 game files and docs (list in Confirmed facts). Note results here.
- [ ] **TS2** First blueprint (tier 1): user builds it in game, exports the string; store it in `mods/cheating-mod/`.
- [ ] **TS3** `/cheat-base <tier>`: at the player's position (TS-D7), clear footprint, build instantly, fill the input chests with plates once (TS-D8). Terrain handling only as far as TS-Q5 and TS-D4 allow. Print what was done.
- [ ] **TS4** In-game test on a new map: stamp in ring 0 and next to ring 1, check it's complete and powered.
- [ ] **TS5** First crusade playtest on a stamped base with the normal trigger (TS-D6): note the time to the first crusade and whether it hit the base.
- [ ] **TS6** Headless: remote interface in `cheating-mod`, harness run with a stamped base and the normal trigger (ticks fast-forwarded), read the outcome.
- [ ] **TS7** More tiers (from TS-Q3).
- [ ] **TS8** Add every new command to [docs/commands.md](../docs/commands.md).
- [ ] **TS9** Crusade-test launch config (TS-D9): how the ring gets passed (TS-Q12), the builder kit (TS-Q13), research per ring (TS-Q14). Can be built before TS3: it's useful on its own for building a test base by hand.

## Open questions

- ~~**TS-Q1 Infinite or real supply?**~~ Real, and keep it simple: TS-D4, TS-D5 (2026-10-23).
- ~~**TS-Q2 Placement and claiming:**~~ Player's position (TS-D7). No claiming needed: the next crusade target is a claimed territory by definition (2026-10-23).
- **TS-Q3 Which tiers?** Proposal: early (gun turrets + walls), mid (+ flamers or lasers + power), late (+ artillery). Tied to evolution or to ring?
- ~~**TS-Q4 Point the crusade at the base?**~~ No, wait for the normal trigger: TS-D6 (2026-10-23).
- **TS-Q5 Terrain:** landfill water and remove cliffs, or refuse and print "pick another spot"? What about enemy entities inside the footprint: remove, or refuse?
- **TS-Q6 Evolution:** research now comes from the launch config (TS-D9, TS-Q14). Should the config also set evolution to match the ring, or let it build up naturally (fits TS-D6)?
- **TS-Q7 Player gear:** mostly answered by TS-D9 (gear comes from the launch config). Open: should the same kit also be reachable as `/cheat-kit crusade-ring<N>` mid-game? Proposal: yes, the config just picks that kit on spawn.
- **TS-Q8 Headless:** is a headless crusade test (TS6) wanted now, or only in-game use first? With TS-D6 a headless run would have to wait for the real budget too (fast-forwarding ticks is possible headless).
- ~~**TS-Q9 Where does the base go?**~~ By hand in the next target: TS-D7 (2026-10-23).
- ~~**TS-Q10 How much of the supply chain?**~~ Defence + ammo + power from pre-filled chests, miners by hand: TS-D8 (2026-10-23).
- **TS-Q11 How many plates per fill?** Enough for one crusade, or enough to last until the miners run? Depends on the tier; set when the first blueprint exists (TS2).
- **TS-Q12 How does the launch config say which ring?** Options: (a) replace the `cheating-mod-auto-kit` bool with a dropdown setting (`off` / `demolisher` / `crusade-ring0` / `crusade-ring1` …) and let each launch config set it, if the FMTK launch config can set mod settings (check in TS1, don't trust memory; TS-I6 applies); (b) a scenario in `cheating-mod` per ring (`--load-scenario cheating-mod/crusade-ring1`), no shared settings, but one scenario folder per ring; (c) one crusade config, pick the ring in game with `/cheat-kit crusade-ring<N>`. Proposal: (a) if FMTK supports it, else (c).
- **TS-Q13 The builder kit:** how strong is "strong power armor": power armor MK2 (fits early rings) or the legendary mech armor the demolisher kit uses? Besides robots, which buildings come with it: roboports + storage chests (needed for supply robots), poles, a stack of the blueprint's buildings? Weapons: the ring's challenge kit (`ring0`, `ring1`), or none?
- **TS-Q14 Research per ring:** which techs per ring? Proposal: always the robot and logistics techs (so the kit works), plus the ring's turret and weapon techs (start from the `ring1` kit list). Tiers (TS-Q3) could then simply be **rings**, so one ring number drives kit, research and blueprint.
