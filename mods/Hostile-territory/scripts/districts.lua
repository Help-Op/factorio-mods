-- Districts of ring-2+ bases (ring2-challenge-plan.md R2-E1 4c; R2-D2, D23, D24): SLOTS districts around the
-- brain, DISTANCE tiles out and 90° apart (turned by the base rotation), each a district heart (ht-district-heart)
-- in a ring of NESTS nests at NEST_R. Placed by script, since water decides where they fit (R2-D17):
--   brain.lua calls districts.plan once a ring-2+ brain stands on its base. Per slot, candidate spots (the slot's
--   angle ±15° / ±30°, DISTANCE ± up to 15) are checked from the noise: land (elevation >= LAND) under the heart
--   and 8 points on the district's rim, all in the brain's own territory. A slot with no fit is dropped (R2-D17:
--   fewer districts).
--   A planned district is built once its territory's chunks within REACH are generated, by normal exploration (map
--   gen runs ahead of the player): heart first, then the nests, trees and rocks in their way removed (as map gen
--   places bases before trees); cliffs too under a heart (every district needs its heart; a nest just skips them). Not requested: requesting them created new territories whose districts requested
--   more, a chain that never ended (headless 2026-10-25).
-- Regrowth (regrow.lua) treats district hearts and nests as more slots of the base (districts.slots).
-- Guaranteed uranium (R2-D18, D21, 4d): the URANIUM_TERRITORIES ring-2 territories whose points are closest to the
--   origin each get a uranium patch under their district closest to the origin (the one facing spawn): a disc of
--   URANIUM_RADIUS around the heart, URANIUM_AMOUNT in all (more in the middle), placed before the heart and nests.
--   Water tiles and tiles that already have ore are skipped. The territories are picked from the noise in init.
-- storage.districts[territory id] = {point = {x, y}, list = {{slot, x, y (heart tile), rotation, built, uranium}}}
--   uranium: true on the patch's district, then {tiles, amount} once placed. fighting / fallen: set by war.lua.
-- storage.uranium_points = the picked territories' points {{x, y}}

local territories = require("scripts.territories")

local districts = {}

local SLOTS = 4
local DISTANCE = 115
local NESTS, NEST_R = 6, 14
local RIM = NEST_R + 4      -- land checked this far from the heart (nest ring + nest half-size)
districts.RIM = RIM         -- war.lua: a hit this close to a heart belongs to its district
local REACH = RIM + 2       -- chunks within this of the heart are generated before it is built
local LAND = 2              -- as brain.lua / oil.lua (water is < 0)
local CLEAR = {nest = 3, heart = 5} -- tiles around a piece cleared of trees and rocks (a nest is 5 x 5, a heart 7 x 7)
local HEART = "ht-district-heart"
local TWO_PI = 2 * math.pi
local TURNS = {0, 1, -1, 2, -2}          -- × 15°
local RADII = {0, -10, 10, -15}          -- + DISTANCE
local URANIUM_TERRITORIES = 3
local URANIUM_RADIUS = 12                -- ~450 tiles
local URANIUM_AMOUNT = 1500000
local G = 384 -- grid cell (nauvis-territory.lua)
local function layer(i) return i >= 0 and i or -i - 1 end

