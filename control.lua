script.on_init(function()
  local surface = game.surfaces["nauvis"]
  if not surface then return end

  local demolisher_names = {"small-demolisher", "medium-demolisher", "big-demolisher"}
  local nests_created = 0

  -- debug: report counts of demolisher entities on init
  local total = 0
  for _, name in ipairs(demolisher_names) do
    local cnt = surface.count_entities_filtered{name = name}
    total = total + (cnt or 0)
    game.print("[Hostile-territory] found "..(cnt or 0).." entities of "..name)
  end
  game.print("[Hostile-territory] total demolishers found on init: "..total)

  for _, name in ipairs(demolisher_names) do
    local ents = surface.find_entities_filtered{name = name}
    for _, e in pairs(ents) do
      if nests_created > 500 then break end
      local pos = e.position
      if surface.can_place_entity({name = "demolisher-nest", position = pos}) then
        surface.create_entity({name = "demolisher-nest", position = pos})
        nests_created = nests_created + 1
        break
      end
    end
  end
end)

-- also create nests when chunks are generated, in case demolishers spawn later
script.on_event(defines.events.on_chunk_generated, function(event)
  local surface = nil
  if event.surface_index then
    surface = game.surfaces[event.surface_index]
  elseif event.surface then
    surface = event.surface
  else
    surface = game.surfaces["nauvis"]
  end
  if not surface then return end
  local demolisher_names = {"small-demolisher", "medium-demolisher", "big-demolisher"}
  for _, name in ipairs(demolisher_names) do
    if not event.area then goto continue_end_for end
    local area = {{event.area.left_top.x, event.area.left_top.y}, {event.area.right_bottom.x, event.area.right_bottom.y}}
    local ents = surface.find_entities_filtered{area = area, name = name}
    for _, e in pairs(ents) do
      if surface.can_place_entity({name = "demolisher-nest", position = e.position}) then
        surface.create_entity({name = "demolisher-nest", position = e.position})
      end
    end
    ::continue_end_for::
  end
end)
