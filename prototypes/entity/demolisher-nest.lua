local nest =
{
  type = "simple-entity",
  name = "demolisher-nest",
  icon = "__base__/graphics/icons/small-biter.png",
  icon_size = 64,
  flags = {"placeable-neutral", "not-on-map"},
  subgroup = "raw-resource",
  order = "z[demolisher-nest]",
  collision_box = {{-1, -1}, {1, 1}},
  selection_box = {{-1, -1}, {1, 1}},
  render_layer = "object",
  pictures =
  {
    {
      filename = "__base__/graphics/icons/small-biter.png",
      width = 64,
      height = 64,
      shift = {0,0}
    }
  }
}

data:extend({nest})
