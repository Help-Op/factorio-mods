-- Challenge waves: enemies spawned around participants, scaled by ring (distance from spawn) and evolution.
-- Rings with an entry in PHASES (ring 0: challenge-feel-plan.md E1, ring 1: oil-ring-challenge-plan.md OR-E1) are
-- different: enemies come out of the brain base's nests, in phases. P below = PHASES[ring].
--   siege (E9): the challenge started because the player attacked the base, not the brain yet. Small groups every
--   P.siege_interval, shrinking with the share of nests alive. Ends when the brain is engaged (waves.wake).
--   wake: from the start, a group every P.interval, split over the living nests. The group shrinks with the
--   share of nests still alive (all nests dead = no more groups); with P.wake_from_brain (ring 1, OR-E10) it keeps
--   its size and comes out of the brain once the nests are dead.
--   swarm (was "climax" until E8): once the brain is below P.swarm_at of its health, P.swarm_total units,
--   P.swarm_per_check per challenge check. No nest left → they come out at the brain. Only P.unit:
--   no evolution upgrade, no slow.
--   Surround (E4/E5): every swarm unit has its own point on a ring around the target (flank_min..flank_max tiles;
--   angles spread over the target's sides and back, seen from the brain). It gets there on a wide detour at
--   detour_radius: units for the back half go to the target's side first, then to their angle, then in to the
--   ring point, then attack. Waypoints are fixed at spawn. A unit whose run fails attacks straight away
--   (storage.flankers).
--   Guards (E7): every guard_every-th of those units is a guard instead: it runs to a spot between the brain and the
--   target and holds there for guard_hold (attacking if the target comes close), then attacks. They can't block
--   bullets, but they put bodies in the line of fire, so auto-targeting picks them before the brain.
--   last stand (E6): once the swarm is out, a surround group every P.last_stand_interval until the brain dies,
--   shrinking with the share of nests still alive like the wake groups.
-- Per challenge record: ring, origin (guardian head at start), next_wave_tick, spawned = {[unit_number] = entity};
-- phased rings also: phase ("siege" / "wake" / "swarm"), swarm_left, swarm_index, next_last_stand_tick, nests_start;
-- with surges also surge, surge_mode, ring_units = {[unit_number] = entity} (encircle units for the director's
-- closing ring, OR-E6).
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
  slow = 20, -- OR-D22 (oil-ring-challenge-plan.md, PT3): every unit the phases spawn is 20 % slower (ht-challenge-slow-*)
}

-- base with the given fields replaced
local function with(base, changes)
  local copy = {}
  for key, value in pairs(base) do copy[key] = value end
  for key, value in pairs(changes) do copy[key] = value end
  return copy
end

