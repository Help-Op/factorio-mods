-- Challenge waves: enemies spawned around participants, scaled by ring (distance from spawn) and evolution.
-- Ring 0 (challenge-feel-plan.md E1) is different: enemies come out of the brain base's nests, in phases.
--   siege (E9): the challenge started because the player attacked the base, not the brain yet. Small groups every
--   RING0.siege_interval, shrinking with the share of nests alive. Ends when the brain is engaged (waves.wake).
--   wake: from the start, a group every RING0.interval, split over the living nests. The group shrinks with the
--   share of nests still alive (all nests dead = no more groups).
--   swarm (was "climax" until E8): once the brain is below RING0.swarm_at of its health, RING0.swarm_total units,
--   RING0.swarm_per_check per challenge check. No nest left → they come out at the brain. Only small biters:
--   no evolution upgrade, no slow.
--   Surround (E4/E5): every swarm unit has its own point on a ring around the target (flank_min..flank_max tiles;
--   angles spread over the target's sides and back, seen from the brain). It gets there on a wide detour at
--   detour_radius: units for the back half go to the target's side first, then to their angle, then in to the
--   ring point, then attack. Waypoints are fixed at spawn. A unit whose run fails attacks straight away
--   (storage.flankers).
--   Guards (E7): every guard_every-th of those units is a guard instead: it runs to a spot between the brain and the
--   target and holds there for guard_hold (attacking if the target comes close), then attacks. They can't block
--   bullets, but they put bodies in the line of fire, so auto-targeting picks them before the brain.
--   last stand (E6): once the swarm is out, a surround group every RING0.last_stand_interval until the brain dies,
--   shrinking with the share of nests still alive like the wake groups.
-- Per challenge record: ring, origin (guardian head at start), next_wave_tick, spawned = {[unit_number] = entity};
-- ring 0 also: phase ("siege" / "wake" / "swarm"), swarm_left, swarm_index, next_last_stand_tick, nests_start.
-- storage.fleeing[unit_number] = {entity, until_tick}: leftovers of a won challenge running to another territory.
-- storage.flankers[unit_number] = {entity, target}: swarm units on their way to a flank point.

local waves = {}

local SPAWN_MIN, SPAWN_MAX = 40, 50
local FIRST_WAVE_DELAY = 2 * 60
local FLEE_TIMEOUT = 60 * 60

-- units: picked uniformly per spawned unit.
local RINGS = {
  [1] = {units = {"ht-tiny-biter", "small-biter"}, slow = 40, wave = 5, interval = 8 * 60, max_alive = 25},
  [2] = {units = {"small-biter", "small-spitter"}, slow = 30, wave = 8, interval = 8 * 60, max_alive = 40},
  [3] = {units = {"small-biter", "medium-biter", "small-spitter"}, slow = 20, wave = 12, interval = 6 * 60, max_alive = 60},
}

-- One tier up, with chance = evolution factor.
local RING0 = {
  unit = "small-biter",
  siege_min = 4, siege_max = 7, siege_interval = 10 * 60, siege_max_alive = 30, -- E9 (PT8)
  wave_min = 11, wave_max = 17, interval = 8 * 60, max_alive = 70, -- E6 (PT5); was 9–15/60 (E5), 7–13/50, 5–10/40
  swarm_at = 0.6, swarm_total = 250, swarm_per_check = 12, -- per 30-tick check: 250 in ~10 s; at 60 % since E8 (PT7)
  flank_min = 12, flank_max = 18, -- ring around the target that swarm units run to first
  flank_arc = 270, -- degrees of that ring, centred on the target's back (the front faces the brain)
  detour_radius = 35, -- E5 (PT4): the wide way round, so the swarm doesn't cut past the target's front
  guard_every = 3, -- E7 (PT6): every 3rd swarm / last-stand unit guards the brain's front
  guard_min = 5, guard_max = 10, guard_spread = 6, -- tiles from the brain towards the target, ± sideways
  guard_hold = 10 * 60,
  last_stand_group = 5, last_stand_interval = 2 * 60, last_stand_max_alive = 120, -- E9 (PT8): steadier; was 12 / 4 s (E8), 10 / 4 s (E6)
  nest_radius = 25, -- brain.lua BASE_RADIUS: reach of a brain base
}

local UPGRADE = {
  ["ht-tiny-biter"] = "small-biter",
  ["small-biter"] = "medium-biter",
  ["small-spitter"] = "medium-spitter",
}

local function ring_settings(record)
  return RINGS[math.min(record.ring, 3)]
end

local function count_alive(record)
  local alive = 0
  for unit_number, entity in pairs(record.spawned) do
    if entity.valid then alive = alive + 1 else record.spawned[unit_number] = nil end
  end
  return alive
end

-- Ring (ring-layout-plan.md R1): the grid layer of the cell holding position, counted from the 4 cells that meet at
-- the map origin (ring 0 = those 4: the territories touching the safe zone). Same as hostile_point_ring in
-- nauvis-territory.lua (G must match). Was floor(distance from spawn / 500) before R1.
local G = 384
local function layer(i) return i >= 0 and i or -i - 1 end
function waves.ring_at(surface, position)
  return math.max(layer(math.floor(position.x / G)), layer(math.floor(position.y / G)))
end

-- phase: ring 0's first phase, "siege" or "wake" (default)
function waves.init(record, surface, origin, phase)
  record.ring = waves.ring_at(surface, origin)
  record.origin = {x = origin.x, y = origin.y}
  record.next_wave_tick = game.tick + FIRST_WAVE_DELAY
  record.spawned = {}
  if record.ring == 0 then
    record.phase = phase or "wake"
    record.nests_start = #surface.find_entities_filtered{position = record.origin, radius = RING0.nest_radius,
      type = "unit-spawner", force = "enemy"}
  end
