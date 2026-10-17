-- L4 check: one base per territory? Territories and bases both come from the ht_l4_* points.
-- Headless (no players): generates an area on tick 2, checks, moves each territory's wyrm
-- to its base centre (L4c) and writes script-output/l4-result.txt.
-- In game: /ht-layout-check, /ht-layout-nearest, /ht-layout-move-brains.

local G = 384
local CHECK_RADIUS = 40 -- chunks, headless only

local function key(c) return c.x .. "," .. c.y end

-- every point (own cell point with a base) whose cell centre lies in the tile box
local function points_in(surface, x1, y1, x2, y2)
  local positions = {}
  for i = math.floor(x1 / G), math.floor(x2 / G) do
    for j = math.floor(y1 / G), math.floor(y2 / G) do
      positions[#positions + 1] = {(i + 0.5) * G, (j + 0.5) * G}
    end
  end
  local p = surface.calculate_tile_properties({"ht_l4_cx", "ht_l4_cy", "ht_l4_has_base", "ht_l4_ring_n", "ht_l4_core_m"}, positions)
  local points = {}
  for k = 1, #positions do
    points[#points + 1] = {x = p.ht_l4_cx[k], y = p.ht_l4_cy[k], base = p.ht_l4_has_base[k] > 0,
                           n = p.ht_l4_ring_n[k], m = p.ht_l4_core_m[k]}
  end
  return points
end

-- the territory's point: nearest point of any of its chunks (all its chunks share it)
local function territory_point(surface, territory)
  local c = territory.get_chunks()[1]
  local p = surface.calculate_tile_properties({"ht_l4_nx", "ht_l4_ny"}, {{c.x * 32 + 16, c.y * 32 + 16}})
  return {x = p.ht_l4_nx[1], y = p.ht_l4_ny[1]}
end

local function fully_generated(surface, territory)
  for _, c in pairs(territory.get_chunks()) do
    if not surface.is_chunk_generated(c) then return false end
  end
  return true
end

-- move the territory's first segmented unit so its head is on the point (set_body_nodes, EB3c C5)
local function move_brain(territory, point)
  local unit = territory.get_segmented_units()[1]
  if not unit then return nil end
  local head = unit.segments[1].position
  local dx, dy = point.x + 0.5 - head.x, point.y + 0.5 - head.y
  local nodes = unit.get_body_nodes()
  for _, n in pairs(nodes) do n.x, n.y = n.x + dx, n.y + dy end
  unit.set_body_nodes(nodes)
  local h = unit.segments[1].position
  return math.sqrt((h.x - point.x - 0.5) ^ 2 + (h.y - point.y - 0.5) ^ 2)
end

local function check(surface, x1, y1, x2, y2, move)
  local out = {}
  local function p(...) out[#out + 1] = string.format(...) end

  local owner = {}
  local full = {}
  local sizes = {}
  for i, t in pairs(surface.get_territories()) do
    for _, c in pairs(t.get_chunks()) do owner[key(c)] = i end
    if fully_generated(surface, t) then full[i] = t sizes[#sizes + 1] = #t.get_chunks() end
  end

  -- points per territory
  local per = {}
  local points = points_in(surface, x1, y1, x2, y2)
  local no_territory = 0
  for _, pt in pairs(points) do
    if pt.base then
      local i = owner[math.floor(pt.x / 32) .. "," .. math.floor(pt.y / 32)]
      if i then
        per[i] = per[i] or {}
        table.insert(per[i], pt)
      else
        no_territory = no_territory + 1
      end
    end
  end

  local one, zero, many, placed, water, moved_ok, moved, no_unit = 0, 0, 0, 0, 0, 0, 0, 0
  local own_point_ok = 0
  for i, t in pairs(full) do
    local list = per[i] or {}
    if #list == 0 then zero = zero + 1 elseif #list == 1 then one = one + 1 else many = many + 1 end
    local tp = territory_point(surface, t)
    for _, pt in pairs(list) do
      if pt.x == tp.x and pt.y == tp.y then own_point_ok = own_point_ok + 1 end
      local worm = surface.find_entities_filtered{position = {pt.x + 0.5, pt.y + 0.5}, radius = 1.6, type = "turret"}
      if #worm > 0 then placed = placed + 1
      elseif surface.get_tile(pt.x, pt.y).collides_with("water_tile") then water = water + 1 end
    end
    local units = #t.get_segmented_units()
    if units == 0 then no_unit = no_unit + 1 end
    local line = string.format("territory #%d chunks=%d bases=%d units=%d point=(%d,%d)", i, #t.get_chunks(), #list, units, tp.x, tp.y)
    if move and units > 0 then
      local d = move_brain(t, tp)
      moved = moved + 1
      if d and d < 2 then moved_ok = moved_ok + 1 end
      line = line .. string.format(" head after move %.1f tiles from point", d or -1)
    end
    p("%s", line)
  end

  table.sort(sizes)
  local sum = 0 for _, v in pairs(sizes) do sum = sum + v end
  local enemies = surface.find_entities_filtered{area = {{x1, y1}, {x2, y2}}, type = {"turret", "unit-spawner"}, force = "enemy"}
  local stray, in_start = 0, 0
  for _, e in pairs(enemies) do
    local near = false
    for _, pt in pairs(points) do
      if pt.base and (e.position.x - pt.x) ^ 2 + (e.position.y - pt.y) ^ 2 < 25 ^ 2 then near = true break end
    end
    if not near then stray = stray + 1 end
    if (e.position.x ^ 2 + e.position.y ^ 2) < 384 ^ 2 then in_start = in_start + 1 end
  end
  table.insert(out, 1, string.format(
    "territories=%d fully generated=%d | bases per full territory: 1=%d 0=%d 2+=%d | base point is its territory's point=%d | centre worm placed=%d, on water=%d | points with a base but no territory=%d | territory size (chunks) min=%s avg=%.0f max=%s | territories without unit=%d | moved=%d, head within 2 tiles=%d | enemies=%d stray=%d in starting area=%d",
    #surface.get_territories(), #sizes, one, zero, many, own_point_ok, placed, water, no_territory,
    tostring(sizes[1]), #sizes > 0 and sum / #sizes or 0, tostring(sizes[#sizes]), no_unit, moved, moved_ok, #enemies, stray, in_start))
  return out
end

script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 2 or #game.players > 0 then return end
  local s = game.surfaces.nauvis
  s.request_to_generate_chunks({0, 0}, CHECK_RADIUS)
  s.force_generate_chunk_requests()
  local r = CHECK_RADIUS * 32
  helpers.write_file("l4-result.txt", table.concat(check(s, -r, -r, r, r, true), "\n"))
end)

commands.add_command("ht-layout-check", "L4: check territories and bases within 1500 tiles of you (generated chunks only)", function(c)
  local player = game.get_player(c.player_index)
  local x, y = player.position.x, player.position.y
  local out = check(player.surface, x - 1500, y - 1500, x + 1500, y + 1500, false)
  player.print(out[1])
  helpers.write_file("l4-ingame-result.txt", table.concat(out, "\n"))
end)

commands.add_command("ht-layout-move-brains", "L4: move the wyrm of every fully generated territory to its base centre", function(c)
  local player = game.get_player(c.player_index)
  local s = player.surface
  local n = 0
  for _, t in pairs(s.get_territories()) do
    if fully_generated(s, t) and move_brain(t, territory_point(s, t)) then n = n + 1 end
  end
  player.print("moved " .. n .. " wyrms")
end)

commands.add_command("ht-layout-nearest", "L4: GPS link to the nearest base", function(c)
  local player = game.get_player(c.player_index)
  local x, y = player.position.x, player.position.y
  local best, bd
  for _, b in pairs(points_in(player.surface, x - 1200, y - 1200, x + 1200, y + 1200)) do
    local d = (b.x - x) ^ 2 + (b.y - y) ^ 2
    if b.base and (not bd or d < bd) then best, bd = b, d end
  end
  if best then
    player.print(string.format("Nearest base: [gps=%d,%d] %.0f tiles away, %d nests, %d worms", best.x, best.y, math.sqrt(bd), best.n, 1 + best.m))
  else
    player.print("No base within 1200 tiles")
  end
end)
