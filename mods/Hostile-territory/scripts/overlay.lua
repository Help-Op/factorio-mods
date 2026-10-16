-- Map-view colours per territory state. Drawn per chunk, only on chunks the player force has charted.
-- Hostile and claimed have no script overlay: the engine draws red for guarded territories and nothing otherwise.

local overlay = {}

-- Colours are premultiplied (rgb already scaled by alpha), like utility-constants chart colours.
overlay.colors = {
  challenge = {0.25, 0, 0.3, 0.35},
  warning = {0.35, 0.22, 0, 0.35},
  crusade = {0.45, 0.12, 0, 0.45},
}

local CHUNK = 32

local function chunk_key(position)
  return position.x .. "," .. position.y
end

local function viewer_force()
  return game.forces.player
end

function overlay.draw_chunk(record, position)
  local color = overlay.colors[record.state]
  if not color then return end
  local key = chunk_key(position)
  local existing = record.overlay[key]
  if existing and existing.valid then return end
  record.overlay[key] = rendering.draw_rectangle{
    color = color,
    filled = true,
    left_top = {position.x * CHUNK, position.y * CHUNK},
    right_bottom = {position.x * CHUNK + CHUNK, position.y * CHUNK + CHUNK},
    surface = record.territory.surface,
    forces = {viewer_force()},
    render_mode = "chart",
  }
end

function overlay.clear(record)
  for _, object in pairs(record.overlay) do
    if object.valid then object.destroy() end
  end
  record.overlay = {}
end

function overlay.redraw(record)
  overlay.clear(record)
  if not overlay.colors[record.state] then return end
  local territory = record.territory
  if not territory.valid then return end
  local force = viewer_force()
  local surface = territory.surface
  for _, chunk in pairs(territory.get_chunks()) do
    if force.is_chunk_charted(surface, chunk) then
      overlay.draw_chunk(record, chunk)
    end
  end
end

return overlay
