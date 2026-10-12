-- Crusade rally (phase H): the structure a crusade army builds on the target's patrol path.
-- One per guardian size. Stats are copied plainly from the demolisher, max_health × 0.75.
-- healing_per_tick is copied too, but simple-entity-with-force doesn't heal (tested H0).
-- Placeholder look: a white square, 6×6 tiles (white-square.png is 10×10 px: 10 × 19.2 = 192 px = 6 tiles).

local SIZES = {"small", "medium", "big"}

for _, size in pairs(SIZES) do
  local guardian = data.raw["segmented-unit"][size .. "-demolisher"]
  data:extend({{
    type = "simple-entity-with-force",
    name = "ht-rally-" .. size,
    localised_name = {"entity-name.ht-rally", {"entity-name." .. size .. "-demolisher"}},
    icon = "__core__/graphics/white-square.png",
    icon_size = 10,
    flags = {"placeable-enemy", "placeable-off-grid", "not-repairable"},
    order = "s-z-" .. size,
    subgroup = "enemies",
    max_health = guardian.max_health * 0.75,
    healing_per_tick = guardian.healing_per_tick,
    resistances = table.deepcopy(guardian.resistances),
    is_military_target = true,
    collision_box = {{-2.9, -2.9}, {2.9, 2.9}},
    selection_box = {{-3, -3}, {3, 3}},
    map_color = {1, 1, 1},
    picture = {filename = "__core__/graphics/white-square.png", size = 10, scale = 19.2},
    render_layer = "object",
  }})
end
