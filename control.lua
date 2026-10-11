local territories = require("scripts.territories")

script.on_init(territories.scan)
script.on_configuration_changed(territories.scan)

script.on_event(defines.events.on_territory_created, territories.on_territory_created)
script.on_event(defines.events.on_territory_destroyed, territories.on_territory_destroyed)
script.on_event(defines.events.on_object_destroyed, territories.on_object_destroyed)
script.on_event(defines.events.on_segmented_unit_created, territories.on_segmented_unit_created)
script.on_event(defines.events.on_segmented_unit_died, territories.on_segmented_unit_died)
script.on_event(defines.events.on_chunk_charted, territories.on_chunk_charted)

-- Debug interface (headless harness): /c remote.call("hostile-territory-debug", "set_state", id, "warning")
remote.add_interface("hostile-territory-debug", {
  set_state = function(id, state)
    local record = storage.territories[id]
    if record and territories.states[state] then territories.set_state(record, state) end
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
