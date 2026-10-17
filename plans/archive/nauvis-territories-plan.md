# Plan: add Vulcanus-style territories to Nauvis

> **Status:** archived 2026-10-17, superseded by [territory-mapgen-plan.md](../territory-mapgen-plan.md), don't use · [Roadmap](../roadmap.md)

## Goal

Add territory-based enemy spawning to Nauvis so that the world behaves similarly to Vulcanus, where the game uses a territory map and then spawns unit groups from a unit pool (for example `small-demolisher`, `medium-demolisher`, `big-demolisher`).

This is intended as a practical implementation plan for a mod project, based on the patterns in the installed Factorio data files.

## What we have confirmed from the game files

The relevant patterns are visible in the installed game data:

- `C:\Program Files (x86)\Steam\steamapps\common\Factorio\data\space-age\prototypes\planet\planet-map-gen.lua`
- `C:\Program Files (x86)\Steam\steamapps\common\Factorio\data\space-age\prototypes\planet\planet-vulcanus-map-gen.lua`
- `C:\Program Files (x86)\Steam\steamapps\common\Factorio\data\base\prototypes\planet\planet-map-gen.lua`

The Vulcanus pattern is:

- a `territory_settings` block on the planet map definition
- a territory index expression
- a territory variation expression
- a minimum territory size
- a unit list such as `{"small-demolisher", "medium-demolisher", "big-demolisher"}`

This strongly indicates that the actual territory logic is driven by the planet-generation data and generic territory system, not by a direct Lua `create_territory()` call in the enemy prototype itself.

---

## General design approach

Use the same conceptual model as Vulcanus:

1. Create terrain-noise expressions that divide the map into regions.
2. Exclude starting areas, if desired.
3. Turn those regions into enemy territory zones.
4. Choose a unit from the territory unit pool based on the variation index.
5. Keep the territories away from the player spawn and optionally disable them in special cases.

The safest strategy is to treat this as a map-generation patch rather than a direct runtime enemy spawn patch.

---

## Recommended mod structure

Create a new data-stage file in the mod, for example:

- `prototypes/planet/nauvis-territory.lua`
- or a single `data.lua` block that patches the Nauvis planet generation table

Then include a file such as:

- `data.lua`:

```lua
require("prototypes.planet.nauvis-territory")
```

This keeps the territory logic isolated and easier to debug.

---

## Step-by-step implementation plan

### 1. Identify the Nauvis planet generation table to patch

The base game defines Nauvis in:

- `data/base/prototypes/planet/planet-map-gen.lua`

The Vulcanus implementation adds its own custom map-gen expressions in:

- `data/space-age/prototypes/planet/planet-vulcanus-map-gen.lua`

For your mod, do not replace the whole game data file. Instead, patch the generated table at data stage.

The goal is to augment the existing Nauvis generation with a `territory_settings` section.

---

### 2. Decide which enemies will be territory units

For a Nauvis equivalent, choose a unit list similar to:

```lua
units = {"small-biter", "medium-biter", "big-biter"}
```

or if you want a custom hostile set:

```lua
units = {"small-worm-turret", "medium-worm-turret", "big-worm-turret"}
```

If the goal is exactly “hostile territory like Vulcanus,” use the existing enemy families already supported by your mod or by base vanilla.

---

### 3. Add a territory-expression block

This is the core of the system. Reproduce the Vulcanus pattern with custom names such as:

```lua
local territory_radius = 384

local expressions =
{
  {
    type = "noise-expression",
    name = "hostile_territory_radius",
    expression = 384
  },
  {
    type = "noise-expression",
    name = "hostile_territory_expression",
    expression = "voronoi_cell_id{x = x + 1000 * hostile_territory_radius,\
                                  y = y + 1000 * hostile_territory_radius,\
                                  seed0 = map_seed,\
                                  seed1 = 0,\
                                  grid_size = hostile_territory_radius,\
                                  distance_type = 'manhattan',\
                                  jitter = 1} - hostile_starting_area"
  },
  {
    type = "noise-expression",
    name = "hostile_starting_area",
    expression = "0 < starting_spot_at_angle{angle = 0,\
                                              distance = 100 * 32 + 32,\
                                              radius = 7 * 32,\
                                              x_distortion = 0,\
                                              y_distortion = 0}"
  },
  {
    type = "noise-expression",
    name = "hostile_territory_variation",
    expression = "floor(clamp(distance / (18 * 32) - 0.25, 0, 4)) + (-99 * no_enemies_mode)"
  }
}
```

This mirrors the Vulcanus pattern closely:

- `territory_radius` defines the region size
- `territory_expression` divides the map into Voronoi cells
- `starting_area` excludes the spawn region
- `variation_expression` distinguishes small / medium / big territories

Use the exact same logic style as the game files, because the engine expects the expression names and structure to match the territory system.

---

### 4. Add the territory settings to the Nauvis map generation table

Once your noise expressions exist, attach them to the Nauvis planet config.

Pseudo-structure:

```lua
local map_gen = require("__base__/prototypes/planet/planet-map-gen")
local nauvis = map_gen.nauvis()

nauvis.territory_settings =
{
  units = {"small-biter", "medium-biter", "big-biter"},
  territory_index_expression = "hostile_territory_expression",
  territory_variation_expression = "hostile_territory_variation",
  minimum_territory_size = 10
}
```

