local planet_map_gen = require("__base__/prototypes/planet/planet-map-gen")

local nauvis = planet_map_gen.nauvis()

-- territory noise expressions (mirror Vulcanus pattern)
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

for _, expr in ipairs(territory_expressions) do
  data:extend({expr})
end

-- enable territory settings on Nauvis
nauvis.territory_settings =
{
  -- using vanilla biters for testing (no Space Age dependency)
  units = {"small-biter", "medium-biter", "big-biter"},
  territory_index_expression = "hostile_territory_expression",
  territory_variation_expression = "hostile_territory_variation",
  minimum_territory_size = 10
}

-- overwrite the nauvis function result in the planet map gen table
local planet_map_gen_module = require("__base__/prototypes/planet/planet-map-gen")
planet_map_gen_module.nauvis = function() return nauvis end
