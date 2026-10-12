-- Crusade trigger: picks the target and works out what attacking it costs.
-- Target = the claimed territory furthest from the player force spawn (ties: random).
-- cost = BASE × (1 + distance / DISTANCE_STEP) × (1 + EVOLUTION_WEIGHT × evolution)
-- Distance = player force spawn to the territory centre (territories.centre).
-- Evolution from time and spawner kills also feeds storage.crusade_budget (EVOLUTION_POINTS per 1.0 evolution).
-- The pollution part is left out: it is already counted through cancelled attacks (attacks.lua).
-- storage.crusade_evolution_seen = time + spawner-kill evolution at the last check.
-- Trigger (every check): no crusade active, no cooldown, a target exists, budget >= cost and a staging nest exists
-- → plan the army, spend what it costs (the rest stays in the budget), mark the staging nest, target → warning.
-- No staging nest → no crusade, budget kept.
-- Migration (every MIGRATION_INTERVAL): spawn the army at the nest in batches over MIGRATION_TIME.
-- storage.crusade = {phase, target_id, distance, cost, spent, tick, staging_id, nest, nest_position, tag,
--   queue = {unit names}, next_unit, batch_size, spawned, group}.
-- phase: "migration" → "crusade" (critical mass: whole army spawned, target → crusade) → "ended".
-- A crusade from before phase G has no phase and counts as ended.
-- Ends (G-8, checked every migration tick): target no longer warning/crusade → cancelled; staging territory
-- claimed or gone (its guardian died) → cancelled; every spawned unit dead
-- → cancelled (migration) or defeated (crusade). Leftover units are removed, the target goes back to claimed.
-- Until phase H, a crusade waits at the nest; /ht-crusade-cancel ends it.

local territories = require("scripts.territories")
local staging = require("scripts.staging")
local army = require("scripts.army")

local crusade = {}

crusade.surface_name = "nauvis"

local BASE = 400
local DISTANCE_STEP = 500
local EVOLUTION_WEIGHT = 4
local EVOLUTION_POINTS = 10000

crusade.CHECK_INTERVAL = 60 * 60
local COOLDOWN = 15 * 60 * 60
crusade.MIGRATION_INTERVAL = 10 * 60
local MIGRATION_TIME = 2 * 60 * 60

local function active()
  local state = storage.crusade
  return state and state.phase and state.phase ~= "ended" and state or nil
end

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
  if active() or game.tick < (storage.crusade_cooldown_until or 0) then return end
  local target, distance = crusade.pick_target()
  if not target then return end
  local evolution = game.forces.enemy.get_evolution_factor(crusade.surface_name)
  local cost = crusade.cost(distance, evolution)
  if (storage.crusade_budget or 0) < cost then return end
  local surface = game.surfaces[crusade.surface_name]
  local staging_record, nest = staging.pick(target, surface)
  if not staging_record then return end
  local queue, spent = army.plan(nest.name, evolution, cost)
  if #queue == 0 then return end
  if storage.crusade then staging.unmark(storage.crusade) end
  storage.crusade_budget = storage.crusade_budget - spent
  storage.crusade = {phase = "migration", target_id = target.id, distance = distance, cost = cost, spent = spent,
    tick = game.tick, staging_id = staging_record.id, nest = nest, nest_position = nest.position,
    queue = queue, next_unit = 1, spawned = 0,
    batch_size = math.ceil(#queue * crusade.MIGRATION_INTERVAL / MIGRATION_TIME)}
  staging.mark(storage.crusade, surface)
  territories.set_state(target, "warning")
  storage.crusade_cooldown_until = game.tick + COOLDOWN
  game.forces.player.print(string.format("Crusade warning: %d enemies gather in territory %d to attack territory %d (%d tiles from spawn). Cost %d of %d, budget left %d.",
    #queue, staging_record.id, target.id, math.floor(distance), spent, cost, storage.crusade_budget))
end

function crusade.on_tick()
  if not game.surfaces[crusade.surface_name] then return end
  add_evolution_budget()
  try_trigger()
end

local TARGET_STATES = {warning = true, crusade = true}
local STAGING_STATES = {hostile = true, challenge = true}

-- Ends the active crusade: removes leftover units and the map tag, target back to claimed.
function crusade.finish(message)
  local state = active()
  if not state then return false end
  if state.group and state.group.valid then
    for _, unit in pairs(state.group.members) do unit.destroy() end
    if state.group.valid then state.group.destroy() end
  end
  staging.unmark(state)
  local target = storage.territories and storage.territories[state.target_id]
  if target and TARGET_STATES[target.state] then territories.set_state(target, "claimed") end
  state.phase = "ended"
  state.ended_tick = game.tick
  game.forces.player.print(message)
  return true
end

function crusade.on_migration_tick()
  local state = active()
  if not state then return end
  local target = storage.territories and storage.territories[state.target_id]
  if not (target and TARGET_STATES[target.state]) then
    crusade.finish(string.format("Crusade on territory %d cancelled: the target changed.", state.target_id))
    return
  end
  local staging_record = storage.territories[state.staging_id]
  if not (staging_record and STAGING_STATES[staging_record.state]) then
    crusade.finish(string.format("Crusade on territory %d cancelled: staging territory %d was taken.",
      state.target_id, state.staging_id))
    return
  end
  if state.spawned > 0 and army.alive(state) == 0 then
    if state.phase == "migration" then
      crusade.finish(string.format("Crusade on territory %d cancelled: the gathering army was wiped out.", state.target_id))
    else
      crusade.finish(string.format("Crusade on territory %d defeated: the army was wiped out.", state.target_id))
    end
    return
  end
  if state.phase ~= "migration" then return end
  army.spawn_batch(state, game.surfaces[crusade.surface_name], state.batch_size)
  if state.next_unit > #state.queue then
    state.phase = "crusade"
    territories.set_state(target, "crusade")
    game.forces.player.print(string.format("Crusade on territory %d: %d enemies are ready in territory %d.",
      state.target_id, army.alive(state), state.staging_id))
  end
end

function crusade.on_chunk_charted(event)
  local state = active()
  if state then staging.on_chunk_charted(state, event) end
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
    lines[#lines + 1] = string.format("Crusade (%s): territory %d, cost %d (spent %d), %ds ago. Staging territory %s, nest at %d,%d (%s), map tag %s.",
      tostring(last.phase or "ended"), last.target_id, last.cost, last.spent or last.cost, math.floor((game.tick - last.tick) / 60), tostring(last.staging_id),
      last.nest_position and last.nest_position.x or 0, last.nest_position and last.nest_position.y or 0,
      last.nest and last.nest.valid and "alive" or "gone", last.tag and last.tag.valid and "yes" or "pending")
    if last.queue then
      local mix = {}
      for _, name in pairs(last.queue) do mix[name] = (mix[name] or 0) + 1 end
      local parts = {}
      for name, n in pairs(mix) do parts[#parts + 1] = n .. " " .. name end
      table.sort(parts)
      lines[#lines + 1] = string.format("Army: %d of %d spawned, %d alive (%s).",
        last.spawned or 0, #last.queue, army.alive(last), table.concat(parts, ", "))
    end
  end
  return table.concat(lines, "\n")
end

return crusade
