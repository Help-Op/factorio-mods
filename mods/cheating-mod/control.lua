-- Test kits. Auto-kit on spawn only with the "cheating-mod-auto-kit" map setting; /cheat-kit [name] and /cheat-clear anytime.
-- The demolisher kit (default) is built for fighting demolishers.
-- Demolisher resistances (space-age enemies.lua): immune to fire, laser and impact;
-- 60% explosion, 50% physical, 20/20% electric, 10% poison. So: railgun, rockets/nukes, tesla.

local QUALITY = "legendary" -- falls back to "normal" when the quality mod is off
local CHART_RADIUS = 480    -- tiles charted around spawn on a new game, enough to see the nearest territories

local HEALTH_BONUS = 2000   -- character max health 250 -> 2250

local armor_equipment =
{
  -- biggest first so auto-placement doesn't fragment the grid.
  -- Legendary mech armor has a 15x17 grid: this uses 235 of 255 cells (6750 shield).
  -- With normal quality (10x12) the list simply stops when the grid is full.
  {"fusion-reactor-equipment", 3},
  {"exoskeleton-equipment", 3},
  {"energy-shield-mk2-equipment", 18},
  {"personal-laser-defense-equipment", 16}, -- useless vs demolishers, but handles challenge biters
  {"personal-roboport-mk2-equipment", 2},
  {"toolbelt-equipment", 1},
  {"battery-mk3-equipment", 8},
}

local guns = {"railgun", "rocket-launcher", "teslagun"}
local ammo = {{"railgun-ammo", 10}, {"explosive-rocket", 100}, {"tesla-ammo", 100}} -- one stack per ammo slot

local main_items =
{
  {"atomic-bomb", 20},
  {"railgun-ammo", 100},
  {"explosive-rocket", 400},
  {"tesla-ammo", 200},
  {"destroyer-capsule", 100},
  {"repair-pack", 100},
  {"raw-fish", 100}, -- heals the character
  {"construction-robot", 50},
  {"tank", 1},
  {"explosive-uranium-cannon-shell", 200},
  {"nuclear-fuel", 10},
}

-- Buildings to place in territories (to trigger demolishers). The player and the spidertron both get these.
local building_items =
{
  {"stone-furnace", 50},
  {"burner-mining-drill", 20},
  {"wooden-chest", 50},
  {"stone-wall", 200},
  {"gun-turret", 20},
  {"firearm-magazine", 200},
  {"transport-belt", 200},
  {"inserter", 50},
  {"small-electric-pole", 50},
  {"solar-panel", 20},
  {"assembling-machine-1", 20},
}

-- Fills the 10x6 grid exactly: reactor 4x4, 3 exoskeletons 2x4, then a 10x2 row of 2x2s.
local spidertron_equipment =
{
  {"fusion-reactor-equipment", 1},
  {"exoskeleton-equipment", 3},
  {"personal-roboport-mk2-equipment", 2},
  {"energy-shield-mk2-equipment", 3},
}

local function quality()
  return prototypes.quality[QUALITY] and QUALITY or "normal"
end

local function fill_grid(grid, list)
  for _, entry in ipairs(list) do
    for _ = 1, entry[2] do
      if not grid.put{name = entry[1], quality = quality()} then break end
    end
  end
  -- start with full shields and batteries instead of waiting for them to charge
  for _, equipment in pairs(grid.equipment) do
    if equipment.max_shield > 0 then equipment.shield = equipment.max_shield end
    if equipment.max_energy > 0 then equipment.energy = equipment.max_energy end
  end
end

local function insert_all(inventory, list)
  for _, entry in ipairs(list) do
    inventory.insert{name = entry[1], count = entry[2], quality = quality()}
  end
end

local function give_spidertron(player)
  local surface = player.character.surface
  local position = surface.find_non_colliding_position("spidertron", player.character.position, 32, 1)
  if not position then return end
  local spider = surface.create_entity{name = "spidertron", position = position, force = player.force, quality = quality()}
  if not spider then return end
  fill_grid(spider.grid, spidertron_equipment)
  spider.get_inventory(defines.inventory.spider_ammo).insert{name = "explosive-rocket", count = 400, quality = quality()}
  -- robots + buildings in the trunk so the spidertron can build ghosts placed far away
  local trunk = spider.get_inventory(defines.inventory.spider_trunk)
  trunk.insert{name = "construction-robot", count = 50, quality = quality()}
  insert_all(trunk, building_items)
  spider.color = player.color
  return spider
end

-- Spidertron remotes only live in the cursor in 2.0, so hand one over already linked to the spider.
local function give_remote(player, spider)
  if not player.clear_cursor() then return end
  player.cursor_stack.set_stack{name = "spidertron-remote"}
  player.spidertron_remote_selection = {spider}
end

-- Tiered kits for weapon-checkpoint tests (Hostile-territory enemy-balancing-plan D19–D23):
-- a plain character (no armor, normal quality) with one gun and its ammo.
local tier_kits =
{
  {name = "pistol",       gun = "pistol",          ammo = {{"firearm-magazine", 200}}},
  {name = "smg-yellow",   gun = "submachine-gun",  ammo = {{"firearm-magazine", 400}}},
  {name = "smg-red",      gun = "submachine-gun",  ammo = {{"piercing-rounds-magazine", 400}}},
  {name = "smg-uranium",  gun = "submachine-gun",  ammo = {{"uranium-rounds-magazine", 200}}},
  {name = "shotgun",      gun = "shotgun",         ammo = {{"shotgun-shell", 200}}},
  {name = "flamethrower", gun = "flamethrower",    ammo = {{"flamethrower-ammo", 100}}},
  {name = "rockets",      gun = "rocket-launcher", ammo = {{"rocket", 200}, {"explosive-rocket", 100}}},
}
local tier_kit_by_name = {}
for _, kit in ipairs(tier_kits) do tier_kit_by_name[kit.name] = kit end

