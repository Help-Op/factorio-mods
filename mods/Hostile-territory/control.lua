local territories = require("scripts.territories")
local challenge = require("scripts.challenge")
local waves = require("scripts.waves")
local attacks = require("scripts.attacks")
local crusade = require("scripts.crusade")
local rally = require("scripts.rally")
local patrol = require("scripts.patrol")
local brain = require("scripts.brain")
local regrow = require("scripts.regrow")
local staging = require("scripts.staging")
local oil = require("scripts.oil")
local director = require("scripts.director")
local telemetry = require("scripts.telemetry")
local brain_fight = require("scripts.brain-fight")
local districts = require("scripts.districts")
local war = require("scripts.war")
local influence = require("scripts.influence")

script.on_init(function()
  territories.scan()
  crusade.init()
  regrow.init()
  districts.init()
  brain.init()
  brain.scan()
  oil.init()
end)
script.on_configuration_changed(function()
  patrol.migrate()
  territories.scan()
  crusade.init()
  regrow.init()
  districts.init()
  brain.init()
  brain.scan()
  oil.init()
end)

script.on_event(defines.events.on_territory_created, territories.on_territory_created)
script.on_event(defines.events.on_territory_destroyed, territories.on_territory_destroyed)
script.on_event(defines.events.on_object_destroyed, territories.on_object_destroyed)
script.on_event(defines.events.on_segmented_unit_created, function(event)
  territories.on_segmented_unit_created(event)
  brain.on_segmented_unit_created(event)
end)
script.on_event(defines.events.on_segmented_unit_died, function(event)
  local claimed = territories.on_segmented_unit_died(event)
  if claimed then
    challenge.on_won(claimed.id)
    war.on_won(claimed.id)
  end
end)
script.on_event(defines.events.on_chunk_generated, function(event)
  brain.on_chunk_generated(event)
  districts.on_chunk_generated(event)
  oil.on_chunk_generated(event)
end)
script.on_event(defines.events.on_chunk_charted, function(event)
  territories.on_chunk_charted(event)
  crusade.on_chunk_charted(event)
end)
-- script.on_nth_tick keeps one handler per interval: a second registration with the same interval silently
-- replaces the first (that switched off the crusade check, 2026-10-17). Always register through every().
local nth_tick = {}
local function every(interval, handler)
  local handlers = nth_tick[interval]
  if not handlers then
    handlers = {}
    nth_tick[interval] = handlers
    script.on_nth_tick(interval, function(event)
      for _, h in ipairs(handlers) do h(event) end
    end)
  end
  handlers[#handlers + 1] = handler
end

every(challenge.CHECK_INTERVAL, challenge.on_tick)
every(war.CHECK_INTERVAL, war.on_tick) -- ring-2+ wars (ring2-challenge-plan.md 4e1)
every(crusade.CHECK_INTERVAL, crusade.on_tick)
every(crusade.MIGRATION_INTERVAL, crusade.on_migration_tick)
every(patrol.INTERVAL, patrol.on_tick)
every(regrow.INTERVAL, regrow.on_tick)
every(brain.SWEEP_INTERVAL, brain.sweep) -- brains made with the map: out of sight (ring2-challenge-plan.md R2-E1 4b)
every(patrol.LIVE_INTERVAL, patrol.on_live_tick)
every(waves.PULSE_STEP, waves.on_pulse_tick) -- frenzy shockwave stages (oil-ring-challenge-plan.md OR-D28)
script.on_event(defines.events.on_ai_command_completed, function(event)
  waves.on_ai_command_completed(event)
  crusade.on_ai_command_completed(event)
  director.on_ai_command_completed(event)
  brain_fight.on_ai_command_completed(event)
end)
-- rallies (crusade defence), enemy nests / worms (siege, challenge-feel-plan.md E9) and characters (pressure
-- director, oil-ring-challenge-plan.md OR-E2)
local damage_filters = {{filter = "type", type = "unit-spawner"}, {filter = "type", type = "turret"},
  {filter = "type", type = "character"}}
for _, name in pairs(rally.NAMES) do damage_filters[#damage_filters + 1] = {filter = "name", name = name} end
script.on_event(defines.events.on_entity_damaged, function(event)
  local type = event.entity.type
  if type == "unit-spawner" or type == "turret" then
    war.on_base_damaged(event, challenge.player_of(event.cause)) -- district fights (4e1)
    challenge.on_base_damaged(event)
  elseif type == "character" then
    director.on_character_damaged(event)
  else
    crusade.on_entity_damaged(event)
  end
end, damage_filters)
script.on_event(defines.events.on_unit_group_finished_gathering, attacks.on_unit_group_finished_gathering)
script.on_event(defines.events.on_unit_added_to_group, attacks.on_unit_added_to_group) -- 4e2: army units stay ours
script.on_event(defines.events.on_entity_died, function(event)
  if event.entity.type == "unit-spawner" then
    brain_fight.on_nest_died(event) -- OR-E8 E8-A2: an anchor releases its bearer
    challenge.on_nest_died(event)
    war.on_nest_died(event) -- a district heart falls (4e1)
  else
    telemetry.on_entity_died(event)
    director.on_unit_died(event) -- OR-E9 kill zone
    war.on_unit_died(event) -- 4e2 influence map: hive deaths are threat
  end
end, {{filter = "type", type = "unit"}, {filter = "type", type = "unit-spawner"}})
script.on_event(defines.events.on_player_died, function(event)
  telemetry.on_player_died(event)
  war.on_player_died(event)
end)
-- brain shield + guard rush trigger (oil-ring-challenge-plan.md OR-E6)
script.on_event(defines.events.on_segmented_unit_damaged, brain_fight.on_damaged)

-- Test helper (oil-ring-challenge-plan.md PT2: the /c teleport 60 tiles east could land in a ring-0 territory).
-- Picks the territory points of that ring (grid layer of the cell, from the noise: no chunks needed), nearest to
-- `from` first, and returns a spot GOTO_DISTANCES tiles from the first one's brain towards spawn: outside its base
-- (radius 25), inside its territory (the first distance that still is). Generates only GOTO_CHUNKS chunks around
-- each point it tries (base + districts, ring2-challenge 4c), not the whole map out to that ring (was ~5300 chunks
-- for ring 2, a second of lag). Returns spot, brain position, or nil and a reason.
local GOTO_DISTANCES = {45, 38, 32}
local GOTO_CHUNKS = 6 -- 192 tiles: districts sit 115 tiles out, built once their chunks within ~40 tiles exist
local GOTO_TRIES = 4 -- points tried (one may be claimed: no land)
local G = 384 -- grid cell (nauvis-territory.lua)
local function layer(i) return i >= 0 and i or -i - 1 end
local function goto_spot(surface, from, ring)
  local positions = {}
  for i = -ring - 1, ring do
    for j = -ring - 1, ring do
      if math.max(layer(i), layer(j)) == ring then positions[#positions + 1] = {(i + 0.5) * G, (j + 0.5) * G} end
    end
  end
  local p = surface.calculate_tile_properties({"hostile_point_own_x", "hostile_point_own_y"}, positions)
  local points = {}
  for k = 1, #positions do points[k] = {x = p.hostile_point_own_x[k], y = p.hostile_point_own_y[k]} end
  table.sort(points, function(a, b)
    return (a.x - from.x) ^ 2 + (a.y - from.y) ^ 2 < (b.x - from.x) ^ 2 + (b.y - from.y) ^ 2
  end)
  local reason = string.format("No ring-%d brain found.", ring)
  for k = 1, math.min(#points, GOTO_TRIES) do
    surface.request_to_generate_chunks(points[k], GOTO_CHUNKS)
    surface.force_generate_chunk_requests()
    surface.force_generate_chunk_requests() -- the ones brain.lua requested for a base moved onto land
    local territory = surface.get_territory_for_chunk({x = math.floor(points[k].x / 32), y = math.floor(points[k].y / 32)})
    local unit = territory and territory.get_segmented_units()[1]
    local head = unit and unit.valid and unit.segments[1]
    if head then
      local best = head.position
      local length = math.max(math.sqrt(best.x ^ 2 + best.y ^ 2), 1)
      for _, distance in ipairs(GOTO_DISTANCES) do
        local wanted = {x = best.x - best.x / length * distance, y = best.y - best.y / length * distance}
        local found = surface.find_non_colliding_position("character", wanted, 10, 1)
        if found and surface.get_territory_for_chunk({x = math.floor(found.x / 32), y = math.floor(found.y / 32)}) == territory then
          return found, best
        end
      end
      reason = "No free spot next to that brain." -- try the next one
    end
  end
  return nil, reason
end

-- OR-E6 / OR-E7 rocks of a (debug) challenge: {{x, y, wall, arena}, ...}
local function rock_list(record)
  local list = {}
  for i, wall in pairs(record.fight and record.fight.walls or {}) do
    for _, rock in pairs(wall.rocks) do
      if rock.valid then list[#list + 1] = {x = rock.position.x, y = rock.position.y, wall = i, arena = wall.arena or false} end
    end
  end
  return list
end

local function bearer_list(record)
  local list = {}
  for _, unit in pairs(record.bearers or {}) do
    local spot = record.bearer_spots and record.bearer_spots[unit.unit_number]
    if unit.valid then list[#list + 1] = {x = unit.position.x, y = unit.position.y, spot = spot,
      command = unit.commandable.command and unit.commandable.command.type} end
  end
  return list
end

local command_names = {}
for name, value in pairs(defines.command) do command_names[value] = name end

local function queen_list(record)
  local list = {}
  for _, queen in pairs(record.queens or {}) do
    if queen.entity.valid then
      list[#list + 1] = {x = queen.entity.position.x, y = queen.entity.position.y, state = queen.state, spot = queen.spot,
        picked_at = queen.picked_at, number = queen.entity.unit_number,
        command = queen.entity.commandable.command and command_names[queen.entity.commandable.command.type],
        distraction = queen.entity.commandable.command and queen.entity.commandable.command.distraction,
        dest = queen.entity.commandable.command and queen.entity.commandable.command.destination,
        speed = queen.entity.speed,
        group = queen.entity.commandable.parent_group ~= nil}
    end
  end
  return list
end

local function escort_list(record)
  local list = {}
  for _, escort in pairs(record.escorts or {}) do
    if escort.entity.valid then
      local command = escort.entity.commandable.command
      list[#list + 1] = {x = escort.entity.position.x, y = escort.entity.position.y, queen = escort.queen,
        command = command and command_names[command.type], speed = escort.entity.speed}
    end
  end
  return list
end

-- Debug interface (headless harness): /c remote.call("hostile-territory-debug", "set_state", id, "warning")
remote.add_interface("hostile-territory-debug", {
  set_state = function(id, state)
    local record = storage.territories[id]
    if record and territories.states[state] then territories.set_state(record, state) end
  end,
  crusade = function() return crusade.describe() end,
  attacks = function() return attacks.describe() end,
  brains = function() return brain.describe() .. " " .. regrow.describe() .. " " .. districts.describe() .. " " .. war.describe() end,
  -- ring-2+ districts (R2-E1 4c): {[territory id] = {point, list = {{slot, x, y, rotation, built}}}}
  districts_state = function() return storage.districts end,
  -- points of the ring-2 territories that get guaranteed uranium (R2-E1 4d)
  uranium_points = function() return storage.uranium_points end,
  -- ring-2+ wars (4e1): {[territory id] = {started_tick, log, fights = {[slot] = fight}}}
  wars = function() return storage.wars end,
  -- 4e1b: the garrison of the district nearest x, y (within 300) to full now; returns territory id, slot
  garrison_fill = function(x, y) return war.fill(game.surfaces[territories.surface_name], {x = x, y = y}) end,
  -- 4e2: retake armies {[territory id] = army}, influence cells, and the next retake now (all wars, or territory id)
  armies = function() return storage.armies end,
  influence = function() return storage.influence end,
  retake_now = function(id) return war.retake_now(id) end,
  -- 4e2b/c: core garrisons, funds and queen reserves {[territory id] = core}, the next raid now, every live heart's queen now
  cores = function() return storage.cores end,
  raid_now = function(id) return war.raid_now(id) end,
  queen_now = function() return war.queen_now() end,
  -- tests: true keeps every brain from deciding (no pre-positioning, raids or retakes)
  hive_hold = function(on) storage.hive_hold = on or nil end,
  oil = function() return storage.oil end,
  -- brain placement (R2-E1 4b): {placed, dead, moved = {[cell] = {point, spot, id, done}}}
  brain_state = function() return storage.brain end,
  -- n regrowth rounds now; returns the number of pieces built
  regrow = function(n) return regrow.run(n or 1) end,
  -- staging choice for a target territory id (may generate a neighbour's base): {id, x, y} or nil
  staging_for = function(id)
    local record = storage.territories[id]
    if not (record and record.territory.valid) then return nil end
    local chosen, nest = staging.pick(record, game.surfaces[territories.surface_name])
    if not chosen then return nil end
    return {id = chosen.id, x = nest.position.x, y = nest.position.y}
  end,
  -- what a lost crusade does, without the crusade: a brain at x, y in the territory there, its base registered
  place_brain = function(x, y)
    local surface = game.surfaces[territories.surface_name]
    local record = territories.get_at(surface, {x = x, y = y})
    if not record then return nil end
    local name = rally.guardian_for(record, surface)
    surface.create_segmented_unit{name = name, position = {x, y}, territory = record.territory, force = "enemy"}
    regrow.register(record, {x = x, y = y})
    return name
  end,
  crusade_cancel = function() return crusade.finish("Crusade cancelled (debug).") end,
  -- /ht-goto-ring without a player: {spot, brain, spot_territory, brain_territory} (territory ids) or {reason}
  goto_spot = function(ring, x, y)
    local surface = game.surfaces[territories.surface_name]
    local spot, brain_or_reason = goto_spot(surface, {x = x or 0, y = y or 0}, ring)
    if not spot then return {reason = brain_or_reason} end
    local at_spot, at_brain = territories.get_at(surface, spot), territories.get_at(surface, brain_or_reason)
    return {spot = spot, brain = brain_or_reason, spot_territory = at_spot and at_spot.id,
      brain_territory = at_brain and at_brain.id}
  end,
  -- one challenge check of waves for the territory at x, y against entity target, without a player or a real
  -- challenge (fake record in storage.debug_waves, challenge-feel-plan.md E1-8).
  -- options (optional): phase = first phase of a new fake record ("siege" / "wake"), wake = true to call waves.wake,
  -- reset = true to drop the fake record first, director = false to measure without acting (OR-E2),
  -- antikite = false to keep squad slots where they were first placed (OR-E6; was: no follow / rebuild / intercept).
  -- Also runs the director and telemetry (script-output/ht-telemetry/). Returns {id, ring, text,
  -- spawned = {[unit_number] = {x, y}}, held, director = record.director}
  waves_step = function(x, y, target, options)
    options = options or {}
    local surface = game.surfaces[territories.surface_name]
    local record = territories.get_at(surface, {x = x, y = y})
    if not (record and record.territory.valid) then return nil end
    local id = record.id
    storage.debug_waves = storage.debug_waves or {}
    storage.director_debug = options.debug or nil -- director.describe lists the commands of held units next to you
    if options.reset and storage.debug_waves[id] then
      brain_fight.clear(storage.debug_waves[id])
      director.disband(storage.debug_waves[id])
      waves.clear(storage.debug_waves[id])
      storage.debug_waves[id] = nil
    end
    local fake = storage.debug_waves[id]
    if not fake then
      local unit = record.territory.get_segmented_units()[1]
      if not (unit and unit.segments[1]) then return nil end
      fake = {territory_id = id, players = {}, started_tick = game.tick}
      waves.init(fake, surface, unit.segments[1].position, options.phase)
      storage.debug_waves[id] = fake
    end
    if options.wake then waves.wake(fake) end
    waves.update(fake, surface, {{entity = target}})
    director.update(fake, surface, {{entity = target}}, options.director == false, options.antikite == false)
    brain_fight.update(fake, surface, {{entity = target}})
    telemetry.sample(fake, surface, {{entity = target}})
    local spawned = {}
    for number, entity in pairs(fake.spawned) do
      if entity.valid then spawned[number] = {x = entity.position.x, y = entity.position.y} end
    end
    return {id = id, ring = fake.ring, phase = fake.phase, text = waves.describe(fake) .. brain_fight.describe(fake) .. director.describe(fake),
      spawned = spawned, held = director.held_count(fake), director = fake.director, surge = fake.surge,
      pulse = fake.pulse_tick ~= nil, shield = fake.fight and fake.fight.shield, stats = fake.stats,
      squads = director.squad_counts(fake, target.unit_number), closing = fake.closing and {radius = fake.closing.radius,
        state = fake.closing.state, n = table_size(fake.closing.members), centre = fake.closing.centre},
      slot_error = director.slot_error(fake, target), rocks = rock_list(fake),
      bearers = brain_fight.bearers_alive(fake), anchors = brain_fight.anchors_alive(fake),
      anchors_start = fake.fight and fake.fight.anchors_start, links = brain_fight.links_alive(fake),
      bearer_list = bearer_list(fake), queens = queen_list(fake), escorts = escort_list(fake), queen_level = fake.queen_level or 0, take = brain_fight.take(fake), regroup = fake.regroup and table_size(fake.regroup.units) or nil,
      choke = director.choke(fake, target.unit_number), blocked = select(2, director.choke(fake, target.unit_number))}
  end,
  -- reroute one territory now (runs again even if done); returns its stats
  reroute = function(id)
    local record = storage.territories[id]
    if not (record and record.territory.valid) then return nil end
    return patrol.reroute(record)
  end,
  -- reroute stats per territory: {[id] = record.patrol}
  patrol = function()
    local out = {}
    for id, record in pairs(storage.territories or {}) do out[id] = record.patrol or false end
    return out
  end,
})

-- Debug commands -------------------------------------------------------------

local function state_list()
  local names = {}
  for name in pairs(territories.states) do names[#names + 1] = name end
  table.sort(names)
  return table.concat(names, ", ")
end

commands.add_command("ht-territory", "Show the id and state of the territory you stand in.", function(command)
  local player = game.get_player(command.player_index)
  if not player then return end
  local record = territories.get_at(player.surface, player.position)
  if not record then
    player.print("No territory here.")
    return
  end
  player.print(string.format("Territory %d: state=%s, guardians=%d, chunks=%d",
    record.id, record.state, #record.territory.get_segmented_units(), #record.territory.get_chunks()))
end)

commands.add_command("ht-set-state", "<state> Force the state of the territory you stand in. States: " .. state_list(), function(command)
  local player = game.get_player(command.player_index)
  if not player then return end
  if not player.admin then
    player.print("Admins only.")
    return
  end
  local state = command.parameter
  if not (state and territories.states[state]) then
    player.print("Usage: /ht-set-state <state>. States: " .. state_list())
    return
  end
  local record = territories.get_at(player.surface, player.position)
  if not record then
    player.print("No territory here.")
    return
  end
  territories.set_state(record, state)
  player.print(string.format("Territory %d: state=%s", record.id, state))
end)

commands.add_command("ht-challenges", "List running challenges.", function(command)
  local player = game.get_player(command.player_index)
  if player then player.print(challenge.describe()) end
end)

commands.add_command("ht-attacks", "Show cancelled vanilla attacks and the crusade budget.", function(command)
  local player = game.get_player(command.player_index)
  if player then player.print(attacks.describe()) end
end)

commands.add_command("ht-crusade", "Show the crusade budget, the next target and its cost.", function(command)
  local player = game.get_player(command.player_index)
  if player then player.print(crusade.describe()) end
end)

commands.add_command("ht-brains", "Show how many brains were placed on their base and how many territories started claimed (water).", function(command)
  local player = game.get_player(command.player_index)
  if player then player.print(brain.describe() .. " " .. regrow.describe() .. " " .. districts.describe() .. " " .. war.describe() .. " " .. oil.describe()) end
end)

commands.add_command("ht-garrison-fill", "Fill the garrison of the nearest ring-2 district (within 300 tiles) to full now.", function(command)
  local player = game.get_player(command.player_index)
  if not player then return end
  local id, slot = war.fill(player.surface, player.position)
  player.print(id and string.format("Garrison of territory %d, district %d filled.", id, slot) or "No live district within 300 tiles.")
end)

commands.add_command("ht-war", "Show ring-2+ wars, garrisons on the map, retake armies and the influence map.", function(command)
  local player = game.get_player(command.player_index)
  if player then player.print(war.describe()) end
end)

commands.add_command("ht-retake-now", "Start the next retake army of every war now (fallen districts count as left, 5 s massing, a queen is made if the reserve is empty).", function(command)
  local player = game.get_player(command.player_index)
  if player then player.print(string.format("Retake forced in %d wars.", war.retake_now())) end
end)

commands.add_command("ht-raid-now", "The brain of every war sends its next raid now, with whatever its raid fund holds (at you in a fallen district, else your best building cluster).", function(command)
  local player = game.get_player(command.player_index)
  if player then player.print(string.format("Raid forced in %d wars.", war.raid_now())) end
end)

commands.add_command("ht-queen-now", "Every live district heart at war makes its next elder queen now (while the reserve has room).", function(command)
  local player = game.get_player(command.player_index)
  if player then player.print(string.format("%d hearts make a queen.", war.queen_now())) end
end)

commands.add_command("ht-influence", "Draw the hive's influence map for you (on / off): threat (red, T), your buildings (V), control colour.", function(command)
  local player = game.get_player(command.player_index)
  if player then player.print(influence.toggle(player) and "Influence map on (redrawn every 5 s)." or "Influence map off.") end
end)

-- A/B (oil-ring-challenge-plan.md OR-E4, OR-E6): off = squad slots stay where they were first placed (stale points).
commands.add_command("ht-antikite", "[on|off] Switch whether the director's squads follow you (off: slots stay where first placed); no parameter shows it.", function(command)
  local player = game.get_player(command.player_index)
  if not player then return end
  if command.parameter == "off" then storage.antikite_off = true elseif command.parameter == "on" then storage.antikite_off = nil end
  player.print("Anti-kite: " .. (storage.antikite_off and "off" or "on"))
end)

commands.add_command("ht-goto-ring", "[ring] Teleport next to the nearest brain of that ring (default 1), on its spawn side. Generates chunks first (a few seconds).", function(command)
  local player = game.get_player(command.player_index)
  if not (player and player.character) then return end
  local ring = tonumber(command.parameter) or 1
  local spot, brain_or_reason = goto_spot(player.surface, player.position, ring)
  if not spot then
    player.print(brain_or_reason)
    return
  end
  player.teleport(spot, player.surface)
  local b = brain_or_reason
  player.print(string.format("Ring-%d brain [gps=%d,%d], %d tiles from spawn.", ring, b.x, b.y, math.sqrt(b.x ^ 2 + b.y ^ 2)))
end)

commands.add_command("ht-crusade-cancel", "End the active crusade: army removed, target back to claimed.", function(command)
  local player = game.get_player(command.player_index)
  if not player then return end
  if not player.admin then
    player.print("Admins only.")
    return
  end
  if not crusade.finish("Crusade cancelled by " .. player.name .. ".") then player.print("No active crusade.") end
end)
