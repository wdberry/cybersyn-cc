local config = {}
local startup_settings = settings.startup

config.ltnc_ltn_slot_count  = 3
config.ltnc_misc_slot_count = 7 * startup_settings["ltnc-signal-rows"].value
config.ltnc_item_slot_count = config.ltnc_ltn_slot_count + config.ltnc_misc_slot_count

config.cs_signals = {
  ["cybersyn-request-threshold"]  = {default = 0, slot = 1, bounds = {min = 0, max = 2000000000}},
  ["cybersyn-priority"]           = {default = 0, slot = 2, bounds = {min = -2000000000, max = 2000000000}},
  ["cybersyn-locked-slots"]       = {default = 0, slot = 3, bounds = {min = 0, max = 80}},
}


return config
