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
-- Telemetry: a CSV per fight (ht-telemetry/<tick>-t<id>-d<slot>.csv, a row per participant every SAMPLE ticks, a
-- summary line at the end) and a war log (ht-telemetry/<tick>-t<id>-war.csv, a row per event).
-- storage.wars[territory id] = {started_tick, log, fights = {[slot] = fight}}
--   fight = {slot, trigger, started_tick, players = {[player index] = true}, spawned = {[unit_number] = entity}
--     (committed units), held, lead = {tick, units}, sent, rebuilt, lose_since, deaths, file, rows, next_flush}
-- district.garrison (on the district in storage.districts) = {count (units while off the map), hidden_tick,
--   units = {[unit_number] = entity} (while on the map), idle_since, progress (rebuild)}

local territories = require("scripts.territories")
local districts = require("scripts.districts")

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
  local w = {started_tick = game.tick, fights = {}, log = string.format("ht-telemetry/%d-t%d-war.csv", game.tick, id)}
  helpers.write_file(w.log, "tick,second,event,slot,detail\n", false)
  storage.wars[id] = w
  log_event(w, "war_start")
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
  g.units[unit.unit_number] = unit
  return unit
end

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

-- The fallen district's garrison walks to the nearest live district and joins it, else to the brain.
local function relocate(surface, id, d)
  local g = d.garrison
  d.garrison = nil
  if not (g and g.units) then return 0, "none" end
  local best, bd
  for _, other in pairs(storage.districts[id].list) do
    if other ~= d and live(other) then
      local q = dist2(heart_position(other), heart_position(d))
      if not bd or q < bd then best, bd = other, q end
    end
  end
  local destination, joined
  if best then
    destination, joined = heart_position(best), garrison(best)
  else
    local record = storage.territories[id]
    local brain = record and record.territory.valid and record.territory.get_segmented_units()[1]
    local head = brain and brain.valid and brain.segments[1] -- a LuaSegmentedUnit has no position, its head does
    destination = head and head.position or heart_position(d)
  end
  local n = 0
  for _, unit in pairs(g.units) do
    if unit.valid then
      n = n + 1
      unit.commandable.set_command{type = defines.command.go_to_location, destination = destination, radius = 15,
        distraction = defines.distraction.by_enemy}
      if joined then
        if joined.units then joined.units[unit.unit_number] = unit else joined.count = math.min(GARRISON, joined.count + 1) end
      end
    end
  end
  if joined and not joined.units then for _, unit in pairs(g.units) do if unit.valid then unit.destroy() end end end
  return n, best and ("district " .. best.slot) or "brain"
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

-- Nests and heart add units (none without the heart). New units join a running fight.
local function rebuild(surface, d, g, f, players)
  local nests, heart = {}, false
  for _, n in pairs(living_nests(surface, d)) do
    if not n.disabled_by_script then
      nests[#nests + 1] = n
      if n.name == HEART then heart = true end
    end
  end
  if not heart then g.progress = 0 return end
  g.progress = g.progress + #nests * war.CHECK_INTERVAL / REBUILD
  local n = garrison_alive(g)
  local new = {}
  while g.progress >= 1 and n < GARRISON do
    g.progress = g.progress - 1
    local unit = spawn_unit(surface, g, nests[math.random(#nests)].position)
    if unit then
      n = n + 1
      if f then new[#new + 1] = unit else post(unit) end
    end
  end
  if n >= GARRISON then g.progress = 0 end
  if f and #new > 0 then
    f.rebuilt = f.rebuilt + #new
    commit(f, new, players)
  end
end

-- A running fight: hold release, brute lead, leash, retarget, rebuild.
local function run_fight(surface, d, f, players)
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
  rebuild(surface, d, g, f, players)
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
  if g.units then
    if seen then
      g.idle_since = nil
    else
      g.idle_since = g.idle_since or game.tick
      if game.tick - g.idle_since >= DESPAWN_AFTER then hide(g) return end
    end
    rebuild(surface, d, g)
  elseif seen then
    show(surface, d, g)
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
            run_fight(surface, d, f, players)
            sample(surface, d, f, players)
          end
        elseif live(d) then
          run_peace(surface, w, record, d, chars, forces)
          w = storage.wars[id]
        end
      end
    end
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
    parts[#parts + 1] = string.format("territory %d (%d s, %d fights, fallen: %s)", id,
      math.floor((game.tick - w.started_tick) / 60), fights, #fallen > 0 and table.concat(fallen, " ") or "none")
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
    (#shown > 0 and table.concat(shown, ", ") or "none") .. "."
end

return war
