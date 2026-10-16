# Workspace migration plan

## Goal

Move development into one workspace at `E:\dev\factorio`:

- Plans, tools and docs at the workspace root, the mods under `mods/`.
- Each mod folder holds only what goes in the zip.
- Unrelated mods (gameplay mods, `noise-tools`, `team-starts`, `zones_survivor`) stay out.
- Factorio loads the dev mods in two ways: directly from `E:\dev\factorio\mods` for debug runs, and through junctions for normal play.

## Target layout

```
E:\dev\factorio\                  ← git repo (continues the Hostile-territory repo)
  CLAUDE.md
  docs/commands.md
  plans/                          ← all *-plan.md files and reports (flat)
  tools/                          ← check-paths.py, later package.py and the harness
  .vscode/launch.json             ← --mod-directory E:/dev/factorio/mods
  .gitignore
  mods/                           ← Factorio mod directory for debug runs
    Hostile-territory/            ← tracked, zip contents only
    Hostile-fauna/                ← tracked
    cheating-mod/                 ← tracked
    mod-list.json                 ← ignored (Factorio writes it)
    mod-settings.dat              ← ignored
    *.zip                         ← ignored (dependencies, if ever needed)

C:\Users\Sam\AppData\Roaming\Factorio\mods\
  Hostile-territory  → junction to E:\dev\factorio\mods\Hostile-territory
  Hostile-fauna      → junction
  (gameplay mods unchanged)
```

## Decisions

| # | Decision | Why |
|---|----------|-----|
| W1 | Workspace at `E:\dev\factorio` | Your choice. Keeps dev work out of `AppData`. |
| W2 | One monorepo for all three mods | Hostile-territory depends on Hostile-fauna, and they share plans and commits. |
| W3 | Continue the existing Hostile-territory repo; its files move with `git mv` into `mods/Hostile-territory/` | Keeps its 10 commits and the GitHub remote. `git log --follow` still finds the history. |
| W4 | `mods/` is the debug mod directory (`--mod-directory`), not a junction | Factorio supports only one mod directory, with no per-mod paths (checked `factorio.exe --help`, 2.1.21). Pointing at it directly needs no junctions. |
| W5 | Junctions in `AppData\...\mods` for normal play | Your choice. Lets a normal Steam launch see the dev mods. |
| W6 | Build the workspace from a clone, leave the old folders until verified | Easy to roll back. The original stays usable until step 9. |
| W7 | `cheating-mod` is debug-only: no junction in `AppData` (Q1, 2026-10-16) | It's a test helper, so keep it out of normal saves. |
| W8 | Rename the GitHub repo to `factorio-mods` (Q2, 2026-10-16) | The repo holds several mods now. GitHub redirects the old URL. |
| W9 | `commands.md` → `docs/commands.md` (Q3, 2026-10-16) | Keeps the root tidy as reference docs grow. |
| W10 | Flat `plans/` folder, no per-mod subfolders (Q4, 2026-10-16) | Most plans cover both mods. |
| W11 | The harness keeps an isolated mod dir with junctions to `E:\dev\factorio\mods\<mod>` (Q5, 2026-10-16) | Test runs don't depend on, or change, the debug `mod-list.json`. |

## Confirmed facts (2026-10-16)

- Factorio 2.1.21 has only `--mod-directory PATH` (one folder). `mod-list.json` stores names, not paths.
- `E:` is a fixed, local NTFS disk ("Extra Disk"). Junctions from `C:` to `E:` work.
- `E:\dev\factorio` already exists and is empty.
- FMTK 2.1.9 launch type `factorio` has no `modsPath` option. Its options are `factorioArgs`, `tags`, `followSymlinks`, `hookDebugConsole` and `trace`, so the mod directory goes in `factorioArgs`.
- `Hostile-fauna` has a `.git` with **no commits** (all files untracked). There's no history to keep.
- `cheating-mod` has no git repo.
- Hostile-territory remote: `https://github.com/Help-Op/hostile-territory.git`.
- Claude project memory for the old path is empty, so nothing needs to move.

## Issues

