-- District heart (ring2-challenge-plan.md R2-E1, R2-D23): the big, tanky spawner in the middle of each ring-2+
-- district. Placed by script (scripts/districts.lua), never by map gen. Placeholder art: the biter spawner at
-- SCALE, tinted. Copied in data-final-fixes, so it has every change other mods made to the biter spawner.

require("__base__.prototypes.entity.spawner-animation")

local SCALE = 1.6
local TINT = {0.55, 0.1, 0.75, 0.8} -- violet, the hive's colour (the ring-1 brain is blue-violet)

local function scaled(box) return {{box[1][1] * SCALE, box[1][2] * SCALE}, {box[2][1] * SCALE, box[2][2] * SCALE}} end

local heart = table.deepcopy(data.raw["unit-spawner"]["biter-spawner"])
heart.name = "ht-district-heart"
heart.order = "b-d-z"
heart.autoplace = nil
heart.factoriopedia_simulation = nil
heart.max_health = 3000           -- first guess (Q24); a biter spawner has 350
heart.healing_per_tick = 0.1      -- 6 HP/s
heart.max_count_of_owned_units = 14
heart.max_friends_around_to_spawn = 10
heart.collision_box = scaled(heart.collision_box)
heart.selection_box = scaled(heart.selection_box)
heart.map_generator_bounding_box = scaled(heart.map_generator_bounding_box)
heart.graphics_set.animations = {}
for v = 0, 3 do
  local animation = spawner_idle_animation(v, TINT)
  for _, layer in pairs(animation.layers) do
    layer.scale = layer.scale * SCALE
    if layer.shift then layer.shift = {layer.shift[1] * SCALE, layer.shift[2] * SCALE} end
  end
  heart.graphics_set.animations[#heart.graphics_set.animations + 1] = animation
end

data:extend({heart})
