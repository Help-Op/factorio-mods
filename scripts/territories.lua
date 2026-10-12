-- Registry of Nauvis territories and their state.
-- storage.territories[id] = {id, territory, state, overlay = {["x,y"] = LuaRenderObject}, centre = MapPosition (cached),
--   guardian = segmented-unit prototype name (last seen guarding it)}
-- The id is the registration number from script.register_on_object_destroyed, which is stable
-- and returned again when the same territory is registered twice.

local overlay = require("scripts.overlay")

local territories = {}

territories.surface_name = "nauvis"

-- hostile/claimed are set automatically from guardian count; the others come from later phases.
territories.states = {
  hostile = true,
  challenge = true,
  claimed = true,
  warning = true,
  crusade = true,
}

local function get_id(territory)
  return (script.register_on_object_destroyed(territory))
end

local function is_tracked_surface(surface)
  return surface.name == territories.surface_name
end

-- Counts guardians, optionally ignoring one unit (the one that is dying right now).
local function guardian_count(territory, ignored_unit_number)
  local count = 0
  for _, unit in pairs(territory.get_segmented_units()) do
    if unit.valid and unit.unit_number ~= ignored_unit_number then
      count = count + 1
    end
  end
  return count
end

local function remember_guardian(record)
  for _, unit in pairs(record.territory.get_segmented_units()) do
    if unit.valid then
      record.guardian = unit.prototype.name
      return
    end
  end
end

local function default_state(territory)
  return guardian_count(territory) > 0 and "hostile" or "claimed"
end

function territories.get(territory)
  if not (territory and territory.valid and is_tracked_surface(territory.surface)) then return nil end
  storage.territories = storage.territories or {}
  local id = get_id(territory)
  local record = storage.territories[id]
  if not record then
    record = {id = id, territory = territory, state = default_state(territory), overlay = {}}
    storage.territories[id] = record
    remember_guardian(record)
  end
  return record
end

function territories.get_at(surface, map_position)
  local chunk = {x = math.floor(map_position.x / 32), y = math.floor(map_position.y / 32)}
  return territories.get(surface.get_territory_for_chunk(chunk))
end

-- Average of the territory's chunk centres, cached on the record. Nil if it has no chunks.
function territories.centre(record)
  if not record.centre then
    local x, y, n = 0, 0, 0
    for _, chunk in pairs(record.territory.get_chunks()) do
      x, y, n = x + chunk.x * 32 + 16, y + chunk.y * 32 + 16, n + 1
    end
    if n == 0 then return nil end
    record.centre = {x = x / n, y = y / n}
  end
  return record.centre
end

function territories.set_state(record, state)
  if record.state == state then return end
  record.state = state
  overlay.redraw(record)
end

function territories.remove_id(id)
  local record = storage.territories[id]
  if not record then return end
  overlay.clear(record)
  storage.territories[id] = nil
end

-- Rebuilds the registry from the surface. Keeps non-automatic states; drops records whose territory is gone.
function territories.scan()
  storage.territories = storage.territories or {}
  for id, record in pairs(storage.territories) do
    if not record.territory.valid then territories.remove_id(id) end
  end
  local surface = game.surfaces[territories.surface_name]
  if not surface then return end
  for _, territory in pairs(surface.get_territories()) do
    local record = territories.get(territory)
    if record.state == "hostile" or record.state == "claimed" then
      record.state = default_state(territory)
    end
    if not record.guardian then remember_guardian(record) end
    overlay.redraw(record)
  end
end

-- Event handlers -------------------------------------------------------------

function territories.on_territory_created(event)
  territories.get(event.territory)
end

function territories.on_territory_destroyed(event)
  territories.remove_id(get_id(event.territory))
end

function territories.on_object_destroyed(event)
  if event.type == defines.target_type.territory then
    territories.remove_id(event.registration_number)
  end
end

function territories.on_segmented_unit_created(event)
  local record = territories.get(event.segmented_unit.territory)
  if record then record.guardian = event.segmented_unit.prototype.name end
  if record and record.state == "claimed" then
    territories.set_state(record, "hostile")
  end
end

-- Returns the record if this death claimed the territory.
function territories.on_segmented_unit_died(event)
  local unit = event.segmented_unit
  local record = territories.get(unit.territory)
  if record and guardian_count(record.territory, unit.unit_number) == 0 then
    territories.set_state(record, "claimed")
    return record
  end
end

function territories.on_chunk_charted(event)
  if event.force.name ~= "player" then return end
  local surface = game.surfaces[event.surface_index]
  if not is_tracked_surface(surface) then return end
  local record = territories.get(surface.get_territory_for_chunk(event.position))
  if record then overlay.draw_chunk(record, event.position) end
end

return territories
