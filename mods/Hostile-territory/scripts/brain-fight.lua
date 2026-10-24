-- The brain's side of the ring-1 fight (oil-ring-challenge-plan.md OR-E6, OR-E7): phased rings with P.shield in
-- waves.PHASES.
--   Shield bearers (OR-E7, OR-D47, OR-D48; replace OR-E6's "kill 70 % of the surge", PT6: unclear what unlocks the
--   brain): at the start of every surge but the frenzy, BEARERS ht-shield-bearer appear and stand
--   BEARER_MIN..BEARER_MAX tiles from it, 120° apart, each with a dashed line to the brain. They hold their spot and
--   don't fight. While one of them lives
--   the shield is up: the brain gets P.shield of every hit back (on_segmented_unit_damaged). All dead → open until the
--   next surge. The frenzy leaves it open; before the first surge it's open. Lure (OR-D49): open while the director
--   has the hive pulled back (record.regroup). Shown by a ring around the brain: blue while shut, red while open.
--   Guard rush trigger (E6-4): a participant damaging the brain sets record.brain_hit_tick; director.lua sends the
--   reserve squad (and ends a regroup).
--   Rocks (OR-D50, from surge 1; only with P.rock_walls, off since OR-D54): every ROCK_EVERY a wall of 3 huge rocks across your path ROCK_AHEAD tiles ahead
--   (your heading from the director's velocity; none while you stand still), after a ROCK_TELL warning (circles on
--   the ground). They stay, also after the challenge. Never locks you in: no rock within ROCK_MIN tiles of you, the
--   fight's rocks within ROCK_COVER_RADIUS of you cover at most ROCK_COVER_MAX of the circle around you, at most
--   ROCK_WALLS walls per fight.
--   Arena (OR-D51, surge 2): a ring of rocks ARENA_RADIUS tiles around you, one every ARENA_STEP tiles, with
--   ARENA_GAPS gaps of ARENA_GAP tiles. Stays too.
-- record.fight = {shield = "open" / "shut", surge, render (object id), walls = {{rocks = {entity, ...}}, ...},
--   pending = {spots, at_tick, arena}, next_rock}; record.bearers = {[unit_number] = entity}.
-- record.stats = {charged, charges, guard_rush, stand_still, rocks, openings, regroups, arena}: running totals.

local territories = require("scripts.territories")
local waves = require("scripts.waves")

local brain_fight = {}

local SHUT_COLOR, OPEN_COLOR = {r = 0.3, g = 0.5, b = 1, a = 0.6}, {r = 1, g = 0.2, b = 0.1, a = 0.7}
local LINE_COLOR = {r = 0.3, g = 0.9, b = 1, a = 0.6}
local RING_RADIUS = 3.5
local BEARER = "ht-shield-bearer"
local BEARERS, BEARER_MIN, BEARER_MAX = 3, 6, 10
local BEARER_WAIT = 10 * 60 * 60

local ROCK = "huge-rock"
local ROCK_EVERY, ROCK_TELL = 8 * 60, 60
local ROCK_AHEAD, ROCK_SPACING, ROCK_HALF_WIDTH = 8, 3, 1.5
local ROCK_MIN, ROCK_COVER_RADIUS, ROCK_COVER_MAX = 4, 12, math.pi / 2
local ROCK_WALLS = 30
local ARENA_RADIUS, ARENA_STEP, ARENA_GAPS, ARENA_GAP = 28, 3, 4, 4 -- OR-D57 (PT8): 22 → 28
local MOVING = 1.5 -- tiles/s: slower counts as standing still (no heading)

local function notify(record, message)
  for index in pairs(record.players) do
    local player = game.get_player(index)
    if player and player.connected then player.print(message) end
  end
end

function brain_fight.stats(record)
  record.stats = record.stats or {charged = 0, charges = 0, guard_rush = 0, stand_still = 0, rocks = 0, openings = 0,
    regroups = 0, arena = 0}
  return record.stats
end

