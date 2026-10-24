-- Pressure director (oil-ring-challenge-plan.md OR-E2; OR-D13, OR-D17): during the swarm (incl. last stand) of a
-- phased ring with director = true in waves.PHASES (ring 1; ring 0 is open question Q6), keeps the damage a
-- participant takes at max BUDGET_SHARE of their max health per second, measured over WINDOW (~30 s of non-stop
-- attack before you die). The swarm still surrounds you; the director only decides how many units may come at you.
--   Attacker slots (OR-D20, PT2): you kill most attackers before they bite, so slots aren't fixed. The floor is what's
--   left of the budget after damage from other sources (the brain, worms) / damage per biter; damage per biter is
--   learned from what units deal you (unit damage / units biting, smoothed), starting at PER_BITER (a small biter vs
--   heavy armor). Slots grow by GROW per check while you take < CALM of the budget and are cut in proportion
--   (slots × budget / measured, not below the floor) when you take more than the budget.
--   Squads (OR-E6, OR-D36; replace OR-E2's holding ring and OR-E5's intercept. PT5: units walked to points planned
--   at spawn around where you had been, which looked random): challenge units within RECRUIT tiles that aren't
--   attacking you join a squad. One squad per role, each with a slot around you, re-placed while you move:
--     pin (between you and the brain), flank_left / flank_right / back, cutoff (where you'll be in CUTOFF_LEAD s, a
--     bit further ahead; behind-left while you stand still), reserve (RESERVE_D tiles from the brain, your side).
--   New units go to the role with the nearest slot that isn't fuller than its share. Members walk to a spot near
--   their slot and wait there, ignoring enemies (OR-I6). States: form → ready (READY_SHARE of the members at the
--   slot, or READY_AFTER) → tell (TELL ticks standing still, a circle on the ground) → charge: up to its share of the
--   free slots (at least CHARGE_FLOOR in total) attack together, nearest first; the rest stay ready. A charge starts
--   when 2+ squads are ready and CHARGE_MIN slots are free (one squad alone: when it's the only one with members, or ready for STALE_READY).
--   Units within STRIKE beyond the slots (too many on you) join the nearest squad. Charging units are left alone for
--   CHARGE_TICKS.
--   Rebuild (OR-D23): nothing of the challenge within NEAR tiles but squads have members → the two biggest charge
--   (at most every REBUILD_GAP).
--   Reactions (OR-D37), each with REACTION_COOLDOWN: guard rush (from surge 1): you hit the brain → the reserve
--   charges (at least REACTION_MIN, even over the slots); stand-still punish (from surge 2): you move < STILL_RADIUS
--   in STILL_TICKS → every squad with members charges.
--   Closing ring (E6-6, OR-D38, surge 2): encircle units (record.ring_units, waves.lua) get points on a full ring of
--   RING_START tiles around where you were when it formed; once the surge is out and the ring has formed, it steps in
--   RING_STEP every RING_EVERY; at RING_CHARGE they charge. Centre fixed (deviation from the spec draft "centred on you
--   each time": a ring that follows you can't be broken out of): get further than radius + BREAK_OUT from the centre
--   and the ring breaks up into squads.
--   Regroup (OR-E7, OR-D49; PT6: kiting worked again): kiting means the brain lost its grip on you. While you move
--   faster than REGROUP_SPEED, units deal you less than REGROUP_HURT of the budget (3 s window; a count of units near
--   you reset it too easily, headless) and REGROUP_CHASERS enemy units are within REGROUP_CHASE (they're chasing you,
--   not still on their way) for REGROUP_AFTER (swarm, no closing ring, not in the frenzy, REGROUP_GAP after the last
--   one), every challenge unit but the shield bearers leaves its squad and joins one of TRAP_GROUPS equal groups that wait
--   TRAP_RADIUS tiles around you (re-placed as you move; units walk round you, not through you), with
--   the directions towards the brain and your heading left open; new units join them too. The brain opens as a lure
--   (brain-fight.lua). When you come within REGROUP_LURE tiles of the brain after at least REGROUP_HOLD (free shots:
--   the bait), or after REGROUP_MAX_TICKS, the trap springs: every group charges you at once from its own side, and
--   squads leave them alone for RESWARM_TICKS.
--   Shield bearers (record.bearers, brain-fight.lua) are never recruited or pulled back.
--   Chokepoint (OR-E9, OR-D61; PT10: a cliff next to the brain, 160 s of biters fed into your guns): the brain sees a
--   choke when (kill zone) ZONE_MIN+ challenge units died within ZONE_RADIUS of you in the last KILL_LOG ticks, at
--   least ZONE_SHARE of them inside one ZONE_ARC arc, (stalemate) you moved less than STALL_MOVE tiles in STALL_TICKS
--   and (calm) units dealt you less than CHOKE_CALM of the budget on average over CHOKE_CALM_TICKS. Then it stops feeding: no
--   squad charges from inside the arc; the reserve waits CHOKE_OUT tiles out on the choke side (out of SMG range).
--   The others go the long way round: slots opposite and beside the choke (CHOKE_ROUND), CHOKE_OUT out too, reached
--   by normal pathfinding. A squad whose walks fail CHOKE_FAILS times and for half its members, or whose charging
--   units mostly die in the arc anyway (CHOKE_LEARN, CHOKE_LEARN_SHARE: the way round leads through the choke), has no
--   way round and waits out of range too. While choked, squads recruit from 3 x RECRUIT tiles. Only squads with a
--   slot outside the arc charge; no rebuild, no stand-still punish through the arc. The choke ends when you move
--   CHOKE_LEAVE tiles from where it started or the kill zone is gone for CHOKE_LOST.
--   no_antikite (/ht-antikite off, headless comparison): slots stay where they were first placed (the stale points),
--   no regroup.
-- Damage is tracked per character entity, so it works headless without players.
-- storage.damage_taken[character unit_number] = {{tick, amount, by_unit, by}, ...}: enemy-force damage in the last
-- WINDOW ticks; by_unit: dealt by a unit (biter / spitter), not the brain or a worm; by: the cause's name, else the
-- damage type (telemetry, OR-D59).
-- record.squads[character unit_number][role] = {role, members = {[unit_number] = entity}, state, since, slot, issued,
-- issued_tick, charged_tick, tell_until, tell_count}; storage.squad_units[unit_number] = {entity, squad} (for
-- on_ai_command_completed); record.charging[unit_number] = until_tick; record.closing = {target, centre, radius,
-- state, since, next_step, members = {[unit_number] = {entity, angle}}, index}; record.regroup = {since, target,
-- units = {[unit_number] = entity}, sizes = {[k] = n}, angles = {[k] = direction}, groups = {[k] = unit group},
-- anchor, moved_tick},
-- record.next_regroup. record.director[character
-- unit_number] = {hp_per_s, budget, touching, biting, other, ring, state, per_biter, floor, allowed, pos, tick, vx, vy,
-- still_anchor, still_since, kite_since, next_guard_rush, next_still, next_rebuild, charged, reaction, hist ({tick, x, y, by_units} every 60 ticks),
-- choke = {dir, anchor, since, lost_since, came_round (charging units reached you outside the arc)}}; record.kill_log = {{tick, x, y}, ...},
-- record.charged_from = {[unit_number] = role}, record.charge_deaths = {[role] = {arc, other}}, record.choke_now (OR-E9); state: "off" (not in a swarm), "calm",
-- "busy", "full".

local waves = require("scripts.waves")
local brain_fight = require("scripts.brain-fight")

local director = {}

local WINDOW = 3 * 60          -- OR-D17: rolling 3 s
local BUDGET_SHARE = 1 / 30    -- OR-D17: max health per second / 30 = 8.3 HP/s at 250 HP
local TOUCH, NEAR = 3, 10      -- touching: < TOUCH tiles; ring: TOUCH..NEAR (telemetry)
local STRIKE = 6               -- units this close count against the slots (OR-D20; was 24 tiles in OR-E2)
local CALM = 0.6               -- slots grow below this share of the budget
local GROW = 2
local MAX_SLOTS = 200
local PER_BITER = 1.2          -- HP/s of one small biter vs heavy armor (0.7 per 35 ticks)
local SMOOTHING = 0.3
local REBUILD, REBUILD_GAP = 20, 4 * 60

local ROLES = {"pin", "flank_left", "flank_right", "cutoff", "back", "reserve"}
local RECRUIT = 40
local PIN_D, FLANK_D, BACK_D, RESERVE_D = 9, 12, 12, 8
local CUTOFF_LEAD, CUTOFF_AHEAD = 4, 6
local MOVING = 1.5             -- tiles/s: slower counts as standing still
local SPREAD = 3               -- members wait within this of their slot
local WAIT = 10 * 60
local REPLACE, REPLACE_TICKS = 4, 60
local READY_SHARE, READY_RADIUS, READY_AFTER = 0.6, 6, 8 * 60
local TELL = 90
local CHARGE_MIN, CHARGE_SQUADS = 4, 3
local CHARGE_FLOOR = 12        -- a charge sends at least this many in total (6 free slots over 3 squads isn't a charge)
local CHARGE_GAP = 3 * 60
local STALE_READY = 6 * 60
local CHARGE_TICKS = 10 * 60
local REACTION_MIN, REACTION_COOLDOWN = 8, 6 * 60
local STILL_RADIUS, STILL_TICKS = 1, 2 * 60
local RING_START, RING_STEP, RING_EVERY, RING_CHARGE = 16, 2, 3 * 60, 6
local RING_FORM_SHARE, RING_FORM_MAX = 0.6, 12 * 60
local BREAK_OUT = 3
local GOLDEN = 0.6180339887
local REGROUP_SPEED, REGROUP_HURT, REGROUP_AFTER = 3, 0.25, 5 * 60
local REGROUP_CHASERS, REGROUP_CHASE = 20, 25 -- the hive is on you (not still on its way) but can't catch you
-- OR-D56 (PT8): all of them pull back (was 90 %). OR-D58 (PT9): not to the brain (they crowded around it, and the
-- trickle spawned right where you went for the bait) but into TRAP_GROUPS groups TRAP_RADIUS tiles around you, the
-- directions towards the brain and your heading left open (within TRAP_OPEN), following you
local TRAP_GROUPS, TRAP_RADIUS, TRAP_SPREAD, TRAP_OPEN = 8, 30, 4, math.rad(40)
local TRAP_ARC = math.rad(60) -- waypoints on the way round, so units don't run straight through you
-- one unit group per direction (one path each); re-sent when you moved TRAP_REPLACE, at most every TRAP_REPLACE_TICKS
-- (per-unit commands every 2 s while you kite kept 600 units re-pathing: they never got anywhere, headless)
local TRAP_REPLACE, TRAP_REPLACE_TICKS = 8, 3 * 60
-- OR-D53 (PT7: every lure was taken at once, you kite near the brain and shoot it): hold REGROUP_HOLD first, then
-- re-swarm within REGROUP_LURE of the brain (was 25, or a hit on the brain)
-- OR-D64 (PT10.2: the lure worked, hold it longer to make it more enticing): hold 6 → 10 s, time out 20 → 25 s
local REGROUP_LURE, REGROUP_MAX_TICKS, REGROUP_GAP, RESWARM_TICKS = 15, 25 * 60, 30 * 60, 15 * 60
local REGROUP_HOLD = 10 * 60
-- OR-E9 chokepoint
local KILL_LOG = 15 * 60
local ZONE_RADIUS, ZONE_MIN, ZONE_SHARE, ZONE_ARC = 20, 20, 0.7, math.rad(60)
local STALL_MOVE, STALL_TICKS = 5, 20 * 60
local CHOKE_CALM, CHOKE_CALM_TICKS = 0.35, 10 * 60 -- units' damage, averaged (a moment over the line reset it, headless)
-- CHOKE_LOST: the kill zone goes away because the brain stopped feeding it, so only a long quiet ends the choke
local CHOKE_LEAVE, CHOKE_LOST, CHOKE_OUT, CHOKE_FAILS = 10, 30 * 60, 22, 5
local CHOKE_LEARN, CHOKE_LEARN_SHARE = 5, 0.6 -- a squad whose charging units die in the arc has no real way round
local CHOKE_ROUND = {pin = 180, flank_left = 120, flank_right = -120, cutoff = 90, back = -90} -- degrees off the choke

function director.on_character_damaged(event)
  if not (event.force and event.force.name == "enemy") then return end
  local id = event.entity.unit_number
  storage.damage_taken = storage.damage_taken or {}
  local list = storage.damage_taken[id] or {}
  storage.damage_taken[id] = list
  local cause = event.cause
  local by = cause and cause.valid and cause.name or (event.damage_type and event.damage_type.name) or "?"
  list[#list + 1] = {game.tick, event.final_damage_amount, cause and cause.valid and cause.type == "unit" or false, by}
end

-- on_entity_died for units (OR-E9): where attacking challenge units die, for the kill zone. Units waiting in squads,
-- the trap or the closing ring don't count: you shoot those over the cliff too, all around (headless: the gap's arc
-- held only 35–55 % of all deaths).
function director.on_unit_died(event)
  local number = event.entity.unit_number
  if storage.squad_units and storage.squad_units[number] then return end
  for _, records in pairs({storage.challenges or {}, storage.debug_waves or {}}) do
    for _, record in pairs(records) do
      if record.spawned and record.spawned[number] then
        if (record.regroup and record.regroup.units[number]) or (record.closing and record.closing.members[number])
          or (record.bearers and record.bearers[number]) then
          return
        end
        local role = record.charged_from and record.charged_from[number]
        if role then
          record.charged_from[number] = nil
          record.charge_deaths = record.charge_deaths or {}
          local t = record.charge_deaths[role] or {arc = 0, other = 0}
          record.charge_deaths[role] = t
          local choke = record.choke_now
          local p = event.entity.position
          -- in the arc near you: the way round led through it; outside it within STRIKE: they reached you another way
          -- (further out you just shot them over the cliff on their way round)
          local d2 = choke and (p.x - choke.x) ^ 2 + (p.y - choke.y) ^ 2
          if d2 and d2 < ZONE_RADIUS * ZONE_RADIUS then
            if math.abs(((math.atan2(p.y - choke.y, p.x - choke.x) - choke.dir) + math.pi) % (2 * math.pi) - math.pi)
              < ZONE_ARC / 2 then
              t.arc = t.arc + 1
            elseif d2 < STRIKE * STRIKE then
              t.other = t.other + 1
            end
          end
        end
        local log = record.kill_log or {}
        record.kill_log = log
        while log[1] and log[1][1] <= game.tick - KILL_LOG do table.remove(log, 1) end
        local p = event.entity.position
        log[#log + 1] = {game.tick, p.x, p.y}
        return
      end
    end
  end
end

-- Damage per second taken by the character over the last WINDOW ticks: all of it, and the part dealt by units.
function director.hp_per_s(character)
  local list = storage.damage_taken and storage.damage_taken[character.unit_number]
  if not list then return 0, 0 end
  local from, kept, sum, by_units = game.tick - WINDOW, {}, 0, 0
  for _, hit in ipairs(list) do
    if hit[1] > from then
      kept[#kept + 1] = hit
      sum = sum + hit[2]
      if hit[3] then by_units = by_units + hit[2] end
    end
  end
  storage.damage_taken[character.unit_number] = kept
  return sum / (WINDOW / 60), by_units / (WINDOW / 60)
end

local function distance_squared(a, b) return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 end

local function notify(record, message)
  for index in pairs(record.players or {}) do
    local player = game.get_player(index)
    if player and player.connected then player.print(message) end
  end
end

-- Walk to a spot near `to`, then wait there (ticks, default WAIT) ignoring enemies.
local function wait_at(surface, unit, to, spread, ticks)
  local a, r = math.random() * 2 * math.pi, math.random() * spread
  local wanted = {x = to.x + math.cos(a) * r, y = to.y + math.sin(a) * r}
  local spot = surface.find_non_colliding_position(unit.name, wanted, 4, 0.5) or wanted
  unit.commandable.set_command{type = defines.command.compound, structure_type = defines.compound_command.return_last,
    commands = {
      {type = defines.command.go_to_location, destination = spot, radius = 1.5, distraction = defines.distraction.none},
      {type = defines.command.wander, radius = 2, ticks_to_wait = ticks or WAIT, distraction = defines.distraction.none},
    }}
end

local function attack(unit, target)
  unit.commandable.set_command{type = defines.command.attack, target = target, distraction = defines.distraction.by_enemy}
end

-- Slot of each role around p (the target), seen from the brain at o, with the target's velocity v.
local function slots(p, o, vx, vy)
  local dx, dy = o.x - p.x, o.y - p.y
  local length = math.sqrt(dx * dx + dy * dy)
  if length < 0.1 then dx, dy, length = 1, 0, 1 end
  dx, dy = dx / length, dy / length -- towards the brain
  local function at(ux, uy, d) return {x = p.x + ux * d, y = p.y + uy * d} end
  local result = {
    pin = at(dx, dy, PIN_D),
    flank_left = at(-dy, dx, FLANK_D),
    flank_right = at(dy, -dx, FLANK_D),
    back = at(-dx, -dy, BACK_D),
    reserve = {x = o.x - dx * RESERVE_D, y = o.y - dy * RESERVE_D},
  }
  local speed = math.sqrt(vx * vx + vy * vy)
  if speed >= MOVING then
    result.cutoff = {x = p.x + vx * CUTOFF_LEAD + vx / speed * CUTOFF_AHEAD, y = p.y + vy * CUTOFF_LEAD + vy / speed * CUTOFF_AHEAD}
  else
    local c, s = math.cos(math.rad(135)), math.sin(math.rad(135)) -- behind-left
    result.cutoff = at(dx * c - dy * s, dx * s + dy * c, FLANK_D)
  end
  return result
end

local function size(squad) return table_size(squad.members) end

local function join(squad, surface, unit)
  local number = unit.unit_number
  squad.members[number] = unit
  storage.squad_units = storage.squad_units or {}
  storage.squad_units[number] = {entity = unit, squad = squad}
  if storage.flankers then storage.flankers[number] = nil end
  if squad.state ~= "tell" then wait_at(surface, unit, squad.slot, SPREAD) end
end

local function leave(squad, number)
  squad.members[number] = nil
  if storage.squad_units then storage.squad_units[number] = nil end
end

-- A squad member's command ended while it's still in its squad: wait again (failed walk: stand still a bit, the next
-- re-place sends it again; a unit without a command attacks whatever is next to it).
function director.on_ai_command_completed(event)
  local entry = storage.squad_units and storage.squad_units[event.unit_number]
  if not entry then return end
  local unit, squad = entry.entity, entry.squad
  if not (unit.valid and squad.members[event.unit_number]) then
    storage.squad_units[event.unit_number] = nil
    return
  end
  if event.result ~= defines.behavior_result.success then squad.fails = (squad.fails or 0) + 1 end -- OR-E9: no way round
  if event.result ~= defines.behavior_result.success or squad.state == "tell" then
    unit.commandable.set_command{type = defines.command.stop, ticks_to_wait = 2 * 60, distraction = defines.distraction.none}
  else
    unit.commandable.set_command{type = defines.command.wander, radius = 2, ticks_to_wait = WAIT,
      distraction = defines.distraction.none}
  end
end

-- The `count` members nearest the target attack it; the squad goes back to ready.
local function charge(record, squad, target, count)
  local list = {}
  for number, unit in pairs(squad.members) do list[#list + 1] = {number = number, unit = unit} end
  local t = target.position
  table.sort(list, function(a, b) return distance_squared(a.unit.position, t) < distance_squared(b.unit.position, t) end)
  record.charging = record.charging or {}
  local sent = 0
  record.charged_from = record.charged_from or {}
  for i = 1, math.min(count, #list) do
    attack(list[i].unit, target)
    leave(squad, list[i].number)
    record.charging[list[i].number] = game.tick + CHARGE_TICKS
    record.charged_from[list[i].number] = squad.role -- OR-E9: where its charges really end up
    sent = sent + 1
  end
  -- the ones left go back to waiting at the slot
  for _, unit in pairs(squad.members) do wait_at(unit.surface, unit, squad.slot, SPREAD) end
  squad.state, squad.since, squad.charged_tick = "ready", game.tick, game.tick
  local s = brain_fight.stats(record)
  s.charged, s.charges = s.charged + sent, s.charges + 1
  return sent
end

local function tell(squad, surface, count)
  squad.state, squad.tell_until, squad.tell_count = "tell", game.tick + TELL, count
  for _, unit in pairs(squad.members) do
    unit.commandable.set_command{type = defines.command.stop, ticks_to_wait = TELL + 60, distraction = defines.distraction.none}
  end
  rendering.draw_circle{color = {r = 0.8, g = 0.1, b = 0.1, a = 0.35}, radius = 4, width = 4, target = squad.slot,
    surface = surface, time_to_live = TELL, draw_on_ground = true}
end

-- Splits count over the given squads (at least 1 each) and starts their tell.
local function tell_all(record, list, surface, count)
  if #list >= 2 then brain_fight.stats(record).multi_charges = (brain_fight.stats(record).multi_charges or 0) + 1 end
  for i, squad in ipairs(list) do
    tell(squad, surface, math.max(1, math.floor(count / #list + (i <= count % #list and 1 or 0))))
  end
end

local function release_all(record, target)
  for _, squads in pairs(record.squads or {}) do
    for _, squad in pairs(squads) do
      for number, unit in pairs(squad.members) do
        if unit.valid and target and target.valid then attack(unit, target) end
        leave(squad, number)
      end
    end
  end
  record.squads = {}
  if record.closing then
    for _, member in pairs(record.closing.members) do
      if member.entity.valid and target and target.valid then attack(member.entity, target) end
    end
    record.closing = nil
  end
  if record.regroup then
    for _, group in pairs(record.regroup.groups or {}) do
      if group.valid then group.destroy() end
    end
    for _, unit in pairs(record.regroup.units) do
      if unit.valid and target and target.valid then attack(unit, target) end
    end
    record.regroup = nil
  end
end

local function ring_point(closing, member)
  local c = closing.centre
  return {x = c.x + math.cos(member.angle) * closing.radius, y = c.y + math.sin(member.angle) * closing.radius}
end

-- The closing ring of encircle units around target (OR-D38).
local function update_closing(record, surface, target, p)
  if record.ring_units and next(record.ring_units) then
    record.closing = record.closing or {target = target, centre = {x = p.x, y = p.y}, radius = RING_START,
      state = "form", since = game.tick, members = {}, index = 0}
    local closing = record.closing
    for number, unit in pairs(record.ring_units) do
      if unit.valid then
        closing.index = closing.index + 1
        local member = {entity = unit, angle = 2 * math.pi * ((closing.index * GOLDEN) % 1)}
        closing.members[number] = member
        if storage.flankers then storage.flankers[number] = nil end
        wait_at(surface, unit, ring_point(closing, member), 1)
      end
    end
    record.ring_units = {}
  end
  local closing = record.closing
  if not closing then return end
  for number, member in pairs(closing.members) do
    if not member.entity.valid then closing.members[number] = nil end
  end
  if not next(closing.members) then
    record.closing = nil
    return
  end
  -- broke out: the ring turns into squads (they're free units now, recruited next)
  if distance_squared(p, closing.centre) > (closing.radius + BREAK_OUT) ^ 2 then
    record.closing = nil
    notify(record, "You broke out of the ring!")
    return
  end
  if closing.state == "form" then
    local at, n = 0, 0
    for _, member in pairs(closing.members) do
      n = n + 1
      if distance_squared(member.entity.position, ring_point(closing, member)) < 16 then at = at + 1 end
    end
    if (record.swarm_left or 0) == 0 and (at >= n * RING_FORM_SHARE or game.tick - closing.since >= RING_FORM_MAX) then
      closing.state, closing.next_step = "closing", game.tick + RING_EVERY
    end
  elseif game.tick >= closing.next_step then
    closing.radius = closing.radius - RING_STEP
    closing.next_step = game.tick + RING_EVERY
    if closing.radius <= RING_CHARGE then
      record.charging = record.charging or {}
      for number, member in pairs(closing.members) do
        attack(member.entity, target)
        record.charging[number] = game.tick + CHARGE_TICKS
      end
      record.closing = nil
      local s = brain_fight.stats(record)
      s.charges = s.charges + 1
    else
      for _, member in pairs(closing.members) do wait_at(surface, member.entity, ring_point(closing, member), 1) end
    end
  end
end

local function in_ring(record, number) return record.closing and record.closing.members[number] end

-- Units the squads leave alone: the closing ring, the shield bearers, a pulled-back hive.
local function reserved(record, number)
  return in_ring(record, number) or (record.bearers and record.bearers[number])
    or (record.regroup and record.regroup.units[number])
end

-- Spot of trap group k (a direction fixed at the pull-back) around p.
local function trap_spot(regroup, k, p)
  local a = regroup.angles[k]
  return {x = p.x + math.cos(a) * TRAP_RADIUS, y = p.y + math.sin(a) * TRAP_RADIUS}
end

local function angle_off(a, b) return (a - b + math.pi) % (2 * math.pi) - math.pi end

-- Sends trap group k (a unit group: one path for all its members) to its spot around p, along the circle (a waypoint
-- every TRAP_ARC) instead of straight through you, then it waits there ignoring enemies.
local function trap_walk(regroup, surface, k, p)
  local group = regroup.groups[k]
  if not (group and group.valid) then return end
  local g = group.position
  local from, to = math.atan2(g.y - p.y, g.x - p.x), regroup.angles[k]
  local turn = angle_off(to, from)
  local commands = {}
  local steps = math.floor(math.abs(turn) / TRAP_ARC)
  for i = 1, steps do
    local a = from + turn * i / (steps + 1)
    local wanted = {x = p.x + math.cos(a) * TRAP_RADIUS, y = p.y + math.sin(a) * TRAP_RADIUS}
    commands[#commands + 1] = {type = defines.command.go_to_location, radius = 4, distraction = defines.distraction.none,
      destination = surface.find_non_colliding_position("small-biter", wanted, 6, 1) or wanted}
  end
  local spot = trap_spot(regroup, k, p)
  commands[#commands + 1] = {type = defines.command.go_to_location, radius = TRAP_SPREAD,
    distraction = defines.distraction.none, destination = surface.find_non_colliding_position("small-biter", spot, 6, 1) or spot}
  commands[#commands + 1] = {type = defines.command.wander, radius = TRAP_SPREAD, ticks_to_wait = REGROUP_MAX_TICKS + 2 * 60,
    distraction = defines.distraction.none}
  group.set_command{type = defines.command.compound, structure_type = defines.compound_command.return_last,
    commands = commands}
end

-- A unit joins the trap group nearest its own angle around p that isn't fuller than `share`.
local function join_trap(record, regroup, surface, unit, p, share)
  local number = unit.unit_number
  local entry_of = storage.squad_units and storage.squad_units[number]
  if entry_of then leave(entry_of.squad, number) end
  if storage.flankers then storage.flankers[number] = nil end
  if record.charging then record.charging[number] = nil end
  local u = unit.position
  local a = math.atan2(u.y - p.y, u.x - p.x)
  local best, best_d, any, any_d
  for k, angle in pairs(regroup.angles) do
    local d = math.abs(angle_off(a, angle))
    if not any_d or d < any_d then any, any_d = k, d end
    if (regroup.sizes[k] or 0) < share and (not best_d or d < best_d) then best, best_d = k, d end
  end
  local k = best or any
  regroup.units[number] = unit
  regroup.sizes[k] = (regroup.sizes[k] or 0) + 1
  local group = regroup.groups[k]
  if not (group and group.valid) then
    -- the group starts where its first member is; the others gather there, then it walks round you
    group = surface.create_unit_group{position = u, force = unit.force}
    regroup.groups[k] = group
  end
  group.add_member(unit)
end

-- Ends the trap: groups gone, members free (their own commands next).
local function disband(regroup)
  for _, group in pairs(regroup.groups) do
    if group.valid then group.destroy() end
  end
  regroup.groups = {}
end

-- OR-D49, OR-D58: pull back when the target kites, spring the trap when it takes the lure.
local function update_regroup(record, surface, target, entry, p)
  local regroup = record.regroup
  if regroup then
    local o = record.origin
    local held = game.tick - regroup.since
    local near = held >= REGROUP_HOLD and distance_squared(p, o) < REGROUP_LURE * REGROUP_LURE
    if near or held >= REGROUP_MAX_TICKS or record.frenzy then -- OR-D65: the frenzy springs a running trap
      local stats = brain_fight.stats(record)
      local why = near and "reswarm_near" or record.frenzy and "reswarm_frenzy" or "reswarm_time"
      stats[why] = (stats[why] or 0) + 1
      -- the trap: every group charges straight at you at once, from its own side
      disband(regroup)
      record.charging = record.charging or {}
      for number, unit in pairs(regroup.units) do
        if unit.valid then
          attack(unit, target)
          record.charging[number] = game.tick + RESWARM_TICKS
        end
      end
      record.regroup, record.next_regroup = nil, game.tick + REGROUP_GAP
      notify(record, "The hive swarms!")
      return
    end
    -- new units (last stand) join the trap; the groups follow you
    local fresh = {}
    for number, unit in pairs(record.spawned) do
      if unit.valid and unit.type == "unit" and not regroup.units[number] and not reserved(record, number) then
        fresh[#fresh + 1] = unit
      end
    end
    if #fresh > 0 then
      local share = math.ceil((table_size(regroup.units) + #fresh) / table_size(regroup.angles))
      for _, unit in ipairs(fresh) do join_trap(record, regroup, surface, unit, p, share) end
    end
    if game.tick - regroup.moved_tick >= TRAP_REPLACE_TICKS
      and distance_squared(p, regroup.anchor) > TRAP_REPLACE * TRAP_REPLACE then
      regroup.anchor, regroup.moved_tick = {x = p.x, y = p.y}, game.tick
      for k in pairs(regroup.groups) do trap_walk(regroup, surface, k, p) end
    end
    return
  end
  -- OR-D65 (PT10.2): no lure in the frenzy; the brain is open anyway, so a pull-back only gave free shots
  if record.closing or record.frenzy or game.tick < (record.next_regroup or 0) or not entry.kite_since
    or game.tick - entry.kite_since < REGROUP_AFTER then
    return
  end
  -- TRAP_GROUPS directions around you, 0 towards the brain; the ones towards the brain and your heading stay open
  local o = record.origin
  local to_brain = math.atan2(o.y - p.y, o.x - p.x)
  local speed = math.sqrt((entry.vx or 0) ^ 2 + (entry.vy or 0) ^ 2)
  local heading = speed >= MOVING and math.atan2(entry.vy, entry.vx) or nil
  regroup = {since = game.tick, target = target, units = {}, sizes = {}, angles = {}, groups = {},
    anchor = {x = p.x, y = p.y}, moved_tick = game.tick}
  for k = 0, TRAP_GROUPS - 1 do
    local a = to_brain + k * 2 * math.pi / TRAP_GROUPS
    if math.abs(angle_off(a, to_brain)) >= TRAP_OPEN and not (heading and math.abs(angle_off(a, heading)) < TRAP_OPEN) then
      regroup.angles[k] = a
    end
  end
  record.regroup = regroup
  local list = {}
  for number, unit in pairs(record.spawned) do
    if unit.valid and unit.type == "unit" and not (record.bearers and record.bearers[number]) then list[#list + 1] = unit end
  end
  local share = math.ceil(#list / math.max(table_size(regroup.angles), 1))
  for _, unit in ipairs(list) do join_trap(record, regroup, surface, unit, p, share) end
  for k in pairs(regroup.groups) do trap_walk(regroup, surface, k, p) end
  entry.kite_since = nil
  local stats = brain_fight.stats(record)
  stats.regroups = (stats.regroups or 0) + 1
  notify(record, "The hive pulls back...")
end

-- OR-E9: kill zone (the arc most deaths near you fall in) of the last KILL_LOG ticks around p: centre, or nil.
local function kill_zone(record, p)
  local angles = {}
  for _, k in pairs(record.kill_log or {}) do
    if k[1] > game.tick - KILL_LOG and (k[2] - p.x) ^ 2 + (k[3] - p.y) ^ 2 < ZONE_RADIUS * ZONE_RADIUS then
      angles[#angles + 1] = math.atan2(k[3] - p.y, k[2] - p.x)
    end
  end
  local n = #angles
  if n < ZONE_MIN then return nil, n, 0 end
  table.sort(angles)
  local best, best_from = 0, angles[1]
  local j = 1
  for i = 1, n do
    -- angles[i .. j] within ZONE_ARC of angles[i], wrapping round
    if j < i then j = i end
    while j - i + 1 < n do
      local nxt = angles[(j % n) + 1] + (j >= n and 2 * math.pi or 0)
      if nxt - angles[i] > ZONE_ARC then break end
      j = j + 1
    end
    if j - i + 1 > best then best, best_from = j - i + 1, angles[i] end
  end
  if best < n * ZONE_SHARE then return nil, n, best end
  return best_from + ZONE_ARC / 2, n, best
end

-- OR-E9: is a chokepoint held? Sets entry.choke (and the history it needs) from last.
local function update_choke(record, entry, last, p)
  local hist = last and last.hist or {}
  if not hist[#hist] or game.tick - hist[#hist][1] >= 60 then hist[#hist + 1] = {game.tick, p.x, p.y, entry.by_units} end
  while hist[1] and hist[1][1] < game.tick - STALL_TICKS do table.remove(hist, 1) end
  entry.hist = hist
  local zone, zone_n, zone_best = kill_zone(record, p)
  entry.zone_n, entry.zone_best = zone_n, zone_best -- debug (headless)
  local choke = last and last.choke
  if choke then
    if distance_squared(p, choke.anchor) > CHOKE_LEAVE * CHOKE_LEAVE then
      choke = nil
    elseif zone then
      choke.dir, choke.lost_since = zone, nil
    else
      choke.lost_since = choke.lost_since or game.tick
      if game.tick - choke.lost_since >= CHOKE_LOST then choke = nil end
    end
    entry.choke = choke
    record.choke_now = choke and {x = p.x, y = p.y, dir = choke.dir} or nil
    return
  end
  record.choke_now = nil
  if not (zone and hist[1] and game.tick - hist[1][1] >= STALL_TICKS - 60) then return end
  local sum, n = 0, 0
  for _, h in pairs(hist) do
    if h[1] > game.tick - CHOKE_CALM_TICKS then sum, n = sum + h[4], n + 1 end
  end
  entry.calm = n > 0 and sum / n or nil -- debug (headless)
  if not (n > 0 and sum / n < entry.budget * CHOKE_CALM) then return end
  for _, h in pairs(hist) do
    if (h[2] - p.x) ^ 2 + (h[3] - p.y) ^ 2 > STALL_MOVE * STALL_MOVE then return end
  end
  entry.choke = {dir = zone, anchor = {x = p.x, y = p.y}, since = game.tick}
  for _, squad in pairs(record.squads and record.squads[entry.id] or {}) do squad.fails, squad.blocked = 0, false end
  record.charge_deaths = {}
  record.choke_now = {x = p.x, y = p.y, dir = zone}
  local stats = brain_fight.stats(record)
  stats.chokes = (stats.chokes or 0) + 1
  notify(record, "The hive won't walk into your guns.")
end

-- Squads for one target: recruit, re-place, ready, charges, reactions. near = units attacking within STRIKE (sorted).
local function update_squads(record, surface, target, entry, near, no_antikite)
  local id = target.unit_number
  local p = target.position
  record.squads = record.squads or {}
  local squads = record.squads[id]
  local places = slots(p, record.origin, entry.vx or 0, entry.vy or 0)
  local choke = entry.choke
  local function in_arc(pos)
    return choke and math.abs(angle_off(math.atan2(pos.y - p.y, pos.x - p.x), choke.dir)) < ZONE_ARC / 2
  end
  if choke then
    -- OR-E9: the long way round; the reserve and squads with no way round wait out of range on the choke side
    local out = {x = p.x + math.cos(choke.dir) * CHOKE_OUT, y = p.y + math.sin(choke.dir) * CHOKE_OUT}
    for role, offset in pairs(CHOKE_ROUND) do
      local a = choke.dir + math.rad(offset)
      -- out of range: at 12 tiles you'd shoot them over the cliff
      places[role] = {x = p.x + math.cos(a) * CHOKE_OUT, y = p.y + math.sin(a) * CHOKE_OUT}
    end
    places.reserve = out
    for role, squad in pairs(squads or {}) do
      -- half its members failed (one stuck unit isn't "no way round")
      if (squad.fails or 0) >= math.max(CHOKE_FAILS, size(squad) / 2) then squad.blocked = true end
      -- its charges die in the choke anyway: the way round leads through it
      local deaths = record.charge_deaths and record.charge_deaths[role]
      if deaths and deaths.arc >= CHOKE_LEARN and deaths.arc >= (deaths.arc + deaths.other) * CHOKE_LEARN_SHARE then
        squad.blocked = true
      end
      -- they reached you another way
      if deaths and deaths.other >= 3 and not choke.came_round then
        choke.came_round = true
        notify(record, "The hive comes around!")
      end
      if squad.blocked then places[role] = out end
    end
  else
    for _, squad in pairs(squads or {}) do squad.fails, squad.blocked = 0, false end
  end
  -- a squad may charge unless the brain sees a choke and its slot lies in it (or it has no way round)
  local function may_charge(squad) return not choke or not (squad.blocked or in_arc(squad.slot)) end
  if not squads then
    squads = {}
    for _, role in ipairs(ROLES) do
      squads[role] = {role = role, members = {}, state = "form", since = game.tick, slot = places[role],
        issued = places[role], issued_tick = game.tick, charged_tick = 0}
    end
    record.squads[id] = squads
  end
  local total = 0
  for _, squad in pairs(squads) do
    for number, unit in pairs(squad.members) do
      if not unit.valid then leave(squad, number) end
    end
    if size(squad) == 0 and squad.state ~= "form" then squad.state, squad.since = "form", game.tick end
    total = total + size(squad)
  end
  -- re-place (C0): slots follow you
  if not no_antikite then
    for role, squad in pairs(squads) do
      squad.slot = places[role]
      if squad.state ~= "tell" and game.tick - squad.issued_tick >= REPLACE_TICKS
        and distance_squared(squad.slot, squad.issued) > REPLACE * REPLACE then
        squad.issued, squad.issued_tick = squad.slot, game.tick
        for _, unit in pairs(squad.members) do wait_at(surface, unit, squad.slot, SPREAD) end
      end
    end
  end
  -- recruit: too many on you, and free units within RECRUIT
  local free_units = {}
  for i = entry.allowed + 1, #near do free_units[#free_units + 1] = near[i].unit end
  record.charging = record.charging or {}
  -- OR-E9: while choked, every unit (units from far away walked their spawn route straight into the choke)
  for _, unit in pairs(surface.find_entities_filtered{position = p, radius = choke and 3 * RECRUIT or RECRUIT, type = "unit",
    force = "enemy"}) do
    local number = unit.unit_number
    if record.spawned[number] and not (storage.squad_units and storage.squad_units[number]) and not reserved(record, number)
      and not ((record.charging[number] or 0) > game.tick) and distance_squared(unit.position, p) > STRIKE * STRIKE then
      free_units[#free_units + 1] = unit
    end
  end
  if #free_units > 0 then
    local share = math.ceil((total + #free_units) / #ROLES)
    for _, unit in ipairs(free_units) do
      local u = unit.position
      local best, best_d, any, any_d
      for _, squad in pairs(squads) do
        if squad.state ~= "tell" then
          local d = distance_squared(u, squad.slot)
          if not any_d or d < any_d then any, any_d = squad, d end
          if size(squad) < share and (not best_d or d < best_d) then best, best_d = squad, d end
        end
      end
      local squad = best or any
      if squad then join(squad, surface, unit) end
    end
  end
  for number, until_tick in pairs(record.charging) do
    if until_tick <= game.tick then record.charging[number] = nil end
  end
  -- ready
  local ready, with_members, telling = {}, 0, false
  for _, squad in pairs(squads) do
    local n = size(squad)
    if n > 0 then with_members = with_members + 1 end
    if squad.state == "form" and n > 0 then
      local at = 0
      for _, unit in pairs(squad.members) do
        if distance_squared(unit.position, squad.slot) < READY_RADIUS * READY_RADIUS then at = at + 1 end
      end
      if at >= n * READY_SHARE or game.tick - squad.since >= READY_AFTER then squad.state, squad.since = "ready", game.tick end
    end
    if squad.state == "tell" then
      telling = true
      if game.tick >= squad.tell_until then charge(record, squad, target, squad.tell_count) end
    end
  end
  for _, squad in pairs(squads) do
    if squad.state == "ready" and size(squad) > 0 and game.tick - squad.charged_tick >= CHARGE_GAP and may_charge(squad) then
      ready[#ready + 1] = squad
    end
  end
  table.sort(ready, function(a, b) return size(a) > size(b) end)
  local free = entry.allowed - math.min(#near, entry.allowed)
  entry.charged, entry.reaction = 0, nil
  local surge = record.surge or 0
  -- reactions first (OR-D37)
  local reserve = squads.reserve
  if surge >= 1 and record.brain_hit_tick and game.tick - record.brain_hit_tick <= 60 and game.tick >= (entry.next_guard_rush or 0)
    and size(reserve) > 0 and reserve.state ~= "tell" and may_charge(reserve) then
    tell(reserve, surface, math.max(free, REACTION_MIN))
    entry.next_guard_rush, entry.reaction = game.tick + REACTION_COOLDOWN, "guard rush"
    brain_fight.stats(record).guard_rush = brain_fight.stats(record).guard_rush + 1
    return
  end
  if surge >= 2 and game.tick - (entry.still_since or game.tick) >= STILL_TICKS and game.tick >= (entry.next_still or 0) then
    local list = {}
    for _, squad in pairs(squads) do
      if size(squad) > 0 and squad.state ~= "tell" and may_charge(squad) then list[#list + 1] = squad end
    end
    if #list > 0 then
      tell_all(record, list, surface, math.max(free, REACTION_MIN * #list))
      entry.next_still, entry.reaction = game.tick + REACTION_COOLDOWN, "stand still"
      entry.still_since = game.tick
      brain_fight.stats(record).stand_still = brain_fight.stats(record).stand_still + 1
      return
    end
  end
  if telling then return end
  -- rebuild: nothing near you
  if not choke and entry.touching + entry.ring == 0 and total > 0 and game.tick >= (entry.next_rebuild or 0) then
    local list = {}
    for _, squad in pairs(squads) do if size(squad) > 0 then list[#list + 1] = squad end end
    table.sort(list, function(a, b) return size(a) > size(b) end)
    list = {list[1], list[2]} -- the two biggest (or the only one)
    tell_all(record, list, surface, math.max(free, REBUILD))
    entry.next_rebuild = game.tick + REBUILD_GAP
    return
  end
  -- a coordinated charge
  if free >= CHARGE_MIN and #ready > 0 then
    local alone = #ready == 1 and (with_members == 1 or game.tick - ready[1].since >= STALE_READY)
    if #ready >= 2 or alone then
      local list = {}
      for i = 1, math.min(CHARGE_SQUADS, #ready) do list[i] = ready[i] end
      tell_all(record, list, surface, math.max(free, CHARGE_FLOOR))
    end
  end
end

-- targets: array of {player (optional), entity} as in waves.update. off = true measures but doesn't act;
-- no_antikite = true leaves squad slots where they were first placed (headless comparison, /ht-antikite off).
function director.update(record, surface, targets, off, no_antikite)
  if storage.held_units then storage.held_units = nil end -- holding ring before OR-E6
  record.held = nil
  local old = record.director or {}
  record.director = {}
  local phases = waves.PHASES[record.ring]
  local active = not off and phases and phases.director and record.phase == "swarm"
  for _, target in pairs(targets) do
    local character = target.player and target.player.character or target.entity
    if character and character.valid then
      local id = character.unit_number
      local measured, by_units = director.hp_per_s(character)
      local budget = character.max_health * BUDGET_SHARE
      local p = character.position
      -- touching: challenge units < TOUCH that aren't in a squad; other: enemy units < TOUCH that aren't the
      -- challenge's (base defenders), which the director can't hold
      local near, touching, biting, other, ring = {}, 0, 0, 0, 0
      for _, unit in pairs(surface.find_entities_filtered{position = p, radius = NEAR, type = "unit", force = "enemy"}) do
        local number = unit.unit_number
        local d = distance_squared(unit.position, p)
        if record.spawned[number] then
          local waiting = (storage.squad_units and storage.squad_units[number]) or reserved(record, number)
          if d < TOUCH * TOUCH then
            touching = touching + 1
            if not waiting then biting = biting + 1 end
          elseif d < NEAR * NEAR then
            ring = ring + 1
          end
          if not waiting and d < STRIKE * STRIKE then near[#near + 1] = {unit = unit, d = d} end
        elseif d < TOUCH * TOUCH then
          other = other + 1
        end
      end
      local last = old[id]
      local per_biter = last and last.per_biter or PER_BITER
      if biting + other > 0 and by_units > 0 then
        per_biter = math.max(0.3, per_biter + SMOOTHING * (by_units / (biting + other) - per_biter))
      end
      local unit_budget = math.max(budget - (measured - by_units), 0)
      local floor = math.max(1, math.floor(unit_budget / per_biter) - other)
      local allowed = active and last and last.allowed or floor -- slots start at the floor when the swarm does
      if not active then
        allowed = floor
      elseif measured < budget * CALM then
        allowed = math.min(MAX_SLOTS, allowed + GROW)
      elseif measured > budget then
        allowed = math.floor(allowed * budget / measured)
      end
      allowed = math.max(floor, allowed)
      local entry = {hp_per_s = measured, by_units = by_units, budget = budget, touching = touching, biting = biting, other = other,
        ring = ring, state = "off", per_biter = per_biter, floor = floor, allowed = allowed, pos = {x = p.x, y = p.y},
        tick = game.tick, next_guard_rush = last and last.next_guard_rush, next_still = last and last.next_still,
        next_rebuild = last and last.next_rebuild, id = id}
      -- velocity (smoothed) for the cut-off slot and the rocks; standing still for the stand-still punish
      if last and last.pos and game.tick > last.tick then
        local dt = (game.tick - last.tick) / 60
        local vx, vy = (p.x - last.pos.x) / dt, (p.y - last.pos.y) / dt
        entry.vx = (last.vx or vx) + 0.5 * (vx - (last.vx or vx))
        entry.vy = (last.vy or vy) + 0.5 * (vy - (last.vy or vy))
      end
      if last and last.still_anchor and distance_squared(p, last.still_anchor) < STILL_RADIUS * STILL_RADIUS then
        entry.still_anchor, entry.still_since = last.still_anchor, last.still_since
      else
        entry.still_anchor, entry.still_since = {x = p.x, y = p.y}, game.tick
      end
      -- kiting (regroup): fast, and nothing reaches you
      local speed = math.sqrt((entry.vx or 0) ^ 2 + (entry.vy or 0) ^ 2)
      if speed > REGROUP_SPEED and by_units < budget * REGROUP_HURT and active and phases.squads and not no_antikite
        and surface.count_entities_filtered{position = p, radius = REGROUP_CHASE, type = "unit", force = "enemy"}
          >= REGROUP_CHASERS then
        entry.kite_since = last and last.kite_since or game.tick
      end
      if active then
        entry.state = measured > budget and "full" or "busy"
        table.sort(near, function(a, b) return a.d < b.d end)
        if phases.squads then
          update_choke(record, entry, last, p)
          update_regroup(record, surface, target.entity, entry, p)
          update_closing(record, surface, target.entity, p)
          update_squads(record, surface, target.entity, entry, near, no_antikite)
          if measured < budget and entry.allowed > #near then entry.state = "calm" end
        end
      end
      record.director[id] = entry
    end
  end
  if not active and (record.squads and next(record.squads) or record.closing) then
    release_all(record, targets[1] and targets[1].entity)
  end
end

-- Challenge over (won / lost / debug reset): the trap's unit groups go, so the leftovers take their own commands.
function director.disband(record)
  if record.regroup then disband(record.regroup) end
end

-- Units waiting in squads or the closing ring ("held" in telemetry and /ht-challenges).
function director.held_count(record)
  local n = 0
  for _, squads in pairs(record.squads or {}) do
    for _, squad in pairs(squads) do n = n + size(squad) end
  end
  if record.closing then n = n + table_size(record.closing.members) end
  return n
end

-- Headless (OR-E6 E6-9): average distance of squad members from where their role's slot is now (fresh), or nil.
function director.slot_error(record, target)
  local squads = record.squads and record.squads[target.unit_number]
  local entry = record.director and record.director[target.unit_number]
  if not (squads and entry and record.origin) then return nil end
  local places = slots(target.position, record.origin, entry.vx or 0, entry.vy or 0)
  local sum, n = 0, 0
  for role, squad in pairs(squads) do
    for _, unit in pairs(squad.members) do
      if unit.valid then
        sum, n = sum + math.sqrt(distance_squared(unit.position, places[role])), n + 1
      end
    end
  end
  return n > 0 and sum / n or nil
end

-- OR-E9 (telemetry, headless): the choke one target's director entry sees, and how many squads have no way round.
function director.choke(record, id)
  local entry = record.director and record.director[id]
  local blocked = 0
  for _, squad in pairs(record.squads and record.squads[id] or {}) do if squad.blocked then blocked = blocked + 1 end end
  return entry and entry.choke, blocked
end

-- Units per squad state for one target: forming, ready, telling.
function director.squad_counts(record, id)
  local counts = {form = 0, ready = 0, tell = 0}
  for _, squad in pairs(record.squads and record.squads[id] or {}) do counts[squad.state] = counts[squad.state] + size(squad) end
  return counts
end

function director.describe(record)
  local parts = {}
  for id, entry in pairs(record.director or {}) do
    local roles = {}
    for _, role in ipairs(ROLES) do
      local squad = record.squads and record.squads[id] and record.squads[id][role]
      if squad and size(squad) > 0 then roles[#roles + 1] = string.format("%s %d %s", role, size(squad), squad.state) end
    end
    local choke = entry.choke and string.format(", choke at %.0f°", math.deg(entry.choke.dir)) or ""
    local closing = record.closing and string.format(", ring %d at %d tiles (%s)", table_size(record.closing.members),
      record.closing.radius, record.closing.state) or ""
    parts[#parts + 1] = string.format(
      "director %s: %.1f / %.1f HP/s (%.1f from units), slots %d, biting %d (+%d not ours), touching %d, ring %d, held %d [%s]%s%s",
      entry.state, entry.hp_per_s, entry.budget, entry.by_units or 0, entry.allowed or 0, entry.biting or 0, entry.other or 0,
      entry.touching, entry.ring, director.held_count(record), table.concat(roles, ", "), closing .. choke,
      entry.reaction and (", reaction " .. entry.reaction) or "")
  end
  return #parts > 0 and (", " .. table.concat(parts, "; ")) or ""
end

return director
