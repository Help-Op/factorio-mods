# Factorio mods workspace

Monorepo for my Factorio mods (`E:\dev\factorio`). Main mod: **Hostile Territory**, which adds Vulcanus-style demolisher territories to Nauvis. Requires Space Age, targets Factorio 2.1 (installed: 2.1.21, experimental; switched from 2.0.77 on 2026-10-15).

## How we work

1. **Plan first, in a markdown file.** Before writing code for a new feature or test, write or extend a plan file in `plans/`.
2. **Interview before building.** Go through the plan with me: ask questions, raise open decisions, suggest options. Wait for my go-ahead before you implement.
3. **Keep the plan file current.** Update it as we go: decisions, test results (with date and game version), checked-off steps, and new open questions. Anyone should be able to pick up in a new session from the plan alone.
4. **Never commit.** I do all commits myself. You may stage changes (`git add`).
5. **One step at a time.** Do steps in order and verify each one before moving on. I often test in game myself and report back. Write my results into the plan.

## Writing style

- Clear structure, short and to the point. Use headings, bullets and tables. No filler.
- Plans use: header line → Goal → Decisions / Confirmed facts → Issues → Step-by-step checklist (`- [ ]`) → Open questions.
- Give in-game test commands as one-line `/c ...` console commands that I can paste.
- **Keep useful commands in [docs/commands.md](docs/commands.md)**: one command per fenced code block (plain lines get merged by markdown). Add every new debug command or test snippet that will be reused.

## Roadmap, inbox and plan files

CLAUDE.md says **how** we work. **What** we work on lives in `plans/`. Details: [planning-structure-plan.md](plans/planning-structure-plan.md).

- **[roadmap.md](plans/roadmap.md)** is the big picture: every plan with status and next step, open threads in order, a Mermaid map of how the plans connect, and issues across plans. Read it at the start of a session to find where we are.
- **[inbox.md](plans/inbox.md)** collects my random thoughts: one dated line each. Don't put them straight into plans. Triage together when a step is done or the list gets long: move to a plan (with a link), park, or drop.
- **Every plan starts with a header line:** `> **Status:** … · **Parent:** … · **Next:** … · [Roadmap](roadmap.md)`.
- **Plans stay the source of truth.** The roadmap only summarises them. When a plan's status or next step changes, update its header line **and** its roadmap row (and the map, if needed) in the same edit. A new plan file gets a header line and a roadmap row.

## Workspace layout

- `plans/` all plan files (flat), `docs/commands.md`, `tools/` (helper scripts, not shipped), `.vscode/` (debug config).
- `mods/` holds one folder per mod. Each mod folder contains only what goes in the zip, so no plans, tools or notes in there.
- `mods/` is also the Factorio mod directory for debug runs (`launch.json` passes `--mod-directory E:/dev/factorio/mods`). Factorio writes `mod-list.json` and `mod-settings.dat` there; both are gitignored.
- Normal play: `Hostile-territory` and `Hostile-fauna` are junctions in `%APPDATA%\Factorio\mods` pointing here. `cheating-mod` is debug-only.

## Hostile Territory (`mods/Hostile-territory`)

- `data.lua` requires `prototypes/planet/nauvis-territory.lua`, which sets `data.raw.planet.nauvis.map_gen_settings.territory_settings`.
- `control.lua` (approved 2026-10-11) only wires events and debug commands. Logic lives in `scripts/` (`territories.lua`: registry + state, `overlay.lua`: map colours, `challenge.lua`: challenge start/win/lose, `waves.lua`: challenge enemies, `attacks.lua`: cancels vanilla attacks, pollution budget, `crusade.lua`: evolution budget, target, cost, trigger and crusade phases, `staging.lua`: staging nest pick + map tag, `army.lua`: army mix, spawning and unit list, `rally.lua`: rally plan, spot, build, `tags.lua`: map tags, `patrol.lua`: reroutes patrol paths over land using the elevation noise, and wyrms make land when kited over water). `prototypes/entity/` holds the tiny biter and slowdown stickers. See phases A–E in `plans/vision-plan.md`.
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
