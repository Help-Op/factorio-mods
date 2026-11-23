-- Vanilla pollution attacks are cancelled when their group finishes gathering. Each cancelled unit adds its
-- absorptions_to_join_attack pollution to storage.crusade_budget (the vanilla cost of that attack).
-- Expansion (build_base) groups and script-driven groups pass untouched.
-- Expansion parties can still attack player buildings near the spot they settle (vanilla behaviour).
-- POC: cancelled units are removed; phase G will send them to a staging nest instead.

local war = require("scripts.war")
local hive = require("scripts.hive")

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
  local units, pollution, kept = 0, 0, 0
  for _, unit in pairs(group.members) do
    -- the engine also gathers units the mod commands (a retake army, a garrison): they stay (4e2, 2026-11-22)
    if hive.owns(unit) or war.owns(unit) then
      kept = kept + 1
      goto continue
    end
    local cost = unit.prototype.absorptions_to_join_attack
    pollution = pollution + (cost and cost.pollution or 0)
    units = units + 1
    unit.destroy()
    ::continue::
  end
  if group.valid then group.destroy() end
  storage.cancelled_attacks.kept = (storage.cancelled_attacks.kept or 0) + kept
  storage.cancelled_attacks.groups = storage.cancelled_attacks.groups + 1
  storage.cancelled_attacks.units = storage.cancelled_attacks.units + units
  storage.crusade_budget = storage.crusade_budget + pollution
end

-- on_unit_added_to_group: the engine pulls idle units into its own groups (attacks, expansion parties that use their
-- members up to build a nest). Units the mod commands (a retake army, a garrison) leave such a group at once; the
-- army or garrison gives them their next command (4e2, 2026-11-22).
function attacks.on_unit_added_to_group(event)
  local unit, group = event.unit, event.group
  if not (unit and unit.valid and group and group.valid) or group.is_script_driven then return end
  if not (hive.owns(unit) or war.owns(unit)) then return end
  unit.commandable.set_command{type = defines.command.go_to_location, destination = unit.position, radius = 3,
    distraction = defines.distraction.by_enemy}
  init_storage()
  storage.cancelled_attacks.pulled = (storage.cancelled_attacks.pulled or 0) + 1
end

function attacks.describe()
  init_storage()
  return string.format("Cancelled attacks: %d groups, %d units (%d script units kept, %d pulled out of engine groups). Crusade budget: %d pollution.",
    storage.cancelled_attacks.groups, storage.cancelled_attacks.units, storage.cancelled_attacks.kept or 0,
    storage.cancelled_attacks.pulled or 0, storage.crusade_budget)
end

return attacks
