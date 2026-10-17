> **Status:** outdated (2.0 era, uses `global`) · **Parent:** none · **Next:** archive (roadmap R1) · [Roadmap](roadmap.md)

**Hostile-territory: Overlay troubleshooting log**

**Summary**
- **Purpose:** Diagnose why territory overlays (in-world and map/alt-mode) are not appearing reliably.
- **Current state:** Multiple fixes and debug commands added; overlay rendering works intermittently (screenshots show success and failure). Command-based rebuild/refresh utilities are available.

**What we tried**
- **Code inspection:** Reviewed `control.lua` to see how overlays are generated and why none were drawn (found rendering tied to `global.ht_nests`).
- **Manual scan:** Asked user to run `/ht-scan` to detect enemy units and create `demolisher-nest` entities; this created nests when enemies existed.
- **Protected rendering:** Replaced direct `rendering.destroy` calls with guarded calls to avoid runtime errors when the `rendering` API differs. Added `safe_destroy()` wrapper and swapped all direct calls.
- **Debug overlay command:** Added `/ht-debug-map-visible` to draw stronger, always-visible overlays (not limited to Alt) for quick verification.
- **Rebuild/clear registry:** Added `/ht-rebuild-nests` to repopulate `global.ht_nests` from existing `demolisher-nest` entities and `/ht-clear-nests` to clear the registry without removing entities.
- **Force-visible draw:** Implemented a debug draw that increases radius/alpha and draws text so markers are easy to spot.

**Files changed**
- **`control.lua`**: multiple patches
  - Added `safe_destroy()` and replaced fragile `rendering.destroy` calls.
  - Added `/ht-debug-map-visible`, `/ht-rebuild-nests`, `/ht-clear-nests` commands.
  - Kept overlay drawing logic (`create_overlays_on_surface` and `refresh_overlays`) and added map-overlay tracking in `global.ht_map_overlays`.

**Commands used during debugging**
- `/ht-scan` — scans surface for enemies (`small-biter`, `medium-biter`, `big-biter`) and creates nests (registers them in `global.ht_nests`).
- `/ht-overlay-refresh` — destroys existing overlays and redraws from the registry.
- `/ht-toggle-map-overlay` — toggles alt-mode-only map overlays.
- `/ht-debug-map-visible` — toggles force-visible debug overlays (always drawn, stronger visuals).
- `/ht-rebuild-nests` — rebuilds `global.ht_nests` from placed `demolisher-nest` entities.
- `/ht-clear-nests` — clears the registry (does not delete entities).

**Observations / Logs**
- When `/ht-scan` found enemies, nests were created and `global.ht_nests` populated (example: 44 nests created; overlays total now: 88 labels: 44).
- On at least one run, `/ht-debug-map-visible` produced visually obvious markers on the map (screenshot shows colored patches at multiple nest positions).
- In other runs (different save or session), console shows `registered_nests=0` and `overlays total now: 0`, and no map overlays are visible.
- A runtime error was encountered earlier: `LuaRendering doesn't contain key destroy` — fixed by wrapping calls in `pcall`.

**Likely causes of inconsistent visibility**
- `global.ht_nests` empty: if no nests are registered (or registry was not persisted), refresh draws nothing.
- Rendering API/runtime differences: some runtimes may not expose `rendering.destroy` (fixed), or rendering commands may fail silently on some clients.
- Map rendering specifics: `only_in_alt_mode` overlays depend on the player's map zoom/alt-state and client-side rendering; these can sometimes be invisible or appear behind other layers depending on zoom.
- Multiplayer/permission/context: if commands are run from server console or non-local players, some rendering may not appear to a given player (client-specific behavior).

**Where we are now (status)**
- `control.lua` contains multiple defensive guards and debug commands to re-create overlays and registry without restarting the game.
- We can reproduce two states: (A) overlays visible (after a successful `/ht-scan` + `/ht-debug-map-visible`), (B) overlays missing (registry empty or refresh drawing 0 overlays).
- The mod now includes commands to rebuild/clear the registry and to draw force-visible overlays for verification.

**Recommended next steps (options)**
- **Option 1 — Quick verification:** Run these commands in-game in this order and report console output/screenshot:
  ```
  /ht-scan
  /ht-rebuild-nests
  /ht-overlay-refresh
  /ht-debug-map-visible
  ```
  If overlays appear, we can finalize stronger defaults or add a one-time rebuild on load.

- **Option 2 — Visible temporary entities:** Add a debug command to spawn temporary, visible entities (e.g., `small-lamp` or `simple-entity` marker) at each nest position so you can visually confirm nest positions in-world and on the map.

- **Option 3 — Chart/map tags:** Use chart tags or map icons (if available in your Factorio API version) instead of rendering; chart tags are persistent and visible on the map independent of rendering layers. (I will implement this if you prefer — requires verifying the exact chart API in your Factorio version.)

- **Option 4 — Persist registry on save/load:** Ensure `global.ht_nests` is populated reliably on load by scanning for placed `demolisher-nest` entities on `on_load` or on the first tick; I can implement an automatic rebuild on init.

**Suggested immediate action**
- Run the quick verification commands listed under Option 1 and paste the console output or a screenshot.

If you want, I can now implement Option 2 (visible temporary markers) or Option 3 (chart tags). Tell me which and I'll make the patch and add the new commands.

---
Generated on 2026-08-16 for the `Hostile-territory` mod.