-- Challenges: started when a guardian is engaged and a player is nearby; won when the territory is claimed;
-- lost when for LOSE_GRACE ticks no guardian is engaged or no participant is near a guardian.
-- While a participant is near, guardians are kept enraged at the nearest participant (so a challenge
-- started by building doesn't end when the building is destroyed).
-- storage.challenges[territory_id] = {territory_id, players = {[player_index] = true}, started_tick, lose_since_tick}
-- storage.player_challenge[player_index] = territory_id

local territories = require("scripts.territories")
local waves = require("scripts.waves")

local challenge = {}

challenge.CHECK_INTERVAL = 30
local RANGE = 100
local LOSE_GRACE = 5 * 60
local RAGE_REFRESH_BELOW = 15 * 60 -- refresh last_damage_time when less rage than this is left

local ENGAGED = {
  [defines.segmented_unit_ai_state.attacking] = true,
  [defines.segmented_unit_ai_state.enraged_at_target] = true,
  [defines.segmented_unit_ai_state.enraged_at_nothing] = true,
}

local function init_storage()
  storage.challenges = storage.challenges or {}
  storage.player_challenge = storage.player_challenge or {}
end

local function notify(record, message)
  for index in pairs(record.players) do
    local player = game.get_player(index)
    if player and player.connected then player.print(message) end
  end
end

-- Characters of connected players near any of the given positions, keyed by player index.
local function players_near(surface, positions)
  local found = {}
  local range_squared = RANGE * RANGE
  for _, player in pairs(game.connected_players) do
    local character = player.character
    if character and character.surface == surface then
      local p = character.position
      for _, q in pairs(positions) do
        if (p.x - q.x) ^ 2 + (p.y - q.y) ^ 2 <= range_squared then
          found[player.index] = player
          break
        end
      end
    end
  end
  return found
end

local function participant_near(record, surface, positions)
  if not positions then return false end
  for index in pairs(players_near(surface, positions)) do
    if record.players[index] then return true end
  end
  return false
end

-- What a guardian should chase for this player: their vehicle if they're in one, else the character.
local function chase_target(player)
  local character = player.character
  return character.vehicle or character
end

local function is_participant_entity(record, entity)
  if not (entity and entity.valid) then return false end
  for index in pairs(record.players) do
    local player = game.get_player(index)
    if player and player.character and (entity == player.character or entity == player.character.vehicle) then
      return true
    end
  end
  return false
end

-- Nearest participant (within RANGE) to a position, or nil.
local function nearest_participant(record, surface, position)
  local best, best_distance
  for index in pairs(players_near(surface, {position})) do
    if record.players[index] then
      local player = game.get_player(index)
      local p = player.character.position
      local distance = (p.x - position.x) ^ 2 + (p.y - position.y) ^ 2
      if not best_distance or distance < best_distance then best, best_distance = player, distance end
    end
  end
  return best
end

-- Returns true if the guardian is (now) engaged with a participant.
local function keep_engaged(record, surface, unit)
  local head = unit.segments[1]
  if not head then return false end
  local player = nearest_participant(record, surface, head.position)
  if not player then return false end
  local state = unit.get_ai_state()
  local enraged_at_participant = state.type == defines.segmented_unit_ai_state.enraged_at_target
    and is_participant_entity(record, state.target)
  if enraged_at_participant and state.remaining_time >= RAGE_REFRESH_BELOW then return true end
  unit.set_ai_state{
    type = defines.segmented_unit_ai_state.enraged_at_target,
    target = enraged_at_participant and state.target or chase_target(player),
    attacked_me = true,
    last_damage_time = game.tick,
  }
  return true
end

local function join(record, player)
  if storage.player_challenge[player.index] then return end
  record.players[player.index] = true
  storage.player_challenge[player.index] = record.territory_id
  player.print(string.format("Challenge started: territory %d.", record.territory_id))
end

local function start(territory_record, surface, origin)
  local record = {territory_id = territory_record.id, players = {}, started_tick = game.tick}
  waves.init(record, surface, origin)
  storage.challenges[territory_record.id] = record
  territories.set_state(territory_record, "challenge")
  return record
end

local function finish(record, message)
  notify(record, message)
  for index in pairs(record.players) do
    storage.player_challenge[index] = nil
  end
  storage.challenges[record.territory_id] = nil
end

local function lose(record)
  local territory_record = storage.territories[record.territory_id]
  if territory_record and territory_record.territory.valid then
    for _, unit in pairs(territory_record.territory.get_segmented_units()) do
      if unit.valid then unit.health = unit.max_health end
    end
    territories.set_state(territory_record, "hostile")
  end
  waves.clear(record)
  finish(record, string.format("Challenge lost: territory %d. The guardian recovers.", record.territory_id))
end

function challenge.on_won(territory_id)
  init_storage()
  local record = storage.challenges[territory_id]
  if record then
    waves.flee(record)
    finish(record, string.format("Challenge won: territory %d claimed.", territory_id))
  end
end

function challenge.on_tick()
  init_storage()
  local surface = game.surfaces[territories.surface_name]
  if not surface then return end

  -- Per territory: guardian head positions and whether any guardian is engaged.
  local heads, engaged, units = {}, {}, {}
  for _, unit in pairs(surface.get_segmented_units()) do
    local territory_record = territories.get(unit.territory)
    if territory_record then
      local id = territory_record.id
      units[id] = units[id] or {}
      table.insert(units[id], unit)
      local head = unit.segments[1]
      if head then
        heads[id] = heads[id] or {}
        table.insert(heads[id], head.position)
      end
      if ENGAGED[unit.get_ai_state().type] then engaged[id] = true end
    end
  end

  -- Start and join.
  for id in pairs(engaged) do
    local territory_record = storage.territories[id]
    local nearby = heads[id] and players_near(surface, heads[id]) or {}
    if next(nearby) then
      local record = storage.challenges[id]
      if not record and territory_record.state == "hostile" then
        record = start(territory_record, surface, heads[id][1])
      end
      if record then
        for _, player in pairs(nearby) do join(record, player) end
      end
    end
  end

  -- Keep guardians engaged with nearby participants.
  for id, record in pairs(storage.challenges) do
    for _, unit in pairs(units[id] or {}) do
      if keep_engaged(record, surface, unit) then engaged[id] = true end
    end
  end

  -- Waves around participants near the guardian.
  for id, record in pairs(storage.challenges) do
    local targets = {}
    for index, player in pairs(heads[id] and players_near(surface, heads[id]) or {}) do
      if record.players[index] then targets[#targets + 1] = {player = player, entity = chase_target(player)} end
    end
    waves.update(record, surface, targets)
  end
  waves.update_fleeing()

  -- Lose.
  for id, record in pairs(storage.challenges) do
    if not storage.territories[id] then
      waves.clear(record)
      finish(record, string.format("Challenge ended: territory %d is gone.", id))
    elseif engaged[id] and participant_near(record, surface, heads[id]) then
      record.lose_since_tick = nil
    else
      record.lose_since_tick = record.lose_since_tick or game.tick
      if game.tick - record.lose_since_tick >= LOSE_GRACE then lose(record) end
    end
  end
end

function challenge.describe()
  init_storage()
  local lines = {}
  for id, record in pairs(storage.challenges) do
    local names = {}
    for index in pairs(record.players) do
      local player = game.get_player(index)
      names[#names + 1] = player and player.name or tostring(index)
    end
    lines[#lines + 1] = string.format("Territory %d: %ds, players: %s%s", id, math.floor((game.tick - record.started_tick) / 60),
      table.concat(names, ", "), waves.describe(record) .. (record.lose_since_tick and " (losing)" or ""))
  end
  if #lines == 0 then return "No running challenges." end
  return table.concat(lines, "\n")
end

return challenge