- **Uncommitted work.** Hostile-territory has many modified and untracked files. You have to commit them before cloning (step 1), or they won't come along.
- **The old folders have the same names as the junctions.** The old `AppData` folders must be moved out before the junctions can be created (step 8).
- **`.vscode/settings.json`** contains a machine path into FMTK's `workspaceStorage`. FMTK regenerates it for the new workspace, so delete the line and let it come back.
- **Headless harness** (plan.md step 5) builds an isolated mod directory with a junction to the mod. It needs new paths (step 7).
- **Paths in docs:** `CLAUDE.md` (`../Hostile-fauna`, `../cheating-mod`, plan table links) and `enemy-balancing-plan.md` line 5.
- **`scripts/test-plan.md`** is a plan inside the mod's code folder. It moves to `plans/`.
- **Normal-play junctions:** if `E:` is missing, Factorio errors on these mods at startup.

## Steps

- [ ] **1. Commit current work (you).** Commit everything in Hostile-territory, including the untracked `commands.md`, `enemy-balancing-plan.md`, `scripts/patrol.lua`, `scripts/test-plan.md`, `tools/` and this plan.
- [ ] **2. Clone into the workspace.** `git clone C:\Users\Sam\AppData\Roaming\Factorio\mods\Hostile-territory E:\dev\factorio`. Rename the GitHub repo to `factorio-mods` (you, on GitHub), then `git remote set-url origin https://github.com/Help-Op/factorio-mods.git`.
- [ ] **3. Restructure with `git mv`.**
  - Mod files → `mods/Hostile-territory/`: `info.json`, `data.lua`, `control.lua`, `scripts/`, `prototypes/`, `locale/` (plus `graphics/`, `thumbnail.png`, `changelog.txt` if they exist).
  - `*-plan.md`, `overlay-debug-report.md`, `scripts/test-plan.md` → `plans/`.
  - `commands.md` → `docs/commands.md`.
  - `CLAUDE.md`, `tools/`, `.vscode/` stay at the root.
  - Check: `mods/Hostile-territory/` contains only files that belong in the zip.
- [ ] **4. Add the other mods.** Copy `Hostile-fauna` (without its empty `.git`) and `cheating-mod` into `mods/`. Run `git add`.
- [ ] **5. Add `.gitignore`.** Ignore `mods/mod-list.json`, `mods/mod-settings.dat`, `mods/*.zip` and `script-output/`.
- [ ] **6. Update the debug launch config.** In `.vscode/launch.json` set `"factorioArgs": ["--mod-directory", "E:/dev/factorio/mods", "--load-scenario", "base/freeplay"]`. Remove the `workspaceStorage` line from `settings.json`.
  - Test: open `E:\dev\factorio` in VS Code, press F5, and check that freeplay starts with all three mods enabled and breakpoints hit in `mods/Hostile-territory/control.lua`.
- [ ] **7. Fix paths in docs and tools.** Update the `CLAUDE.md` project layout, the plan table and the harness notes. Fix `enemy-balancing-plan.md` line 5. Update the harness so its isolated mod dir has junctions to `E:\dev\factorio\mods\<mod>` (W11). Update every `commands.md` link to `docs/commands.md`. Then run `tools/check-paths.py` on a fresh `--dump-data`.
  - Test: one headless harness run (territory count matches plan.md step 5).
- [ ] **8. Swap the AppData folders for junctions.** Move the old `Hostile-territory`, `Hostile-fauna` and `cheating-mod` folders out of `AppData\...\mods` into a backup, e.g. `E:\dev\factorio-backup`. Then create junctions for `Hostile-territory` and `Hostile-fauna` only (no junction for `cheating-mod`, W7):
  ```bash
  cmd //c mklink /J "C:\Users\Sam\AppData\Roaming\Factorio\mods\Hostile-territory" "E:\dev\factorio\mods\Hostile-territory"
  ```
  - Test: launch Factorio from Steam and check that the mods appear in the mod list and a new game starts.
- [ ] **9. Clean up.** After a few days without problems, delete the backup. Start Claude Code sessions from `E:\dev\factorio` from now on.
- [ ] **10. (Optional) Packaging.** Add `tools/package.py`: it zips `mods/<name>` into `<name>_<version>.zip` with the top folder `<name>_<version>/`, reading the version from `info.json`.

## Open questions

None. Q1–Q5 were answered on 2026-10-16 (see W7–W11).
