-- ring-layout-plan.md R1-4: rings (grid layer of the territory point's cell, Lua vs noise), oil patches per ring,
-- the guaranteed ring-1 patch. Headless on tick 10 after generating 40 chunks around the origin.
-- Result: script-output/ring-check-result.txt
script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 2 then s.request_to_generate_chunks({0, 0}, 40) s.force_generate_chunk_requests() end
  if e.tick ~= 10 then return end
  local out = {}
  local function d(p) return math.sqrt(p.x * p.x + p.y * p.y) end
  local function layer(i) return i >= 0 and i or -i - 1 end
  local function ring(p) return math.max(layer(math.floor(p.x / 384)), layer(math.floor(p.y / 384))) end
  local ring_of, band = {}, {}
  for _, t in pairs(s.get_territories()) do
    local c1 = t.get_chunks()[1]
    if c1 then
      local q = s.calculate_tile_properties({"hostile_point_nearest_x", "hostile_point_nearest_y", "hostile_point_ring"}, {{c1.x * 32 + 16, c1.y * 32 + 16}})
      local pt = {x = q.hostile_point_nearest_x[1], y = q.hostile_point_nearest_y[1]}
      local r = ring(pt)
      if r ~= q.hostile_point_ring[1] then out[#out + 1] = "MISMATCH lua vs noise ring at " .. pt.x .. "," .. pt.y end
      local lo, hi = math.huge, 0
      for _, c in pairs(t.get_chunks()) do
        ring_of[c.x .. "," .. c.y] = r
        local cd = d({x = c.x * 32 + 16, y = c.y * 32 + 16})
        lo, hi = math.min(lo, cd), math.max(hi, cd)
      end
      band[r] = band[r] or {n = 0, lo = math.huge, hi = 0, blo = math.huge, bhi = 0}
      local b = band[r]
      b.n, b.lo, b.hi, b.blo, b.bhi = b.n + 1, math.min(b.lo, lo), math.max(b.hi, hi), math.min(b.blo, d(pt)), math.max(b.bhi, d(pt))
    end
  end
  for r = 0, 2 do
    if band[r] then out[#out + 1] = string.format("ring %d: %d territories, chunks %d–%d tiles, brains %d–%d", r, band[r].n, band[r].lo, band[r].hi, band[r].blo, band[r].bhi) end
  end
  local wells = s.find_entities_filtered{name = "crude-oil", position = {0, 0}, radius = 1300}
  local patches = {}
  for _, w in pairs(wells) do
    local hit
    for _, p in pairs(patches) do if (p.x - w.position.x) ^ 2 + (p.y - w.position.y) ^ 2 < 40 ^ 2 then hit = p break end end
    if hit then hit.n = hit.n + 1 else patches[#patches + 1] = {x = w.position.x, y = w.position.y, n = 1} end
  end
  table.sort(patches, function(a, b) return d(a) < d(b) end)
  local line, per = {}, {}
  for i, p in ipairs(patches) do
    local r = ring_of[math.floor(p.x / 32) .. "," .. math.floor(p.y / 32)]
    local key = r and ("r" .. r) or "safe/none"
    per[key] = (per[key] or 0) + 1
    if i <= 8 then line[#line + 1] = string.format("%d(%s,%dw)", d(p), key, p.n) end
  end
  out[#out + 1] = "oil patches nearest first: " .. table.concat(line, " ")
  local pl = {} for k, v in pairs(per) do pl[#pl + 1] = k .. "=" .. v end table.sort(pl)
  out[#out + 1] = "oil patches per ring: " .. table.concat(pl, " ")
  local st = remote.call("hostile-territory-debug", "oil")
  if st and st.spot then
    local n = s.count_entities_filtered{name = "crude-oil", position = st.spot, radius = 15}
    local r = ring_of[math.floor(st.spot.x / 32) .. "," .. math.floor(st.spot.y / 32)]
    out[#out + 1] = string.format("guaranteed spot (%d,%d), %d from origin, ring %s, done %s, placed %s, wells within 15: %d",
      st.spot.x, st.spot.y, d(st.spot), tostring(r), tostring(st.done), tostring(st.placed), n)
  else
    out[#out + 1] = "guaranteed spot: none"
  end
  helpers.write_file("ring-check-result.txt", table.concat(out, "\n"))
end)
