-- Map check (territory-brain-plan.md B2/B3): reads Hostile Territory's territories and brain bases, changes nothing.
-- One base per territory? Base on the territory's point? Brains? Stray enemies? Uses the hostile_point_* /
-- hostile_base_* noise expressions through calculate_tile_properties.
-- Headless (no players): generates an area on tick 2, checks on tick 10 and writes script-output/map-check-result.txt.
-- In game: /ht-map-check, /ht-map-nearest.

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
  local p = surface.calculate_tile_properties({"hostile_point_own_x", "hostile_point_own_y", "hostile_base_exists", "hostile_base_ring_n", "hostile_base_core_m"}, positions)
  local points = {}
  for k = 1, #positions do
    points[#points + 1] = {x = p.hostile_point_own_x[k], y = p.hostile_point_own_y[k], base = p.hostile_base_exists[k] > 0,
                           n = p.hostile_base_ring_n[k], m = p.hostile_base_core_m[k]}
  end
  return points
end

-- the territory's point: nearest point of any of its chunks (all its chunks share it)
local function territory_point(surface, territory)
  local c = territory.get_chunks()[1]
  local p = surface.calculate_tile_properties({"hostile_point_nearest_x", "hostile_point_nearest_y"}, {{c.x * 32 + 16, c.y * 32 + 16}})
  return {x = p.hostile_point_nearest_x[1], y = p.hostile_point_nearest_y[1]}
end

local function fully_generated(surface, territory)
  for _, c in pairs(territory.get_chunks()) do
    if not surface.is_chunk_generated(c) then return false end
  end
  return true
end