local function head_entity(record)
  local territory_record = storage.territories[record.territory_id]
  local unit = territory_record and territory_record.territory.valid and territory_record.territory.get_segmented_units()[1]
  local head = unit and unit.valid and unit.segments[1]
  return head and head.entity
end

-- The running challenge (or headless debug record) of the territory a segmented unit guards.
local function record_of(unit)
  local territory_record = unit.territory and territories.get(unit.territory)
  if not territory_record then return nil end
  local id = territory_record.id
  return (storage.challenges and storage.challenges[id]) or (storage.debug_waves and storage.debug_waves[id])
end

local function is_participant(cause)
  if not (cause and cause.valid) then return false end
  if cause.force.name ~= "player" then return false end
  return cause.type == "character" or cause.type == "car" or cause.type == "spider-vehicle"
end

-- on_segmented_unit_damaged: the shield refund, and the guard rush trigger.
function brain_fight.on_damaged(event)
  local unit = event.segmented_unit
  if not (unit and unit.valid) then return end
  local record = record_of(unit)
  if not (record and record.fight) then return end
  if is_participant(event.cause) then record.brain_hit_tick = game.tick end
  local P = waves.PHASES[record.ring]
  if record.fight.shield == "shut" and event.final_health > 0 then
    unit.health = math.min(unit.max_health, unit.health + event.final_damage_amount * P.shield)
  end
end

local function set_render(record, color)
  local fight = record.fight
  if fight.render then
    local object = rendering.get_object_by_id(fight.render)
    if object then object.destroy() end
    fight.render = nil
  end
  local head = color and head_entity(record)
  if head then
    fight.render = rendering.draw_circle{color = color, radius = RING_RADIUS, width = 6, target = head,
      surface = head.surface, draw_on_ground = true}.id
  end
end

local function set_shield(record, shield, message)
  local fight = record.fight
  if fight.shield == shield then return end
  fight.shield = shield
  if shield == "open" then brain_fight.stats(record).openings = brain_fight.stats(record).openings + 1 end
  set_render(record, shield == "open" and OPEN_COLOR or SHUT_COLOR)
  if message then notify(record, message) end
end

local function distance_squared(a, b) return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 end

local function bearers_alive(record)
  local n = 0
  for number, unit in pairs(record.bearers or {}) do
    if unit.valid then n = n + 1 else record.bearers[number] = nil end
  end
  return n
end
brain_fight.bearers_alive = bearers_alive

-- BEARERS shield bearers out of the brain, each to its spot around it. Returns how many were placed.
local function spawn_bearers(record, surface)
  local head = head_entity(record)
  if not head then return 0 end
  record.bearers = {}
  local o = record.origin
  local rotation = math.random() * 2 * math.pi
  local placed = 0
  for i = 1, BEARERS do
    local angle = rotation + (i - 1) * 2 * math.pi / BEARERS
    local radius = BEARER_MIN + math.random() * (BEARER_MAX - BEARER_MIN)
    local spot = surface.find_non_colliding_position(BEARER, {o.x + math.cos(angle) * radius, o.y + math.sin(angle) * radius}, 6, 0.5)
    -- created at the spot: walking out of the brain, one took the long way round through the base (headless)
    local unit = spot and surface.create_entity{name = BEARER, position = spot, force = "enemy"}
    if unit then
      -- distraction none: with by_enemy they chased you from their 30-tile vision (headless)
      unit.commandable.set_command{type = defines.command.wander, radius = 1, ticks_to_wait = BEARER_WAIT,
        distraction = defines.distraction.none}
      record.bearers[unit.unit_number] = unit
      record.spawned[unit.unit_number] = unit
      rendering.draw_line{color = LINE_COLOR, width = 2, from = unit, to = head, surface = surface,
        dash_length = 1, gap_length = 0.5}
      placed = placed + 1
    end
  end
  return placed
end

