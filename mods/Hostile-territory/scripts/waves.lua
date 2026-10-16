-- Challenge waves: enemies spawned around participants, scaled by ring (distance from spawn) and evolution.
-- Per challenge record: ring, origin (guardian head at start), next_wave_tick, spawned = {[unit_number] = entity}.
-- storage.fleeing[unit_number] = {entity, until_tick}: leftovers of a won challenge running to another territory.

local waves = {}

local RING_SIZE = 500
local SPAWN_MIN, SPAWN_MAX = 40, 50
local FIRST_WAVE_DELAY = 2 * 60
local FLEE_TIMEOUT = 60 * 60

-- units: picked uniformly per spawned unit.
local RINGS = {
  [0] = {units = {"ht-tiny-biter"}, slow = 50, wave = 3, interval = 10 * 60, max_alive = 15},
  [1] = {units = {"ht-tiny-biter", "small-biter"}, slow = 40, wave = 5, interval = 8 * 60, max_alive = 25},
  [2] = {units = {"small-biter", "small-spitter"}, slow = 30, wave = 8, interval = 8 * 60, max_alive = 40},
  [3] = {units = {"small-biter", "medium-biter", "small-spitter"}, slow = 20, wave = 12, interval = 6 * 60, max_alive = 60},
}

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

function waves.init(record, surface, origin)
  local spawn = game.forces.player.get_spawn_position(surface)
  local distance = math.sqrt((origin.x - spawn.x) ^ 2 + (origin.y - spawn.y) ^ 2)
  record.ring = math.floor(distance / RING_SIZE)
  record.origin = {x = origin.x, y = origin.y}
  record.next_wave_tick = game.tick + FIRST_WAVE_DELAY
  record.spawned = {}
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

-- targets: array of {player, entity} for participants near the guardian. Spawns a wave when it's due.
function waves.update(record, surface, targets)
  if not record.ring then return end -- challenge from before phase C
  local alive = count_alive(record)
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
  for _, entity in pairs(record.spawned or {}) do
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
    if entity.valid then
      entity.commandable.set_command{type = defines.command.go_to_location, destination = destination,
        radius = 20, distraction = defines.distraction.none}
      storage.fleeing[unit_number] = {entity = entity, until_tick = game.tick + FLEE_TIMEOUT}
    end
  end
  record.spawned = {}
end

function waves.on_ai_command_completed(event)
  local fleeing = storage.fleeing and storage.fleeing[event.unit_number]
  if not fleeing then return end
  if fleeing.entity.valid then fleeing.entity.destroy() end
  storage.fleeing[event.unit_number] = nil
end

function waves.update_fleeing()
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
  return string.format(", ring %d, alive %d, next wave in %ds", record.ring, count_alive(record),
    math.max(0, math.ceil((record.next_wave_tick - game.tick) / 60)))
end

return waves
