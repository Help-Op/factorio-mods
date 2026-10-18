-- B5: regrowth. Runs after ht-map-check generated the area (tick 2) and HT placed the brains.
local out = {}
local function p(...) out[#out + 1] = string.format(...) end
local function pieces(s, c)
  return s.find_entities_filtered{position = {c.x + 0.5, c.y + 0.5}, radius = 25, type = {"turret", "unit-spawner"}, force = "enemy"}
end
local function key(e) return string.format("%s@%.1f,%.1f", e.name, e.position.x, e.position.y) end

script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 12 then return end
  local s = game.surfaces.nauvis
  local R = "hostile-territory-debug"
  -- 1. a placed brain (head on x.5, y.5) with a full-ish base: knock out 1 worm + 2 nests
  local base
  for _, u in pairs(s.get_segmented_units()) do
    local h = u.segments[1].position
    if h.x % 1 == 0.5 and h.y % 1 == 0.5 then
      local c = {x = math.floor(h.x), y = math.floor(h.y)}
      local list = pieces(s, c)
      local worms, nests = 0, 0
      for _, x in pairs(list) do if x.type == "turret" then worms = worms + 1 else nests = nests + 1 end end
      if worms >= 1 and nests >= 6 then base = {c = c, list = list} break end
    end
  end
  if not base then p("no base found") helpers.write_file("b5-result.txt", table.concat(out, "\n")) return end
  local before, removed = {}, {}
  for _, x in pairs(base.list) do before[key(x)] = true end
  local worm_done, nests_done = false, 0
  for _, x in pairs(base.list) do
    if x.type == "turret" and not worm_done then removed[#removed + 1] = key(x) x.destroy() worm_done = true
    elseif x.type == "unit-spawner" and nests_done < 2 then removed[#removed + 1] = key(x) x.destroy() nests_done = nests_done + 1 end
  end
  p("base at (%d,%d): %d pieces, removed %s", base.c.x, base.c.y, #base.list, table.concat(removed, " "))
  local all0 = {}
  for _, x in pairs(s.find_entities_filtered{type = {"turret", "unit-spawner"}, force = "enemy"}) do all0[key(x)] = x.position end
  local built1 = remote.call(R, "regrow", 1)
  for _, x in pairs(s.find_entities_filtered{type = {"turret", "unit-spawner"}, force = "enemy"}) do
    if not all0[key(x)] then
      local near = s.find_entities_filtered{position = x.position, radius = 3, type = x.type, force = "enemy"}
      local l = {}
      for _, y in pairs(near) do if y ~= x then l[#l + 1] = key(y) end end
      p("  new: %s | same type within 3: %s | tile %s", key(x), table.concat(l, " "), s.get_tile(x.position).name)
    end
  end
  local after1 = pieces(s, base.c)
  local worm_back = false
  for _, x in pairs(after1) do if key(x) == removed[1] then worm_back = true end end
  p("after 1 round: built %d pieces on the whole map; this base %d pieces; the removed worm is back on its tile: %s", built1, #after1, tostring(worm_back))
  local built2 = remote.call(R, "regrow", 2)
  local after = pieces(s, base.c)
  local same = 0
  for _, x in pairs(after) do if before[key(x)] then same = same + 1 end end
  for _, x in pairs(after) do if not before[key(x)] then p("  differs: %s", key(x)) end end
  p("after 3 rounds: built %d more; this base %d pieces, %d of them on exactly the same tile and type as before (want %d)", built2, #after, same, #base.list)
  -- 2. a new brain in a water territory (no unit), on land, as after a lost crusade
  local target
  for _, t in pairs(s.get_territories()) do
    if #t.get_segmented_units() == 0 then
      local chunks = t.get_chunks()
      for _, c in pairs(chunks) do
        if s.is_chunk_generated(c) then
          local pos = s.find_non_colliding_position("ht-rally-small", {c.x * 32 + 16, c.y * 32 + 16}, 8, 1)
          if pos and s.count_tiles_filtered{position = pos, radius = 30, collision_mask = "water_tile"} == 0 then
            local all = true
            for dx = -1, 1 do for dy = -1, 1 do if not s.is_chunk_generated({c.x + dx, c.y + dy}) then all = false end end end
            if all and s.get_territory_for_chunk({x = math.floor(pos.x / 32), y = math.floor(pos.y / 32)}) == t then target = pos break end
          end
        end
      end
    end
    if target then break end
  end
  if target then
    local name = remote.call(R, "place_brain", target.x, target.y)
    local c = {x = math.floor(target.x), y = math.floor(target.y)}
    local before_new = #pieces(s, c)
    local n1 = remote.call(R, "regrow", 1)
    local worms1 = s.count_entities_filtered{position = {c.x + 0.5, c.y + 0.5}, radius = 25, type = "turret", force = "enemy"}
    local n = remote.call(R, "regrow", 20)
    local list = pieces(s, c)
    local worms, nests = 0, 0
    for _, x in pairs(list) do if x.type == "turret" then worms = worms + 1 else nests = nests + 1 end end
    p("new brain %s at (%.1f,%.1f) in a water territory: pieces before %d; after 1 round %d worm(s); after 21 rounds %d worms, %d nests (built %d + %d on the whole map)",
      tostring(name), target.x, target.y, before_new, worms1, worms, nests, n1, n)
  else
    p("no dry spot in a water territory found")
  end
  p("%s", remote.call(R, "brains"))
  helpers.write_file("b5-result.txt", table.concat(out, "\n"))
end)
