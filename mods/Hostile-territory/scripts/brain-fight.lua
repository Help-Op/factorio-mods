-- The brain's side of the ring-1 fight (oil-ring-challenge-plan.md OR-E6, OR-E7): phased rings with P.shield in
-- waves.PHASES.
--   Shield links (OR-E8 E8-A2, OR-D74, OR-D75; replace OR-E7's bearers out of the brain per surge, PT12: two
--   mechanics for one job, bearers from nowhere): the anchors are the spawners ANCHOR_MIN..ANCHOR_MAX tiles from the
--   brain when the fight starts (map gen's anchor ring, brain-bases.lua), each with a dashed line to the brain. An
--   anchor that dies releases an ht-shield-bearer at its spot, which walks to BEARER_MIN..BEARER_MAX tiles from the
--   brain on the anchor's side and holds there (doesn't fight); the line moves to it. Still walking after BEARER_WALK
--   (a spot behind the brain's body can mean a path all the way round): a new spot on the side it's on now; after
--   another BEARER_WALK it holds where it is. While any link lives (anchor or
--   its bearer), from the start of the fight, the shield is up: the brain gets P.shield of every hit back
--   (on_segmented_unit_damaged). All broken → open for good. The frenzy opens it too; a base without anchors is open.
--   Lure (OR-D49): open while the director has the hive pulled back (record.regroup). Shown by a ring around the
--   brain: blue while shut, red while open.
--   Queens (OR-E8 E8-B, OR-D78–D80; with P.queens): BP-1 (OR-D99, PT17: nests cleared early left only 2 queens): when
--   the wake starts (not in the siege: an anchor death no longer starts them), all QUEENS come out at once, each from
--   the living nest furthest from you that hasn't released one yet (headless: at the wake you stand next to the
--   nearest nest, so all 4 fled at once and their escorts were on you); a dead queen is replaced QUEEN_EVERY later by
--   the nest nearest to you. No nest left → no new queens. A queen walks (no distractions) to a spot
--   QUEEN_MIN..QUEEN_MAX tiles from you in one of QUEENS slots all around you (OR-D91; see queen_spot) and holds
--   there; a new spot when hers is closer than QUEEN_NEAR or further than QUEEN_FAR from you (OR-D93), or after a
--   failed walk. A walk longer than QUEEN_WALK ends where she is. Holding or walking (OR-D92): QUEEN_SPAWN small biters every
--   QUEEN_SPAWN_EVERY, plus record.queen_level (OR-E11, OR-D89: the director raises it while you're calm), on top of
--   the surges, paused while the challenge has QUEEN_CAP units alive. They run straight at you (waves.spawn_from, then
--   marked as charging for QUEEN_RUN so the squads leave them alone). QUEEN_ESCORT small biters come out with her, walk with her as one unit group
--   and stay within ESCORT_NEAR of her while she holds. Retreat (PT13: too easy to pick off): you within QUEEN_FLEE of
--   her → her escort stays and attacks you (for good: it joins the rest), and she walks alone to a new spot
--   QUEEN_MIN..QUEEN_MAX tiles from you in her slot (away from you). A dead queen's escort attacks you.
--   Guard rush trigger (E6-4): a participant damaging the brain sets record.brain_hit_tick; director.lua sends the
--   reserve squad (and ends a regroup).
--   Rocks (OR-D50, from surge 1; only with P.rock_walls, off since OR-D54): every ROCK_EVERY a wall of 3 huge rocks across your path ROCK_AHEAD tiles ahead
--   (your heading from the director's velocity; none while you stand still), after a ROCK_TELL warning (circles on
--   the ground). They stay, also after the challenge. Never locks you in: no rock within ROCK_MIN tiles of you, the
--   fight's rocks within ROCK_COVER_RADIUS of you cover at most ROCK_COVER_MAX of the circle around you, at most
--   ROCK_WALLS walls per fight.
--   Arena (OR-D51, surge 2): a ring of rocks ARENA_RADIUS tiles around you, one every ARENA_STEP tiles, with
--   ARENA_GAPS gaps of ARENA_GAP tiles. Stays too.
-- record.fight = {shield = "open" / "shut", render (object id), walls = {{rocks = {entity, ...}}, ...},
--   pending = {spots, at_tick, arena}, next_rock, anchors = {[unit_number] = entity}, anchors_start, lines =
--   {object id, ...}, links_down}; record.bearers = {[unit_number] = entity}.
-- record.queens = {[unit_number] = {entity, spot, picked_at, state = "walk" / "hold" / "flee" / "repick", next_spawn, group,
--   walk_since}},
-- record.escorts = {[unit_number] = {entity, queen = unit_number}}; record.fight.queens_on, queen_next.
-- record.stats = {charged, charges, guard_rush, stand_still, rocks, openings, regroups, arena, queens,
--   queen_spawned}: running totals.

local territories = require("scripts.territories")
local waves = require("scripts.waves")

local brain_fight = {}

local SHUT_COLOR, OPEN_COLOR = {r = 0.3, g = 0.5, b = 1, a = 0.6}, {r = 1, g = 0.2, b = 0.1, a = 0.7}
local LINE_COLOR = {r = 0.3, g = 0.9, b = 1, a = 0.6}
local ANCHOR_MIN, ANCHOR_MAX = 29, 36 -- the anchor ring is at 32 (brain-bases.lua)
local RING_RADIUS = 3.5
local BEARER = "ht-shield-bearer"
local BEARER_MIN, BEARER_MAX = 6, 10
local BEARER_WAIT = 10 * 60 * 60
local QUEEN = "ht-queen"
local QUEENS, QUEEN_EVERY = 4, 20 * 60 -- OR-D88 (PT14): 2 → 4
local QUEEN_MIN, QUEEN_MAX = 50, 70 -- PT13: 20–28 made her easy to pick off; OR-D88: 40–50 → 50–70
local QUEEN_NEAR, QUEEN_FAR = 40, 80 -- OR-D93 (PT15): a new spot only when hers is out of this band from you
local QUEEN_SLOT_TURN, QUEEN_JITTER = math.pi / 4, math.rad(20) -- OR-D91: slots all around, none on the brain road
local QUEEN_FLEE = 25
local QUEEN_WALK = 20 * 60 -- a longer walk (cliffs, forest: headless) ends where she is
local QUEEN_SPAWN, QUEEN_SPAWN_EVERY, QUEEN_CAP = 3, 4 * 60, 800 -- OR-E11: cap 300 → 500; BP-1 (OR-D100): 500 → 800
-- (PT16, PT17: the surges alone filled 500, so the queens stalled in the swarm)
local QUEEN_RUN = 10 * 60 -- her biters run straight at you: the squads leave them alone this long
local QUEEN_ESCORT, ESCORT_NEAR, ESCORT_REPATH = 8, 6, 4
local QUEEN_THERE = 4
local BEARER_WALK = 12 * 60 -- a walk in that takes longer went the long way round (headless): new spot on its side, once

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
  local refund = 1 - brain_fight.take(record)
  if refund > 0 and event.final_health > 0 then
    unit.health = math.min(unit.max_health, unit.health + event.final_damage_amount * refund)
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

local function anchors_alive(record)
  local fight = record.fight
  local n = 0
  for number, nest in pairs(fight and fight.anchors or {}) do
    if nest.valid then n = n + 1 else fight.anchors[number] = nil end
  end
  return n
end
brain_fight.anchors_alive = anchors_alive

-- Links still holding the shield: anchors alive + bearers alive (OR-D74).
function brain_fight.links_alive(record)
  return anchors_alive(record) + bearers_alive(record)
end

-- Share of a hit the brain keeps now: shut 1 - P.shield, open 1.
function brain_fight.take(record)
  local fight = record.fight
  if not (fight and fight.shield == "shut") then return 1 end
  return 1 - waves.PHASES[record.ring].shield
end

local function draw_link(fight, from, head)
  fight.lines[#fight.lines + 1] = rendering.draw_line{color = LINE_COLOR, width = 2, from = from, to = head,
    surface = head.surface, dash_length = 1, gap_length = 0.5}.id
end

-- The anchor ring around the brain when the fight starts, each with a line to the brain.
local function find_anchors(record, surface)
  local fight = record.fight
  fight.anchors, fight.lines, fight.anchors_start = {}, {}, 0
  record.bearers = {}
  local head = head_entity(record)
  if not head then return end
  local o = record.origin
  for _, nest in pairs(surface.find_entities_filtered{position = o, radius = ANCHOR_MAX, type = "unit-spawner",
      force = "enemy"}) do
    if distance_squared(nest.position, o) >= ANCHOR_MIN * ANCHOR_MIN then
      fight.anchors[nest.unit_number] = nest
      fight.anchors_start = fight.anchors_start + 1
      draw_link(fight, nest, head)
    end
  end
end

local function hold(unit)
  unit.commandable.set_command{type = defines.command.wander, radius = 1, ticks_to_wait = BEARER_WAIT,
    distraction = defines.distraction.none}
end

-- Sends a bearer to a spot BEARER_MIN..BEARER_MAX tiles from the brain at the given angle; holds if there's none.
local function walk_in(record, unit, angle)
  local o = record.origin
  local radius = BEARER_MIN + math.random() * (BEARER_MAX - BEARER_MIN)
  local spot = unit.surface.find_non_colliding_position(BEARER, {o.x + math.cos(angle) * radius, o.y + math.sin(angle) * radius}, 6, 0.5)
  record.bearer_spots = record.bearer_spots or {}
  record.bearer_spots[unit.unit_number] = spot
  record.bearer_walk = record.bearer_walk or {}
  if spot then
    -- distraction none: with by_enemy they chased you from their 30-tile vision (headless, OR-E7)
    unit.commandable.set_command{type = defines.command.go_to_location, destination = spot, radius = 1,
      distraction = defines.distraction.none}
    local walk = record.bearer_walk[unit.unit_number]
    record.bearer_walk[unit.unit_number] = {since = game.tick, again = walk ~= nil}
  else
    hold(unit)
    record.bearer_walk[unit.unit_number] = nil
  end
end

-- An anchor died (OR-D74): its bearer comes out at its spot and walks in to BEARER_MIN..BEARER_MAX tiles from the
-- brain on the anchor's side. Returns the bearer, or nil.
local function release_bearer(record, nest)
  local fight = record.fight
  fight.anchors[nest.unit_number] = nil
  local head = head_entity(record)
  if not head then return nil end
  local surface, o, from = nest.surface, record.origin, nest.position
  local start = surface.find_non_colliding_position(BEARER, from, 8, 0.5)
  local unit = start and surface.create_entity{name = BEARER, position = start, force = "enemy"}
  if not unit then return nil end
  walk_in(record, unit, math.atan2(from.y - o.y, from.x - o.x))
  record.bearers[unit.unit_number] = unit
  record.spawned[unit.unit_number] = unit
  draw_link(fight, unit, head)
  notify(record, "An anchor falls: its bearer runs to the brain!")
  return unit
end

-- on_entity_died for nests: an anchor of a running fight releases its bearer.
function brain_fight.on_nest_died(event)
  local nest = event.entity
  for _, records in pairs({storage.challenges or {}, storage.debug_waves or {}}) do
    for _, record in pairs(records) do
      local fight = record.fight
      if fight and record.origin and distance_squared(nest.position, record.origin) <= ANCHOR_MAX * ANCHOR_MAX then
        if fight.anchors and fight.anchors[nest.unit_number] then release_bearer(record, nest) end
        return
      end
    end
  end
end

-- Units the director leaves alone (OR-E7, OR-E8): shield bearers, queens and their escorts.
function brain_fight.reserved(record, number)
  return (record.bearers and record.bearers[number]) or (record.queens and record.queens[number])
    or (record.escorts and record.escorts[number]) or false
end

local function count_alive(record)
  local n = 0
  for _, unit in pairs(record.spawned) do if unit.valid then n = n + 1 end end
  return n
end

-- A spot QUEEN_MIN..QUEEN_MAX tiles from p in one of QUEENS slots around it (OR-D91: all around, PT15), the slots
-- 360° / QUEENS apart starting QUEEN_SLOT_TURN off "away from the brain"; the queen takes the slot nearest her own
-- angle that no other queen holds (± QUEEN_JITTER).
local function queen_spot(record, surface, p, queen)
  local o = record.origin
  local away = math.atan2(p.y - o.y, p.x - o.x)
  local taken = {}
  for _, other in pairs(record.queens or {}) do
    if other ~= queen and other.slot and other.entity.valid then taken[other.slot] = true end
  end
  local q = queen.entity.position
  local mine = math.atan2(q.y - p.y, q.x - p.x)
  local best, best_off
  for k = 0, QUEENS - 1 do
    local a = away + QUEEN_SLOT_TURN + k * 2 * math.pi / QUEENS
    local off = math.abs((a - mine + math.pi) % (2 * math.pi) - math.pi)
    if not taken[k] and (not best_off or off < best_off) then best, best_off = k, off end
  end
  queen.slot = best or queen.slot or 0
  local centre = away + QUEEN_SLOT_TURN + queen.slot * 2 * math.pi / QUEENS
  for _ = 1, 6 do
    local a = centre + (math.random() * 2 - 1) * QUEEN_JITTER
    local d = QUEEN_MIN + math.random() * (QUEEN_MAX - QUEEN_MIN)
    local spot = surface.find_non_colliding_position(QUEEN, {p.x + math.cos(a) * d, p.y + math.sin(a) * d}, 4, 0.5)
    if spot then return spot end
  end
end

-- She stops: her walking group goes, she holds, her escort stays round her (update_queens).
local function arrive(record, queen)
  if queen.group and queen.group.valid then queen.group.destroy() end
  queen.group = nil
  queen.state = "hold"
  hold(queen.entity)
  for _, escort in pairs(record.escorts or {}) do
    if escort.queen == queen.entity.unit_number and escort.entity.valid then
      escort.dest = nil
      escort.entity.commandable.set_command{type = defines.command.wander, radius = 2, ticks_to_wait = BEARER_WAIT,
        distraction = defines.distraction.none}
    end
  end
end

-- She walks to a new spot with her escort as one unit group: alone, the escort crowded her (half her speed) or fell
-- 12-15 tiles behind (headless).
local function send_queen(record, surface, queen, p)
  queen.spot = queen_spot(record, surface, p, queen)
  queen.picked_at = {x = p.x, y = p.y}
  if not queen.spot then return arrive(record, queen) end
  if queen.group and queen.group.valid then queen.group.destroy() end
  local group = surface.create_unit_group{position = queen.entity.position, force = queen.entity.force}
  group.add_member(queen.entity)
  for _, escort in pairs(record.escorts or {}) do
    if escort.queen == queen.entity.unit_number and escort.entity.valid and not escort.attacking then
      group.add_member(escort.entity)
    end
  end
  group.set_command{type = defines.command.go_to_location, destination = queen.spot, radius = 3,
    distraction = defines.distraction.none}
  queen.group, queen.state, queen.walk_since = group, "walk", game.tick
end

local function attack(unit, target)
  unit.commandable.set_command{type = defines.command.attack, target = target, distraction = defines.distraction.by_enemy}
end

-- The living nest of the base nearest to the target releases a queen with her escort; with `used` (BP-1 burst), the
-- furthest one not in `used` (any nest once all are used).
local function release_queen(record, surface, target, quiet, used)
  local nests = surface.find_entities_filtered{position = record.origin, radius = ANCHOR_MAX, type = "unit-spawner",
    force = "enemy"}
  if #nests == 0 then return false end
  local nest, best
  for _, candidate in pairs(nests) do
    local d = distance_squared(candidate.position, target.position)
    if used then
      d = -d + (used[candidate.unit_number] and 1e9 or 0)
    end
    if not best or d < best then nest, best = candidate, d end
  end
  if used then used[nest.unit_number] = true end
  local position = surface.find_non_colliding_position(QUEEN, nest.position, 8, 0.5)
  local unit = position and surface.create_entity{name = QUEEN, position = position, force = "enemy"}
  if not unit then return false end
  record.queens = record.queens or {}
  record.escorts = record.escorts or {}
  local queen = {entity = unit, next_spawn = 0}
  record.queens[unit.unit_number] = queen
  record.spawned[unit.unit_number] = unit
  for _, escort in pairs(waves.spawn_from(record, surface, {nest}, QUEEN_ESCORT, target)) do
    record.escorts[escort.unit_number] = {entity = escort, queen = unit.unit_number}
    escort.commandable.set_command{type = defines.command.go_to_location, destination = position, radius = 3,
      distraction = defines.distraction.none}
  end
  send_queen(record, surface, queen, target.position)
  local stats = brain_fight.stats(record)
  stats.queens = (stats.queens or 0) + 1
  if not quiet then notify(record, "A queen crawls out of a nest!") end
  return true
end

-- You came for her: her escort stays and attacks you (it joins the rest for good), she walks alone to a new spot away
-- from you.
local function retreat(record, surface, queen, p, target)
  if queen.group and queen.group.valid then queen.group.destroy() end
  queen.group = nil
  for number, escort in pairs(record.escorts or {}) do
    if escort.queen == queen.entity.unit_number then
      record.escorts[number] = nil
      if escort.entity.valid then attack(escort.entity, target) end
    end
  end
  -- away from you, in her slot around you (OR-E12: straight away ignored the slots and bunched the queens, headless);
  -- her slot is the one nearest her own angle, so the way there leads away from you
  queen.spot = queen_spot(record, surface, p, queen)
  queen.picked_at = {x = p.x, y = p.y}
  if not queen.spot then return arrive(record, queen) end
  queen.entity.commandable.set_command{type = defines.command.go_to_location, destination = queen.spot, radius = 3,
    distraction = defines.distraction.none}
  queen.state, queen.walk_since = "flee", game.tick
  brain_fight.stats(record).queen_retreats = (brain_fight.stats(record).queen_retreats or 0) + 1
end

local function update_queens(record, surface, targets)
  local fight = record.fight
  if not (targets[1] and targets[1].entity.valid) then return end
  local burst = false
  if not fight.queens_on then
    if record.phase == "siege" then return end
    fight.queens_on, burst = true, true -- BP-1 (OR-D99): the wake starts → all QUEENS at once
  end
  local target = targets[1].entity
  local p = target.position
  local alive = 0
  for number, queen in pairs(record.queens or {}) do
    if queen.entity.valid then
      alive = alive + 1
    else
      if queen.group and queen.group.valid then queen.group.destroy() end
      record.queens[number] = nil
      fight.queen_next = math.max(fight.queen_next or 0, game.tick + QUEEN_EVERY)
    end
  end
  if burst then
    local released, used = 0, {}
    while alive < QUEENS and release_queen(record, surface, target, true, used) do
      alive, released = alive + 1, released + 1
    end
    if released > 0 then notify(record, "The queens crawl out of the nests!") end
    fight.queen_next = game.tick + QUEEN_EVERY
  elseif alive < QUEENS and game.tick >= (fight.queen_next or 0) and release_queen(record, surface, target) then
    alive = alive + 1
    fight.queen_next = game.tick + QUEEN_EVERY
  end
  local stats = brain_fight.stats(record)
  for _, queen in pairs(record.queens or {}) do
    local close = distance_squared(queen.entity.position, p) < QUEEN_FLEE * QUEEN_FLEE
    if close and queen.state ~= "flee" then
      retreat(record, surface, queen, p, target)
    elseif queen.state == "repick" or (queen.state ~= "flee" and queen.spot
        and (distance_squared(p, queen.spot) < QUEEN_NEAR * QUEEN_NEAR
          or distance_squared(p, queen.spot) > QUEEN_FAR * QUEEN_FAR)) then
      send_queen(record, surface, queen, p)
    elseif queen.state == "flee" and (game.tick - queen.walk_since > QUEEN_WALK
        or distance_squared(queen.entity.position, queen.spot) < QUEEN_THERE * QUEEN_THERE) then
      arrive(record, queen)
    elseif queen.state == "walk" and (game.tick - queen.walk_since > QUEEN_WALK
        or not (queen.group and queen.group.valid)
        or distance_squared(queen.entity.position, queen.spot) < QUEEN_THERE * QUEEN_THERE) then
      arrive(record, queen) -- there, or too long
    elseif queen.state == "hold" and (not queen.entity.commandable.command
        or queen.entity.commandable.command.type ~= defines.command.wander) then
      hold(queen.entity) -- the engine sometimes sends an idle unit back to a nest (headless)
    end
    if game.tick >= queen.next_spawn then -- OR-D92 (PT15): walking too (she mostly walked, 1.8 biters/s at level 9)
      queen.next_spawn = game.tick + QUEEN_SPAWN_EVERY
      if count_alive(record) < QUEEN_CAP then
        local spawned = waves.spawn_from(record, surface, {queen.entity}, QUEEN_SPAWN + (record.queen_level or 0), target)
        record.charging = record.charging or {}
        for _, unit in pairs(spawned) do record.charging[unit.unit_number] = game.tick + QUEEN_RUN end
        stats.queen_spawned = (stats.queen_spawned or 0) + #spawned
      end
    end
  end
  for number, escort in pairs(record.escorts or {}) do
    local unit = escort.entity
    local queen = record.queens and record.queens[escort.queen]
    if not unit.valid then
      record.escorts[number] = nil
    elseif not queen then
      record.escorts[number] = nil -- her escort joins the rest
      attack(unit, target)
    elseif queen.state ~= "walk" then -- walking, they're in her group
      local follow = queen.entity.position
      -- a new path only when she moved on (re-pathing every check stalled them)
      local moved = not escort.dest or distance_squared(escort.dest, follow) > ESCORT_REPATH * ESCORT_REPATH
      if escort.attacking or (moved and distance_squared(unit.position, follow) > ESCORT_NEAR * ESCORT_NEAR) then
        escort.attacking, escort.dest = nil, follow
        unit.commandable.set_command{type = defines.command.go_to_location, destination = follow, radius = 3,
          distraction = defines.distraction.none}
      end
    end
  end
end

function brain_fight.queens_alive(record)
  local n = 0
  for _, queen in pairs(record.queens or {}) do if queen.entity.valid then n = n + 1 end end
  return n
end

-- A bearer's command ended (it arrived, its walk failed, or the long wait is over): it stays where it is. Without a
-- command the game sent it after you (headless: one ended up 22 tiles from the brain).
function brain_fight.on_ai_command_completed(event)
  for _, records in pairs({storage.challenges or {}, storage.debug_waves or {}}) do
    for _, record in pairs(records) do
      local unit = record.bearers and record.bearers[event.unit_number]
      if unit and unit.valid then
        hold(unit)
        if record.bearer_walk then record.bearer_walk[event.unit_number] = nil end
        return
      end
      local escort = record.escorts and record.escorts[event.unit_number]
      if escort and escort.entity.valid then
        escort.attacking = nil
        escort.entity.commandable.set_command{type = defines.command.wander, radius = 2, ticks_to_wait = BEARER_WAIT,
          distraction = defines.distraction.none}
        return
      end
      local queen = record.queens and record.queens[event.unit_number]
      if queen and queen.entity.valid then
        -- arrived: hold and spawn; a failed walk: a new spot next check
        if (queen.state == "walk" or queen.state == "flee") and event.result ~= defines.behavior_result.success then
          queen.state = "repick"
        else
          queen.state = "hold"
          hold(queen.entity)
        end
        return
      end
    end
  end
end

-- Bearers still walking in after BEARER_WALK: a new spot on the side they're on now, then hold (see the top).
local function update_bearers(record)
  for number, walk in pairs(record.bearer_walk or {}) do
    local unit = record.bearers and record.bearers[number]
    if not (unit and unit.valid) then
      record.bearer_walk[number] = nil
    elseif game.tick - walk.since > BEARER_WALK then
      if walk.again then
        hold(unit)
        record.bearer_walk[number] = nil
      else
        local o, p = record.origin, unit.position
        walk_in(record, unit, math.atan2(p.y - o.y, p.x - o.x))
      end
    end
  end
end

local function update_shield(record)
  local fight = record.fight
  local links = brain_fight.links_alive(record)
  if links == 0 and not fight.links_down and (fight.anchors_start or 0) > 0 then
    fight.links_down = true
    set_shield(record, "open", "The links are broken: the brain is exposed!")
    return
  end
  if record.frenzy or record.regroup ~= nil or links == 0 then
    set_shield(record, "open", record.frenzy and fight.shield == "shut" and "The brain is exposed!" or nil)
  else
    set_shield(record, "shut", fight.shield ~= "shut" and not fight.shut_once and
      "The brain is shielded by its anchors: break the links!" or "The brain closes up.")
    fight.shut_once = true
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
  if not record.fight then
    record.fight = {shield = "open", walls = {}}
    find_anchors(record, surface)
  end
  brain_fight.stats(record)
  update_bearers(record)
  update_shield(record)
  if P.queens then update_queens(record, surface, targets) end
  update_rocks(record, surface, targets)
end

-- Challenge over: the ring around the brain goes; rocks stay (OR-D50).
function brain_fight.clear(record)
  local fight = record.fight
  if not fight then return end
  fight.pending = nil
  set_render(record, nil)
  for _, id in pairs(fight.lines or {}) do
    local object = rendering.get_object_by_id(id)
    if object then object.destroy() end
  end
  fight.lines = nil
end

function brain_fight.describe(record)
  local fight = record.fight
  if not fight then return "" end
  local rocks = 0
  for _, wall in pairs(fight.walls) do
    for _, rock in pairs(wall.rocks) do if rock.valid then rocks = rocks + 1 end end
  end
  return string.format(", brain %s (takes %d%%), links %d (anchors %d/%d, bearers %d), queens %d, rocks %d", fight.shield,
    math.floor(brain_fight.take(record) * 100 + 0.5), brain_fight.links_alive(record), anchors_alive(record),
    fight.anchors_start or 0, bearers_alive(record), brain_fight.queens_alive(record), rocks)
end

return brain_fight
