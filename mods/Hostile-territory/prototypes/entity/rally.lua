-- Crusade rally (phase H): the structure a crusade army builds on the target's patrol path.
-- One per guardian size. Stats are copied plainly from the guardian (Hostile-fauna brain, territory-brain-plan.md B1), max_health × 0.75.
-- healing_per_tick = 0: on 2.0 simple-entity-with-force didn't heal (H0), on 2.1 it does (2026-10-15), and the rally must not regen (H-6).
-- Placeholder look: a white square, 6×6 tiles (white-square.png is 10×10 px: 10 × 19.2 = 192 px = 6 tiles).

local SIZES = {"small", "medium", "big", "ring1"} -- ring1: oil-ring-challenge-plan.md OR-D4

for _, size in pairs(SIZES) do
  local guardian = data.raw["segmented-unit"]["hf-brain-" .. size]
  data:extend({{
    type = "simple-entity-with-force",
    name = "ht-rally-" .. size,
    localised_name = {"entity-name.ht-rally", {"entity-name.hf-brain-" .. size}},
    icon = "__core__/graphics/white-square.png",
    icon_size = 10,
    flags = {"placeable-enemy", "placeable-off-grid", "not-repairable"},
    order = "s-z-" .. size,
    subgroup = "enemies",
    max_health = guardian.max_health * 0.75,
    healing_per_tick = 0,
    resistances = table.deepcopy(guardian.resistances),
    is_military_target = true,
    collision_box = {{-2.9, -2.9}, {2.9, 2.9}},
    selection_box = {{-3, -3}, {3, 3}},
    map_color = {1, 1, 1},
    picture = {filename = "__core__/graphics/white-square.png", size = 10, scale = 19.2},
    render_layer = "object",
  }})
end
