-- Brain placement (territory-brain-plan.md B3).
-- Map gen builds one base per territory around the territory's point (brain-bases.lua); the engine spawns the
-- territory's brain somewhere on its patrol path. When the chunk holding a point is generated:
--   the centre is dry → the brain is moved onto it (set_body_nodes, a jump; it never moves on its own) and its
--   base is registered for regrowth (regrow.lua);
--   water within FIT_RADIUS → the brain is destroyed, the base removed and the territory starts claimed (B-D5).
-- A base lies inside its point's grid cell (nauvis-territory.lua keeps every point 38 tiles from the cell edge, a
-- base reaches BASE_RADIUS), and chunks never straddle cells. So a chunk only ever touches its own cell's base:
-- every newly generated chunk in a dead point's cell is cleaned too (base pieces generated after the point's chunk).
-- storage.brain = {placed = {[cell] = true}, dead = {[cell] = {x, y}}}, cell = "i,j" of the point's grid cell.

local territories = require("scripts.territories")
local regrow = require("scripts.regrow")

local brain = {}

local G = 384           -- grid cell, tiles (nauvis-territory.lua)
local FIT_RADIUS = 3    -- no water this close to the centre, or the brain can't stand there
local BASE_RADIUS = 25  -- reach of a base (ring 18 + nest size)
local CLEAN_RADIUS = 40 -- also takes the nests' biters, which wander around them

function brain.init()
  storage.brain = storage.brain or {placed = {}, dead = {}}
end

local function cell_key(x, y)
  return math.floor(x / G) .. "," .. math.floor(y / G)
end

-- The point of the grid cell holding this chunk, or nil if that cell has no base.
local function point_of_chunk(surface, chunk)
  local p = surface.calculate_tile_properties({"hostile_point_own_x", "hostile_point_own_y", "hostile_base_exists"},
    {{chunk.x * 32 + 16, chunk.y * 32 + 16}})
  if p.hostile_base_exists[1] <= 0 then return nil end
  return {x = p.hostile_point_own_x[1], y = p.hostile_point_own_y[1]}
end

local function clean(surface, centre, area)
  for _, e in pairs(surface.find_entities_filtered{area = area, position = not area and centre or nil,
      radius = not area and CLEAN_RADIUS or nil, force = "enemy", type = {"turret", "unit-spawner", "unit"}}) do
    if not area or (e.position.x - centre.x) ^ 2 + (e.position.y - centre.y) ^ 2 < CLEAN_RADIUS ^ 2 then e.destroy() end
  end
end

-- Moves the unit so its head is on the centre. The body (if any) moves along.
local function move(unit, centre)
  local head = unit.segments[1].position
  local dx, dy = centre.x - head.x, centre.y - head.y
  local nodes = unit.get_body_nodes()
  for _, n in pairs(nodes) do n.x, n.y = n.x + dx, n.y + dy end
  unit.set_body_nodes(nodes)
end

local function handle_point(surface, chunk, point, key)
  local record = territories.get(surface.get_territory_for_chunk(chunk))
  if not record then return end
  local unit
  for _, u in pairs(record.territory.get_segmented_units()) do
    if u.valid then unit = u break end
  end
  if not unit then return end -- already claimed
  local centre = {x = point.x + 0.5, y = point.y + 0.5}
  if surface.count_tiles_filtered{position = centre, radius = FIT_RADIUS, collision_mask = "water_tile"} > 0 then
    unit.destroy()
    territories.set_state(record, "claimed")
    storage.brain.dead[key] = centre
    clean(surface, centre)
  else
    move(unit, centre)
    storage.brain.placed[key] = true
    regrow.register(record, centre)
  end
end

local function on_chunk(surface, chunk, area)
  local point = point_of_chunk(surface, chunk)
  if not point then return end
  local key = cell_key(point.x, point.y)
  local dead = storage.brain.dead[key]
  if dead then
    clean(surface, dead, area)
  elseif not storage.brain.placed[key] and math.floor(point.x / 32) == chunk.x and math.floor(point.y / 32) == chunk.y then
    handle_point(surface, chunk, point, key)
  end
end

function brain.on_chunk_generated(event)
  if event.surface.name ~= territories.surface_name then return end
  on_chunk(event.surface, event.position, event.area)
end

-- Chunks generated before the mod was added (or before on_init): every generated chunk once.
function brain.scan()
  local surface = game.surfaces[territories.surface_name]
  if not surface then return end
  for chunk in surface.get_chunks() do
    if surface.is_chunk_generated(chunk) then on_chunk(surface, chunk, chunk.area) end
  end
end

function brain.describe()
  local placed, dead = 0, 0
  for _ in pairs(storage.brain.placed) do placed = placed + 1 end
  for _ in pairs(storage.brain.dead) do dead = dead + 1 end
  return string.format("Brains placed on their base: %d. Territories claimed at map gen (water): %d.", placed, dead)
end

return brain
