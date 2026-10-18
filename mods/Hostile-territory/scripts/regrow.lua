-- Base regrowth (territory-brain-plan.md B5, B-D6/B-D8).
-- Every INTERVAL, each hostile territory with a registered base gets back one missing piece: core worms first,
-- then the ring nests. Same layout as map gen (prototypes/planet/brain-bases.lua), computed here in Lua with the
-- same formulas on the same integer tile offsets, so a regrown piece lands on the tile map gen used.
-- A base is registered by its brain's centre tile: by brain.lua when it moves a brain onto its point, and by
-- crusade.lua when a lost territory gets its new brain at the rally spot (no base there yet: it grows from nothing).
-- Only "hostile" territories regrow (not during a challenge, warning or crusade, not once claimed).
-- A slot is skipped while something blocks it (water, cliff, player buildings); it's tried again next time.
-- storage.bases[territory id] = {x, y} centre tile (the brain stands on x + 0.5, y + 0.5).

local territories = require("scripts.territories")

local regrow = {}

regrow.INTERVAL = 60 * 60

-- layout, as in brain-bases.lua and nauvis-territory.lua
local G = 384
local FAR_START = 420 -- hostile_point_start_radius in nauvis-territory.lua: bases grow from here out
local FAR = 2400
local RING_R = 18
local CORE_R = 6
local TWO_PI = 2 * math.pi

function regrow.init()
  storage.bases = storage.bases or {}
end

function regrow.register(record, centre)
  storage.bases[record.id] = {x = math.floor(centre.x), y = math.floor(centre.y)}
end

local function worm_for(distance)
  if distance < 700 then return "small-worm-turret" end
  if distance < 1400 then return "medium-worm-turret" end
  if distance < 2400 then return "big-worm-turret" end
  return "behemoth-worm-turret"
end

local function round(v) return math.floor(v + 0.5) end

-- The base's slots in build order: {name, type, x, y} with x, y the tile; entities stand on x + 0.5, y + 0.5.
-- rotation comes from the noise (per grid cell), so it matches map gen for bases on their point.
local function slots(surface, base)
  local rotation = surface.calculate_tile_properties({"hostile_base_rotation"}, {{base.x, base.y}}).hostile_base_rotation[1]
  local distance = math.sqrt(base.x * base.x + base.y * base.y)
  local far = math.max(0, math.min(1, (distance - FAR_START) / (FAR - FAR_START)))
  local list = {}
  -- core: 4 slots, those with (index + 100) % 4 < 1 + M (index as map gen computes it from the tile offset)
  local m = math.floor(3 * far + 0.5)
  for k = 0, 3 do
    local a = k * TWO_PI / 4 + rotation
    local dx, dy = round(CORE_R * math.cos(a)), round(CORE_R * math.sin(a))
    local index = math.floor((math.atan2(dy, dx) - rotation) * 4 / TWO_PI + 0.5)
    if (index + 100) % 4 < 1 + m then
      list[#list + 1] = {name = worm_for(distance), type = "turret", x = base.x + dx, y = base.y + dy}
    end
  end
  -- ring: N slots, biter and spitter spawners by the parity of the slot index
  local n = 6 + math.floor(4 * far + 0.5)
  for k = 0, n - 1 do
    local a = k * TWO_PI / n + rotation
    local dx, dy = round(RING_R * math.cos(a)), round(RING_R * math.sin(a))
    local index = math.floor((math.atan2(dy, dx) - rotation) * n / TWO_PI + 0.5)
    local name = (index + 100) % 2 == 0 and "biter-spawner" or "spitter-spawner"
    list[#list + 1] = {name = name, type = "unit-spawner", x = base.x + dx, y = base.y + dy}
  end
  return list
end

local function has_brain(record)
  for _, unit in pairs(record.territory.get_segmented_units()) do
    if unit.valid then return true end
  end
  return false
end

-- Builds the first missing piece of one base. Returns the entity, or nil if nothing was built.
function regrow.step(surface, record, base)
  for _, slot in pairs(slots(surface, base)) do
    local position = {slot.x + 0.5, slot.y + 0.5}
    if surface.count_entities_filtered{position = position, radius = 1.5, type = slot.type, force = "enemy"} == 0
        and surface.can_place_entity{name = slot.name, position = position, force = "enemy"} then
      return surface.create_entity{name = slot.name, position = position, force = "enemy"}
    end
  end
end

function regrow.on_tick()
  local surface = game.surfaces[territories.surface_name]
  if not surface then return end
  for id, base in pairs(storage.bases) do
    local record = storage.territories and storage.territories[id]
    if not (record and record.territory.valid) then
      storage.bases[id] = nil
    elseif record.state == "hostile" and has_brain(record) then
      regrow.step(surface, record, base)
    end
  end
end

-- Debug: n regrowth rounds at once. Returns the number of pieces built.
function regrow.run(n)
  local surface = game.surfaces[territories.surface_name]
  local built = 0
  for _ = 1, n do
    for id, base in pairs(storage.bases) do
      local record = storage.territories and storage.territories[id]
      if record and record.territory.valid and record.state == "hostile" and has_brain(record)
          and regrow.step(surface, record, base) then
        built = built + 1
      end
    end
  end
  return built
end

function regrow.describe()
  local count = 0
  for _ in pairs(storage.bases) do count = count + 1 end
  return string.format("Bases that regrow: %d (one piece per %d s each while hostile).", count, math.floor(regrow.INTERVAL / 60))
end

return regrow
