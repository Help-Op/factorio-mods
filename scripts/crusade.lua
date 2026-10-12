-- Crusade trigger: picks the target and works out what attacking it costs.
-- Target = the claimed territory furthest from the player force spawn (ties: random).
-- cost = BASE × (1 + distance / DISTANCE_STEP) × (1 + EVOLUTION_WEIGHT × evolution)
-- Distance = player force spawn to the territory centre (territories.centre).
-- Evolution from time and spawner kills also feeds storage.crusade_budget (EVOLUTION_POINTS per 1.0 evolution).
-- The pollution part is left out: it is already counted through cancelled attacks (attacks.lua).
-- storage.crusade_evolution_seen = time + spawner-kill evolution at the last check.
-- Trigger (every check): no cooldown, a target exists, budget >= cost and a staging nest exists
-- → spend the cost, mark the staging nest, announce it. No staging nest → no crusade, budget kept.
-- storage.crusade = {target_id, distance, cost, tick, staging_id, nest, nest_position, tag}.
-- Until phase G exists, a new crusade simply replaces the old one once the cooldown is over.

local territories = require("scripts.territories")
local staging = require("scripts.staging")

local crusade = {}

crusade.surface_name = "nauvis"

local BASE = 400
local DISTANCE_STEP = 500
local EVOLUTION_WEIGHT = 4
local EVOLUTION_POINTS = 10000

crusade.CHECK_INTERVAL = 60 * 60
local COOLDOWN = 15 * 60 * 60

local function distance_from_spawn(record, surface)
  local c = territories.centre(record)
  if not c then return nil end
  local spawn = game.forces.player.get_spawn_position(surface)
  return math.sqrt((c.x - spawn.x) ^ 2 + (c.y - spawn.y) ^ 2)
end

function crusade.cost(distance, evolution)
  return math.floor(BASE * (1 + distance / DISTANCE_STEP) * (1 + EVOLUTION_WEIGHT * evolution))
end

-- Returns record, distance of the furthest claimed territory, or nil if none is claimed.
function crusade.pick_target()
  local surface = game.surfaces[crusade.surface_name]
  if not surface then return nil end
  local best, best_distance = {}, nil
  for _, record in pairs(storage.territories or {}) do
    if record.state == "claimed" and record.territory.valid then
      local distance = distance_from_spawn(record, surface)
      if distance then
        if not best_distance or distance > best_distance + 0.5 then
          best, best_distance = {record}, distance
        elseif distance >= best_distance - 0.5 then
          best[#best + 1] = record
        end
      end
    end
  end
  if #best == 0 then return nil end
  return best[math.random(#best)], best_distance
end

local function budgeted_evolution()
  local enemy = game.forces.enemy
  return enemy.get_evolution_factor_by_time(crusade.surface_name)
    + enemy.get_evolution_factor_by_killing_spawners(crusade.surface_name)
end

-- Starts counting from the current evolution, so loading the mod into a running game adds no lump sum.
function crusade.init()
  if not game.surfaces[crusade.surface_name] then return end
  storage.crusade_evolution_seen = storage.crusade_evolution_seen or budgeted_evolution()
end

local function add_evolution_budget()
  local now = budgeted_evolution()
  local gained = now - (storage.crusade_evolution_seen or now)
  storage.crusade_evolution_seen = now
  if gained > 0 then
    storage.crusade_budget = (storage.crusade_budget or 0) + gained * EVOLUTION_POINTS
    storage.crusade_evolution_points = (storage.crusade_evolution_points or 0) + gained * EVOLUTION_POINTS
  end
end

local function try_trigger()
  if game.tick < (storage.crusade_cooldown_until or 0) then return end
  local target, distance = crusade.pick_target()
  if not target then return end
  local cost = crusade.cost(distance, game.forces.enemy.get_evolution_factor(crusade.surface_name))
  if (storage.crusade_budget or 0) < cost then return end
  local surface = game.surfaces[crusade.surface_name]
  local staging_record, nest = staging.pick(target, surface)
  if not staging_record then return end
  if storage.crusade then staging.unmark(storage.crusade) end
  storage.crusade_budget = storage.crusade_budget - cost
  storage.crusade = {target_id = target.id, distance = distance, cost = cost, tick = game.tick,
    staging_id = staging_record.id, nest = nest, nest_position = nest.position}
  staging.mark(storage.crusade, surface)
  storage.crusade_cooldown_until = game.tick + COOLDOWN
  game.forces.player.print(string.format("Crusade ready: the enemy targets territory %d (%d tiles from spawn) and gathers in territory %d. Cost %d, budget left %d.",
    target.id, math.floor(distance), staging_record.id, cost, storage.crusade_budget))
end

function crusade.on_tick()
  if not game.surfaces[crusade.surface_name] then return end
  add_evolution_budget()
  try_trigger()
end

function crusade.on_chunk_charted(event)
  if storage.crusade then staging.on_chunk_charted(storage.crusade, event) end
end

function crusade.describe()
  local evolution = game.forces.enemy.get_evolution_factor(crusade.surface_name)
  local lines = {string.format("Crusade budget: %d (%d from evolution). Evolution %.3f.",
    storage.crusade_budget or 0, storage.crusade_evolution_points or 0, evolution)}
  local target, distance = crusade.pick_target()
  if target then
    lines[#lines + 1] = string.format("Next target: territory %d, %d tiles from spawn, cost %d.",
      target.id, math.floor(distance), crusade.cost(distance, evolution))
    local staging_record, nest = staging.pick(target, game.surfaces[crusade.surface_name])
    if staging_record then
      lines[#lines + 1] = string.format("Next staging: territory %d, %s at %d,%d.",
        staging_record.id, nest.name, nest.position.x, nest.position.y)
    else
      lines[#lines + 1] = "Next staging: none (no hostile territory with a nest nearby): no crusade."
    end
  else
    lines[#lines + 1] = "Next target: none (no claimed territory)."
  end
  local cooldown = (storage.crusade_cooldown_until or 0) - game.tick
  if cooldown > 0 then lines[#lines + 1] = string.format("Cooldown: %ds left.", math.ceil(cooldown / 60)) end
  local last = storage.crusade
  if last then
    lines[#lines + 1] = string.format("Last crusade: territory %d, cost %d, %ds ago. Staging territory %s, nest at %d,%d (%s), map tag %s.",
      last.target_id, last.cost, math.floor((game.tick - last.tick) / 60), tostring(last.staging_id),
      last.nest_position and last.nest_position.x or 0, last.nest_position and last.nest_position.y or 0,
      last.nest and last.nest.valid and "alive" or "gone", last.tag and last.tag.valid and "yes" or "pending")
  end
  return table.concat(lines, "\n")
end

return crusade