-- Points of the ring-2 cells, closest to the origin first (from the noise: works before the chunks exist).
local function ring2_points(surface)
  local positions = {}
  for i = -3, 2 do
    for j = -3, 2 do
      if math.max(layer(i), layer(j)) == 2 then positions[#positions + 1] = {(i + 0.5) * G, (j + 0.5) * G} end
    end
  end
  local p = surface.calculate_tile_properties({"hostile_point_own_x", "hostile_point_own_y"}, positions)
  local points = {}
  for k = 1, #positions do points[k] = {x = p.hostile_point_own_x[k], y = p.hostile_point_own_y[k]} end
  table.sort(points, function(a, b) return a.x * a.x + a.y * a.y < b.x * b.x + b.y * b.y end)
  return points
end

function districts.init()
  storage.districts = storage.districts or {}
  if not storage.uranium_points then
    local surface = game.surfaces[territories.surface_name]
    if surface then
      storage.uranium_points = {}
      for k, point in ipairs(ring2_points(surface)) do
        if k > URANIUM_TERRITORIES then break end
        storage.uranium_points[k] = point
      end
    end
  end
end

local function gets_uranium(point)
  for _, u in pairs(storage.uranium_points or {}) do
    if u.x == point.x and u.y == point.y then return true end
  end
  return false
end

-- The uranium disc around a district's heart: URANIUM_AMOUNT spread over the land tiles without ore, weighted
-- 1 in the middle down to 0.5 at the rim.
local function place_uranium(surface, d)
  local tiles, total = {}, 0
  for dx = -URANIUM_RADIUS, URANIUM_RADIUS do
    for dy = -URANIUM_RADIUS, URANIUM_RADIUS do
      local r = math.sqrt(dx * dx + dy * dy)
      if r <= URANIUM_RADIUS then
        local x, y = d.x + dx, d.y + dy
        if not surface.get_tile(x, y).collides_with("water_tile")
            and surface.count_entities_filtered{position = {x + 0.5, y + 0.5}, radius = 0.4, type = "resource"} == 0 then
          local w = 1 - 0.5 * r / URANIUM_RADIUS
          tiles[#tiles + 1] = {x = x + 0.5, y = y + 0.5, w = w}
          total = total + w
        end
      end
    end
  end
  local placed = 0
  for _, t in pairs(tiles) do
    local amount = math.max(1, math.floor(URANIUM_AMOUNT * t.w / total))
    surface.create_entity{name = "uranium-ore", position = {t.x, t.y}, amount = amount}
    placed = placed + amount
  end
  d.uranium = {tiles = #tiles, amount = placed}
end

-- The pieces of one district: heart, then NESTS nests (biter and spitter spawners alternating), {name, type, x, y}.
local function pieces(d) -- also districts.pieces
  local rotation = d.rotation
  local list = {{name = HEART, type = "unit-spawner", x = d.x, y = d.y, clear = CLEAR.heart}}
  for k = 0, NESTS - 1 do
    local a = rotation + k * TWO_PI / NESTS
    list[#list + 1] = {name = k % 2 == 0 and "biter-spawner" or "spitter-spawner", type = "unit-spawner",
      x = d.x + math.floor(NEST_R * math.cos(a) + 0.5), y = d.y + math.floor(NEST_R * math.sin(a) + 0.5), clear = CLEAR.nest}
  end
  return list
end

districts.pieces = pieces

-- Pieces of every built district of a territory, for regrow.lua. Not those of a district in a fight or fallen
-- (war.lua, ring2-challenge-plan.md 4e1).
function districts.slots(id)
  local state = storage.districts[id]
  local list = {}
  if not state then return list end
  for _, d in pairs(state.list) do
    if d.built and not (d.fighting or d.fallen) then
      for _, piece in pairs(pieces(d)) do list[#list + 1] = piece end
    end
  end
  return list
end

local function place(surface, piece)
  local position = {piece.x + 0.5, piece.y + 0.5}
  if surface.count_entities_filtered{position = position, radius = 1.5, type = piece.type, force = "enemy"} > 0 then return end
  for _, e in pairs(surface.find_entities_filtered{area = {{position[1] - piece.clear, position[2] - piece.clear},
      {position[1] + piece.clear, position[2] + piece.clear}},
      type = piece.name == HEART and {"tree", "simple-entity", "cliff"} or {"tree", "simple-entity"}}) do
    e.destroy()
  end
  if surface.can_place_entity{name = piece.name, position = position, force = "enemy"} then
    surface.create_entity{name = piece.name, position = position, force = "enemy"}
  end
end

local function try_build(surface, state, d)
  if d.built then return end
  for _, c in pairs(territories.own_chunks(surface, {x = d.x + 0.5, y = d.y + 0.5}, state.point, REACH)) do
    if not surface.is_chunk_generated(c) then return end
  end
  d.built = true
  if d.uranium == true then place_uranium(surface, d) end
  for _, piece in pairs(pieces(d)) do place(surface, piece) end
end

-- A ring-2+ brain stands on its base at centre (tile + 0.5); point = its territory's point (tile).

function districts.plan(surface, record, centre, point)
  if storage.districts[record.id] then return end
  if math.max(layer(math.floor(point.x / G)), layer(math.floor(point.y / G))) < 2 then return end -- ring 2+ only
  local rotation = surface.calculate_tile_properties({"hostile_base_rotation"}, {{centre.x, centre.y}}).hostile_base_rotation[1]
  -- candidates per slot, in order of preference, each with the heart and 8 rim points to check
  local candidates, positions = {}, {}
  for slot = 1, SLOTS do
    candidates[slot] = {}
    for _, turn in ipairs(TURNS) do
      for _, dr in ipairs(RADII) do
        local a = rotation + (slot - 1) * TWO_PI / SLOTS + turn * math.pi / 12
        local r = DISTANCE + dr
        local c = {x = math.floor(centre.x + r * math.cos(a)), y = math.floor(centre.y + r * math.sin(a)), first = #positions + 1}
        positions[#positions + 1] = {c.x + 0.5, c.y + 0.5}
        for k = 0, 7 do
          local b = k * math.pi / 4
          positions[#positions + 1] = {c.x + 0.5 + RIM * math.cos(b), c.y + 0.5 + RIM * math.sin(b)}
        end
        table.insert(candidates[slot], c)
      end
    end
  end
  local p = surface.calculate_tile_properties({"elevation", "hostile_point_nearest_x", "hostile_point_nearest_y"}, positions)
  local state = {point = {x = point.x, y = point.y}, list = {}}
  storage.districts[record.id] = state
  for slot = 1, SLOTS do
    for _, c in ipairs(candidates[slot]) do
      local fits = true
      for k = c.first, c.first + 8 do
        if p.elevation[k] < LAND or p.hostile_point_nearest_x[k] ~= point.x or p.hostile_point_nearest_y[k] ~= point.y then
          fits = false
          break
        end
      end
      if fits then
        state.list[#state.list + 1] = {slot = slot, x = c.x, y = c.y, rotation = rotation, built = false}
        break
      end
    end
  end
  if gets_uranium(point) then
    local best, bd
    for _, d in pairs(state.list) do
      local q = d.x * d.x + d.y * d.y
      if not bd or q < bd then best, bd = d, q end
    end
    if best then best.uranium = true end
  end
  for _, d in pairs(state.list) do try_build(surface, state, d) end
end

-- Any chunk generated: districts waiting for their chunks try again (few at a time: only planned, unbuilt ones).
function districts.on_chunk_generated(event)
  if event.surface.name ~= territories.surface_name then return end
  local cx, cy = event.position.x * 32 + 16, event.position.y * 32 + 16
  for _, state in pairs(storage.districts) do
    for _, d in pairs(state.list) do
      if not d.built and math.abs(d.x - cx) <= REACH + 32 and math.abs(d.y - cy) <= REACH + 32 then
        try_build(event.surface, state, d)
      end
    end
  end
end

function districts.describe()
  local bases, planned, built, uranium = 0, 0, 0, {}
  for _, state in pairs(storage.districts) do
    bases = bases + 1
    for _, d in pairs(state.list) do
      planned = planned + 1
      if d.built then built = built + 1 end
      if d.uranium then
        uranium[#uranium + 1] = string.format("[gps=%d,%d] %s", d.x, d.y,
          d.uranium == true and "waiting" or string.format("%.1f M", d.uranium.amount / 1e6))
      end
    end
  end
  return string.format("Ring-2+ bases with districts: %d, districts planned %d, built %d. Guaranteed uranium (%d of %d): %s.",
    bases, planned, built, #uranium, #(storage.uranium_points or {}), #uranium > 0 and table.concat(uranium, ", ") or "none yet")
end

return districts
