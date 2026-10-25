-- ring2-challenge-plan.md step 3: room for a 150-tile base per ring-2 (and ring-3) territory, for the point offset J
-- of today (0.8) and smaller ones, and where uranium spawns today. Changes no data.
-- Points: read at J = 0.8 from the noise (hostile_point_own_*), the per-cell random offset backed out, then rebuilt
-- for each J in Lua. Territory border = nearest point by Manhattan distance among the 3x3 cells (nauvis-territory.lua).
-- Headless on tick 10 after generating 40 chunks around the origin. Result: script-output/ring2-check-result.txt
local G, J_NOW, R = 384, 0.8, 150
local JS = {0.8, 0.4, 0.2, 0}
local NEST = 3 -- nest half-size: a slot needs this much room past its centre

local function layer(i) return i >= 0 and i or -i - 1 end
local function ring_of_cell(i, j) return math.max(layer(i), layer(j)) end
local function sorted(t) table.sort(t) return t end
local function median(t) local s = sorted(t) return s[math.floor((#s + 1) / 2)] end
local function fmt(n) return string.format("%.0f", n) end

local function analyse(s, out)
  -- per-cell offsets in [-0.5, 0.5], from the J = 0.8 points
  local u, positions, keys = {}, {}, {}
  for i = -7, 6 do
    for j = -7, 6 do
      positions[#positions + 1] = {(i + 0.5) * G, (j + 0.5) * G}
      keys[#keys + 1] = {i, j}
    end
  end
  local p = s.calculate_tile_properties({"hostile_point_own_x", "hostile_point_own_y"}, positions)
  for k, c in pairs(keys) do
    local i, j = c[1], c[2]
    u[i .. "," .. j] = {
      x = (p.hostile_point_own_x[k] - (i + 0.5) * G) / (J_NOW * G),
      y = (p.hostile_point_own_y[k] - (j + 0.5) * G) / (J_NOW * G),
      nx = p.hostile_point_own_x[k], ny = p.hostile_point_own_y[k]}
  end

  -- rebuilt points must match the noise at J = 0.8 (outside the 4 pushed ring-0 cells)
  local bad = 0
  for key, o in pairs(u) do
    local i, j = key:match("(-?%d+),(-?%d+)")
    i, j = tonumber(i), tonumber(j)
    if ring_of_cell(i, j) >= 1 then
      local x = math.floor((i + 0.5) * G + o.x * J_NOW * G + 0.5)
      if math.abs(x - o.nx) > 1 then bad = bad + 1 end
    end
  end
  out[#out + 1] = "rebuild check (J 0.8, ring 1+ cells, off by > 1 tile): " .. bad

  for _, ring in pairs({2, 3}) do
    out[#out + 1] = ""
    out[#out + 1] = string.format("== ring %d, base radius %d (+%d nest)", ring, R, NEST)
    out[#out + 1] = "J    | room worst side: min / median / max over territories | dirs < 153 (of 72), avg | 150-disk outside own territory: avg / worst % | gap to neighbour base: min / median | overlapping pairs"
    for _, J in pairs(JS) do
      local pts = {}
      local function pt(i, j)
        local key = i .. "," .. j
        if not pts[key] then
          local o = u[key]
          pts[key] = {x = math.floor((i + 0.5) * G + o.x * J * G), y = math.floor((j + 0.5) * G + o.y * J * G)}
        end
        return pts[key]
      end
      local function owner(x, y)
        local ci, cj = math.floor(x / G), math.floor(y / G)
        local best, bi, bj = math.huge, nil, nil
        for di = -1, 1 do
          for dj = -1, 1 do
            local q = pt(ci + di, cj + dj)
            local d = math.abs(x - q.x) + math.abs(y - q.y)
            if d < best then best, bi, bj = d, ci + di, cj + dj end
          end
        end
        return bi, bj
      end
      local mins, shorts, clips, gaps, overlaps = {}, 0, {}, {}, 0
      local seen = {}
      for i = -6, 5 do
        for j = -6, 5 do
          if ring_of_cell(i, j) == ring then
            local o = pt(i, j)
            -- room per direction
            local worst = math.huge
            for a = 0, 71 do
              local ang = a * 2 * math.pi / 72
              local c, sn, r = math.cos(ang), math.sin(ang), 0
              while r < 300 do
                local oi, oj = owner(o.x + r * c, o.y + r * sn)
                if oi ~= i or oj ~= j then break end
                r = r + 1
              end
              worst = math.min(worst, r)
              if r < R + NEST then shorts = shorts + 1 end
            end
            mins[#mins + 1] = worst
            -- share of the 150-disk owned by another territory
            local n, outside = 0, 0
            for x = -R, R, 3 do
              for y = -R, R, 3 do
                if x * x + y * y <= R * R then
                  n = n + 1
                  local oi, oj = owner(o.x + x, o.y + y)
                  if oi ~= i or oj ~= j then outside = outside + 1 end
                end
              end
            end
            clips[#clips + 1] = 100 * outside / n
            -- gap to the neighbouring bases (any ring), each pair once
            for di = -1, 1 do
              for dj = -1, 1 do
                if di ~= 0 or dj ~= 0 then
                  local a, b = i .. "," .. j, (i + di) .. "," .. (j + dj)
                  local pair = a < b and a .. "|" .. b or b .. "|" .. a
                  if not seen[pair] then
                    seen[pair] = true
                    local q = pt(i + di, j + dj)
                    local g = math.sqrt((o.x - q.x) ^ 2 + (o.y - q.y) ^ 2) - 2 * R
                    gaps[#gaps + 1] = g
                    if g < 0 then overlaps = overlaps + 1 end
                  end
                end
              end
            end
          end
        end
      end
      local cs, csum = sorted(clips), 0
      for _, c in pairs(cs) do csum = csum + c end
      local ms = sorted(mins)
      out[#out + 1] = string.format("%-4s | %s / %s / %s | %d, %.1f per territory | %.1f / %.1f | %s / %s | %d of %d",
        tostring(J), fmt(ms[1]), fmt(median(mins)), fmt(ms[#ms]), shorts, shorts / #mins,
        csum / #cs, cs[#cs], fmt(sorted(gaps)[1]), fmt(median(gaps)), overlaps, #gaps)
    end
  end

  -- land inside the 150-disk around the cell centre (J = 0; terrain doesn't depend on J)
  out[#out + 1] = ""
  out[#out + 1] = "== ring 2: land share of the 150-disk around the cell centre (elevation >= 0)"
  local lands = {}
  for i = -6, 5 do
    for j = -6, 5 do
      if ring_of_cell(i, j) == 2 then
        local cx, cy, ps = (i + 0.5) * G, (j + 0.5) * G, {}
        for x = -R, R, 6 do
          for y = -R, R, 6 do
            if x * x + y * y <= R * R then ps[#ps + 1] = {cx + x, cy + y} end
          end
        end
        local land = 0
        for _, e in pairs(s.calculate_tile_properties({"elevation"}, ps).elevation) do
          if e >= 0 then land = land + 1 end
        end
        lands[#lands + 1] = math.floor(100 * land / #ps + 0.5)
      end
    end
  end
  out[#out + 1] = "per territory %: " .. table.concat(sorted(lands), " ")

  -- uranium today
  out[#out + 1] = ""
  out[#out + 1] = "== uranium (generated square +-1280)"
  local ores = s.find_entities_filtered{name = "uranium-ore", area = {{-1280, -1280}, {1280, 1280}}}
  local patches = {}
  for _, o in pairs(ores) do
    local hit
    for _, q in pairs(patches) do
      if (q.x - o.position.x) ^ 2 + (q.y - o.position.y) ^ 2 < 40 ^ 2 then hit = q break end
    end
    if hit then hit.n, hit.amount = hit.n + 1, hit.amount + o.amount
    else patches[#patches + 1] = {x = o.position.x, y = o.position.y, n = 1, amount = o.amount} end
  end
  local where = {}
  for _, q in pairs(patches) do where[#where + 1] = {q.x, q.y} end
  local rings = #where > 0 and s.calculate_tile_properties({"hostile_point_ring", "hostile_point_nearest_x", "hostile_point_nearest_y"}, where) or {}
  local per = {}
  for k, q in pairs(patches) do
    q.d = math.sqrt(q.x * q.x + q.y * q.y)
    q.ring = rings.hostile_point_ring[k]
    q.brain = math.sqrt((q.x - rings.hostile_point_nearest_x[k]) ^ 2 + (q.y - rings.hostile_point_nearest_y[k]) ^ 2)
    if q.d < 150 then q.ring = "safe" end
    local key = "r" .. tostring(q.ring)
    per[key] = per[key] or {n = 0, amount = 0}
    per[key].n, per[key].amount = per[key].n + 1, per[key].amount + q.amount
  end
  table.sort(patches, function(a, b) return a.d < b.d end)
  out[#out + 1] = string.format("%d ore tiles, %d patches", #ores, #patches)
  local keys2 = {} for k in pairs(per) do keys2[#keys2 + 1] = k end table.sort(keys2)
  for _, k in pairs(keys2) do
    out[#out + 1] = string.format("  %s: %d patches, %.1f M ore", k, per[k].n, per[k].amount / 1e6)
  end
  out[#out + 1] = "nearest first (distance from origin, ring, tiles, distance to its brain):"
  for k = 1, math.min(10, #patches) do
    local q = patches[k]
    out[#out + 1] = string.format("  %s  ring %s  %d tiles  brain %s", fmt(q.d), tostring(q.ring), q.n, fmt(q.brain))
  end
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 2 then s.request_to_generate_chunks({0, 0}, 40) s.force_generate_chunk_requests() end
  if e.tick ~= 10 then return end
  local out = {"seed " .. s.map_gen_settings.seed}
  analyse(s, out)
  helpers.write_file("ring2-check-result.txt", table.concat(out, "\n"))
end)
