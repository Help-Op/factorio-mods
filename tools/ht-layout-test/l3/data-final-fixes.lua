-- L3: every enemy base is a worm core with a ring of nests (hive-layout-plan.md).
-- Bases sit on a grid without jitter, so map gen knows each base's exact centre
-- and can compute every tile's offset from it.

local G = 192            -- grid cell, tiles
local OFFSET = 0.5       -- centre moves up to ±OFFSET/2 of a cell
local START = 420        -- no base centre closer to spawn (384 + margin)
local FAR = 2400         -- distance where density, ring size and core size max out
local RING_R = 18
local CORE_R = 6
local TWO_PI = 2 * math.pi

-- random value per cell, constant over the whole cell
local function cell_random(seed1)
  return string.format(
    "voronoi_cell_id{x = ht_l3_ccx, y = ht_l3_ccy, seed0 = map_seed, seed1 = %d, grid_size = %d, distance_type = 'chebyshev', jitter = 0}",
    seed1, G)
end

local expressions =
{
  ht_l3_ccx = string.format("(floor(x / %d) + 0.5) * %d", G, G),
  ht_l3_ccy = string.format("(floor(y / %d) + 0.5) * %d", G, G),
  ht_l3_r1 = cell_random(101),
  ht_l3_r2 = cell_random(102),
  ht_l3_r3 = cell_random(103),
  ht_l3_r4 = cell_random(104),
  -- exact base centre (a tile)
  ht_l3_cx = string.format("floor(ht_l3_ccx + (ht_l3_r2 - 0.5) * %g * %d)", OFFSET, G),
  ht_l3_cy = string.format("floor(ht_l3_ccy + (ht_l3_r3 - 0.5) * %g * %d)", OFFSET, G),
  ht_l3_dx = "floor(x) - ht_l3_cx",
  ht_l3_dy = "floor(y) - ht_l3_cy",
  ht_l3_base_distance = "sqrt(ht_l3_cx * ht_l3_cx + ht_l3_cy * ht_l3_cy)",
  -- 0 near spawn, 1 at FAR and beyond
  ht_l3_far = string.format("clamp((ht_l3_base_distance - %d) / %d, 0, 1)", START, FAR - START),
  ht_l3_has_base = string.format("(ht_l3_r1 < 0.5 + 0.3 * ht_l3_far) * (ht_l3_base_distance > %d)", START),
  ht_l3_rotation = string.format("ht_l3_r4 * %g", TWO_PI),
  ht_l3_angle = "atan2(ht_l3_dy, ht_l3_dx) - ht_l3_rotation",
  -- ring: N slots, each tile checks whether it is its nearest slot's tile
  ht_l3_ring_n = "6 + floor(4 * ht_l3_far + 0.5)",
  ht_l3_ring_slot = string.format("floor(ht_l3_angle * ht_l3_ring_n / %g + 0.5)", TWO_PI),
  ht_l3_ring_a = string.format("ht_l3_ring_slot * %g / ht_l3_ring_n + ht_l3_rotation", TWO_PI),
  ht_l3_ring_hit = string.format(
    "(ht_l3_dx == floor(%d * cos(ht_l3_ring_a) + 0.5)) * (ht_l3_dy == floor(%d * sin(ht_l3_ring_a) + 0.5)) * ht_l3_has_base",
    RING_R, RING_R),
  ht_l3_ring_odd = "(ht_l3_ring_slot + 100) % 2",
  -- core: centre worm plus up to 3 worms at CORE_R (3 fixed slots, the first M used)
  ht_l3_core_m = "floor(3 * ht_l3_far + 0.5)",
  ht_l3_core_slot = string.format("floor(ht_l3_angle * 3 / %g + 0.5)", TWO_PI),
  ht_l3_core_a = string.format("ht_l3_core_slot * %g / 3 + ht_l3_rotation", TWO_PI),
  ht_l3_core_hit = string.format(
    "((ht_l3_dx == 0) * (ht_l3_dy == 0)\
      + (ht_l3_dx == floor(%d * cos(ht_l3_core_a) + 0.5)) * (ht_l3_dy == floor(%d * sin(ht_l3_core_a) + 0.5))\
        * (((ht_l3_core_slot + 99) %% 3) < ht_l3_core_m)) * ht_l3_has_base",
    CORE_R, CORE_R),
}

for name, expression in pairs(expressions) do
  data:extend({{type = "noise-expression", name = name, expression = expression}})
end

-- vanilla (and any other) enemy autoplace off: only our pattern places enemies
for _, t in pairs({"unit-spawner", "turret"}) do
  for _, e in pairs(data.raw[t]) do e.autoplace = nil end
end

local function autoplace(order, probability)
  return {control = "enemy-base", force = "enemy", order = order, probability_expression = probability}
end

-- worm tier by base distance
local worms =
{
  {"small-worm-turret", "ht_l3_base_distance < 700"},
  {"medium-worm-turret", "(ht_l3_base_distance >= 700) * (ht_l3_base_distance < 1400)"},
  {"big-worm-turret", "(ht_l3_base_distance >= 1400) * (ht_l3_base_distance < 2400)"},
  {"behemoth-worm-turret", "ht_l3_base_distance >= 2400"},
}
for i, w in pairs(worms) do
  data.raw.turret[w[1]].autoplace = autoplace("!a" .. i, "ht_l3_core_hit * (" .. w[2] .. ")")
end

-- biter and spitter spawners alternate around the ring
data.raw["unit-spawner"]["biter-spawner"].autoplace = autoplace("!b1", "ht_l3_ring_hit * (1 - ht_l3_ring_odd)")
data.raw["unit-spawner"]["spitter-spawner"].autoplace = autoplace("!b2", "ht_l3_ring_hit * ht_l3_ring_odd")
