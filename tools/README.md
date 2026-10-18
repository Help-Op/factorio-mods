# Tools

Helper scripts and test mods. Not shipped. Test mods run in an isolated `--mod-directory` (junctions to the mods under test, see CLAUDE.md "Headless test harness"), unless noted.

| Tool | What | Status | Used by |
|------|------|--------|---------|
| `check-paths.py` | Every file path in a `--dump-data` dump must exist | Current: run after prototype changes | CLAUDE.md |
| `ht-map-check/` | Reads territories and brain bases, changes no data: one base per territory, brain on its point, water territories clean, stray enemies. Headless on tick 2 → `script-output/map-check-result.txt`; in game `/ht-map-check`, `/ht-map-nearest` | Current. Junction `mods/ht-map-check` for debug runs (gitignored) | territory-brain B2, B3 |
| `ht-regrow-test/` | Regrowth: knocks pieces out of a base, `place_brain` in a water territory, runs `regrow` rounds. Needs `ht-map-check` (it generates the area) | Current headless regression test | territory-brain B5 |
| `ht-staging-test/` | Crusade staging next door: small generated area, one brain killed, `staging_for` | Current headless regression test | territory-brain B-I9 |
| `ht-challenge-test/` | First-ring challenge (E1, E2): gun and brain numbers (incl. fissures), starting resources vs. the 150 safe zone, territory edge per 15°, brain distances, climax flank arrivals, ring-0 waves via the `waves_step` debug call (groups from nests, fewer after nests die, swarm below 50 %). Headless only (no players: drives waves against a player-less character). → `script-output/e1-result.txt` | Current headless regression test | challenge-feel E1-8 |
| `ht-ring-check/` | Rings and oil (ring-layout R1): ring per territory (Lua vs noise), territories per ring, oil patches per ring, the guaranteed ring-1 patch. Headless on tick 10 → `script-output/ring-check-result.txt` | Current headless regression test | ring-layout R1-4 |
| `hf-brain-test/` | Puts the brains into `territory_settings` before HT did | Historical (superseded by B2); kept for its result file | territory-brain B1 |
| `ht-layout-test/` | Map-gen layout tests L1–L4 (one folder per version, L4 at the top) | Historical (superseded by HT's own map gen); kept for its result files. Overrides HT's noise, so never load it together with HT's current map gen | hive-layout L1–L4 |

Headless runs without a server: `--create x.zip --map-gen-seed 12345`, then `--benchmark x.zip --benchmark-ticks N --benchmark-runs 1` (runs `control.lua`, exits by itself). Own `--config` with `write-data` in the scratchpad. Details: hive-layout-plan.md, step-by-step checklist.
