--[[
-- Factorio::Signal
--  signal :: SignalID: ID of the signal.
--  count :: int: Value of the signal.
--
-- Factorio::SignalID
--  type :: string: "item", "fluid", or "virtual".
--  name :: string (optional): Name of the item, fluid or virtual signal.
--]]

local config = require "config"

cs_constant_combinator = {
  entity = nil,
  ltn_stop_type = nil,
}

cs_constant_combinator.__index = cs_constant_combinator

function cs_constant_combinator:new(entity)
  if not entity or not entity.valid or entity.name ~= "cybersyn-constant-combinator" then
    print("cs_constant_combinator:new: entity has to be a valid instance of 'cybersyn-constant-combinator'")
    return nil
  end

  local obj = {}
  setmetatable(obj, self)

  obj.entity = entity
  obj:_parse_entity()

  return obj
end

-- cs_constant_combinator:_parse_entity
--  is called upon opening any cybersyn-constant-combinator. Checks if ltn-signals are sorted to
--  their predefined slot, determines ltn stop type and validates signals
function cs_constant_combinator:_parse_entity()
  if not self.entity or not self.entity.valid then return end
  local control = self.entity.get_or_create_control_behavior()

  -- check if signals are sorted correctly
  local need_sorting = false
  for slot = 1, config.ltnc_item_slot_count do
    local signal = control.get_signal(slot)
    if signal.signal ~= nil then
      local type = signal.signal.type
      local name = signal.signal.name

      -- check if its a ltn signal and if its in a correct slot
      if type == "virtual" and config.cs_signals[name] ~= nil then
        need_sorting = config.cs_signals[name].slot ~= slot or need_sorting

        -- remove ltn signals in 1 .. 13 if it equals 0 or default value
        -- signals aren't emitted if 0, and if no signal is present LTN default is used
        if signal.count == config.cs_signals[name].default then
          if name == "ltn-requester-threshold" or name == "ltn-provider-threshold" then
          elseif name == "ltn-network-id" and settings.global["ltnc-emit-default-network-id"].value then
          else
            control.set_signal(slot, nil)
          end
        elseif signal.count == 0 then
          control.set_signal(slot, nil)
        end
      end

      -- check if a non ltn signal is in slot 1..13
      if slot <= config.ltnc_ltn_slot_count and config.cs_signals[name] == nil then
        need_sorting = true
      end
    end
  end

  if need_sorting == true then
    --dlog("ltnc::_parse_entity: combinator needs sorting of signals")
    self:_sort_signal_slots()
  end

end

-- cs_constant_combinator:_has_requests
-- returns true if there are item or fluid signals with negative values indicatind a request for materials
function cs_constant_combinator:_has_requests()
  if not self.entity or not self.entity.valid then return end
  local control = self.entity.get_or_create_control_behavior()
  for i = 1 + config.ltnc_ltn_slot_count, config.ltnc_item_slot_count do
    local signal = control.get_signal(i)
    if signal.signal ~= nil and (signal.signal.type == "item" or signal.signal.type == "fluid") and signal.count < 0 then
       return true
    end
  end
  return false
end

-- cs_constant_combinator:_sort_signal_slots
--  sort ltn signal to their predefined slot and move any non-ltn signals to slot 14 .. 27
function cs_constant_combinator:_sort_signal_slots()
  if not self.entity or not self.entity.valid then return end
  local control = self.entity.get_or_create_control_behavior()

  -- cache all signals
  local previous = {}
  for slot = 1, config.ltnc_item_slot_count do
    local signal = control.get_signal(slot)

    if signal ~= nil and signal.signal ~= nil then
      table.insert(previous, signal)
    end

    control.set_signal(slot, nil)
  end

  -- reassign all signals to a proper slot
  local misc_slot = config.ltnc_ltn_slot_count + 1
  for _, signal in pairs(previous) do
    local type = signal.signal.type
    local name = signal.signal.name

    -- check if its a ltn signal
    if type == "virtual" and config.cs_signals[name] ~= nil then
      control.set_signal(config.cs_signals[name].slot, signal)
    else
      control.set_signal(misc_slot, signal)
      misc_slot = misc_slot + 1
      if misc_slot > config.ltnc_item_slot_count then
        break
      end
    end
  end