local function check(surface, x1, y1, x2, y2)
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

  local one, zero, many, core_worms, no_unit, not_brain, claimed_clean, claimed_dirty, water_points = 0, 0, 0, 0, 0, 0, 0, 0, 0
  local brain_d = {}
  local own_point_ok = 0
  for i, t in pairs(full) do
    local list = per[i] or {}
    if #list == 0 then zero = zero + 1 elseif #list == 1 then one = one + 1 else many = many + 1 end
    local tp = territory_point(surface, t)
    for _, pt in pairs(list) do
      if pt.x == tp.x and pt.y == tp.y then own_point_ok = own_point_ok + 1 end
      core_worms = core_worms + surface.count_entities_filtered{position = {pt.x + 0.5, pt.y + 0.5}, radius = 8, type = "turret"}
      if surface.count_tiles_filtered{position = {pt.x + 0.5, pt.y + 0.5}, radius = 3, collision_mask = "water_tile"} > 0 then water_points = water_points + 1 end
      if #t.get_segmented_units() == 0 then
        local left = surface.count_entities_filtered{position = {pt.x + 0.5, pt.y + 0.5}, radius = 40, force = "enemy", type = {"turret", "unit-spawner", "unit"}}
        if left == 0 then claimed_clean = claimed_clean + 1 else claimed_dirty = claimed_dirty + 1 end
      end
    end
    local units = t.get_segmented_units()
    if #units == 0 then no_unit = no_unit + 1 end
    local line = string.format("territory #%d chunks=%d bases=%d units=%d point=(%d,%d)", i, #t.get_chunks(), #list, #units, tp.x, tp.y)
    for _, u in pairs(units) do
      if not u.prototype.name:find("^hf%-brain%-") then not_brain = not_brain + 1 end
      local h = u.segments[1].position
      local d = math.sqrt((h.x - tp.x - 0.5) ^ 2 + (h.y - tp.y - 0.5) ^ 2)
      brain_d[#brain_d + 1] = d
      line = line .. string.format(" | %s %.0f tiles from point", u.prototype.name, d)
    end
    p("%s", line)
  end

  table.sort(sizes)
  table.sort(brain_d)
  local sum = 0 for _, v in pairs(sizes) do sum = sum + v end
  local enemies = surface.find_entities_filtered{area = {{x1, y1}, {x2, y2}}, type = {"turret", "unit-spawner"}, force = "enemy"}
  local stray, in_start = 0, 0
  -- bases moved onto land (R2-E1 4b) stand on their spot, not their point
  local spots = {}
  for _, m in pairs(remote.call("hostile-territory-debug", "brain_state").moved) do spots[#spots + 1] = m.spot end
  for _, e in pairs(enemies) do
    local near = false
    for _, pt in pairs(points) do
      if pt.base and (e.position.x - pt.x) ^ 2 + (e.position.y - pt.y) ^ 2 < 36 ^ 2 then near = true break end -- 36: anchor ring (OR-E8)
    end
    for _, pt in pairs(spots) do
      if (e.position.x - pt.x) ^ 2 + (e.position.y - pt.y) ^ 2 < 36 ^ 2 then near = true break end
    end
    if not near then stray = stray + 1 end
    if (e.position.x ^ 2 + e.position.y ^ 2) < 150 ^ 2 then in_start = in_start + 1 end
  end
  table.insert(out, 1, string.format(
    "territories=%d fully generated=%d | bases per full territory: 1=%d 0=%d 2+=%d | base point is its territory's point=%d | core worms (radius 8)=%d | points with water within 3 tiles=%d | no unit + base area clean=%d, not clean=%d | points with a base but no territory=%d | territory size (chunks) min=%s avg=%.0f max=%s | territories without unit=%d | units that are not a brain=%d | brain distance from point min=%s max=%s | enemies=%d stray=%d in starting area=%d",
    #surface.get_territories(), #sizes, one, zero, many, own_point_ok, core_worms, water_points, claimed_clean, claimed_dirty, no_territory,
    tostring(sizes[1]), #sizes > 0 and sum / #sizes or 0, tostring(sizes[#sizes]), no_unit, not_brain, brain_d[1] and string.format("%.0f", brain_d[1]) or "-", brain_d[#brain_d] and string.format("%.0f", brain_d[#brain_d]) or "-", #enemies, stray, in_start))
  if remote.interfaces["hostile-territory-debug"] and remote.interfaces["hostile-territory-debug"].brains then
    table.insert(out, 2, remote.call("hostile-territory-debug", "brains"))
  end
  return out
end

-- generate on tick 2, check on tick 10 (after Hostile Territory's on_chunk_generated handlers)
script.on_event(defines.events.on_tick, function(e)
  if #game.players > 0 then return end
  local s = game.surfaces.nauvis
  if e.tick == 2 then
    s.request_to_generate_chunks({0, 0}, CHECK_RADIUS)
    s.force_generate_chunk_requests()
  end
  if e.tick ~= 10 then return end
  local r = CHECK_RADIUS * 32
  helpers.write_file("map-check-result.txt", table.concat(check(s, -r, -r, r, r), "\n"))
end)

commands.add_command("ht-map-check", "Check territories and brain bases within 1500 tiles of you (generated chunks only)", function(c)
  local player = game.get_player(c.player_index)
  local x, y = player.position.x, player.position.y
  local out = check(player.surface, x - 1500, y - 1500, x + 1500, y + 1500)
  player.print(out[1])
  helpers.write_file("map-check-ingame-result.txt", table.concat(out, "\n"))
end)

commands.add_command("ht-map-nearest", "GPS link to the nearest brain base", function(c)
  local player = game.get_player(c.player_index)
  local x, y = player.position.x, player.position.y
  local best, bd
  for _, b in pairs(points_in(player.surface, x - 1200, y - 1200, x + 1200, y + 1200)) do
    local d = (b.x - x) ^ 2 + (b.y - y) ^ 2
    if b.base and (not bd or d < bd) then best, bd = b, d end
  end
  if best then
    player.print(string.format("Nearest base: [gps=%d,%d] %.0f tiles away, %d nests", best.x, best.y, math.sqrt(bd), best.n)) -- no worms since R2-E1 4a
  else
    player.print("No base within 1200 tiles")
  end
end)
