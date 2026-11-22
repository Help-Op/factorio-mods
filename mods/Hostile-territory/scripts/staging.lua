-- Staging point for a crusade (phase G): an existing enemy nest in a hostile territory next to the target.
-- Candidates: hostile territories touching the target (a chunk next to one of its chunks) that have a nest.
-- A touching territory whose base isn't generated yet (one base per territory, territory-brain-plan.md B-I9) gets
-- the chunks around its point generated first (map gen builds the base, brain.lua places the brain). A point on
-- water has no base (brain.lua claims that territory), so it's skipped.
-- Pick the one whose centre is furthest from spawn, so the army gathers on the far side of the target.
-- Fallback: the hostile territory with a nest whose centre is nearest to the target centre.
-- Nests are never built: no candidate → no staging → no crusade.
-- The staging nest gets a map tag for the player force (scripts/tags.lua).

local territories = require("scripts.territories")
local tags = require("scripts.tags")
local brain = require("scripts.brain")

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

-- Generates the chunks around the territory's point (its base: ring radius 18 + nest size fits in 3x3 chunks)
-- if they aren't yet, and around its land spot when the point is on water (brain.lua moves the base there,
-- R2-E1 4b). Returns true if the base can exist (the territory still has its brain).
local function ensure_base(record, surface)
  local chunk = record.territory.get_chunks()[1]
  if not chunk then return false end
  local p = surface.calculate_tile_properties({"hostile_point_nearest_x", "hostile_point_nearest_y"},
    {{chunk.x * 32 + 16, chunk.y * 32 + 16}})
  local point = {x = p.hostile_point_nearest_x[1] + 0.5, y = p.hostile_point_nearest_y[1] + 0.5}
  local cx, cy = math.floor(point.x / 32), math.floor(point.y / 32)
  local missing = false
  for dx = -1, 1 do
    for dy = -1, 1 do
      if not surface.is_chunk_generated({cx + dx, cy + dy}) then missing = true end
    end
  end
  local home = brain.home(surface, {x = point.x - 0.5, y = point.y - 0.5})
  if home and (home.x ~= point.x - 0.5 or home.y ~= point.y - 0.5) then
    local hx, hy = math.floor(home.x / 32), math.floor(home.y / 32)
    for dx = -2, 2 do
      for dy = -2, 2 do
        if not surface.is_chunk_generated({hx + dx, hy + dy}) then missing = true end
      end
    end
    if missing then surface.request_to_generate_chunks({home.x + 0.5, home.y + 0.5}, 2) end
  end
  if missing then
    surface.request_to_generate_chunks(point, 1)
    surface.force_generate_chunk_requests()
  end
  for _, unit in pairs(record.territory.get_segmented_units()) do
    if unit.valid then return true end
  end
  return false
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
        if not nest and ensure_base(record, surface) then nest = nearest_nest(record, surface, target_centre) end
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

local function icon(state)
  return {type = "entity", name = state.nest.valid and state.nest.name or "biter-spawner"}
end

function staging.mark(state, surface)
  state.tag = tags.place(surface, state.nest_position, icon(state), TAG_TEXT)
end

function staging.unmark(state)
  tags.remove(state.tag)
  state.tag = nil
end

function staging.on_chunk_charted(state, event)
  if (state.tag and state.tag.valid) or not state.nest_position then return end
  state.tag = tags.retry(event, state.nest_position, icon(state), TAG_TEXT)
end

return staging
