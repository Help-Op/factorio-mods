-- Hive AI, operational layer (ring2-challenge-plan.md 4e2, 4e2b, 4e2c; R2-D36-D41; ring-feel-plan.md RF-D15, D16,
-- D19, D30, D34, D35, D38, D50). Armies of two kinds: a retake army (with an elder queen) and a raid (4e2c, was the
-- 4e2b wave; no queen: it only destroys). A territory has at most one of each out at a time. war.lua decides when one
-- goes and hands it its units (from the core garrison's funds, core.lua) and the queen (from the reserve); this
-- module runs it:
--   mass:    the units walk to a spot next to the brain (war.lua picks it) and wait there until mass_until.
--   march:   every unit walks to the fallen heart spot; they fight back only when hit (distraction by_damage), so
--            decoys on the way don't pull them off. Leash: a unit more than CHASE tiles off the route goes back to it
--            without distraction, and is free again once within CHASE / 2.
--   retake:  most units at the spot → every unit attacks the nearest player building within HOLD_RADIUS of it, until
--            none is left. Then the elder queen walks to the spot and settles (war.lua rebuilds the heart, wakes the
--            nests; the survivors become the garrison).
--   attack:  (raid) most units at the target → every unit attacks the nearest player building within HOLD_RADIUS or
--            participant within HUNT of it; none left → the survivors walk home to the core.
--   retreat: (retake) fewer than half the start size alive or the elder queen dead, (raid) fewer than RAID_RETREAT of
--            it → the survivors walk back to the core; a living queen goes back to the reserve.
-- Telemetry: an army CSV (ht-telemetry/<tick>-t<id>-army.csv or -raid.csv, one row per SAMPLE), events in the war log.
-- storage.armies["<territory id>/<kind>"] = {id, key, kind = "retake" | "raid", state, slot (target district, nil for a
--   raid on buildings outside one), target, spot, mass_until, started_tick, start_size,
--   units = {[unit_number] = {entity, from (slot)}}, queen, leashed = {[unit_number] = true}, file, rows, kills}

local influence = require("scripts.influence")

local hive = {}

hive.HOLD_RADIUS = 40
local CHASE = 30
local ARRIVE = 30
local SETTLE = 12
local SAMPLE = 60
local STUCK = 10 * 60
local LOST = 30 * 60
local MASS_STRAY = 25
local HUNT = 60
local RAID_RETREAT = 0.25

local api -- war.lua's callbacks: log(id, event, slot, detail), retaken(surface, id, slot, units), rejoin(id, unit)
-- (back to the core), queen_back(id, queen), queen_used(id, queen), done(id, kind, outcome)

function hive.connect(callbacks) api = callbacks end

local function init_storage()
  storage.armies = storage.armies or {}
  local old = {}
  for k, army in pairs(storage.armies) do if not army.key then old[k] = army end end
  for k, army in pairs(old) do -- (older saves: one army per territory id, waves)
    do
      storage.armies[k] = nil
      army.id = army.id or k
      if army.kind == "wave" then army.kind = "raid" end
      army.kind = army.kind or "retake"
      army.key = army.id .. "/" .. army.kind
      storage.armies[army.key] = army
    end
  end
end

local function dist2(a, b) return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 end

-- Squared distance from p to the segment a-b.
local function seg_dist2(p, a, b)
  local dx, dy = b.x - a.x, b.y - a.y
  local l = dx * dx + dy * dy
  local t = l > 0 and math.max(0, math.min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / l)) or 0
  return dist2(p, {x = a.x + t * dx, y = a.y + t * dy})
end

local function go(entity, destination, radius, distraction)
  entity.commandable.set_command{type = defines.command.go_to_location, destination = destination, radius = radius,
    distraction = distraction}
end

-- Units that finish or fail a command get one from the engine (wander, or a walk back into a spawner that removes
-- them: biters have allow_try_return_to_spawner), so "has a command" says nothing: is it walking to our target?
local function walking(entity, destination)
  local cmd = entity.commandable.command
  return cmd and cmd.type == defines.command.go_to_location and cmd.destination
    and dist2(cmd.destination, destination) < 1
