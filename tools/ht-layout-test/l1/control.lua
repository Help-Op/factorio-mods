local CX, CY, R, N = 200, 0, 20, 8

script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 2 then return end
  local s = game.surfaces.nauvis
  s.request_to_generate_chunks({CX, CY}, 3)
  s.force_generate_chunk_requests()
  local out = {}
  local function p(...) out[#out + 1] = string.format(...) end
  local area = {{CX - 60, CY - 60}, {CX + 60, CY + 60}}
  local worms = s.find_entities_filtered{area = area, type = "turret"}
  local nests = s.find_entities_filtered{area = area, type = "unit-spawner"}
  p("worms=%d spawners=%d (in 120x120 box)", #worms, #nests)
  for _, w in pairs(worms) do p("worm %s at %.1f,%.1f", w.name, w.position.x, w.position.y) end
  for _, n in pairs(nests) do
    local dx, dy = n.position.x - CX, n.position.y - CY
    p("spawner %s at %.1f,%.1f  r=%.1f  angle=%.0f", n.name, n.position.x, n.position.y, math.sqrt(dx*dx+dy*dy), math.deg(math.atan2(dy, dx)))
  end
  -- what is on each target spot (missing ones: why?)
  for i = 0, N - 1 do
    local a = 2 * math.pi * i / N
    local tx, ty = math.floor(CX + R * math.cos(a) + 0.5), math.floor(CY + R * math.sin(a) + 0.5)
    local tile = s.get_tile(tx, ty).name
    local blockers = {}
    for _, b in pairs(s.find_entities_filtered{area = {{tx - 3, ty - 3}, {tx + 3, ty + 3}}}) do blockers[#blockers + 1] = b.type end
    p("target %d (%d,%d) tile=%s nearby=%s", i, tx, ty, tile, table.concat(blockers, ","))
  end
  p("worm target tile=%s", s.get_tile(CX, CY).name)
  -- whole surface check: any enemy anywhere else?
  p("enemy turrets on surface=%d spawners=%d", s.count_entities_filtered{type = "turret"}, s.count_entities_filtered{type = "unit-spawner"})
  helpers.write_file("l1-result.txt", table.concat(out, "\n"))
  log("L1 DONE\n" .. table.concat(out, "\n"))
end)
