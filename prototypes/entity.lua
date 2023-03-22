local config = require("config")
local util = require("util")
local ltnc = flib.copy_prototype(data.raw["constant-combinator"]["constant-combinator"], "cybersyn-constant-combinator")
ltnc.icon = "__cybersyn-cc__/graphics/cybersyn-constant-combinator.png"
ltnc.icon_size = 32
ltnc.icon_mipmaps = nil
ltnc.next_upgrade = nil
ltnc.item_slot_count = config.ltnc_item_slot_count
ltnc.fast_replaceable_group = "constant-combinator"
ltnc.sprites = make_4way_animation_from_spritesheet(
  { layers =
    {
      {
        filename = "__cybersyn-cc__/graphics/cybersyn-constant-combinator.png",
        width = 58,
        height = 52,
        frame_count = 1,
        shift = util.by_pixel(0, 5),
        hr_version = {
          scale = 0.5,
          filename = "__cybersyn-cc__/graphics/hr-cybersyn-constant-combinator.png",
          width = 114,
          height = 102,
          frame_count = 1,
          shift = util.by_pixel(0, 5),
        },
      },
      {
        filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
        width = 50,
        height = 30,
        frame_count = 1,
        shift = util.by_pixel(9,6),
        draw_as_shadow = true,
        hr_version = {
          scale = 0.5,
          filename = "__base__/graphics/entity/combinator/hr-constant-combinator-shadow.png",
          width = 98,
          height = 66,
          frame_count = 1,
          shift = util.by_pixel(8.5, 5.5),
          draw_as_shadow = true,
        },
      },
    },
  }
)

local ltnc_item = flib.copy_prototype(data.raw["item"]["constant-combinator"], "cybersyn-constant-combinator")
ltnc_item.icon = "__cybersyn-cc__/graphics/cybersyn-constant-combinator-item.png"
ltnc_item.icon_size = 64
ltnc_item.icon_mipmaps = 4

local ltnc_recipe = flib.copy_prototype(data.raw["recipe"]["constant-combinator"], "cybersyn-constant-combinator")
ltnc_recipe.ingredients = {
  {"constant-combinator", 1},
  {"electronic-circuit", 1},
}

data:extend({
  ltnc,
  ltnc_item,
  ltnc_recipe,
})
