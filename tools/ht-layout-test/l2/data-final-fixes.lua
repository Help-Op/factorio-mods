-- L2: one medium worm at the centre of every Hostile Territory territory.
-- Same input, seed, grid and jitter as hostile_territory_expression (nauvis-territory.lua),
-- but voronoi_spot_noise (distance to the cell's point) instead of voronoi_cell_id.

-- all other enemy autoplace off, so only our worms appear
for _, t in pairs({"unit-spawner", "turret"}) do
  for _, e in pairs(data.raw[t]) do e.autoplace = nil end
end

data.raw.turret["medium-worm-turret"].autoplace =
{
  control = "enemy-base",
  force = "enemy",
  order = "!a",
  probability_expression = "(ht_test_centre_distance < 1) * (1 - hostile_starting_area)"
}

-- named, so control.lua can read it with calculate_tile_properties
data:extend({{
  type = "noise-expression",
  name = "ht_test_centre_distance",
  expression = "voronoi_spot_noise{x = x + 1000 * hostile_territory_radius,                                   y = y + 1000 * hostile_territory_radius,                                   seed0 = map_seed,                                   seed1 = 0,                                   grid_size = hostile_territory_radius,                                   distance_type = 'euclidean',                                   jitter = 1} * hostile_territory_radius"
}})
