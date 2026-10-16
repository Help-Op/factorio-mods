-- Wyrms and water (EB3b, D32, D34, D35).
-- The engine's patrol path ignores water (~19 % on water) and wyrms walk over it.
-- (A) Reroute (D34): on registration the path is moved onto land using the map-gen noise. Nauvis water is
--   elevation < 0, and calculate_tile_properties reads the elevation of chunks that aren't generated yet
--   (99.96 % match with the real tiles at integer positions, Q-EB3b-8). The territory is seen as a grid of
--   GRID-tile cells, land = elevation > SHORE, only cells in the territory's chunks.
--   One job at a time (storage.patrol_job), spread over ticks, stages:
--     fetch: elevation of FETCH_CHUNKS chunks per tick (one call each tick; every call costs ~0.7 ms extra);
--     label: connected land parts (flood fill);
--     snap:  path points on water move to the nearest land cell (search capped at SNAP_LIMIT cells);
--            split by water (D35): keep the part with the most path points, drop the rest;
--     route: segments that cross water get an A* detour (inside one part it always succeeds), shortened to the
--            corners it needs. Then set_patrol_path.
--   label, snap and route share a budget of WORK cells per tick (at least one step per tick).
--   Almost all water (< MIN_POINTS points on land): the engine path is kept, (B) makes land when a player is near.
--   storage.patrol_pending = territories waiting for a job.
-- (B) Live: every LIVE_INTERVAL ticks, every fully active wyrm (= one a player can see) turns the water under its
--   head into land: covers kiting over a lake, corner cutting (turn radius) and thin streams the grid misses.
-- Land tile: a land tile found near the spot (natural look), else FALLBACK_TILE.
-- record.patrol = {v, points, snapped, dropped, detours, chunks, ticks, result} (debug);
--   result = "rerouted" / "dry" (no change needed) / "water" (engine path kept).

local patrol = {}

local VERSION = 2 -- records with an older patrol.v get rerouted
local GRID = 4
local CELLS = 32 / GRID -- cells per chunk side
local SHORE = 1 -- elevation a land cell needs (keeps the path ~1-2 tiles off the shore)
local FETCH_CHUNKS = 8 -- ~1.5 ms
local WORK = 600 -- cells per tick for label / snap / route (~1-2 ms)
local SNAP_LIMIT = 256 -- cells a snap search may visit (~32 tiles); deeper points are dropped
local MIN_POINTS = 3
local MARGIN = 1
local DEFAULT_HALF_WIDTH = 3
local LAND_SEARCH_RADIUS = 16
local FALLBACK_TILE = "landfill"
patrol.INTERVAL = 1
patrol.LIVE_INTERVAL = 31 -- not 30: on_nth_tick(30) is taken by challenge.on_tick (one handler per interval)

local floor, abs, max, min = math.floor, math.abs, math.max, math.min

-- Cell keys: one number per cell.
local K = 2 ^ 21
local H = 2 ^ 20

local function key(gx, gy)
  return gx * K + gy
end

local function coords(k)
  local gy = (k + H) % K - H
  return (k - gy) / K, gy
end

-- Neighbour offsets in key space (dx * K + dy) and step costs.
local DK = {K, -K, 1, -1, K + 1, K - 1, -K + 1, -K - 1}
local DC = {1, 1, 1, 1, 1.4142, 1.4142, 1.4142, 1.4142}

-- (A) Reroute: helpers -----------------------------------------------------------

-- Straight line between two cells stays in one land part. Returns ok, cells checked.
local function clear(job, ax, ay, bx, by)
  local part_of = job.part
  local part = part_of[key(ax, ay)]
  if not part then return false, 1 end
  local steps = max(1, math.ceil(max(abs(bx - ax), abs(by - ay)) * 2))
  for s = 0, steps do
    local t = s / steps
    if part_of[key(floor(ax + (bx - ax) * t + 0.5), floor(ay + (by - ay) * t + 0.5))] ~= part then
      return false, s + 1
    end
  end
  return true, steps + 1
end

-- Binary heap of keys ordered by f.
local function push(heap, f, k)
  local i = #heap + 1
  heap[i] = k
  while i > 1 do
    local p = floor(i / 2)
    if f[heap[p]] <= f[k] then break end
    heap[i], heap[p] = heap[p], k
    i = p
  end
end

