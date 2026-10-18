-- Brain bases (territory-brain-plan.md B2, tested as L3/L4 in hive-layout-plan.md): one base per territory,
-- built by map gen around the territory's point (hostile_point_*, nauvis-territory.lua). The brain itself is the
-- territory's segmented unit; scripts/brain.lua moves it onto the centre (B3), so the centre tile stays free.
-- Layout (B-D4): worm core (1-4 worms by distance on 4 slots at CORE_R around the brain), ring of 6-10 nests at RING_R,
-- biter and spitter spawners alternating, worm tier by distance, random rotation per base.
-- Every enemy autoplace is turned off first (B-D2): only this layout places nests and worms on Nauvis.
-- Loaded from data-final-fixes.lua, so nests added by other mods are turned off too.
-- Noise gotcha: always put comparisons in parentheses (`a * b < c` is `(a * b) < c`).

local G = 384             -- same grid as nauvis-territory.lua
local FAR = 2400          -- distance where ring size and core size max out
local RING_R = 18
local CORE_R = 6
local TWO_PI = 2 * math.pi

local cell_centre_x = string.format("((floor(x / %d) + 0.5) * %d)", G, G)
local cell_centre_y = string.format("((floor(y / %d) + 0.5) * %d)", G, G)

local expressions =
{
  hostile_base_dx = "floor(x) - hostile_point_own_x",
  hostile_base_dy = "floor(y) - hostile_point_own_y",
  hostile_base_distance = "sqrt(hostile_point_own_x * hostile_point_own_x + hostile_point_own_y * hostile_point_own_y)",
  -- 0 up to hostile_point_start_radius (420), 1 at FAR and beyond
  hostile_base_far = string.format(
    "clamp((hostile_base_distance - hostile_point_start_radius) / (%d - hostile_point_start_radius), 0, 1)", FAR),
  -- every point is outside the safe zone since E2 (pushed out, nauvis-territory.lua), so every cell has a base
  hostile_base_exists = "1 - no_enemies_mode",
  hostile_base_rotation = string.format(
    "voronoi_cell_id{x = %s, y = %s, seed0 = map_seed, seed1 = 104, grid_size = %d, distance_type = 'chebyshev', jitter = 0} * %g",
    cell_centre_x, cell_centre_y, G, TWO_PI),
  hostile_base_angle = "atan2(hostile_base_dy, hostile_base_dx) - hostile_base_rotation",
  -- ring: each tile checks whether it is its nearest slot's tile
  hostile_base_ring_n = "6 + floor(4 * hostile_base_far + 0.5)",
  hostile_base_ring_slot = string.format("floor(hostile_base_angle * hostile_base_ring_n / %g + 0.5)", TWO_PI),
  hostile_base_ring_a = string.format("hostile_base_ring_slot * %g / hostile_base_ring_n + hostile_base_rotation", TWO_PI),
  hostile_base_ring_hit = string.format(
    "(hostile_base_dx == floor(%d * cos(hostile_base_ring_a) + 0.5))\
      * (hostile_base_dy == floor(%d * sin(hostile_base_ring_a) + 0.5)) * hostile_base_exists",
    RING_R, RING_R),
  hostile_base_ring_odd = "(hostile_base_ring_slot + 100) % 2",
  -- core: 4 fixed slots at CORE_R around the brain, the first 1 + M used (1 near spawn, 4 far out)
  hostile_base_core_m = "floor(3 * hostile_base_far + 0.5)",
  hostile_base_core_slot = string.format("floor(hostile_base_angle * 4 / %g + 0.5)", TWO_PI),
  hostile_base_core_a = string.format("hostile_base_core_slot * %g / 4 + hostile_base_rotation", TWO_PI),
  hostile_base_core_hit = string.format(
    "(hostile_base_dx == floor(%d * cos(hostile_base_core_a) + 0.5))\
      * (hostile_base_dy == floor(%d * sin(hostile_base_core_a) + 0.5))\
      * (((hostile_base_core_slot + 100) %% 4) < (1 + hostile_base_core_m)) * hostile_base_exists",
    CORE_R, CORE_R),
}

for name, expression in pairs(expressions) do
  data:extend({{type = "noise-expression", name = name, expression = expression}})
end

-- every enemy autoplace off
for _, t in pairs({"unit-spawner", "turret"}) do
  for _, e in pairs(data.raw[t]) do e.autoplace = nil end
end

-- order "!" places before trees (L1), so trees don't block the layout
local function autoplace(order, probability)
  return {control = "enemy-base", force = "enemy", order = order, probability_expression = probability}
end

-- worm tier by base distance
local worms =
{
  {"small-worm-turret", "hostile_base_distance < 700"},
  {"medium-worm-turret", "(hostile_base_distance >= 700) * (hostile_base_distance < 1400)"},
  {"big-worm-turret", "(hostile_base_distance >= 1400) * (hostile_base_distance < 2400)"},
  {"behemoth-worm-turret", "hostile_base_distance >= 2400"},
}
for i, w in pairs(worms) do
  data.raw.turret[w[1]].autoplace = autoplace("!a" .. i, "hostile_base_core_hit * (" .. w[2] .. ")")
end

data.raw["unit-spawner"]["biter-spawner"].autoplace = autoplace("!b1", "hostile_base_ring_hit * (1 - hostile_base_ring_odd)")
data.raw["unit-spawner"]["spitter-spawner"].autoplace = autoplace("!b2", "hostile_base_ring_hit * hostile_base_ring_odd")
