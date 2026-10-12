-- Map tags for the player force (crusade staging nest, rally).
-- A tag needs a charted chunk, so the area is charted first. If the chart isn't done yet, add_chart_tag returns nil;
-- callers retry from on_chunk_charted with tags.is_chunk_of.

local tags = {}

local function add(surface, position, icon, text)
  return game.forces.player.add_chart_tag(surface, {position = position, icon = icon, text = text})
end

-- Charts the spot and tries to place the tag. Returns the tag or nil (retry later).
function tags.place(surface, position, icon, text)
  game.forces.player.chart(surface, {{position.x - 16, position.y - 16}, {position.x + 16, position.y + 16}})
  return add(surface, position, icon, text)
end

function tags.retry(event, position, icon, text)
  if event.force.name ~= "player" then return nil end
  if event.position.x ~= math.floor(position.x / 32) or event.position.y ~= math.floor(position.y / 32) then return nil end
  return add(game.surfaces[event.surface_index], position, icon, text)
end

function tags.remove(tag)
  if tag and tag.valid then tag.destroy() end
end

return tags
