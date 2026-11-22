-- Brain bases (territory-brain-plan.md B2, tested as L3/L4 in hive-layout-plan.md): one base per territory,
-- built by map gen around the territory's point (hostile_point_*, nauvis-territory.lua). The brain itself is the
-- territory's segmented unit; scripts/brain.lua moves it onto the centre (B3), so the centre tile stays free.
-- Layout (B-D4): ring of 6-10 nests at RING_R, biter and spitter spawners alternating, random rotation per base.
-- No worms (OR-D105 for rings 0-1, ring2-challenge-plan.md R2-D8 / D14 for ring 2+): the hostile_base_core_* slots
-- below are no longer placed (tools/ht-map-check still reads them). Ring 1 bases also get ANCHOR_N anchor nests
-- (biter spawners) at ANCHOR_R (oil-ring-challenge-plan.md OR-E8, OR-D66); ring 2+ gets districts instead (R2-D22).
-- Every enemy autoplace is turned off first (B-D2): only this layout places nests and worms on Nauvis.
-- Loaded from data-final-fixes.lua, so nests added by other mods are turned off too.
-- Noise gotcha: always put comparisons in parentheses (`a * b < c` is `(a * b) < c`).

local G = 384             -- same grid as nauvis-territory.lua
local FAR = 2400          -- distance where ring size and core size max out
local RING_R = 18
local CORE_R = 6
local ANCHOR_R = 32       -- + nest half-size stays inside the 38-tile cell margin (nauvis-territory.lua)
local ANCHOR_N = 4
local TWO_PI = 2 * math.pi
local ANCHOR_TURN = TWO_PI / 8

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
  -- anchor ring (oil-ring-challenge-plan.md OR-D66): ring 1 bases only (ring 2+: districts, R2-D22), ANCHOR_N nests at ANCHOR_R, ANCHOR_TURN off the
  -- base rotation. They shield the brain in its fight (scripts/brain-fight.lua)
  hostile_base_anchor_slot = string.format("floor((hostile_base_angle - %g) * %d / %g + 0.5)", ANCHOR_TURN, ANCHOR_N, TWO_PI),
  hostile_base_anchor_a = string.format("hostile_base_anchor_slot * %g / %d + hostile_base_rotation + %g",
    TWO_PI, ANCHOR_N, ANCHOR_TURN),
  hostile_base_anchor_hit = string.format(
    "(hostile_base_dx == floor(%d * cos(hostile_base_anchor_a) + 0.5))\
      * (hostile_base_dy == floor(%d * sin(hostile_base_anchor_a) + 0.5))\
      * (hostile_point_ring == 1) * hostile_base_exists",
    ANCHOR_R, ANCHOR_R),
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

-- no worms anywhere (OR-D105, PT18: worms took 164 HP in 15 s; R2-D8: they stop you moving): their autoplace stays off
data.raw["unit-spawner"]["biter-spawner"].autoplace = autoplace("!b1",
  "hostile_base_ring_hit * (1 - hostile_base_ring_odd) + hostile_base_anchor_hit")
data.raw["unit-spawner"]["spitter-spawner"].autoplace = autoplace("!b2", "hostile_base_ring_hit * hostile_base_ring_odd")
