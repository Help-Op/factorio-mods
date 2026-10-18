-- Territories on Nauvis (territory-mapgen-plan.md), built from our own points (territory-brain-plan.md B2,
-- tested as L4 in hive-layout-plan.md).
-- One point per grid cell of G tiles, moved inside the cell by per-cell random values. The offset is capped at
-- ±J * G / 2, so every point keeps (1 - J) * G / 2 tiles (38 for G = 384, J = 0.8) from its cell edge.
-- Territory index (per chunk) = id of the nearest point (Manhattan) among the 3x3 surrounding cells.
-- Map gen can compute every point exactly, so brain-bases.lua builds each territory's base around its point.
-- Point names: hostile_point_* (shared with brain-bases.lua and scripts).

local G = 384             -- grid cell, tiles
local J = 0.8             -- point offset: up to ±J * G / 2 inside the cell
local POINT_START = 420   -- points closer to spawn join the starting area (384 + margin for the base)

local expressions = {}
local function def(name, expression) expressions[name] = expression end

def("hostile_territory_radius", G)
def("hostile_starting_area_radius", 384) -- tiles around each starting position kept free of territories
def("hostile_starting_area", "distance < hostile_starting_area_radius")

-- random value per cell, evaluated at the cell centre so it's constant over the cell
local function cell_random(ccx, ccy, seed1)
  return string.format(
    "voronoi_cell_id{x = %s, y = %s, seed0 = map_seed, seed1 = %d, grid_size = %d, distance_type = 'chebyshev', jitter = 0}",
    ccx, ccy, seed1, G)
end

-- point and id of the cell (floor(x / G) + di, floor(y / G) + dj)
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

-- 9-way nearest point, as a chain of named expressions (k = 5 is the tile's own cell)
local k = 0
for di = -1, 1 do
  for dj = -1, 1 do
    k = k + 1
    local px, py, id = point(di, dj)
    def("hostile_point_x" .. k, px)
    def("hostile_point_y" .. k, py)
    def("hostile_point_id" .. k, id)
    def("hostile_point_d" .. k, string.format("abs(x - hostile_point_x%d) + abs(y - hostile_point_y%d)", k, k))
    if k == 1 then
      def("hostile_point_best_d1", "hostile_point_d1")
      def("hostile_point_best_x1", "hostile_point_x1")
      def("hostile_point_best_y1", "hostile_point_y1")
      def("hostile_point_best_id1", "hostile_point_id1")
    else
      local closer = string.format("hostile_point_d%d < hostile_point_best_d%d", k, k - 1)
      def("hostile_point_best_d" .. k, string.format("min(hostile_point_d%d, hostile_point_best_d%d)", k, k - 1))
      def("hostile_point_best_x" .. k, string.format("if(%s, hostile_point_x%d, hostile_point_best_x%d)", closer, k, k - 1))
      def("hostile_point_best_y" .. k, string.format("if(%s, hostile_point_y%d, hostile_point_best_y%d)", closer, k, k - 1))
      def("hostile_point_best_id" .. k, string.format("if(%s, hostile_point_id%d, hostile_point_best_id%d)", closer, k, k - 1))
    end
  end
end

-- the nearest point = the territory's point (all chunks of a territory share it)
def("hostile_point_nearest_x", "hostile_point_best_x9")
def("hostile_point_nearest_y", "hostile_point_best_y9")
def("hostile_point_nearest_id", "hostile_point_best_id9")
def("hostile_point_start_radius", POINT_START)
def("hostile_point_near_start",
  "(hostile_point_nearest_x * hostile_point_nearest_x + hostile_point_nearest_y * hostile_point_nearest_y)\
    < (hostile_point_start_radius * hostile_point_start_radius)")
-- the tile's own cell point (where a base is built)
def("hostile_point_own_x", "hostile_point_x5")
def("hostile_point_own_y", "hostile_point_y5")

-- territory index: the starting area (by distance, and every chunk whose point is near spawn) is -1
def("hostile_territory_expression", "if((hostile_starting_area + hostile_point_near_start) > 0, -1, hostile_point_nearest_id)")

-- index into `units` (0 = small, 1 = medium, 2 = big), stepping up every 576 tiles from 720 tiles out;
-- negative means no brain: used for the starting-area territory and no-enemies mode
def("hostile_territory_variation",
  "floor(clamp(distance / (18 * 32) - 0.25, 0, 2)) + (-99 * no_enemies_mode) + (-99 * hostile_starting_area)")

for name, expression in pairs(expressions) do
  data:extend({{type = "noise-expression", name = name, expression = expression}})
end

-- enable territory settings on the existing Nauvis prototype
-- (units must be segmented-unit prototypes: the brains from Hostile-fauna, territory-brain-plan.md B-D1)
data.raw.planet.nauvis.map_gen_settings.territory_settings =
{
  units = {"hf-brain-small", "hf-brain-medium", "hf-brain-big"},
  territory_index_expression = "hostile_territory_expression",
  territory_variation_expression = "hostile_territory_variation",
  minimum_territory_size = 10
}