local function pop(heap, f)
  local top, last = heap[1], table.remove(heap)
  if #heap == 0 then return top end
  heap[1] = last
  local i, n = 1, #heap
  while true do
    local l, r, m = i * 2, i * 2 + 1, i
    if l <= n and f[heap[l]] < f[heap[m]] then m = l end
    if r <= n and f[heap[r]] < f[heap[m]] then m = r end
    if m == i then break end
    heap[i], heap[m] = heap[m], heap[i]
    i = m
  end
  return top
end

local function octile(ak, bx, by)
  local ax, ay = coords(ak)
  local dx, dy = abs(bx - ax), abs(by - ay)
  return max(dx, dy) + 0.4142 * min(dx, dy)
end

-- A* over the cells of one land part, resumable: state in job.search.
local function search_start(job, p, q)
  local a = key(p.gx, p.gy)
  local s = {b = key(q.gx, q.gy), bx = q.gx, by = q.gy, part = job.part[a],
    g = {[a] = 0}, f = {}, from = {}, closed = {}, heap = {}}
  s.f[a] = octile(a, q.gx, q.gy)
  push(s.heap, s.f, a)
  job.search = s
end

-- Expands up to budget cells. Returns cells used, and the cell keys from a to b once found (false if unreachable).
local function search_step(job, budget)
  local s = job.search
  local part_of, part, g, f, from, closed, heap = job.part, s.part, s.g, s.f, s.from, s.closed, s.heap
  local used = 0
  while heap[1] and used < budget do
    local k = pop(heap, f)
    if not closed[k] then
      closed[k] = true
      used = used + 1
      if k == s.b then
        local path = {k}
        while from[k] do
          k = from[k]
          path[#path + 1] = k
        end
        local n = #path
        for i = 1, floor(n / 2) do path[i], path[n + 1 - i] = path[n + 1 - i], path[i] end
        return used, path
      end
      for i = 1, 8 do
        local nk = k + DK[i]
        if not closed[nk] and part_of[nk] == part then
          local ng = g[k] + DC[i]
          if not g[nk] or ng < g[nk] then
            g[nk], f[nk], from[nk] = ng, ng + octile(nk, s.bx, s.by), k
            push(heap, f, nk)
          end
        end
      end
    end
  end
  if heap[1] then return used, nil end
  return used, false
end

-- Nearest land cell (breadth first over the territory's cells, capped), or nil. Returns gx, gy, cells visited.
local function snap(job, gx, gy)
  local start = key(gx, gy)
  local part_of, chunks = job.part, job.chunks
  if part_of[start] then return gx, gy, 1 end
  local queue, seen, head = {start}, {[start] = true}, 1
  while queue[head] and head <= SNAP_LIMIT do
    local k = queue[head]
    head = head + 1
    for i = 1, 8 do
      local nk = k + DK[i]
      if not seen[nk] then
        seen[nk] = true
        local x, y = coords(nk)
        if part_of[nk] then return x, y, head end
        if chunks[key(floor(x / CELLS), floor(y / CELLS))] then queue[#queue + 1] = nk end
      end
    end
  end
  return nil, nil, head
end

-- (A) Reroute: stages ------------------------------------------------------------

local stages = {}

function stages.fetch(job, territory)
  local positions, cells = {}, {}
  for _ = 1, FETCH_CHUNKS do
    local c = job.chunk_list[job.ci]
    if not c then break end
    job.ci = job.ci + 1
    for i = 0, CELLS - 1 do
      for j = 0, CELLS - 1 do
        positions[#positions + 1] = {c.x * 32 + i * GRID, c.y * 32 + j * GRID}
        cells[#cells + 1] = key(c.x * CELLS + i, c.y * CELLS + j)
      end
    end
  end
  if #positions > 0 then
    local elevation = territory.surface.calculate_tile_properties({"elevation"}, positions).elevation
    local land = job.land
    for n, k in pairs(cells) do
      if elevation[n] > SHORE then land[#land + 1] = k end
    end
  end
  if not job.chunk_list[job.ci] then
    job.chunk_list = nil
    -- part[k] = 0: land, not labelled yet
    for _, k in pairs(job.land) do job.part[k] = 0 end
    job.stage, job.li, job.parts = "label", 1, 0
  end
  return WORK -- one fetch per tick
end

-- Flood fill, resumable: job.queue / job.head hold the fill in progress.
function stages.label(job)
  local cost, part_of = 0, job.part
  while cost < WORK do
    local queue = job.queue
    if queue and queue[job.head] then
      local k = queue[job.head]
      job.head = job.head + 1
      cost = cost + 1
      for i = 1, 8 do
        local nk = k + DK[i]
        if part_of[nk] == 0 then
          part_of[nk] = job.parts
          queue[#queue + 1] = nk
        end
      end
    else
      job.queue = nil
      local k = job.land[job.li]
      while k and part_of[k] ~= 0 do
        job.li = job.li + 1
        k = job.land[job.li]
      end
      if not k then
        job.land = nil
        job.stage, job.pi, job.points = "snap", 1, {}
        return cost
      end
      job.parts = job.parts + 1
      part_of[k] = job.parts
      job.queue, job.head = {k}, 1
    end
  end
  return cost
end

function stages.snap(job)
  local cost, stats = 0, job.stats
  while cost < WORK do
    local p = job.path[job.pi]
    if not p then break end
    job.pi = job.pi + 1
    local cx, cy = floor(p.x / GRID + 0.5), floor(p.y / GRID + 0.5)
    local gx, gy, c = snap(job, cx, cy)
    cost = cost + c
    if not gx then
      stats.dropped = stats.dropped + 1
    else
      local last = job.points[#job.points]
      if last and last.gx == gx and last.gy == gy then
        -- same cell as the previous point: merged
      elseif gx == cx and gy == cy then
        job.points[#job.points + 1] = {gx = gx, gy = gy, position = {x = p.x, y = p.y}}
      else
        stats.snapped = stats.snapped + 1
        job.points[#job.points + 1] = {gx = gx, gy = gy, position = {x = gx * GRID, y = gy * GRID}}
      end
    end
  end
  if job.path[job.pi] then return cost end
  -- all points done: keep the part with the most points (D35)
  local points, count, best = job.points, {}, nil
  for _, p in pairs(points) do
    local part = job.part[key(p.gx, p.gy)]
    count[part] = (count[part] or 0) + 1
    if not best or count[part] > count[best] then best = part end
  end
  local kept = {}
  for _, p in pairs(points) do
    local last = kept[#kept]
    if job.part[key(p.gx, p.gy)] ~= best then
      stats.dropped = stats.dropped + 1
    elseif not (last and last.gx == p.gx and last.gy == p.gy) then
      kept[#kept + 1] = p
    end
  end
  if #kept > 1 and kept[1].gx == kept[#kept].gx and kept[1].gy == kept[#kept].gy then kept[#kept] = nil end
  job.points, job.path = kept, nil
  job.stage, job.ri, job.out = "route", 1, {}
  return cost
end

-- Per segment: straight if clear, else A* (job.search), then corners (job.corner), all resumable.
function stages.route(job)
  local cost, points, stats, out = 0, job.points, job.stats, job.out
  if #points < MIN_POINTS then
    job.stage = "done"
    return cost
  end
  while cost < WORK do
    local corner = job.corner
    if corner then
      -- keep a cell only where a straight line from the last corner would leave the part
      local cells, i = corner.cells, corner.i
      if i >= #cells then
        job.corner = nil
      else
        local ax, ay = coords(corner.anchor)
        local nx, ny = coords(cells[i + 1])
        local ok, c = clear(job, ax, ay, nx, ny)
        cost = cost + c
        if not ok then
          corner.anchor = cells[i]
          local x, y = coords(cells[i])
          out[#out + 1] = {x = x * GRID, y = y * GRID}
        end
        corner.i = i + 1
      end
    elseif job.search then
      local used, cells = search_step(job, WORK - cost)
      cost = cost + used
      if cells ~= nil then
        job.search = nil
        if cells then
          stats.detours = stats.detours + 1
          job.corner = {cells = cells, i = 2, anchor = cells[1]}
        end
      end
    else
      local p = points[job.ri]
      if not p then
        job.stage = "done"
        return cost
      end
      job.ri = job.ri + 1
      out[#out + 1] = p.position
      local q = points[(job.ri - 1) % #points + 1]
      local ok, c = clear(job, p.gx, p.gy, q.gx, q.gy)
      cost = cost + c
      if not ok then search_start(job, p, q) end
    end
  end
  return cost
end

local function finish(job, territory)
  local stats = job.stats
  if #job.points < MIN_POINTS then
    stats.result = "water"
  elseif stats.snapped == 0 and stats.dropped == 0 and stats.detours == 0 then
    stats.result = "dry"
  else
    territory.set_patrol_path(job.out)
    stats.result = "rerouted"
  end
  return stats
end

local function new_job(record)
  local territory = record.territory
  local chunks = {}
  local chunk_list = territory.get_chunks()
  for _, c in pairs(chunk_list) do chunks[key(c.x, c.y)] = true end
  local path = territory.get_patrol_path()
  return {id = record.id, stage = "fetch", chunk_list = chunk_list, ci = 1, chunks = chunks, land = {}, part = {},
    path = path, ticks = 0,
    stats = {v = VERSION, points = #path, snapped = 0, dropped = 0, detours = 0, chunks = #chunk_list}}
end

-- Runs stages until the tick's budget is used. Returns true when the job is done (record.patrol set).
local function step(job, record)
  local territory = record.territory
  job.ticks = job.ticks + 1
  local used = 0
  repeat
    if job.stage == "done" then
      job.stats.ticks = job.ticks
      record.patrol = finish(job, territory)
      return true
    end
    local stage = job.stage
    used = used + stages[stage](job, territory)
  until used >= WORK
  return false
end

-- Reroutes a territory now, in one go (debug). Returns its stats.
function patrol.reroute(record)
  local job = new_job(record)
  while not step(job, record) do end
  return record.patrol
end

function patrol.queue(record)
  if record.patrol and record.patrol.v == VERSION then return end
  storage.patrol_pending = storage.patrol_pending or {}
  storage.patrol_pending[record.id] = true
end

-- Territory gone.
function patrol.forget(record)
  if storage.patrol_pending then storage.patrol_pending[record.id] = nil end
  if storage.patrol_job and storage.patrol_job.id == record.id then storage.patrol_job = nil end
end

-- Old per-chunk fix (D33) data: dropped.
function patrol.migrate()
  storage.patrol_by_chunk = nil
  for _, record in pairs(storage.territories or {}) do
    record.patrol_todo = nil
    record.patrol_requested = nil
  end
end

-- Works on one job per tick; starts the next pending territory when idle.
function patrol.on_tick()
  local job = storage.patrol_job
  if not job then
    local pending = storage.patrol_pending
    local id = pending and next(pending)
    if not id then return end
    pending[id] = nil
    local record = storage.territories and storage.territories[id]
    if not (record and record.territory.valid) then return end
    job = new_job(record)
    storage.patrol_job = job
  end
  local record = storage.territories and storage.territories[job.id]
  if not (record and record.territory.valid) or step(job, record) then storage.patrol_job = nil end
end

-- (B) Live -----------------------------------------------------------------------

local function is_water(surface, position)
  local tile = surface.get_tile(position.x, position.y)
  return tile.valid and tile.collides_with("water_tile")
end

-- Half the width of the guardian's head (from its collision box), or a default.
local function half_width(name)
  local prototype = name and prototypes.entity[name]
  if not prototype then return DEFAULT_HALF_WIDTH end
  local box = prototype.collision_box
  return math.max(box.right_bottom.x - box.left_top.x, box.right_bottom.y - box.left_top.y) / 2
end

local function land_tile_near(surface, position)
  local tiles = surface.find_tiles_filtered{position = position, radius = LAND_SEARCH_RADIUS,
    collision_mask = "water_tile", invert = true, limit = 1}
  return tiles[1] and tiles[1].name or FALLBACK_TILE
end

-- Turns every water tile within radius of the centre into land.
local function make_land(surface, centre, radius)
  local tiles, name = {}, nil
  for x = math.floor(centre.x - radius), math.ceil(centre.x + radius) do
    for y = math.floor(centre.y - radius), math.ceil(centre.y + radius) do
      if (x + 0.5 - centre.x) ^ 2 + (y + 0.5 - centre.y) ^ 2 <= radius ^ 2 and is_water(surface, {x = x, y = y}) then
        name = name or land_tile_near(surface, centre)
        tiles[#tiles + 1] = {name = name, position = {x, y}}
      end
    end
  end
  if #tiles > 0 then surface.set_tiles(tiles, true, true, true, true) end
end

-- Every fully active wyrm makes land under its head.
function patrol.on_live_tick()
  for _, record in pairs(storage.territories or {}) do
    if record.territory.valid then
      for _, unit in pairs(record.territory.get_segmented_units()) do
        if unit.valid and unit.activity_mode == defines.segmented_unit_activity_mode.full then
          local head = unit.segments[1]
          if head and head.valid then
            make_land(unit.surface, head.position, half_width(unit.prototype.name) + MARGIN)
          end
        end
      end
    end
  end
end

return patrol
