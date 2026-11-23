-- Ring-2+ war (ring2-challenge-plan.md 4e1, 4e1b; R2-D27, D28, D30, D31, D33; ring-feel-plan.md RF-D17, D29, D31–D33,
-- D44, D45, D48).
-- A war is a state of one territory, kept apart from its record's state (challenge, overlay and crusade code don't
-- see it; nothing about it goes on the map). It starts with the first district fight and ends when the brain dies
-- (claimed). Leaving doesn't end it. (The hive-win end comes with the retake army, 4e2.)
--   Garrison (4e1b, 4e1c): every live district has a standing army of GARRISON units in the MIX shares (brutes =
--   big + medium biters, the swarm = small biters, all SLOW % slower) that wanders POST tiles around its heart. It is only on the
--   map while a player character is within WAKE of the heart or the heart's chunk is visible to a player force
--   (radar); after DESPAWN_AFTER without either it is kept as a number. The living nests and the heart refill it,
--   one unit per nest per REBUILD ticks, in and out of a fight; no heart, no rebuild.
--   District fight: a player character within ZONE of a built, standing district's heart (zone of control), or a
--   player-force hit on an enemy within districts.RIM of it, while the territory is hostile and no core challenge
--   runs. Half the garrison attacks the nearest participant (brutes first, the small biters BRUTE_LEAD later); the
--   rest holds the heart and joins once a participant is within HOLD of it. Units further than LEASH from their
--   heart turn back and join again once within RETURN of it. No help from the core.
--   Won: the heart dies → the district is fallen (districts.lua `fallen`): its nests stay but are made inactive
--   (disabled_by_script: no spawning), it doesn't regrow. The garrison walks to the nearest live district of the
--   territory and joins its garrison (else to the brain). A heart killed with no fight running falls the same way.
--   Left: no participant (a character of a player force) within RANGE of the heart for LOSE_GRACE → the fight ends,
--   its units walk back to the heart; the heart heals by itself and the district regrows as before. Coming back
--   starts a new fight in the same war.
--   Hive budget (4e2b; R2-D38, D39): at war a district's nests make one unit per nest per REBUILD_WAR (never idle); the core starts with START_STOCK.
--   Its garrison keeps FLOOR; the rest walks to the core garrison next to the brain (core.lua, up to core.MAX). A
--   fallen district's survivors and its queen (a dying heart releases one) walk to the core too. A live heart makes
--   an elder queen every QUEEN_EVERY while the reserve has fewer than core.RESERVE.
--   Strategic layer (4e2c, R2-D40, D41): the brain's own ring of nests (BRAIN_R around the territory point, not the
--   brain) makes normal units for the core too, one per nest per BRAIN_REBUILD, no queens. The core's free units are
--   split into funds (core.lua: reserve, raid, retake). Every DECIDE (and right after a heart falls) the brain decides:
--     defend: the live district with the most participant presence within PREDICT_RANGE (sum of PREDICT_RANGE - distance)
--       gets up to PRE reserve units into its garrison (its floor rises by as many); a fight gets the whole reserve.
--     raid (hive.lua, no queen): you in a fallen district (LEFT_RANGE of its heart) once the raid fund has RAID_MIN,
--       else the chunk of your buildings with the most value + threat around it (influence.lua, SCORE_RADIUS) once the
--       raid fund holds threat × RAID_PER_THREAT (at least RAID_MIN, at most the fund's cap). Takes the whole fund.
--     retake: a left fallen district (no participant within LEFT_RANGE for LEFT_AFTER), once the retake fund has
--       RETAKE_MIN and a reserve queen is free (RETRY after a retreat); the district with the lowest (threat + 1) /
--       (value + 1) around its heart. Takes the whole fund. Retaken: heart rebuilt, nests awake, the survivors are its
--       garrison.
--   One raid and one retake can be out at once. Hive win (RF-D21): every built district live and no player building within
--   hive.HOLD_RADIUS of any heart → the war ends, the brain heals to full, the core joins the districts.
-- Telemetry: a CSV per fight (ht-telemetry/<tick>-t<id>-d<slot>.csv, a row per participant every SAMPLE ticks, a
-- summary line at the end) and a war log (ht-telemetry/<tick>-t<id>-war.csv, a row per event).
-- storage.wars[territory id] = {started_tick, log, fights = {[slot] = fight}}
--   fight = {slot, trigger, started_tick, players = {[player index] = true}, spawned = {[unit_number] = entity}
--     (committed units), held, lead = {tick, units}, sent, rebuilt, lose_since, deaths, file, rows, next_flush}
-- district.garrison (on the district in storage.districts) = {count (units while off the map), hidden_tick,
--   units = {[unit_number] = entity} (while on the map), idle_since, progress (rebuild)}

local territories = require("scripts.territories")
local districts = require("scripts.districts")
local influence = require("scripts.influence")
local hive = require("scripts.hive")
local core = require("scripts.core")

local war = {}

war.CHECK_INTERVAL = 30
local RANGE = 100
local LOSE_GRACE = 5 * 60
local GARRISON = 80
-- Shares of the garrison (R2-D34, 4e1c). Big and medium biters are the brutes: they attack first.
local MIX = {{name = "big-biter", share = 0.2}, {name = "medium-biter", share = 0.3}, {name = "small-biter", share = 0.5}}
local BRUTES = {["big-biter"] = true, ["medium-biter"] = true}
local POST_MIN, POST_MAX = 20, 30
local WAKE = 200
local DESPAWN_AFTER = 60 * 60
local ZONE = 80
local HOLD = 40
local LEASH = 120
local RETURN = 60
local REBUILD = 10 * 60
local BRUTE_LEAD = 90
local SLOW = 20
local SAMPLE = 60
local FLUSH = 30 * 60
local HEART = "ht-district-heart"
local LEFT_RANGE = 60
local LEFT_AFTER = 30 * 60
local RETAKE_MASS = 20 * 60
local RETRY = 2 * 60 * 60
local MASS_DIST = 30
local FLOOR = 40
local REBUILD_WAR = 8 * 60 -- (R2-D42; was 20 s)
local BRAIN_REBUILD = 20 * 60
local START_STOCK = 150
local TRANSFER = 5
local DECIDE = 20 * 60
local PRE = 30
local PREDICT_RANGE = 150
local RAID_MIN = 20
local RAID_PER_THREAT = 4
local RETAKE_MIN = 40
local BRAIN_R = 30
local QUEEN_EVERY = 3 * 60 * 60
local CORE_SAMPLE = 5 * 60
local SCORE_RADIUS = 48
local ELDER = "ht-elder-queen"

local function init_storage()
  storage.wars = storage.wars or {}
end

-- A player's force (or "player" itself, which has no players in headless tests).
local function player_force(force) return force.name == "player" or #force.players > 0 end

local function heart_position(d) return {x = d.x + 0.5, y = d.y + 0.5} end

local function dist2(a, b) return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 end

local function log_event(w, event, slot, detail)
  helpers.write_file(w.log, string.format("%d,%d,%s,%s,%s\n", game.tick, math.floor((game.tick - w.started_tick) / 60),
    event, slot and tostring(slot) or "", detail or ""), true)
end

local function start_war(id)
  local w = {started_tick = game.tick, fights = {}, log = string.format("ht-telemetry/%d-t%d-war.csv", game.tick, id),
    core_file = string.format("ht-telemetry/%d-t%d-core.csv", game.tick, id)}
  helpers.write_file(w.log, "tick,second,event,slot,detail\n", false)
  helpers.write_file(w.core_file, "second,free,incoming,escorts,queens_home,queens_walking,queens_flee,queens_army,arrived,brain_made,reserve,raid_fund,retake_fund,raid,raid_units,retake,retake_units,live_districts,predicted\n", false)
  storage.wars[id] = w
  core.add_count(id, START_STOCK) -- the brain has an army ready when the war starts (R2-D42)
  log_event(w, "war_start", nil, string.format("core starts with %d", START_STOCK))
  return w
end

-- The district of territory id whose heart is within districts.RIM of position, or nil.
local function district_at(id, position)
  local state = storage.districts and storage.districts[id]
  if not state then return nil end
  for _, d in pairs(state.list) do
    if d.built and (position.x - d.x - 0.5) ^ 2 + (position.y - d.y - 0.5) ^ 2 <= districts.RIM ^ 2 then return d end
  end
end

-- The district's nests standing now (heart first if it stands).
local function living_nests(surface, d)
  local list = {}
  for _, piece in pairs(districts.pieces(d)) do
    local e = surface.find_entities_filtered{position = {piece.x + 0.5, piece.y + 0.5}, radius = 1.5, name = piece.name,
      force = "enemy", limit = 1}[1]
    if e then list[#list + 1] = e end
  end
  return list
end

-- Participants: characters of player forces (a player's, or a player-less one in headless tests), and vehicles with
-- a driver (find_entities_filtered doesn't find a character inside a vehicle; the units attack the vehicle).
local function characters(surface)
  local list = {}
  for _, c in pairs(surface.find_entities_filtered{type = "character"}) do
    if player_force(c.force) then list[#list + 1] = c end
  end
  for _, v in pairs(surface.find_entities_filtered{type = {"car", "spider-vehicle"}}) do
    if player_force(v.force) and v.get_driver() then list[#list + 1] = v end
  end
  return list
end

-- The player behind a participant (character or vehicle), or nil.
local function player_of(e)
  if e.type == "character" then return e.player end
  local driver = e.get_driver()
  if not driver then return nil end
  if driver.object_name == "LuaPlayer" then return driver end
  return driver.player
end

local function within(list, centre, r)
  local out = {}
  for _, c in pairs(list) do
    if dist2(c.position, centre) <= r * r then out[#out + 1] = c end
  end
  return out
end

local function nearest(list, position)
  local best, bd
  for _, c in pairs(list) do
    local q = dist2(c.position, position)
    if not bd or q < bd then best, bd = c, q end
  end
  return best
end

-- The brain's head (a LuaSegmentedUnit has no position, its head does), or nil.
local function brain_head(id)
  local record = storage.territories[id]
  local brain = record and record.territory.valid and record.territory.get_segmented_units()[1]
  local head = brain and brain.valid and brain.segments[1]
  return head, brain
end

local function brain_centre(id)
  local head = brain_head(id)
  return head and head.position
end

-- Garrison ------------------------------------------------------------------------------------------------------

local function garrison(d)
  d.garrison = d.garrison or {count = GARRISON, hidden_tick = game.tick, progress = 0}
  return d.garrison
end

-- Units alive, and alive per unit name (dead ones dropped).
local function garrison_alive(g)
  local n, per = 0, {}
  for k, unit in pairs(g.units or {}) do
    if unit.valid then
      n = n + 1
      per[unit.name] = (per[unit.name] or 0) + 1
    else
      g.units[k] = nil
    end
  end
  return n, per
end

-- Units the war commands stay ours: base biters walk back into a nest and enter it once they have nothing to do
-- (allow_try_return_to_spawner; the 4e2 massing drift, PT4), are removed after failed commands, and join the engine's
-- attack groups. Off for every unit the war makes (garrisons, armies, elder queens).
function war.tame(unit)
  local ai = unit.ai_settings
  ai.allow_try_return_to_spawner = false
  ai.allow_destroy_when_commands_fail = false
  ai.join_attacks = false
end

local function post(unit)
  unit.commandable.set_command{type = defines.command.wander, radius = 8, distraction = defines.distraction.by_enemy}
end

-- One unit near position (a post on the ring or a nest): the kind furthest below its MIX share.
local function spawn_unit(surface, g, position)
  local n, per = garrison_alive(g)
  local name, gap = MIX[#MIX].name, nil
  for _, m in ipairs(MIX) do
    local short = m.share * (n + 1) - (per[m.name] or 0)
    if not gap or short > gap then name, gap = m.name, short end
  end
  local spot = surface.find_non_colliding_position(name, position, 8, 0.5)
  if not spot then return nil end
  local unit = surface.create_entity{name = name, position = spot, force = "enemy"}
  if not unit then return nil end
  surface.create_entity{name = "ht-challenge-slow-" .. SLOW, position = spot, target = unit}
  war.tame(unit)
  g.units[unit.unit_number] = unit
  return unit
end

core.connect{
  spawn = function(surface, g, position) return spawn_unit(surface, g, position) end,
  log = function(id, event, detail)
    local w = storage.wars[id]
    if w then log_event(w, event, nil, detail) end
  end,
}

local function post_position(d)
  local a, r = math.random() * 2 * math.pi, POST_MIN + math.random() * (POST_MAX - POST_MIN)
  return {x = d.x + 0.5 + r * math.cos(a), y = d.y + 0.5 + r * math.sin(a)}
end

-- Put the garrison on the map: its count, plus what the nests rebuilt while it was off the map.
local function show(surface, d, g)
  local nests = 0
  for _, n in pairs(living_nests(surface, d)) do if not n.disabled_by_script then nests = nests + 1 end end
  -- (more than GARRISON after units of a fallen district joined: those are kept, the rebuild stops at GARRISON)
  local count = math.max(g.count, math.min(GARRISON, g.count + math.floor((game.tick - (g.hidden_tick or game.tick)) / REBUILD * nests)))
  g.units, g.count, g.hidden_tick, g.idle_since = {}, nil, nil, nil
  for _ = 1, count do
    local unit = spawn_unit(surface, g, post_position(d))
    if unit then post(unit) end
  end
end

local function hide(g)
  local n = garrison_alive(g)
  for _, unit in pairs(g.units) do unit.destroy() end
  g.units, g.count, g.hidden_tick, g.idle_since = nil, n, game.tick, nil
end

-- Fights ---------------------------------------------------------------------------------------------------------

local function fight_header()
  return "second,participant,hp,max_hp,shield,heart_pct,alive,garrison,nests,quiet,sent,rebuilt"
end

local function flush(f)
  if #f.rows > 0 then helpers.write_file(f.file, table.concat(f.rows, "\n") .. "\n", true) end
  f.rows = {}
end

local function attack(unit, players)
  local target = nearest(players, unit.position)
  if target then
    unit.commandable.set_command{type = defines.command.attack, target = target, distraction = defines.distraction.by_enemy}
  end
end

-- Units join the fight: brutes attack now, the rest BRUTE_LEAD later (on_tick).
local function commit(f, units, players)
  local later = {}
  for _, unit in pairs(units) do
    f.spawned[unit.unit_number] = unit
    f.sent = f.sent + 1
    if BRUTES[unit.name] then attack(unit, players) else later[#later + 1] = unit end
  end
  if #later > 0 then
    f.lead = f.lead or {}
    f.lead[#f.lead + 1] = {tick = game.tick + BRUTE_LEAD, units = later}
  end
end

-- Share of each kind (rounded up) on fight start; everything left once the hold is released.
local function commit_share(f, g, players, share)
  local kinds = {}
  for _, unit in pairs(g.units or {}) do
    if unit.valid and not f.spawned[unit.unit_number] then
      kinds[unit.name] = kinds[unit.name] or {}
      table.insert(kinds[unit.name], unit)
    end
  end
  local units = {}
  for _, list in pairs(kinds) do
    for k = 1, math.ceil(#list * share) do units[#units + 1] = list[k] end
  end
  commit(f, units, players)
end

local function start_fight(surface, w, id, d, trigger, players)
  local f = {slot = d.slot, trigger = trigger, started_tick = game.tick, players = {}, spawned = {}, sent = 0,
    rebuilt = 0, deaths = 0, held = true, rows = {}, next_flush = game.tick + FLUSH,
    file = string.format("ht-telemetry/%d-t%d-d%d.csv", game.tick, id, d.slot)}
  helpers.write_file(f.file, fight_header() .. "\n", false)
  w.fights[d.slot] = f
  d.fighting = true
  log_event(w, "fight_start", d.slot, string.format("%d %d %s", d.x, d.y, trigger))
  local g = garrison(d)
  if not g.units then show(surface, d, g) end
  commit_share(f, g, players, 0.5)
  d.pre = nil -- the pre-positioned units are in the fight now
  -- help from the core, once: the whole reserve (R2-D41)
  local centre = brain_centre(id)
  local reserve = centre and core.fund(id, "reserve") or 0
  if reserve > 0 then
    local help = core.take(surface, id, reserve, centre, "reserve")
    for _, unit in pairs(help) do g.units[unit.unit_number] = unit end
    if #help > 0 then
      commit(f, help, players)
      log_event(w, "help_sent", d.slot, string.format("%d units from the core", #help))
    end
  end
  return f
end

local function end_fight(w, d, f, outcome)
  local seconds = math.floor((game.tick - f.started_tick) / 60)
  f.rows[#f.rows + 1] = string.format("# outcome=%s duration_s=%d trigger=%s sent=%d rebuilt=%d deaths=%d", outcome,
    seconds, f.trigger or "hit", f.sent, f.rebuilt or 0, f.deaths)
  flush(f)
  w.fights[d.slot] = nil
  d.fighting = nil
  log_event(w, "fight_" .. outcome, d.slot, string.format("%ds sent %d", seconds, f.sent))
end

-- Units of an ended fight walk back to the heart and are the garrison again.
local function send_home(f, d)
  for _, unit in pairs(f.spawned) do
    if unit.valid then
      unit.commandable.set_command{type = defines.command.go_to_location, destination = heart_position(d), radius = 12,
        distraction = defines.distraction.by_enemy}
    end
  end
  f.spawned = {}
  f.lead = nil
end

local function find_district(id, slot)
  for _, d in pairs(storage.districts[id].list) do
    if d.slot == slot then return d end
  end
end

local function live(d) return d.built and not d.fallen end

-- A district's garrison at war keeps FLOOR, plus the units the brain moved in ahead of you (R2-D41).
local function floor_of(d) return FLOOR + (d.pre or 0) end


-- n units of district d go to the core: counted if the core is off the map, else they walk there from the district.
local function to_core(surface, id, d, n)
  if n <= 0 or core.add_count(id, n) then return end
  local centre = brain_centre(id)
  if not centre then return end
  local g = {units = {}}
  for _ = 1, n do
    local unit = spawn_unit(surface, g, post_position(d))
    if unit then core.receive(id, unit, centre) end
  end
end

-- A new elder queen next to position (tamed), or nil.
local function new_queen(surface, position)
  local spot = surface.find_non_colliding_position(ELDER, {position.x + 4, position.y + 4}, 20, 1)
  local queen = spot and surface.create_entity{name = ELDER, position = spot, force = "enemy"}
  if queen then war.tame(queen) end
  return queen
end

-- The fallen district's garrison walks to the core (R2-D39).
local function relocate(surface, id, d)
  local g = d.garrison
  d.garrison = nil
  if not g then return 0, "core" end
  if not g.units then
    to_core(surface, id, d, g.count or 0)
    return g.count or 0, "core"
  end
  local centre = brain_centre(id)
  local n = 0
  for _, unit in pairs(g.units) do
    if unit.valid and centre then
      n = n + 1
      core.receive(id, unit, centre)
    end
  end
  return n, "core"
end

-- The heart died: the district falls, its nests go quiet, the garrison leaves.
local function fall(surface, id, d)
  d.fallen = true
  local quiet = 0
  for _, nest in pairs(living_nests(surface, d)) do
    if nest.name ~= HEART then -- the dying heart itself
      nest.disabled_by_script = true
      quiet = quiet + 1
    end
  end
  local w = storage.wars[id] or start_war(id)
  local f = w.fights[d.slot]
  if f then
    f.spawned, f.lead = {}, nil
    end_fight(w, d, f, "won")
  end
  local moved, to = relocate(surface, id, d)
  log_event(w, "fallen", d.slot, string.format("%d quiet nests, %d units to %s", quiet, moved, to))
  -- the heart contains a queen: she flees to the brain (R2-D39)
  local centre = brain_centre(id)
  local queen = centre and new_queen(surface, heart_position(d))
  if queen then core.add_queen(id, queen, centre, "released") end
  w.decide_now = true -- the brain answers right away (a raid at you)
end

-- A fight may start at district d of territory record: hostile, no core challenge, not already fighting.
local function can_start(record, d)
  return live(d) and not d.fighting and record.state == "hostile"
    and not (storage.challenges and storage.challenges[record.id])
end

-- on_entity_damaged for enemy spawners and turrets, with the player behind the cause (or nil).
function war.on_base_damaged(event, player)
  init_storage()
  local entity = event.entity
  if entity.force.name ~= "enemy" or entity.surface.name ~= territories.surface_name then return end
  local cause = event.cause
  if not (player or (cause and cause.valid and player_force(cause.force))) then return end
  local record = territories.get_at(entity.surface, entity.position)
  if not record then return end
  local d = district_at(record.id, entity.position)
  if not d or d.fallen then return end
  local w = storage.wars[record.id]
  local f = w and w.fights[d.slot]
  if not f then
    if not can_start(record, d) then return end
    local players = within(characters(entity.surface), heart_position(d), RANGE)
    if #players == 0 and cause and cause.valid then players = {cause} end
    w = w or start_war(record.id)
    f = start_fight(entity.surface, w, record.id, d, "hit", players)
  end
  if player then f.players[player.index] = true end
end

-- on_entity_died for spawners: a district heart falls.
function war.on_nest_died(event)
  init_storage()
  local entity = event.entity
  if entity.name ~= HEART or entity.surface.name ~= territories.surface_name then return end
  local record = territories.get_at(entity.surface, entity.position)
  if not record then return end
  local d = district_at(record.id, entity.position)
  if d and not d.fallen then fall(entity.surface, record.id, d) end
end

function war.on_player_died(event)
  init_storage()
  for _, w in pairs(storage.wars) do
    for _, f in pairs(w.fights) do
      if f.players[event.player_index] then f.deaths = f.deaths + 1 end
    end
  end
end

-- The territory was claimed (its brain died): the war ends.
function war.on_won(id)
  init_storage()
  local w = storage.wars[id]
  if not w then return end
  local state = storage.districts and storage.districts[id]
  for slot, f in pairs(w.fights) do
    local d = state and find_district(id, slot)
    if d then
      send_home(f, d)
      end_fight(w, d, f, "claimed")
    end
  end
  hive.cancel(id)
  core.dissolve(id, function() end)
  log_event(w, "war_end", nil, "brain dead")
  storage.wars[id] = nil
end

-- Shield points left in a character's armor (0 for vehicles and bare characters).
local function shield_of(c)
  if c.type ~= "character" then return 0 end
  local inventory = c.get_inventory(defines.inventory.character_armor)
  local armor = inventory and inventory[1]
  return armor and armor.valid_for_read and armor.grid and armor.grid.shield or 0
end

local function sample(surface, d, f, players)
  if game.tick >= f.next_flush then
    f.next_flush = game.tick + FLUSH
    flush(f)
  end
  if (game.tick - f.started_tick) % SAMPLE >= war.CHECK_INTERVAL then return end
  local heart = surface.find_entities_filtered{position = heart_position(d), radius = 1.5, name = HEART, limit = 1}[1]
  local nests = living_nests(surface, d)
  local quiet = 0
  for _, n in pairs(nests) do if n.disabled_by_script then quiet = quiet + 1 end end
  local alive = 0
  for k, unit in pairs(f.spawned) do
    if unit.valid then alive = alive + 1 else f.spawned[k] = nil end
  end
  local g_alive = garrison_alive(garrison(d))
  local second = math.floor((game.tick - f.started_tick) / 60)
  for _, c in pairs(players) do
    local player = player_of(c)
    local who = player and (player.name ~= "" and player.name or "player-" .. player.index) or (c.type .. "-" .. c.unit_number)
    f.rows[#f.rows + 1] = string.format("%d,%s,%.0f,%.0f,%.0f,%d,%d,%d,%d,%d,%d,%d", second, who, c.health, c.max_health, shield_of(c),
      heart and math.floor(heart.get_health_ratio() * 100) or 0, alive, g_alive, #nests, quiet, f.sent, f.rebuilt)
  end
end

-- Nests and heart add units (none without the heart). New units join a running fight. At war (id given, 4e2b) the
-- nests make one unit per nest per REBUILD_WAR (R2-D42) and never idle: over FLOOR (out of a fight) the units walk to the core.
local function rebuild(surface, d, g, f, players, id)
  local nests, heart = {}, false
  for _, n in pairs(living_nests(surface, d)) do
    if not n.disabled_by_script then
      nests[#nests + 1] = n
      if n.name == HEART then heart = true end
    end
  end
  if not heart then g.progress = 0 return end
  g.progress = g.progress + #nests * war.CHECK_INTERVAL / (id and REBUILD_WAR or REBUILD)
  local n = garrison_alive(g)
  local new = {}
  local centre = id and brain_centre(id)
  while g.progress >= 1 do
    local surplus = id and not f and n >= floor_of(d)
    if surplus then
      if not centre or core.full(id) then break end
    elseif n >= GARRISON then break end
    g.progress = g.progress - 1
    local unit = spawn_unit(surface, g, nests[math.random(#nests)].position)
    if unit then
      if surplus then
        g.units[unit.unit_number] = nil
        core.receive(id, unit, centre)
      else
        n = n + 1
        if f then new[#new + 1] = unit else post(unit) end
      end
    end
  end
  if g.progress >= 1 then g.progress = 0 end -- capped: nothing saved up
  if f and #new > 0 then
    f.rebuilt = f.rebuilt + #new
    commit(f, new, players)
  end
end

-- A running fight: hold release, brute lead, leash, retarget, rebuild.
local function run_fight(surface, d, f, players, id)
  local centre = heart_position(d)
  local g = garrison(d)
  if not g.units then show(surface, d, g) end
  if f.held and #within(players, centre, HOLD) > 0 then
    f.held = false
    commit_share(f, g, players, 1)
  end
  for k = #(f.lead or {}), 1, -1 do
    local batch = f.lead[k]
    if game.tick >= batch.tick then
      for _, unit in pairs(batch.units) do
        if unit.valid and f.spawned[unit.unit_number] then attack(unit, players) end
      end
      table.remove(f.lead, k)
    end
  end
  local waiting = {}
  for _, batch in pairs(f.lead or {}) do for _, unit in pairs(batch.units) do waiting[unit] = true end end
  for k, unit in pairs(f.spawned) do
    if not unit.valid then
      f.spawned[k] = nil
    elseif dist2(unit.position, centre) > LEASH * LEASH then
      f.spawned[k] = nil
      unit.commandable.set_command{type = defines.command.go_to_location, destination = centre, radius = 12,
        distraction = defines.distraction.none}
    elseif not waiting[unit] and not unit.commandable.has_command then
      attack(unit, players)
    end
  end
  if not f.held then -- leashed units back home join again
    local back = {}
    for k, unit in pairs(g.units) do
      if unit.valid and not f.spawned[k] and dist2(unit.position, centre) <= RETURN * RETURN then back[#back + 1] = unit end
    end
    if #back > 0 then
      for _, unit in pairs(back) do f.spawned[unit.unit_number] = unit attack(unit, players) end
    end
  end
  rebuild(surface, d, g, f, players, id)
end

-- Garrison on / off the map, refill, zone of control for one district at peace.
local function run_peace(surface, w, record, d, chars, forces)
  local centre = heart_position(d)
  local g = garrison(d)
  local seen = #within(chars, centre, WAKE) > 0
  if not seen then
    local chunk = {x = math.floor(centre.x / 32), y = math.floor(centre.y / 32)}
    for _, force in pairs(forces) do
      if force.is_chunk_visible(surface, chunk) then seen = true break end
    end
  end
  local id = w and record.id
  if g.units then
    if seen then
      g.idle_since = nil
    else
      g.idle_since = g.idle_since or game.tick
      if game.tick - g.idle_since >= DESPAWN_AFTER then hide(g) return end
    end
    rebuild(surface, d, g, nil, nil, id)
    -- at war, what's over FLOOR walks to the core (a few per check)
    local centre = id and brain_centre(id)
    if centre then
      local n = garrison_alive(g)
      local moved = 0
      for k, unit in pairs(g.units) do
        if n - moved <= floor_of(d) or moved >= TRANSFER or core.full(id) then break end
        g.units[k] = nil
        if unit.valid then
          core.receive(id, unit, centre)
          moved = moved + 1
        end
      end
    end
  elseif seen then
    show(surface, d, g)
  elseif id then
    -- off the map at war: the nests' output is counted, what's over FLOOR goes to the core
    local nests, heart = 0, false
    for _, n in pairs(living_nests(surface, d)) do
      if not n.disabled_by_script then
        nests = nests + 1
        if n.name == HEART then heart = true end
      end
    end
    if heart then g.progress = (g.progress or 0) + nests * war.CHECK_INTERVAL / REBUILD_WAR end
    local made = math.floor(g.progress or 0)
    g.progress = (g.progress or 0) - made
    g.count = g.count + made
    local over = math.min(g.count - floor_of(d), TRANSFER)
    if over > 0 and not core.full(id) then
      g.count = g.count - over
      to_core(surface, id, d, over)
    end
    g.hidden_tick = game.tick -- show() adds nothing for the time off the map: it's counted here
  end
  local intruders = within(chars, centre, ZONE)
  if #intruders > 0 and can_start(record, d) then
    w = w or start_war(record.id)
    log_event(w, "zone_enter", d.slot, string.format("%d tiles", math.sqrt(dist2(nearest(intruders, centre).position, centre))))
    local f = start_fight(surface, w, record.id, d, "zone", within(chars, centre, RANGE))
    for _, c in pairs(intruders) do
      local player = player_of(c)
      if player then f.players[player.index] = true end
    end
  end
end

-- Hive: core, raids, retakes, queens (4e2b, 4e2c) ----------------------------------------------------------------

local function all_built(id)
  local list = {}
  for _, d in pairs(storage.districts[id].list) do if d.built then list[#list + 1] = d end end
  return list
end

-- Fallen districts: are they left (no participant within LEFT_RANGE for LEFT_AFTER)?
local function track_left(id, chars)
  for _, d in pairs(all_built(id)) do
    if d.fallen then
      if #within(chars, heart_position(d), LEFT_RANGE) > 0 then d.left_since = nil
      else d.left_since = d.left_since or game.tick end
    else
      d.left_since = nil
    end
  end
end

-- The district with the lowest (threat + 1) / (value + 1) around its heart, and the scores for the log.
local function pick(list)
  local best, best_score, scores = nil, nil, {}
  for _, d in pairs(list) do
    local threat, value = influence.around(heart_position(d), SCORE_RADIUS)
    local score = (threat + 1) / (value + 1)
    scores[#scores + 1] = string.format("d%d threat %.1f value %d score %.2f", d.slot, threat, value, score)
    if not best_score or score < best_score then best, best_score = d, score end
  end
  return best, table.concat(scores, "; ")
end

-- An army out of a fund: kind "raid" / "retake", to target (slot = its district or nil).
local function send(surface, w, id, kind, slot, target, queen, mass, fund)
  local centre = brain_centre(id)
  local units = {}
  for _, unit in pairs(core.take(surface, id, core.fund(id, fund), centre, fund)) do
    units[#units + 1] = {entity = unit, from = "core"}
  end
  local l = math.max(math.sqrt(dist2(target, centre)), 1)
  local spot = {x = centre.x + (target.x - centre.x) / l * MASS_DIST, y = centre.y + (target.y - centre.y) / l * MASS_DIST}
  hive.start(id, kind, slot, target, spot, units, queen, mass)
  return #units
end

-- The live district you'll likely hit next: the most participant presence within PREDICT_RANGE, or nil.
local function predict(id, chars)
  local best, bs
  for _, d in pairs(all_built(id)) do
    if live(d) and not d.fighting then
      local score = 0
      for _, c in pairs(chars) do
        local q = math.sqrt(dist2(c.position, heart_position(d)))
        if q < PREDICT_RANGE then score = score + PREDICT_RANGE - q end
      end
      if score > 0 and (not bs or score > bs) then best, bs = d, score end
    end
  end
  return best, bs
end

-- Defend: up to PRE reserve units into the predicted district; the others give theirs back (floor down again).
local function preposition(surface, w, id, d, centre)
  for _, other in pairs(all_built(id)) do
    if other ~= d and other.pre and not other.fighting then other.pre = nil end
  end
  if not d then return 0 end
  local g = garrison(d)
  local have = g.units and garrison_alive(g) or g.count
  local n = math.min(PRE - (d.pre or 0), GARRISON - have, core.fund(id, "reserve"))
  if n <= 0 then return 0 end
  local units = core.take(surface, id, n, centre, "reserve")
  for _, unit in pairs(units) do
    if g.units then
      g.units[unit.unit_number] = unit
      unit.commandable.set_command{type = defines.command.go_to_location, destination = post_position(d), radius = 8,
        distraction = defines.distraction.by_enemy}
    else
      g.count = g.count + 1
      unit.destroy()
    end
  end
  d.pre = (d.pre or 0) + #units
  if #units > 0 then log_event(w, "preposition", d.slot, string.format("%d units, %d ahead now", #units, d.pre)) end
  return #units
end

-- Your best raid target outside a fallen district: the chunk of your buildings with the most value + threat around
-- it. Returns position, threat, value, or nil.
local function raid_cluster(id)
  local best, bs, bt, bv
  for _, c in pairs(influence.cells(id)) do
    if c.value > 0 then
      local position = {x = c.x * 32 + 16, y = c.y * 32 + 16}
      local threat, value = influence.around(position, SCORE_RADIUS)
      local score = threat + value
      if not bs or score > bs then best, bs, bt, bv = position, score, threat, value end
    end
  end
  return best, bt, bv
end

-- The brain's decision (every DECIDE, right after a heart falls, or forced by a debug command).
local function decide(surface, w, id, chars, centre)
  if storage.hive_hold then return end
  local forced_retake, forced_raid = w.force_retake, w.force_raid
  if not (w.decide_now or forced_retake or forced_raid or game.tick >= (w.next_decide or 0)) then return end
  w.decide_now, w.next_decide = nil, game.tick + DECIDE
  core.sync(id)
  local parts = {}
  -- defend
  local next_d = predict(id, chars)
  w.predicted = next_d and next_d.slot or nil
  local moved = preposition(surface, w, id, next_d, centre)
  if next_d then parts[#parts + 1] = string.format("next d%d (+%d)", next_d.slot, moved) end
  -- raid
  if not hive.army(id, "raid") then
    local fund = core.fund(id, "raid")
    local occupied = {}
    for _, d in pairs(all_built(id)) do
      if d.fallen and #within(chars, heart_position(d), LEFT_RANGE) > 0 then occupied[#occupied + 1] = d end
    end
    if #occupied > 0 and (fund >= RAID_MIN or (forced_raid and fund > 0)) then
      local d = pick(occupied)
      local n = send(surface, w, id, "raid", d.slot, heart_position(d), nil, 0, "raid")
      parts[#parts + 1] = string.format("raid at you in d%d, %d units", d.slot, n)
      w.force_raid = nil
    else
      local target, threat, value = raid_cluster(id)
      if target then
        local cap = core.FUNDS[2].cap
        local need = math.min(cap, math.max(RAID_MIN, math.ceil(threat * RAID_PER_THREAT)))
        if fund >= need or (forced_raid and fund > 0) then
          local n = send(surface, w, id, "raid", nil, target, nil, 0, "raid")
          parts[#parts + 1] = string.format("raid at %d %d (threat %.1f value %d), %d units", target.x, target.y, threat, value, n)
          w.force_raid = nil
        else
          parts[#parts + 1] = string.format("raid waits: %d of %d for %d %d", fund, need, target.x, target.y)
        end
      end
    end
  end
  -- retake
  if not hive.army(id, "retake") then
    local left = {}
    for _, d in pairs(all_built(id)) do
      if d.fallen and d.left_since and (forced_retake or game.tick - d.left_since >= LEFT_AFTER) then left[#left + 1] = d end
    end
    local fund = core.fund(id, "retake")
    if #left > 0 and (forced_retake or (game.tick >= (w.retry_after or 0) and fund >= RETAKE_MIN)) then
      if forced_retake and core.queens(id) == 0 then
        local queen = new_queen(surface, centre) -- debug: a queen for the forced retake
        if queen then core.add_queen(id, queen, centre, "debug") end
        local q = core.get(id).queens[queen and queen.unit_number or -1]
        if q then q.state = "home" end
      end
      local queen = core.take_queen(id, centre, chars)
      if queen then
        local d, scores = pick(left)
        w.force_retake = nil
        log_event(w, "retake_plan", d.slot, scores)
        local n = send(surface, w, id, "retake", d.slot, heart_position(d), queen, forced_retake and 5 * 60 or RETAKE_MASS, "retake")
        parts[#parts + 1] = string.format("retake d%d, %d units", d.slot, n)
      else
        parts[#parts + 1] = "retake waits for a queen"
      end
    end
  end
  local c = core.get(id)
  w.last_decision = string.format("reserve %d raid %d retake %d: %s", c.funds.reserve, c.funds.raid, c.funds.retake,
    #parts > 0 and table.concat(parts, "; ") or "nothing")
  log_event(w, "decide", w.predicted, w.last_decision)
end

-- The brain's own ring of nests (not part of a district) makes units for the core. Looked for around the brain's base
-- (regrow.lua's storage.bases, where brain.lua put it: a base moved onto land sits away from its point; PT6 found
-- none around the point) and around the point. Looked for again every minute (nests regrow, chunks generate).
local function brain_nests(surface, w, id)
  if w.brain_nests and game.tick < (w.brain_nests_tick or 0) then return w.brain_nests end
  local state = storage.districts[id]
  local centres = {{x = state.point.x + 0.5, y = state.point.y + 0.5}}
  local base = storage.bases and storage.bases[id]
  if base then centres[#centres + 1] = {x = base.x + 0.5, y = base.y + 0.5} end
  local list, seen = {}, {}
  for _, c in pairs(centres) do
    for _, e in pairs(surface.find_entities_filtered{position = c, radius = BRAIN_R, type = "unit-spawner", force = "enemy"}) do
      if not seen[e.unit_number] and not district_at(id, e.position) then
        seen[e.unit_number] = true
        list[#list + 1] = e
      end
    end
  end
  w.brain_nests, w.brain_nests_tick = list, game.tick + 60 * 60
  return list
end

local function brain_income(surface, w, id, centre)
  local nests = 0
  for k, e in pairs(brain_nests(surface, w, id)) do
    if e.valid then
      if not e.disabled_by_script then nests = nests + 1 end
    else
      w.brain_nests[k] = nil
    end
  end
  w.brain_progress = math.min((w.brain_progress or 0) + nests * war.CHECK_INTERVAL / BRAIN_REBUILD, nests + 1)
  while w.brain_progress >= 1 and not core.full(id) do
    w.brain_progress = w.brain_progress - 1
    w.brain_made = (w.brain_made or 0) + 1
    if not core.add_count(id, 1) then
      local list = {}
      for _, e in pairs(w.brain_nests) do if e.valid then list[#list + 1] = e end end
      local unit = #list > 0 and spawn_unit(surface, {units = {}}, list[math.random(#list)].position)
      if unit then core.receive(id, unit, centre) end
    end
  end
end

-- Live hearts make queens for the reserve (R2-D39).
local function make_queens(surface, id, centre)
  for _, d in pairs(all_built(id)) do
    if live(d) and not d.fighting then
      d.queen_progress = math.min(QUEEN_EVERY, (d.queen_progress or 0) + war.CHECK_INTERVAL)
      if d.queen_progress >= QUEEN_EVERY and core.queens(id) < core.RESERVE then
        local queen = new_queen(surface, heart_position(d))
        if queen then
          d.queen_progress = 0
          core.add_queen(id, queen, centre, "made")
        end
      end
    end
  end
end

local function core_sample(w, id)
  if (game.tick - w.started_tick) % CORE_SAMPLE >= war.CHECK_INTERVAL then return end
  w.core_file = w.core_file or string.format("ht-telemetry/%d-t%d-core.csv", w.started_tick, id) -- (older saves)
  local free, incoming, q, funds = core.stats(id)
  local function army_of(kind)
    local army = hive.army(id, kind)
    local n = 0
    if army then for _, u in pairs(army.units) do if u.entity.valid then n = n + 1 end end end
    return army and army.state or "-", n
  end
  local raid, raid_units = army_of("raid")
  local retake, retake_units = army_of("retake")
  local live_n = 0
  for _, d in pairs(all_built(id)) do if live(d) then live_n = live_n + 1 end end
  helpers.write_file(w.core_file, string.format("%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%d,%s,%d,%d,%s\n",
    math.floor((game.tick - w.started_tick) / 60), free, incoming, q.escorts, q.home, q.walking, q.flee, q.army,
    core.get(id).made, w.brain_made or 0, funds.reserve, funds.raid, funds.retake, raid, raid_units, retake, retake_units,
    live_n, w.predicted and ("d" .. w.predicted) or "-"), true)
end

-- No player building in any district and every built district live: the hive won the war (RF-D21).
local function check_hive_win(surface, id)
  local w = storage.wars[id]
  if not w then return end
  for _, d in pairs(all_built(id)) do
    if d.fallen then return end
    if #hive.buildings(surface, heart_position(d)) > 0 then return end
  end
  for slot, f in pairs(w.fights) do
    local d = find_district(id, slot)
    if d then
      send_home(f, d)
      end_fight(w, d, f, "hive_win")
    end
  end
  local _, brain = brain_head(id)
  if brain then brain.health = brain.max_health end
  -- the core goes back to the districts
  local list = all_built(id)
  local k = 0
  core.dissolve(id, function(unit)
    k = k + 1
    local d = list[(k % #list) + 1]
    local g = garrison(d)
    if g.units then
      g.units[unit.unit_number] = unit
      unit.commandable.set_command{type = defines.command.go_to_location, destination = heart_position(d), radius = 15,
        distraction = defines.distraction.by_enemy}
    else
      g.count = g.count + 1
      unit.destroy()
    end
  end)
  -- no garrison stays over GARRISON at peace: the rest goes back into the nests
  for _, d in pairs(list) do
    local g = garrison(d)
    if g.units then
      local n = 0
      for k, unit in pairs(g.units) do
        if unit.valid then
          n = n + 1
          if n > GARRISON then unit.destroy() g.units[k] = nil end
        end
      end
    else
      g.count = math.min(g.count, GARRISON)
    end
  end
  log_event(w, "hive_win", nil, "every district back, brain healed")
  storage.wars[id] = nil
end

hive.connect{
  log = function(id, event, slot, detail)
    local w = storage.wars[id]
    if w then log_event(w, event, slot, detail) end
  end,
  -- The elder queen settled: heart back, nests awake, the survivors are the garrison.
  retaken = function(surface, id, slot, units)
    local d = find_district(id, slot)
    if not d then return end
    local position = heart_position(d)
    if surface.count_entities_filtered{position = position, radius = 1.5, name = HEART} == 0 then
      surface.create_entity{name = HEART, position = position, force = "enemy"}
      -- units standing where the heart now is would be stuck in it: move them out
      for _, unit in pairs(surface.find_entities_filtered{position = position, radius = 7, type = "unit", force = "enemy"}) do
        local free = surface.find_non_colliding_position(unit.name, unit.position, 20, 0.5)
        if free then unit.teleport(free) end
      end
    end
    d.fallen, d.left_since, d.queen_progress = nil, nil, 0
    for _, n in pairs(living_nests(surface, d)) do n.disabled_by_script = false end
    local g = {units = {}, progress = 0}
    d.garrison = g
    for _, unit in pairs(units) do
      if unit.valid then
        g.units[unit.unit_number] = unit
        post(unit)
      end
    end
    local w = storage.wars[id]
    if w then log_event(w, "retaken", slot, string.format("%d units in the garrison", #units)) end
    check_hive_win(surface, id)
  end,
  -- A unit of an army or raid goes home to the core.
  rejoin = function(id, unit)
    local centre = brain_centre(id)
    if centre and unit.valid then core.receive(id, unit, centre) end
  end,
  queen_back = function(id, queen)
    local centre = brain_centre(id)
    if centre then core.queen_back(id, queen, centre) else queen.destroy() end
  end,
  queen_used = function(id, queen) core.queen_used(id, queen) end,
  done = function(id, kind, outcome)
    local w = storage.wars[id]
    if w and kind ~= "raid" then w.retry_after = game.tick + (outcome == "retreat" and RETRY or 0) end
  end,
}

-- Debug: the next retake of territory id (or every territory at war) starts now: every fallen district counts as
-- left, no wait for units or the retry, 5 s massing (a queen is made if the reserve is empty).
function war.retake_now(id)
  init_storage()
  local n = 0
  for wid, w in pairs(storage.wars) do
    if not id or wid == id then
      w.force_retake, w.retry_after = true, 0
      for _, d in pairs(all_built(wid)) do if d.fallen then d.left_since = game.tick - LEFT_AFTER end end
      n = n + 1
    end
  end
  return n
end

-- Debug: the next raid goes as soon as it has a target and any unit in the raid fund.
function war.raid_now(id)
  init_storage()
  local n = 0
  for wid, w in pairs(storage.wars) do
    if not id or wid == id then w.force_raid, n = true, n + 1 end
  end
  return n
end

-- Debug: every live heart of every war makes its next queen now (while the reserve has room).
function war.queen_now()
  init_storage()
  local n = 0
  for wid in pairs(storage.wars) do
    for _, d in pairs(all_built(wid)) do
      if live(d) then d.queen_progress, n = QUEEN_EVERY, n + 1 end
    end
  end
  return n
end

-- Is unit in a district garrison (attacks.lua must not cancel it)?
function war.owns(unit)
  if core.owns(unit) then return true end
  for _, state in pairs(storage.districts or {}) do
    for _, d in pairs(state.list) do
      if d.garrison and d.garrison.units and d.garrison.units[unit.unit_number] then return true end
    end
  end
  return false
end

function war.on_unit_died(event) influence.on_unit_died(event.entity) end

function war.on_tick()
  init_storage()
  local surface = game.surfaces[territories.surface_name]
  if not surface or not storage.districts then return end
  local chars = characters(surface)
  local forces = {}
  for _, force in pairs(game.forces) do if player_force(force) then forces[#forces + 1] = force end end
  for id, state in pairs(storage.districts) do
    local record = storage.territories and storage.territories[id]
    local w = storage.wars[id]
    if w and (not (record and record.territory.valid) or record.state == "claimed") then
      war.on_won(id)
      w = nil
    end
    if record and record.territory.valid and record.state ~= "claimed" then
      for _, d in pairs(state.list) do
        local f = w and w.fights[d.slot]
        if f then
          local players = within(chars, heart_position(d), RANGE)
          if #players == 0 then
            f.lose_since = f.lose_since or game.tick
            if game.tick - f.lose_since >= LOSE_GRACE then
              send_home(f, d)
              end_fight(w, d, f, "left")
            end
          else
            f.lose_since = nil
            for _, c in pairs(players) do
              local player = player_of(c)
              if player then f.players[player.index] = true end
            end
            run_fight(surface, d, f, players, id)
            sample(surface, d, f, players)
          end
        elseif live(d) then
          run_peace(surface, w, record, d, chars, forces)
          w = storage.wars[id]
        end
      end
      if w then
        track_left(id, chars)
        local centre = brain_centre(id)
        if centre then
          core.tick(surface, id, centre, chars, forces)
          make_queens(surface, id, centre)
          brain_income(surface, w, id, centre)
          decide(surface, w, id, chars, centre)
          core_sample(w, id)
        end
      end
    end
  end
  hive.on_tick(surface, chars)
  if game.tick % influence.INTERVAL < war.CHECK_INTERVAL then
    local centres = {}
    for id in pairs(storage.wars) do
      local head = brain_head(id)
      if head then centres[id] = head.position end
    end
    influence.update(surface, centres)
  end
end

-- Debug: the garrison of the district nearest position (within 300 tiles) to full now. Returns its slot or nil.
function war.fill(surface, position)
  init_storage()
  local best, bd, best_id
  for id, state in pairs(storage.districts or {}) do
    for _, d in pairs(state.list) do
      if live(d) then
        local q = dist2(heart_position(d), position)
        if q <= 300 * 300 and (not bd or q < bd) then best, bd, best_id = d, q, id end
      end
    end
  end
  if not best then return nil end
  local g = garrison(best)
  if g.units then
    for _ = garrison_alive(g) + 1, GARRISON do
      local unit = spawn_unit(surface, g, post_position(best))
      if unit then post(unit) end
    end
  else
    g.count, g.hidden_tick = GARRISON, game.tick
  end
  return best_id, best.slot
end

function war.describe()
  init_storage()
  local parts = {}
  for id, w in pairs(storage.wars) do
    local fallen, fights = {}, 0
    for _, d in pairs(storage.districts[id] and storage.districts[id].list or {}) do
      if d.fallen then fallen[#fallen + 1] = string.format("[gps=%d,%d]", d.x, d.y) end
    end
    for _ in pairs(w.fights) do fights = fights + 1 end
    parts[#parts + 1] = string.format("territory %d (%d s, %d fights, fallen: %s, %s; brain made %d; next district %s; last decision: %s)",
      id, math.floor((game.tick - w.started_tick) / 60), fights, #fallen > 0 and table.concat(fallen, " ") or "none",
      core.describe(id), w.brain_made or 0, w.predicted and ("d" .. w.predicted) or "none", w.last_decision or "none")
  end
  local shown, units = {}, 0
  for _, state in pairs(storage.districts or {}) do
    for _, d in pairs(state.list) do
      if d.garrison and d.garrison.units then
        local n = garrison_alive(d.garrison)
        units = units + n
        shown[#shown + 1] = string.format("[gps=%d,%d] %d", d.x, d.y, n)
      end
    end
  end
  return "Wars: " .. (#parts > 0 and table.concat(parts, "; ") or "none") .. ". Garrisons on the map: " ..
    (#shown > 0 and table.concat(shown, ", ") or "none") .. ". " .. hive.describe() .. " " .. influence.describe()
end

return war
