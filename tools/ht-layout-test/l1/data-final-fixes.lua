-- L1: exact shapes from autoplace. Worm at (200, 0), 8 biter spawners on a ring of radius 20.
local CX, CY, R, N = 200, 0, 20, 8

local function hit(px, py)
  return string.format("(floor(x) == %d) * (floor(y) == %d)", px, py)
end

-- all vanilla enemy autoplace off, so only our shapes appear
for _, t in pairs({"unit-spawner", "turret"}) do
  for _, e in pairs(data.raw[t]) do e.autoplace = nil end
end

local ring = {}
for i = 0, N - 1 do
  local a = 2 * math.pi * i / N
  ring[#ring + 1] = hit(math.floor(CX + R * math.cos(a) + 0.5), math.floor(CY + R * math.sin(a) + 0.5))
end

data.raw.turret["medium-worm-turret"].autoplace =
{
  control = "enemy-base",
  force = "enemy",
  order = "!a",
  probability_expression = hit(CX, CY)
}
data.raw["unit-spawner"]["biter-spawner"].autoplace =
{
  control = "enemy-base",
  force = "enemy",
  order = "!b",
  probability_expression = table.concat(ring, " + ")
}
