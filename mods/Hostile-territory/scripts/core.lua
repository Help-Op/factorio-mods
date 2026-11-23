-- Core garrison and queen reserve of a territory at war (ring2-challenge-plan.md 4e2b; R2-D38, D39).
--   Core garrison: units next to the brain, fed by the districts (everything they make over war.lua's FLOOR, the
--   survivors of a fallen district, waves and armies coming home). On the map while a participant is within WAKE of
--   the brain or its chunk is visible (radar), else kept as a number, like a district garrison. Units walking to the
--   core are "incoming" until they arrive. Waves, retake armies (hive.lua) and help for an attacked district are
--   taken from the free units (not escorts).
--   Queen reserve: elder queens next to the brain (always on the map). Hearts make them (war.lua), a dying heart
--   releases one; a retake army takes one and gives her back if it retreats.
--   Protection (Q70): a participant within DANGER of a reserve queen → she walks to the safest spot within SAFE of
--   the brain (lowest threat on the influence map, furthest from participants) and ESCORT free core units stay near
--   her. Nobody within CALM_RANGE of her for CALM_AFTER → she walks home, the escorts rejoin the core.
--   Funds (4e2c, R2-D41): the free units are split into FUNDS (reserve, raid, retake) by share of what comes in, each
--   up to its cap; a full fund's share goes to the others. A fund is a number over the free units, not a list: sync()
--   credits new free units to the funds and takes lost ones off the biggest fund. Help and escorts spend the reserve,
--   raids the raid fund, retakes the retake fund (core.take with a fund name).
-- storage.cores[territory id] = {g = {units | count, hidden_tick, idle_since}, incoming = {[unit_number] = unit},
--   queens = {[unit_number] = {entity, state = "walking" | "home" | "flee" | "army", spot, escorts, calm_since}},
--   funds = {reserve, raid, retake}, acc = {per fund}, last_wave_tick, made (units that reached the core, telemetry)}

local influence = require("scripts.influence")

local core = {}

core.MAX = 350
core.RESERVE = 3
core.FUNDS = {{name = "reserve", share = 0.4, cap = 80}, {name = "raid", share = 0.35, cap = 150},
  {name = "retake", share = 0.25, cap = 120}}
local POST_MIN, POST_MAX = 12, 24
local ARRIVE = 20
local STRAY = 40
local WAKE = 200
local DESPAWN_AFTER = 60 * 60
local DANGER = 40
local SAFE = 80
local ESCORT = 10
local ESCORT_NEAR = 8
local CALM_RANGE = 60
local CALM_AFTER = 30 * 60

local api -- war.lua: spawn(surface, g, position) → unit (tamed, in g.units), log(id, event, detail)

function core.connect(callbacks) api = callbacks end

local function init_storage() storage.cores = storage.cores or {} end

local function dist2(a, b) return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 end

local function go(unit, destination, radius, distraction)
  unit.commandable.set_command{type = defines.command.go_to_location, destination = destination, radius = radius,
    distraction = distraction or defines.distraction.by_enemy}
end

local function walking(unit, destination)
  local cmd = unit.commandable.command
  return cmd and cmd.type == defines.command.go_to_location and cmd.destination
    and dist2(cmd.destination, destination) < 4
end

local function near_any(chars, position, r)
  for _, ch in pairs(chars) do if dist2(ch.position, position) <= r * r then return true end end
  return false
end

local function post(unit)
  unit.commandable.set_command{type = defines.command.wander, radius = 8, distraction = defines.distraction.by_enemy}
end

local function post_position(centre)
  local a, r = math.random() * 2 * math.pi, POST_MIN + math.random() * (POST_MAX - POST_MIN)
  return {x = centre.x + r * math.cos(a), y = centre.y + r * math.sin(a)}
end

function core.get(id)
  init_storage()
  local c = storage.cores[id]
  if not c then
    c = {g = {count = 0, hidden_tick = game.tick}, incoming = {}, queens = {}, last_wave_tick = game.tick, made = 0}
    storage.cores[id] = c
  end
  if not c.funds then c.funds, c.acc = {reserve = 0, raid = 0, retake = 0}, {reserve = 0, raid = 0, retake = 0} end
  return c
end

local function alive(list)
  local n = 0
  for k, unit in pairs(list) do
    if unit.valid then n = n + 1 else list[k] = nil end
  end
  return n
end

-- Free units at the core (on the map or counted), not counting incoming or escorts.
function core.free(id)
  local c = core.get(id)
  return c.g.units and alive(c.g.units) or c.g.count
