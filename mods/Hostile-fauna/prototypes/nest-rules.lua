-- Nest rules (D24, D26): one table shared by data and control, readable at runtime via
-- prototypes.mod_data["hf-nest-rules"].data. Other mods (Hostile Territory) may add entries at the data stage.
-- Settler and evolution gating live on the units (buildable_entities, 2.1); this table only covers distance.
-- nests[name] = {min_distance = tiles from spawn, fallback = nest name to swap in when built closer than that}.

data:extend({{
  type = "mod-data",
  name = "hf-nest-rules",
  data = {nests = {}},
}})