local function kit_names()
  local names = {"demolisher"}
  for _, kit in ipairs(tier_kits) do names[#names + 1] = kit.name end
  return table.concat(names, ", ")
end

-- Back to a bare character: no armor, guns, ammo, items or health bonus.
local function clear_character(player)
  local character = player.character
  if not (character and character.valid) then return false end
  player.clear_cursor()
  for _, id in pairs({defines.inventory.character_armor, defines.inventory.character_guns,
      defines.inventory.character_ammo, defines.inventory.character_main, defines.inventory.character_trash}) do
    local inventory = character.get_inventory(id)
    if inventory then inventory.clear() end
  end
  character.character_health_bonus = 0
  character.health = character.max_health
  return true
end

local function give_tier_kit(player, kit)
  if not clear_character(player) then return false end
  local character = player.character
  character.get_inventory(defines.inventory.character_guns)[1].set_stack{name = kit.gun}
  local ammo_slot = character.get_inventory(defines.inventory.character_ammo)[1]
  ammo_slot.set_stack{name = kit.ammo[1][1], count = kit.ammo[1][2]}
  local main = character.get_main_inventory()
  for i = 2, #kit.ammo do main.insert{name = kit.ammo[i][1], count = kit.ammo[i][2]} end
  -- the ammo slot holds one stack; the rest of the first ammo goes in the main inventory
  local rest = kit.ammo[1][2] - ammo_slot.count
  if rest > 0 then main.insert{name = kit.ammo[1][1], count = rest} end
  player.print("[cheating-mod] Kit '" .. kit.name .. "' delivered (no armor).")
  return true
end

local function give_kit(player)
  local character = player.character
  if not (character and character.valid) then return false end

  -- armor first: mech armor's inventory bonus has to apply before the main inventory fills
  local armor_inventory = character.get_inventory(defines.inventory.character_armor)
  armor_inventory.clear()
  armor_inventory.insert{name = "mech-armor", quality = quality()}
  local armor = armor_inventory[1]
  fill_grid(armor.grid or armor.create_grid(), armor_equipment)
  character.character_health_bonus = HEALTH_BONUS
  character.health = character.max_health

  local gun_inventory = character.get_inventory(defines.inventory.character_guns)
  local ammo_inventory = character.get_inventory(defines.inventory.character_ammo)
  gun_inventory.clear()
  ammo_inventory.clear()
  for i, gun in ipairs(guns) do
    gun_inventory[i].set_stack{name = gun, quality = quality()}
    ammo_inventory[i].set_stack{name = ammo[i][1], count = ammo[i][2], quality = quality()}
  end

  insert_all(character.get_main_inventory(), main_items)
  insert_all(character.get_main_inventory(), building_items)
  local spider = give_spidertron(player)
  if spider then give_remote(player, spider) end
  player.print("[cheating-mod] Demolisher test kit delivered.")
  return true
end

-- Characters don't always exist yet in on_player_created (freeplay intro/cutscene),
-- so players are queued and kitted once they have a character.
-- Only with the "cheating-mod-auto-kit" map setting on; otherwise players start plain (speed/early tests).
local function queue(player_index)
  if not settings.global["cheating-mod-auto-kit"].value then return end
  storage.pending[player_index] = true
end

script.on_init(function()
  storage.pending = {}
  for _, player in pairs(game.players) do queue(player.index) end

  if remote.interfaces["freeplay"] then
    remote.call("freeplay", "set_skip_intro", true)
    remote.call("freeplay", "set_disable_crashsite", true)
    remote.call("freeplay", "set_chart_distance", CHART_RADIUS)
  end

  -- generate the charted area up front (a few seconds' pause on map creation);
  -- otherwise the chunks get generated in the background and the map fills in gradually
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, math.ceil(CHART_RADIUS / 32))
  surface.force_generate_chunk_requests()
end)

script.on_configuration_changed(function()
  storage.pending = storage.pending or {}
end)

script.on_event(defines.events.on_player_created, function(event) queue(event.player_index) end)
script.on_event(defines.events.on_player_respawned, function(event) queue(event.player_index) end)

script.on_nth_tick(30, function()
  for player_index in pairs(storage.pending) do
    local player = game.get_player(player_index)
    if not player or give_kit(player) then
      storage.pending[player_index] = nil
    end
  end
end)

commands.add_command("cheat-kit", "[name] Give yourself a test kit. Kits: " .. kit_names() .. " (default: demolisher).",
  function(command)
    if not command.player_index then return end -- server console
    local player = game.get_player(command.player_index)
    local name = command.parameter and command.parameter:match("^%s*(%S+)") or "demolisher"
    local done
    if name == "demolisher" then
      done = give_kit(player)
    elseif tier_kit_by_name[name] then
      done = give_tier_kit(player, tier_kit_by_name[name])
    else
      player.print("[cheating-mod] Unknown kit '" .. name .. "'. Kits: " .. kit_names() .. ".")
      return
    end
    if not done then player.print("[cheating-mod] You need a character to receive the kit.") end
  end)

commands.add_command("cheat-clear", "Strip your character: no armor, guns, ammo, items or health bonus.", function(command)
  if not command.player_index then return end
  local player = game.get_player(command.player_index)
  if clear_character(player) then
    player.print("[cheating-mod] Character cleared.")
  else
    player.print("[cheating-mod] You need a character to clear.")
  end
end)