-- A bearer's command ended (walk failed, or the long wait is over): it stays where it is. Without a command the
-- game sent it after you (headless: one ended up 22 tiles from the brain).
function brain_fight.on_ai_command_completed(event)
  for _, records in pairs({storage.challenges or {}, storage.debug_waves or {}}) do
    for _, record in pairs(records) do
      local unit = record.bearers and record.bearers[event.unit_number]
      if unit and unit.valid then
        unit.commandable.set_command{type = defines.command.wander, radius = 1, ticks_to_wait = BEARER_WAIT,
          distraction = defines.distraction.none}
        return
      end
    end
  end
end

local function update_shield(record, surface)
  local fight = record.fight
  if (record.surge or 0) ~= (fight.surge or 0) then
    fight.surge = record.surge
    if record.frenzy then
      record.bearers = {}
      set_shield(record, "open", "The brain is exposed!")
    elseif spawn_bearers(record, surface) > 0 then
      set_shield(record, "shut", "The brain shields itself: kill its shield bearers!")
    else
      set_shield(record, "open", "The brain is exposed!")
    end
    return
  end
  local lure = record.regroup ~= nil
  if lure or bearers_alive(record) == 0 then
    set_shield(record, "open", not lure and fight.shield == "shut" and "The shield bearers are dead: the brain is exposed!" or nil)
  else
    set_shield(record, "shut", "The brain closes up.")
  end
end