end

local function alive(army)
  local n = 0
  for k, u in pairs(army.units) do
    if u.entity.valid then n = n + 1 else army.units[k], army.leashed[k] = nil, nil end
  end
  return n
end

-- Player buildings within HOLD_RADIUS of position (any of them holds a fallen district, RF-D19).
function hive.buildings(surface, position)
  local list = {}
  for _, force in pairs(game.forces) do
    if force.name == "player" or #force.players > 0 then
      for _, e in pairs(surface.find_entities_filtered{position = position, radius = hive.HOLD_RADIUS, force = force}) do
        if influence.is_building(e) then list[#list + 1] = e end
      end
    end
  end
  return list
end

local function nearest(list, position)
  local best, bd
  for _, e in pairs(list) do
    local q = dist2(e.position, position)
    if not bd or q < bd then best, bd = e, q end
  end
  return best
end

-- Start an army for territory id. units = {{entity, from}}, queen = the elder queen, slot / target = the fallen
-- district, spot = massing spot, mass = ticks to wait there.
function hive.start(id, kind, slot, target, spot, units, queen, mass)
  init_storage()
  local army = {id = id, key = id .. "/" .. kind, kind = kind, state = mass > 0 and "mass" or "march", slot = slot,
    target = target, spot = spot, mass_until = game.tick + mass, started_tick = game.tick, units = {}, leashed = {},
    queen = queen, rows = {}, kills = 0,
    file = string.format("ht-telemetry/%d-t%d-%s.csv", game.tick, id, kind == "raid" and "raid" or "army")}
  for _, u in pairs(units) do
    army.units[u.entity.unit_number] = u
    go(u.entity, mass > 0 and spot or target, 12, defines.distraction.by_damage)
  end
  army.start_size = alive(army)
  if queen then go(queen, spot, 6, defines.distraction.by_damage) end
  storage.armies[army.key] = army
  helpers.write_file(army.file, "second,state,alive,start,target_slot,distance,buildings,queen_hp\n", false)
  if kind == "raid" then
    api.log(id, "raid_start", slot, string.format("%d units to %d %d", army.start_size, target.x, target.y))
  else
    api.log(id, "army_mass", slot, string.format("%d units at %d %d, march in %d s", army.start_size, spot.x, spot.y,
      math.floor(mass / 60)))
  end
  return army
end

local function finish(id, army, outcome)
  helpers.write_file(army.file, string.format("# outcome=%s duration_s=%d start=%d alive=%d\n", outcome,
    math.floor((game.tick - army.started_tick) / 60), army.start_size, alive(army)), true)
  storage.armies[army.key] = nil
  api.done(id, army.kind, outcome)
end

local function retreat(id, army, why)
  local n = 0
  for _, u in pairs(army.units) do
    if u.entity.valid then
      n = n + 1
      api.rejoin(id, u.entity)
    end
  end
  if army.queen and army.queen.valid then api.queen_back(id, army.queen)
  elseif army.queen then api.queen_used(id, army.queen) end
  api.log(id, army.kind == "raid" and "raid_retreat" or "army_retreat", army.slot,
    string.format("%s, %d of %d back", why, n, army.start_size))
  finish(id, army, "retreat")
end

-- Leash on the march: off the route by more than CHASE → back to it, undistracted.
local function leash(army, unit, k, from, to)
  local d2 = seg_dist2(unit.position, from, to)
  if army.leashed[k] then
    if d2 <= (CHASE / 2) ^ 2 then
      army.leashed[k] = nil
      go(unit, army.target, 10, defines.distraction.by_damage)
    end
  elseif d2 > CHASE * CHASE then
    army.leashed[k] = true
    go(unit, army.target, 10, defines.distraction.none)
  elseif not walking(unit, army.target) then
    local cmd = unit.commandable.command
    if not (cmd and cmd.type == defines.command.attack) then go(unit, army.target, 10, defines.distraction.by_damage) end
  end
end

local function sample(army)
  if (game.tick - army.started_tick) % SAMPLE >= 30 then return end
  local n, sx, sy = 0, 0, 0
  for _, u in pairs(army.units) do
    if u.entity.valid then n, sx, sy = n + 1, sx + u.entity.position.x, sy + u.entity.position.y end
  end
  local distance = n > 0 and math.sqrt(dist2({x = sx / n, y = sy / n}, army.target)) or -1
  army.rows[#army.rows + 1] = string.format("%d,%s,%d,%d,%d,%.0f,%d,%.0f", math.floor((game.tick - army.started_tick) / 60),
    army.state, n, army.start_size, army.slot or 0, distance, army.buildings or -1,
    army.queen and army.queen.valid and army.queen.health or 0)
  if #army.rows >= 30 then
    helpers.write_file(army.file, table.concat(army.rows, "\n") .. "\n", true)
    army.rows = {}
  end
end

local function flush(army)
  if #army.rows > 0 then helpers.write_file(army.file, table.concat(army.rows, "\n") .. "\n", true) end
  army.rows = {}
end

-- Raid: attack what's at the target; nothing left → home.
local function run_raid(surface, id, army, chars, n)
  local targets = hive.buildings(surface, army.target)
  local buildings = #targets
  for _, c in pairs(chars) do
    if dist2(c.position, army.target) <= HUNT * HUNT then targets[#targets + 1] = c end
  end
  if army.buildings and buildings < army.buildings then
    for _ = 1, army.buildings - buildings do api.log(id, "building_killed", army.slot, "raid") end
  end
  army.buildings = buildings
  if #targets > 0 then
    for _, u in pairs(army.units) do
      local unit = u.entity
      local cmd = unit.commandable.command
      if not (u.target and u.target.valid and cmd and cmd.type == defines.command.attack) then
        u.target = nearest(targets, unit.position)
        unit.commandable.set_command{type = defines.command.attack, target = u.target, distraction = defines.distraction.by_enemy}
      end
    end
    return
  end
  flush(army)
  for _, u in pairs(army.units) do api.rejoin(id, u.entity) end
  api.log(id, "raid_done", army.slot, string.format("%d of %d back", n, army.start_size))
  finish(id, army, "done")
end

local function run(surface, id, army, chars)
  local n = alive(army)
  local retake = army.kind ~= "raid"
  if retake and not army.queen.valid then
    flush(army)
    api.queen_used(id, army.queen)
    return retreat(id, army, "elder queen dead")
  end
  if n == 0 then flush(army) return retreat(id, army, "all dead") end
  if army.state ~= "mass" then
    if retake and n < army.start_size / 2 then flush(army) return retreat(id, army, "below half") end
    if not retake and n < army.start_size * RAID_RETREAT then flush(army) return retreat(id, army, "below a quarter") end
  end
  sample(army)
  if army.state == "mass" then
    -- anyone who wandered off the spot (or lost his walk there) goes back
    for _, u in pairs(army.units) do
      if dist2(u.entity.position, army.spot) > MASS_STRAY * MASS_STRAY and not walking(u.entity, army.spot) then
        go(u.entity, army.spot, 12, defines.distraction.by_damage)
      end
    end
    if game.tick >= army.mass_until then
      army.state = "march"
      for _, u in pairs(army.units) do go(u.entity, army.target, 10, defines.distraction.by_damage) end
      if army.queen then go(army.queen, army.target, 6, defines.distraction.none) end
      api.log(id, "army_march", army.slot, string.format("%d units", n))
    end
    return
  end
  local near = 0
  for k, u in pairs(army.units) do
    local unit = u.entity
    if dist2(unit.position, army.target) <= ARRIVE * ARRIVE then near = near + 1 end
    if army.state == "march" then leash(army, unit, k, army.spot, army.target) end
  end
  if not retake then
    if army.state == "march" and near * 2 >= n then
      army.state = "attack"
      api.log(id, "raid_arrive", army.slot, string.format("%d units", n))
    end
    if army.state == "attack" then return run_raid(surface, id, army, chars, n) end
    return
  end
  if not walking(army.queen, army.target) then go(army.queen, army.target, SETTLE, defines.distraction.none) end
  -- the elder queen's progress: no step closer for LOST outside ARRIVE → she can't get there, the army goes home
  local qd = dist2(army.queen.position, army.target)
  if not army.queen_best or qd < army.queen_best - 1 then army.queen_best, army.queen_tick = qd, game.tick end
  if qd > ARRIVE * ARRIVE and game.tick - army.queen_tick >= LOST then
    flush(army)
    return retreat(id, army, string.format("elder queen stuck %.0f tiles out", math.sqrt(qd)))
  end
  if army.state == "march" and near * 2 >= n then
    army.state = "retake"
    api.log(id, "army_arrive", army.slot, string.format("%d units", n))
  end
  if army.state ~= "retake" then return end
  local buildings = hive.buildings(surface, army.target)
  if army.buildings and #buildings < army.buildings then
    for _ = 1, army.buildings - #buildings do api.log(id, "building_killed", army.slot, "") end
  end
  army.buildings = #buildings
  if #buildings > 0 then
    -- a new attack only when the unit's building is gone or it dropped the command (re-issuing every check resets
    -- its path; biters whose commands keep failing are removed by the engine)
    for _, u in pairs(army.units) do
      local unit = u.entity
      local cmd = unit.commandable.command
      if not (u.target and u.target.valid and cmd and cmd.type == defines.command.attack) then
        u.target = nearest(buildings, unit.position)
        unit.commandable.set_command{type = defines.command.attack, target = u.target, distraction = defines.distraction.by_enemy}
      end
    end
    return
  end
  -- nothing of yours left: the elder queen settles, at the spot or (blocked by the nest ring or units) once she
  -- stops getting closer within ARRIVE
  local stuck = qd <= ARRIVE * ARRIVE and game.tick - army.queen_tick >= STUCK
  if qd <= SETTLE * SETTLE or stuck then
    local units = {}
    for _, u in pairs(army.units) do units[#units + 1] = u.entity end
    army.queen.destroy()
    api.queen_used(id, army.queen)
    flush(army)
    api.log(id, "queen_settled", army.slot, string.format("%d units stay, queen %.0f tiles from the spot%s", #units,
      math.sqrt(qd), stuck and " (stuck)" or ""))
    api.retaken(surface, id, army.slot, units)
    finish(id, army, "retaken")
  else
    for _, u in pairs(army.units) do
      if not walking(u.entity, army.target) then go(u.entity, army.target, 15, defines.distraction.by_enemy) end
    end
  end
end

function hive.on_tick(surface, chars)
  init_storage()
  for _, army in pairs(storage.armies) do run(surface, army.id, army, chars or {}) end
end

-- Is unit part of a retake army (attacks.lua must not cancel it)?
function hive.owns(unit)
  init_storage()
  for _, army in pairs(storage.armies) do
    if army.units[unit.unit_number] or (army.queen and army.queen.valid and army.queen == unit) then return true end
  end
  return false
end

-- The territory's army of a kind ("raid" / "retake"), or nil.
function hive.army(id, kind)
  init_storage()
  return storage.armies[id .. "/" .. kind]
end

-- The war ended another way (brain dead): its armies just stop.
function hive.cancel(id)
  init_storage()
  for key, army in pairs(storage.armies) do
    if army.id == id then
      flush(army)
      if army.queen and army.queen.valid then army.queen.destroy() end
      storage.armies[key] = nil
    end
  end
end

function hive.describe()
  init_storage()
  local parts = {}
  for _, army in pairs(storage.armies) do
    parts[#parts + 1] = string.format("territory %d: %s %s to district %d [gps=%d,%d], %d of %d alive, queen %s", army.id,
      army.kind or "retake", army.state, army.slot or 0, army.target.x, army.target.y, alive(army), army.start_size,
      not army.queen and "none" or army.queen.valid and string.format("%.0f HP", army.queen.health) or "dead")
  end
  return "Armies: " .. (#parts > 0 and table.concat(parts, "; ") or "none") .. "."
end

return hive
