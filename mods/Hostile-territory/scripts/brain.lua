-- Brain placement (territory-brain-plan.md B3; water: ring2-challenge-plan.md R2-E1 4b, R2-D17, D19, D20).
-- Map gen builds one base per territory around the territory's point (brain-bases.lua); the engine spawns the
-- territory's brain somewhere on its patrol path. When the chunk holding a point is generated:
--   the centre is dry → the brain is moved onto it (set_body_nodes, a jump; it never moves on its own) and its
--   base is registered for regrowth (regrow.lua);
--   water within FIT_RADIUS → the base moves to a land spot (land_spot below, from the noise): map gen's base
--   around the point is removed, the chunks around the spot are generated, then the brain jumps there and its whole
--   base is built by script at once (regrow.fill). No land spot (or the spot turns out wet) → the brain is
--   destroyed and the territory starts claimed (B-D5).
-- Out of sight before that (B-I10, R2-E1 4b): when the engine creates a territory's brain, it jumps at once to where
-- its base will stand (brain.home, from the noise; usually in chunks not generated yet) and that base's chunks are
-- requested, so the base appears around it soon after. The chunk generation above still decides with the real tiles.
-- Brains made with the map (the starting area) raise no creation event, so a sweep every SWEEP_INTERVAL catches
-- every brain not seen yet.
-- A base lies inside its point's grid cell (nauvis-territory.lua keeps every point 38 tiles from the cell edge, a
-- land spot keeps EDGE; a base reaches BASE_RADIUS, 36 with ring 1's anchors), and chunks never straddle cells. So a
-- chunk only ever touches its own cell's base: every newly generated chunk in a moved or dead point's cell is cleaned
-- around the point too (map gen's base pieces generated after the point's chunk). A spot's base is only built once
-- its territory's chunks within REACH of it are generated, so later chunks of the cell never hold a piece of it
-- (a slot in another territory's chunk is left to regrowth).
-- storage.brain = {placed = {[cell] = true}, dead = {[cell] = {x, y}}, seen = {[unit_number] = true} (hidden or left),
--   homes = {[cell] = {x, y}} (where its brain was hidden),
--   moved = {[cell] = {point = {x, y}, spot = {x, y}, id = territory id, done = bool}}}, cell = "i,j" of the point's grid cell.

local territories = require("scripts.territories")
local regrow = require("scripts.regrow")
local districts = require("scripts.districts")

local brain = {}

local G = 384           -- grid cell, tiles (nauvis-territory.lua)
local FIT_RADIUS = 3    -- no water this close to the centre, or the brain can't stand there
local WET_RADIUS = FIT_RADIUS + 2 -- brain.home's noise check around a point, with a margin over the real check
local WET = 1           -- elevation below this counts as water there (real water is < 0)
local BASE_RADIUS = 25  -- reach of a base (ring 18 + nest size)
local CLEAN_RADIUS = 40 -- also takes the nests' biters, which wander around them
local STEP = 16         -- land spot: sample grid over the cell, tiles
local EDGE = 40         -- a spot stays this far inside its cell (anchors at 32 + nest size)
local CORES = {2, 1, 0} -- samples (STEP each) around a spot that must be land too: the whole nest ring first, else less (R2-D19)
local SCORE = 4         -- samples around a spot counted as its land (the bigger the land, the better)
local LAND = 2          -- elevation a sample needs (water is < 0; as oil.lua)
brain.SWEEP_INTERVAL = 60
local REACH = EDGE - 1  -- tiles around a spot whose chunks are generated before its base is built (all in its cell)

function brain.init()
  storage.brain = storage.brain or {placed = {}, dead = {}}
  storage.brain.moved = storage.brain.moved or {}
  storage.brain.seen = storage.brain.seen or {}
  storage.brain.homes = storage.brain.homes or {}
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

-- The best land spot for the base of point (tile position), from the noise, or nil: a sample of the point's grid cell
-- (STEP grid, EDGE inside the cell) in the point's own territory with land under it and its neighbours within the
-- first of CORES that any sample fits, with the most land samples within SCORE; the one closest to the point on ties.
local function land_spot(surface, point)
  local x0, y0 = math.floor(point.x / G) * G, math.floor(point.y / G) * G
  local n = G / STEP
  local positions = {}
  for i = 0, n - 1 do
    for j = 0, n - 1 do positions[#positions + 1] = {x0 + (i + 0.5) * STEP, y0 + (j + 0.5) * STEP} end
  end
  local p = surface.calculate_tile_properties({"elevation", "hostile_point_nearest_x", "hostile_point_nearest_y"}, positions)
  local land = {}
  for k = 1, #positions do
    land[k] = p.elevation[k] >= LAND and p.hostile_point_nearest_x[k] == point.x and p.hostile_point_nearest_y[k] == point.y
  end
  local function is_land(i, j) return i >= 0 and j >= 0 and i < n and j < n and land[i * n + j + 1] end
  local function count(i, j, r)
    local c = 0
    for di = -r, r do
      for dj = -r, r do
        if di * di + dj * dj <= r * r and is_land(i + di, j + dj) then c = c + 1 end
      end
    end
    return c
  end
  for _, core in ipairs(CORES) do
    local core_full = 0 -- samples in a core disk
    for di = -core, core do
      for dj = -core, core do
        if di * di + dj * dj <= core * core then core_full = core_full + 1 end
      end
    end
    local best, best_score, best_d
    for k, c in ipairs(positions) do
      local i, j = math.floor((k - 1) / n), (k - 1) % n
      if land[k] and c[1] - x0 >= EDGE and c[2] - y0 >= EDGE and x0 + G - c[1] >= EDGE and y0 + G - c[2] >= EDGE
          and count(i, j, core) == core_full then
        local score = count(i, j, SCORE)
        local d = (c[1] - point.x) ^ 2 + (c[2] - point.y) ^ 2
        if not best or score > best_score or (score == best_score and d < best_d) then
          best, best_score, best_d = c, score, d
        end
      end
    end
    if best then return {x = math.floor(best[1]), y = math.floor(best[2])} end
  end
end

-- Where the base of point (tile position) stands, from the noise, before its chunks exist (oil.lua, staging.lua):
-- the point itself when the noise is clearly dry within WET_RADIUS (every tile, elevation >= WET: a margin, so the
-- real tiles rarely disagree), else its land spot (nil: none). Once a brain is hidden there (storage.brain.homes),
-- that stays its home: the chunk generation only overrules a point that turns out wet after all. Without a land spot
-- the point is returned too: then the real tiles decide (claimed if wet).
function brain.home(surface, point)
  local key = cell_key(point.x, point.y)
  if storage.brain then
    if storage.brain.moved[key] then return storage.brain.moved[key].spot end
    if storage.brain.dead[key] then return nil end
    if storage.brain.homes[key] then return storage.brain.homes[key] end
  end
  local around = {}
  for dx = -WET_RADIUS, WET_RADIUS do
    for dy = -WET_RADIUS, WET_RADIUS do
      if dx * dx + dy * dy <= WET_RADIUS * WET_RADIUS then around[#around + 1] = {point.x + 0.5 + dx, point.y + 0.5 + dy} end
    end
  end
  for _, e in pairs(surface.calculate_tile_properties({"elevation"}, around).elevation) do
    -- no land spot: the point after all (the real tiles decide once its chunk is generated)
    if e < WET then return land_spot(surface, point) or point end
  end
  return point
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

local function unit_of(record)
  for _, u in pairs(record.territory.get_segmented_units()) do
    if u.valid then return u end
  end
end

local function claim(surface, record, unit, key, centre)
  unit.destroy()
  territories.set_state(record, "claimed")
  storage.brain.dead[key] = centre
  clean(surface, centre)
end

-- A moved base whose own spot chunks are all generated: the brain jumps to the spot, the base is built there. Slots in
-- another territory's chunk not generated yet are built later by regrowth.
local function try_finish(surface, key)
  local moved = storage.brain.moved[key]
  local point = {x = moved.point.x - 0.5, y = moved.point.y - 0.5}
  for _, c in pairs(territories.own_chunks(surface, {x = moved.spot.x + 0.5, y = moved.spot.y + 0.5}, point, REACH)) do
    if not surface.is_chunk_generated(c) then return end
  end
  moved.done = true
  local record = storage.territories and storage.territories[moved.id]
  local unit = record and record.territory.valid and unit_of(record)
  if not unit then return end -- claimed meanwhile
  local centre = {x = moved.spot.x + 0.5, y = moved.spot.y + 0.5}
  if surface.count_tiles_filtered{position = centre, radius = FIT_RADIUS, collision_mask = "water_tile"} > 0 then
    storage.brain.moved[key] = nil
    claim(surface, record, unit, key, moved.point)
    return
  end
  move(unit, centre)
  storage.brain.placed[key] = true
  regrow.register(record, centre)
  regrow.fill(surface, record)
  districts.plan(surface, record, centre, point)
end

-- A territory brain whose base isn't placed yet jumps to where it will stand, and that base's chunks are requested.
-- Brains of cells already handled (a lost crusade's brain at its rally spot, brain.lua's own moves) are left alone.
local function hide(unit)
  if not unit.valid or storage.brain.seen[unit.unit_number] then return end
  storage.brain.seen[unit.unit_number] = true
  if not (unit.territory and unit.surface.name == territories.surface_name) then return end
  local surface = unit.surface
  -- the territory's point, read at one of its chunks (the engine may spawn a brain outside its own territory)
  local chunk = unit.territory.get_chunks()[1]
  if not chunk then return end
  local p = surface.calculate_tile_properties({"hostile_point_nearest_x", "hostile_point_nearest_y"},
    {{chunk.x * 32 + 16, chunk.y * 32 + 16}})
  local point = {x = p.hostile_point_nearest_x[1], y = p.hostile_point_nearest_y[1]}
  local key = cell_key(point.x, point.y)
  if storage.brain.placed[key] or storage.brain.dead[key] or storage.brain.moved[key] then return end
  local home = brain.home(surface, point)
  if not home then return end -- no land: claimed once the point's chunk is generated
  storage.brain.homes[key] = home
  move(unit, {x = home.x + 0.5, y = home.y + 0.5})
  territories.request_own(surface, {x = point.x + 0.5, y = point.y + 0.5}, point, REACH)
  territories.request_own(surface, {x = home.x + 0.5, y = home.y + 0.5}, point, REACH)
end

function brain.on_segmented_unit_created(event)
  if storage.brain and event.segmented_unit then hide(event.segmented_unit) end
end

-- Every SWEEP_INTERVAL: brains no creation event told us about.
function brain.sweep()
  local surface = game.surfaces[territories.surface_name]
  if not surface then return end
  for _, unit in pairs(surface.get_segmented_units()) do
    if not storage.brain.seen[unit.unit_number] then hide(unit) end
  end
end

local function handle_point(surface, chunk, point, key)
  local record = territories.get(surface.get_territory_for_chunk(chunk))
  if not record then return end
  local unit = unit_of(record)
  if not unit then return end -- already claimed
  local centre = {x = point.x + 0.5, y = point.y + 0.5}
  -- a brain hidden on a land spot keeps it (no second jump); else the real tiles decide
  local home = storage.brain.homes[key]
  local spot = home and (home.x ~= point.x or home.y ~= point.y) and home
  if not spot then
    if surface.count_tiles_filtered{position = centre, radius = FIT_RADIUS, collision_mask = "water_tile"} == 0 then
      move(unit, centre)
      storage.brain.placed[key] = true
      regrow.register(record, centre)
      districts.plan(surface, record, centre, point)
      return
    end
    spot = land_spot(surface, point)
  end
  if not spot then
    claim(surface, record, unit, key, centre)
    return
  end
  clean(surface, centre)
  storage.brain.moved[key] = {point = centre, spot = spot, id = record.id, done = false}
  territories.request_own(surface, {x = spot.x + 0.5, y = spot.y + 0.5}, point, REACH)
  try_finish(surface, key)
end

local function on_chunk(surface, chunk, area)
  local point = point_of_chunk(surface, chunk)
  if not point then return end
  local key = cell_key(point.x, point.y)
  local dead, moved = storage.brain.dead[key], storage.brain.moved[key]
  if dead then
    clean(surface, dead, area)
  elseif moved then
    clean(surface, moved.point, area)
    if not moved.done then try_finish(surface, key) end
  elseif not storage.brain.placed[key] and math.floor(point.x / 32) == chunk.x and math.floor(point.y / 32) == chunk.y then
    handle_point(surface, chunk, point, key)
  end
end

function brain.on_chunk_generated(event)
  if event.surface.name ~= territories.surface_name then return end
  on_chunk(event.surface, event.position, event.area)
end

-- Chunks generated before the mod was added (or before on_init): every generated chunk once. Brains created
-- before then (the territories around spawn come with the map, before any handler runs) are hidden here.
function brain.scan()
  local surface = game.surfaces[territories.surface_name]
  if not surface then return end
  for chunk in surface.get_chunks() do
    if surface.is_chunk_generated(chunk) then on_chunk(surface, chunk, chunk.area) end
  end
  for _, unit in pairs(surface.get_segmented_units()) do hide(unit) end
end

function brain.describe()
  local placed, dead, moved, waiting = 0, 0, 0, 0
  for _ in pairs(storage.brain.placed) do placed = placed + 1 end
  for _ in pairs(storage.brain.dead) do dead = dead + 1 end
  for _, m in pairs(storage.brain.moved) do
    if m.done then moved = moved + 1 else waiting = waiting + 1 end
  end
  return string.format("Brains placed on their base: %d (%d of them moved onto land, %d waiting for their chunks). "
    .. "Territories claimed at map gen (no land): %d.", placed, moved, waiting, dead)
end

return brain