end


-- cs_constant_combinator:set_enabled
function cs_constant_combinator:set_enabled(enable)
  if not self.entity or not self.entity.valid then return end
  self.entity.get_or_create_control_behavior().enabled = enable
end

-- cs_constant_combinator:is_enabled
function cs_constant_combinator:is_enabled()
  if not self.entity or not self.entity.valid then return false end
  return self.entity.get_or_create_control_behavior().enabled
end

-- cs_constant_combinator:set
--  @param  signal_name as defined data
--  @param  integer value (32bit signed) for this signal
function cs_constant_combinator:set(signal_name, value)
  if not self.entity or not self.entity.valid then return end
  -- check if its a proper ltn signal
  if not config.cs_signals[signal_name] then
    dlog("cs_constant_combinator:set '" .. tostring(signal_name) .. "' is not a ltn signal")
    return
  end

  local slot   = config.cs_signals[signal_name].slot
  local signal = {
    signal = {
      type = "virtual",
      name = signal_name,
    },
    count = value
  }

  self.entity.get_or_create_control_behavior().set_signal(slot, signal)
end

-- cs_constant_combinator:get
--  @param  a signal name defined by LogisticTrainNetwork
--  returns integer value set in combinator OR default value
function cs_constant_combinator:get(signal_name)
  if not self.entity or not self.entity.valid then return 0 end
  if not config.cs_signals[signal_name] or not self.entity then
    dlog("cs_constant_combinator:set " .. tostring(signal_name) .. " is not a ltn signal")
    return nil
  end

  local signal = self.entity.get_or_create_control_behavior().get_signal(config.cs_signals[signal_name].slot)
  if not signal or not signal.signal then
    signal.count = config.cs_signals[signal_name].default
  end
  return signal.count
end

-- cs_constant_combinator:set_slot
--  @param  slot number (integer: 1 .. 14)
--  @param  signal Factorio::Signal table
function cs_constant_combinator:set_slot(slot, signal)
  if not self.entity or not self.entity.valid then return end
  slot = self:_validate_slot(slot)
  if slot < 1 then return end

  self.entity.get_or_create_control_behavior().set_signal(slot, signal)
end

-- cs_constant_combinator:set_slot_value
--  @param  slot number (integer: 1 .. 14)
--  @param  slot value (integer: 32bit signed)
function cs_constant_combinator:set_slot_value(slot, value)
  if not self.entity or not self.entity.valid then return end
  slot = self:_validate_slot(slot)
  if slot < 1 then return end

  local control = self.entity.get_or_create_control_behavior()

  local signal = control.get_signal(slot)
  if not signal or not signal.signal then return end

  control.set_signal(slot, {signal = signal.signal, count = value})
end

-- cs_constant_combinator:get_slot
--  @param designated slot. integer between 1 .. 14
--  returns table of type Factorio::Signal
function cs_constant_combinator:get_slot(slot)
  if not self.entity or not self.entity.valid then return {signal=nil, count=0} end
  slot = self:_validate_slot(slot)
  if slot < 1 then return end

  return self.entity.get_or_create_control_behavior().get_signal(slot)
end

-- cs_constant_combinator:remove_slot
--  @param designated slot. integer between 1 .. 14
function cs_constant_combinator:remove_slot(slot)
  if not self.entity or not self.entity.valid then return end
  slot = self:_validate_slot(slot)
  if slot < 1 then return end

  self.entity.get_or_create_control_behavior().set_signal(slot, nil)
end

function cs_constant_combinator:_validate_slot(slot)
  if not slot then return -1 end
  slot = slot + config.ltnc_ltn_slot_count

  -- make sure slot is a valid number for a non-ltn signal
  if slot <= config.ltnc_ltn_slot_count or slot > config.ltnc_item_slot_count then
    dlog("Invalid slot number #" .. slot)
    return -1
  end

  return slot
end

--[[
        THIS IS THE END
--]] ----------------------------------------------------------------------------------