end

function core.incoming(id) return alive(core.get(id).incoming) end

-- Funds ------------------------------------------------------------------------------------------------------------

-- n new free units go to the funds by share; a full fund is skipped (its share goes to the others).
local function credit(c, n)
  for _ = 1, n do
    local best
    for _, f in ipairs(core.FUNDS) do
      if c.funds[f.name] < f.cap then
        c.acc[f.name] = math.min(c.acc[f.name] + f.share, 2)
        if not best or c.acc[f.name] > c.acc[best] then best = f.name end
      end
    end
    if not best then return end
    c.acc[best] = c.acc[best] - 1
    c.funds[best] = c.funds[best] + 1
  end
end

-- The funds follow the free units: new ones are credited, lost ones come off each fund by its share (R2-D42; off the
-- biggest fund only, the slow retake fund was the one emptied in PT6).
function core.sync(id)
  local c = core.get(id)
  local free = core.free(id)
  local sum = c.funds.reserve + c.funds.raid + c.funds.retake
  if free > sum then credit(c, free - sum)
  elseif sum > free then
    local lost, taken = sum - free, 0
    for name, n in pairs(c.funds) do
      local k = math.floor(lost * n / sum)
      c.funds[name], taken = n - k, taken + k
    end
    for _ = 1, lost - taken do -- the rest, one each off the biggest
      local big
      for name, n in pairs(c.funds) do if n > 0 and (not big or n > c.funds[big]) then big = name end end
      if not big then break end
      c.funds[big] = c.funds[big] - 1
    end
  end
end

function core.fund(id, name)
  core.sync(id)
  return core.get(id).funds[name]
end

-- Everything that belongs to the core (free + incoming + escorts): the cap counts this.
function core.size(id)
  local c = core.get(id)
  local n = core.free(id) + core.incoming(id)
  for _, q in pairs(c.queens) do n = n + alive(q.escorts or {}) end
  return n
end

function core.full(id) return core.size(id) >= core.MAX end

function core.shown(id) return core.get(id).g.units ~= nil end

local function show(surface, c, centre)
  local count = c.g.count or 0
  c.g.units, c.g.count, c.g.hidden_tick, c.g.idle_since = {}, nil, nil, nil
  for _ = 1, count do
    local unit = api.spawn(surface, c.g, post_position(centre))
    if unit then post(unit) end
  end
end

local function hide(c)
  local n = alive(c.g.units)
  for _, unit in pairs(c.g.units) do unit.destroy() end
  c.g.units, c.g.count, c.g.hidden_tick, c.g.idle_since = nil, n, game.tick, nil
end

-- A unit walks to the core (a district's surplus, a fallen district's survivor, an army coming home).
function core.receive(id, unit, centre)
  local c = core.get(id)
  if not unit.valid then return end
  c.incoming[unit.unit_number] = unit
  go(unit, centre, 10)
end

