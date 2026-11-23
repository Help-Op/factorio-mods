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

-- OR-E7 (oil-ring-challenge-plan.md OR-D47): the shield bearer. While one of a surge's bearers lives, the ring-1 brain
-- is shielded (scripts/brain-fight.lua). A big biter (its health and resistances), slower, tinted shield blue.
local bearer_tint1 = {0.3, 0.9, 1, 1} -- the big biter is already blue-violet: cyan to stand out
local bearer_tint2 = {0.9, 1, 1, 0.9}

local bearer = table.deepcopy(data.raw.unit["big-biter"])
bearer.name = "ht-shield-bearer"
bearer.order = "b-a-z"
bearer.factoriopedia_simulation = nil
bearer.movement_speed = bearer.movement_speed * 0.6
bearer.run_animation = biterrunanimation(big_biter_scale, bearer_tint1, bearer_tint2)
bearer.attack_parameters.animation = biterattackanimation(big_biter_scale, bearer_tint1, bearer_tint2)
bearer.icons = {{icon = bearer.icon or "__base__/graphics/icons/big-biter.png", tint = bearer_tint1}}
bearer.icon = nil

data:extend({bearer})

-- OR-E8 E8-B (oil-ring-challenge-plan.md OR-D70, OR-D72, OR-D78): the queen. Nests release her once a nest of the base
-- dies; she walks to a spot near you and spawns small biters (scripts/brain-fight.lua). Big biter health and
-- resistances, 500 HP, slow, drawn at behemoth size in purple (the bearer is the cyan big biter).
local queen_tint1 = {0.65, 0.2, 0.9, 1}
local queen_tint2 = {1, 0.6, 1, 0.9}

local queen = table.deepcopy(data.raw.unit["big-biter"])
queen.name = "ht-queen"
queen.order = "b-a-zz"
queen.factoriopedia_simulation = nil
queen.max_health = 500
queen.distance_per_frame = queen.distance_per_frame * 0.1 / queen.movement_speed -- no sliding run animation
queen.movement_speed = 0.1
queen.run_animation = biterrunanimation(behemoth_biter_scale, queen_tint1, queen_tint2)
queen.attack_parameters.animation = biterattackanimation(behemoth_biter_scale, queen_tint1, queen_tint2)
queen.icons = {{icon = queen.icon or "__base__/graphics/icons/big-biter.png", tint = queen_tint1}}
queen.icon = nil

data:extend({queen})

-- 4e2 (ring2-challenge-plan.md R2-D36, ring-feel RF-D50): the elder queen. The retake army brings her to a fallen
-- district; once your buildings there are gone she settles and the heart is rebuilt (scripts/hive.lua). Kill her and
-- the army retreats. The queen at 1.3 x her size, 2000 HP, in the heart's violet with a gold glow.
local elder_tint1 = {0.55, 0.1, 0.75, 1}
local elder_tint2 = {1, 0.85, 0.3, 0.9}

local elder = table.deepcopy(data.raw.unit["ht-queen"])
elder.name = "ht-elder-queen"
elder.order = "b-a-zzz"
elder.max_health = 2000
elder.distance_per_frame = elder.distance_per_frame * 0.12 / elder.movement_speed
elder.movement_speed = 0.12
elder.run_animation = biterrunanimation(behemoth_biter_scale * 1.3, elder_tint1, elder_tint2)
elder.attack_parameters.animation = biterattackanimation(behemoth_biter_scale * 1.3, elder_tint1, elder_tint2)
elder.icons = {{icon = "__base__/graphics/icons/big-biter.png", tint = elder_tint1}}
-- the engine removes a biter whose commands keep failing; she is the army's key unit, so she stays (hive.lua
-- settles her once she stops getting closer)
elder.ai_settings = elder.ai_settings or {}
elder.ai_settings.destroy_when_commands_fail = false
elder.ai_settings.allow_try_return_to_spawner = false

data:extend({elder})
