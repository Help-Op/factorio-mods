-- ring2-challenge-plan.md 4e1 + 4e1b + 4e1c (garrison mix 50 % small / 30 % medium / 20 % big; big + medium lead): ring-2 war (scripts/war.lua) with garrisons and zones of control. Headless, no
-- players: a player-less, healed-every-tick character of force "player" stands in for the player (never shoots).
-- 1. Generates 40 chunks, picks the ring-2 territory with the most built districts (A = first, B = its nearest).
--    Garrisons on the map before anyone comes near.
-- 2. Character 150 tiles out from A (inside WAKE, outside the zone): A's garrison on the map, no war.
-- 3. Character 70 out (inside the zone): war + fight by zone, half the garrison sent, brutes attack first, the small
--    biters ~1.5 s later.
-- 4. Character 30 out (inside HOLD): the rest joins. Leash: a sent unit moved 130 out turns home and drops out; moved
--    back within 60 it joins again.
-- 5. Rebuild: 30 garrison units killed, units added in 10 s.
-- 6. A's heart killed: fallen, fight won, nests disabled, garrison walks to the nearest live district.
-- 7. Character drives a tank into B's zone: fight by zone (does the zone see a driver?). Tank 400 away: fight left,
--    units home; a minute later B's garrison is off the map (kept as a number).
-- 8. Every other heart killed (the last garrison walks to the brain), brain killed → war ends.
-- Radar visibility can't be tested headless (no charting). --benchmark-ticks 5700. Result:
-- script-output/war-test-result.txt (+ the telemetry CSVs in ht-telemetry/)
local G = 384
local out = {}
local function p(...) out[#out + 1] = string.format(...) end
local function layer(i) return i >= 0 and i or -i - 1 end
local function ring_of(x, y) return math.max(layer(math.floor(x / G)), layer(math.floor(y / G))) end
local T0 = 120
local st = {}

local function centre(d) return {x = d.x + 0.5, y = d.y + 0.5} end
local function heart_of(s, d)
  return s.find_entities_filtered{position = centre(d), radius = 1.5, name = "ht-district-heart"}[1]
end
local function nests_of(s, d)
  return s.find_entities_filtered{position = centre(d), radius = 18, name = {"biter-spawner", "spitter-spawner"}}
end
local function war_of() return (remote.call("hostile-territory-debug", "wars") or {})[st.id] end
local function district(slot)
  for _, d in pairs(remote.call("hostile-territory-debug", "districts_state")[st.id].list) do
    if d.slot == slot then return d end
  end
end
local function fight_of(slot)
  local w = war_of()
  return w and w.fights[slot]
end
-- spot `dist` tiles out from district d, away from the territory point
local function out_from(s, d, dist, name)
  local c = centre(d)
  local dx, dy = c.x - st.point.x, c.y - st.point.y
  local base = math.atan2(dy, dx)
  for _, turn in pairs({0, 1, -1, 2, -2, 3, -3, 4}) do -- × 45°, outward first (water / ungenerated: next angle)
    local a = base + turn * math.pi / 4
    local spot = {c.x + math.cos(a) * dist, c.y + math.sin(a) * dist}
    if s.is_chunk_generated({math.floor(spot[1] / 32), math.floor(spot[2] / 32)}) then
      local found = s.find_non_colliding_position(name or "character", spot, 10, 1)
      if found then return found end
    end
  end
end
local function garrison_line(slot)
  local d = district(slot)
  local g = d.garrison
  if not g then return "no garrison record" end
  if not g.units then return string.format("off the map, count %d", g.count or -1) end
  local n, per = 0, {}
  for _, u in pairs(g.units) do
    if u.valid then
      n = n + 1
      per[u.name] = (per[u.name] or 0) + 1
    end
  end
  return string.format("on the map, %d units (small %d / medium %d / big %d)", n, per["small-biter"] or 0,
    per["medium-biter"] or 0, per["big-biter"] or 0)
end
local function committed(f)
  local n, brutes_attacking, swarm_attacking = 0, 0, 0
  for _, u in pairs(f and f.spawned or {}) do
    if u.valid then
      n = n + 1
      local cmd = u.commandable.command
      if cmd and cmd.type == defines.command.attack then
        if u.name == "medium-biter" or u.name == "big-biter" then brutes_attacking = brutes_attacking + 1 else swarm_attacking = swarm_attacking + 1 end
      end
    end
  end
  return n, brutes_attacking, swarm_attacking
end
local function units_on_map(s) return s.count_entities_filtered{type = "unit", force = "enemy"} end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  local t = e.tick
  if st.c and st.c.valid then st.c.health = st.c.max_health end
  if st.tank and st.tank.valid then st.tank.health = st.tank.max_health end
  if t == 2 then s.request_to_generate_chunks({0, 0}, 40) end
  if t >= 2 and t < 100 then s.force_generate_chunk_requests() end

  if t == T0 then
    p("seed %d", s.map_gen_settings.seed)
    local by_id = {}
    for _, terr in pairs(s.get_territories()) do by_id[script.register_on_object_destroyed(terr)] = terr end
    local best, bn
    for id, state in pairs(remote.call("hostile-territory-debug", "districts_state")) do
      local built = {}
      for _, d in pairs(state.list) do if d.built then built[#built + 1] = d end end
      if ring_of(state.point.x, state.point.y) == 2 and #built >= 2 and (not bn or #built > bn) then
        best, bn = {id = id, built = built, point = state.point}, #built
      end
    end
    if not best then p("no ring-2 territory with 2 built districts") helpers.write_file("war-test-result.txt", table.concat(out, "\n")) return end
    st.id, st.point, st.territory = best.id, best.point, by_id[best.id]
    st.A = best.built[1]
    local bd
    for k = 2, #best.built do
      local d = best.built[k]
      local q = (d.x - st.A.x) ^ 2 + (d.y - st.A.y) ^ 2
      if not bd or q < bd then st.B, bd = d, q end
    end
    p("territory %d, %d built districts; A slot %d (%d,%d), B slot %d (%d,%d), %d tiles apart", st.id, bn, st.A.slot,
      st.A.x, st.A.y, st.B.slot, st.B.x, st.B.y, math.sqrt(bd))
    local shown = 0
    for _, state in pairs(remote.call("hostile-territory-debug", "districts_state")) do
      for _, d in pairs(state.list) do if d.garrison and d.garrison.units then shown = shown + 1 end end
    end
    p("1. before anyone near: garrisons on the map %d, enemy units %d", shown, units_on_map(s))
    st.c = s.create_entity{name = "character", position = out_from(s, st.A, 150), force = "player"}
    st.c.character_health_bonus = 100000 -- destructible (units don't target indestructible entities), healed every tick
  end

  if t == T0 + 90 then
    p("2. character 150 out from A: A %s; B %s; war %s", garrison_line(st.A.slot), garrison_line(st.B.slot), tostring(war_of() ~= nil))
    st.c.teleport(out_from(s, st.A, 70))
  end

  if t == T0 + 150 then
    local f = fight_of(st.A.slot)
    local n, ba, sa = committed(f)
    p("3. character 70 out: war %s, fight A %s (trigger %s); sent %d, held %s; attacking now: brutes %d, small %d",
      tostring(war_of() ~= nil), tostring(f ~= nil), f and f.trigger or "-", n, tostring(f and f.held), ba, sa)
  end

  if t == T0 + 270 then
    local n, ba, sa = committed(fight_of(st.A.slot))
    p("   2 s later: sent %d; attacking: brutes %d, small %d", n, ba, sa)
    local sum, cnt = {}, {}
    for _, u in pairs(fight_of(st.A.slot).spawned) do
      if u.valid then
        local q = math.sqrt((u.position.x - st.c.position.x) ^ 2 + (u.position.y - st.c.position.y) ^ 2)
        sum[u.name], cnt[u.name] = (sum[u.name] or 0) + q, (cnt[u.name] or 0) + 1
      end
    end
    local function avg(name) return cnt[name] and sum[name] / cnt[name] or -1 end
    p("   mean distance to the character: big %.0f, medium %.0f, small %.0f (does the front read?)", avg("big-biter"),
      avg("medium-biter"), avg("small-biter"))
    st.c.teleport(out_from(s, st.A, 30))
  end

  if t == T0 + 360 then
    local f = fight_of(st.A.slot)
    local n = committed(f)
    p("4. character 30 out: held %s, sent %d; A %s", tostring(f and f.held), n, garrison_line(st.A.slot))
    for _, u in pairs(f.spawned) do
      if u.valid then st.leash = u break end
    end
    local c = centre(st.A)
    local dx, dy = c.x - st.point.x, c.y - st.point.y
    local l = math.sqrt(dx * dx + dy * dy)
    st.leash.teleport(s.find_non_colliding_position(st.leash.name, {c.x - dx / l * 130, c.y - dy / l * 130}, 10, 0.5))
  end

  if t == T0 + 420 then
    local f = fight_of(st.A.slot)
    local cmd = st.leash.valid and st.leash.commandable.command
    p("   unit moved 130 out: still sent %s, command %s", tostring(f.spawned[st.leash.unit_number] ~= nil),
      cmd and (cmd.type == defines.command.go_to_location and "go home" or tostring(cmd.type)) or "none")
    st.leash.teleport(s.find_non_colliding_position(st.leash.name, centre(st.A), 25, 0.5))
  end

  if t == T0 + 480 then
    local f = fight_of(st.A.slot)
    p("   moved back within 60: sent again %s", tostring(st.leash.valid and f.spawned[st.leash.unit_number] ~= nil))
    local killed = 0
    for _, u in pairs(district(st.A.slot).garrison.units) do
      if u.valid and killed < 30 then u.die("player") killed = killed + 1 end
    end
    st.rebuilt0 = f.rebuilt
    p("5. killed %d garrison units: A %s", killed, garrison_line(st.A.slot))
  end

  if t == T0 + 1080 then
    local f = fight_of(st.A.slot)
    p("   10 s later: rebuilt %d (expected ~0.7 / s with 6 nests + heart), A %s", f.rebuilt - st.rebuilt0, garrison_line(st.A.slot))
    st.b_before = garrison_line(st.B.slot)
    st.a_units = {}
    for _, u in pairs(district(st.A.slot).garrison.units) do if u.valid then st.a_units[#st.a_units + 1] = u end end
    heart_of(s, st.A).die("player", st.c)
  end

  if t == T0 + 1140 then
    local d = district(st.A.slot)
    local inactive = 0
    for _, n in pairs(nests_of(s, st.A)) do if n.disabled_by_script then inactive = inactive + 1 end end
    local to_b, cmd = 0, nil
    local b = centre(st.B)
    for _, u in pairs(st.a_units) do
      if u.valid then
        local c = u.commandable.command
        cmd = cmd or c
        if c and c.destination and (c.destination.x - b.x) ^ 2 + (c.destination.y - b.y) ^ 2 < 4 then to_b = to_b + 1 end
      end
    end
    p("6. A's heart killed: fallen %s, fight A %s, nests %d inactive, A garrison %s; %d of %d A units walk to B; B before %s, now %s",
      tostring(d.fallen), tostring(fight_of(st.A.slot) ~= nil), inactive, tostring(d.garrison ~= nil), to_b, #st.a_units,
      st.b_before, garrison_line(st.B.slot))
    -- 7. tank into B's zone
    st.tank = s.create_entity{name = "tank", position = out_from(s, st.B, 200, "tank"), force = "player"}
    st.tank.set_driver(st.c)
    st.tank.teleport(out_from(s, st.B, 70, "tank"))
    local seen = 0
    for _, c in pairs(s.find_entities_filtered{type = "character"}) do if c == st.c then seen = seen + 1 end end
    p("7. character drives a tank (driving %s), found by find_entities_filtered type=character: %s (war.lua also takes vehicles with a driver)", tostring(st.c.driving), tostring(seen == 1))
  end

  if t == T0 + 1200 then
    local f = fight_of(st.B.slot)
    local n, ba, sa = committed(f)
    local on_tank = 0
    for _, u in pairs(f and f.spawned or {}) do
      local cmd = u.valid and u.commandable.command
      if cmd and cmd.target == st.tank then on_tank = on_tank + 1 end
    end
    p("   tank 70 out from B: fight B %s (trigger %s), sent %d, attacking brutes %d / small %d, %d of them at the tank", tostring(f ~= nil), f and f.trigger or "-", n, ba, sa, on_tank)
    st.tank.teleport(out_from(s, st.B, 400, "tank"))
  end

  if t == T0 + 1620 then
    p("   tank 400 away: fight B %s; B %s", tostring(fight_of(st.B.slot) ~= nil), garrison_line(st.B.slot))
  end

  if t == T0 + 5400 then
    p("   a minute later: B %s; enemy units on the map %d", garrison_line(st.B.slot), units_on_map(s))
    p("%s", remote.call("hostile-territory-debug", "brains"))
    -- last districts: B's garrison back on the map, then every standing heart killed (the last one sends its units to the brain)
    local head = st.territory.get_segmented_units()[1].segments[1].position -- all districts within WAKE of the brain
    st.tank.teleport(s.find_non_colliding_position("tank", head, 30, 1))
  end

  if t == T0 + 5460 then
    local killed = 0
    for _, d in pairs(remote.call("hostile-territory-debug", "districts_state")[st.id].list) do
      local h = d.built and not d.fallen and heart_of(s, d)
      if h then h.die("player", st.c) killed = killed + 1 end
    end
    local fallen = 0
    for _, d in pairs(remote.call("hostile-territory-debug", "districts_state")[st.id].list) do if d.fallen then fallen = fallen + 1 end end
    p("   every other heart killed (%d): districts fallen %d, no error (war log: the last garrison walks to the brain)", killed, fallen)
    for _, u in pairs(st.territory.get_segmented_units()) do if u.valid then u.die() end end
  end

  if t == T0 + 5520 then
    p("8. brain killed: war %s", tostring(war_of() ~= nil))
    helpers.write_file("war-test-result.txt", table.concat(out, "\n"))
  end
end)
