# Factorio mods workspace

Monorepo for my Factorio mods (`E:\dev\factorio`). Main mod: **Hostile Territory**, which adds Vulcanus-style demolisher territories to Nauvis. Requires Space Age, targets Factorio 2.1 (installed: 2.1.21, experimental; switched from 2.0.77 on 2026-10-15).

## How we work

The global "How we work" list applies (plan first, interview before building, keep the plan current, one step at a time; I commit). Here, results carry the date and game version, and every playtest (PT) is handed over in the dispatch skill's **Play hand-over** shape (`~/.claude/skills/dispatch/SKILL.md`), in chat and as the PT's step in the plan; *Send back* is the telemetry CSV name and feel notes.

## Side sessions

Offer a separate session (with a full brief, starting from the plan file) for work that stands on its own (tried 2026-10-23, the ring-1 brainstorm). For a whole thread run from one session, use `/dispatch` (user skill), which follows the rules below and the Dispatch section:

- **Brainstorm / design** when a question goes open-ended.
- **Playtest analysis**: read the telemetry, write the PT step into the plan.
- **Parallel roadmap threads** that don't touch the same files.
- **Review** of a finished build step before I playtest it.
- **Test sweeps** (seeds, parameter variants): each headless run gets its own write-data folder.

Rules:

- Side sessions share this checkout and **never commit**.
- Each session edits only **its own plan file and code area**.
- **One session at a time** edits `plans/roadmap.md` (and other shared files like `docs/commands.md`).
- A session that needs another's changes waits until I've reviewed them.

## Writing style

- Clear structure, short and to the point. Use headings, bullets and tables. No filler.
- Give in-game test commands as one-line `/c ...` console commands that I can paste.
- **Keep useful commands in [docs/commands.md](docs/commands.md)**: one command per fenced code block (plain lines get merged by markdown). Add every new debug command or test snippet that will be reused.

## Plans, roadmap and dispatch

- **Plans** follow the user skill `planning` (`~/.claude/skills/planning/`): read it before editing anything in `plans/`. Start a session with [roadmap.md](plans/roadmap.md) to find where we are; new ideas go to [inbox.md](plans/inbox.md). This workspace's history of those rules: [planning-structure-plan.md](plans/planning-structure-plan.md).
- The pre-commit hook (`.githooks/`, enabled with `git config core.hooksPath .githooks`) runs the shared plan-header check.

## Dispatch

What the dispatch skill leaves to the project:

- **Checks:** the headless harness (Factorio gotchas below; scripts in `tools/`, see `tools/README.md`); after prototype changes, `--dump-data` + `python tools/check-paths.py`. Sprites, overlays and feel only show in game.
- **Architecture doc:** the mod sections below (Hostile Territory, Other mods).
- **Existing things** to reuse: `mods/*/prototypes/`, `mods/Hostile-territory/scripts/`, `docs/commands.md`; numbers come from the Lua prototypes and scripts.
- **Polish rule:** balance changes quote the last telemetry CSV first (which phase is slow, what a cap counts).
- **Play setup:** one-line `/c` commands from `docs/commands.md`, the `cheating-mod` kit; the play writes a telemetry CSV to `script-output/ht-telemetry/`. Branch runs: not yet (planning-structure PS7).

## Workspace layout

- `plans/` all plan files (flat), `docs/commands.md`, `tools/` (helper scripts, not shipped), `.vscode/` (debug config).
- `mods/` holds one folder per mod. Each mod folder contains only what goes in the zip, so no plans, tools or notes in there.
- `mods/` is also the Factorio mod directory for debug runs (`launch.json` passes `--mod-directory E:/dev/factorio/mods`). Factorio writes `mod-list.json` and `mod-settings.dat` there; both are gitignored.
- Normal play: `Hostile-territory` and `Hostile-fauna` are junctions in `%APPDATA%\Factorio\mods` pointing here. `cheating-mod` is debug-only.

## Hostile Territory (`mods/Hostile-territory`)

