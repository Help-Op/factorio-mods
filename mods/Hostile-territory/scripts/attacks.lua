-- Vanilla pollution attacks are cancelled when their group finishes gathering. Each cancelled unit adds its
-- absorptions_to_join_attack pollution to storage.crusade_budget (the vanilla cost of that attack).
-- Expansion (build_base) groups and script-driven groups pass untouched.
-- Expansion parties can still attack player buildings near the spot they settle (vanilla behaviour).
-- POC: cancelled units are removed; phase G will send them to a staging nest instead.

local attacks = {}

attacks.surface_name = "nauvis"

local function init_storage()
  storage.crusade_budget = storage.crusade_budget or 0
  storage.cancelled_attacks = storage.cancelled_attacks or {groups = 0, units = 0}
end

local function contains_command(command, types)
  if not command then return false end
  if types[command.type] then return true end
  if command.type == defines.command.compound then
    for _, sub in pairs(command.commands or {}) do
      if contains_command(sub, types) then return true end
    end
  end
  return false
end

local EXPANSION = {[defines.command.build_base] = true}
local ATTACK = {[defines.command.attack_area] = true, [defines.command.attack] = true}

function attacks.on_unit_group_finished_gathering(event)
  local group = event.group
  if not (group and group.valid) or group.is_script_driven then return end
  if group.surface.name ~= attacks.surface_name then return end
  local command = group.command
  if contains_command(command, EXPANSION) then return end
  if not contains_command(command, ATTACK) then
    log("Hostile-territory: engine group with unknown command type " .. tostring(command and command.type) .. " left alone")
    return
  end

  init_storage()
  local units, pollution = 0, 0
  for _, unit in pairs(group.members) do
    local cost = unit.prototype.absorptions_to_join_attack
    pollution = pollution + (cost and cost.pollution or 0)
    units = units + 1
    unit.destroy()
  end
  if group.valid then group.destroy() end
  storage.cancelled_attacks.groups = storage.cancelled_attacks.groups + 1
  storage.cancelled_attacks.units = storage.cancelled_attacks.units + units
  storage.crusade_budget = storage.crusade_budget + pollution
end

function attacks.describe()
  init_storage()
  return string.format("Cancelled attacks: %d groups, %d units. Crusade budget: %d pollution.",
    storage.cancelled_attacks.groups, storage.cancelled_attacks.units, storage.crusade_budget)
end

return attacks
