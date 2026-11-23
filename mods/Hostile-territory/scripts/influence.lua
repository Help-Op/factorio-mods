-- Influence map (ring2-challenge-plan.md 4e2; R2-D36, D37; ring-feel-plan.md RF-D36): the hive's hidden memory, one
-- cell per chunk around every territory at war. The first piece of the shared hive AI; the retake army (hive.lua)
-- reads it to pick which fallen district to take back. Later steps read it for routes, probes and prediction.
--   threat: player turrets (TURRET_THREAT by type, spread over the chunks in their range), participants (characters
--     and driven vehicles, PARTICIPANT_THREAT each) and hive units that died in the chunk (DEATH_THREAT each,
--     halving every DEATH_HALF_LIFE).
--   value: player buildings in the chunk (any entity of a player force whose prototype is a building).
--   control: "hive" (enemy spawners or turrets, no player buildings), "player" (player buildings, no hive ones),
--     "contested" (both) or "none".
-- Updated every INTERVAL for the chunks within RADIUS of each warring territory's brain. Nothing goes on the map;
-- `/ht-influence` draws it for one player (debug, RF-D22).
-- storage.influence = {cells = {[key] = {x, y, threat, value, control, deaths}}, territories = {[id] = {keys}},
--   viewers = {[player index] = true}}

local influence = {}

influence.INTERVAL = 300
local RADIUS = 200
local DEATH_THREAT = 0.5
local DEATH_HALF_LIFE = 60 * 60
local PARTICIPANT_THREAT = 3
local TURRET_THREAT = {["ammo-turret"] = 2, ["electric-turret"] = 3, ["fluid-turret"] = 4, ["artillery-turret"] = 1}
local TURRET_RANGE = {["ammo-turret"] = 18, ["electric-turret"] = 24, ["fluid-turret"] = 30, ["artillery-turret"] = 0}

local function init_storage()
  storage.influence = storage.influence or {cells = {}, territories = {}, viewers = {}}
end

local function key_of(cx, cy) return cx .. "," .. cy end
local function chunk_of(position) return math.floor(position.x / 32), math.floor(position.y / 32) end

local function cell(cx, cy)
  local cells = storage.influence.cells
  local k = key_of(cx, cy)
  local c = cells[k]
  if not c then
    c = {x = cx, y = cy, threat = 0, value = 0, control = "none", deaths = 0, death_tick = game.tick}
    cells[k] = c
  end
  return c
end

local function player_force(force) return force.name == "player" or #force.players > 0 end

