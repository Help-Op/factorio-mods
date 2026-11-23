-- ring2-challenge-plan.md 4e2c: the brain's strategic layer (war.lua decide, core.lua funds, hive.lua raids).
-- Headless, no players: an immortal, unarmed player-less character of force "player" stands in for the player.
-- Enemy expansion is on every 10 s (as in a real game, it must not take our units).
-- 1. Picks the first ring-2 territory with 4 built districts. Heart A is killed with the character 40 tiles out: war,
--    A falls. A raid at the character comes from the raid fund; the reserve and retake funds stay.
-- 2. Character 120 tiles out from B (inside the prediction range, outside B's zone): the brain moves reserve units
--    into B ahead of it (pre-positioning).
-- 3. Character 55 tiles from B: fight, the whole reserve comes to help.
-- 4. Character home. Six gun turrets (no ammo) 60 tiles out from fallen A (a forward camp, outside the district), C's
--    heart killed: a raid at the turrets sized by their
--    threat, and a retake to a left district; both out at the same time.
-- 5. Hive held, every heart killed: the brain's ring of nests still makes units (brain income, 60 s). Hive free
--    again: a retake within 120 s.
-- Result: script-output/brain-test-result.txt (+ ht-telemetry/*.csv). --benchmark-ticks 42000.
local G = 384
local out = {}
local function save() helpers.write_file("brain-test-result.txt", table.concat(out, "\n")) end
local function p(...) out[#out + 1] = string.format("[%5.0f s] ", game.tick / 60) .. string.format(...) save() end
local function layer(i) return i >= 0 and i or -i - 1 end
local function ring_of(x, y) return math.max(layer(math.floor(x / G)), layer(math.floor(y / G))) end
local T0 = 120
local st = {phase = "init"}

local function debug(name, ...) return remote.call("hostile-territory-debug", name, ...) end
local function centre(d) return {x = d.x + 0.5, y = d.y + 0.5} end
local function dist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end
local function district(slot)
  for _, d in pairs(debug("districts_state")[st.id].list) do if d.slot == slot then return d end end
end
local function heart_of(s, d)
  return s.find_entities_filtered{position = centre(d), radius = 1.5, name = "ht-district-heart"}[1]
end
local function war_of() return (debug("wars") or {})[st.id] end
local function army_of(kind) return st.id and (debug("armies") or {})[st.id .. "/" .. kind] end
local function core_of() return (debug("cores") or {})[st.id] end
local function brain_pos()
  local b = st.territory.valid and st.territory.get_segmented_units()[1]
  return b and b.valid and b.segments[1].position
end

local function count(list)
  local n = 0
  for _, u in pairs(list or {}) do if u.valid then n = n + 1 end end
  return n
end

local function alive(a)
  local n = 0
  for _, u in pairs(a and a.units or {}) do if u.entity.valid then n = n + 1 end end
  return n
end

local function funds()
  local c = core_of()
  local f = c and c.funds or {reserve = 0, raid = 0, retake = 0}
  return f
end

local function core_text()
  local c = core_of()
  if not c then return "no core" end
  local f = c.funds or {}
  local q = {}
  for _, queen in pairs(c.queens) do
    if queen.entity.valid then q[queen.state] = (q[queen.state] or 0) + 1 end
  end
  local qs = {}
  for k, n in pairs(q) do qs[#qs + 1] = n .. " " .. k end
  return string.format("core free %s (reserve %d, raid %d, retake %d), incoming %d, queens {%s}",
    c.g.units and (count(c.g.units) .. " on map") or (c.g.count .. " kept"), f.reserve or -1, f.raid or -1,
    f.retake or -1, count(c.incoming), table.concat(qs, ", "))
end

local function garrisons()
  local parts = {}
  for _, d in pairs(debug("districts_state")[st.id].list) do
    if d.built then
      local g = d.garrison
      local n
      if not g then n = "-"
      elseif g.units then n = count(g.units) .. " on map"
      else n = (g.count or 0) .. " kept" end
      parts[#parts + 1] = string.format("d%d %s%s%s", d.slot, d.fallen and "fallen " or "", n, d.pre and (" pre " .. d.pre) or "")
    end
  end
  return table.concat(parts, ", ")
end

local function home() st.c.teleport(game.surfaces.nauvis.find_non_colliding_position("character", {0, 0}, 20, 1)) end

-- Position r tiles from district d's heart, on the side away from the brain.
local function near_heart(d, r)
  local c = centre(d)
  local b = brain_pos()
  local dx, dy = c.x - b.x, c.y - b.y
  local a0 = math.atan2(dy, dx)
  for _, turn in ipairs({0, 0.4, -0.4, 0.8, -0.8, 1.2, -1.2}) do -- (water in the way: turn around the heart)
    local a = a0 + turn
    local pos = game.surfaces.nauvis.find_non_colliding_position("character", {c.x + math.cos(a) * r, c.y + math.sin(a) * r}, 10, 1)
    if pos then return pos end
  end
end

local function decision()
  local w = war_of()
  return w and w.last_decision or "-"
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  local t = e.tick
  if st.c and st.c.valid then st.c.health = st.c.max_health end
  if t == 2 then s.request_to_generate_chunks({0, 0}, 40) end
  if t >= 2 and t < 100 then s.force_generate_chunk_requests() end
  if t < T0 or t % 30 ~= 0 then return end
  local function after(sec) return t >= st.since + sec * 60 end
  local function go(phase) st.phase, st.since = phase, t end

  -- armies seen (both out at once?)
  local raid, retake = army_of("raid"), army_of("retake")
  if raid and retake and not st.both then
    st.both = true
    p("   raid (%s, %d) and retake (%s, %d) out at the same time", raid.state, alive(raid), retake.state, alive(retake))
  end
  if raid and raid.started_tick ~= st.raid_seen then
    st.raid_seen = raid.started_tick
    p("   raid starts: %d units to %.0f %.0f (d%s); %s", raid.start_size, raid.target.x, raid.target.y,
      tostring(raid.slot), core_text())
    p("   decision: %s", decision())
  end
  if retake and retake.started_tick ~= st.retake_seen then
    st.retake_seen = retake.started_tick
    p("   retake starts: %d units to d%d; %s", retake.start_size, retake.slot, core_text())
  end

  if st.phase == "init" then
    p("seed %d", s.map_gen_settings.seed)
    game.map_settings.enemy_expansion.enabled = true
    game.map_settings.enemy_expansion.min_expansion_cooldown = 10 * 60
    game.map_settings.enemy_expansion.max_expansion_cooldown = 10 * 60
    local by_id = {}
    for _, terr in pairs(s.get_territories()) do by_id[script.register_on_object_destroyed(terr)] = terr end
    -- prefer a territory whose brain base was moved off its point (onto land): PT6's brain income bug (R2-D42)
    local moved = {}
    for _, m in pairs((debug("brain_state") or {}).moved or {}) do if m.id then moved[m.id] = m end end
    local best
    for id, state in pairs(debug("districts_state")) do
      local built = {}
      for _, d in pairs(state.list) do if d.built then built[#built + 1] = d end end
      if ring_of(state.point.x, state.point.y) == 2 and #built >= 4 and (not best or (moved[id] and not best.moved)) then
        best = {id = id, built = built, moved = moved[id] ~= nil}
      end
    end
    if not best then p("no ring-2 territory with 4 built districts") st.phase = "end" return end
    st.id, st.territory = best.id, by_id[best.id]
    st.A, st.B, st.C, st.D = best.built[1], best.built[2], best.built[3], best.built[4]
    local point = debug("districts_state")[st.id].point
    p("territory %d (base moved off its point: %s); A = d%d, B = d%d, C = d%d, D = d%d; brain at %.0f %.0f, %.0f tiles from its point",
      st.id, tostring(best.moved), st.A.slot, st.B.slot, st.C.slot, st.D.slot, brain_pos().x, brain_pos().y,
      dist(brain_pos(), {x = point.x, y = point.y}))
    st.c = s.create_entity{name = "character", position = near_heart(st.A, 40), force = "player"}
    st.c.character_health_bonus = 100000
    heart_of(s, st.A).die("player", st.c)
    p("1. A's heart killed, character 40 tiles out: war %s, A fallen %s; %s", tostring(war_of() ~= nil),
      tostring(district(st.A.slot).fallen), core_text())
    go("raid_you")
    return
  end

  -- 1. a raid at the character in fallen A, out of the raid fund only
  if st.phase == "raid_you" then
    if raid and not st.f_before then
      local f = funds()
      st.f_before = true
      p("   right after the raid left: reserve %d, raid %d, retake %d (raid fund spent, the others kept)", f.reserve, f.raid, f.retake)
    end
    if (st.f_before and after(20)) or after(120) then
      if not st.f_before then p("   no raid at the character in 120 s: FAIL; %s; %s", core_text(), decision()) end
      local w = war_of()
      p("   brain made %d units so far (%d brain nests found, %s); %s", w and w.brain_made or 0, w and #(w.brain_nests or {}) or 0,
        (w and (w.brain_made or 0) > 0) and "ok" or "FAIL", garrisons())
      home()
      st.c.teleport(near_heart(st.B, 120))
      p("2. character %.0f tiles from B (zone 80, prediction 150); B: %s", dist(st.c.position, centre(st.B)), garrisons())
      go("pre")
    end
    return
  end

  -- 2. pre-positioning into B
  if st.phase == "pre" then
    if after(25) then
      local d = district(st.B.slot)
      p("   25 s later: B pre %s (%s); %s; decision: %s", tostring(d.pre), (d.pre or 0) > 0 and "ok" or "FAIL", garrisons(), decision())
      st.reserve_before = funds().reserve
      st.c.teleport(near_heart(st.B, 55))
      p("3. character 55 tiles from B; reserve %d", st.reserve_before)
      go("help")
    end
    return
  end

  if st.phase == "help" then
    if after(5) then
      local w = war_of()
      local f = w and w.fights[st.B.slot]
      p("   fight B %s, sent %d (half of B's garrison + the whole reserve of %d); %s", tostring(f ~= nil), f and f.sent or 0,
        st.reserve_before, core_text())
      home()
      -- 4. turrets at fallen A, C falls
      local a = near_heart(st.A, 60)
      st.camp = a
      local n = 0
      for k = 1, 6 do
        local pos = s.find_non_colliding_position("gun-turret", {a.x + 3 * (k % 3), a.y + 3 * math.floor(k / 3)}, 10, 1)
        if pos and s.create_entity{name = "gun-turret", position = pos, force = "player"} then n = n + 1 end
      end
      local h = heart_of(s, st.C)
      if h then h.die("player", st.c) end
      p("4. character home; %d gun turrets (no ammo) 60 tiles out from fallen A (outside its 40-tile hold), C's heart killed; %s", n, core_text())
      go("turrets")
    end
    return
  end

  if st.phase == "turrets" then
    local d = decision()
    if d ~= st.last_d then st.last_d = d p("   decision: %s", d) end
    if after(240) or (st.both and after(60)) then
      local w = war_of()
      p("   %s; war %s; turrets left %d; %s", st.both and "raid + retake seen together" or "raid + retake never out together",
        tostring(w ~= nil), s.count_entities_filtered{name = "gun-turret", force = "player"}, garrisons())
      if not w then
        heart_of(s, st.A).die("player", st.c)
        p("   war over: A killed again for a new war")
      end
      debug("hive_hold", true)
      for _, d in pairs({st.A, st.B, st.C, st.D}) do
        local h = heart_of(s, d)
        if h then h.die("player", st.c) end
      end
      w = war_of()
      st.brain0 = w and w.brain_made or 0
      p("5. hive held, every heart killed: %s; %s", garrisons(), core_text())
      go("income")
    end
    return
  end

  if st.phase == "income" then
    if after(60) then
      local w = war_of()
      local made = (w and w.brain_made or 0) - st.brain0
      local c = core_of()
      local size = c and ((c.g.units and count(c.g.units) or c.g.count) + count(c.incoming)) or 0
      p("   brain income with every district fallen: %d units in 60 s = %.2f units/s (%s); %s", made, made / 60,
        made > 0 and "ok" or (size >= 350 and "stopped: core full, " .. size .. " of 350" or "FAIL"), core_text())
      debug("hive_hold", false)
      st.retake_seen0 = st.retake_seen
      go("last")
    end
    return
  end

  if st.phase == "last" then
    if st.retake_seen ~= st.retake_seen0 and not st.last_ok then
      st.last_ok = true
      p("   retake with every district fallen after %.0f s: ok", (t - st.since) / 60)
    end
    if (st.last_ok and after(60)) or after(150) then
      if not st.last_ok then p("   no retake in 150 s: FAIL; %s", decision()) end
      p("   end: %s; %s; war %s", garrisons(), core_text(), tostring(war_of() ~= nil))
      st.phase = "end"
    end
    return
  end
end)
