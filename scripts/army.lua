-- Crusade army (phase G, POC): spawned at the staging nest from the crusade cost (V8 b).
-- Mix = the nest's own result_units, weighted at the current evolution (vanilla, G-4).
-- Each unit costs its absorptions_to_join_attack pollution, as in phase E. Capped at MAX_UNITS (G-5).
-- Members go into one script-driven unit group with no command, so they wait at the nest (G0 d).
-- The army is tracked in state.units (our own list): units can drop out of the group (H0 a).

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
      state.units = state.units or {}
      state.units[#state.units + 1] = unit
      spawned = spawned + 1
    end
  end
  state.spawned = (state.spawned or 0) + spawned
  return spawned
end

-- Drops dead units from state.units and returns how many are alive.
function army.alive(state)
  if not state.units then return state.group and state.group.valid and #state.group.members or 0 end
  local alive = {}
  for _, unit in pairs(state.units) do
    if unit.valid then alive[#alive + 1] = unit end
  end
  state.units = alive
  return #alive
end

-- Puts every living unit into a new group at position (the old group is dissolved).
function army.regroup(state, surface, position)
  if state.group and state.group.valid then state.group.destroy() end
  state.group = surface.create_unit_group{position = position, force = "enemy"}
  army.alive(state)
  for _, unit in pairs(state.units or {}) do state.group.add_member(unit) end
  return state.group
end

-- The group's position, or the first living unit's, or nil.
function army.position(state)
  if state.group and state.group.valid and #state.group.members > 0 then return state.group.position end
  army.alive(state)
  local unit = state.units and state.units[1]
  return unit and unit.position
end

-- Removes the living unit closest to position (within max_distance) as a builder. Returns true if one was taken.
function army.take_builder(state, position, max_distance)
  army.alive(state)
  local best, best_i, best_distance
  for i, unit in pairs(state.units or {}) do
    local d = (unit.position.x - position.x) ^ 2 + (unit.position.y - position.y) ^ 2
    if d <= max_distance ^ 2 and (not best_distance or d < best_distance) then best, best_i, best_distance = unit, i, d end
  end
  if not best then return false end
  table.remove(state.units, best_i)
  best.destroy()
  return true
end

-- Moves the count living units closest to position into a new group (a unit can only be in one group).
function army.split(state, surface, count, position)
  army.alive(state)
  local sorted = {}
  for _, unit in pairs(state.units or {}) do
    sorted[#sorted + 1] = {unit = unit, d = (unit.position.x - position.x) ^ 2 + (unit.position.y - position.y) ^ 2}
  end
  table.sort(sorted, function(a, b) return a.d < b.d end)
  local first = sorted[1]
  if not first then return nil end
  local group = surface.create_unit_group{position = first.unit.position, force = "enemy"}
  for i = 1, math.min(count, #sorted) do group.add_member(sorted[i].unit) end
  return group
end

-- Dissolves the group and lets the units go: they stay as normal biters.
function army.release(state)
  if state.group and state.group.valid then state.group.destroy() end
  state.group = nil
  state.units = {}
end

-- Living units whose chunk belongs to the territory.
function army.count_inside(state, surface, territory)
  army.alive(state)
  local count = 0
  for _, unit in pairs(state.units or {}) do
    local p = unit.position
    if surface.get_territory_for_chunk({x = math.floor(p.x / 32), y = math.floor(p.y / 32)}) == territory then
      count = count + 1
    end
  end
  return count
end

function army.destroy_all(state)
  for _, unit in pairs(state.units or {}) do
    if unit.valid then unit.destroy() end
  end
  state.units = {}
  if state.group and state.group.valid then
    for _, unit in pairs(state.group.members) do unit.destroy() end
    if state.group.valid then state.group.destroy() end
  end
end

return army