-- Rings whose challenge runs in phases from the nests. Other rings use RINGS.
local PHASES = {
  [0] = RING0,
  -- oil-ring-challenge-plan.md OR-E1 (OR-D5): swarm ×3, siege / wake / last stand ×2; small biters only (OR-D6)
  [1] = with(RING0, {
    siege_min = 8, siege_max = 14, siege_max_alive = 60,
    wave_min = 22, wave_max = 34, max_alive = 140,
    swarm_per_check = 25,
    -- OR-D28 (PT4: the end was one long kite-and-shoot): three surges instead of one swarm, still 750 in total.
    -- surround: from the nests, flank routes + guards (as ring 0); encircle: from the nests to a full ring around you
    -- (ENCIRCLE_MIN..MAX tiles), then attack; frenzy: from then on the last stand is ×frenzy_last_stand and the
    -- brain's shockwave gets an extra pulse every FRENZY_PULSE ticks.
    surges = {
      {at = 0.8, total = 350, mode = "surround", message = "The hive swarms!"},
      {at = 0.55, total = 250, mode = "encircle", message = "The hive encircles you!"},
      -- BP-3 (OR-D102, PT20: the frenzy dealt 11 HP in 75 s): 150 → 250
      {at = 0.3, total = 250, mode = "surround", frenzy = true, message = "The brain goes into a frenzy!"},
    },
    -- BP-3 (OR-D102): ×2 → ×3; OR-D108: in the frenzy the last stand stops at frenzy_max_alive, not last_stand_max_alive
    -- (PT20: ~580 alive in the frenzy, mostly queen biters, so the 240 cap stopped the last stand completely)
    -- OR-D109 (PT22: 740–800 alive held the brain at 20 % for 50 s, no way through): 800 → 400
    frenzy_last_stand = 3, frenzy_max_alive = 400,
    last_stand_group = 10, last_stand_max_alive = 240,
    last_stand_from_brain = true, -- OR-D30: no nest share; with the nests dead they come out of the brain
    director = true, -- OR-E2 pressure director (director.lua); ring 0 open (Q6)
    -- OR-E6 (OR-D33–D38): squads instead of the holding ring (director.lua), the closing ring for encircle units,
    -- the brain's shield + openings, guard rush, stand-still punish, rocks (brain-fight.lua)
    squads = true,
    shield = 0.9, -- share of each hit refunded while the brain is shielded
    rock_walls = false, -- OR-D54 (PT7): one parameter too many for now; the arena (surge 2) stays
    wake_on_nest = true, -- OR-D55 (PT7): the first nest destroyed in the siege wakes the brain (its shockwave starts)
    queens = true, -- OR-E8 E8-B (OR-D78): nests release queens once one of them dies (brain-fight.lua)
    wake_from_brain = true, -- OR-E10 (OR-D84): wake groups keep their size; with the nests dead, out of the brain
    director_wake = true, -- OR-E10 (OR-D84): the director runs from the wake on (director.lua)
    stream = false, -- OR-E10 (OR-D85): a squad stream while you're calm (director.lua); off since OR-E11: queens are the stream
  }),
}
waves.PHASES = PHASES

-- Surges of a phased ring: its own list, or one swarm from swarm_at / swarm_total (ring 0).
local function surges(P)
  return P.surges or {{at = P.swarm_at, total = P.swarm_total, mode = "surround", message = "The hive swarms!"}}
end

local ENCIRCLE_MIN, ENCIRCLE_MAX = 16, 20
local FRENZY_PULSE = 20 * 60 -- the brain's own shockwave: every 20 s (update_effects_while_enraged)
-- OR-D107 (PT19: you shot the lured brain past 55 %, so the encircle surge came out round you with the sprung trap:
-- 102 touching, dead in 7 s): a surge whose threshold falls during a pull-back (record.regroup, director.lua) waits
-- until SURGE_AFTER_TRAP after the spring
local SURGE_AFTER_TRAP = 5 * 60
local PULSE_STAGES, PULSE_STEP = 30, 10 -- hf-earth-wyrm-small-expanding-ash-cloud-1..30, one every 10 ticks

-- One tier up, with chance = evolution factor.

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

-- phase: first phase of a phased ring, "siege" or "wake" (default)
function waves.init(record, surface, origin, phase)
  record.ring = waves.ring_at(surface, origin)
  record.origin = {x = origin.x, y = origin.y}
  record.next_wave_tick = game.tick + FIRST_WAVE_DELAY
  record.spawned = {}
  if PHASES[record.ring] then
    record.phase = phase or "wake"
    record.nests_start = #surface.find_entities_filtered{position = record.origin, radius = PHASES[record.ring].nest_radius,
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

waves.brain_health = brain_health
waves.count_alive = count_alive

local function living_nests(record, surface)
  return surface.find_entities_filtered{position = record.origin, radius = PHASES[record.ring].nest_radius,
    type = "unit-spawner", force = "enemy"}
end
waves.living_nests = living_nests

local function attack_command(target)
  return {type = defines.command.attack, target = target, distraction = defines.distraction.by_enemy}
end