-- Angular share of the circle around p that rocks within ROCK_COVER_RADIUS cover (sum of each rock's width).
local function cover(p, positions)
  local sum = 0
  for _, q in pairs(positions) do
    local d = math.sqrt(distance_squared(p, q))
    if d < ROCK_COVER_RADIUS then sum = sum + 2 * math.atan(ROCK_HALF_WIDTH / math.max(d, ROCK_HALF_WIDTH)) end
  end
  return sum
end

local function live_rock_positions(fight)
  local list = {}
  for _, wall in pairs(fight.walls) do
    for _, rock in pairs(wall.rocks) do if rock.valid then list[#list + 1] = rock.position end end
  end
  return list
end

-- Spots of a wall across the heading of target entry d (director entry), or nil.
local function plan_wall(d, p)
  if not (d and d.vx) then return nil end
  local speed = math.sqrt(d.vx * d.vx + d.vy * d.vy)
  if speed < MOVING then return nil end
  local hx, hy = d.vx / speed, d.vy / speed
  local cx, cy = p.x + hx * ROCK_AHEAD, p.y + hy * ROCK_AHEAD
  local spots = {}
  for k = -1, 1 do spots[#spots + 1] = {x = cx - hy * k * ROCK_SPACING, y = cy + hx * k * ROCK_SPACING} end
  return spots
end

-- Spots of the arena ring around p: every ARENA_STEP tiles, leaving ARENA_GAPS gaps.
local function plan_arena(p)
  local spots = {}
  local rotation = math.random() * 2 * math.pi
  local half_gap = (ARENA_GAP / 2 + ROCK_HALF_WIDTH) / ARENA_RADIUS -- the gap is free of rock edges, not centres
  local n = math.floor(2 * math.pi * ARENA_RADIUS / ARENA_STEP)
  for i = 0, n - 1 do
    local angle = i * 2 * math.pi / n
    local open = false
    for k = 0, ARENA_GAPS - 1 do
      local centre = rotation + k * 2 * math.pi / ARENA_GAPS
      if math.abs((angle - centre + math.pi) % (2 * math.pi) - math.pi) < half_gap then open = true end
    end
    if not open then spots[#spots + 1] = {x = p.x + math.cos(angle) * ARENA_RADIUS, y = p.y + math.sin(angle) * ARENA_RADIUS} end
  end
  return spots
end

-- The safety rules (OR-D41) for these rock positions around p, with the fight's rocks already standing.
local function safe(fight, p, positions)
  for _, q in pairs(positions) do
    if distance_squared(p, q) < ROCK_MIN * ROCK_MIN then return false end
  end
  local all = live_rock_positions(fight)
  for _, q in pairs(positions) do all[#all + 1] = q end
  return cover(p, all) <= ROCK_COVER_MAX
end

local function tell_rocks(surface, spots)
  for _, spot in pairs(spots) do
    rendering.draw_circle{color = {r = 0.6, g = 0.4, b = 0.2, a = 0.5}, radius = 1.5, filled = true, target = spot,
      surface = surface, time_to_live = ROCK_TELL, draw_on_ground = true}
  end
end

local function place_pending(record, surface, p)
  local fight = record.fight
  local placed = {}
  for _, spot in pairs(fight.pending.spots) do
    local position = surface.find_non_colliding_position(ROCK, spot, fight.pending.arena and 1 or 1.5, 0.5)
    -- the arena is far from you (22 tiles): only the "not on you" rule applies to it
    local ok = position and (fight.pending.arena and distance_squared(p, position) >= ROCK_MIN * ROCK_MIN
      or not fight.pending.arena and safe(fight, p, {position}))
    if ok then
      local rock = surface.create_entity{name = ROCK, position = position}
      if rock then
        placed[#placed + 1] = rock
        if not fight.pending.arena then -- headless: the safety values at placement
          local s = brain_fight.stats(record)
          s.rock_min = math.min(s.rock_min or math.huge, math.sqrt(distance_squared(p, position)))
          s.rock_cover = math.max(s.rock_cover or 0, cover(p, live_rock_positions(fight)) + cover(p, {position}))
        end
      end
    end
  end
  local s = brain_fight.stats(record)
  if fight.pending.arena then s.arena = s.arena + #placed else s.rocks = s.rocks + #placed end
  if #placed > 0 then fight.walls[#fight.walls + 1] = {rocks = placed, arena = fight.pending.arena} end
  fight.pending = nil
end

local function update_rocks(record, surface, targets)
  local fight = record.fight
  if (record.surge or 0) < 1 or #targets == 0 then return end
  local target = targets[1].entity
  local p = target.position
  if fight.pending then
    if game.tick >= fight.pending.at_tick then place_pending(record, surface, p) end
    return
  end
  if record.surge >= 2 and not fight.arena_done then
    fight.arena_done = true
    local spots = plan_arena(p)
    fight.pending = {spots = spots, at_tick = game.tick + ROCK_TELL, arena = true}
    tell_rocks(surface, spots)
    return
  end
  if not waves.PHASES[record.ring].rock_walls then return end
  local walls = 0
  for _, wall in pairs(fight.walls) do if not wall.arena then walls = walls + 1 end end
  if game.tick < (fight.next_rock or 0) or walls >= ROCK_WALLS then return end
  local spots = plan_wall(record.director and record.director[target.unit_number], p)
  if not (spots and safe(fight, p, spots)) then return end
  fight.next_rock = game.tick + ROCK_EVERY
  fight.pending = {spots = spots, at_tick = game.tick + ROCK_TELL}
  tell_rocks(surface, spots)
end

-- Every challenge check, after waves.update and director.update.
function brain_fight.update(record, surface, targets)
  local P = waves.PHASES[record.ring]
  if not (P and P.shield) then return end
  record.fight = record.fight or {shield = "open", surge = 0, walls = {}}
  brain_fight.stats(record)
  if record.phase == "swarm" then update_shield(record, surface) end
  update_rocks(record, surface, targets)
end

-- Challenge over: the ring around the brain goes; rocks stay (OR-D50).
function brain_fight.clear(record)
  local fight = record.fight
  if not fight then return end
  fight.pending = nil
  set_render(record, nil)
end

function brain_fight.describe(record)
  local fight = record.fight
  if not fight then return "" end
  local rocks = 0
  for _, wall in pairs(fight.walls) do
    for _, rock in pairs(wall.rocks) do if rock.valid then rocks = rocks + 1 end end
  end
  return string.format(", brain %s, bearers %d, rocks %d", fight.shield, bearers_alive(record), rocks)
end

return brain_fight
