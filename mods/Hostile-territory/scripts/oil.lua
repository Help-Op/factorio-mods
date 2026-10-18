-- Guaranteed oil in ring 1 (ring-layout-plan.md R1-3, RL-D3). Map gen keeps crude oil out of ring 0 and the safe zone
-- (nauvis-territory.lua), so one patch is placed by script in the ring-1 territory whose point (brain) is closest to
-- the map origin: WELLS wells around a spot SPOT_DISTANCE tiles from that point, in the same territory. The spot is
-- picked from the noise once (works before the chunks exist): in the same territory and on land (elevation, as in
-- patrol.lua; water is elevation < 0), else the next direction or the next ring-1 territory. The wells are created
-- when the spot's chunk is generated (or right away if it already is).
-- storage.oil = {spot = {x, y} or nil, done = bool}

local territories = require("scripts.territories")

local oil = {}

local G = 384               -- grid cell, tiles (nauvis-territory.lua)
local SPOT_DISTANCE = 45    -- from the brain: outside its base (radius 25)
local WELLS = 6
local WELL_SPREAD = 9       -- tiles around the spot
local AMOUNT = 450000       -- per well (300000 = 100 % yield)
local LAND = 2              -- elevation the spot and the patch's corners need (water is < 0)

local function layer(i) return i >= 0 and i or -i - 1 end

-- Points of the ring-1 cells (the 12 around the 4 at the origin), closest to the origin first.
local function ring1_points(surface)
  local positions = {}
  for i = -2, 1 do
    for j = -2, 1 do
      if math.max(layer(i), layer(j)) == 1 then positions[#positions + 1] = {(i + 0.5) * G, (j + 0.5) * G} end
    end
  end
  local p = surface.calculate_tile_properties({"hostile_point_own_x", "hostile_point_own_y"}, positions)
  local points = {}
  for k = 1, #positions do
    points[k] = {x = p.hostile_point_own_x[k], y = p.hostile_point_own_y[k]}
  end
  table.sort(points, function(a, b) return a.x * a.x + a.y * a.y < b.x * b.x + b.y * b.y end)
  return points
end

-- A spot SPOT_DISTANCE from the point whose nearest territory point is still that point, with land under the spot
-- and the patch's 4 corners (8 directions, outward first). nil if none fits.
local function pick_spot(surface, point)
  local outward = math.atan2(point.y, point.x)
  local candidates = {}
  for k = 0, 7 do
    local a = outward + (k % 2 == 0 and 1 or -1) * math.ceil(k / 2) * math.pi / 4
    candidates[#candidates + 1] = {point.x + math.cos(a) * SPOT_DISTANCE, point.y + math.sin(a) * SPOT_DISTANCE}
  end
  local p = surface.calculate_tile_properties({"hostile_point_nearest_x", "hostile_point_nearest_y"}, candidates)
  for k, c in ipairs(candidates) do
    if p.hostile_point_nearest_x[k] == point.x and p.hostile_point_nearest_y[k] == point.y then
      local area = {c}
      for _, o in pairs({{-1, -1}, {-1, 1}, {1, -1}, {1, 1}}) do
        area[#area + 1] = {c[1] + o[1] * WELL_SPREAD, c[2] + o[2] * WELL_SPREAD}
      end
      local land = true
      for _, e in pairs(surface.calculate_tile_properties({"elevation"}, area).elevation) do
        if e < LAND then land = false end
      end
      if land then return {x = math.floor(c[1]), y = math.floor(c[2])} end
    end
  end
  return nil
end

local function place(surface)
  local spot = storage.oil.spot
  local placed = 0
  for _ = 1, WELLS * 4 do
    if placed == WELLS then break end
    local wanted = {spot.x + (math.random() * 2 - 1) * WELL_SPREAD, spot.y + (math.random() * 2 - 1) * WELL_SPREAD}
    local position = surface.find_non_colliding_position("crude-oil", wanted, WELL_SPREAD, 1, true)
    if position and not surface.get_tile(math.floor(position.x), math.floor(position.y)).collides_with("water_tile") then
      surface.create_entity{name = "crude-oil", position = position, amount = AMOUNT}
      placed = placed + 1
    end
  end
  storage.oil.done = true
  storage.oil.placed = placed
end

function oil.init()
  if storage.oil then return end
  storage.oil = {done = false}
  local surface = game.surfaces[territories.surface_name]
  if not surface then return end
  for _, point in ipairs(ring1_points(surface)) do
    local spot = pick_spot(surface, point)
    if spot then
      storage.oil.spot = spot
      break
    end
  end
  if not storage.oil.spot then return end
  local chunk = {x = math.floor(storage.oil.spot.x / 32), y = math.floor(storage.oil.spot.y / 32)}
  if surface.is_chunk_generated(chunk) then place(surface) end
end

function oil.on_chunk_generated(event)
  local state = storage.oil
  if not (state and state.spot and not state.done) or event.surface.name ~= territories.surface_name then return end
  if math.floor(state.spot.x / 32) == event.position.x and math.floor(state.spot.y / 32) == event.position.y then
    place(event.surface)
  end
end

function oil.describe()
  local state = storage.oil
  if not (state and state.spot) then return "No guaranteed oil spot." end
  return string.format("Guaranteed oil at [gps=%d,%d]: %s.", state.spot.x, state.spot.y,
    state.done and ((state.placed or 0) .. " wells placed") or "waiting for its chunk")
end

return oil