-- Route of swarm unit number `index`: waypoints of the wide detour, then its point on the ring around the target.
-- Angles step by the golden ratio over flank_arc, so any run of units spreads evenly; 0° is the target's back (away
-- from the brain). Waypoints that don't fit (water, cliffs) are left out.
local GOLDEN = 0.6180339887
local function flank_route(record, surface, target, index)
  local P = PHASES[record.ring]
  local t = target.position
  local back = math.atan2(t.y - record.origin.y, t.x - record.origin.x)
  local offset = math.rad(P.flank_arc) * ((index * GOLDEN) % 1 - 0.5)
  local function at(angle, radius)
    return surface.find_non_colliding_position(P.unit,
      {t.x + math.cos(back + angle) * radius, t.y + math.sin(back + angle) * radius}, 6, 1)
  end
  local route = {}
  if math.abs(offset) < math.pi / 2 then
    route[#route + 1] = at(offset < 0 and -math.pi / 2 or math.pi / 2, P.detour_radius)
  end
  route[#route + 1] = at(offset, P.detour_radius)
  route[#route + 1] = at(offset, P.flank_min + math.random() * (P.flank_max - P.flank_min))
  return route
end

-- Commands of a guard: a spot between the brain and the target, hold there, then attack.
local function guard_commands(record, surface, target)
  local P = PHASES[record.ring]
  local t = target.position
  local dx, dy = t.x - record.origin.x, t.y - record.origin.y
  local length = math.max(math.sqrt(dx * dx + dy * dy), 1)
  dx, dy = dx / length, dy / length
  local ahead = P.guard_min + math.random() * (P.guard_max - P.guard_min)
  local side = (math.random() * 2 - 1) * P.guard_spread
  local spot = surface.find_non_colliding_position(P.unit,
    {record.origin.x + dx * ahead - dy * side, record.origin.y + dy * ahead + dx * side}, 6, 1)
  if not spot then return {} end
  return {
    {type = defines.command.go_to_location, destination = spot, radius = 2, distraction = defines.distraction.none},
    {type = defines.command.wander, radius = 3, ticks_to_wait = P.guard_hold, distraction = defines.distraction.by_enemy},
  }
end

-- Commands of the next surround unit: a flank route (E4/E5) or, every guard_every-th, a guard (E7).
local function surround_commands(record, surface, target)
  local P = PHASES[record.ring]
  record.swarm_index = (record.swarm_index or 0) + 1
  if record.swarm_index % P.guard_every == 0 then return guard_commands(record, surface, target) end
  local commands = {}
  for _, waypoint in ipairs(flank_route(record, surface, target, record.swarm_index)) do
    commands[#commands + 1] = {type = defines.command.go_to_location, destination = waypoint, radius = 4,
      distraction = defines.distraction.none}
  end
  return commands
end

-- commands, then attack the target (a flanker until then); no commands: attack straight away.
local function send(unit, commands, target)
  if #commands > 0 then
    commands[#commands + 1] = attack_command(target)
    unit.commandable.set_command{type = defines.command.compound, structure_type = defines.compound_command.return_last,
      commands = commands}
    storage.flankers = storage.flankers or {}
    storage.flankers[unit.unit_number] = {entity = unit, target = target}
  else
    unit.commandable.set_command(attack_command(target))
  end
end

-- Spawns count biters out of the given nests (round robin), at the brain if there are none.
-- With surround, each runs its own flank route first (no distractions) or guards the brain (E7), then attacks.
-- mode: nil (straight attack), "surround" (flank route or guard, E4/E7) or "encircle" (OR-D28: a point on a full ring
-- around the target, then attack). With P.squads (OR-E6) encircle units are left to the director's closing ring
-- (record.ring_units). Returns the spawned units.
local function spawn_from_nests(record, surface, nests, count, target, mode)
  local P = PHASES[record.ring]
  local first = math.random(math.max(#nests, 1))
  local spawned = {}
  for i = 1, count do
    local nest = nests[(first + i - 2) % math.max(#nests, 1) + 1]
    local from = nest and nest.position or record.origin
    local position = surface.find_non_colliding_position(P.unit, from, 10, 0.5)
    local unit = position and surface.create_entity{name = P.unit, position = position, force = "enemy"}
    if unit and P.slow then
      surface.create_entity{name = "ht-challenge-slow-" .. P.slow, position = position, target = unit}
    end
    local commands = {}
    if unit and mode == "encircle" and P.squads then
      record.ring_units = record.ring_units or {}
      record.ring_units[unit.unit_number] = unit
    elseif unit and mode == "encircle" then
      record.swarm_index = (record.swarm_index or 0) + 1
      local t = target.position
      local angle = 2 * math.pi * ((record.swarm_index * GOLDEN) % 1)
      local radius = ENCIRCLE_MIN + math.random() * (ENCIRCLE_MAX - ENCIRCLE_MIN)
      local spot = surface.find_non_colliding_position(P.unit,
        {t.x + math.cos(angle) * radius, t.y + math.sin(angle) * radius}, 6, 1)
      if spot then
        commands = {{type = defines.command.go_to_location, destination = spot, radius = 3,
          distraction = defines.distraction.none}}
      end
    elseif unit and mode == "surround" then
      commands = surround_commands(record, surface, target)
    end
    if unit then
      send(unit, commands, target)
      record.spawned[unit.unit_number] = unit
      spawned[#spawned + 1] = unit
    end
  end
  return spawned
end

waves.spawn_from = spawn_from_nests -- OR-E8 E8-B: queens and their escorts (brain-fight.lua)

-- Siege -> wake: the brain is engaged now.
function waves.wake(record)
  if record.phase ~= "siege" then return end
  record.phase = "wake"
  record.next_wave_tick = game.tick + FIRST_WAVE_DELAY
  notify(record, "The brain wakes!")
end

local function update_phased(record, surface, targets, alive)
  local P = PHASES[record.ring]
  if record.phase == "climax" then -- before E8
    record.phase, record.swarm_left, record.swarm_index = "swarm", record.climax_left, record.climax_index
  end
  -- next surge (OR-D28): the brain fell below its threshold
  local list = surges(P)
  if record.phase == "swarm" and not record.surge then record.surge = 1 end -- swarm from before OR-E5
  local next_surge = list[(record.surge or 0) + 1]
  local trap = record.regroup or game.tick < (record.trap_sprung_tick or -SURGE_AFTER_TRAP) + SURGE_AFTER_TRAP
  if next_surge and brain_health(record) < next_surge.at and not trap then
    record.phase = "swarm"
    record.surge = (record.surge or 0) + 1
    record.surge_mode = next_surge.mode
    record.swarm_left = (record.swarm_left or 0) + next_surge.total
    if next_surge.frenzy then
      record.frenzy = true
      record.next_pulse_tick = game.tick + FRENZY_PULSE / 2
    end
    notify(record, next_surge.message)
  end
  if #targets == 0 then return end
  local target = targets[math.random(#targets)].entity
  if record.phase == "swarm" then
    if record.frenzy and game.tick >= (record.next_pulse_tick or 0) then
      record.next_pulse_tick = game.tick + FRENZY_PULSE
      record.pulse_tick = game.tick -- waves.on_pulse_tick plays the stages
    end
    if record.swarm_left > 0 then
      local count = math.min(P.swarm_per_check, record.swarm_left)
      record.swarm_left = record.swarm_left - count
      spawn_from_nests(record, surface, living_nests(record, surface), count, target, record.surge_mode or "surround")
      if record.swarm_left == 0 then record.next_last_stand_tick = game.tick + P.last_stand_interval end
    elseif game.tick >= (record.next_last_stand_tick or 0) then
      record.next_last_stand_tick = game.tick + P.last_stand_interval
      local nests = living_nests(record, surface)
      local share = P.last_stand_from_brain and 1 or #nests / math.max(record.nests_start or #nests, 1)
      local size = P.last_stand_group * (record.frenzy and P.frenzy_last_stand or 1)
      local cap = record.frenzy and P.frenzy_max_alive or P.last_stand_max_alive
      local group = math.min(math.floor(size * share + 0.5), cap - alive)
      if group > 0 then spawn_from_nests(record, surface, nests, group, target, "surround") end
    end
    return
  end
  if game.tick < record.next_wave_tick then return end
  local siege = record.phase == "siege"
  record.next_wave_tick = game.tick + (siege and P.siege_interval or P.interval)
  local nests = living_nests(record, surface)
  local share = #nests / math.max(record.nests_start or #nests, 1)
  -- OR-E10 (OR-D84, PT13.2: the wake starved once the nests were dead): full size, out of the brain with no nest left
  if not siege and P.wake_from_brain then share = 1 end
  local size = siege and math.random(P.siege_min, P.siege_max) or math.random(P.wave_min, P.wave_max)
  local cap = siege and P.siege_max_alive or P.max_alive
  local count = math.min(math.floor(size * share + 0.5), cap - alive)
  if count > 0 then spawn_from_nests(record, surface, nests, count, target) end
end

-- targets: array of {player, entity} for participants near the guardian. Spawns a wave when it's due.
function waves.update(record, surface, targets)
  if not record.ring then return end -- challenge from before phase C
  local alive = count_alive(record)
  if PHASES[record.ring] then
    record.phase = record.phase or "wake" -- ring-0 challenge from before E1
    return update_phased(record, surface, targets, alive)
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

-- OR-D28 frenzy: plays the brain's expanding shockwave (the same stages its own pulse makes, one every PULSE_STEP
-- ticks) from the brain, with the brain as source (the stages' sticker areas need a valid origin). Every PULSE_STEP.
waves.PULSE_STEP = PULSE_STEP
function waves.on_pulse_tick()
  for _, records in pairs({storage.challenges or {}, storage.debug_waves or {}}) do
    for _, record in pairs(records) do
      if record.pulse_tick then
        local stage = math.floor((game.tick - record.pulse_tick) / PULSE_STEP) + 1
        if stage > PULSE_STAGES then
          record.pulse_tick = nil
        else
          local territory_record = storage.territories[record.territory_id]
          local unit = territory_record and territory_record.territory.valid and territory_record.territory.get_segmented_units()[1]
          local head = unit and unit.valid and unit.segments[1]
          if head then
            unit.surface.create_entity{name = "hf-earth-wyrm-small-expanding-ash-cloud-" .. stage,
              position = head.position, source = head.entity, force = "enemy"}
          end
        end
      end
    end
  end
end

function waves.describe(record)
  if not record.ring then return "" end
  if PHASES[record.ring] then
    local function seconds(tick) return math.max(0, math.ceil(((tick or game.tick) - game.tick) / 60)) end
    local extra
    if record.phase ~= "swarm" then
      extra = string.format(", next group in %ds", seconds(record.next_wave_tick))
    elseif (record.swarm_left or 0) > 0 then
      extra = string.format(", swarm left %d", record.swarm_left)
    else
      extra = string.format(", last stand, next group in %ds", seconds(record.next_last_stand_tick))
    end
    local surge = record.surge and string.format(" (surge %d%s)", record.surge, record.frenzy and ", frenzy" or "") or ""
    return string.format(", ring %d, phase %s%s, brain %d%%, alive %d%s", record.ring, record.phase or "wake", surge,
      math.floor(brain_health(record) * 100), count_alive(record), extra)
  end
  return string.format(", ring %d, alive %d, next wave in %ds", record.ring, count_alive(record),
    math.max(0, math.ceil((record.next_wave_tick - game.tick) / 60)))
end

return waves
