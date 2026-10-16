-- data-updates.lua: changes to vanilla prototypes (D1: slow all enemies, D2/D11: player speed).
-- The enemy speed pass comes in EB3.

-- D2/D11: the player outruns most enemies, so a fight can be left (kiting, retreat). Vanilla 0.15 tiles/tick (9 tiles/s).
data.raw.character.character.running_speed = 0.25 -- 15 tiles/s

-- EB3 speed pass (D1, D3, D13): biters slower than the player (0.25). Spitters stay vanilla (already 60–74 %).
-- distance_per_frame shrinks by the same factor, so the run animation doesn't slide.
local BITER_SPEEDS = {
  ["small-biter"] = 0.225,    -- vanilla 0.2,  90 % of the player
  ["medium-biter"] = 0.2,     -- vanilla 0.24, 80 %
  ["big-biter"] = 0.16,       -- vanilla 0.23, 65 %
  ["behemoth-biter"] = 0.125, -- vanilla 0.3,  50 %
}
for name, speed in pairs(BITER_SPEEDS) do
  local unit = data.raw.unit[name]
  unit.distance_per_frame = unit.distance_per_frame * speed / unit.movement_speed
  unit.movement_speed = speed
end
