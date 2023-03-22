local me = {}
local config = require("config")
local signals = config.ltn_signals
local gsettings = settings.global

function me.check_built_entity(event)
  local built_entity = event.created_entity or event.entity
  if not built_entity then return end

  local ltnc = cs_constant_combinator:new(built_entity)
  if not ltnc then return end
  if gsettings["ltnc-disable-built-combinators"].value == "all" then
    ltnc:set_enabled(false)
  end
end

return me
