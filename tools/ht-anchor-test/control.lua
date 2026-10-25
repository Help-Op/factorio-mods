-- OR-E8 E8-A / E8-A2 (oil-ring-challenge-plan.md): the anchor ring, headless. Result: script-output/or-e8a-result.txt
-- 1. Map gen: per brain, nests within 25 tiles (inner ring + core area) and at 29–36 tiles (anchors), by ring;
--    anchor distances; blocked slots. Ring 1+ should have 4 anchors, ring 0 none.
-- 2. Oil: the guaranteed ring-1 wells (oil.lua, spot now 56 tiles out) vs the nearest nest.
-- 3. Regrow: one anchor of the nearest ring-1 base destroyed, regrow rounds, back on the same tile?
-- 4. Fight (waves_step debug record, siege; E8-A2 shield links): 4 links at the start, shut from the siege (a 200 hit
--    costs 20); a killed anchor releases a bearer at its spot that walks to 6–10 tiles from the brain on its side;
--    still shut until every anchor and bearer is dead, then open (200) for good, also when surge 1 comes (no new
--    bearers). Killing anchors in the siege doesn't wake the brain, killing an inner nest does (OR-D55).
-- 5. Queens (E8-B), logged at every step of 4: none before a nest dies; 1 at the first nest death, 2 after 20 s, never
--    3; where they hold (tiles from the target, degrees off "away from the brain"); biters spawned; escort distance
--    from its queen. Then a queen is killed (replaced 20 s later?), then every nest and queen (no new queens?).
-- BP-1 (OR-D99, OR-D100): no queens in the siege (anchor deaths), all 4 at once when the wake starts (inner nest);
--    summary: most queens in the siege, seconds from the wake to 4 queens, most units alive (cap 800).
-- Can't test headless: the siege starting on a hit on an anchor needs a connected player (challenge.on_base_damaged).
local R = "hostile-territory-debug"
local out = {}
local function p(...) out[#out + 1] = string.format(...) end
local function dist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end
local G = 384
local function layer(i) return i >= 0 and i or -i - 1 end
local function ring_at(pos) return math.max(layer(math.floor(pos.x / G)), layer(math.floor(pos.y / G))) end
local function write() helpers.write_file("or-e8a-result.txt", table.concat(out, "\n")) end

local function nests_between(s, h, r1, r2)
  local list = {}
  for _, n in pairs(s.find_entities_filtered{position = h, radius = r2, type = "unit-spawner", force = "enemy"}) do
    if dist(n.position, h) >= r1 then list[#list + 1] = n end
  end
  return list
end

local function brains(s)
  local list = {}
  for _, u in pairs(s.get_segmented_units()) do
    local h = u.segments[1] and u.segments[1].position
    -- placed brains only (head on x.5, y.5, brain.lua), fully generated around
    if h and h.x % 1 == 0.5 and h.y % 1 == 0.5 and dist(h, {x = 0, y = 0}) < 760 then
      list[#list + 1] = {u = u, h = h, ring = ring_at(h), d = dist(h, {x = 0, y = 0})}
    end
  end
  table.sort(list, function(a, b) return a.d < b.d end)
  return list
end

local function map_gen(s)
  p("== 1. map gen")
  local per_ring = {}
  for _, b in pairs(brains(s)) do
    local inner = #nests_between(s, b.h, 0, 25)
    local anchors = nests_between(s, b.h, 29, 36)
    local ds, names = {}, {}
    for _, a in pairs(anchors) do
      ds[#ds + 1] = string.format("%.1f", dist(a.position, b.h))
      names[a.name] = (names[a.name] or 0) + 1
    end
    local other = #nests_between(s, b.h, 25, 29) + #nests_between(s, b.h, 36, 45)
    local r = per_ring[b.ring] or {bases = 0, anchors = {}, inner = {}}
    per_ring[b.ring] = r
    r.bases = r.bases + 1
    r.anchors[#anchors] = (r.anchors[#anchors] or 0) + 1
    r.inner[inner] = (r.inner[inner] or 0) + 1
    local blocked = ""
    if b.ring >= 1 and #anchors < 4 then
      blocked = string.format(" | water within 36: %d tiles, cliffs within 36: %d",
        s.count_tiles_filtered{position = b.h, radius = 36, collision_mask = "water_tile"},
        s.count_entities_filtered{position = b.h, radius = 36, type = "cliff"})
      -- the 4 slots as regrow.lua computes them: what stands there, the noise hit on the slot tile
      local c = {x = math.floor(b.h.x), y = math.floor(b.h.y)}
      local rot = s.calculate_tile_properties({"hostile_base_rotation"}, {{c.x, c.y}}).hostile_base_rotation[1]
      for k = 0, 3 do
        local a = k * math.pi / 2 + rot + math.pi / 4
        local x, y = c.x + math.floor(32 * math.cos(a) + 0.5), c.y + math.floor(32 * math.sin(a) + 0.5)
        local hit = s.calculate_tile_properties({"hostile_base_anchor_hit"}, {{x, y}}).hostile_base_anchor_hit[1]
        local here = {}
        for _, e in pairs(s.find_entities_filtered{position = {x + 0.5, y + 0.5}, radius = 3.5}) do here[#here + 1] = e.name end
        blocked = blocked .. string.format(" | slot (%d,%d) hit %s tile %s: %s", x, y, hit, s.get_tile(x, y).name,
          table.concat(here, " "))
      end
    end
    local kinds = {}
    for k, v in pairs(names) do kinds[#kinds + 1] = k .. " " .. v end
    -- OR-D105: no worm core in rings 0 and 1
    local worms = s.count_entities_filtered{position = b.h, radius = 25, type = "turret", force = "enemy"}
    p("ring %d brain at (%.1f, %.1f), %.0f from spawn: inner nests %d, worms %d, anchors %d at %s (%s), nests 25–29 / 36–45: %d%s",
      b.ring, b.h.x, b.h.y, b.d, inner, worms, #anchors, table.concat(ds, " "), table.concat(kinds, ", "), other, blocked)
  end
  for ring, r in pairs(per_ring) do
    local a, i = {}, {}
    for k, v in pairs(r.anchors) do a[#a + 1] = k .. " anchors: " .. v end
    for k, v in pairs(r.inner) do i[#i + 1] = k .. ": " .. v end
    table.sort(a) table.sort(i)
    p("ring %d: %d bases | %s | inner nests %s", ring, r.bases, table.concat(a, ", "), table.concat(i, ", "))
  end
end

local function oil_check(s)
  p("== 2. oil")
  local oil = remote.call(R, "oil")
  if not (oil and oil.spot) then p("no oil spot") return end
  local spot = {x = oil.spot.x or oil.spot[1], y = oil.spot.y or oil.spot[2]}
  local wells = s.find_entities_filtered{position = spot, radius = 20, name = "crude-oil"}
  local nearest_brain
  for _, b in pairs(brains(s)) do
    if not nearest_brain or dist(b.h, spot) < dist(nearest_brain.h, spot) then nearest_brain = b end
  end
  local closest = math.huge
  for _, w in pairs(wells) do
    for _, n in pairs(s.find_entities_filtered{position = w.position, radius = 20, type = "unit-spawner", force = "enemy"}) do
      closest = math.min(closest, dist(w.position, n.position))
    end
  end
  p("spot (%.0f, %.0f), %.1f tiles from its brain; %d wells; nearest nest to a well %s tiles (want > 6)", spot.x, spot.y,
    nearest_brain and dist(nearest_brain.h, spot) or -1, #wells, closest == math.huge and "> 20" or string.format("%.1f", closest))
end

local function regrow_check(s, b)
  p("== 3. regrow")
  local anchors = nests_between(s, b.h, 29, 36)
  if #anchors == 0 then p("no anchor at the ring-1 brain (%.1f, %.1f)", b.h.x, b.h.y) return end
  local gone = {name = anchors[1].name, x = anchors[1].position.x, y = anchors[1].position.y}
  anchors[1].destroy()
  local built = remote.call(R, "regrow", 3)
  local back = s.find_entities_filtered{position = {gone.x, gone.y}, radius = 0.1, type = "unit-spawner"}[1]
  p("destroyed %s at (%.1f, %.1f); after 3 regrow rounds (%d pieces on the map): %s; anchors now %d", gone.name, gone.x,
    gone.y, built, back and ("back, " .. back.name) or "NOT back", #nests_between(s, b.h, 29, 36))
end

local t = {}
local function angle(a, o) return math.deg(math.atan2(a.y - o.y, a.x - o.x)) end
local function fight_step(s, label, probe)
  t.target.health = t.target.max_health -- siege waves come at it; it never shoots back
  local r = remote.call(R, "waves_step", t.b.h.x, t.b.h.y, t.target, {phase = t.first and "siege" or nil, reset = t.first})
  t.first = false
  local lost = -1
  if probe ~= false then
    local before = t.b.u.health
    t.b.u.damage(200, "player", "physical", t.target, t.target)
    lost = before - t.b.u.health
    t.b.u.health = before
  end
  local bearers = {}
  for _, b in pairs(r.bearer_list or {}) do
    bearers[#bearers + 1] = string.format("%.1f tiles at %.0f°%s", dist(b, t.b.h), angle(b, t.b.h),
      b.spot and string.format(" (spot %.1f at %.0f°, %.1f away, cmd %s)", dist(b.spot, t.b.h), angle(b.spot, t.b.h),
        dist(b, b.spot), tostring(b.command)) or "")
  end
  p("%s: phase %s, surge %s, shield %s, links %s (anchors %s / %s, bearers %d: %s), a 200 hit cost %.1f HP", label,
    tostring(r.phase), tostring(r.surge), tostring(r.shield), tostring(r.links), tostring(r.anchors),
    tostring(r.anchors_start), #bearers, table.concat(bearers, ", "), lost)
  local tp = t.target.position
  local away = math.atan2(tp.y - t.b.h.y, tp.x - t.b.h.x)
  local queens = {}
  for _, q in pairs(r.queens or {}) do
    local off = math.deg((math.atan2(q.y - tp.y, q.x - tp.x) - away + math.pi) % (2 * math.pi) - math.pi)
    queens[#queens + 1] = string.format("%s %.1f tiles from target, %.0f° off away-from-brain, spot %s, cmd %s%s", q.state,
      dist(q, tp), off, q.spot and string.format("%.1f away", dist(q, q.spot)) or "-", tostring(q.command) .. "/" .. tostring(q.distraction) .. string.format(" at (%.1f, %.1f) dest %s spot %s speed %s", q.x, q.y,
        q.dest and string.format("(%.1f, %.1f)", q.dest.x, q.dest.y) or "-", q.spot and string.format("(%.1f, %.1f)", q.spot.x, q.spot.y) or "-",
        tostring(q.speed)), q.group and " IN GROUP" or "")
  end
  local esc, esc_n, esc_max = 0, 0, 0
  local by = {}
  for _, q in pairs(r.queens or {}) do by[q.number] = q end
  for _, e in pairs(r.escorts or {}) do
    local q = by[e.queen]
    if q then local d = dist(e, q) esc, esc_n, esc_max = esc + d, esc_n + 1, math.max(esc_max, d) end
  end
  local cmds = {}
  for _, e in pairs(r.escorts or {}) do local k = tostring(e.command) .. "@" .. string.format("%.3f", e.speed or 0) cmds[k] = (cmds[k] or 0) + 1 end
  local cl = {}
  for k, v in pairs(cmds) do cl[#cl + 1] = k .. " x" .. v end
  local st = r.stats or {}
  p("    queens %d (level %d) [%s], released %d, biters spawned %d; escorts %d, avg %.1f / max %.1f tiles from their queen (%s); alive %d",
    #queens, r.queen_level or 0, table.concat(queens, "; "), st.queens or 0, st.queen_spawned or 0, esc_n, esc_n > 0 and esc / esc_n or 0,
    esc_max, table.concat(cl, ", "), table_size(r.spawned or {}))
  t.queens_max = math.max(t.queens_max or 0, #queens)
  -- BP-1: none in the siege, 4 at once at the wake start
  if r.phase == "siege" then t.siege_queens = math.max(t.siege_queens or 0, #queens) end
  if r.phase ~= "siege" and not t.wake_tick then t.wake_tick = game.tick end
  if t.wake_tick and not t.four_tick and #queens >= 4 then t.four_tick = game.tick end
  t.alive_max = math.max(t.alive_max or 0, table_size(r.spawned or {}))
  -- OR-E12: with 4 queens, the smallest angle between two of them around the target (want ~90°)
  if #(r.queens or {}) == 4 then
    local angles = {}
    for _, q in pairs(r.queens) do angles[#angles + 1] = math.atan2(q.y - tp.y, q.x - tp.x) end
    table.sort(angles)
    local gap = 2 * math.pi + angles[1] - angles[#angles]
    for i = 2, #angles do gap = math.min(gap, angles[i] - angles[i - 1]) end
    t.gap_best = math.max(t.gap_best or 0, math.deg(gap))
    t.gap_n = (t.gap_n or 0) + 1
    t.gap_sum = (t.gap_sum or 0) + math.deg(gap)
  end
  local walking = false
  for _, q in pairs(r.queens or {}) do if q.state ~= "hold" then walking = true end end
  local spawned = st.queen_spawned or 0
  if t.last_spawned and spawned > t.last_spawned then
    if walking then t.spawn_walking = (t.spawn_walking or 0) + spawned - t.last_spawned end
  end
  t.last_spawned = spawned
  t.retreats = st.queen_retreats or 0
  return r
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 2 then
    s.request_to_generate_chunks({0, 0}, 26)
    s.force_generate_chunk_requests()
  elseif e.tick == 10 then
    -- speed check in the safe area: a lone queen and a small biter each walk 30 tiles east
    t.speed = {}
    for i, name in pairs({"ht-queen", "small-biter"}) do
      local from = s.find_non_colliding_position(name, {-60, -40 + i * 12}, 10, 0.5)
      local u = s.create_entity{name = name, position = from, force = "enemy"}
      u.commandable.set_command{type = defines.command.go_to_location, destination = {from.x + 30, from.y}, radius = 1,
        distraction = defines.distraction.none}
      t.speed[#t.speed + 1] = {u = u, from = from, name = name}
    end
    map_gen(s)
    oil_check(s)
    -- the ring-1 brain with 4 anchors and the fewest cliffs + water within 60 (retro: a neutral test brain)
    local best
    for _, b in pairs(brains(s)) do
      if b.ring == 1 and #nests_between(s, b.h, 29, 36) == 4 then
        local rough = s.count_entities_filtered{position = b.h, radius = 60, type = "cliff"}
          + s.count_tiles_filtered{position = b.h, radius = 60, collision_mask = "water_tile"} / 20
        if not best or rough < best then t.b, best = b, rough end
      end
    end
    if t.b then p("test brain (%.1f, %.1f): cliffs + water/20 within 60 = %.1f", t.b.h.x, t.b.h.y, best) end
    -- speed check 2: a lone queen walking out of this base (anchor ring side), 30 tiles outwards
    if t.b then
      local from = s.find_non_colliding_position("ht-queen", {t.b.h.x - 34, t.b.h.y + 2}, 6, 0.5)
      local u = s.create_entity{name = "ht-queen", position = from, force = "enemy"}
      u.commandable.set_command{type = defines.command.go_to_location, destination = {from.x - 30, from.y}, radius = 1,
        distraction = defines.distraction.none}
      t.speed[#t.speed + 1] = {u = u, from = from, name = "ht-queen at the base"}
    end
    if not t.b then p("no ring-1 brain with 4 anchors") write() return end
    regrow_check(s, t.b)
    p("== 4. fight (ring-1 brain at (%.1f, %.1f), debug record, siege)", t.b.h.x, t.b.h.y)
    local pos = s.find_non_colliding_position("character", {t.b.h.x + 60, t.b.h.y}, 20, 1)
    t.target = s.create_entity{name = "character", position = pos, force = "player"}
    t.target.get_inventory(defines.inventory.character_armor).insert{name = "heavy-armor"}
    -- OR-E12: queens spawning while walking killed it between heals; indestructible = no damage = calm, so the queen
    -- level climbs (tests the level-9 rate)
    t.target.destructible = false
    t.first = true
    fight_step(s, "start")
    write()
  elseif e.tick == 130 then
    for _, x in pairs(t.speed) do
      p("speed check: %s moved %.1f tiles in 2 s (%.2f tiles/tick), prototype speed %.3f", x.name, dist(x.u.position, x.from),
        dist(x.u.position, x.from) / 120, x.u.prototype.speed)
      x.u.destroy()
    end
    p("trees / rocks / cliffs in x -115..-40, y -450..-410: %d / %d / %d", s.count_entities_filtered{area = {{-115, -450}, {-40, -410}}, type = "tree"},
      s.count_entities_filtered{area = {{-115, -450}, {-40, -410}}, type = "simple-entity"}, s.count_entities_filtered{area = {{-115, -450}, {-40, -410}}, type = "cliff"})
    p("trees in the speed check strip x -60..-30, y -30..-10: %d", s.count_entities_filtered{area = {{-60, -30}, {-30, -10}}, type = "tree"})
    write()
  elseif e.tick == 40 then
    local a = nests_between(s, t.b.h, 29, 36)[1]
    p("-- kill the anchor at %.0f°", angle(a.position, t.b.h))
    a.die("player", t.target)
    fight_step(s, "1 anchor killed")
  elseif e.tick % 30 == 10 and e.tick > 40 and e.tick < 400 then
    fight_step(s, "  walking", false)
  elseif e.tick == 400 then
    fight_step(s, "bearer walked in")
    t.angles = {}
    local others = nests_between(s, t.b.h, 29, 36)
    for _, a in pairs(others) do t.angles[#t.angles + 1] = string.format("%.0f°", angle(a.position, t.b.h)) a.die("player", t.target) end
    p("-- kill the other %d anchors (at %s)", #others, table.concat(t.angles, ", "))
    fight_step(s, "all anchors killed")
  elseif e.tick % 30 == 10 and e.tick > 400 and e.tick < 1300 then
    fight_step(s, "  walking", false)
  elseif e.tick == 1300 then
    fight_step(s, "bearers walked in")
    local n = 0
    for _, b in pairs(s.find_entities_filtered{position = t.b.h, radius = 60, name = "ht-shield-bearer"}) do b.die("player", t.target) n = n + 1 end
    p("-- killed %d bearers", n)
    fight_step(s, "links broken")
  elseif e.tick == 1330 then
    local inner = nests_between(s, t.b.h, 0, 25)
    if inner[1] then inner[1].die("player", t.target) end
    fight_step(s, "an inner nest killed")
    t.b.u.health = t.b.u.max_health * 0.7
    p("-- brain set to 70 %% (surge 1)")
  elseif e.tick == 1360 or e.tick == 1390 then
    fight_step(s, "surge 1")
  elseif e.tick == 1420 then
    fight_step(s, "surge 1, later")
    p("%s", remote.call(R, "waves_step", t.b.h.x, t.b.h.y, t.target).text)
    write()
  elseif e.tick > 1420 and e.tick < 7800 and e.tick % 30 == 10 then
    if e.tick == 1810 then
      -- PT13 retreat: the target goes for a holding queen (15 tiles from her, on the brain side)
      local q = s.find_entities_filtered{position = t.b.h, radius = 150, name = "ht-queen"}[1]
      if q then
        local o = t.b.h
        local d = math.max(dist(q.position, o), 1)
        local to = s.find_non_colliding_position("character", {q.position.x + (o.x - q.position.x) / d * 15,
          q.position.y + (o.y - q.position.y) / d * 15}, 8, 0.5)
        t.target.teleport(to)
        t.chased = q
        p("-- target jumps to %.1f tiles from a queen (she was %.1f tiles from it)", dist(to, q.position), dist(q.position, to))
      end
    end
    if t.chased and t.chased.valid and (e.tick == 1990 or e.tick == 2290) then
      p("-- chased queen now %.1f tiles from the target", dist(t.chased.position, t.target.position))
    end
    if e.tick == 4210 then
      local q = s.find_entities_filtered{position = t.b.h, radius = 120, name = "ht-queen"}[1]
      if q then q.die("player", t.target) t.queen_killed = e.tick p("-- killed a queen at %.1f s", e.tick / 60) end
    end
    if e.tick == 6010 then
      local n, q = 0, 0
      for _, x in pairs(s.find_entities_filtered{position = t.b.h, radius = 36, type = "unit-spawner", force = "enemy"}) do x.die("player", t.target) n = n + 1 end
      for _, x in pairs(s.find_entities_filtered{position = t.b.h, radius = 250, name = "ht-queen"}) do x.die("player", t.target) q = q + 1 end
      p("-- killed the last %d nests and %d queens at %.1f s", n, q, e.tick / 60)
      t.all_dead = e.tick
    end
    local r = fight_step(s, string.format("t %.1f s", e.tick / 60), false)
    local n = #(r.queens or {})
    if t.queen_killed and not t.replaced and e.tick > t.queen_killed and n == 4 then
      t.replaced = e.tick
      p("-- queen replaced %.1f s after the kill", (e.tick - t.queen_killed) / 60)
    end
    if t.all_dead and not t.released_at_kill then t.released_at_kill = (r.stats or {}).queens or 0 end
    if t.all_dead and e.tick > t.all_dead and ((r.stats or {}).queens or 0) > t.released_at_kill then t.after_all = true end
  elseif e.tick == 7800 then
    p("OR-E12: with 4 queens, smallest angle between two of them: avg %.0f°, best %.0f° (%d checks); queen biters spawned while a queen walked: %d",
      t.gap_n and t.gap_sum / t.gap_n or -1, t.gap_best or -1, t.gap_n or 0, t.spawn_walking or 0)
    p("nests within 36 of the brain at the end: %d (the debug record leaves the territory hostile, so regrow runs); worms: %d",
      #nests_between(s, t.b.h, 0, 36), s.count_entities_filtered{position = t.b.h, radius = 25, type = "turret", force = "enemy"})
    p("== summary: most queens at once %d; retreats %d; replaced after %s; queens released after all nests died: %s", t.queens_max or 0, t.retreats or 0,
      t.replaced and string.format("%.1f s", (t.replaced - t.queen_killed) / 60) or "never", tostring(t.after_all or false))
    p("== BP-1: most queens in the siege %d; 4 queens %s after the wake started; most units alive %d (cap 800)",
      t.siege_queens or 0, t.four_tick and string.format("%.1f s", (t.four_tick - t.wake_tick) / 60) or "never", t.alive_max or 0)
    write()
  end
end)