- `data.lua` requires `prototypes/planet/nauvis-territory.lua`, which builds territories from our own points (`hostile_point_*` noise) and sets `data.raw.planet.nauvis.map_gen_settings.territory_settings` (units = the brains). `data-final-fixes.lua` requires `prototypes/planet/brain-bases.lua`: one brain base per territory around its point (`hostile_base_*` noise), every other enemy autoplace off. See `plans/territory-brain-plan.md`.
- `control.lua` (approved 2026-10-11) only wires events and debug commands. Logic lives in `scripts/` (`territories.lua`: registry + state, `overlay.lua`: map colours, `challenge.lua`: challenge start/win/lose, `waves.lua`: challenge enemies, `attacks.lua`: cancels vanilla attacks, pollution budget, `crusade.lua`: evolution budget, target, cost, trigger and crusade phases, `staging.lua`: staging nest pick + map tag, `army.lua`: army mix, spawning and unit list, `rally.lua`: rally plan, spot, build, `tags.lua`: map tags, `patrol.lua`: reroutes patrol paths over land using the elevation noise, and wyrms make land when kited over water, `brain.lua`: moves each brain onto its base when the chunk with its point is generated, or claims the territory and removes the base when the point is on water, `regrow.lua`: hostile bases regrow one missing piece per minute, also around a brain a lost crusade created, `oil.lua`: places the guaranteed oil patch in ring 1, since map gen keeps crude oil out of ring 0, `director.lua`: pressure director, caps the damage a participant takes in the ring-1 swarm, `telemetry.lua`: per-second challenge CSV in `script-output/ht-telemetry/`). `prototypes/entity/` holds the tiny biter and slowdown stickers. See phases A–E in `plans/vision-plan.md`.
- Debug through VS Code with the Factorio Mod Debug extension (`.vscode/launch.json` launches straight into freeplay).

## Other mods

- `mods/Hostile-fauna` is the enemy overhaul mod (slower enemies, new units, new segmented units, player speed). Hostile Territory has a hard dependency on it. Plan: `plans/enemy-balancing-plan.md`.
- `mods/cheating-mod` is a separate helper mod for testing. Map setting `cheating-mod-auto-kit` (default off) gives the demolisher kit on spawn. `/cheat-kit [name]` (demolisher, pistol, smg-yellow, smg-red, smg-uranium, shotgun, flamethrower, rockets) and `/cheat-clear` work anytime.

## Factorio gotchas

- Use the 2.1 API: `storage`, not `global`. `rendering.draw_*` returns a `LuaRenderObject`, which you remove with `.destroy()`.
- Territory units must be `segmented-unit` prototypes (demolishers), not biters.
- Check the API against the installed game files (`Factorio/data/`) and the 2.1 docs. Don't trust memory.
- Headless test harness (described in `plans/territory-mapgen-plan.md` step 5): `--create` with map-gen settings, then `--start-server` with RCON, then generate chunks and count territories and demolishers. Use `/c __Hostile-territory__ ...` to read the mod's `storage`. The server needs `auto_pause = false`. Headless never charts chunks, so map overlays must be tested in game (`force.chart()` and chart tags do work headless).
- Harness details: build `server-settings.json` from `data/server-settings.example.json` (a partial file is rejected). Run with an isolated `--mod-directory` in the scratchpad (junctions to `E:\dev\factorio\mods\Hostile-territory` and `mods\Hostile-fauna`, plus a minimal `mod-list.json`), so the run only has the mods under test and never touches the debug `mods/mod-list.json`. On 2.1 the `debugadapter` mod is gone; FMTK uses Factorio's native debugger (launch `type: "factorio"`). In Git Bash set `MSYS_NO_PATHCONV=1`, or `/c` gets rewritten to a path. Console code can't `require`; read module output through the `hostile-territory-debug` remote interface. Stop the server by PID, not by image name, and always at the end of a test run: a forgotten headless server crashed the in-game start (2026-10-15). Headless doesn't load sprites, so wrong sprite sizes and missing files only show up in game: check image sizes in the game files, and after prototype changes run `--dump-data` + `python tools/check-paths.py <write-data>/script-output/data-raw-dump.json` (every file path in our prototypes must exist; caught the earth wyrm icon bug).
- The parameter lists in `doc-html/runtime-api.json` aren't in call order. Sort them by `order` before trusting them.
- `script.on_nth_tick` keeps one handler per interval: registering the same interval twice silently replaces the first handler (this switched off the crusade check, 2026-10-17). In Hostile Territory, always register timers through `every(interval, handler)` in `control.lua`.
