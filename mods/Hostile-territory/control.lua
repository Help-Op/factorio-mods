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

script.on_init(function()
  territories.scan()
  crusade.init()
  regrow.init()
  brain.init()
  brain.scan()
  oil.init()
end)
script.on_configuration_changed(function()
  patrol.migrate()
  territories.scan()
  crusade.init()
  regrow.init()
  brain.init()
  brain.scan()
  oil.init()
end)

script.on_event(defines.events.on_territory_created, territories.on_territory_created)
script.on_event(defines.events.on_territory_destroyed, territories.on_territory_destroyed)
script.on_event(defines.events.on_object_destroyed, territories.on_object_destroyed)
script.on_event(defines.events.on_segmented_unit_created, territories.on_segmented_unit_created)
script.on_event(defines.events.on_segmented_unit_died, function(event)
  local claimed = territories.on_segmented_unit_died(event)
  if claimed then challenge.on_won(claimed.id) end
end)
script.on_event(defines.events.on_chunk_generated, function(event)
  brain.on_chunk_generated(event)
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
every(crusade.CHECK_INTERVAL, crusade.on_tick)
every(crusade.MIGRATION_INTERVAL, crusade.on_migration_tick)
every(patrol.INTERVAL, patrol.on_tick)
every(regrow.INTERVAL, regrow.on_tick)
every(patrol.LIVE_INTERVAL, patrol.on_live_tick)
script.on_event(defines.events.on_ai_command_completed, function(event)
  waves.on_ai_command_completed(event)
  crusade.on_ai_command_completed(event)
end)
-- rallies (crusade defence) and enemy nests / worms (siege, challenge-feel-plan.md E9)
local damage_filters = {{filter = "type", type = "unit-spawner"}, {filter = "type", type = "turret"}}
for _, name in pairs(rally.NAMES) do damage_filters[#damage_filters + 1] = {filter = "name", name = name} end
script.on_event(defines.events.on_entity_damaged, function(event)
  local type = event.entity.type
  if type == "unit-spawner" or type == "turret" then
    challenge.on_base_damaged(event)
  else
    crusade.on_entity_damaged(event)
  end
end, damage_filters)
script.on_event(defines.events.on_unit_group_finished_gathering, attacks.on_unit_group_finished_gathering)

-- Debug interface (headless harness): /c remote.call("hostile-territory-debug", "set_state", id, "warning")
remote.add_interface("hostile-territory-debug", {
  set_state = function(id, state)
    local record = storage.territories[id]
    if record and territories.states[state] then territories.set_state(record, state) end
  end,
  crusade = function() return crusade.describe() end,
  brains = function() return brain.describe() .. " " .. regrow.describe() end,
  oil = function() return storage.oil end,
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
  -- one challenge check of waves for the territory at x, y against entity target, without a player or a real
  -- challenge (fake record in storage.debug_waves, challenge-feel-plan.md E1-8).
  -- options (optional): phase = first phase of a new fake record ("siege" / "wake"), wake = true to call waves.wake.
  -- Returns {id, ring, text, spawned = {[unit_number] = {x, y}}}
  waves_step = function(x, y, target, options)
    options = options or {}
    local surface = game.surfaces[territories.surface_name]
    local record = territories.get_at(surface, {x = x, y = y})
    if not (record and record.territory.valid) then return nil end
    local id = record.id
    storage.debug_waves = storage.debug_waves or {}
    local fake = storage.debug_waves[id]
    if not fake then
      local unit = record.territory.get_segmented_units()[1]
      if not (unit and unit.segments[1]) then return nil end
      fake = {territory_id = id, players = {}}
      waves.init(fake, surface, unit.segments[1].position, options.phase)
      storage.debug_waves[id] = fake
    end
    if options.wake then waves.wake(fake) end
    waves.update(fake, surface, {{entity = target}})
    local spawned = {}
    for number, entity in pairs(fake.spawned) do
      if entity.valid then spawned[number] = {x = entity.position.x, y = entity.position.y} end
    end
    return {id = id, ring = fake.ring, text = waves.describe(fake), spawned = spawned}
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
  if player then player.print(brain.describe() .. " " .. regrow.describe() .. " " .. oil.describe()) end
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
