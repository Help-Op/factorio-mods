-- Crusade army (phase G, POC): spawned at the staging nest from the crusade cost (V8 b).
-- Mix = the nest's own result_units, weighted at the current evolution (vanilla, G-4).
-- Each unit costs its absorptions_to_join_attack pollution, as in phase E. Capped at MAX_UNITS (G-5).
-- Members go into one script-driven unit group with no command, so they wait at the nest (G0 d).

local army = {}

army.MAX_UNITS = 200
local SPAWN_RADIUS = 30

local function weight_at(spawn_points, evolution)
  local points = {}
  for _, point in pairs(spawn_points) do points[#points + 1] = point end
  table.sort(points, function(a, b) return a.evolution_factor < b.evolution_factor end)
  if evolution <= points[1].evolution_factor then return points[1].weight end
  for i = 2, #points do
    local a, b = points[i - 1], points[i]
    if evolution <= b.evolution_factor then
      return a.weight + (b.weight - a.weight) * (evolution - a.evolution_factor) / (b.evolution_factor - a.evolution_factor)
    end
  end
  return points[#points].weight
end

local function unit_cost(name)
  local cost = prototypes.entity[name].absorptions_to_join_attack
  return cost and cost.pollution or 0
end

-- Returns a list of unit names and the pollution they cost in total.
function army.plan(nest_name, evolution, budget)
  local options = {}
  for _, definition in pairs(prototypes.entity[nest_name].result_units) do
    local weight = weight_at(definition.spawn_points, evolution)
    local cost = unit_cost(definition.unit)
    if weight > 0 and cost > 0 then options[#options + 1] = {name = definition.unit, weight = weight, cost = cost} end
  end

  local units, spent = {}, 0
  while #units < army.MAX_UNITS do
    local affordable, total = {}, 0
    for _, option in pairs(options) do
      if option.cost <= budget - spent then
        affordable[#affordable + 1] = option
        total = total + option.weight
      end
    end
    if #affordable == 0 then break end
    local roll = math.random() * total
    local pick = affordable[#affordable]
    for _, option in ipairs(affordable) do
      roll = roll - option.weight
      if roll <= 0 then pick = option break end
    end
    units[#units + 1] = pick.name
    spent = spent + pick.cost
  end
  return units, spent
end

-- Spawns up to count units from state.queue at the nest into state.group. Returns how many were spawned.
function army.spawn_batch(state, surface, count)
  if not (state.group and state.group.valid) then
    state.group = surface.create_unit_group{position = state.nest_position, force = "enemy"}
  end
  local spawned = 0
  while spawned < count and state.next_unit <= #state.queue do
    local name = state.queue[state.next_unit]
    state.next_unit = state.next_unit + 1
    local position = surface.find_non_colliding_position(name, state.nest_position, SPAWN_RADIUS, 0.5)
    local unit = position and surface.create_entity{name = name, position = position, force = "enemy"}
    if unit then
      state.group.add_member(unit)
      spawned = spawned + 1
    end
  end
  state.spawned = (state.spawned or 0) + spawned
  return spawned
end

function army.alive(state)
  return state.group and state.group.valid and #state.group.members or 0
end

return army
