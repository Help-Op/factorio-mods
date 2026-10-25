-- E1-8 / E2 (challenge-feel-plan.md): phased challenges, headless. No players, so waves run through the debug
-- remote "waves_step" against a player-less character. Result: script-output/e1-result.txt
-- One run per entry in RUNS, one after the other: ring 0 (challenge-feel), ring 1 (oil-ring-challenge-plan.md
-- OR-E1) without and with the pressure director (OR-E2). The target wears heavy armor and is healed every check, so
-- the director's damage budget (max health / 30 per s) is the real one. It never shoots back, except in runs with
-- kill = n: then the n nearest enemy units within 15 tiles die every check.
-- Average tick time (LuaProfiler, wall clock) with no challenge and during each swarm → e1-ups.txt (OR-I3).
-- Telemetry CSVs of the runs land in script-output/ht-telemetry/.
local R = "hostile-territory-debug"
local out = {}
local function p(...) out[#out + 1] = string.format(...) end
local function dist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end
local RUNS = {
  {brain = "hf-brain-small"},
  {brain = "hf-brain-ring1", director = false},
  {brain = "hf-brain-ring1"},
  {brain = "hf-brain-ring1", kill = 4}, -- OR-E3: the target "shoots": kills the 4 nearest units per check (~8/s, SMG)
  -- OR-E4: the target kites (circle around the brain, KITE_STEP tiles per check from the swarm on), no killing (with
  -- killing nothing ever got close), with and without the director's anti-kite (follow / rebuild / re-surround)
  {brain = "hf-brain-ring1", kite = true},
  {brain = "hf-brain-ring1", kite = true, antikite = false},
  -- OR-E7: the kiting target takes the lure: once the hive pulls back it walks in towards the brain
  {brain = "hf-brain-ring1", kite = true, lure = true},
  -- OR-E9: the target holds a chokepoint: a ring of rocks around it with a 60° gap towards the brain (choke = 1), and
  -- with a second gap behind it (choke = 2, a way round); it kills the 4 nearest units per check
  {brain = "hf-brain-ring1", kill = 8, choke = 1}, -- 16/s: you held the PT10 cliff at ~13/s + the shotgun
  {brain = "hf-brain-ring1", kill = 8, choke = 2},
}
local KITE_STEP = 3.4 -- 6.75 tiles/s: your speed in the brain's ash cloud (0.25 × 0.45, OR-D27); biters there 4.9
-- OR-E5: the kite circles the brain (as the user does, PT4) at the target's start distance (35 tiles)
local STEP = 30
local BASELINE_AT, START = 60, 400 -- 300 ticks of baseline tick time before the first run
local KILL_NESTS = 20 * STEP -- after ~10 s of siege
local WAKE = 30 * STEP       -- E9: siege → wake (the brain engages)
local SWARM = 50 * STEP      -- brain to 55 %
local PROFILE = SWARM + 30 * STEP -- 300 ticks of tick time, once the swarm is out (ring 1: 750 in ~15 s)
-- OR-E6: longer ring-1 timeline, so the closing ring (surge 2) has time to close before surge 3 (was +28 / +40 / +60)
local CLEAR = SWARM + 80 * STEP -- E6: the player "clears" the swarm (and, OR-E5, all nests), then the last stand
-- OR-E5 surges (ring 1: at 80 / 55 / 30 %): the brain is set to 75 % at SWARM, 50 % at SURGE2, 25 % at SURGE3
local SURGE2, SURGE3 = SWARM + 16 * STEP, SWARM + 64 * STEP
local STOP = SWARM + 100 * STEP
-- OR-E6 / OR-E7 / OR-E8 shield probes (ring 1): 200 physical from the target on the brain while the links (anchors)
-- live, after the target kills the anchors and their bearers (KILL_SURGE), at surge 2 (links broken), in the frenzy
local SHUT_PROBE, KILL_SURGE, OPEN_PROBE, FRENZY_PROBE = SWARM + 6 * STEP, SWARM + 14 * STEP, SWARM + 15 * STEP, SURGE3 + 2 * STEP
local SURGE2_PROBE = SURGE2 + 4 * STEP
local RUN_LENGTH = STOP + 10 * STEP
local t = {}
local anchor_spots = {} -- [brain head "x,y"] = {{name, x, y}, ...}

local function nests(s) return s.find_entities_filtered{position = t.head, radius = 25, type = "unit-spawner", force = "enemy"} end

-- Prints that don't depend on the brain under test (once).
local function setup_common(s)
  local pistol, smg, shotgun = prototypes.item["pistol"], prototypes.item["submachine-gun"], prototypes.item["shotgun"]
  p("damage_modifier: pistol %s, submachine-gun %s, shotgun %s, gun-turret %s", pistol.attack_parameters.damage_modifier,
    smg.attack_parameters.damage_modifier, shotgun.attack_parameters.damage_modifier,
    prototypes.entity["gun-turret"].attack_parameters.damage_modifier)
  for _, size in pairs({"small", "ring1", "medium"}) do
    local b = prototypes.entity["hf-brain-" .. size]
    p("hf-brain-%s: max_health %s, healing_per_tick %s, revenge attack (fissures) %s", size, b.get_max_health(),
      b.healing_per_tick, b.revenge_attack_parameters and "yes" or "none")
  end
  -- 15 physical (one yellow bullet ×3) on a small biter and a spawner, in the safe area
  local biter = s.create_entity{name = "small-biter", position = s.find_non_colliding_position("small-biter", {20, 20}, 20, 1), force = "enemy"}
  biter.damage(15, "player", "physical")
  p("small biter after 15 physical: %s", biter.valid and ("alive, " .. biter.health) or "dead")
  local nest = s.create_entity{name = "biter-spawner", position = s.find_non_colliding_position("biter-spawner", {-40, -40}, 30, 1), force = "enemy"}
  nest.damage(15, "player", "physical")
  p("biter spawner after 15 physical: lost %.2f of %d", nest.max_health - nest.health, nest.max_health)
  nest.destroy()
  -- starting resources vs the safe area
  local inside, outside = {}, {}
  for _, r in pairs(s.find_entities_filtered{type = "resource", position = {0, 0}, radius = 700}) do
    local list = dist(r.position, {x = 0, y = 0}) < 150 and inside or outside
    list[r.name] = (list[r.name] or 0) + 1
  end
  local function fmt(l) local x = {} for k, v in pairs(l) do x[#x + 1] = k .. " " .. v end table.sort(x) return table.concat(x, ", ") end
  p("resource tiles < 150: %s", fmt(inside))
  p("resource tiles 150–700: %s", fmt(outside))
  local nearest_chunk
  for _, terr in pairs(s.get_territories()) do
    for _, c in pairs(terr.get_chunks()) do
      local d = dist({x = c.x * 32 + 16, y = c.y * 32 + 16}, {x = 0, y = 0})
      if not nearest_chunk or d < nearest_chunk then nearest_chunk = d end
    end
  end
  p("nearest territory chunk centre: %.0f tiles from spawn", nearest_chunk or -1)
  -- first territory tile per 15° (E2: should be ~150 everywhere)
  local owner, line, all = {}, {}, {}
  for _, terr in pairs(s.get_territories()) do for _, c in pairs(terr.get_chunks()) do owner[c.x .. "," .. c.y] = true end end
  for a = 0, 345, 15 do
    local found
    for d = 0, 800, 4 do
      local x, y = d * math.cos(math.rad(a)), d * math.sin(math.rad(a))
      if owner[math.floor(x / 32) .. "," .. math.floor(y / 32)] then found = d break end
    end
    line[#line + 1] = a .. ":" .. (found or "-")
    if found then all[#all + 1] = found end
  end
  table.sort(all)
  p("first territory tile per 15° (deg:tiles): %s", table.concat(line, " "))
  p("  min %d, median %d, max %d", all[1], all[math.ceil(#all / 2)], all[#all])
  local brains = {}
  for _, u in pairs(s.get_segmented_units()) do brains[#brains + 1] = math.floor(dist(u.segments[1].position, {x = 0, y = 0})) end
  table.sort(brains)
  p("brain distances from spawn (nearest 8): %s", table.concat(brains, " ", 1, math.min(8, #brains)))
end

-- Picks the nearest brain of the given prototype and puts a target character next to it.
local function setup_run(s, brain_name)
  local best
  for _, u in pairs(s.get_segmented_units()) do
    local h = u.segments[1] and u.segments[1].position
    if h and u.prototype.name == brain_name and (not best or dist(h, {x = 0, y = 0}) < best.d) then
      best = {u = u, h = h, d = dist(h, {x = 0, y = 0})}
    end
  end
  if not best then p("no %s found", brain_name) return false end
  t = {}
  t.unit, t.head = best.u, best.h
  p("== run %s", brain_name)
  p("nearest brain: %s at (%.1f, %.1f), %.0f tiles from spawn, health %d / %d", best.u.prototype.name, best.h.x, best.h.y,
    best.d, best.u.health, best.u.max_health)
  t.nests0 = #nests(s)
  p("nests within 25 of the brain: %d", t.nests0)
  -- OR-E8 E8-A2: runs reuse brains, so put back the anchors an earlier run killed (spots from the first run)
  local key = string.format("%.1f,%.1f", t.head.x, t.head.y)
  if not anchor_spots[key] then
    anchor_spots[key] = {}
    for _, a in pairs(s.find_entities_filtered{position = t.head, radius = 36, type = "unit-spawner", force = "enemy"}) do
      if dist(a.position, t.head) >= 29 then table.insert(anchor_spots[key], {name = a.name, x = a.position.x, y = a.position.y}) end
    end
  end
  local rebuilt = 0
  for _, a in pairs(anchor_spots[key]) do
    if s.count_entities_filtered{position = {a.x, a.y}, radius = 0.5, type = "unit-spawner"} == 0 then
      s.create_entity{name = a.name, position = {a.x, a.y}, force = "enemy"}
      rebuilt = rebuilt + 1
    end
  end
  p("anchors: %d (%d put back)", #anchor_spots[key], rebuilt)
  local pos = s.find_non_colliding_position("character", {t.head.x + 35, t.head.y}, 20, 1)
  t.target = s.create_entity{name = "character", position = pos, force = "player"}
  t.target.get_inventory(defines.inventory.character_armor).insert{name = "heavy-armor"}
  best.u.health = best.u.max_health -- a previous run on the same brain left it at 55 %
  p("target character at (%.1f, %.1f), %.0f tiles from the brain", pos.x, pos.y, dist(pos, t.head))
  t.seen = {}
  return true
end

-- E4 surround: sector (0..7, 45° each, 0 = the target's back seen from the brain) of a position around the target
local function sector(pos)
  local tp = t.target.position
  local back = math.atan2(tp.y - t.head.y, tp.x - t.head.x)
  local a = (math.atan2(pos.y - tp.y, pos.x - tp.x) - back) % (2 * math.pi)
  return math.floor((a + math.pi / 8) / (math.pi / 4)) % 8
end

local function step(s)
  t.target.health = t.target.max_health
  if t.kite and game.tick > t.start + SWARM then
    local c = t.head
    t.kite_radius = t.kite_radius or dist(t.target.position, c)
    if t.lure and t.regroup_on then t.kite_radius = math.max(10, t.kite_radius - 1.5) end -- walks in (lure: 15 tiles)
    t.kite_angle = (t.kite_angle or math.atan2(t.target.position.y - c.y, t.target.position.x - c.x)) + KITE_STEP / t.kite_radius
    local before = t.target.position
    t.target.teleport({c.x + math.cos(t.kite_angle) * t.kite_radius, c.y + math.sin(t.kite_angle) * t.kite_radius})
    -- where the swarm is: units 8–25 tiles away, ahead of (or beside) the heading vs behind
    local tp = t.target.position
    local hx, hy = tp.x - before.x, tp.y - before.y
    local front, all = 0, 0
    for _, u in pairs(s.find_entities_filtered{position = tp, radius = 25, type = "unit", force = "enemy"}) do
      local dx, dy = u.position.x - tp.x, u.position.y - tp.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d >= 8 then
        all = all + 1
        if dx * hx + dy * hy > -0.3 * d * math.sqrt(hx * hx + hy * hy) then front = front + 1 end
      end
    end
    if all > 0 and game.tick <= t.start + CLEAR then
      t.front_sum, t.front_n = (t.front_sum or 0) + front / all, (t.front_n or 0) + 1
    end
  end
  if t.kill and game.tick > t.start + WAKE then
    local list = s.find_entities_filtered{position = t.target.position, radius = 15, type = "unit", force = "enemy"}
    local tp = t.target.position
    table.sort(list, function(a, b) return dist(a.position, tp) < dist(b.position, tp) end)
    for i = 1, math.min(t.kill, #list) do list[i].die("player", t.target) end
    t.killed = (t.killed or 0) + math.min(t.kill, #list)
  end
  local res = remote.call(R, "waves_step", t.head.x, t.head.y, t.target,
    {phase = "siege", wake = game.tick == t.start + WAKE, reset = t.reset, director = t.director, debug = true,
      antikite = t.antikite})
  if game.tick == t.start + WAKE then p("-- brain engages: siege → wake") end
  if t.log_phase and res then
    t.log_phase = false
    p("-- phase right after the nests died: %s (OR-D55: ring 1 wakes, ring 0 stays in siege)", tostring(res.phase))
  end
  if not res then p("waves_step returned nil") return end
  t.reset = false
  if res.pulse and not t.pulse_logged then -- OR-E5 frenzy: script-played shockwave stages near the brain
    t.pulse_logged = true
    p("-- frenzy pulse running (surge %s): %d shockwave stage smokes within 60 tiles of the brain", tostring(res.surge),
      s.count_entities_filtered{position = t.head, radius = 60, type = "smoke-with-trigger"})
  end
  -- OR-E2: damage per second the target takes during the swarm, against the director's budget
  local d = res.director and select(2, next(res.director))
  if d and game.tick > t.start + SWARM and game.tick <= t.start + CLEAR then
    t.dps_sum, t.dps_n = (t.dps_sum or 0) + d.hp_per_s, (t.dps_n or 0) + 1
    t.dps_max = math.max(t.dps_max or 0, d.hp_per_s)
    if d.hp_per_s > d.budget then t.over_checks = (t.over_checks or 0) + 1 end
    t.held_max = math.max(t.held_max or 0, res.held or 0)
    t.slots_max = math.max(t.slots_max or 0, d.allowed or 0)
    t.budget = d.budget
  end
  -- OR-E6: squads, shield, closing ring, rocks (ring 1)
  if res.stats then
    local tp = t.target.position
    if res.slot_error and game.tick > t.start + SWARM and game.tick <= t.start + CLEAR then
      t.err_sum, t.err_n = (t.err_sum or 0) + res.slot_error, (t.err_n or 0) + 1
    end
    local cover, walls, min_d = 0, {}, math.huge
    for _, r in pairs(res.rocks or {}) do
      local d = dist(r, tp)
      min_d = math.min(min_d, d)
      if d < 12 then cover = cover + 2 * math.atan(1.5 / math.max(d, 1.5)) end
      walls[r.wall] = true
    end
    if #(res.rocks or {}) > 0 then
      t.rock_min = math.min(t.rock_min or math.huge, min_d)
      t.rock_cover = math.max(t.rock_cover or 0, cover)
      t.rock_walls = math.max(t.rock_walls or 0, table_size(walls))
      t.rock_seen = math.max(t.rock_seen or 0, #res.rocks)
    end
    if res.closing then
      t.ring_min = math.min(t.ring_min or math.huge, res.closing.radius)
      if res.closing.state == "closing" and not t.ring_close_logged then
        t.ring_close_logged = true
        p("t=%5.1fs closing ring starts closing: %d units at %d tiles", (game.tick - t.start) / 60, res.closing.n, res.closing.radius)
      end
    end
    t.last_stats = res.stats
    -- OR-E9: when the brain sees the choke; kills per second before / after; units that reach the target from behind
    if res.choke and not t.choke_at then
      t.choke_at = game.tick
      p("t=%5.1fs choke seen at %.0f° (the brain is at %.0f°)", (game.tick - t.start) / 60, math.deg(res.choke.dir),
        math.deg(math.atan2(t.head.y - t.target.position.y, t.head.x - t.target.position.x)))
    end
    if t.choke_run and (game.tick - t.start) % (5 * 60) == 0 and game.tick > t.start + SWARM then
      local d = res.director and select(2, next(res.director))
      if d then
        p("  choke debug t=%5.1fs: attackers died within 20 tiles in 15 s %d, best 60° arc %d; units %.1f HP/s, 10 s average %s (calm < %.1f)",
          (game.tick - t.start) / 60, d.zone_n or 0, d.zone_best or 0, d.by_units or 0,
          d.calm and string.format("%.1f", d.calm) or "-", d.budget * 0.35)
      end
    end
    if t.choke_run then
      local now = game.tick
      t.kill_hist = t.kill_hist or {}
      t.kill_hist[now] = t.killed or 0
      if t.choke_at and now == t.choke_at + 20 * 60 then
        local before = (t.kill_hist[t.choke_at] or 0) - (t.kill_hist[t.choke_at - 10 * 60] or 0)
        local after = (t.kill_hist[now] or 0) - (t.kill_hist[now - 10 * 60] or 0)
        p("  choke: kills in the 10 s before it was seen %d, in the 10 s from +10 s to +20 s %d; squads with no way round %d; came round: %s",
          before, after, res.blocked or 0, tostring(res.choke and res.choke.came_round or false))
      end
      if t.choke_at then
        t.choke_blocked = res.blocked
        t.came_round = t.came_round or (res.choke and res.choke.came_round)
        local tp = t.target.position
        local to_brain = math.atan2(t.head.y - tp.y, t.head.x - tp.x)
        for _, pos in pairs(res.spawned) do
          if dist(pos, tp) < 6.5 and math.abs((math.atan2(pos.y - tp.y, pos.x - tp.x) - to_brain + math.pi) % (2 * math.pi) - math.pi) > math.rad(90) then
            t.from_behind = (t.from_behind or 0) + 1
          end
        end
      end
    end
    -- OR-E7: bearers, regroup, arena
    t.bearers_max = math.max(t.bearers_max or 0, res.bearers or 0)
    if res.regroup and not t.regroup_on then
      local alive = 0
      for _ in pairs(res.spawned) do alive = alive + 1 end
      p("t=%5.1fs regroup: %d of %d units pulled back (%.0f %%), %d bearers stay", (game.tick - t.start) / 60, res.regroup,
        alive, 100 * res.regroup / math.max(alive, 1), res.bearers or 0)
    elseif t.regroup_on and not res.regroup then
      p("t=%5.1fs re-swarm (target %.0f tiles from the brain)", (game.tick - t.start) / 60, dist(t.target.position, t.head))
    end
    if res.regroup and not t.regroup_on then t.regroup_since = game.tick end
    -- OR-D58: into a pull-back (the bait time): units 12–40 tiles from the target per 45° sector (0 = towards the brain);
    -- OR-E13: at 3, 6 and 9 s, with their average distance (the ring should spread and tighten 30 → 20)
    local into = t.regroup_since and (game.tick - t.regroup_since) / 60
    if res.regroup and into and (into == 3 or into == 6 or into == 9) then
      local tp = t.target.position
      local to_brain = math.atan2(t.head.y - tp.y, t.head.x - tp.x)
      local counts, ring_n, d_sum = {}, 0, 0
      for _, pos in pairs(res.spawned) do
        local d = dist(pos, tp)
        if d >= 12 and d <= 40 then
          ring_n, d_sum = ring_n + 1, d_sum + d
          local a = (math.atan2(pos.y - tp.y, pos.x - tp.x) - to_brain) % (2 * math.pi)
          local k = math.floor((a + math.pi / 8) / (math.pi / 4)) % 8
          counts[k] = (counts[k] or 0) + 1
        end
      end
      local l, held = {}, 0
      for k = 0, 7 do
        l[#l + 1] = tostring(counts[k] or 0)
        if (counts[k] or 0) >= 5 then held = held + 1 end
      end
      p("  trap +%d s: %d of %d units 12–40 tiles from the target, avg %.1f tiles; per sector (0 towards the brain): %s; sectors with 5+: %d",
        into, ring_n, res.regroup, ring_n > 0 and d_sum / ring_n or 0, table.concat(l, " "), held)
    end
    t.regroup_on = res.regroup ~= nil
    t.rocks_now = res.rocks
    local arena = {}
    for _, r in pairs(res.rocks or {}) do if r.arena then arena[#arena + 1] = r end end
    if #arena > 0 and not t.arena_logged then
      t.arena_logged = true
      -- gaps in the ring: angles around the arena's centre (the mean of its rocks)
      local cx, cy = 0, 0
      for _, r in pairs(arena) do cx, cy = cx + r.x / #arena, cy + r.y / #arena end
      local angles, radius = {}, 0
      for _, r in pairs(arena) do
        angles[#angles + 1] = math.atan2(r.y - cy, r.x - cx)
        radius = radius + dist(r, {x = cx, y = cy}) / #arena
      end
      table.sort(angles)
      local gaps = {}
      for i = 1, #angles do
        local next_angle = angles[i + 1] or angles[1] + 2 * math.pi
        local free = (next_angle - angles[i]) * radius - 3 -- minus one rock width (two half widths)
        if free > 1 then gaps[#gaps + 1] = string.format("%.1f", free) end
      end
      p("t=%5.1fs arena: %d rocks on a ring of %.1f tiles around (%.0f, %.0f) (target %.1f tiles from its centre); free gaps > 1 tile (tiles): %s",
        (game.tick - t.start) / 60, #arena, radius, cx, cy, dist(t.target.position, {x = cx, y = cy}), table.concat(gaps, " "))
    end
    if game.tick > t.start + SWARM and (game.tick - t.start) % 60 == 0 then
      p("  E6 t=%5.1fs shield %s, bearers %d%s | squads form %d ready %d tell %d | ring %s | charges %d (%d units, %d multi), guard rush %d, stand still %d, openings %d, rocks %d (%d up) | slot error %.1f",
        (game.tick - t.start) / 60, tostring(res.shield), res.bearers or 0, res.regroup and (", pulled back " .. res.regroup) or "",
        res.squads.form, res.squads.ready, res.squads.tell,
        res.closing and string.format("%d at %d %s", res.closing.n, res.closing.radius, res.closing.state) or "-",
        res.stats.charges, res.stats.charged, res.stats.multi_charges or 0, res.stats.guard_rush, res.stats.stand_still,
        res.stats.openings, res.stats.rocks, #(res.rocks or {}), res.slot_error or -1)
    end
  end
  local new, near_nest, far_from_target = 0, 0, 0
  local live = nests(s)
  for number, pos in pairs(res.spawned) do
    if not t.seen[number] then
      t.seen[number] = true
      new = new + 1
      local d = math.huge
      for _, n in pairs(live) do d = math.min(d, dist(pos, n.position)) end
      if #live == 0 then d = dist(pos, t.head) end
      if d <= 12 then near_nest = near_nest + 1 end
      if dist(pos, t.target.position) > 20 then far_from_target = far_from_target + 1 end
    end
  end
  if not t.id then t.id = res.id p("territory id %d", res.id) end
  if game.tick > (t.start + SWARM) then
    -- E3: biters slowed by the brain's ash cloud, and the target's own ash sticker
    local slowed, total = 0, 0
    for _, e in pairs(s.find_entities_filtered{position = t.head, radius = 80, name = "small-biter", force = "enemy"}) do
      total = total + 1
      for _, st in pairs(e.stickers or {}) do if st.name == "hf-ash-sticker-ally" then slowed = slowed + 1 break end end
    end
    local target_ash = false
    for _, st in pairs(t.target.stickers or {}) do if st.name == "hf-ash-sticker-enemy" then target_ash = true end end
    t.slow_max = math.max(t.slow_max or 0, slowed)
    t.target_ash = t.target_ash or target_ash
    if slowed > 0 and not t.slow_logged then
      t.slow_logged = true
      p("t=%5.1fs first biters with hf-ash-sticker-ally: %d of %d small biters within 80", (game.tick - t.start) / 60, slowed, total)
    end
    -- swarm units 8–22 tiles from the target, per sector; a sector counts when it holds 2+
    local counts = {}
    for _, pos in pairs(res.spawned) do
      local d = dist(pos, t.target.position)
      if d >= 8 and d <= 22 then local k = sector(pos) counts[k] = (counts[k] or 0) + 1 end
    end
    local covered = 0
    for k = 0, 7 do if (counts[k] or 0) >= 2 then covered = covered + 1 end end
    if (game.tick - (t.start + SWARM)) % 60 == 0 and game.tick - (t.start + SWARM) <= 25 * 60 then
      local l = {}
      for k = 0, 7 do l[#l + 1] = tostring(counts[k] or 0) end
      local near = 0
      for _, pos in pairs(res.spawned) do if dist(pos, t.target.position) < 8 then near = near + 1 end end
      -- E7: units in the line of fire: 3–14 tiles from the brain towards the target, at most 7 tiles sideways
      local tp = t.target.position
      local ux, uy = tp.x - t.head.x, tp.y - t.head.y
      local ul = math.max(math.sqrt(ux * ux + uy * uy), 1)
      ux, uy = ux / ul, uy / ul
      local front = 0
      for _, pos in pairs(res.spawned) do
        local rx, ry = pos.x - t.head.x, pos.y - t.head.y
        local along, across = rx * ux + ry * uy, math.abs(-rx * uy + ry * ux)
        if along >= 3 and along <= 14 and across <= 7 then front = front + 1 end
      end
      p("  swarm +%2ds: per sector 8–22 tiles (0 back … 4 front … 7): %s | within 8 tiles: %d | in front of the brain: %d",
        (game.tick - (t.start + SWARM)) / 60, table.concat(l, " "), near, front)
    end
    if covered > (t.ring_best or -1) then
      t.ring_best = covered
      local l = {}
      for k = 0, 7 do l[#l + 1] = tostring(counts[k] or 0) end
      t.ring_line = string.format("t=%.1fs sectors back→ (0 back, 2/6 sides, 4 front): %s", (game.tick - t.start) / 60, table.concat(l, " "))
    end
  end
  if new > 0 or game.tick % (10 * STEP) == t.start % (10 * STEP) then
    p("t=%5.1fs ring %d: +%d new (%d within 12 of a nest/brain, %d more than 20 from the target)%s", (game.tick - t.start) / 60,
      res.ring, new, near_nest, far_from_target, res.text)
  end
end


local function write() helpers.write_file("e1-result.txt", table.concat(out, "\n")) end

-- Average tick time over the ticks since start_profile, appended to e1-ups.txt.
local profiler, profile_ticks, profile_label
local function start_profile(label, ticks)
  profiler, profile_ticks, profile_label = helpers.create_profiler(), ticks, label
end
local function stop_profile(s)
  profiler.stop()
  profiler.divide(profile_ticks)
  local alive = s.count_entities_filtered{force = "enemy", type = "unit"}
  helpers.write_file("e1-ups.txt", {"", profile_label, ", enemy units alive ", tostring(alive), ": ", profiler, " per tick\n"}, true)
  profiler = nil
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if profiler and e.tick == profile_ticks + t.profile_from then stop_profile(s) end
  if e.tick == 2 then
    s.request_to_generate_chunks({0, 0}, 25)
    s.force_generate_chunk_requests()
    return
  elseif e.tick == 10 then
    helpers.write_file("e1-ups.txt", "")
    setup_common(s)
    write()
    return
  elseif e.tick == BASELINE_AT then
    t.profile_from = e.tick
    start_profile("baseline (no challenge)", 300)
    return
  end
  local run = math.floor((e.tick - START) / RUN_LENGTH) + 1
  local offset = (e.tick - START) % RUN_LENGTH
  if e.tick < START or not RUNS[run] or offset % STEP ~= 0 then return end
  if offset == 0 then
    if not setup_run(s, RUNS[run].brain) then write() return end
    t.start, t.reset, t.director, t.kill, t.kite, t.antikite = e.tick, true, RUNS[run].director, RUNS[run].kill,
      RUNS[run].kite, RUNS[run].antikite
    t.lure = RUNS[run].lure
    t.choke_run = RUNS[run].choke
    if t.choke_run then
      -- rocks every 2 tiles on a ring of 7 around the target (overlapping: create_entity doesn't check collisions)
      local tp = t.target.position
      local to_brain = math.atan2(t.head.y - tp.y, t.head.x - tp.x)
      t.wall_rocks = {}
      for i = 0, 21 do
        local a = i * 2 * math.pi / 22
        local open = math.abs((a - to_brain + math.pi) % (2 * math.pi) - math.pi) < math.rad(30)
          or (t.choke_run == 2 and math.abs((a - to_brain) % (2 * math.pi) - math.pi) < math.rad(30))
        if not open then
          t.wall_rocks[#t.wall_rocks + 1] = s.create_entity{name = "huge-rock", position = {tp.x + math.cos(a) * 7, tp.y + math.sin(a) * 7}}
        end
      end
      p("  (choke: %d rocks around the target, gap towards the brain%s)", #t.wall_rocks, t.choke_run == 2 and " and one behind" or "")
    end
    p("director: %s%s%s%s", RUNS[run].director == false and "off (measures only)" or "on",
      RUNS[run].kill and (", target kills " .. RUNS[run].kill .. " per check") or "",
      RUNS[run].kite and ", target kites" or "", RUNS[run].antikite == false and ", anti-kite off" or "")
    if RUNS[run].lure then p("  (takes the lure: walks in towards the brain while the hive is pulled back)") end
  end
  if not t.unit or offset > STOP then return end
  if offset == KILL_NESTS then
    local list, killed = nests(s), 0
    -- OR-E10: ring 1 kills every inner nest (PT13.2: you clear them before surge 1, the wake starved); ring 0 half
    local n = RUNS[run].brain == "hf-brain-ring1" and #list or math.floor(#list / 2)
    for i = 1, n do list[i].die() killed = killed + 1 end -- die: OR-D55 wakes the brain (ring 1)
    p("-- destroyed %d of %d nests", killed, #list)
    t.log_phase = killed > 0
  end
  local ring1 = RUNS[run].brain == "hf-brain-ring1"
  if ring1 and (offset == SURGE2 or offset == SURGE3) then
    t.unit.health = t.unit.max_health * (offset == SURGE2 and 0.5 or 0.25)
    p("-- brain set to %d %%", offset == SURGE2 and 50 or 25)
  end
  if offset == SWARM then
    t.unit.health = t.unit.max_health * (ring1 and 0.75 or 0.55) -- E8: below 60 % (ring 0), OR-E5: 80 % (ring 1)
    -- enraged, as in a real challenge: its ash cloud ("shockwave") starts (E3)
    t.unit.set_ai_state{type = defines.segmented_unit_ai_state.enraged_at_target, target = t.target,
      attacked_me = true, last_damage_time = game.tick}
    p("-- brain set to %d %% health (%d), enraged at the target", ring1 and 75 or 55, t.unit.health)
  end
  if offset == PROFILE then
    t.profile_from = e.tick
    start_profile(RUNS[run].brain .. (RUNS[run].director == false and " (director off)" or "") ..
      (RUNS[run].kill and " (target kills)" or "") .. (RUNS[run].kite and " (kites)" or "") ..
      (RUNS[run].antikite == false and " (anti-kite off)" or "") .. " swarm",
      CLEAR - PROFILE)
  end
  if ring1 and offset == KILL_SURGE then
    -- OR-E8 E8-A2: the anchors (29-36 tiles) are the shield links; each releases a bearer when it dies
    local anchors = 0
    for _, a in pairs(s.find_entities_filtered{position = t.head, radius = 36, type = "unit-spawner", force = "enemy"}) do
      if dist(a.position, t.head) >= 29 then a.die("player", t.target) anchors = anchors + 1 end
    end
    p("-- killed %d anchors", anchors)
    local list = s.find_entities_filtered{position = t.head, radius = 60, name = "ht-shield-bearer"}
    local near = {}
    for _, b in pairs(list) do near[#near + 1] = string.format("%.1f", dist(b.position, t.head)) end
    for _, b in pairs(list) do b.die("player", t.target) end
    p("-- killed the anchors' %d shield bearers (tiles from the brain: %s)", #list, table.concat(near, " "))
  end
  if ring1 and (offset == SHUT_PROBE or offset == OPEN_PROBE or offset == FRENZY_PROBE or offset == SURGE2_PROBE) then
    local before = t.unit.health
    t.unit.damage(200, "player", "physical", t.target, t.target)
    p("-- probe: 200 physical on the brain (%s): lost %.1f HP", offset == SHUT_PROBE and "surge 1, links alive" or
      offset == OPEN_PROBE and "after killing them" or offset == SURGE2_PROBE and "surge 2, links broken" or "frenzy",
      before - t.unit.health)
  end
  -- OR-D111: own-force damage (a grenade at your feet) is logged as "own explosion" (telemetry max_hit_by) and kept out
  -- of the director's budget
  if ring1 and offset == SHUT_PROBE then
    t.target.damage(30, "player", "explosion", t.target)
    p("-- probe: 30 own explosion on the target (telemetry max_hit_by should say \"own explosion\")")
  end
  if offset == CLEAR then
    local n = 0
    for _, u in pairs(s.find_entities_filtered{position = t.head, radius = 120, name = "small-biter", force = "enemy"}) do
      u.destroy() n = n + 1
    end
    local killed = 0
    for _, nest in pairs(nests(s)) do nest.destroy() killed = killed + 1 end
    p("-- cleared %d small biters (as if the player killed the swarm) and the last %d nests", n, killed)
  end
  step(s)
  if offset == STOP then
    p("total spawned: %d. Target alive: %s", table_size(t.seen), tostring(t.target.valid))
    p("ash cloud: most biters slowed at once %d; target got hf-ash-sticker-enemy (OR-D27): %s", t.slow_max or 0, tostring(t.target_ash))
    if t.dps_n then
      p("damage taken in the swarm (until the clear): avg %.1f HP/s, max %.1f (rolling 3 s), budget %.1f; over budget in %d of %d checks; most held at once %d; most slots %d; killed by the target %d",
        t.dps_sum / t.dps_n, t.dps_max, t.budget, t.over_checks or 0, t.dps_n, t.held_max or 0, t.slots_max or 0, t.killed or 0)
    end
    if t.front_n then
      p("kite: on average %.0f %% of the units 8–25 tiles away were ahead of or beside the target (not trailing)",
        100 * t.front_sum / t.front_n)
    end
    if t.last_stats then
      local st = t.last_stats
      p("OR-E6: charges %d (%d units, %d with 2+ squads), guard rush %d, stand still %d, openings %d, rocks placed %d",
        st.charges, st.charged, st.multi_charges or 0, st.guard_rush, st.stand_still, st.openings, st.rocks)
      p("OR-E6: squad members' average distance from their role's current slot: %.1f tiles (%d checks)",
        t.err_n and t.err_sum / t.err_n or -1, t.err_n or 0)
      p("OR-E7: most bearers alive at once %d; regroups %d, re-swarm near %d / time %d; arena rocks %d; rocks still standing at the end %d of %d placed",
        t.bearers_max or 0, st.regroups or 0, st.reswarm_near or 0, st.reswarm_time or 0, st.arena or 0,
        #(t.rocks_now or {}), (st.rocks or 0) + (st.arena or 0))
      -- rock safety at placement (brain-fight.lua stats): the test target teleports through rocks that stay, so
      -- distances measured afterwards mean nothing
      p("OR-E6: closing ring smallest radius %s; rocks: most at once %d in %d walls; at placement nearest to the target %.1f tiles, most of the circle covered %.0f°",
        t.ring_min and tostring(t.ring_min) or "-", t.rock_seen or 0, t.rock_walls or 0, st.rock_min or -1,
        math.deg(st.rock_cover or 0))
    end
    if t.ring_best then
      p("surround: most 45° sectors holding 2+ swarm units 8–22 tiles from the target at once: %d of 8", t.ring_best)
      p("  %s", t.ring_line)
    end
    if t.choke_run then
      p("OR-E9: choke seen %s; unit-checks inside the ring from behind (> 90° off the gap towards the brain) after that: %d; squads with no way round at the end %d; came round: %s",
        t.choke_at and string.format("at %.1f s", (t.choke_at - t.start) / 60) or "never", t.from_behind or 0,
        t.choke_blocked or 0, tostring(t.came_round or false))
      for _, r in pairs(t.wall_rocks or {}) do if r.valid then r.destroy() end end
    end
    -- clean up for the next run (OR-E7 rocks stay in the mod: remove this run's, so the next run starts clean)
    for _, r in pairs(t.rocks_now or {}) do
      for _, e in pairs(s.find_entities_filtered{position = {r.x, r.y}, radius = 0.5, name = "huge-rock"}) do e.destroy() end
    end
    for _, u in pairs(s.find_entities_filtered{position = t.head, radius = 150, type = "unit", force = "enemy"}) do u.destroy() end
    if t.target.valid then t.target.destroy() end
    write()
  end
end)