end

local function pick_unit(settings, evolution)
  local name = settings.units[math.random(#settings.units)]
  if UPGRADE[name] and math.random() < evolution then name = UPGRADE[name] end
  return name
end

local function spawn_unit(surface, name, center, slow, target)
  local angle = math.random() * 2 * math.pi
  local distance = SPAWN_MIN + math.random() * (SPAWN_MAX - SPAWN_MIN)
  local wanted = {x = center.x + math.cos(angle) * distance, y = center.y + math.sin(angle) * distance}
  if not surface.is_chunk_generated({x = math.floor(wanted.x / 32), y = math.floor(wanted.y / 32)}) then return nil end
  local position = surface.find_non_colliding_position(name, wanted, 8, 0.5)
  if not position then return nil end
  local unit = surface.create_entity{name = name, position = position, force = "enemy"}
  if not unit then return nil end
  surface.create_entity{name = "ht-challenge-slow-" .. slow, position = position, target = unit}
  unit.commandable.set_command{type = defines.command.attack, target = target, distraction = defines.distraction.by_enemy}
  return unit
end

local function notify(record, message)
  for index in pairs(record.players) do
    local player = game.get_player(index)
    if player and player.connected then player.print(message) end
  end
end

-- Lowest health share of the territory's brains (1 if none is found).
local function brain_health(record)
  local territory_record = storage.territories[record.territory_id]
  local share = 1
  if territory_record and territory_record.territory.valid then
    for _, unit in pairs(territory_record.territory.get_segmented_units()) do
      if unit.valid then share = math.min(share, unit.health / unit.max_health) end
    end
  end
  return share
end

local function living_nests(record, surface)
  return surface.find_entities_filtered{position = record.origin, radius = RING0.nest_radius,
    type = "unit-spawner", force = "enemy"}
end

local function attack_command(target)
  return {type = defines.command.attack, target = target, distraction = defines.distraction.by_enemy}
end

-- Route of swarm unit number `index`: waypoints of the wide detour, then its point on the ring around the target.
-- Angles step by the golden ratio over flank_arc, so any run of units spreads evenly; 0° is the target's back (away
-- from the brain). Waypoints that don't fit (water, cliffs) are left out.
local GOLDEN = 0.6180339887
local function flank_route(record, surface, target, index)
  local t = target.position
  local back = math.atan2(t.y - record.origin.y, t.x - record.origin.x)
  local offset = math.rad(RING0.flank_arc) * ((index * GOLDEN) % 1 - 0.5)
  local function at(angle, radius)
    return surface.find_non_colliding_position(RING0.unit,
      {t.x + math.cos(back + angle) * radius, t.y + math.sin(back + angle) * radius}, 6, 1)
  end
  local route = {}
  if math.abs(offset) < math.pi / 2 then
    route[#route + 1] = at(offset < 0 and -math.pi / 2 or math.pi / 2, RING0.detour_radius)
  end
  route[#route + 1] = at(offset, RING0.detour_radius)
  route[#route + 1] = at(offset, RING0.flank_min + math.random() * (RING0.flank_max - RING0.flank_min))
  return route
end

-- Commands of a guard: a spot between the brain and the target, hold there, then attack.
local function guard_commands(record, surface, target)
  local t = target.position
  local dx, dy = t.x - record.origin.x, t.y - record.origin.y
  local length = math.max(math.sqrt(dx * dx + dy * dy), 1)
  dx, dy = dx / length, dy / length
  local ahead = RING0.guard_min + math.random() * (RING0.guard_max - RING0.guard_min)
  local side = (math.random() * 2 - 1) * RING0.guard_spread
  local spot = surface.find_non_colliding_position(RING0.unit,
    {record.origin.x + dx * ahead - dy * side, record.origin.y + dy * ahead + dx * side}, 6, 1)
  if not spot then return {} end
  return {
    {type = defines.command.go_to_location, destination = spot, radius = 2, distraction = defines.distraction.none},
    {type = defines.command.wander, radius = 3, ticks_to_wait = RING0.guard_hold, distraction = defines.distraction.by_enemy},
  }
end

-- Spawns count biters out of the given nests (round robin), at the brain if there are none.
-- With surround, each runs its own flank route first (no distractions) or guards the brain (E7), then attacks.
local function spawn_from_nests(record, surface, nests, count, target, surround)
  local first = math.random(math.max(#nests, 1))
  for i = 1, count do
    local nest = nests[(first + i - 2) % math.max(#nests, 1) + 1]
    local from = nest and nest.position or record.origin
    local position = surface.find_non_colliding_position(RING0.unit, from, 10, 0.5)
    local unit = position and surface.create_entity{name = RING0.unit, position = position, force = "enemy"}
    local commands = {}
    if unit and surround then
      record.swarm_index = (record.swarm_index or 0) + 1
      if record.swarm_index % RING0.guard_every == 0 then
        commands = guard_commands(record, surface, target)
      else
        for _, waypoint in ipairs(flank_route(record, surface, target, record.swarm_index)) do
          commands[#commands + 1] = {type = defines.command.go_to_location, destination = waypoint, radius = 4,
            distraction = defines.distraction.none}
        end
      end
    end
    if unit then
      if #commands > 0 then
        commands[#commands + 1] = attack_command(target)
        unit.commandable.set_command{type = defines.command.compound, structure_type = defines.compound_command.return_last,
          commands = commands}
        storage.flankers = storage.flankers or {}
        storage.flankers[unit.unit_number] = {entity = unit, target = target}
      else
        unit.commandable.set_command(attack_command(target))
      end
      record.spawned[unit.unit_number] = unit
    end
  end
end

-- Siege -> wake: the brain is engaged now.
function waves.wake(record)
  if record.phase ~= "siege" then return end
  record.phase = "wake"
  record.next_wave_tick = game.tick + FIRST_WAVE_DELAY
  notify(record, "The brain wakes!")
end

local function update_ring0(record, surface, targets, alive)
  if record.phase == "climax" then -- before E8
    record.phase, record.swarm_left, record.swarm_index = "swarm", record.climax_left, record.climax_index
  end
  if record.phase ~= "swarm" and brain_health(record) < RING0.swarm_at then
    record.phase = "swarm"
    record.swarm_left = RING0.swarm_total
    notify(record, "The hive swarms!")
  end
  if #targets == 0 then return end
  local target = targets[math.random(#targets)].entity
  if record.phase == "swarm" then
    if record.swarm_left > 0 then
      local count = math.min(RING0.swarm_per_check, record.swarm_left)
      record.swarm_left = record.swarm_left - count
      spawn_from_nests(record, surface, living_nests(record, surface), count, target, true)
      if record.swarm_left == 0 then record.next_last_stand_tick = game.tick + RING0.last_stand_interval end
    elseif game.tick >= (record.next_last_stand_tick or 0) then
      record.next_last_stand_tick = game.tick + RING0.last_stand_interval
      local nests = living_nests(record, surface)
      local share = #nests / math.max(record.nests_start or #nests, 1)
      local group = math.min(math.floor(RING0.last_stand_group * share + 0.5), RING0.last_stand_max_alive - alive)
      if group > 0 then spawn_from_nests(record, surface, nests, group, target, true) end
    end
    return
  end
  if game.tick < record.next_wave_tick then return end
  local siege = record.phase == "siege"
  record.next_wave_tick = game.tick + (siege and RING0.siege_interval or RING0.interval)
  local nests = living_nests(record, surface)
  local share = #nests / math.max(record.nests_start or #nests, 1)
  local size = siege and math.random(RING0.siege_min, RING0.siege_max) or math.random(RING0.wave_min, RING0.wave_max)
  local cap = siege and RING0.siege_max_alive or RING0.max_alive
  local count = math.min(math.floor(size * share + 0.5), cap - alive)
  if count > 0 then spawn_from_nests(record, surface, nests, count, target) end
end

-- targets: array of {player, entity} for participants near the guardian. Spawns a wave when it's due.
function waves.update(record, surface, targets)
  if not record.ring then return end -- challenge from before phase C
  local alive = count_alive(record)
  if record.ring == 0 then
    record.phase = record.phase or "wake" -- ring-0 challenge from before E1
    return update_ring0(record, surface, targets, alive)
  end
  if #targets == 0 or game.tick < record.next_wave_tick then return end
  local settings = ring_settings(record)
  record.next_wave_tick = game.tick + settings.interval
  local chosen = targets[math.random(#targets)]
  local evolution = game.forces.enemy.get_evolution_factor(surface)
  local count = math.min(settings.wave, settings.max_alive - alive)
  for _ = 1, count do
    local unit = spawn_unit(surface, pick_unit(settings, evolution), chosen.player.character.position,
      settings.slow, chosen.entity)
    if unit then record.spawned[unit.unit_number] = unit end
  end
end

function waves.clear(record)
  for unit_number, entity in pairs(record.spawned or {}) do
    if storage.flankers then storage.flankers[unit_number] = nil end
    if entity.valid then entity.destroy() end
  end
  record.spawned = {}
end

-- Nearest guardian head of another guarded territory, or nil.
local function flee_destination(record)
  local best, best_distance
  for id, territory_record in pairs(storage.territories) do
    if id ~= record.territory_id and territory_record.territory.valid then
      for _, unit in pairs(territory_record.territory.get_segmented_units()) do
        local head = unit.valid and unit.segments[1]
        if head then
          local p = head.position
          local distance = (p.x - record.origin.x) ^ 2 + (p.y - record.origin.y) ^ 2
          if not best_distance or distance < best_distance then best, best_distance = p, distance end
        end
      end
    end
  end
  return best
end

-- Won: leftovers run to the nearest other guarded territory and are removed on arrival or after FLEE_TIMEOUT.
function waves.flee(record)
  if not record.spawned then return end
  local destination = record.origin and flee_destination(record)
  if not destination then
    waves.clear(record)
    return
  end
  storage.fleeing = storage.fleeing or {}
  for unit_number, entity in pairs(record.spawned) do
    if storage.flankers then storage.flankers[unit_number] = nil end
    if entity.valid then
      entity.commandable.set_command{type = defines.command.go_to_location, destination = destination,
        radius = 20, distraction = defines.distraction.none}
      storage.fleeing[unit_number] = {entity = entity, until_tick = game.tick + FLEE_TIMEOUT}
    end
  end
  record.spawned = {}
end

function waves.on_ai_command_completed(event)
  local flanker = storage.flankers and storage.flankers[event.unit_number]
  if flanker then
    storage.flankers[event.unit_number] = nil
    -- the run to the flank point failed (or the attack ended): attack again if the target is still there
    if event.result ~= defines.behavior_result.success and flanker.entity.valid and flanker.target.valid then
      flanker.entity.commandable.set_command(attack_command(flanker.target))
    end
    return
  end
  local fleeing = storage.fleeing and storage.fleeing[event.unit_number]
  if not fleeing then return end
  if fleeing.entity.valid then fleeing.entity.destroy() end
  storage.fleeing[event.unit_number] = nil
end

function waves.update_fleeing()
  for unit_number, flanker in pairs(storage.flankers or {}) do
    if not flanker.entity.valid then storage.flankers[unit_number] = nil end
  end
  if not storage.fleeing then return end
  for unit_number, fleeing in pairs(storage.fleeing) do
    if not fleeing.entity.valid then
      storage.fleeing[unit_number] = nil
    elseif game.tick >= fleeing.until_tick then
      fleeing.entity.destroy()
      storage.fleeing[unit_number] = nil
    end
  end
end

function waves.describe(record)
  if not record.ring then return "" end
  if record.ring == 0 then
    local function seconds(tick) return math.max(0, math.ceil(((tick or game.tick) - game.tick) / 60)) end
    local extra
    if record.phase ~= "swarm" then
      extra = string.format(", next group in %ds", seconds(record.next_wave_tick))
    elseif (record.swarm_left or 0) > 0 then
      extra = string.format(", swarm left %d", record.swarm_left)
    else
      extra = string.format(", last stand, next group in %ds", seconds(record.next_last_stand_tick))
    end
    return string.format(", ring 0, phase %s, brain %d%%, alive %d%s", record.phase or "wake",
      math.floor(brain_health(record) * 100), count_alive(record), extra)
  end
  return string.format(", ring %d, alive %d, next wave in %ds", record.ring, count_alive(record),
    math.max(0, math.ceil((record.next_wave_tick - game.tick) / 60)))
end

return waves
