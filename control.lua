MOD_STRING  = "Cybersyn Constant Combinator"

print, dlog = require "script.logger" ()
local on_built = require("script.on_built")
local event = require("__flib__.event")
require("script.gui")
require("script.remote")

-- TODO: Move mod / settings init here


local ev = defines.events
event.register(
  {ev.on_built_entity, ev.on_robot_built_entity, ev.script_raised_built, ev.script_raised_revive},
  on_built.check_built_entity,
  {
    {filter="type", type="constant-combinator"},
    {filter="name", name="cybersyn-constant-combinator", mode="and"}
  }
)