local function player_forces()
  local list = {}
  for _, force in pairs(game.forces) do if player_force(force) then list[#list + 1] = force end end
  return list
end

-- Decayed death count of a cell now.
local function deaths_now(c)
  return c.deaths * 0.5 ^ ((game.tick - c.death_tick) / DEATH_HALF_LIFE)
end

-- A player entity that holds ground: a building (pole, turret, wall, ...), not a character, vehicle or robot.
function influence.is_building(e)
  return e.valid and e.prototype.is_building and e.type ~= "character" and e.type ~= "car" and e.type ~= "spider-vehicle"
end

-- on_entity_died of a hive unit: more threat in its chunk.
function influence.on_unit_died(entity)
  init_storage()
  if entity.force.name ~= "enemy" then return end
  local cx, cy = chunk_of(entity.position)
  local c = storage.influence.cells[key_of(cx, cy)]
  if not c then return end -- only chunks of a territory at war
  c.deaths, c.death_tick = deaths_now(c) + 1, game.tick
end

-- Recompute the cells of one territory, brain head at centre.
local function update_territory(surface, id, centre, forces)
  local keys = {}
  local x0, y0 = math.floor((centre.x - RADIUS) / 32), math.floor((centre.y - RADIUS) / 32)
  local x1, y1 = math.floor((centre.x + RADIUS) / 32), math.floor((centre.y + RADIUS) / 32)
  for cx = x0, x1 do
    for cy = y0, y1 do
      local c = cell(cx, cy)
      c.threat, c.value, c.hive, c.control = 0, 0, 0, "none"
      keys[#keys + 1] = key_of(cx, cy)
    end
  end
  local area = {{x0 * 32, y0 * 32}, {(x1 + 1) * 32, (y1 + 1) * 32}}
  local cells = storage.influence.cells
  for _, e in pairs(surface.find_entities_filtered{area = area, force = forces}) do
    local cx, cy = chunk_of(e.position)
    local c = cells[key_of(cx, cy)]
    if c then
      if influence.is_building(e) then c.value = c.value + 1 end
      local t = TURRET_THREAT[e.type]
      if t then
        -- full threat in its own chunk, less in the chunks its range reaches into
        local reach = math.ceil(TURRET_RANGE[e.type] / 32)
        for dx = -reach, reach do
          for dy = -reach, reach do
            local other = cells[key_of(cx + dx, cy + dy)]
            if other then other.threat = other.threat + t / (1 + math.abs(dx) + math.abs(dy)) end
          end
        end
      elseif (e.type == "character") or ((e.type == "car" or e.type == "spider-vehicle") and e.get_driver()) then
        c.threat = c.threat + PARTICIPANT_THREAT
      end
    end
  end
  for _, e in pairs(surface.find_entities_filtered{area = area, force = "enemy", type = {"unit-spawner", "turret"}}) do
    local cx, cy = chunk_of(e.position)
    local c = cells[key_of(cx, cy)]
    if c then c.hive = c.hive + 1 end
  end
  for _, k in pairs(keys) do
    local c = cells[k]
    c.threat = c.threat + DEATH_THREAT * deaths_now(c)
    if c.value > 0 then c.control = c.hive > 0 and "contested" or "player"
    elseif c.hive > 0 then c.control = "hive" end
  end
  storage.influence.territories[id] = keys
end

-- Every INTERVAL: centres = {[territory id] = brain head position} of the territories at war (war.lua).
function influence.update(surface, centres)
  init_storage()
  local forces = player_forces()
  local keep = {}
  for id, centre in pairs(centres) do
    update_territory(surface, id, centre, forces)
    for _, k in pairs(storage.influence.territories[id]) do keep[k] = true end
  end
  for id in pairs(storage.influence.territories) do
    if not centres[id] then storage.influence.territories[id] = nil end
  end
  for k in pairs(storage.influence.cells) do
    if not keep[k] then storage.influence.cells[k] = nil end
  end
  influence.draw(surface)
end

-- Threat, value and control summed over the chunks within r of position (cells only where a territory is at war).
function influence.around(position, r)
  init_storage()
  local threat, value, n = 0, 0, 0
  local x0, y0 = math.floor((position.x - r) / 32), math.floor((position.y - r) / 32)
  local x1, y1 = math.floor((position.x + r) / 32), math.floor((position.y + r) / 32)
  for cx = x0, x1 do
    for cy = y0, y1 do
      local c = storage.influence.cells[key_of(cx, cy)]
      if c then threat, value, n = threat + c.threat, value + c.value, n + 1 end
    end
  end
  return threat, value, n
end

-- The cells of a territory at war (its last update), as a list.
function influence.cells(id)
  init_storage()
  local list = {}
  for _, k in pairs(storage.influence.territories[id] or {}) do
    local c = storage.influence.cells[k]
    if c then list[#list + 1] = c end
  end
  return list
end

-- Debug view ---------------------------------------------------------------------------------------------------------

local CONTROL_COLOUR = {hive = {0.5, 0.1, 0.6, 0.25}, player = {0.1, 0.4, 0.9, 0.25}, contested = {0.9, 0.6, 0.1, 0.3}}

function influence.draw(surface)
  init_storage()
  local viewers = {}
  for index in pairs(storage.influence.viewers) do
    local player = game.get_player(index)
    if player and player.connected then viewers[#viewers + 1] = player else storage.influence.viewers[index] = nil end
  end
  if #viewers == 0 then return end
  local ttl = influence.INTERVAL + 2
  for _, c in pairs(storage.influence.cells) do
    local lt, rb = {c.x * 32 + 1, c.y * 32 + 1}, {c.x * 32 + 31, c.y * 32 + 31}
    local colour = CONTROL_COLOUR[c.control]
    if colour then
      rendering.draw_rectangle{color = colour, filled = true, left_top = lt, right_bottom = rb, surface = surface,
        time_to_live = ttl, players = viewers, draw_on_ground = true}
    end
    if c.threat > 0.05 then
      local a = math.min(0.6, c.threat / 20)
      rendering.draw_rectangle{color = {1, 0, 0, a}, width = 4, filled = false, left_top = lt, right_bottom = rb,
        surface = surface, time_to_live = ttl, players = viewers}
    end
    if c.threat > 0.05 or c.value > 0 then
      rendering.draw_text{text = string.format("T %.1f  V %d", c.threat, c.value), surface = surface,
        target = {c.x * 32 + 16, c.y * 32 + 16}, color = {1, 1, 1}, scale = 2, time_to_live = ttl, players = viewers,
        alignment = "center", vertical_alignment = "middle"}
    end
  end
end

-- /ht-influence: switch the view for a player; returns true when it's now on.
function influence.toggle(player)
  init_storage()
  local on = not storage.influence.viewers[player.index]
  storage.influence.viewers[player.index] = on or nil
  return on
end

function influence.describe()
  init_storage()
  local cells, threat, value, held = 0, 0, 0, 0
  for _, c in pairs(storage.influence.cells) do
    cells, threat, value = cells + 1, threat + c.threat, value + c.value
    if c.control == "player" or c.control == "contested" then held = held + 1 end
  end
  return string.format("Influence: %d chunks, threat %.1f, value %d, %d chunks held by you.", cells, threat, value, held)
end

return influence
