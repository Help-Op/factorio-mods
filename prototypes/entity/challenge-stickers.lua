-- Invisible, effectively permanent slowdown stickers for challenge units: ht-challenge-slow-10 ... -50.

local stickers = {}
for percent = 10, 50, 10 do
  stickers[#stickers + 1] = {
    type = "sticker",
    name = "ht-challenge-slow-" .. percent,
    flags = {"not-on-map"},
    duration_in_ticks = 4000000000, -- uint32, about 2 years of game time
    target_movement_modifier = 1 - percent / 100,
  }
end

data:extend(stickers)
