-- Challenge telemetry (oil-ring-challenge-plan.md OR-E2, OR-D18): one CSV per challenge in
-- script-output/ht-telemetry/<start tick>-t<territory id>.csv, a row per participant every SAMPLE ticks.
-- Written every FLUSH ticks while the challenge runs (a crash keeps the data), on a participant's death, and when it
-- ends, with a summary line
-- ("# ..."): outcome, duration, seconds per phase, peak HP/s, longest time over the director's budget, deaths.
-- Director values come from record.director (director.lua), so call director.update first.
-- record.telemetry = {file, rows, header_written, next_sample, next_flush, kills = {[damage type] = n},
--   peak, over, longest_over, phase_s = {[phase] = seconds}, deaths, start_tick}

local waves = require("scripts.waves")
local director = require("scripts.director")
local brain_fight = require("scripts.brain-fight")

local telemetry = {}

local SAMPLE = 60
local FLUSH = 30 * 60
local AMMO = {
  {"red", "piercing-rounds-magazine"}, {"yellow", "firearm-magazine"}, {"shells", "shotgun-shell"},
  {"grenades", "grenade"},
}
local KILL_TYPES = {"physical", "explosion", "impact"}

local function header()
  local columns = {"second", "participant", "phase", "brain_pct", "hp", "max_hp", "hp_per_s", "budget", "director",
    "touching", "ring", "held", "alive", "surge", "swarm_left", "nests",
    -- OR-E6: brain shield, units per squad state, units in the closing ring, running totals (brain-fight.lua stats)
    "shield", "squad_form", "squad_ready", "squad_tell", "closing", "charges", "charged", "guard_rush", "stand_still",
    "rocks", "openings",
    -- OR-E7: shield bearers alive, regroup (off / pulled), regroups so far, arena rocks
    "bearers", "regroup", "regroups", "arena",
    -- OR-D59 (PT8, PT9: two deaths nobody could explain): the biggest single hit this second and what dealt it
    "max_hit", "max_hit_by",
    -- OR-E9: the brain sees a chokepoint (and its direction, degrees, 0 = east), squads with no way round
    "choke", "choke_dir", "blocked",
    -- OR-E8 E8-A / A2: anchor nests alive, share of a hit the brain keeps now, shield links alive (anchors + bearers)
    "anchors", "brain_take", "links",
    -- OR-E8 E8-B: queens alive, biters the queens spawned so far
    "queens", "queen_spawned",
    -- OR-E10: the director's continuous stream (on / off) and units streamed so far
    "stream", "streamed",
    -- OR-E11: the queens' level (extra biters per queen spawn, raised while you're calm)
    "queen_level"}
  for _, name in ipairs(KILL_TYPES) do columns[#columns + 1] = "kills_" .. name end
  columns[#columns + 1] = "kills_other"
  for _, ammo in ipairs(AMMO) do columns[#columns + 1] = ammo[1] end
  return table.concat(columns, ",")
end

local function state(record)
  if not record.telemetry then
    local start = record.started_tick or game.tick
    record.telemetry = {
      file = string.format("ht-telemetry/%d-t%d.csv", start, record.territory_id),
      rows = {}, next_sample = game.tick, next_flush = game.tick + FLUSH, kills = {},
      peak = 0, over = 0, longest_over = 0, phase_s = {}, deaths = 0, start_tick = start,
    }
  end
  return record.telemetry
end

local function flush(t)
  if not t.header_written then
    helpers.write_file(t.file, header() .. "\n", false)
    t.header_written = true
  end
  if #t.rows > 0 then helpers.write_file(t.file, table.concat(t.rows, "\n") .. "\n", true) end
  t.rows = {}
end

local function count_item(character, name)
  if not prototypes.item[name] then return 0 end
  local n = 0
  local player = character.player -- OR-D25: the stack in the cursor (e.g. grenades being thrown) counts too
  local cursor = player and player.cursor_stack
  if cursor and cursor.valid_for_read and cursor.name == name then n = cursor.count end
  for _, id in pairs({defines.inventory.character_ammo, defines.inventory.character_main}) do
    local inventory = character.get_inventory(id)
    if inventory then n = n + inventory.get_item_count(name) end
  end
  return n
end

-- The biggest hit (director.lua storage.damage_taken entry) a character took after tick `from`, or nil.
local function biggest_hit(id, from)
  local best
  for _, hit in ipairs(storage.damage_taken and storage.damage_taken[id] or {}) do
    if hit[1] > from and (not best or hit[2] > best[2]) then best = hit end
  end
  return best
end

-- targets as in waves.update. Call every challenge check; samples every SAMPLE ticks.
function telemetry.sample(record, surface, targets)
  local t = state(record)
  if game.tick >= t.next_flush then
    t.next_flush = game.tick + FLUSH
    flush(t)
  end
  if game.tick < t.next_sample then return end
  t.next_sample = game.tick + SAMPLE
  local phase = record.phase or ("ring" .. tostring(record.ring))
  t.phase_s[phase] = (t.phase_s[phase] or 0) + SAMPLE / 60
  local second = math.floor((game.tick - t.start_tick) / 60)
  local brain = math.floor(waves.brain_health(record) * 100)
  local alive = waves.count_alive(record)
  local nests = record.origin and waves.PHASES[record.ring] and #waves.living_nests(record, surface) or 0 -- OR-D30
  local kills = {}
  local other = 0
  for name, n in pairs(t.kills) do
    local known = false
    for _, k in ipairs(KILL_TYPES) do if k == name then known = true end end
    if not known then other = other + n end
  end
  for _, name in ipairs(KILL_TYPES) do kills[#kills + 1] = tostring(t.kills[name] or 0) end
  kills[#kills + 1] = tostring(other)
  t.kills = {}
  local any_over = false
  for _, target in pairs(targets) do
    local character = target.player and target.player.character or target.entity
    if character and character.valid then
      local d = record.director and record.director[character.unit_number] or {}
      local measured = d.hp_per_s or director.hp_per_s(character)
      if measured > t.peak then t.peak = measured end
      if d.budget and measured > d.budget then any_over = true end
      local who = target.player and target.player.name or ("character-" .. character.unit_number)
      local row = {second, who, phase, brain, string.format("%.0f", character.health), character.max_health,
        string.format("%.1f", measured), string.format("%.1f", d.budget or 0), d.state or "off",
        d.touching or 0, d.ring or 0, director.held_count(record), alive, record.surge or 0, record.swarm_left or 0, nests}
      local squads = director.squad_counts(record, character.unit_number)
      local stats = record.stats or {}
      for _, v in ipairs({record.fight and record.fight.shield or "-", squads.form, squads.ready, squads.tell,
        record.closing and table_size(record.closing.members) or 0, stats.charges or 0, stats.charged or 0,
        stats.guard_rush or 0, stats.stand_still or 0, stats.rocks or 0, stats.openings or 0,
        brain_fight.bearers_alive(record), record.regroup and "pulled" or "off", stats.regroups or 0, stats.arena or 0}) do
        row[#row + 1] = v
      end
      local hit = biggest_hit(character.unit_number, game.tick - SAMPLE)
      row[#row + 1] = hit and string.format("%.0f", hit[2]) or 0
      row[#row + 1] = hit and hit[4] or "-"
      local choke, blocked = director.choke(record, character.unit_number)
      row[#row + 1] = choke and "on" or "off"
      row[#row + 1] = choke and string.format("%.0f", math.deg(choke.dir)) or "-"
      row[#row + 1] = blocked
      row[#row + 1] = brain_fight.anchors_alive(record)
      row[#row + 1] = string.format("%.2f", brain_fight.take(record))
      row[#row + 1] = brain_fight.links_alive(record)
      row[#row + 1] = brain_fight.queens_alive(record)
      row[#row + 1] = stats.queen_spawned or 0
      row[#row + 1] = d.stream and "on" or "off"
      row[#row + 1] = stats.streamed or 0
      row[#row + 1] = record.queen_level or 0
      if target.player then
        t.characters = t.characters or {}
        t.characters[target.player.index] = character.unit_number
      end
      for _, k in ipairs(kills) do row[#row + 1] = k end
      for _, ammo in ipairs(AMMO) do row[#row + 1] = count_item(character, ammo[2]) end
      for i, v in ipairs(row) do row[i] = tostring(v) end
      t.rows[#t.rows + 1] = table.concat(row, ",")
    end
  end
  t.over = any_over and t.over + 1 or 0
  if t.over > t.longest_over then t.longest_over = t.over end
end

-- on_entity_died for units: counts kills of challenge units by damage type (also the debug waves_step records).
function telemetry.on_entity_died(event)
  local number = event.entity.unit_number
  for _, records in pairs({storage.challenges or {}, storage.debug_waves or {}}) do
    for _, record in pairs(records) do
      if record.spawned and record.spawned[number] then
        local t = state(record)
        local name = event.damage_type and event.damage_type.name or "other"
        t.kills[name] = (t.kills[name] or 0) + 1
        return
      end
    end
  end
end

function telemetry.on_player_died(event)
  local id = storage.player_challenge and storage.player_challenge[event.player_index]
  local record = id and storage.challenges and storage.challenges[id]
  if record then
    local t = state(record)
    t.deaths = t.deaths + 1
    -- OR-D59: the biggest hits of the last 3 s (the dead character's unit number from the last sample)
    local hits = {}
    local id = t.characters and t.characters[event.player_index]
    for _, hit in ipairs(id and storage.damage_taken and storage.damage_taken[id] or {}) do
      if hit[1] > game.tick - 3 * 60 then hits[#hits + 1] = hit end
    end
    table.sort(hits, function(a, b) return a[2] > b[2] end)
    local top = {}
    for i = 1, math.min(5, #hits) do
      top[i] = string.format("%.0f by %s %.1f s before", hits[i][2], hits[i][4] or "?", (game.tick - hits[i][1]) / 60)
    end
    t.rows[#t.rows + 1] = string.format("# second %d: %s died; biggest hits in the last 3 s: %s",
      math.floor((game.tick - t.start_tick) / 60), game.get_player(event.player_index).name,
      #top > 0 and table.concat(top, ", ") or "none recorded")
    flush(t) -- OR-I11 (PT5): the end of a run that never reaches finish (game closed) got lost
  end
end

-- outcome: "won" / "lost" / "ended"
function telemetry.finish(record, outcome)
  local t = state(record)
  local phases = {}
  for phase, seconds in pairs(t.phase_s) do phases[#phases + 1] = phase .. " " .. seconds end
  table.sort(phases)
  t.rows[#t.rows + 1] = string.format(
    "# %s after %d s, territory %d, ring %s; seconds per phase: %s; peak %.1f HP/s; longest over budget %d s; deaths %d",
    outcome, math.floor((game.tick - t.start_tick) / 60), record.territory_id, tostring(record.ring),
    table.concat(phases, ", "), t.peak, t.longest_over, t.deaths)
  flush(t)
end

return telemetry
