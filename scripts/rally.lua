-- Crusade rally (phase H): what to build, how long it takes and where.
-- Guardian = the one last seen in the territory (territories.lua), else the map gen rule on the territory centre:
-- floor(clamp(distance / 576 - 0.25, 0, 2)) → small / medium / big (prototypes/planet/nauvis-territory.lua).
-- Rally prototype ht-rally-<size> and build time follow the guardian size (H-c).
-- Spot = a random patrol path point inside the target territory, moved to free space for the rally;
-- the moved spot must still be inside the target.
-- Building (H-4/H-5): builders = 10 % of the army (5–20); each sacrificed builder adds max_health / builders.
-- The rally gets a map tag (H-13).

local territories = require("scripts.territories")
local tags = require("scripts.tags")

local rally = {}

local GUARDIANS = {"small-demolisher", "medium-demolisher", "big-demolisher"}
local SIZE = {["small-demolisher"] = "small", ["medium-demolisher"] = "medium", ["big-demolisher"] = "big"}
local BUILD_TIME = {small = 5 * 60 * 60, medium = 15 * 60 * 60, big = 30 * 60 * 60}
local SPOT_SEARCH_RADIUS = 20
local TAG_TEXT = "Crusade rally"
rally.NAMES = {"ht-rally-small", "ht-rally-medium", "ht-rally-big"}

local function in_territory(surface, record, position)
  return surface.get_territory_for_chunk({x = math.floor(position.x / 32), y = math.floor(position.y / 32)}) == record.territory
end

function rally.guardian_for(record, surface)
  if record.guardian and SIZE[record.guardian] then return record.guardian end
  local centre = territories.centre(record)
  if not centre then return GUARDIANS[1] end
  local spawn = game.forces.player.get_spawn_position(surface)
  local distance = math.sqrt((centre.x - spawn.x) ^ 2 + (centre.y - spawn.y) ^ 2)
  return GUARDIANS[math.floor(math.max(0, math.min(2, distance / 576 - 0.25))) + 1]
end

-- Returns guardian name, rally prototype name, build time in ticks.
function rally.plan(record, surface)
  local guardian = rally.guardian_for(record, surface)
  local size = SIZE[guardian]
  return guardian, "ht-rally-" .. size, BUILD_TIME[size]
end

-- A free spot for the rally on the target's patrol path, or nil.
function rally.pick_spot(record, surface, rally_name)
  local function in_target(position) return in_territory(surface, record, position) end
  local inside = {}
  for _, point in pairs(record.territory.get_patrol_path()) do
    if in_target(point) then inside[#inside + 1] = point end
  end
  while #inside > 0 do
    local i = math.random(#inside)
    local spot = surface.find_non_colliding_position(rally_name, inside[i], SPOT_SEARCH_RADIUS, 1)
    if spot and in_target(spot) then return spot end
    table.remove(inside, i)
  end
  return nil
end

function rally.in_target(surface, record, position)
  return in_territory(surface, record, position)
end

-- A free spot for the rally near position, inside the target; or nil.
function rally.spot_near(record, surface, rally_name, position)
  local spot = surface.find_non_colliding_position(rally_name, position, SPOT_SEARCH_RADIUS, 1)
  if spot and in_territory(surface, record, spot) then return spot end
  return nil
end

-- Player military (H-8, 7a): anything that can damage enemies; walls and other buildings don't count.
-- Characters come first (H-15): other military is only picked when no character is in the territory.
local CHARACTER_TYPES = {"character"}
local OTHER_MILITARY_TYPES = {"ammo-turret", "electric-turret", "fluid-turret", "artillery-turret", "car",
  "spider-vehicle", "combat-robot", "artillery-wagon"}

-- The entity of the given types in the territory closest to near (one candidate per chunk), or nil.
local function find_nearest(record, surface, near, types)
  local best, best_distance
  for _, chunk in pairs(record.territory.get_chunks()) do
    local found = surface.find_entities_filtered{area = chunk.area, force = "player", type = types, limit = 1}[1]
    if found then
      local d = (found.position.x - near.x) ^ 2 + (found.position.y - near.y) ^ 2
      if not best_distance or d < best_distance then best, best_distance = found, d end
    end
  end
  return best
end

-- The player character in the territory closest to near; else other player military closest to near; or nil.
function rally.find_player_military(record, surface, near)
  return find_nearest(record, surface, near, CHARACTER_TYPES) or find_nearest(record, surface, near, OTHER_MILITARY_TYPES)
end

function rally.builder_count(alive)
  return math.min(alive, math.max(5, math.min(20, math.floor(alive * 0.1 + 0.5))))
end

-- Places the rally at state.rally_spot (or the nearest free spot, or a new patrol spot) with 1 health.
-- Returns the entity, or nil if there is no room.
function rally.place(state, surface, record)
  local spot = state.rally_spot
  if not surface.can_place_entity{name = state.rally_name, position = spot, force = "enemy"} then
    spot = rally.spot_near(record, surface, state.rally_name, spot) or rally.pick_spot(record, surface, state.rally_name)
  end
  if not spot then return nil end
  local entity = surface.create_entity{name = state.rally_name, position = spot, force = "enemy"}
  if not entity then return nil end
  entity.health = 1
  state.rally_spot = entity.position
  return entity
end

local function icon(state)
  return {type = "entity", name = state.rally_name}
end

function rally.mark(state, surface)
  tags.remove(state.rally_tag)
  state.rally_tag = tags.place(surface, state.rally_spot, icon(state), TAG_TEXT)
end

function rally.unmark(state)
  tags.remove(state.rally_tag)
  state.rally_tag = nil
end

function rally.on_chunk_charted(state, event)
  if not state.rally or (state.rally_tag and state.rally_tag.valid) then return end
  state.rally_tag = tags.retry(event, state.rally_spot, icon(state), TAG_TEXT)
end

return rally
