-- SUPERSEDED by tools/ht-brain-test (4e2c: waves became raids, armies come from funds). Kept for the 4e2b results.
-- ring2-challenge-plan.md 4e2b: hive budget (core garrison), waves, queens and their protection (scripts/core.lua,
-- war.lua, hive.lua). Headless, no players: an immortal, unarmed player-less character of force "player" stands in
-- for the player. Enemy expansion is on every 10 s (as in a real game, it must not take our units).
-- Nothing dies (the character is unarmed), so the growth of all hive units is the income.
-- 1. Picks the first ring-2 territory with 4 built districts. Heart A is killed with the character 40 tiles out from
--    it: war, A falls, its queen is released and walks to the brain, A's garrison goes to the core.
-- 2. The character stands in fallen A: a wave (no queen) comes at it; income over 60 s; the character goes home, the
--    wave finds nothing and goes home to the core.
-- 3. A is left: a retake army with the released queen; A retaken → hive win, garrisons capped at 80.
-- 4. Second war (A killed again), hive held (remote hive_hold: no waves or retakes): queen_now → the reserve fills
--    up to 3.
-- 5. Character 30 tiles from a reserve queen: she flees with 10 escorts; character home → she comes back.
-- 6. Character in district B's zone: fight, the core sends half its free units to help.
-- 7. Hive free again; B, C and D fall, walls at C: with every district fallen a retake still comes.
-- Result: script-output/core-test-result.txt (+ ht-telemetry/*.csv). --benchmark-ticks 42000.
local G = 384
local out = {}
local function save() helpers.write_file("core-test-result.txt", table.concat(out, "\n")) end
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
local function army_of() return (debug("armies") or {})[st.id] end
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

local function core_text()
  local c = core_of()
  if not c then return "no core" end
  local q = {}
  for _, queen in pairs(c.queens) do
    if queen.entity.valid then q[queen.state] = (q[queen.state] or 0) + 1 end
  end
  local qs = {}
  for k, n in pairs(q) do qs[#qs + 1] = n .. " " .. k end
  return string.format("core free %s, incoming %d, arrived %d, queens {%s}",
    c.g.units and (count(c.g.units) .. " on map") or (c.g.count .. " kept"), count(c.incoming), c.made, table.concat(qs, ", "))
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
      parts[#parts + 1] = string.format("d%d %s%s", d.slot, d.fallen and "fallen " or "", n)
    end
  end
  return table.concat(parts, ", ")
end

local function walls(s, d)
  local c = centre(d)
  local n = 0
  for k = 1, 4 do
    local pos = s.find_non_colliding_position("stone-wall", {c.x + 20 + 2 * k, c.y + 6}, 8, 1)
    if pos and s.create_entity{name = "stone-wall", position = pos, force = "player"} then n = n + 1 end
  end
  return n
end

local function home() st.c.teleport(game.surfaces.nauvis.find_non_colliding_position("character", {0, 0}, 20, 1)) end

local function queen_list(state)
  local list = {}
  for _, q in pairs((core_of() or {queens = {}}).queens) do
    if q.entity.valid and (not state or q.state == state) then list[#list + 1] = q end
  end
  return list
end

-- Every hive unit of the territory (garrisons, core, incoming, escorts, army). Nothing dies in this test (the
-- character is unarmed), so its growth is the income.
local function total()
  local n = 0
  for _, d in pairs(debug("districts_state")[st.id].list) do
    local g = d.garrison
    if g then n = n + (g.units and count(g.units) or g.count or 0) end
  end
  local c = core_of()
  if c then
    n = n + (c.g.units and count(c.g.units) or c.g.count) + count(c.incoming)
    for _, q in pairs(c.queens) do n = n + count(q.escorts) end
  end
  local a = army_of()
  if a then for _, u in pairs(a.units) do if u.entity.valid then n = n + 1 end end end
  return n
end

local function near_heart(d, r)
  local c = centre(d)
  local b = brain_pos()
  local dx, dy = c.x - b.x, c.y - b.y
  local l = math.sqrt(dx * dx + dy * dy)
  return game.surfaces.nauvis.find_non_colliding_position("character", {c.x + dx / l * r, c.y + dy / l * r}, 10, 1)
end

local function live_count()
  local n = 0
  for _, d in pairs(debug("districts_state")[st.id].list) do if d.built and not d.fallen then n = n + 1 end end
  return n
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

  if st.phase == "init" then
    p("seed %d", s.map_gen_settings.seed)
    game.map_settings.enemy_expansion.enabled = true
    game.map_settings.enemy_expansion.min_expansion_cooldown = 10 * 60
    game.map_settings.enemy_expansion.max_expansion_cooldown = 10 * 60
    local by_id = {}
    for _, terr in pairs(s.get_territories()) do by_id[script.register_on_object_destroyed(terr)] = terr end
    local best
    for id, state in pairs(debug("districts_state")) do
      local built = {}
      for _, d in pairs(state.list) do if d.built then built[#built + 1] = d end end
      if not best and ring_of(state.point.x, state.point.y) == 2 and #built >= 4 then best = {id = id, built = built} end
    end
    if not best then p("no ring-2 territory with 4 built districts") st.phase = "end" return end
    st.id, st.territory = best.id, by_id[best.id]
    st.A, st.B, st.C, st.D = best.built[1], best.built[2], best.built[3], best.built[4]
    p("territory %d; A = d%d, B = d%d, C = d%d, D = d%d; brain at %.0f %.0f", st.id, st.A.slot, st.B.slot, st.C.slot,
      st.D.slot, brain_pos().x, brain_pos().y)
    st.c = s.create_entity{name = "character", position = near_heart(st.A, 40), force = "player"}
    st.c.character_health_bonus = 100000
    heart_of(s, st.A).die("player", st.c)
    p("1. A's heart killed, character 40 tiles out from it: war %s, A fallen %s; %s", tostring(war_of() ~= nil),
      tostring(district(st.A.slot).fallen), core_text())
    go("wave_wait")
    return
  end

  -- 2. a wave at the character standing in fallen A; income while it's out
  if st.phase == "wave_wait" then
    local a = army_of()
    if a then
      p("2. %s starts %.0f s after: %d units, queen %s, target d%d; %s", a.kind, (t - st.since) / 60, a.start_size,
        tostring(a.queen ~= nil), a.slot, core_text())
      st.total0 = total()
      go("wave_watch")
    elseif after(70) then
      p("2. no wave after 70 s: FAIL; %s", core_text())
      st.phase = "end"
    end
    return
  end

  if st.phase == "wave_watch" then
    local a = army_of()
    if a and a.state ~= st.wave_state then
      st.wave_state = a.state
      local n, sum = 0, 0
      for _, u in pairs(a.units) do
        if u.entity.valid then n, sum = n + 1, sum + dist(u.entity.position, st.c.position) end
      end
      p("   wave %s, %d alive, mean %.0f tiles from the character", a.state, n, n > 0 and sum / n or -1)
    end
    if after(60) and not st.wave_home then
      st.wave_home = true
      local live = live_count()
      p("   income: %d hive units more in 60 s with %d live districts = %.2f units/s (all: %s | %s)", total() - st.total0,
        live, (total() - st.total0) / 60, garrisons(), core_text())
      home()
      p("   character goes home")
    end
    if st.wave_home and not (a and a.kind == "wave") then
      p("   wave gone home: %s", core_text())
      go("retake_wait")
    elseif after(150) then
      p("   wave still out after 150 s: FAIL (%s)", a and a.state or "-")
      go("retake_wait")
    end
    return
  end

  -- 3. A is left: a retake with the released queen → hive win, garrisons capped
  if st.phase == "retake_wait" then
    local a = army_of()
    if a and a.kind == "retake" and a.state ~= st.r_state then
      st.r_state = a.state
      local n = 0
      for _, u in pairs(a.units) do if u.entity.valid then n = n + 1 end end
      p("3. retake %s: %d units, queen %s", a.state, n, a.queen.valid and "alive" or "dead")
    end
    if not war_of() or after(150) then
      p("   war over %s, A fallen %s; garrisons %s", tostring(war_of() == nil), tostring(district(st.A.slot).fallen), garrisons())
      -- 4. second war, the hive held back: queens
      debug("hive_hold", true)
      heart_of(s, st.A).die("player", st.c)
      p("4. second war (hive held: no waves or retakes): A killed again; %s", core_text())
      p("   queen_now: %d hearts", debug("queen_now"))
      go("queens")
    end
    return
  end

  if st.phase == "queens" then
    if after(45) then
      p("   45 s later: %s (reserve up to 3, plus A's released one)", core_text())
      local q = queen_list("home")[1]
      if q then
        local qp, b = q.entity.position, brain_pos()
        local dx, dy = qp.x - b.x, qp.y - b.y
        local l = math.max(math.sqrt(dx * dx + dy * dy), 1)
        st.c.teleport(s.find_non_colliding_position("character", {qp.x + dx / l * 30, qp.y + dy / l * 30}, 10, 1))
        st.queen = q.entity
        p("5. character %.0f tiles from a reserve queen", dist(st.c.position, qp))
        go("flee")
      else
        p("5. no queen at home: FAIL")
        go("help_setup")
      end
    end
    return
  end

  if st.phase == "flee" then
    if after(15) and not st.fled then
      st.fled = true
      local q
      for _, x in pairs(queen_list()) do if x.entity == st.queen then q = x end end
      if q then
        local near = 0
        for _, u in pairs(q.escorts or {}) do
          if u.valid and dist(u.position, q.entity.position) <= 10 then near = near + 1 end
        end
        p("   15 s later: queen %s, %.0f tiles from the character, %.0f from the brain, %d escorts, %d within 10 tiles",
          q.state, dist(q.entity.position, st.c.position), dist(q.entity.position, brain_pos()), count(q.escorts), near)
      else
        p("   queen gone: FAIL")
      end
      home()
      p("   character goes home")
    end
    if after(75) then
      for _, x in pairs(queen_list()) do
        if x.entity == st.queen then
          p("   60 s later: queen %s, %.0f tiles from the brain, %d escorts; %s", x.state, dist(x.entity.position, brain_pos()),
            count(x.escorts), core_text())
        end
      end
      go("help_setup")
    end
    return
  end

  -- 6. help from the core for a fight at B
  if st.phase == "help_setup" then
    local c = core_of()
    st.free_before = c.g.units and count(c.g.units) or c.g.count
    st.c.teleport(near_heart(st.B, 55))
    p("6. character %.0f tiles from B; core free %d", dist(st.c.position, centre(st.B)), st.free_before)
    go("help")
    return
  end

  if st.phase == "help" then
    if after(5) and not st.helped then
      st.helped = true
      local w = war_of()
      local f = w and w.fights[st.B.slot]
      local fights = {}
      for slot in pairs(w and w.fights or {}) do fights[#fights + 1] = slot end
      p("   character %.0f tiles from B's heart, fights {%s}", dist(st.c.position, centre(st.B)), table.concat(fights, " "))
      p("   fight B %s, sent %d (half of B's garrison + half of the core's %d); %s", tostring(f ~= nil), f and f.sent or 0,
        st.free_before, core_text())
    end
    if after(20) then
      home()
      p("7. B, C, D fall (hive still held); walls at C, character home")
      for _, d in pairs({st.B, st.C, st.D}) do
        local h = heart_of(s, d)
        if h then h.die("player", st.c) end
      end
      walls(s, st.C)
      p("   %s; %s", garrisons(), core_text())
      go("pick_wait")
    end
    return
  end

  if st.phase == "pick_wait" then
    if after(40) then
      debug("hive_hold", false)
      p("   40 s later, every district left; hive free again: the pick should be C (your walls: value, no threat)")
      go("last")
    end
    return
  end

  if st.phase == "last" then
    local a = army_of()
    if a and a.kind == "retake" and not st.last_seen then
      st.last_seen = true
      p("   with every district fallen: a retake to d%d (C = d%d), %d units", a.slot, st.C.slot, a.start_size)
    end
    if (st.last_seen and not a) or after(200) then
      p("   end: %s; %s; war %s; live districts %d", garrisons(), core_text(), tostring(war_of() ~= nil), live_count())
      if not st.last_seen then p("   no retake with every district fallen: FAIL") end
      p("%s", remote.call("hostile-territory-debug", "attacks") or "")
      st.phase = "end"
    end
    return
  end
end)

-- engine groups taking units (any unit; a hint only)
script.on_event(defines.events.on_unit_added_to_group, function(e)
  if not (st.id and e.unit and e.unit.valid and e.group.valid) or e.group.is_script_driven then return end
  st.pulled = (st.pulled or 0) + 1
end)
