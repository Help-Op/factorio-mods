-- EB3b: earth wyrm, the Nauvis replacement for the demolisher (D6). Three sizes, same stats as the demolishers for now (D4).
-- Built with Space Age's global make_demolisher(), which creates the head, segments, corpse and effects
-- (fissures, ash clouds) under our own names. Then every sprite of the new prototypes is tinted earth-brown
-- and glow layers are dropped. The fissure revenge attack and the ash cloud stay as they are for now (Q-EB3b-2/3).
-- Placeholder art: tinted vanilla (placeholders.lua).

local simulations = require("__space-age__.prototypes.factoriopedia-simulations")
local space_age_sounds = require("__space-age__.prototypes.entity.sounds")

local TINT = {0.62, 0.48, 0.34, 1}

local SIZES = {
  -- name suffix, order, scale, damage multiplier, health, regen, speed multiplier (vanilla demolisher values)
  {"small", "s-h-a", 0.5, 1, 30000, 40, 0.55},
  {"medium", "s-h-b", 0.75, 1.5, 100000, 130, 0.6},
  {"big", "s-h-c", 1.0, 2.5, 300000, 400, 0.65},
}

-- A sprite layer has a filename(s) and no volume (sound definitions have filename + volume).
local function is_sprite(t)
  return (t.filename or t.filenames or t.stripes) and t.volume == nil
end

-- make_demolisher() builds some file paths from the unit name (icons: "__space-age__/graphics/icons/<name>.png",
-- "<name>-remains.png"). Those files don't exist for our names: point them back to the vanilla demolisher's.
-- Headless runs don't load graphics, so only the game catches this (2026-10-15).
local function fix_paths(t, name, vanilla, seen)
  if type(t) ~= "table" or seen[t] then return end
  seen[t] = true
  for key, value in pairs(t) do
    if type(value) == "string" and value:find("^__space%-age__/") and value:find(name, 1, true) then
      t[key] = value:gsub(name:gsub("%-", "%%-"), vanilla)
    else
      fix_paths(value, name, vanilla, seen)
    end
  end
end

-- Icons as a tinted icons list.
local function tint_icon(prototype)
  if prototype.icon then
    prototype.icons = {{icon = prototype.icon, icon_size = prototype.icon_size, tint = TINT}}
    prototype.icon = nil
  end
end

-- Tints every sprite layer; drops glow layers from layer lists. The ash cloud keeps its look (Q-EB3b-3).
local function retint(t, seen)
  if type(t) ~= "table" or seen[t] then return end
  seen[t] = true
  if t.layers then
    for i = #t.layers, 1, -1 do
      if type(t.layers[i]) == "table" and t.layers[i].draw_as_glow then table.remove(t.layers, i) end
    end
  end
  if is_sprite(t) and not t.draw_as_shadow then t.tint = TINT end
  for _, value in pairs(t) do retint(value, seen) end
end

for _, size in pairs(SIZES) do
  local name = "hf-earth-wyrm-" .. size[1]
  local sounds = space_age_sounds.demolisher[size[1]]
  make_demolisher(name, size[2], size[3], size[4], size[5], size[6], size[7], nil, sounds)
  for _, prototypes in pairs(data.raw) do
    for proto_name, prototype in pairs(prototypes) do
      if proto_name:sub(1, #name) == name then
        fix_paths(prototype, name, size[1] .. "-demolisher", {})
        if not proto_name:find("ash%-cloud") then
          retint(prototype, {})
          tint_icon(prototype)
        end
      end
    end
  end
end

