-- B1 (territory-brain-plan.md): the territory brain, the guardian every territory gets (B-D1).
-- A copy of the earth wyrm head (needs earth-wyrm.lua first), three sizes like the wyrms (Q3).
-- Never moves on its own: every speed is 0 (EB3c C1 showed a dormant wyrm still moves when enraged or attacking,
-- so those are 0 too). It still fights back with the wyrm's attacks.
-- Head only (Q2): SEGMENTS = 0 drops the body; set it to 1 to keep the first segment.
-- Placeholder art: the wyrm's tinted vanilla sprites, retinted (placeholders.lua).

local SEGMENTS = 0

-- CF-D10 (challenge-feel-plan.md): the small brain guards the first ring of territories and must die to ~150 yellow
-- bullets from the player (15 each with CF-D8, halved by the 50 % physical resistance), so no regen.
-- E6 (PT5): 100 bullets (750 HP) let it die before the climax swarm was in full swing.
-- P7 (PT1, 2026-10-18): no lava fissures either (the demolisher's revenge attack); medium and big keep them for now.
local SMALL_HEALTH = 1125
local TINT = {0.75, 0.45, 0.7, 1}

-- Retints every sprite layer (the wyrm's are already tinted earth-brown).
local function retint(t, seen)
  if type(t) ~= "table" or seen[t] then return end
  seen[t] = true
  if (t.filename or t.filenames or t.stripes) and t.volume == nil and not t.draw_as_shadow then t.tint = TINT end
  for _, value in pairs(t) do retint(value, seen) end
end

for _, size in pairs({"small", "medium", "big"}) do
  local brain = table.deepcopy(data.raw["segmented-unit"]["hf-earth-wyrm-" .. size])
  brain.name = "hf-brain-" .. size
  brain.patrolling_speed = 0
  brain.investigating_speed = 0
  brain.attacking_speed = 0
  brain.enraged_speed = 0
  if size == "small" then
    brain.max_health = SMALL_HEALTH
    brain.healing_per_tick = 0
    brain.revenge_attack_parameters = nil
  end
  local segments = {}
  for i = 1, SEGMENTS do segments[i] = brain.segment_engine.segments[i] end
  brain.segment_engine.segments = segments
  retint(brain, {})
  for _, icon in pairs(brain.icons or {}) do icon.tint = TINT end
  data:extend({brain})
end

-- E3 (challenge-feel-plan.md P9, PT2 2026-10-18): the ash cloud ("shockwave") of an enraged brain caps its enemies'
-- speed (demolisher-ash-sticker: max 0.15, the player runs 0.25) but leaves the biters alone, so the climax swarm
-- outran the player. Next to every ash-sticker area in the small brain's effects comes a second area for its own
-- force that slows ground units by ALLY_SLOW (small biter 0.225 → ~0.10). The cloud effects are prototypes of the
-- small earth wyrm (the brain is a copy of its head), so the small wyrm gets it too; it isn't placed any more.
local ALLY_SLOW = 0.45 -- E4 (PT3): 0.5 felt slightly too easy
local ally_sticker = table.deepcopy(data.raw.sticker["demolisher-ash-sticker"])
ally_sticker.name = "hf-ash-sticker-ally"
ally_sticker.target_movement_max = nil
ally_sticker.target_movement_modifier = ALLY_SLOW
data:extend({ally_sticker})

-- a nested-result with an area action that puts demolisher-ash-sticker on what it hits
local function gives_ash_sticker(item)
  if type(item) ~= "table" or item.type ~= "nested-result" or type(item.action) ~= "table" then return false end
  local action = item.action
  if action.type ~= "area" or type(action.action_delivery) ~= "table" then return false end
  for _, effect in pairs(action.action_delivery.target_effects or {}) do
    if effect.type == "create-sticker" and effect.sticker == "demolisher-ash-sticker" then return true end
  end
  return false
end

local function add_ally_slow(t, seen)
  if type(t) ~= "table" or seen[t] then return end
  seen[t] = true
  local copies = {}
  for _, item in ipairs(t) do
    if gives_ash_sticker(item) then
      local copy = table.deepcopy(item)
      copy.action.target_enemies = false
      copy.action.force = "same"
      copy.action.trigger_target_mask = {"ground-unit"}
      copy.action.action_delivery.target_effects = {{type = "create-sticker", sticker = ally_sticker.name}}
      copies[#copies + 1] = copy
    end
  end
  for _, value in pairs(t) do add_ally_slow(value, seen) end
  for _, copy in ipairs(copies) do t[#t + 1] = copy end
end

for _, prototypes in pairs(data.raw) do
  for name, prototype in pairs(prototypes) do
    if name:sub(1, 19) == "hf-earth-wyrm-small" or name == "hf-brain-small" then add_ally_slow(prototype, {}) end
  end
end
