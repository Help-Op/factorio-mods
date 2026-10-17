-- L3 check: compares the enemies on the map with the bases the noise expressions describe.
-- Headless (no players): generates an area on tick 2 and writes script-output/l3-result.txt.
-- In game: /ht-layout-check (only already generated chunks), /ht-layout-nearest (GPS link to the nearest base).

local G = 192
local CHECK_RADIUS = 40 -- chunks, headless only
local PROPS = {"ht_l3_has_base", "ht_l3_cx", "ht_l3_cy", "ht_l3_ring_n", "ht_l3_core_m", "ht_l3_rotation", "ht_l3_base_distance"}

-- all bases whose grid cell centre lies inside the tile box
local function bases_in(surface, x1, y1, x2, y2)
  local positions = {}
  for i = math.floor(x1 / G), math.floor(x2 / G) do
    for j = math.floor(y1 / G), math.floor(y2 / G) do
      positions[#positions + 1] = {(i + 0.5) * G, (j + 0.5) * G}
    end
  end
  local p = surface.calculate_tile_properties(PROPS, positions)
  local bases = {}
  for k = 1, #positions do
    if p.ht_l3_has_base[k] > 0 then
      bases[#bases + 1] = {x = p.ht_l3_cx[k], y = p.ht_l3_cy[k], n = p.ht_l3_ring_n[k], m = p.ht_l3_core_m[k],
                           rot = p.ht_l3_rotation[k], d = p.ht_l3_base_distance[k]}
    end
  end
  return bases
end

local function generated_around(surface, b, r)
  for cx = math.floor((b.x - r) / 32), math.floor((b.x + r) / 32) do
    for cy = math.floor((b.y - r) / 32), math.floor((b.y + r) / 32) do
      if not surface.is_chunk_generated({cx, cy}) then return false end
    end
  end
  return true
end

local function check(surface, x1, y1, x2, y2)
  local out = {}
  local function p(...) out[#out + 1] = string.format(...) end
  local bases = bases_in(surface, x1, y1, x2, y2)
  local area = {{x1, y1}, {x2, y2}}
  local enemies = surface.find_entities_filtered{area = area, type = {"turret", "unit-spawner"}, force = "enemy"}

  local checked, perfect, worms_ok, missing_slots = 0, 0, 0, 0
  local reasons = {}
  local used = {}
  for _, b in pairs(bases) do
    if generated_around(surface, b, 32) then
      checked = checked + 1
      local worms = surface.find_entities_filtered{position = {b.x + 0.5, b.y + 0.5}, radius = 9, type = "turret"}
      local nests = surface.find_entities_filtered{position = {b.x + 0.5, b.y + 0.5}, radius = 23, type = "unit-spawner"}
      for _, e in pairs(worms) do used[e.unit_number] = true end
      for _, e in pairs(nests) do used[e.unit_number] = true end
      if #worms == 1 + b.m then worms_ok = worms_ok + 1 end
      local found = 0
      for s = 0, b.n - 1 do
        local a = s * 2 * math.pi / b.n + b.rot
        local sx, sy = b.x + math.floor(18 * math.cos(a) + 0.5), b.y + math.floor(18 * math.sin(a) + 0.5)
        local hit = surface.find_entities_filtered{position = {sx + 0.5, sy + 0.5}, radius = 1.6, type = "unit-spawner"}
        if #hit > 0 then
          found = found + 1
        else
          missing_slots = missing_slots + 1
          local tile = surface.get_tile(sx, sy)
          local why = tile.collides_with("water_tile") and "water"
            or (#surface.find_entities_filtered{position = {sx + 0.5, sy + 0.5}, radius = 4, type = "cliff"} > 0 and "cliff")
            or ("other (" .. tile.name .. ")")
          reasons[why] = (reasons[why] or 0) + 1
        end
      end
      if found == b.n and #worms == 1 + b.m then perfect = perfect + 1 end
      p("base (%d,%d) d=%.0f worms=%d/%d nests=%d/%d (ring slots found %d)", b.x, b.y, b.d, #worms, 1 + b.m, #nests, b.n, found)
    end
  end

  local stray, in_start = 0, 0
  for _, e in pairs(enemies) do
    if not used[e.unit_number] then stray = stray + 1 end
    if (e.position.x ^ 2 + e.position.y ^ 2) < 384 ^ 2 then in_start = in_start + 1 end
  end
  local r = {}
  for k, v in pairs(reasons) do r[#r + 1] = k .. "=" .. v end
  table.insert(out, 1, string.format(
    "bases described=%d checked (fully generated)=%d perfect=%d core ok=%d | missing ring slots=%d (%s) | enemies=%d stray=%d in starting area=%d",
    #bases, checked, perfect, worms_ok, missing_slots, table.concat(r, ", "), #enemies, stray, in_start))
  return out
end

script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 2 or #game.players > 0 then return end
  local s = game.surfaces.nauvis
  s.request_to_generate_chunks({0, 0}, CHECK_RADIUS)
  s.force_generate_chunk_requests()
  local r = CHECK_RADIUS * 32
  helpers.write_file("l3-result.txt", table.concat(check(s, -r, -r, r, r), "\n"))
end)

commands.add_command("ht-layout-check", "L3: check bases within 1500 tiles of you (generated chunks only)", function(c)
  local player = game.get_player(c.player_index)
  local x, y = player.position.x, player.position.y
  local out = check(player.surface, x - 1500, y - 1500, x + 1500, y + 1500)
  player.print(out[1])
  helpers.write_file("l3-ingame-result.txt", table.concat(out, "\n"))
end)

commands.add_command("ht-layout-nearest", "L3: GPS link to the nearest base", function(c)
  local player = game.get_player(c.player_index)
  local x, y = player.position.x, player.position.y
  local best, bd
  for _, b in pairs(bases_in(player.surface, x - 1000, y - 1000, x + 1000, y + 1000)) do
    local d = (b.x - x) ^ 2 + (b.y - y) ^ 2
    if not bd or d < bd then best, bd = b, d end
  end
  if best then
    player.print(string.format("Nearest base: [gps=%d,%d] %.0f tiles away, %d nests, %d worms", best.x, best.y, math.sqrt(bd), best.n, 1 + best.m))
  else
    player.print("No base within 1000 tiles")
  end
end)
