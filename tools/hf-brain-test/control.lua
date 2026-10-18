local out = {}
local function p(...) out[#out + 1] = string.format(...) end
local start = {}
local brain, char, hp0

local function head(u) return u.segments[1].position end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 2 then
    s.request_to_generate_chunks({0, 0}, 24)
    s.force_generate_chunk_requests()
    local units = s.get_segmented_units()
    local by = {}
    for _, u in pairs(units) do
      by[u.prototype.name] = (by[u.prototype.name] or 0) + 1
      u.minimum_activity_mode = defines.segmented_unit_activity_mode.full
      start[u.unit_number] = head(u)
    end
    local l = {} for n, c in pairs(by) do l[#l + 1] = n .. "=" .. c end
    p("territories=%d segmented units=%d (%s)", #s.get_territories(), #units, table.concat(l, ", "))
    if units[1] then p("segments of first unit: %d (%s)", #units[1].segments, units[1].prototype.name) end
    -- one brain to provoke: the nearest to spawn
    local bd
    for _, u in pairs(units) do
      local h = head(u) local d = h.x ^ 2 + h.y ^ 2
      if not bd or d < bd then brain, bd = u, d end
    end
  elseif e.tick == 600 and brain then
    local h = head(brain)
    char = s.create_entity{name = "character", position = s.find_non_colliding_position("character", {h.x + 15, h.y}, 10, 0.5), force = "player"}
    hp0 = char.health
    brain.damage(100, "player", "physical", char, char)
    p("tick 600: provoked %s at (%.1f,%.1f), character at (%.1f,%.1f) %.0f tiles away, AI state %s",
      brain.prototype.name, h.x, h.y, char.position.x, char.position.y, math.sqrt((char.position.x - h.x) ^ 2 + (char.position.y - h.y) ^ 2), tostring(brain.get_ai_state().type))
  elseif e.tick == 1500 then
    local moved, maxd = 0, 0
    for _, u in pairs(s.get_segmented_units()) do
      local a, b = start[u.unit_number], head(u)
      if a then
        local d = math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
        if d > 0.5 then moved = moved + 1 end
        if d > maxd then maxd = d end
      end
    end
    p("tick 1500 (25 s, all units full activity): moved > 0.5 tiles = %d, max drift = %.2f tiles", moved, maxd)
    if brain and brain.valid then
      local a, b = start[brain.unit_number], head(brain)
      local types = {}
      for k, v in pairs(defines.segmented_unit_ai_state) do types[v] = k end
      p("provoked brain: drift %.2f tiles, AI state %s, character %s", math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2), types[brain.get_ai_state().type] or "?",
        char.valid and string.format("health %.0f / %.0f", char.health, hp0) or "dead")
    end
    helpers.write_file("b1-result.txt", table.concat(out, "\n"))
  end
end)
