local RADIUS = 32 -- chunks around the origin

local function centroid(points)
  local sx, sy = 0, 0
  for _, p in pairs(points) do sx, sy = sx + (p.x or p[1]), sy + (p.y or p[2]) end
  return sx / #points, sy / #points
end

script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 2 then return end
  local s = game.surfaces.nauvis
  s.request_to_generate_chunks({0, 0}, RADIUS)
  s.force_generate_chunk_requests()

  local out = {}
  local function p(...) out[#out + 1] = string.format(...) end

  -- chunk -> territory index
  local territories = s.get_territories()
  local owner = {}
  local info = {}
  for i, t in pairs(territories) do
    local chunks = t.get_chunks()
    local all_generated = true
    local centres = {}
    for _, c in pairs(chunks) do
      owner[c.x .. "," .. c.y] = i
      if not s.is_chunk_generated(c) then all_generated = false end
      centres[#centres + 1] = {c.x * 32 + 16, c.y * 32 + 16}
    end
    local cx, cy = centroid(centres)
    local path = t.get_patrol_path()
    local px, py = centroid(path)
    info[i] = {chunk_list = chunks, chunks = #chunks, full = all_generated, cx = cx, cy = cy, px = px, py = py, worms = {}}
  end

  local worms = s.find_entities_filtered{name = "medium-worm-turret"}
  local loose = 0
  for _, w in pairs(worms) do
    local key = math.floor(w.position.x / 32) .. "," .. math.floor(w.position.y / 32)
    local i = owner[key]
    if i then table.insert(info[i].worms, w.position) else loose = loose + 1 end
  end

  local full, with1, with0, withmore = 0, 0, 0, 0
  p("territories=%d worms=%d worms outside any territory=%d other enemies: turrets=%d spawners=%d",
    #territories, #worms, loose,
    s.count_entities_filtered{type = "turret"} - #worms, s.count_entities_filtered{type = "unit-spawner"})
  p("fully generated territories:")
  for i, t in pairs(info) do
    if t.full then
      full = full + 1
      local n = #t.worms
      if n == 0 then with0 = with0 + 1 elseif n == 1 then with1 = with1 + 1 else withmore = withmore + 1 end
      local line = string.format("  #%d chunks=%d worms=%d chunk-centroid=(%.0f,%.0f)", i, t.chunks, n, t.cx, t.cy)
      for _, w in pairs(t.worms) do
        local dc = math.sqrt((w.x - t.cx)^2 + (w.y - t.cy)^2)
        local dp = math.sqrt((w.x - t.px)^2 + (w.y - t.py)^2)
        line = line .. string.format(" | worm (%.1f,%.1f) to chunk-centroid=%.0f to patrol-centroid=%.0f", w.x, w.y, dc, dp)
      end
      if n == 0 then
        -- find the Voronoi point: coarse search over chunk centres, then every tile of the best chunk
        local best, bd = nil, math.huge
        for _, c in pairs(t.chunk_list) do
          local d = s.calculate_tile_properties({"ht_test_centre_distance"}, {{c.x * 32 + 16, c.y * 32 + 16}}).ht_test_centre_distance[1]
          if d < bd then best, bd = c, d end
        end
        local pos = {}
        for dx = -48, 79 do for dy = -48, 79 do pos[#pos + 1] = {best.x * 32 + dx, best.y * 32 + dy} end end
        local props = s.calculate_tile_properties({"ht_test_centre_distance", "hostile_starting_area"}, pos)
        local bi, bv = 1, math.huge
        for k, v in pairs(props.ht_test_centre_distance) do if v < bv then bi, bv = k, v end end
        local pt = pos[bi]
        local owner_i = owner[math.floor(pt[1] / 32) .. "," .. math.floor(pt[2] / 32)]
        local blockers = {}
        for _, b in pairs(s.find_entities_filtered{area = {{pt[1] - 2, pt[2] - 2}, {pt[1] + 3, pt[2] + 3}}}) do blockers[#blockers + 1] = b.type end
        local tiles = {}
        for tx = pt[1] - 2, pt[1] + 2 do for ty = pt[2] - 2, pt[2] + 2 do local nm = s.get_tile(tx, ty).name tiles[nm] = (tiles[nm] or 0) + 1 end end
        local tl = {} for nm, c in pairs(tiles) do tl[#tl + 1] = nm .. "x" .. c end
        line = line .. string.format(" | can_place=%s tiles5x5=%s", tostring(s.can_place_entity{name = "medium-worm-turret", position = {pt[1] + 0.5, pt[2] + 0.5}, force = "enemy"}), table.concat(tl, " "))
        line = line .. string.format(" | point (%d,%d) d=%.2f tile=%s start_area=%d from_origin=%.0f in_territory=#%s nearby=%s",
          pt[1], pt[2], bv, s.get_tile(pt[1], pt[2]).name, props.hostile_starting_area[bi],
          math.sqrt(pt[1]^2 + pt[2]^2), tostring(owner_i), table.concat(blockers, ","))
      else
        for _, w in pairs(t.worms) do
          local d = s.calculate_tile_properties({"ht_test_centre_distance"}, {{w.x, w.y}}).ht_test_centre_distance[1]
          line = line .. string.format(" | point distance at worm=%.2f", d)
        end
      end
      p("%s", line)
    end
  end
  p("summary: full=%d with 1 worm=%d with 0=%d with 2+=%d", full, with1, with0, withmore)
  helpers.write_file("l2c-result.txt", table.concat(out, "\n"))
end)
