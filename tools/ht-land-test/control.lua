-- ring2-challenge-plan.md R2-E1 4b: water territories in every ring get their base on a land spot (brain.lua).
-- Generates 40 chunks around the origin (rings 0-2 and part of 3), lets the spot chunk requests finish, then per
-- moved base: ring, distance point -> spot, brain head on the spot, spot in its own cell and territory, water at the
-- spot, nests within 25 / anchors at 28-37 of the spot, map-gen leftovers around the point; claimed territories per
-- ring; the guaranteed oil spot vs its territory's brain. Also where the brains stand right after their territory exists (B-I10). Headless, --benchmark-ticks 110.
-- Result: script-output/land-test-result.txt
local G = 384
local out = {}
local early_heads = {} -- [territory registration] = head at tick 3, chunk generated
local function p(...) out[#out + 1] = string.format(...) end
local function layer(i) return i >= 0 and i or -i - 1 end
local function ring_of(x, y) return math.max(layer(math.floor(x / G)), layer(math.floor(y / G))) end
local function cell(x, y) return math.floor(x / G) .. "," .. math.floor(y / G) end
local function d(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end

local function report(s)
  p("%s", remote.call("hostile-territory-debug", "brains"))
  local state = remote.call("hostile-territory-debug", "brain_state")
  local by_id = {}
  for _, t in pairs(s.get_territories()) do by_id[script.register_on_object_destroyed(t)] = t end

  local per = {}
  local function ring_row(r)
    per[r] = per[r] or {placed = 0, moved = 0, dead = 0}
    return per[r]
  end
  for key in pairs(state.placed) do
    local i, j = key:match("(-?%d+),(-?%d+)")
    ring_row(math.max(layer(tonumber(i)), layer(tonumber(j)))).placed = ring_row(math.max(layer(tonumber(i)), layer(tonumber(j)))).placed + 1
  end
  for _, c in pairs(state.dead) do ring_row(ring_of(c.x, c.y)).dead = ring_row(ring_of(c.x, c.y)).dead + 1 end

  local multi, units = 0, 0
  for _, t in pairs(s.get_territories()) do
    local n = #t.get_segmented_units()
    units = units + n
    if n > 1 then multi = multi + 1 end
  end
  p("territories: %d, brains: %d, territories with more than 1 brain: %d", #s.get_territories(), units, multi)
  -- brains that stood somewhere else at tick 62 than where they ended (a second jump: the noise guessed wrong)
  local same, other = 0, 0
  for id, h in pairs(early_heads) do
    local t = by_id[id]
    local u = t and t.valid and t.get_segmented_units()[1]
    if u and u.valid then
      if d(u.segments[1].position, h) < 1 then same = same + 1 else
        other = other + 1
        p("  jumped again: (%.0f,%.0f) -> (%.0f,%.0f), early chunk generated %s", h.x, h.y,
          u.segments[1].position.x, u.segments[1].position.y, tostring(h.gen))
      end
    end
  end
  p("brains of tick 62: %d where they ended, %d moved again", same, other)

  p("")
  p("== moved bases")
  p("ring | point -> spot (tiles) | done | head on spot | own cell | own territory | water within 3 | nests < 25 | anchors 28-37 | leftovers near point | cliffs / water tiles / trees within 25")
  local bad = 0
  for key, m in pairs(state.moved) do
    local ring = ring_of(m.point.x, m.point.y)
    ring_row(ring).moved = ring_row(ring).moved + 1
    local spot = {x = m.spot.x + 0.5, y = m.spot.y + 0.5}
    local t = by_id[m.id]
    local unit = t and t.valid and t.get_segmented_units()[1]
    local head = unit and unit.valid and unit.segments[1].position
    local on_spot = head and d(head, spot) < 1
    local own_cell = cell(spot.x, spot.y) == key
    local spot_t = s.get_territory_for_chunk({math.floor(spot.x / 32), math.floor(spot.y / 32)})
    local own_t = spot_t and t and spot_t == t
    local water = s.count_tiles_filtered{position = spot, radius = 3, collision_mask = "water_tile"}
    local nests, anchors = 0, 0
    for _, n in pairs(s.find_entities_filtered{position = spot, radius = 40, type = "unit-spawner", force = "enemy"}) do
      local r = d(n.position, spot)
      if r < 25 then nests = nests + 1 elseif r >= 28 and r <= 37 then anchors = anchors + 1 end
    end
    local left = 0
    for _, e in pairs(s.find_entities_filtered{position = m.point, radius = 40, type = {"unit-spawner", "turret"}, force = "enemy"}) do
      if d(e.position, spot) > 45 then left = left + 1 end
    end
    local cliffs = s.count_entities_filtered{position = spot, radius = 25, type = "cliff"}
    local wet = s.count_tiles_filtered{position = spot, radius = 25, collision_mask = "water_tile"}
    local trees = s.count_entities_filtered{position = spot, radius = 25, type = "tree"}
    if not (m.done and on_spot and own_cell and own_t and water == 0 and nests > 0 and left == 0) then bad = bad + 1 end
    p("%d | (%d,%d) -> (%d,%d) %.0f | %s | %s | %s | %s | %d | %d | %d | %d | %d / %d / %d", ring, m.point.x, m.point.y, m.spot.x, m.spot.y,
      d(m.point, spot), tostring(m.done), tostring(on_spot), tostring(own_cell), tostring(own_t), water, nests, anchors, left,
      cliffs, wet, trees)
  end
  p("moved bases failing a check: %d", bad)
  local dry = 0
  for _, m in pairs(state.moved) do
    if s.count_tiles_filtered{position = m.point, radius = 3, collision_mask = "water_tile"} == 0 then dry = dry + 1 end
  end
  p("moved bases whose point has no water within 3 tiles after all (the noise margin): %d", dry)

  p("")
  p("== per ring: on their point / moved onto land / claimed (no land)")
  for r = 0, 6 do
    if per[r] then p("  ring %d: %d / %d / %d", r, per[r].placed - per[r].moved, per[r].moved, per[r].dead) end
  end
  p("claimed (no land) at:")
  for key, c in pairs(state.dead) do
    -- land in the cell (16-tile samples, elevation >= 2, own territory), water at the point, was it hidden first
    local i, j = key:match("(-?%d+),(-?%d+)")
    local x0, y0 = tonumber(i) * G, tonumber(j) * G
    local ps = {}
    for a = 0, 23 do for b = 0, 23 do ps[#ps + 1] = {x0 + a * 16 + 8, y0 + b * 16 + 8} end end
    local q = s.calculate_tile_properties({"elevation", "hostile_point_nearest_x", "hostile_point_nearest_y"}, ps)
    local land = 0
    for k = 1, #ps do
      if q.elevation[k] >= 2 and q.hostile_point_nearest_x[k] + 0.5 == c.x and q.hostile_point_nearest_y[k] + 0.5 == c.y then land = land + 1 end
    end
    p("  cell %s ring %d (%d,%d): land samples in own territory %d of %d, water within 3 of the point %d, hidden home %s",
      key, ring_of(c.x, c.y), c.x, c.y, land, #ps, s.count_tiles_filtered{position = c, radius = 3, collision_mask = "water_tile"},
      state.homes[key] and string.format("(%d,%d)", state.homes[key].x, state.homes[key].y) or "none")
  end

  p("")
  local oil = remote.call("hostile-territory-debug", "oil")
  if oil and oil.spot then
    local t = s.get_territory_for_chunk({math.floor(oil.spot.x / 32), math.floor(oil.spot.y / 32)})
    local unit = t and t.get_segmented_units()[1]
    local head = unit and unit.valid and unit.segments[1].position
    p("oil spot (%d,%d), done %s, placed %s, distance to its territory's brain %s", oil.spot.x, oil.spot.y,
      tostring(oil.done), tostring(oil.placed), head and string.format("%.0f", d(oil.spot, head)) or "no brain")
  else
    p("no oil spot")
  end
end

-- B-I10: right after a small area is generated, where do the brains stand? Each should already be on its future
-- base (point or land spot from the noise), mostly in chunks not generated yet.
local function early(s)
  p("== early (tick 62, after 4 chunks around spawn and the first sweep)")
  local on_home, off_home, in_generated = 0, 0, 0
  for _, u in pairs(s.get_segmented_units()) do
    local h = u.segments[1].position
    local c = u.territory.get_chunks()[1]
    local q = s.calculate_tile_properties({"hostile_point_nearest_x", "hostile_point_nearest_y"}, {{c.x * 32 + 16, c.y * 32 + 16}})
    q.elevation = s.calculate_tile_properties({"elevation"}, {{h.x, h.y}}).elevation
    local pt = {x = q.hostile_point_nearest_x[1] + 0.5, y = q.hostile_point_nearest_y[1] + 0.5} -- its territory's point
    local gen = s.is_chunk_generated({math.floor(h.x / 32), math.floor(h.y / 32)})
    early_heads[script.register_on_object_destroyed(u.territory)] = {x = h.x, y = h.y, gen = gen}
    if gen then in_generated = in_generated + 1 end
    -- on its point, or on land 40+ tiles inside its cell in its own territory (a land spot)
    if d(h, pt) < 1 or q.elevation[1] >= 2 then on_home = on_home + 1 else off_home = off_home + 1 end
    p("  %s head (%.0f,%.0f): %.0f tiles from its point, chunk generated %s", u.prototype.name, h.x, h.y, d(h, pt), tostring(gen))
  end
  p("brains: %d on point or land, %d elsewhere; heads in generated chunks: %d", on_home, off_home, in_generated)
  p("")
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 2 then s.request_to_generate_chunks({0, 0}, 4) s.force_generate_chunk_requests() end
  if e.tick == 2 or e.tick == 30 then s.force_generate_chunk_requests() end
  -- after brain.lua's first sweep (tick 60)
  if e.tick == 62 then p("seed %d", s.map_gen_settings.seed) early(s) s.request_to_generate_chunks({0, 0}, 40) end
  if e.tick >= 62 and e.tick < 100 then s.force_generate_chunk_requests() end
  if e.tick ~= 100 then return end
  report(s)
  helpers.write_file("land-test-result.txt", table.concat(out, "\n"))
end)

