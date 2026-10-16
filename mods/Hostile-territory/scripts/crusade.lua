-- Crusade trigger: picks the target and works out what attacking it costs.
-- Target = the claimed territory furthest from the player force spawn (ties: random).
-- cost = BASE × (1 + distance / DISTANCE_STEP) × (1 + EVOLUTION_WEIGHT × evolution)
-- Distance = player force spawn to the territory centre (territories.centre).
-- Evolution from time and spawner kills also feeds storage.crusade_budget (EVOLUTION_POINTS per 1.0 evolution).
-- The pollution part is left out: it is already counted through cancelled attacks (attacks.lua).
-- storage.crusade_evolution_seen = time + spawner-kill evolution at the last check.
-- Trigger (every check): no crusade active, no cooldown, a target exists, budget >= cost and a staging nest exists
-- The COOLDOWN starts when a crusade ends (lost territory, defeated or cancelled), not when it triggers.
-- → plan the army, spend what it costs (the rest stays in the budget), mark the staging nest, target → warning.
-- No staging nest or no rally spot → no crusade, budget kept.
-- The rally (phase H) is planned at trigger time: guardian, rally prototype, build time, spot (scripts/rally.lua).
-- Migration (every MIGRATION_INTERVAL): spawn the army at the nest in batches over MIGRATION_TIME.
-- storage.crusade = {phase, target_id, distance, cost, spent, tick, staging_id, nest, nest_position, tag,
--   queue = {unit names}, next_unit, batch_size, spawned, group, units = {LuaEntity},
--   guardian, rally_name, build_time, rally_spot, march_tick, march_tries,
--   rally, rally_tag, builders, builders_done, next_builder_tick, builds, defend_tick}.
-- phase: "migration" → "march" (critical mass: whole army spawned, target → crusade, army walks to the rally spot)
--   → "build" (rally placed, builders sacrificed) → "hold" (phase H3) → "ended".
-- A crusade from before phase G has no phase and counts as ended; one waiting in G's "crusade" phase starts marching.
-- Ends (checked every migration tick): target no longer warning/crusade → cancelled; staging territory claimed or
-- gone before the march → cancelled; every unit dead → cancelled (migration) or defeated (later).
-- March (H-10): on arrival (on_ai_command_completed) → build. 5 min without arrival → send again; after a second
-- timeout, build where the army stands if that's inside the target, else defeated.
-- Rally destroyed (build/hold, H-b/H-f): rebuild at the same spot while the army has >= HOLD_UNITS + builders,
-- else defeated. Rally damaged (H-14): the army attacks the cause, at most once per DEFEND_COOLDOWN.
-- Intruders (H-15, build + hold): player military in the target → a squad (SQUAD_SHARE of the army, min SQUAD_MIN)
-- attacks the one nearest the rally, then returns. Re-commanded when idle (not moving or fighting), when the nearest
-- intruder changes, and every SQUAD_REFRESH while the intruder stays.
-- Hold (H3, every migration tick): rally alive, no player military in the target, >= HOLD_UNITS army units inside.
-- HOLD_TIME in a row → lost: the rally turns into the guardian (create_segmented_unit at its spot, full health),
-- target → hostile, leftover army released. A failed check resets the hold timer; so does a rebuild.
-- Otherwise leftover units, rally and tags are removed when a crusade ends; the target goes back to claimed.

