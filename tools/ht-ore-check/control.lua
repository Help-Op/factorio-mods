-- Ore per ring (ring2-challenge-plan.md, user 2026-10-25: "less ore since the districts?"). Changes no data.
-- Generates 40 chunks around the origin, then counts resource tiles and amounts per resource and ring (by position),
-- plus how many ore tiles lie under an enemy spawner. Headless, --benchmark-ticks 30. Result: script-output/ore-check-result.txt
local G = 384
local function layer(i) return i >= 0 and i or -i - 1 end
local function ring_of(x, y) return math.max(layer(math.floor(x / G)), layer(math.floor(y / G))) end
script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 2 then s.request_to_generate_chunks({0, 0}, 40) end
  if e.tick >= 2 and e.tick < 20 then s.force_generate_chunk_requests() end
  if e.tick ~= 20 then return end
  local out = {"seed " .. s.map_gen_settings.seed}
  local per = {}
  for _, r in pairs(s.find_entities_filtered{type = "resource", area = {{-1280, -1280}, {1280, 1280}}}) do
    local key = r.name
    per[key] = per[key] or {}
    local ring = ring_of(r.position.x, r.position.y)
    per[key][ring] = per[key][ring] or {tiles = 0, amount = 0}
    per[key][ring].tiles = per[key][ring].tiles + 1
    per[key][ring].amount = per[key][ring].amount + r.amount
  end
  local names = {} for n in pairs(per) do names[#names + 1] = n end table.sort(names)
  for _, n in pairs(names) do
    local parts = {}
    for ring = 0, 3 do
      local v = per[n][ring]
      parts[#parts + 1] = string.format("r%d %d tiles / %.1f M", ring, v and v.tiles or 0, v and v.amount / 1e6 or 0)
    end
    out[#out + 1] = string.format("%-12s %s", n, table.concat(parts, " | "))
  end
  local under = 0
  for _, sp in pairs(s.find_entities_filtered{type = "unit-spawner", area = {{-1280, -1280}, {1280, 1280}}}) do
    under = under + s.count_entities_filtered{type = "resource", area = sp.bounding_box}
  end
  out[#out + 1] = "ore tiles under spawners: " .. under
  helpers.write_file("ore-check-result.txt", table.concat(out, "\n"))
end)
