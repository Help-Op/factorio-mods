-- EB2 engine tests: one test unit per uncertain lever (Hostile-territory/enemy-balancing-plan.md, EB2).
-- Copies of vanilla units with one change each and their own tint. Speeds stay vanilla (EB3 does speed).
-- Not in any spawner, hidden from Factoriopedia. Removed or promoted to real units after EB2.

-- vanilla animation helpers and constants are globals (the linter doesn't know them); requiring again is harmless
require("__base__.prototypes.entity.enemy-constants")
require("__base__.prototypes.entity.biter-animations")
require("__base__.prototypes.entity.spitter-animations")

local function copy(base_name, name, tint)
  local unit = table.deepcopy(data.raw.unit[base_name])
  unit.name = name
  unit.localised_name = name
  unit.hidden_in_factoriopedia = true
  unit.factoriopedia_simulation = nil
  unit.buildable_entities = nil -- never settles
  unit.order = "z-hf-test-" .. name
  unit.icons = {{icon = unit.icon, tint = tint}}
  unit.icon = nil
  return unit
end

local function retint_spitter(unit, scale, tint1, tint2)
  unit.run_animation = spitterrunanimation(scale, tint1, tint2)
  unit.attack_parameters.animation = spitterattackanimation(scale, tint1, tint2)
end

local function retint_biter(unit, scale, tint1, tint2)
  unit.run_animation = biterrunanimation(scale, tint1, tint2)
  unit.attack_parameters.animation = biterattackanimation(scale, tint1, tint2)
end

-- Kiter (green): backs away when the target is closer than min_range, then spits.
local kiter = copy("medium-spitter", "hf-test-kiter", {0.2, 0.8, 0.2, 1})
retint_spitter(kiter, scale_spitter_medium, {0.2, 0.8, 0.2, 1}, {0.1, 0.5, 0.1, 0.8})
kiter.attack_parameters.range = 14
kiter.attack_parameters.min_attack_distance = 12
kiter.attack_parameters.min_range = 8

-- Strafer (cyan): circles the target at ~10 tiles (strafe_settings, vanilla only on spider-units).
local strafer = copy("medium-spitter", "hf-test-strafer", {0.2, 0.8, 0.9, 1})
retint_spitter(strafer, scale_spitter_medium, {0.2, 0.8, 0.9, 1}, {0.1, 0.4, 0.6, 0.8})
strafer.ai_settings = strafer.ai_settings or {}
strafer.ai_settings.strafe_settings = {ideal_distance = 10, max_distance = 16, face_target = true}

-- Thorns (yellow): any attacker within 4 tiles takes 15 physical damage back, per hit.
-- No damage_type filter, so fire (flamethrower) triggers it too.
local thorns = copy("big-biter", "hf-test-thorns", {0.9, 0.8, 0.1, 1})
retint_biter(thorns, big_biter_scale, {0.9, 0.8, 0.1, 1}, {0.7, 0.5, 0.1, 0.7})
thorns.attack_reaction = {{
  range = 4,
  action = {
    type = "direct",
    action_delivery = {
      type = "instant",
      target_effects = {type = "damage", damage = {amount = 15, type = "physical"}},
    },
  },
}}

-- Splitter (magenta): dies into 4 small biters.
local splitter = copy("medium-biter", "hf-test-splitter", {0.9, 0.2, 0.8, 1})
retint_biter(splitter, medium_biter_scale, {0.9, 0.2, 0.8, 1}, {0.6, 0.1, 0.5, 0.7})
local spawns = {}
for _, offset in pairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
  spawns[#spawns + 1] = {type = "create-entity", entity_name = "small-biter", offsets = {offset},
    find_non_colliding_position = true, as_enemy = true}
end
splitter.dying_trigger_effect = spawns

data:extend({kiter, strafer, thorns, splitter})

-- EB2c expansion test: settler a only builds nest a; settler b builds nest a once, nest b twice (weights?).
-- Nests are plain copies without autoplace, so map gen never places them.
local function test_nest(base_name, name)
  local nest = table.deepcopy(data.raw["unit-spawner"][base_name])
  nest.name = name
  nest.localised_name = name
  nest.hidden_in_factoriopedia = true
  nest.factoriopedia_simulation = nil
  nest.autoplace = nil
  nest.order = "z-hf-test-" .. name
  return nest
end

local settler_a = copy("small-biter", "hf-test-settler-a", {1, 0.5, 0, 1})
settler_a.buildable_entities = {"hf-test-nest-a"}
local settler_b = copy("small-biter", "hf-test-settler-b", {0, 0.5, 1, 1})
settler_b.buildable_entities = {"hf-test-nest-a", "hf-test-nest-b", "hf-test-nest-b"}

data:extend({settler_a, settler_b, test_nest("biter-spawner", "hf-test-nest-a"), test_nest("spitter-spawner", "hf-test-nest-b")})