-- n more units at the core without walkers (a hidden district's surplus while the core is off the map too).
function core.add_count(id, n)
  local c = core.get(id)
  if c.g.units then return false end
  c.g.count = c.g.count + n
  return true
end

-- Take up to n free units of a fund (the core is put on the map first). Returns a list of entities.
function core.take(surface, id, n, centre, fund)
  local c = core.get(id)
  core.sync(id)
  if not c.g.units then show(surface, c, centre) end
  n = math.min(n, c.funds[fund])
  c.funds[fund] = c.funds[fund] - n
  local out = {}
  for k, unit in pairs(c.g.units) do
    if #out >= n then break end
    if unit.valid then out[#out + 1] = unit end
    c.g.units[k] = nil
  end
  return out
end

-- Queens -----------------------------------------------------------------------------------------------------------

function core.add_queen(id, queen, centre, why)
  local c = core.get(id)
  c.queens[queen.unit_number] = {entity = queen, state = "walking", escorts = {}}
  go(queen, centre, 10, defines.distraction.none)
  api.log(id, "queen_" .. why, string.format("%d in the reserve", core.queens(id)))
end

-- Queens of the reserve (walking there, at home or fleeing; not the ones out with an army).
function core.queens(id)
  local c = core.get(id)
  local n = 0
  for _, q in pairs(c.queens) do
    if q.entity.valid and q.state ~= "army" then n = n + 1 end
  end
  return n
end

local function release_escorts(c, q, centre)
  for _, unit in pairs(q.escorts) do
    if unit.valid then
      if c.g.units then c.g.units[unit.unit_number] = unit go(unit, centre, 15) else c.incoming[unit.unit_number] = unit go(unit, centre, 10) end
    end
  end
  q.escorts = {}
end

-- A queen for a retake army (state "army"), or nil: one at home, else (R2-D41) one fleeing or walking home while
-- no participant is within DANGER of the brain.
function core.take_queen(id, centre, chars)
  local c = core.get(id)
  core.queens(id)
  local calm = not near_any(chars or {}, centre, DANGER)
  local best, bd
  for _, q in pairs(c.queens) do
    if q.entity.valid and (q.state == "home" or (calm and (q.state == "flee" or q.state == "walking"))) then
      local d = dist2(q.entity.position, centre) + (q.state == "home" and 0 or 1e9)
      if not bd or d < bd then best, bd = q, d end
    end
  end
  if not best then return nil end
  release_escorts(c, best, centre)
  best.state = "army"
  return best.entity
end

-- A retreating army's queen walks back into the reserve.
function core.queen_back(id, queen, centre)
  local c = core.get(id)
  local q = c.queens[queen.unit_number]
  if q then q.state = "walking" go(queen, centre, 10, defines.distraction.none)
  else core.add_queen(id, queen, centre, "back") end
end

-- The army's queen is gone (settled into a heart, or killed).
function core.queen_used(id, queen)
  local c = core.get(id)
  for k, q in pairs(c.queens) do
    if q.state == "army" and (q.entity == queen or not q.entity.valid) then c.queens[k] = nil end
  end
end

-- The safest spot for a queen: points around the brain within SAFE, lowest threat, then furthest from participants.
local function safe_spot(surface, centre, chars, avoid)
  local best, bs
  for _, r in pairs({30, 55, SAFE}) do
    for k = 0, 15 do
      local a = k * math.pi / 8
      local p = {x = centre.x + r * math.cos(a), y = centre.y + r * math.sin(a)}
      if not (avoid and dist2(p, avoid) < 20 * 20) then
        local near = 1e9
        for _, ch in pairs(chars) do near = math.min(near, dist2(ch.position, p)) end
        near = math.min(math.sqrt(near), 150)
        local threat = influence.around(p, 16)
        local score = threat * 10 - near
        if not bs or score < bs then best, bs = p, score end
      end
    end
  end
  return surface.find_non_colliding_position("ht-elder-queen", best, 20, 1) or best
end

local function run_queens(surface, id, c, centre, chars)
  for k, q in pairs(c.queens) do
    local e = q.entity
    if not e.valid then
      release_escorts(c, q, centre)
      c.queens[k] = nil
    elseif q.state == "walking" then
      if dist2(e.position, centre) <= ARRIVE * ARRIVE then
        q.state = "home"
        e.commandable.set_command{type = defines.command.wander, radius = 6, distraction = defines.distraction.none}
      elseif not walking(e, centre) then go(e, centre, 10, defines.distraction.none) end
    end
    if e.valid and (q.state == "home" or q.state == "walking") and near_any(chars, e.position, DANGER) then
      -- flee with escorts
      q.state, q.calm_since = "flee", nil
      q.spot = safe_spot(surface, centre, chars, e.position)
      go(e, q.spot, 3, defines.distraction.none)
      q.escorts = {}
      if c.g.units then
        -- escorts come out of the reserve fund (R2-D41)
        core.sync(id)
        local want = math.min(ESCORT, c.funds.reserve)
        local n = 0
        for uk, unit in pairs(c.g.units) do
          if n >= want then break end
          if unit.valid then
            q.escorts[uk] = unit
            n = n + 1
          end
          c.g.units[uk] = nil
        end
        c.funds.reserve = c.funds.reserve - n
      end
      api.log(id, "queen_flee", string.format("to %d %d, %d escorts", q.spot.x, q.spot.y, alive(q.escorts)))
    elseif e.valid and q.state == "flee" then
      if near_any(chars, e.position, CALM_RANGE) then
        q.calm_since = nil
        -- caught up at her spot: find another
        if dist2(e.position, q.spot) <= 6 * 6 and near_any(chars, e.position, DANGER) then
          q.spot = safe_spot(surface, centre, chars, e.position)
          go(e, q.spot, 3, defines.distraction.none)
          api.log(id, "queen_flee", string.format("on to %d %d", q.spot.x, q.spot.y))
        elseif not walking(e, q.spot) and dist2(e.position, q.spot) > 6 * 6 then
          go(e, q.spot, 3, defines.distraction.none)
        end
      else
        q.calm_since = q.calm_since or game.tick
        if game.tick - q.calm_since >= CALM_AFTER then
          q.state = "walking"
          go(e, centre, 10, defines.distraction.none)
          release_escorts(c, q, centre)
          api.log(id, "queen_home", "")
        end
      end
      for _, unit in pairs(q.escorts) do
        if unit.valid and dist2(unit.position, e.position) > ESCORT_NEAR * ESCORT_NEAR then
          local cmd = unit.commandable.command
          if not (cmd and cmd.type == defines.command.attack) then go(unit, e.position, 4) end
        end
      end
    end
  end
end

-- Every check, for a territory at war: on / off the map, arrivals, strays, queens.
function core.tick(surface, id, centre, chars, forces)
  local c = core.get(id)
  local seen = near_any(chars, centre, WAKE)
  if not seen then
    local chunk = {x = math.floor(centre.x / 32), y = math.floor(centre.y / 32)}
    for _, force in pairs(forces) do if force.is_chunk_visible(surface, chunk) then seen = true break end end
  end
  if c.g.units then
    if seen then c.g.idle_since = nil
    else
      c.g.idle_since = c.g.idle_since or game.tick
      if game.tick - c.g.idle_since >= DESPAWN_AFTER then hide(c) end
    end
  elseif seen then
    show(surface, c, centre)
  end
  for k, unit in pairs(c.incoming) do
    if not unit.valid then c.incoming[k] = nil
    elseif dist2(unit.position, centre) <= ARRIVE * ARRIVE then
      c.incoming[k] = nil
      c.made = c.made + 1
      if c.g.units then
        c.g.units[k] = unit
        post(unit)
      else
        c.g.count = c.g.count + 1
        unit.destroy()
      end
    elseif not walking(unit, centre) then
      local cmd = unit.commandable.command
      if not (cmd and cmd.type == defines.command.attack) then go(unit, centre, 10) end
    end
  end
  if c.g.units then
    for _, unit in pairs(c.g.units) do
      if unit.valid and dist2(unit.position, centre) > STRAY * STRAY and not walking(unit, centre) then
        local cmd = unit.commandable.command
        if not (cmd and cmd.type == defines.command.attack) then go(unit, post_position(centre), 4) end
      end
    end
  end
  run_queens(surface, id, c, centre, chars)
  core.sync(id)
end

-- Is unit part of a core (free, incoming, escort or a queen)?
function core.owns(unit)
  init_storage()
  local k = unit.unit_number
  for _, c in pairs(storage.cores) do
    if (c.g.units and c.g.units[k]) or c.incoming[k] or c.queens[k] then return true end
    for _, q in pairs(c.queens) do if q.escorts and q.escorts[k] then return true end end
  end
  return false
end

-- The war ended: units join the given garrison table (or stay where they are), queens go back into the hearts.
function core.dissolve(id, join)
  init_storage()
  local c = storage.cores[id]
  if not c then return end
  local function hand(unit) if unit.valid then join(unit) end end
  for _, unit in pairs(c.g.units or {}) do hand(unit) end
  for _, unit in pairs(c.incoming) do hand(unit) end
  for _, q in pairs(c.queens) do
    for _, unit in pairs(q.escorts or {}) do hand(unit) end
    if q.entity.valid and q.state ~= "army" then q.entity.destroy() end
  end
  storage.cores[id] = nil
end

function core.describe(id)
  init_storage()
  local c = storage.cores[id]
  if not c then return "no core" end
  local states = {}
  for _, q in pairs(c.queens) do
    if q.entity.valid then states[q.state] = (states[q.state] or 0) + 1 end
  end
  local list = {}
  for s, n in pairs(states) do list[#list + 1] = n .. " " .. s end
  core.sync(id)
  return string.format("core %d free (%s; reserve %d, raid %d, retake %d), %d incoming, queens: %s", core.free(id),
    c.g.units and "on map" or "kept", c.funds.reserve, c.funds.raid, c.funds.retake, core.incoming(id), #list > 0 and table.concat(list, ", ") or "none")
end

-- Telemetry row values: free, incoming, escorts + queens home / walking / flee / army, funds.
function core.stats(id)
  local c = core.get(id)
  local s = {home = 0, walking = 0, flee = 0, army = 0, escorts = 0}
  for _, q in pairs(c.queens) do
    if q.entity.valid then
      s[q.state] = s[q.state] + 1
      s.escorts = s.escorts + alive(q.escorts or {})
    end
  end
  core.sync(id)
  return core.free(id), core.incoming(id), s, c.funds
end

return core
