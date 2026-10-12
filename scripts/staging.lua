-- Staging point for a crusade (phase G): an existing enemy nest in a hostile territory next to the target.
-- Candidates: hostile territories touching the target (a chunk next to one of its chunks) that have a nest.
-- Pick the one whose centre is furthest from spawn, so the army gathers on the far side of the target.
-- Fallback: the hostile territory with a nest whose centre is nearest to the target centre.
-- Nests are never built: no candidate → no staging → no crusade.
-- The staging nest gets a map tag for the player force. The chunk is charted first; if the tag can't be placed
-- yet (chart pending), it is placed from on_chunk_charted.

local territories = require("scripts.territories")

local staging = {}

local TAG_TEXT = "Crusade staging"

local function distance2(a, b)
  return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2
end

local function touching_hostile(target, surface)
  local own = {}
  local chunks = target.territory.get_chunks()
  for _, chunk in pairs(chunks) do own[chunk.x .. "," .. chunk.y] = true end
  local found = {}
  for _, chunk in pairs(chunks) do
    for dx = -1, 1 do
      for dy = -1, 1 do
        local x, y = chunk.x + dx, chunk.y + dy
        if not own[x .. "," .. y] then
          local record = territories.get(surface.get_territory_for_chunk({x = x, y = y}))
          if record and record.state == "hostile" then found[record.id] = record end
        end
      end
    end
  end
  return found
end

-- The enemy spawner in the territory closest to point, or nil.
local function nearest_nest(record, surface, point)
  local best, best_distance
  for _, chunk in pairs(record.territory.get_chunks()) do
    for _, nest in pairs(surface.find_entities_filtered{area = chunk.area, type = "unit-spawner", force = "enemy"}) do
      local distance = distance2(nest.position, point)
      if not best_distance or distance < best_distance then best, best_distance = nest, distance end
    end
  end
  return best
end

-- Returns staging record, nest entity; or nil if there is no valid staging territory.
function staging.pick(target, surface)
  local target_centre = territories.centre(target)
  if not target_centre then return nil end
  local spawn = game.forces.player.get_spawn_position(surface)

  local best, best_nest, best_distance
  for _, record in pairs(touching_hostile(target, surface)) do
    local centre = territories.centre(record)
    if centre then
      local distance = distance2(centre, spawn)
      if not best_distance or distance > best_distance then
        local nest = nearest_nest(record, surface, target_centre)
        if nest then best, best_nest, best_distance = record, nest, distance end
      end
    end
  end
  if best then return best, best_nest end

  local others = {}
  for _, record in pairs(storage.territories or {}) do
    local centre = record.state == "hostile" and record.territory.valid and territories.centre(record)
    if centre then others[#others + 1] = {record = record, distance = distance2(centre, target_centre)} end
  end
  table.sort(others, function(a, b) return a.distance < b.distance end)
  for _, other in ipairs(others) do
    local nest = nearest_nest(other.record, surface, target_centre)
    if nest then return other.record, nest end
  end
  return nil
end

local function add_tag(state, surface)
  state.tag = game.forces.player.add_chart_tag(surface, {
    position = state.nest_position,
    icon = {type = "entity", name = state.nest.valid and state.nest.name or "biter-spawner"},
    text = TAG_TEXT,
  })
end

function staging.mark(state, surface)
  local p = state.nest_position
  game.forces.player.chart(surface, {{p.x - 16, p.y - 16}, {p.x + 16, p.y + 16}})
  add_tag(state, surface)
end

function staging.unmark(state)
  if state.tag and state.tag.valid then state.tag.destroy() end
  state.tag = nil
end

function staging.on_chunk_charted(state, event)
  if (state.tag and state.tag.valid) or not state.nest_position or event.force.name ~= "player" then return end
  local p = state.nest_position
  if event.position.x ~= math.floor(p.x / 32) or event.position.y ~= math.floor(p.y / 32) then return end
  add_tag(state, game.surfaces[event.surface_index])
end

return staging