local territories = require("scripts.territories")
local staging = require("scripts.staging")
local army = require("scripts.army")
local rally = require("scripts.rally")

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
local MARCH_TIMEOUT = 5 * 60 * 60
local ARRIVAL_RADIUS = 8
local GUARD_RADIUS = 20
local BUILDER_REACH = 40
local HOLD_UNITS = 10
local DEFEND_COOLDOWN = 10 * 60
local HOLD_TIME = 60 * 60
local SQUAD_SHARE = 0.25
local SQUAD_MIN = 5
local SQUAD_REFRESH = 60 * 60

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
  local guardian, rally_name, build_time = rally.plan(target, surface)
  local rally_spot = rally.pick_spot(target, surface, rally_name)
  if not rally_spot then return end
  local queue, spent = army.plan(nest.name, evolution, cost)
  if #queue == 0 then return end
  if storage.crusade then staging.unmark(storage.crusade) end
  storage.crusade_budget = storage.crusade_budget - spent
  storage.crusade = {phase = "migration", target_id = target.id, distance = distance, cost = cost, spent = spent,
    tick = game.tick, staging_id = staging_record.id, nest = nest, nest_position = nest.position,
    queue = queue, next_unit = 1, spawned = 0,
    guardian = guardian, rally_name = rally_name, build_time = build_time, rally_spot = rally_spot,
    batch_size = math.ceil(#queue * crusade.MIGRATION_INTERVAL / MIGRATION_TIME)}
  staging.mark(storage.crusade, surface)
  territories.set_state(target, "warning")
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

-- Ends the active crusade: removes leftover units, the rally and the map tags, target back to claimed.
-- lost = true: the territory was taken; the army is released instead of removed and the target becomes hostile.
function crusade.finish(message, lost)
  local state = active()
  if not state then return false end
  if lost then army.release(state) else army.destroy_all(state) end
  if state.rally and state.rally.valid then state.rally.destroy() end
  rally.unmark(state)
  staging.unmark(state)
  local target = storage.territories and storage.territories[state.target_id]
  if target and TARGET_STATES[target.state] then territories.set_state(target, lost and "hostile" or "claimed") end
  state.phase = "ended"
  state.outcome = lost and "lost" or "ended"
  state.ended_tick = game.tick
  storage.crusade_cooldown_until = game.tick + COOLDOWN
  game.forces.player.print(message)
  return true
end

local function march(state, surface, from)
  local group = army.regroup(state, surface, from)
  group.set_command{type = defines.command.go_to_location, destination = state.rally_spot,
    radius = ARRIVAL_RADIUS, distraction = defines.distraction.by_enemy}
  state.march_tick = game.tick
end

local function guard(state, surface)
  local group = army.regroup(state, surface, state.rally_spot)
  group.set_command{type = defines.command.wander, radius = GUARD_RADIUS, distraction = defines.distraction.by_enemy}
end

local function start_march(state, surface, target)
  state.phase = "march"
  state.march_tries = 1
  territories.set_state(target, "crusade")
  staging.unmark(state)
  march(state, surface, army.position(state) or state.nest_position)
  game.forces.player.print(string.format("Crusade on territory %d: %d enemies march from territory %d.",
    state.target_id, army.alive(state), state.staging_id))
end

-- Places the rally and starts sacrificing builders. Returns false if there is no room.
local function start_build(state, surface, target)
  local entity = rally.place(state, surface, target)
  if not entity then return false end
  state.phase = "build"
  state.rally = entity
  state.builders = rally.builder_count(army.alive(state))
  state.builders_done = 0
  state.next_builder_tick = game.tick + state.build_time / state.builders
  state.builds = (state.builds or 0) + 1
  state.hold_since = nil
  rally.mark(state, surface)
  guard(state, surface)
  game.forces.player.print(string.format("Crusade on territory %d: the enemy builds a rally at %d,%d (%d min).",
    state.target_id, state.rally_spot.x, state.rally_spot.y, state.build_time / 3600))
  return true
end

local function defeat(state, reason)
  crusade.finish(string.format("Crusade on territory %d defeated: %s.", state.target_id, reason))
end

local function update_march(state, surface, target)
  if game.tick < state.march_tick + MARCH_TIMEOUT then return end
  local position = army.position(state)
  if state.march_tries < 2 then
    state.march_tries = state.march_tries + 1
    march(state, surface, position)
    return
  end
  local spot = position and rally.spot_near(target, surface, state.rally_name, position)
  if spot then
    state.rally_spot = spot
    if start_build(state, surface, target) then return end
  end
  defeat(state, "the army never reached the territory")
end

-- The rally turns into the guardian: full health, assigned to the target territory.
local function lose(state, surface, target)
  local position = state.rally.position
  state.rally.destroy()
  surface.create_segmented_unit{name = state.guardian, position = position, territory = target.territory, force = "enemy"}
  crusade.finish(string.format("Territory %d is lost: the rally turned into a %s.", state.target_id, state.guardian), true)
end

-- Sends a squad after player military in the target. Returns true if there is any.
local function squad_alive(squad)
  return squad and squad.group and squad.group.valid and #squad.group.members > 0
end

-- Busy = actually on its way or fighting. An attack on a moving target can end early: the group then sits
-- "finished" with no command, or has already walked back and wanders at the rally (both seen in H4).
local SQUAD_BUSY_STATES = {
  [defines.group_state.gathering] = true,
  [defines.group_state.moving] = true,
  [defines.group_state.pathfinding] = true,
  [defines.group_state.attacking_target] = true,
  [defines.group_state.attacking_distraction] = true,
}
local function squad_idle(group)
  return not group.command or not SQUAD_BUSY_STATES[group.state]
end

local function hunt(squad, intruder, rally_spot)
  squad.group.set_command{type = defines.command.compound, structure_type = defines.compound_command.logical_and, commands = {
    {type = defines.command.attack, target = intruder, distraction = defines.distraction.by_enemy},
    {type = defines.command.go_to_location, destination = rally_spot, radius = ARRIVAL_RADIUS,
      distraction = defines.distraction.by_enemy},
    {type = defines.command.wander, radius = GUARD_RADIUS, distraction = defines.distraction.by_enemy},
  }}
  squad.target = intruder
  squad.tick = game.tick
end

-- Sends a squad after player military in the target (H-15). Returns true if there is any.
-- The squad gets a fresh command when it is idle or a different intruder is nearest; with no intruder left,
-- an idle squad walks back to the rally.
local function check_intruders(state, surface, target)
  local intruder = rally.find_player_military(target, surface, state.rally_spot)
  local squad = state.squad
  if not intruder then
    if squad_alive(squad) and squad_idle(squad.group) then
      squad.group.set_command{type = defines.command.compound, structure_type = defines.compound_command.logical_and, commands = {
        {type = defines.command.go_to_location, destination = state.rally_spot, radius = ARRIVAL_RADIUS,
          distraction = defines.distraction.by_enemy},
        {type = defines.command.wander, radius = GUARD_RADIUS, distraction = defines.distraction.by_enemy},
      }}
    end
    return false
  end
  if not squad_alive(squad) then
    local group = army.split(state, surface, math.max(SQUAD_MIN, math.floor(army.alive(state) * SQUAD_SHARE)), intruder.position)
    if not group then return true end
    squad = {group = group}
    state.squad = squad
  elseif not squad_idle(squad.group) and squad.target == intruder and game.tick < squad.tick + SQUAD_REFRESH then
    return true
  end
  hunt(squad, intruder, state.rally_spot)
  return true
end

local function update_hold(state, surface, target)
  state.hold_units = army.count_inside(state, surface, target.territory)
  state.hold_military = check_intruders(state, surface, target)
  if state.hold_military or state.hold_units < HOLD_UNITS then
    if state.hold_since then
      game.forces.player.print(string.format("Crusade on territory %d: the hold is broken.", state.target_id))
    end
    state.hold_since = nil
    return
  end
  if not state.hold_since then
    state.hold_since = game.tick
    game.forces.player.print(string.format("Crusade on territory %d: the enemy holds the territory. %d s until it is lost.",
      state.target_id, HOLD_TIME / 60))
  elseif game.tick - state.hold_since >= HOLD_TIME then
    lose(state, surface, target)
  end
end

local function update_build(state, surface, target)
  if not (state.rally and state.rally.valid) then
    local alive = army.alive(state)
    if alive >= HOLD_UNITS + rally.builder_count(alive) and start_build(state, surface, target) then
      game.forces.player.print(string.format("Crusade on territory %d: the rally was destroyed, the enemy rebuilds it.",
        state.target_id))
      return
    end
    defeat(state, "the rally was destroyed and the army is too weak to rebuild")
    return
  end
  if state.phase == "hold" then
    update_hold(state, surface, target)
    return
  end
  check_intruders(state, surface, target)
  local step = state.rally.max_health / state.builders
  while state.builders_done < state.builders and game.tick >= state.next_builder_tick do
    if not army.take_builder(state, state.rally.position, BUILDER_REACH) then break end
    state.rally.health = math.min(state.rally.max_health, state.rally.health + step)
    state.builders_done = state.builders_done + 1
    state.next_builder_tick = state.next_builder_tick + state.build_time / state.builders
  end
  if state.builders_done >= state.builders then
    state.phase = "hold"
    game.forces.player.print(string.format("Crusade on territory %d: the rally is finished.", state.target_id))
  end
end

function crusade.on_migration_tick()
  local state = active()
  if not state then return end
  local surface = game.surfaces[crusade.surface_name]
  local target = storage.territories and storage.territories[state.target_id]
  if not (target and TARGET_STATES[target.state]) then
    crusade.finish(string.format("Crusade on territory %d cancelled: the target changed.", state.target_id))
    return
  end
  if state.phase == "migration" or state.phase == "crusade" then
    local staging_record = storage.territories[state.staging_id]
    if not (staging_record and STAGING_STATES[staging_record.state]) then
      crusade.finish(string.format("Crusade on territory %d cancelled: staging territory %d was taken.",
        state.target_id, state.staging_id))
      return
    end
  end
  if state.spawned > 0 and army.alive(state) == 0 then
    if state.phase == "migration" then
      crusade.finish(string.format("Crusade on territory %d cancelled: the gathering army was wiped out.", state.target_id))
    else
      defeat(state, "the army was wiped out")
    end
    return
  end
  if state.phase == "migration" then
    army.spawn_batch(state, surface, state.batch_size)
    if state.next_unit > #state.queue then start_march(state, surface, target) end
  elseif state.phase == "crusade" then
    start_march(state, surface, target)
  elseif state.phase == "march" then
    update_march(state, surface, target)
  elseif state.phase == "build" or state.phase == "hold" then
    update_build(state, surface, target)
  end
end

function crusade.on_ai_command_completed(event)
  local state = active()
  if not (state and state.phase == "march" and state.group and state.group.valid) then return end
  if event.unit_number ~= state.group.unique_id then return end
  local surface = game.surfaces[crusade.surface_name]
  local target = storage.territories[state.target_id]
  if event.result == defines.behavior_result.success then
    if not start_build(state, surface, target) then defeat(state, "no room for the rally") end
  else
    state.march_tick = game.tick - MARCH_TIMEOUT -- handled as a timeout on the next migration tick
  end
end

-- Rally damaged: the army goes after the attacker, then returns to guard the rally (H-14).
function crusade.on_entity_damaged(event)
  local state = active()
  if not (state and state.rally and event.entity == state.rally) then return end
  local cause = event.cause
  if not (cause and cause.valid) or game.tick < (state.defend_tick or 0) + DEFEND_COOLDOWN then return end
  state.defend_tick = game.tick
  local group = army.regroup(state, game.surfaces[crusade.surface_name], state.rally_spot)
  group.set_command{type = defines.command.compound, structure_type = defines.compound_command.logical_and, commands = {
    {type = defines.command.attack, target = cause, distraction = defines.distraction.by_enemy},
    {type = defines.command.go_to_location, destination = state.rally_spot, radius = ARRIVAL_RADIUS,
      distraction = defines.distraction.by_enemy},
    {type = defines.command.wander, radius = GUARD_RADIUS, distraction = defines.distraction.by_enemy},
  }}
end

function crusade.on_chunk_charted(event)
  local state = active()
  if state then
    if state.phase == "migration" then staging.on_chunk_charted(state, event) end
    rally.on_chunk_charted(state, event)
  end
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
    local surface = game.surfaces[crusade.surface_name]
    local guardian, rally_name, build_time = rally.plan(target, surface)
    local spot = rally.pick_spot(target, surface, rally_name)
    lines[#lines + 1] = string.format("Next rally: %s (guardian %s%s), build %d min, e.g. at %s.",
      rally_name, guardian, target.guardian and "" or ", by distance", build_time / 3600,
      spot and string.format("%.1f,%.1f", spot.x, spot.y) or "none (no free spot): no crusade")
  else
    lines[#lines + 1] = "Next target: none (no claimed territory)."
  end
  local cooldown = (storage.crusade_cooldown_until or 0) - game.tick
  if cooldown > 0 then lines[#lines + 1] = string.format("Cooldown: %ds left.", math.ceil(cooldown / 60)) end
  local last = storage.crusade
  if last then
    lines[#lines + 1] = string.format("Crusade (%s): territory %d, cost %d (spent %d), %ds ago. Staging territory %s, nest at %d,%d (%s), map tag %s.",
      last.outcome == "lost" and "ended, territory lost" or tostring(last.phase or "ended"), last.target_id, last.cost, last.spent or last.cost, math.floor((game.tick - last.tick) / 60), tostring(last.staging_id),
      last.nest_position and last.nest_position.x or 0, last.nest_position and last.nest_position.y or 0,
      last.nest and last.nest.valid and "alive" or "gone", last.tag and last.tag.valid and "yes" or "pending")
    if last.rally_name then
      lines[#lines + 1] = string.format("Rally: %s (guardian %s), build %d min, at %.1f,%.1f.",
        last.rally_name, last.guardian, last.build_time / 3600, last.rally_spot.x, last.rally_spot.y)
    end
    if last.phase == "march" then
      lines[#lines + 1] = string.format("March: try %d, %ds.", last.march_tries, math.floor((game.tick - last.march_tick) / 60))
    elseif last.rally and last.rally.valid then
      lines[#lines + 1] = string.format("Rally %s: health %d / %d, builders %d of %d, next in %ds, build #%d.",
        last.phase, last.rally.health, last.rally.max_health, last.builders_done, last.builders,
        math.max(0, math.ceil((last.next_builder_tick - game.tick) / 60)), last.builds)
      local squad = last.squad
      if squad and squad.group and squad.group.valid and #squad.group.members > 0 then
        local t = squad.target
        lines[#lines + 1] = string.format("Squad: %d units at %d,%d after %s, sent %ds ago.", #squad.group.members,
          squad.group.position.x, squad.group.position.y,
          t and t.valid and string.format("%s at %d,%d", t.name, t.position.x, t.position.y) or "a gone target",
          math.floor((game.tick - squad.tick) / 60))
      end
      if last.phase == "hold" then
        lines[#lines + 1] = string.format("Hold: %s, army inside %s (need %d), player military %s.",
          last.hold_since and string.format("%ds of %d", math.floor((game.tick - last.hold_since) / 60), HOLD_TIME / 60) or "not holding",
          tostring(last.hold_units or "?"), HOLD_UNITS, last.hold_military and "yes" or "no")
      end
    end
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
