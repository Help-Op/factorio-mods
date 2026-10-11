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
    name = "hostile_starting_area_radius",
    expression = 384 -- tiles around each starting position kept free of demolishers
  },
  {
    type = "noise-expression",
    name = "hostile_territory_expression",
    -- voronoi_cell_id is in [0, 1); the starting area is carved out as its own territory with index -1
    expression = "voronoi_cell_id{x = x + 1000 * hostile_territory_radius,\
                                  y = y + 1000 * hostile_territory_radius,\
                                  seed0 = map_seed,\
                                  seed1 = 0,\
                                  grid_size = hostile_territory_radius,\
                                  distance_type = 'manhattan',\
                                  jitter = 1} * (1 - hostile_starting_area) - hostile_starting_area"
  },
  {
    type = "noise-expression",
    name = "hostile_starting_area",
    expression = "distance < hostile_starting_area_radius"
  },
  {
    type = "noise-expression",
    name = "hostile_territory_variation",
    -- index into `units` (0 = small, 1 = medium, 2 = big), stepping up every 576 tiles from 720 tiles out;
    -- negative means no demolisher: used for the starting-area territory and no-enemies mode
    expression = "floor(clamp(distance / (18 * 32) - 0.25, 0, 2)) + (-99 * no_enemies_mode) + (-99 * hostile_starting_area)"
  }
}

for _, expr in ipairs(territory_expressions) do
  data:extend({expr})
end

-- enable territory settings on the existing Nauvis prototype
-- (units must be segmented-unit prototypes, so this needs Space Age's demolishers)
data.raw.planet.nauvis.map_gen_settings.territory_settings =
{
  units = {"small-demolisher", "medium-demolisher", "big-demolisher"},
  territory_index_expression = "hostile_territory_expression",
  territory_variation_expression = "hostile_territory_variation",
  minimum_territory_size = 10
}
