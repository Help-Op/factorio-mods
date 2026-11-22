-- ring2-challenge-plan.md R2-E1 4c: districts of ring-2+ bases (scripts/districts.lua).
-- Generates 40 chunks around the origin, lets the base / district chunk requests finish, then: districts per ring-2+
-- territory, per district heart alive, nests around it, water / cliffs, own territory, distance to its brain, gap to
-- the nearest heart of another territory; spawner counts per ring; regrowth of a killed heart and nest; guaranteed
-- uranium (4d): per picked territory its rank, the patch's district, whether it faces spawn, ore found there;
-- uranium tiles per ring. Headless, --benchmark-ticks 140. Result: script-output/district-test-result.txt
local G = 384
local out = {}
local function p(...) out[#out + 1] = string.format(...) end
local function layer(i) return i >= 0 and i or -i - 1 end
local function ring_of(x, y) return math.max(layer(math.floor(x / G)), layer(math.floor(y / G))) end
local function d(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end
local killed

local function report(s)
  p("seed %d", s.map_gen_settings.seed)
  p("%s", remote.call("hostile-territory-debug", "brains"))
  local state = remote.call("hostile-territory-debug", "districts_state")
  local by_id = {}
  for _, t in pairs(s.get_territories()) do by_id[script.register_on_object_destroyed(t)] = t end

  local hearts = {}
  local per_count = {}
  local bad, rows, built, no_heart = 0, {}, 0, {}
  for id, st in pairs(state) do
    local t = by_id[id]
    local unit = t and t.valid and t.get_segmented_units()[1]
    local head = unit and unit.valid and unit.segments[1].position
    local ring = ring_of(st.point.x, st.point.y)
    per_count[ring] = per_count[ring] or {}
    per_count[ring][#st.list] = (per_count[ring][#st.list] or 0) + 1
    for _, dd in pairs(st.list) do
      local c = {x = dd.x + 0.5, y = dd.y + 0.5}
      local heart = s.find_entities_filtered{position = c, radius = 1, name = "ht-district-heart"}[1]
      local nests = 0
      for _, n in pairs(s.find_entities_filtered{position = c, radius = 18, type = "unit-spawner", force = "enemy"}) do
        if n.name ~= "ht-district-heart" then nests = nests + 1 end
      end
      local water = s.count_tiles_filtered{position = c, radius = 18, collision_mask = "water_tile"}
      local cliffs = s.count_entities_filtered{position = c, radius = 18, type = "cliff"}
      local own = s.get_territory_for_chunk({math.floor(c.x / 32), math.floor(c.y / 32)}) == t
      hearts[#hearts + 1] = {x = c.x, y = c.y, id = id}
      if dd.built and not (heart and own and nests >= 3) then bad = bad + 1 end
      if dd.built then built = built + 1 end
      if not heart and dd.built then
        -- what blocks the heart's spot
        local blockers = {}
        for _, e in pairs(s.find_entities_filtered{area = {{c.x - 4, c.y - 4}, {c.x + 4, c.y + 4}}}) do
          blockers[e.type] = (blockers[e.type] or 0) + 1
        end
        local parts = {}
        for k, v in pairs(blockers) do parts[#parts + 1] = k .. " " .. v end
        local wet = s.count_tiles_filtered{area = {{c.x - 4, c.y - 4}, {c.x + 4, c.y + 4}}, collision_mask = "water_tile"}
        no_heart[#no_heart + 1] = string.format("  (%d,%d): %s; water tiles %d", dd.x, dd.y, table.concat(parts, ", "), wet)
      end
      rows[#rows + 1] = string.format("%d | %d | (%d,%d) | %s | %s | %d | %d / %d | %s | %s", ring, dd.slot, dd.x, dd.y,
        tostring(dd.built), tostring(heart ~= nil), nests, water, cliffs, tostring(own), head and string.format("%.0f", d(c, head)) or "-")
    end
  end
  p("")
  p("== districts per territory, by ring (count: territories)")
  for ring = 2, 8 do
    if per_count[ring] then
      local parts = {}
      for n = 0, 4 do parts[#parts + 1] = n .. ": " .. (per_count[ring][n] or 0) end
      p("  ring %d: %s", ring, table.concat(parts, ", "))
    end
  end
  p("")
  p("== districts: ring | slot | heart tile | built | heart alive | nests within 18 | water tiles / cliffs within 18 | own territory | distance to its brain")
  for _, r in pairs(rows) do p("%s", r) end
  p("built districts failing a check (heart, own territory, >= 3 nests): %d of %d built (%d planned)", bad, built, #rows)
  p("built districts without a heart, what stands on its spot (8 x 8):")
  for _, r in pairs(no_heart) do p("%s", r) end

  local gaps = {}
  for _, a in pairs(hearts) do
    local best
    for _, b in pairs(hearts) do
      if b.id ~= a.id then
        local g = d(a, b)
        if not best or g < best then best = g end
      end
    end
    if best then gaps[#gaps + 1] = best end
  end
  table.sort(gaps)
  if #gaps > 0 then p("nearest heart of another territory: min %.0f, median %.0f", gaps[1], gaps[math.floor((#gaps + 1) / 2)]) end

  p("")
  p("== enemies")
  local per_ring = {}
  for _, e in pairs(s.find_entities_filtered{type = "unit-spawner", force = "enemy"}) do
    local r = ring_of(e.position.x, e.position.y)
    per_ring[r] = per_ring[r] or {nests = 0, hearts = 0}
    if e.name == "ht-district-heart" then per_ring[r].hearts = per_ring[r].hearts + 1 else per_ring[r].nests = per_ring[r].nests + 1 end
  end
  for r = 0, 8 do
    if per_ring[r] then p("  ring %d (by position): %d nests, %d hearts", r, per_ring[r].nests, per_ring[r].hearts) end
  end
  p("  units: %d", s.count_entities_filtered{type = "unit", force = "enemy"})

  p("")
  p("== guaranteed uranium (4d)")
  local points = remote.call("hostile-territory-debug", "uranium_points") or {}
  for k, u in ipairs(points) do
    local st
    for _, x in pairs(state) do if x.point.x == u.x and x.point.y == u.y then st = x end end
    if not st then
      p("  #%d point (%d,%d), %.0f from origin, ring %d: no districts planned", k, u.x, u.y, math.sqrt(u.x ^ 2 + u.y ^ 2), ring_of(u.x, u.y))
    else
      local nearest, nd, ud
      for _, dd in pairs(st.list) do
        local q = math.sqrt(dd.x ^ 2 + dd.y ^ 2)
        if not nd or q < nd then nearest, nd = dd, q end
        if dd.uranium then ud = dd end
      end
      if not ud then
        p("  #%d point (%d,%d): %d districts, none with uranium", k, u.x, u.y, #st.list)
      else
        local c = {x = ud.x + 0.5, y = ud.y + 0.5}
        local tiles, amount = 0, 0
        for _, r in pairs(s.find_entities_filtered{position = c, radius = 13, name = "uranium-ore"}) do
          tiles = tiles + 1
          amount = amount + r.amount
        end
        local other = s.count_entities_filtered{position = c, radius = 13, type = "resource"} - tiles
        p("  #%d point (%d,%d), %.0f from origin: %d districts; uranium at slot %d (%d,%d), faces spawn %s; stored %s; found %d tiles / %.2f M (other ore %d); heart %s, nests %d",
          k, u.x, u.y, math.sqrt(u.x ^ 2 + u.y ^ 2), #st.list, ud.slot, ud.x, ud.y, tostring(ud == nearest),
          type(ud.uranium) == "table" and string.format("%d tiles / %.2f M", ud.uranium.tiles, ud.uranium.amount / 1e6) or tostring(ud.uranium),
          tiles, amount / 1e6, other,
          tostring(s.count_entities_filtered{position = c, radius = 1, name = "ht-district-heart"} > 0),
          s.count_entities_filtered{position = c, radius = 18, name = {"biter-spawner", "spitter-spawner"}})
      end
    end
  end
  local per_ring_u = {}
  for _, r in pairs(s.find_entities_filtered{name = "uranium-ore"}) do
    local ring = ring_of(r.position.x, r.position.y)
    per_ring_u[ring] = (per_ring_u[ring] or 0) + 1
  end
  for r = 0, 8 do
    if per_ring_u[r] then p("  uranium tiles in ring %d (by position): %d", r, per_ring_u[r]) end
  end
  return state
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 2 then s.request_to_generate_chunks({0, 0}, 40) end
  if e.tick >= 2 and e.tick < 100 then s.force_generate_chunk_requests() end
  if e.tick == 120 then
    local state = report(s)
    -- regrowth: kill the first built ring-2 district's heart and one of its nests
    for _, st in pairs(state) do
      for _, dd in pairs(st.list) do
        if dd.built and not killed then
          local c = {x = dd.x + 0.5, y = dd.y + 0.5}
          local heart = s.find_entities_filtered{position = c, radius = 1, name = "ht-district-heart"}[1]
          local nest = s.find_entities_filtered{position = c, radius = 18, name = {"biter-spawner", "spitter-spawner"}}[1]
          if heart and nest then
            killed = {c = c, nest = nest.position}
            heart.destroy()
            nest.destroy()
          end
        end
      end
    end
  end
  if e.tick == 130 and killed then
    local built = remote.call("hostile-territory-debug", "regrow", 40)
    p("")
    p("regrow after killing the heart at (%.0f,%.0f) and a nest: %d pieces rebuilt over 40 rounds; heart back %s, nest back %s",
      killed.c.x, killed.c.y, built,
      tostring(s.count_entities_filtered{position = killed.c, radius = 1, name = "ht-district-heart"} > 0),
      tostring(s.count_entities_filtered{position = killed.nest, radius = 1, type = "unit-spawner"} > 0))
    helpers.write_file("district-test-result.txt", table.concat(out, "\n"))
  end
end)
