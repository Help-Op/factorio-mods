-- Weak enemy tier below the small biter, for challenges close to spawn.

require("__base__.prototypes.entity.enemy-constants")
require("__base__.prototypes.entity.biter-animations")

local tiny_scale = small_biter_scale * 0.7
local tiny_tint1 = {0.75, 0.73, 0.66, 1}
local tiny_tint2 = {0.80, 0.72, 0.35, 0.7}

local tiny = table.deepcopy(data.raw.unit["small-biter"])
tiny.name = "ht-tiny-biter"
tiny.max_health = 6
tiny.order = "b-a-0"
tiny.factoriopedia_simulation = nil
tiny.collision_box = {{-0.15, -0.15}, {0.15, 0.15}}
tiny.selection_box = {{-0.3, -0.5}, {0.3, 0.3}}
tiny.run_animation = biterrunanimation(tiny_scale, tiny_tint1, tiny_tint2)
tiny.attack_parameters.animation = biterattackanimation(tiny_scale, tiny_tint1, tiny_tint2)
tiny.water_reflection = biter_water_reflection(tiny_scale)

local effects = tiny.attack_parameters.ammo_type.action.action_delivery.target_effects
if effects.type then effects = {effects} end
for _, effect in pairs(effects) do
  if effect.type == "damage" then effect.damage.amount = effect.damage.amount / 2 end
end

data:extend({tiny})
