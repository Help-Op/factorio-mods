-- E1-8 / E2 (challenge-feel-plan.md): first-ring challenge, headless. No players, so waves run through the debug
-- remote "waves_step" against a player-less character. Result: script-output/e1-result.txt
local R = "hostile-territory-debug"
local out = {}
local function p(...) out[#out + 1] = string.format(...) end
local function dist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end
local START, STEP = 30, 30
local KILL_NESTS_AT = START + 20 * STEP -- after ~10 s of siege
local WAKE_AT = START + 30 * STEP       -- E9: siege → wake (the brain engages)
local SWARM_AT = START + 50 * STEP     -- brain to 55 %
local STOP_AT = START + 100 * STEP
local CLEAR_AT = SWARM_AT + 30 * STEP -- E6: the player "clears" the swarm, then the last stand should trickle in
local t = {}

local function nests(s) return s.find_entities_filtered{position = t.head, radius = 25, type = "unit-spawner", force = "enemy"} end

local function setup(s)
  local pistol, smg = prototypes.item["pistol"], prototypes.item["submachine-gun"]
  p("damage_modifier: pistol %s, submachine-gun %s, gun-turret %s", pistol.attack_parameters.damage_modifier,
    smg.attack_parameters.damage_modifier, prototypes.entity["gun-turret"].attack_parameters.damage_modifier)
  for _, size in pairs({"small", "medium"}) do
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
  -- nearest brain
  local best
  for _, u in pairs(s.get_segmented_units()) do
    local h = u.segments[1] and u.segments[1].position
    if h and (not best or dist(h, {x = 0, y = 0}) < best.d) then best = {u = u, h = h, d = dist(h, {x = 0, y = 0})} end
  end
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
  if not best then p("no brain found") return false end
  t.unit, t.head = best.u, best.h
  p("nearest brain: %s at (%.1f, %.1f), %.0f tiles from spawn, health %d / %d", best.u.prototype.name, best.h.x, best.h.y,
    best.d, best.u.health, best.u.max_health)
  t.nests0 = #nests(s)
  p("nests within 25 of the brain: %d", t.nests0)
  local pos = s.find_non_colliding_position("character", {t.head.x + 35, t.head.y}, 20, 1)
  t.target = s.create_entity{name = "character", position = pos, force = "player"}
  t.target.character_health_bonus = 1e7
  t.target.health = t.target.max_health
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
  local res = remote.call(R, "waves_step", t.head.x, t.head.y, t.target,
    {phase = "siege", wake = game.tick == WAKE_AT})
  if game.tick == WAKE_AT then p("-- brain engages: siege → wake") end
  if not res then p("waves_step returned nil") return end
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
  if game.tick > SWARM_AT then
    -- E3: biters slowed by the brain's ash cloud, and the target's own ash sticker
    local slowed, total = 0, 0
    for _, e in pairs(s.find_entities_filtered{position = t.head, radius = 80, name = "small-biter", force = "enemy"}) do
      total = total + 1
      for _, st in pairs(e.stickers or {}) do if st.name == "hf-ash-sticker-ally" then slowed = slowed + 1 break end end
    end
    local target_ash = false
    for _, st in pairs(t.target.stickers or {}) do if st.name == "demolisher-ash-sticker" then target_ash = true end end
    t.slow_max = math.max(t.slow_max or 0, slowed)
    t.target_ash = t.target_ash or target_ash
    if slowed > 0 and not t.slow_logged then
      t.slow_logged = true
      p("t=%5.1fs first biters with hf-ash-sticker-ally: %d of %d small biters within 80", (game.tick - START) / 60, slowed, total)
    end
    -- swarm units 8–22 tiles from the target, per sector; a sector counts when it holds 2+
    local counts = {}
    for _, pos in pairs(res.spawned) do
      local d = dist(pos, t.target.position)
      if d >= 8 and d <= 22 then local k = sector(pos) counts[k] = (counts[k] or 0) + 1 end
    end
    local covered = 0
    for k = 0, 7 do if (counts[k] or 0) >= 2 then covered = covered + 1 end end
    if (game.tick - SWARM_AT) % 60 == 0 and game.tick - SWARM_AT <= 25 * 60 then
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
        (game.tick - SWARM_AT) / 60, table.concat(l, " "), near, front)
    end
    if covered > (t.ring_best or -1) then
      t.ring_best = covered
      local l = {}
      for k = 0, 7 do l[#l + 1] = tostring(counts[k] or 0) end
      t.ring_line = string.format("t=%.1fs sectors back→ (0 back, 2/6 sides, 4 front): %s", (game.tick - START) / 60, table.concat(l, " "))
    end
  end
  if new > 0 or game.tick % (10 * STEP) == START % (10 * STEP) then
    p("t=%5.1fs ring %d: +%d new (%d within 12 of a nest/brain, %d more than 20 from the target)%s", (game.tick - START) / 60,
      res.ring, new, near_nest, far_from_target, res.text)
  end
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 2 then
    s.request_to_generate_chunks({0, 0}, 25)
    s.force_generate_chunk_requests()
  elseif e.tick == 10 then
    if not setup(s) then helpers.write_file("e1-result.txt", table.concat(out, "\n")) end
  elseif t.unit and e.tick >= START and e.tick <= STOP_AT and (e.tick - START) % STEP == 0 then
    if e.tick == KILL_NESTS_AT then
      local list, killed = nests(s), 0
      for i = 1, math.floor(#list / 2) do list[i].destroy() killed = killed + 1 end
      p("-- destroyed %d of %d nests", killed, #list)
    end
    if e.tick == SWARM_AT then
      t.unit.health = t.unit.max_health * 0.55 -- E8: the swarm starts below 60 % (was 50 %)
      -- enraged, as in a real challenge: its ash cloud ("shockwave") starts (E3)
      t.unit.set_ai_state{type = defines.segmented_unit_ai_state.enraged_at_target, target = t.target,
        attacked_me = true, last_damage_time = game.tick}
      p("-- brain set to 55 %% health (%d), enraged at the target", t.unit.health)
    end
    if e.tick == CLEAR_AT then
      local n = 0
      for _, u in pairs(s.find_entities_filtered{position = t.head, radius = 120, name = "small-biter", force = "enemy"}) do
        u.destroy() n = n + 1
      end
      p("-- cleared %d small biters (as if the player killed the swarm)", n)
    end
    step(s)
    if e.tick == STOP_AT then
      p("total spawned: %d. Target alive: %s", table_size(t.seen), tostring(t.target.valid))
      p("ash cloud: most biters slowed at once %d; target got demolisher-ash-sticker: %s", t.slow_max or 0, tostring(t.target_ash))
      if t.ring_best then
        p("surround: most 45° sectors holding 2+ swarm units 8–22 tiles from the target at once: %d of 8", t.ring_best)
        p("  %s", t.ring_line)
      end
      helpers.write_file("e1-result.txt", table.concat(out, "\n"))
    end
  end
end)
