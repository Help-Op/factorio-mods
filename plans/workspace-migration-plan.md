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
| W12 | Harness becomes `tools/harness.py` (Q6, 2026-10-16) | Reusable instead of rebuilt each session. Fixes the lost-first-RCON-command bug once. Step 11. |
| W13 | `.vscode/settings.json` untracked and gitignored (Q7, 2026-10-16) | FMTK writes a machine-specific `workspaceStorage` path into it on every open. `launch.json` stays tracked. |

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

- [x] **1. Commit current work (you).** Done 2026-10-16 (`a398997`). Commit everything in Hostile-territory, including the untracked `commands.md`, `enemy-balancing-plan.md`, `scripts/patrol.lua`, `scripts/test-plan.md`, `tools/` and this plan.
- [x] **2. Clone into the workspace.** Done 2026-10-16: cloned at `a398997`, origin points to `hostile-territory.git` for now. **Still open:** rename the repo on GitHub (you), then run `git remote set-url origin https://github.com/Help-Op/factorio-mods.git`. Original plan: `git clone C:\Users\Sam\AppData\Roaming\Factorio\mods\Hostile-territory E:\dev\factorio`. Rename the GitHub repo to `factorio-mods` (you, on GitHub), then `git remote set-url origin https://github.com/Help-Op/factorio-mods.git`.
- [x] **3. Restructure with `git mv`.** Done 2026-10-16: 28 renames staged. `mods/Hostile-territory/` holds only `info.json`, `data.lua`, `control.lua`, `locale/`, `prototypes/`, `scripts/` (no graphics, thumbnail or changelog yet). Links in `CLAUDE.md` are broken until step 7.
  - Mod files → `mods/Hostile-territory/`: `info.json`, `data.lua`, `control.lua`, `scripts/`, `prototypes/`, `locale/` (plus `graphics/`, `thumbnail.png`, `changelog.txt` if they exist).
  - `*-plan.md`, `overlay-debug-report.md`, `scripts/test-plan.md` → `plans/`.
  - `commands.md` → `docs/commands.md`.
  - `CLAUDE.md`, `tools/`, `.vscode/` stay at the root.
  - Check: `mods/Hostile-territory/` contains only files that belong in the zip.
- [x] **4. Add the other mods.** Done 2026-10-16: `Hostile-fauna` (9 files, no `.git`) and `cheating-mod` (4 files) copied, `diff -r` identical to the originals, staged. The originals in `AppData` stay until step 8. Copy `Hostile-fauna` (without its empty `.git`) and `cheating-mod` into `mods/`. Run `git add`.
- [x] **5. Add `.gitignore`.** Done 2026-10-16, checked with `git check-ignore`: the four patterns are ignored, mod files stay tracked. Ignore `mods/mod-list.json`, `mods/mod-settings.dat`, `mods/*.zip` and `script-output/`.
- [x] **6. Update the debug launch config.** Done 2026-10-16 (Factorio 2.1.21, FMTK 2.1.9): `launch.json` has `--mod-directory`. F5 test passed: freeplay starts with all three mods enabled, breakpoints hit. FMTK re-added its `userThirdParty` `workspaceStorage` path to `settings.json` with the new workspace hash, as expected. In `.vscode/launch.json` set `"factorioArgs": ["--mod-directory", "E:/dev/factorio/mods", "--load-scenario", "base/freeplay"]`. Remove the `workspaceStorage` line from `settings.json`.
  - Test: open `E:\dev\factorio` in VS Code, press F5, and check that freeplay starts with all three mods enabled and breakpoints hit in `mods/Hostile-territory/control.lua`.
- [x] **7. Fix paths in docs and tools.** Done 2026-10-16 (2.1.21). `CLAUDE.md`: new workspace layout section, plan table links into `plans/`, `docs/commands.md`, harness note (W11). `enemy-balancing-plan.md`: line 5 and the `commands.md` link. `tools/check-paths.py`: `MODS` now points to `<workspace>/mods/`.
  - **`--dump-data` + `check-paths.py`:** passed. Both mods loaded through junctions to the workspace; 2246 paths checked, 0 missing.
  - **Headless harness (seed 12345, 1600 tiles):** passed. 98 territories (same as the 2.1.21 baseline in `enemy-balancing-plan.md`), 71 segmented units, 0 error lines, server stopped by PID.
  - Harness note: the first RCON command after auth got an empty reply and did not run, so the first try showed only 5 territories (start area only). Send a throwaway command first.
  - Original step: Update the `CLAUDE.md` project layout, the plan table and the harness notes. Fix `enemy-balancing-plan.md` line 5. Update the harness so its isolated mod dir has junctions to `E:\dev\factorio\mods\<mod>` (W11). Update every `commands.md` link to `docs/commands.md`. Then run `tools/check-paths.py` on a fresh `--dump-data`.
  - Test: one headless harness run (territory count matches plan.md step 5).
- [ ] **8. Swap the AppData folders for junctions.** Partly done 2026-10-16:
  - The backup is `C:\Users\Sam\AppData\Roaming\Factorio\dev-mods-backup`. It's on the same disk as the mods folder, so the move is a plain rename with no copy-and-delete, and it's outside the mods folder, so Factorio ignores it.
  - The old Hostile-territory repo was checked first. Its changes since `a398997` are line endings only (`git diff --ignore-cr-at-eol` is empty), so nothing is lost.
  - [x] `Hostile-fauna` and `cheating-mod` moved to the backup. Junction `Hostile-fauna` → `E:\dev\factorio\mods\Hostile-fauna` created and resolves.
  - [ ] `Hostile-territory`: the move failed because the folder was in use (it was the Claude session's working directory). Do it from a session opened in `E:\dev\factorio`, with VS Code closed on the old folder: move the folder to the backup, then create the junction.
  - [ ] Test (you): launch Factorio from Steam and check that both mods show in the mod list and a new game starts.
  - Original step: Move the old `Hostile-territory`, `Hostile-fauna` and `cheating-mod` folders out of `AppData\...\mods` into a backup, e.g. `E:\dev\factorio-backup`. Then create junctions for `Hostile-territory` and `Hostile-fauna` only (no junction for `cheating-mod`, W7):
  ```bash
  cmd //c mklink /J "C:\Users\Sam\AppData\Roaming\Factorio\mods\Hostile-territory" "E:\dev\factorio\mods\Hostile-territory"
  ```
  - Test: launch Factorio from Steam and check that the mods appear in the mod list and a new game starts.
- [ ] **9. Clean up.** After a few days without problems, delete the backup. Start Claude Code sessions from `E:\dev\factorio` from now on.
- [ ] **10. (Optional) Packaging.** Add `tools/package.py`: it zips `mods/<name>` into `<name>_<version>.zip` with the top folder `<name>_<version>/`, reading the version from `info.json`.
- [ ] **11. Harness script (W12).** `tools/harness.py`: builds an isolated mod dir in a temp folder (junctions to the chosen `mods/<mod>`, minimal `mod-list.json`), a `config.ini` with its own write-data, `server-settings.json` from the example with `auto_pause = false`. Args: mods, seed, radius, optional extra `/c` commands. Creates the map, starts the server with RCON, sends a throwaway command first (the first one after auth gets an empty reply), generates chunks, prints territory and segmented-unit counts and log error lines, and always stops the server by PID. Optional `--dump-data` mode runs `check-paths.py`. Plan the interface with you before building.
  - Test: seed 12345, 1600 tiles gives 98 territories.

## Open questions

None. Q1–Q5 answered 2026-10-16 (W7–W11), Q6–Q7 answered 2026-10-16 (W12–W13).
