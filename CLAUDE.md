# Hostile Territory

Factorio mod that adds Vulcanus-style demolisher territories to Nauvis. Requires Space Age, targets Factorio 2.0 (installed: 2.0.77).

## How we work

1. **Plan first, in a markdown file.** Before writing code for a new feature or test, write or extend a plan file in the repo root.
2. **Interview before building.** Go through the plan with me: ask questions, raise open decisions, suggest options. Wait for my go-ahead before you implement.
3. **Keep the plan file current.** Update it as we go: decisions, test results (with date and game version), checked-off steps, and new open questions. Anyone should be able to pick up in a new session from the plan alone.
4. **One step at a time.** Do steps in order and verify each one before moving on. I often test in game myself and report back. Write my results into the plan.

## Writing style

- Clear structure, short and to the point. Use headings, bullets and tables. No filler.
- Plans use: Goal → Decisions / Confirmed facts → Issues → Step-by-step checklist (`- [ ]`) → Open questions.
- Give in-game test commands as one-line `/c ...` console commands that I can paste.

## Plan files

| File | Topic | Status |
|------|-------|--------|
| [vision-plan.md](vision-plan.md) | Overall vision: challenges, crusades, territory states | Draft, refining |
| [plan.md](plan.md) | Nauvis territories via map gen | Main plan. Steps 1–6 done, 7–8 open |
| [territory-recapture-plan.md](territory-recapture-plan.md) | Enemies recapturing cleared territories | Active, still exploring |
| [nauvis-territories-plan.md](nauvis-territories-plan.md) | Old approach | Superseded by `plan.md` |
| [overlay-debug-report.md](overlay-debug-report.md) | Old runtime overlay bugs | Outdated, to archive |

## Project layout

- `data.lua` requires `prototypes/planet/nauvis-territory.lua`, which sets `data.raw.planet.nauvis.map_gen_settings.territory_settings`.
- `control.lua` (approved 2026-10-11) only wires events and debug commands. Logic lives in `scripts/` (`territories.lua`: registry + state, `overlay.lua`: map colours). See phase A in `vision-plan.md`.
- Debug through VS Code with the Factorio Mod Debug extension (`.vscode/launch.json` launches straight into freeplay).
- `../cheating-mod` is a separate helper mod for testing (start gear strong enough to kill demolishers).

## Factorio gotchas

- Use the 2.x API: `storage`, not `global`. `rendering.draw_*` returns a `LuaRenderObject`, which you remove with `.destroy()`.
- Territory units must be `segmented-unit` prototypes (demolishers), not biters.
- Check the API against the installed game files (`Factorio/data/`) and the 2.0 docs. Don't trust memory.
- Headless test harness (described in `plan.md` step 5): `--create` with map-gen settings, then `--start-server` with RCON, then generate chunks and count territories and demolishers. Use `/c __Hostile-territory__ ...` to read the mod's `storage`. The server needs `auto_pause = false`. Headless never charts chunks, so map overlays must be tested in game.
- The parameter lists in `doc-html/runtime-api.json` aren't in call order. Sort them by `order` before trusting them.
