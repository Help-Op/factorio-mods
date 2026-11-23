-- SUPERSEDED by tools/ht-core-test (4e2b, 2026-11-22): armies now come from the core garrison and waves have no queen,
-- so this scenario (thirds of each garrison, every army with a queen) no longer runs. Kept for the 4e2 results.
-- ring2-challenge-plan.md 4e2: retake army (scripts/hive.lua) + influence map (scripts/influence.lua). Headless, no
-- players: a player-less character of force "player" stands in for the player.
-- 1. Generates 40 chunks, picks the ring-2 territory with the most built districts (at least 3).
-- 2. A and C (two districts) fall (hearts killed). A gets a pole + 3 walls (value, no threat), C a pole + 3 gun
--    turrets without ammo (value + threat). The brain is damaged to half.
-- 3. Character stays 40 tiles from A for 35 s: A isn't left, C is → the first army goes to C: a third of each live
--    garrison + an elder queen mass next to the brain for 60 s, march, kill the buildings, the queen settles: C live
--    again (heart, nests awake, survivors as garrison).
-- 4. Character goes home (0, 0): A left; the second army goes once the garrisons are full again; A retaken → hive
--    win: war over, brain healed.
-- 5. A and C fall again (new war), now A gets the turrets and C the walls; /ht-retake-now: the hive picks C (lower
--    threat per value); the elder queen is killed on the march → retreat, the survivors rejoin their garrisons,
--    next retry 2 min later.
-- Result: script-output/retake-test-result.txt (+ ht-telemetry/*.csv). --benchmark-ticks 30000.
local G = 384
local out = {}
local function p(...) out[#out + 1] = string.format("[%5.0f s] ", game.tick / 60) .. string.format(...) end
local function save() helpers.write_file("retake-test-result.txt", table.concat(out, "\n")) end
local function layer(i) return i >= 0 and i or -i - 1 end
local function ring_of(x, y) return math.max(layer(math.floor(x / G)), layer(math.floor(y / G))) end
local T0 = 120
local st = {phase = "init"}

local function debug(name, ...) return remote.call("hostile-territory-debug", name, ...) end
local function centre(d) return {x = d.x + 0.5, y = d.y + 0.5} end
local function district(slot)
  for _, d in pairs(debug("districts_state")[st.id].list) do if d.slot == slot then return d end end
end
local function heart_of(s, d)
  return s.find_entities_filtered{position = centre(d), radius = 1.5, name = "ht-district-heart"}[1]
end
local function war_of() return (debug("wars") or {})[st.id] end
local function army_of() return (debug("armies") or {})[st.id] end
local function brain_unit() return st.territory.valid and st.territory.get_segmented_units()[1] end

local function garrisons()
  local parts = {}
  for _, d in pairs(debug("districts_state")[st.id].list) do
    if d.built then
      local g = d.garrison
      local n
      if not g then n = "-"
      elseif g.units then
        n = 0
        for _, u in pairs(g.units) do if u.valid then n = n + 1 end end
        n = n .. " on map"
      else n = (g.count or 0) .. " kept" end
      parts[#parts + 1] = string.format("d%d %s%s", d.slot, d.fallen and "fallen " or "", n)
    end
  end
  return table.concat(parts, ", ")
end

local function place_buildings(s, d, turrets)
  local c = centre(d)
  local made = {}
  local function put(name, dx, dy)
    local pos = s.find_non_colliding_position(name, {c.x + dx, c.y + dy}, 8, 1)
    local e = pos and s.create_entity{name = name, position = pos, force = "player"}
    if e then made[#made + 1] = e end
  end
  put("small-electric-pole", 22, 0)
  for k = 1, 3 do put(turrets and "gun-turret" or "stone-wall", 20 + 3 * k, 6) end
  local names = {}
  for _, e in pairs(made) do names[#names + 1] = e.name .. "=" .. tostring(e.prototype.is_building) end
  return #made, table.concat(names, " ")
end

local function nests_disabled(s, d)
  local n = 0
  for _, e in pairs(s.find_entities_filtered{position = centre(d), radius = 18, name = {"biter-spawner", "spitter-spawner"}}) do
    if e.disabled_by_script then n = n + 1 end
  end
  return n
end

local function last_events(n)
  local w = war_of()
  return w and w.log or "-"
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  local t = e.tick
  if st.c and st.c.valid then st.c.health = st.c.max_health end
  if t == 2 then s.request_to_generate_chunks({0, 0}, 40) end
  if t >= 2 and t < 100 then s.force_generate_chunk_requests() end
  if t < T0 or t % 30 ~= 0 then return end

  if st.phase == "init" then
    p("seed %d", s.map_gen_settings.seed)
    -- enemy expansion on and frequent, as in a real game (PT4: expansion parties took massing army units)
    game.map_settings.enemy_expansion.enabled = true
    game.map_settings.enemy_expansion.min_expansion_cooldown = 10 * 60
    game.map_settings.enemy_expansion.max_expansion_cooldown = 10 * 60
    local by_id = {}
    for _, terr in pairs(s.get_territories()) do by_id[script.register_on_object_destroyed(terr)] = terr end
    local best, bn
    for id, state in pairs(debug("districts_state")) do
      local built = {}
      for _, d in pairs(state.list) do if d.built then built[#built + 1] = d end end
      if ring_of(state.point.x, state.point.y) == 2 and #built >= 3 and (not bn or #built > bn) then
        best, bn = {id = id, built = built, point = state.point}, #built
      end
    end
    if not best then p("no ring-2 territory with 3 built districts") save() st.phase = "end" return end
    st.id, st.territory = best.id, by_id[best.id]
    st.A, st.C = best.built[1], best.built[2]
    p("territory %d, %d built districts; A = d%d, C = d%d", st.id, bn, st.A.slot, st.C.slot)
    st.c = s.create_entity{name = "character", position = s.find_non_colliding_position("character", centre(st.A), 60, 1), force = "player"}
    st.c.character_health_bonus = 100000
    heart_of(s, st.A).die("player", st.c)
    heart_of(s, st.C).die("player", st.c)
    local na, la = place_buildings(s, st.A, false)
    local nc, lc = place_buildings(s, st.C, true)
    p("2. A and C fallen: %s / %s; A: %d buildings (%s), C: %d buildings (%s); character is_building=%s",
      tostring(district(st.A.slot).fallen), tostring(district(st.C.slot).fallen), na, la, nc, lc, tostring(st.c.prototype.is_building))
    local b = brain_unit()
    b.health = b.max_health / 2
    p("   brain %.0f / %.0f HP; war %s; garrisons: %s", b.health, b.max_health, tostring(war_of() ~= nil), garrisons())
    local c = centre(st.A)
    local dx, dy = c.x - best.point.x, c.y - best.point.y
    local l = math.sqrt(dx * dx + dy * dy)
    st.c.teleport(s.find_non_colliding_position("character", {c.x + dx / l * 40, c.y + dy / l * 40}, 10, 1))
    st.phase, st.next = "stay", t + 35 * 60
    return
  end

  if st.phase == "stay" and t >= st.next then
    local a = army_of()
    p("3. character 40 tiles from A for 35 s: A left_since %s; army %s, target d%s (C = d%d)",
      tostring(district(st.A.slot).left_since), tostring(a ~= nil), a and a.slot or "-", st.C.slot)
    st.left_tick, st.phase = t, "wait_army"
    return
  end

  if st.phase == "wait_army" then
    local a = army_of()
    if a then
      local inf = debug("influence")
      local cells, v = 0, 0
      for _, c in pairs(inf.cells) do cells, v = cells + 1, v + c.value end
      p("   army %d starts %.0f s after the last step: target d%d (A = d%d), %d units + elder queen %s, state %s; garrisons now: %s",
        (st.army_n or 0) + 1, (t - st.left_tick) / 60, a.slot, st.A.slot, a.start_size, tostring(a.queen.valid), a.state, garrisons())
      p("   influence: %d cells, value %d in all", cells, v)
      st.army_n, st.phase = (st.army_n or 0) + 1, "watch"
      st.watch_state, st.watch_slot = a.state, a.slot
    elseif t - st.left_tick > 120 * 60 then
      p("4. no army after 120 s: FAIL; garrisons %s", garrisons()) save() st.phase = "end"
    end
    return
  end

  if st.phase == "watch" then
    local a = army_of()
    -- the army while it masses: commands, engine groups, spread (every 10 s)
    if a and a.state == "mass" and t % 600 == 0 then
      local kinds, grouped, n, far = {}, 0, 0, 0
      for _, u in pairs(a.units) do
        local e = u.entity
        if e.valid then
          n = n + 1
          local cmd = e.commandable.command
          local k = cmd and cmd.type or 0
          kinds[k] = (kinds[k] or 0) + 1
          if e.commandable.parent_group then grouped = grouped + 1 end
          if (e.position.x - a.spot.x) ^ 2 + (e.position.y - a.spot.y) ^ 2 > 30 * 30 then far = far + 1 end
        end
      end
      local list = {}
      for k, c in pairs(kinds) do list[#list + 1] = k .. ":" .. c end
      p("   massing: %d alive, commands {%s}, %d in an engine group, %d over 30 tiles from the spot", n, table.concat(list, " "), grouped, far)
    end
    if a and a.state ~= st.watch_state then
      local n = 0
      for _, u in pairs(a.units) do if u.entity.valid then n = n + 1 end end
      p("   army %d: %s → %s, %d of %d alive, buildings %s", st.army_n, st.watch_state, a.state, n, a.start_size, tostring(a.buildings))
      st.watch_state = a.state
    end
    if not a then
      local d = district(st.watch_slot)
      local h = heart_of(s, d)
      local w = war_of()
      local b = brain_unit()
      p("   army %d done: d%d fallen %s, heart %s, nests disabled %d, garrisons %s; war %s; brain %.0f / %.0f",
        st.army_n, st.watch_slot, tostring(d.fallen), tostring(h ~= nil), nests_disabled(s, d), garrisons(),
        tostring(w ~= nil), b.health, b.max_health)
      if w then
        st.c.teleport(s.find_non_colliding_position("character", {0, 0}, 10, 1))
        st.left_tick, st.phase = t, "wait_army"
        p("4. character goes home (0, 0)")
      else
        p("   hive win: war over %s, brain healed %s", tostring(w == nil), tostring(b.health >= b.max_health - 1))
        heart_of(s, st.A).die("player", st.c)
        heart_of(s, st.C).die("player", st.c)
        place_buildings(s, st.A, true)
        place_buildings(s, st.C, false)
        st.phase, st.next = "pick", t + 360 -- influence map updated (every 5 s)
      end
    elseif t - st.left_tick > 250 * 60 then
      local q = a.queen
      local cmd = q.valid and q.commandable.command
      p("   army still out after 250 s: FAIL; queen at %.0f %.0f, %.0f tiles from the target, command %s, has_command %s",
        q.position.x, q.position.y, math.sqrt((q.position.x - a.target.x) ^ 2 + (q.position.y - a.target.y) ^ 2),
        cmd and serpent.line(cmd) or "none", tostring(q.commandable.has_command))
      p("%s", debug("brains")) save() st.phase = "end"
    end
    return
  end

  if st.phase == "pick" and t >= st.next then
    p("5. A (turrets) and C (walls) fall again: war %s; retake forced in %d wars", tostring(war_of() ~= nil), debug("retake_now"))
    st.phase = "retreat_wait"
    return
  end

  if st.phase == "retreat_wait" then
    local a = army_of()
    if a and a.state == "march" then
      st.drawn = garrisons()
      a.queen.die("player", st.c)
      p("   army to d%d (C = d%d) marching (%d units), elder queen killed; garrisons before: %s", a.slot, st.C.slot, a.start_size, st.drawn)
      st.phase, st.next = "retreat_check", t + 60
    end
    return
  end

  if st.phase == "retreat_check" and t >= st.next then
    local w = war_of()
    p("   after the queen died: army %s, retry in %.0f s; garrisons: %s", tostring(army_of() ~= nil),
      w and ((w.retry_after or 0) - t) / 60 or -1, garrisons())
    p("%s", debug("brains"))
    p("%s", debug("attacks"))
    save()
    st.phase = "end"
  end
end)

-- Debug: who kills army units and the elder queen?
script.on_event(defines.events.on_entity_died, function(e)
  local a = st.id and army_of()
  if not a then return end
  local en = e.entity
  if en.name ~= "ht-elder-queen" and not a.units[en.unit_number] then return end
  st.deaths = (st.deaths or 0) + 1
  if st.deaths > 12 and en.name ~= "ht-elder-queen" then return end
  p("   died: %s at %.0f %.0f, cause %s (%s), damage %s", en.name, en.position.x, en.position.y,
    e.cause and e.cause.valid and e.cause.name or "-", e.force and e.force.name or "-", e.damage_type and e.damage_type.name or "-")
end, {{filter = "type", type = "unit"}})

script.on_event(defines.events.on_unit_added_to_group, function(e)
  local a = st.id and army_of()
  if not (a and e.unit and e.unit.valid) then return end
  if e.unit.name ~= "ht-elder-queen" and not a.units[e.unit.unit_number] then return end
  st.pulled = (st.pulled or 0) + 1
  if st.pulled <= 5 then
    local cmd = e.group.valid and e.group.command
    p("   engine group took %s (script driven %s, command %s)", e.unit.name, tostring(e.group.is_script_driven), cmd and cmd.type or "-")
  end
end)

-- Debug: army units that are also in a garrison, and when army units are destroyed without dying.
local function overlap(a)
  local n = 0
  for _, d in pairs(debug("districts_state")[st.id].list) do
    local g = d.garrison
    if g and g.units then
      for k in pairs(g.units) do if a.units[k] then n = n + 1 end end
    end
  end
  return n
end
script.on_nth_tick(60, function()
  local a = st.id and army_of()
  if not a then st.tracked = nil return end
  st.pos = st.pos or {}
  for k, u in pairs(a.units) do if u.entity.valid then st.pos[k] = {u.entity.name, u.entity.position} end end
  if a.queen.valid then st.pos.queen = {a.queen.name, a.queen.position} end
  if st.tracked ~= a.started_tick then
    st.tracked = a.started_tick
    st.reg = {}
    for k, u in pairs(a.units) do if u.entity.valid then st.reg[script.register_on_object_destroyed(u.entity)] = k end end
    if a.queen.valid then st.reg[script.register_on_object_destroyed(a.queen)] = "queen" end
    p("   army units also in a garrison at start: %d", overlap(a))
  end
end)
script.on_event(defines.events.on_object_destroyed, function(e)
  local k = st.reg and st.reg[e.registration_number]
  if not k then return end
  st.reg[e.registration_number] = nil
  st.gone = (st.gone or 0) + 1
  if st.gone <= 8 or k == "queen" then
    local a = army_of()
    local last = st.pos and st.pos[k]
    local where, near = "-", "-"
    if last then
      local q = last[2]
      where = string.format("%s at %.0f %.0f", last[1], q.x, q.y)
      local sp = game.surfaces.nauvis.find_entities_filtered{position = q, radius = 12, type = "unit-spawner"}
      local parts = {}
      for _, e2 in pairs(sp) do parts[#parts + 1] = string.format("%s %.0f%s", e2.name, math.sqrt((e2.position.x - q.x) ^ 2 + (e2.position.y - q.y) ^ 2), e2.disabled_by_script and " off" or "") end
      near = table.concat(parts, ", ")
    end
    p("   destroyed: %s, last %s, spawners within 12: %s (army state %s)", tostring(k), where, near, a and a.state or "-")
  end
end)
