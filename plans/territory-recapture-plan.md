# Hostile Territory: Recapturing Territories

> **Status:** engine tests done, mostly absorbed by phase H · **Parent:** [vision-plan.md](vision-plan.md) (phases A and H) · **Next:** none, open questions only · [Roadmap](roadmap.md)

## Goal

Let enemies take back territories that the player has cleared. Once a territory loses its demolisher, it should be able to become hostile again under rules we decide later (timer, pollution, expansion from neighbouring territories, and so on).

We're building this step by step, testing one engine capability at a time.

## Confirmed

### Respawning a demolisher re-activates its territory (tested 2026-10-11, Factorio 2.0.77)

- `LuaTerritory.regenerate_segmented_units()` spawns the demolisher(s) that the map generator would have created for the territory. The territory's `territory_variation_expression` picks the unit.
- After a respawn, the cleared territory **becomes hostile again**. The new demolisher guards it and the territory shows on the map as before. Nothing else is needed.
- Every call adds more units. The method doesn't check for existing guards (see the API docs), so the caller must check `#territory.get_segmented_units() == 0` first.
- It raises `on_segmented_unit_created` with `cause = defines.segmented_unit_created_cause.map_generated`.
- Territories with no unit (the starting area, variation −99, or no-enemies mode) get no demolisher from this call.

Test command (stand inside a cleared territory):

```
/c local p = game.player local s = p.surface local t = s.get_territory_for_chunk{x = math.floor(p.position.x / 32), y = math.floor(p.position.y / 32)} if not t then p.print("No territory at this chunk") return end local n = #t.get_segmented_units() if n > 0 then p.print("Territory still has " .. n .. " guard(s); not respawning") return end t.regenerate_segmented_units() p.print("Respawned: " .. #t.get_segmented_units() .. " demolisher(s)")
```

### Related runtime API (2.0.77)

- `LuaSurface`: `get_territories()`, `get_territory_for_chunk(chunk_pos)`, `create_territory{chunks, patrol_path?}`, `set_territory_for_chunks(chunks, territory?)`, `clear_territory_for_chunks(chunks)`, `create_segmented_unit{name, force?, quality?, territory?}`, `get_segmented_units()`.
- `LuaTerritory`: `get_chunks()`, `get_segmented_units()`, `get_patrol_path()`, `set_patrol_path()`, `regenerate_patrol_path()`, `regenerate_segmented_units()`, `destroy()`.
- `LuaSegmentedUnit.territory` can be written, so you can move an existing unit to another territory.
- Events: `on_territory_created`, `on_territory_destroyed`, `on_segmented_unit_created`, `on_segmented_unit_died`.

## Next test: territory colour

Question: can a territory be drawn in a different colour on the map, for example to tell "cleared" territories apart from "recaptured" ones?

What the API offers:

- **There is no per-territory colour.** `LuaTerritory` has no colour property, and `TerritorySettings` has none either.
- **One global colour:** `utility-constants` → `chart.default_enemy_territory_color = {0.3, 0.03, 0.03, 0.3}` (in `core/prototypes/utility-constants.lua:162`). It's data-stage only and applies to every territory on every planet, Vulcanus included.
- **The force colour might be used:** `LuaForce.custom_color` can be written at runtime. It's unknown whether the territory overlay uses the guarding force's colour or always uses the utility constant.
- **Script overlay:** `rendering.draw_rectangle{..., render_mode = "chart"}` draws only in the map view. Drawing one rectangle per chunk from `territory.get_chunks()` gives a fully custom colour per territory, which we can update as territories change state.

### Test steps

1. **Global constant.** In `data.lua`, set `data.raw["utility-constants"].default.chart.default_enemy_territory_color` to something obvious (for example `{0, 0.3, 0, 0.3}`). Check that Nauvis territories turn green on the map.
2. **Force colour.** At runtime, run `/c game.forces.enemy.custom_color = {0, 0, 1}`. Does the territory overlay change (blue), or only the enemy unit icons?
   **Result (2026-10-11): no effect.** The overlay stays red (red hatching and a red border) for `{0,0,1}`, `{0,1,0}` and `{1,0,0}`. The overlay doesn't use the enemy force colour. Test 1 is skipped: one global colour can't tell territories apart.
3. **Script overlay.** For one territory, draw a chart-mode rectangle over each chunk:
   ```
   /c local p = game.player local s = p.surface local t = s.get_territory_for_chunk{x = math.floor(p.position.x / 32), y = math.floor(p.position.y / 32)} for _, c in pairs(t.get_chunks()) do rendering.draw_rectangle{color = {0, 0, 0.3, 0.3}, filled = true, left_top = {c.x * 32, c.y * 32}, right_bottom = {c.x * 32 + 32, c.y * 32 + 32}, surface = s, render_mode = "chart"} end
   ```
   Check how it blends with the built-in overlay. If needed, set the global constant's alpha to 0 (step 1) so that only script colours show.
   Clean up with `/c rendering.clear()`.
   **Result (2026-10-11): works, and it's good enough for now.** The chart-mode rectangles tint exactly that one territory's chunks on the map. Two side effects:
   - The built-in red overlay still shows underneath: the red border, and red hatching mixing with the tint (it comes out purple).
   - It also draws over **uncharted chunks (fog of war)**, which shows the territory's shape before the player has explored it. A possible fix later is to draw only chunks where `force.is_chunk_charted(surface, chunk)` is true, and add more as `on_chunk_charted` fires.

**Conclusion:** per-territory colours come from a script overlay (step 3). The built-in red overlay can't be recoloured per territory. Step 1's global constant (alpha 0) is still an option if we ever want to hide the built-in overlay completely.

## Open questions for recapture (later)

- What triggers a recapture: a timer, pollution, a neighbouring hostile territory, or player activity?
- Should we respawn into the original territory (`regenerate_segmented_units`), or grow territories by moving chunks with `set_territory_for_chunks`?
- Should a cleared territory stay a territory with no guard, or be cleared with `clear_territory_for_chunks`? The latter may let the map generator recreate it.
- Is it enough to keep state in `storage` (cleared tick, owner, colour state), or does it need runtime code? Recapture needs a `control.lua` again, which goes against the "no runtime code" decision in `plan.md`.
