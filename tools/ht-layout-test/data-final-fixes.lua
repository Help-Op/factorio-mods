-- L4: territories and bases from the same points (hive-layout-plan.md).
-- One point per grid cell, moved inside the cell by per-cell random values.
-- Territory index (per chunk) = id of the nearest point among the 3x3 surrounding cells.
-- Base (per tile) = L3 base around the tile's own cell point (the point keeps a margin
-- of (1 - J) * G / 2 from its cell edge, so a whole base lies in one cell).

local G = 384            -- grid cell, tiles (= hostile_territory_radius)
local J = 0.8            -- point offset: up to ±J * G / 2 inside the cell
local START = 420        -- points closer to spawn join the starting area
local FAR = 2400         -- distance where ring size and core size max out
local RING_R = 18
local CORE_R = 6
local TWO_PI = 2 * math.pi

local expressions = {}
local function def(name, expression) expressions[name] = expression end

-- random value per cell, evaluated at the cell centre so it's constant over the cell
local function cell_random(cx, cy, seed1)
  return string.format(
    "voronoi_cell_id{x = %s, y = %s, seed0 = map_seed, seed1 = %d, grid_size = %d, distance_type = 'chebyshev', jitter = 0}",
    cx, cy, seed1, G)
end

-- point of the cell (floor(x / G) + di, floor(y / G) + dj)
local function point(di, dj)
  local i = string.format("(floor(x / %d) + %d)", G, di)
  local j = string.format("(floor(y / %d) + %d)", G, dj)
  local ccx = string.format("((%s + 0.5) * %d)", i, G)
  local ccy = string.format("((%s + 0.5) * %d)", j, G)
  local px = string.format("floor(%s + (%s - 0.5) * %g * %d)", ccx, cell_random(ccx, ccy, 102), J, G)
  local py = string.format("floor(%s + (%s - 0.5) * %g * %d)", ccy, cell_random(ccx, ccy, 103), J, G)
  local id = string.format("((%s + 500) * 1000 + (%s + 500))", i, j)
  return px, py, id
end

-- 9-way nearest point (Manhattan), as a chain of named expressions
local k = 0
for di = -1, 1 do
  for dj = -1, 1 do
    k = k + 1
    local px, py, id = point(di, dj)
    def("ht_l4_px" .. k, px)
    def("ht_l4_py" .. k, py)
    def("ht_l4_id" .. k, id)
    def("ht_l4_d" .. k, string.format("abs(x - ht_l4_px%d) + abs(y - ht_l4_py%d)", k, k))
    if k == 1 then
      def("ht_l4_bd1", "ht_l4_d1")
      def("ht_l4_bx1", "ht_l4_px1")
      def("ht_l4_by1", "ht_l4_py1")
      def("ht_l4_bid1", "ht_l4_id1")
    else
      local closer = string.format("ht_l4_d%d < ht_l4_bd%d", k, k - 1)
      def("ht_l4_bd" .. k, string.format("min(ht_l4_d%d, ht_l4_bd%d)", k, k - 1))
      def("ht_l4_bx" .. k, string.format("if(%s, ht_l4_px%d, ht_l4_bx%d)", closer, k, k - 1))
      def("ht_l4_by" .. k, string.format("if(%s, ht_l4_py%d, ht_l4_by%d)", closer, k, k - 1))
      def("ht_l4_bid" .. k, string.format("if(%s, ht_l4_id%d, ht_l4_bid%d)", closer, k, k - 1))
    end
  end
end
-- nearest point and its territory id
def("ht_l4_nx", "ht_l4_bx9")
def("ht_l4_ny", "ht_l4_by9")
def("ht_l4_nid", "ht_l4_bid9")
def("ht_l4_near_start", string.format("(ht_l4_nx * ht_l4_nx + ht_l4_ny * ht_l4_ny) < %d", START * START))

-- own cell point (k = 5 is di = 0, dj = 0)
def("ht_l4_cx", "ht_l4_px5")
def("ht_l4_cy", "ht_l4_py5")

for name, expression in pairs(expressions) do
  data:extend({{type = "noise-expression", name = name, expression = expression}})
end

