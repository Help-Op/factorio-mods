-- oil-ring-challenge-plan.md step 2: checks the pre-oil arsenal at runtime. Headless only (no players).
-- 1. Brain size per ring-1 territory (small / medium) after generating 40 chunks around the origin; /ht-goto-ring spots.
-- 2. Car: top speed, then runs it at full speed through lines of tiny / small / medium biters and a packed group.
-- 3. Shotgun: one shot from a player-less character into a packed group of small biters, 10 trials.
-- 4. Grenade: one grenade into a pack of small + medium biters, 5 trials.
-- Result: script-output/oil-ring-result.txt
local out = {}
local function log_line(...) out[#out + 1] = string.format(...) end
local function flush() helpers.write_file("oil-ring-result.txt", table.concat(out, "\n")) end

local function clear(s, area)
  for _, e in pairs(s.find_entities_filtered{area = area}) do
    if e.valid and e.type ~= "character" and e.type ~= "car" then e.destroy() end
  end
  local tiles = {}
  for x = area[1][1], area[2][1] - 1 do
    for y = area[1][2], area[2][2] - 1 do tiles[#tiles + 1] = {name = "grass-1", position = {x, y}} end
  end
  s.set_tiles(tiles)
end

local function spawn(s, name, list, pos)
  local p = s.find_non_colliding_position(name, pos, 3, 0.1) or pos
  local e = s.create_entity{name = name, position = p, force = "enemy"}
  if e then list[#list + 1] = e end
end

local function dead(list)
  local n = 0
  for _, e in pairs(list) do if not e.valid then n = n + 1 end end
  return n
end

local function wipe(list) for _, e in pairs(list) do if e.valid then e.destroy() end end end

-- car runs east along y = 0 from x = -280, teleported back at x = 280
local CAR_Y, TEST_Y, GREN_Y = 0, 60, 120
local car_tests = {
  {label = "10 tiny biters in a line", name = "ht-tiny-biter", n = 10, packed = false},
  {label = "10 small biters in a line", name = "small-biter", n = 10, packed = false},
  {label = "10 medium biters in a line", name = "medium-biter", n = 10, packed = false},
  {label = "20 small biters packed (r 2)", name = "small-biter", n = 20, packed = true},
}

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  local t = e.tick
  storage.st = storage.st or {}
  local st = storage.st

  if t == 2 then s.request_to_generate_chunks({0, 0}, 40) s.force_generate_chunk_requests() end

  if t == 10 then
    local function d(p) return math.sqrt(p.x * p.x + p.y * p.y) end
    local function layer(i) return i >= 0 and i or -i - 1 end
    local function ring(p) return math.max(layer(math.floor(p.x / 384)), layer(math.floor(p.y / 384))) end
    local per = {}
    for _, b in pairs(s.find_entities_filtered{type = "segmented-unit"}) do
      local r = ring(b.position)
      per[r] = per[r] or {}
      per[r][#per[r] + 1] = string.format("%s@%d", b.name:gsub("hf%-brain%-", ""), d(b.position))
    end
    for r = 0, 2 do
      if per[r] then
        table.sort(per[r], function(a, b) return tonumber(a:match("@(%d+)")) < tonumber(b:match("@(%d+)")) end)
        local count = {}
        for _, x in pairs(per[r]) do local k = x:match("^(%a+)") count[k] = (count[k] or 0) + 1 end
        local c = {} for k, v in pairs(count) do c[#c + 1] = k .. "=" .. v end table.sort(c)
        log_line("ring %d brains: %s | %s", r, table.concat(c, " "), table.concat(per[r], " "))
      end
    end
    -- /ht-goto-ring (PT2 fix): the spot must be in the brain's territory, of the asked ring, ~32–45 tiles out
    for _, r in pairs({0, 1}) do
      local g = remote.call("hostile-territory-debug", "goto_spot", r)
      if g.spot then
        log_line("goto ring %d: brain (%d,%d) ring %d, spot %.0f tiles from it, same territory %s",
          r, g.brain.x, g.brain.y, ring(g.brain), math.sqrt((g.spot.x - g.brain.x) ^ 2 + (g.spot.y - g.brain.y) ^ 2),
          tostring(g.spot_territory ~= nil and g.spot_territory == g.brain_territory))
      else
        log_line("goto ring %d: %s", r, g.reason)
      end
    end
    -- the arenas: flat grass, nothing in the way
    clear(s, {{-300, CAR_Y - 6}, {300, CAR_Y + 6}})
    clear(s, {{-20, TEST_Y - 20}, {40, TEST_Y + 20}})
    clear(s, {{-20, GREN_Y - 20}, {40, GREN_Y + 20}})
    for _, en in pairs(s.find_entities_filtered{force = "enemy", position = {0, 0}, radius = 400}) do en.destroy() end
    flush()
  end

  -- car top speed
  if t == 20 then
    local car = s.create_entity{name = "car", position = {-280, CAR_Y}, force = "player", direction = defines.direction.east}
    car.get_inventory(defines.inventory.fuel).insert{name = "coal", count = 50}
    local driver = s.create_entity{name = "character", position = {-280, CAR_Y + 3}, force = "player"}
    car.set_driver(driver)
    car.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight}
    st.car, st.top, st.top_tick = car, 0, nil
  end
  local car = st.car
  if car and car.valid and t > 20 then
    if car.position.x > 280 then car.teleport({-280, CAR_Y}) end
    car.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight}
    if car.speed > st.top + 0.0001 then st.top, st.top_tick = car.speed, t end
  end
  if t == 1220 then
    log_line("car: top speed %.4f tiles/tick = %.1f km/h, reached at tick %d (start 20), health %d",
      st.top, st.top * 216, st.top_tick or -1, car.health)
    flush()
  end

  -- car run-over tests, one every 1300 ticks from tick 1300 (time to get back to top speed)
  for i, ct in ipairs(car_tests) do
    local start = 1300 + (i - 1) * 1300
    if t == start - 1100 and i > 1 then
      car.teleport({-280, CAR_Y})
    elseif t == start then
      car.teleport({-100, CAR_Y})
      car.health = 450
      st.list = {}
      for k = 1, ct.n do
        if ct.packed then
          local a = k * 2.4
          spawn(s, ct.name, st.list, {-60 + math.cos(a) * (k % 3 + 0.3) * 0.7, CAR_Y + math.sin(a) * (k % 3 + 0.3) * 0.7})
        else
          spawn(s, ct.name, st.list, {-80 + k * 3, CAR_Y + (k % 2 == 0 and 0.4 or -0.4)})
        end
      end
      st.speed_before = car.speed
    elseif t == start + 120 then
      log_line("car vs %s: %d/%d dead, car health %d/450, speed %.3f -> %.3f",
        ct.label, dead(st.list), ct.n, car.health, st.speed_before, car.speed)
      wipe(st.list)
      flush()
    end
  end

  -- shotgun: 10 trials, one shot each, from tick 6600
  if t == 6600 then
    local c = s.create_entity{name = "character", position = {0, TEST_Y}, force = "player"}
    c.destructible = false
    c.get_inventory(defines.inventory.character_guns).insert{name = "shotgun", count = 1}
    c.get_inventory(defines.inventory.character_ammo).insert{name = "shotgun-shell", count = 10}
    st.gunner, st.shot_kills, st.shot_trials = c, {}, 0
  end
  if t >= 6610 and t < 6610 + 10 * 60 then
    local k = (t - 6610) % 60
    local c = st.gunner
    if k == 0 then
      st.list = {}
      for n = 1, 20 do
        local a = n * 2.4
        spawn(s, "small-biter", st.list, {8 + math.cos(a) * (n % 4) * 0.6, TEST_Y + math.sin(a) * (n % 4) * 0.6})
      end
      st.ammo_before = c.get_inventory(defines.inventory.character_ammo)[1].ammo
      c.shooting_state = {state = defines.shooting.shooting_selected, position = {8, TEST_Y}}
    elseif k == 1 then
      c.shooting_state = {state = defines.shooting.not_shooting, position = {8, TEST_Y}}
    elseif k == 40 then
      local stack = c.get_inventory(defines.inventory.character_ammo)[1]
      st.shot_trials = st.shot_trials + 1
      st.shot_kills[#st.shot_kills + 1] = dead(st.list) .. (stack.valid_for_read and "" or "?")
      wipe(st.list)
    end
  end
  if t == 6610 + 10 * 60 then
    local stack = st.gunner.get_inventory(defines.inventory.character_ammo)[1]
    log_line("shotgun, 1 shot into 20 packed small biters (r ~2), 10 trials: kills %s; shells left %d (of 10 items, magazine %d)",
      table.concat(st.shot_kills, " "), stack.valid_for_read and stack.count or 0, prototypes.item["shotgun-shell"].magazine_size)
    flush()
  end

  -- grenade: 5 trials, from tick 7300
  if t >= 7300 and t < 7300 + 5 * 120 then
    local k = (t - 7300) % 120
    if k == 0 then
      st.list, st.med = {}, {}
      for n = 1, 20 do
        local a = n * 2.4
        spawn(s, "small-biter", st.list, {10 + math.cos(a) * (n % 5) * 1.2, GREN_Y + math.sin(a) * (n % 5) * 1.2})
      end
      for n = 1, 5 do spawn(s, "medium-biter", st.med, {10 + n - 3, GREN_Y + 1}) end
      s.create_entity{name = "grenade", position = {0, GREN_Y}, target = {10, GREN_Y}, speed = 0.3, force = "player"}
    elseif k == 90 then
      local hp = {}
      for _, m in pairs(st.med) do hp[#hp + 1] = m.valid and string.format("%d", m.health) or "dead" end
      st.gren = st.gren or {}
      st.gren[#st.gren + 1] = string.format("small %d/20, medium hp [%s]", dead(st.list), table.concat(hp, " "))
      wipe(st.list) wipe(st.med)
    end
  end
  if t == 7300 + 5 * 120 then
    log_line("grenade into 20 small (r ~5) + 5 medium: %s", table.concat(st.gren, " | "))
    log_line("done")
    flush()
  end
end)
