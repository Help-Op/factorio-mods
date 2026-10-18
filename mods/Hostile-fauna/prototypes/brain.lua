-- B1 (territory-brain-plan.md): the territory brain, the guardian every territory gets (B-D1).
-- A copy of the earth wyrm head (needs earth-wyrm.lua first), three sizes like the wyrms (Q3).
-- Never moves on its own: every speed is 0 (EB3c C1 showed a dormant wyrm still moves when enraged or attacking,
-- so those are 0 too). It still fights back with the wyrm's attacks.
-- Head only (Q2): SEGMENTS = 0 drops the body; set it to 1 to keep the first segment.
-- Placeholder art: the wyrm's tinted vanilla sprites, retinted (placeholders.lua).

local SEGMENTS = 0
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
  local segments = {}
  for i = 1, SEGMENTS do segments[i] = brain.segment_engine.segments[i] end
  brain.segment_engine.segments = segments
  retint(brain, {})
  for _, icon in pairs(brain.icons or {}) do icon.tint = TINT end
  data:extend({brain})
end