-- territories: replaces Hostile Territory's Voronoi expression (HT stays untouched)
-- starting area as before (distance), plus every chunk whose nearest point is near spawn
data.raw["noise-expression"]["hostile_territory_expression"].expression =
  "if((hostile_starting_area + ht_l4_near_start) > 0, -1, ht_l4_nid)"

-- base: L3 pattern around the tile's own cell point
local base =
{
  ht_l4_dx = "floor(x) - ht_l4_cx",
  ht_l4_dy = "floor(y) - ht_l4_cy",
  ht_l4_base_distance = "sqrt(ht_l4_cx * ht_l4_cx + ht_l4_cy * ht_l4_cy)",
  ht_l4_far = string.format("clamp((ht_l4_base_distance - %d) / %d, 0, 1)", START, FAR - START),
  ht_l4_has_base = string.format("ht_l4_base_distance >= %d", START),
  ht_l4_rotation = string.format("%s * %g",
    cell_random(string.format("((floor(x / %d) + 0.5) * %d)", G, G), string.format("((floor(y / %d) + 0.5) * %d)", G, G), 104), TWO_PI),
  ht_l4_angle = "atan2(ht_l4_dy, ht_l4_dx) - ht_l4_rotation",
  ht_l4_ring_n = "6 + floor(4 * ht_l4_far + 0.5)",
  ht_l4_ring_slot = string.format("floor(ht_l4_angle * ht_l4_ring_n / %g + 0.5)", TWO_PI),
  ht_l4_ring_a = string.format("ht_l4_ring_slot * %g / ht_l4_ring_n + ht_l4_rotation", TWO_PI),
  ht_l4_ring_hit = string.format(
    "(ht_l4_dx == floor(%d * cos(ht_l4_ring_a) + 0.5)) * (ht_l4_dy == floor(%d * sin(ht_l4_ring_a) + 0.5)) * ht_l4_has_base",
    RING_R, RING_R),
  ht_l4_ring_odd = "(ht_l4_ring_slot + 100) % 2",
  ht_l4_core_m = "floor(3 * ht_l4_far + 0.5)",
  ht_l4_core_slot = string.format("floor(ht_l4_angle * 3 / %g + 0.5)", TWO_PI),
  ht_l4_core_a = string.format("ht_l4_core_slot * %g / 3 + ht_l4_rotation", TWO_PI),
  ht_l4_core_hit = string.format(
    "((ht_l4_dx == 0) * (ht_l4_dy == 0)\
      + (ht_l4_dx == floor(%d * cos(ht_l4_core_a) + 0.5)) * (ht_l4_dy == floor(%d * sin(ht_l4_core_a) + 0.5))\
        * (((ht_l4_core_slot + 99) %% 3) < ht_l4_core_m)) * ht_l4_has_base",
    CORE_R, CORE_R),
}
for name, expression in pairs(base) do
  data:extend({{type = "noise-expression", name = name, expression = expression}})
end

-- vanilla (and any other) enemy autoplace off: only our pattern places enemies
for _, t in pairs({"unit-spawner", "turret"}) do
  for _, e in pairs(data.raw[t]) do e.autoplace = nil end
end

local function autoplace(order, probability)
  return {control = "enemy-base", force = "enemy", order = order, probability_expression = probability}
end

-- worm tier by base distance (comparisons in parentheses, see L3 precedence bug)
local worms =
{
  {"small-worm-turret", "ht_l4_base_distance < 700"},
  {"medium-worm-turret", "(ht_l4_base_distance >= 700) * (ht_l4_base_distance < 1400)"},
  {"big-worm-turret", "(ht_l4_base_distance >= 1400) * (ht_l4_base_distance < 2400)"},
  {"behemoth-worm-turret", "ht_l4_base_distance >= 2400"},
}
for i, w in pairs(worms) do
  data.raw.turret[w[1]].autoplace = autoplace("!a" .. i, "ht_l4_core_hit * (" .. w[2] .. ")")
end

data.raw["unit-spawner"]["biter-spawner"].autoplace = autoplace("!b1", "ht_l4_ring_hit * (1 - ht_l4_ring_odd)")
data.raw["unit-spawner"]["spitter-spawner"].autoplace = autoplace("!b2", "ht_l4_ring_hit * ht_l4_ring_odd")