This is the central change that makes the map generator treat Nauvis as a territory-bearing world.

---

### 5. Choose the right unit pool for Nauvis

Your `units` value should be selected carefully.

Recommended order:

- `small-biter`, `medium-biter`, `big-biter`

or a custom unit list if you want a more interesting monster set.

Do not pick units that are not established on Nauvis unless you are also defining them as valid enemy entities and ensuring they are created in the right conditions.

---

### 6. Decide whether you want spawn exclusion near the starting area

The Vulcanus example excludes an area around the start position using `hostile_starting_area`.

For Nauvis, decide whether to:

- exclude all start-area territories, or
- keep a few small territories nearby, or
- create a larger no-enemy margin

Recommended default:

- keep the starting area free of territories
- leave a buffer so the player gets a clean opening

---

### 7. Add the no-enemies mode / disable rule

The Vulcanus variation expression includes:

```lua
+ (-99 * no_enemies_mode)
```

This is important because it disables the territory effect when the map is configured to have no enemies.

Re-use the same pattern so your territories automatically disappear when no-enemy mode is active.

---

### 8. Validate the data order

This is extremely important. In Factorio data stage, ordering matters.

Ensure the following happens in the correct sequence:

1. define custom noise expressions
2. patch the Nauvis map-gen object
3. make sure the unit names are valid in the game data
4. verify the expression names are referenced exactly by `territory_settings`

If the name strings do not match, the territory system will silently fail or produce no new territories.

---

### 9. Test in the game

After implementing the mod, test with a fresh map:

1. Start a new game on Nauvis.
2. Zoom out and look for large enemy territory clusters.
3. Check whether the territories are centered away from spawn.
4. Confirm the territories spawn smaller and larger enemies as intended.
5. Check the `no_enemies_mode` behavior.
6. Verify performance is acceptable on large maps.

---

### 10. Debugging checklist

If territory generation does not work, check these items:

- Are the expression names exactly the same in the `territory_settings` block?
- Did you attach the expressions to the right planet object?
- Are the unit names valid and actually present in the game?
- Is `minimum_territory_size` too high so that no territories appear?
- Is the starting-area exclusion too large and effectively hiding the whole map?
- Did you forget the `no_enemies_mode` adjustment?
- Did the data stage run before the enemy prototypes were loaded?

---

## Recommended minimal implementation skeleton

Use this as the starting point for a real mod file:

```lua
local planet_map_gen = require("__base__/prototypes/planet/planet-map-gen")

local nauvis = planet_map_gen.nauvis()

-- territory noise expressions
local territory_expressions =
{
  {
    type = "noise-expression",
    name = "hostile_territory_radius",
    expression = 384
  },
  {
    type = "noise-expression",
    name = "hostile_territory_expression",
    expression = "voronoi_cell_id{x = x + 1000 * hostile_territory_radius,\
                                  y = y + 1000 * hostile_territory_radius,\
                                  seed0 = map_seed,\
                                  seed1 = 0,\
                                  grid_size = hostile_territory_radius,\
                                  distance_type = 'manhattan',\
                                  jitter = 1} - hostile_starting_area"
  },
  {
    type = "noise-expression",
    name = "hostile_starting_area",
    expression = "0 < starting_spot_at_angle{angle = 0,\
                                              distance = 100 * 32 + 32,\
                                              radius = 7 * 32,\
                                              x_distortion = 0,\
                                              y_distortion = 0}"
  },
  {
    type = "noise-expression",
    name = "hostile_territory_variation",
    expression = "floor(clamp(distance / (18 * 32) - 0.25, 0, 4)) + (-99 * no_enemies_mode)"
  }
}

-- register expressions
for _, expr in ipairs(territory_expressions) do
  data:extend({expr})
end

-- patch Nauvis
nauvis.territory_settings =
{
  units = {"small-biter", "medium-biter", "big-biter"},
  territory_index_expression = "hostile_territory_expression",
  territory_variation_expression = "hostile_territory_variation",
  minimum_territory_size = 10
}

-- if you need a custom planet object or a data override, apply it here
```

This is a working design pattern, not a locked-in final implementation.

---

## Practical notes for this mod

Because you are working in a custom mod, the most stable route is:

- keep the territory logic in a dedicated file
- avoid editing vanilla files directly
- patch the map generation data in a data-stage file
- test on a fresh save so you can verify the territory pattern from a clean start

If you want a more custom effect, you can later add:

- different territory colors or region shapes
- different unit sets by biome
- different sizes for early-game vs late-game territory zones
- custom exclusions beyond the starting area

---

## Recommended next action

Implement in this order:

1. Create `prototypes/planet/nauvis-territory.lua`
2. Add the four noise expressions
3. Patch `nauvis.territory_settings`
4. Pick a simple unit pool (`small-biter`, `medium-biter`, `big-biter`)
5. Spawn a new game on Nauvis and verify visually
6. Tune the radius and variation values until the territory layout matches the desired density

---

## Summary

The Vulcanus implementation is not a direct `create_territory()` call in Lua; it is a data-driven territory system built around noise expressions and planet map configuration.

For Nauvis, the correct strategy is to mirror that pattern by:

- adding custom noise expressions,
- assigning `territory_settings` to the Nauvis planet,
- selecting an enemy unit set,
- and verifying the result on a fresh map.

This is the cleanest and most maintainable way to bring Vulcanus-like territory generation to Nauvis.
