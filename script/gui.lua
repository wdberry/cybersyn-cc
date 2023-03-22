local gui = require("lib.gui")
local event = require("__flib__.event")
local table = require("__flib__.table")
--local migration = require("__flib__.migration")

local config = require "config"
local ltnc_util = require("script.util")
require("script.cybersyn-constant-combinator")

local ltnc_gui = {}

-- Forward delcaration
local create_window

-------------------------
--  Handlers
-------------------------

--- Update the non-LTN signals emited by the combinator.
local function update_signal_table(ltnc, slot, signal)
  dlog("update_signal_table")
  if signal and signal.signal then
    local b = ltnc.signals[slot].button
    local type = signal.signal.type == "virtual" and "virtual-signal" or signal.signal.type
    b.elem_value = signal.signal
    b.children[1].caption = ltnc_util.format_number(signal.count, true)
    b.locked = true
  end
end -- update_signal_table()

--- Update the LTN signals emited by the combinator
local function update_cs_signals(ltnc)
for name, details in pairs(config.cs_signals) do
  local value = ltnc.combinator:get(name)
    local elem = ltnc["ltnc-element__"..name]
    if  elem then
      if elem.type == "checkbox" then
        elem.state = (value > 0 and true or false)
      else
        elem.text = tostring(value)
      end
    end
  end
end -- update_ltn_signals()

local function set_new_signal_value(ltnc, value, min, max)
  local new_value = ltnc_util.clamp(value, min, max)
  ltnc.combinator:set_slot_value(ltnc.selected_slot, new_value)
  ltnc.signal_value_slider.enabled = false
  ltnc.signal_value_text.enabled = false
  ltnc.signal_value_stack.enabled = false
  ltnc.signal_value_confirm.enabled = false
  ltnc.signals[ltnc.selected_slot].button.children[1].caption = ltnc_util.format_number(new_value, true)
  ltnc.selected_slot = nil
  ltnc.stack_size = nil
end -- set_new_signal_value()

-- Display the Net Config UI
-- function ltnc_gui.Open_Netconfig(player_index)
--   dlog("gui.lua Netconfig")
--   local player = game.get_player(player_index)
--   local rootgui = player.gui.screen
--   if rootgui["ltnc-net-config"] then
--     ltnc_gui.Close(player_index, "ltnc-net-config")
--   end
  
--   local netconfig = create_net_config(player_index)
--   for i = 1, 32 do
--     local gnd = global.network_description[i]
--     local gni = gnd.icon
--     if gni ~= nil then
--       if gni.type ~= nil and gni.name ~= nil then
--         local type = gni.type
--         local name = gni.name
--         local path = (type .. "/" .. name)
--         if netconfig.netconfig_table.gui.is_valid_sprite_path(path) then
--           local signal = {
--             type = type == "virtual-signal" and "virtual" or type,
--             name = name
--           }
--           netconfig.netconfig_table.children[i].children[2].elem_value = signal
--         end
--       end
--     end
--   end

--   local pd = ltnc_util.get_player_data(player_index)
--   pd.netconfig = netconfig
-- end -- Open_Netconfig()

-- Display the GUI for the player
function ltnc_gui.Open(player_index, entity)
  dlog("gui.lua: Open")
  --[[
      Check if player has an LTN Combinator open.
      If the player is trying to open the same LTN Combinator do nothing.
      If a different LTN Combinator, first close the open one, then open the new one.
      If opening something else, close the open LTN Combinator.
  ]]
  local player = game.get_player(player_index)
  local rootgui = player.gui.screen
  if rootgui["ltnc-main-window"] then
    if rootgui["ltnc-main-window"].tags.unit_number  == entity.unit_number then
      player.opened = rootgui["ltnc-main-window"]
      return
    end
    ltnc_gui.Close(player_index)
  end
  local ltnc = create_window(player_index, entity.unit_number)
  ltnc.ep.entity = entity

  -- Create an object to hold an interface with combinator entity
  ltnc.combinator = cs_constant_combinator:new(entity)
  if not ltnc.combinator then
    dlog("Failed to create LTN-C object")
  end

  -- read stop type and set checkboxes
  --update_visible_components(ltnc, player_index)

  -- read on/off switch
  ltnc.on_off.switch_state = ltnc.combinator:is_enabled() and "right" or "left"

  -- read and update other signals
  for slot = 1, config.ltnc_misc_slot_count do
    local signal = ltnc.combinator:get_slot(slot)
    update_signal_table(ltnc, slot, signal)
  end

  -- read and setup the network ID Configurator
  -- local networkid = ltnc.combinator:get("ltn-network-id")
  -- update_net_id_buttons(ltnc, networkid)

  local pd = ltnc_util.get_player_data(player_index)
  pd.ltnc = ltnc

  player.opened = pd.ltnc.main_window

end -- Open()

function ltnc_gui.Close(player_index, name)
  dlog("gui.lua: Close")
  local window = name or "ltnc-main-window"
  local player = game.get_player(player_index)
  local rootgui = player.gui.screen
  if window and rootgui[window] then
    rootgui[window].destroy()
    if window == "ltnc-main-window" then
      gui.update_filters("ltnc_handlers", player_index, nil, "remove")
      --ltnc_gui.Close(player_index, "ltnc-net-config")
      --ltnc_gui.Close(player_index, "ltnc-net-dialog")
      local pd = global.player_data[player_index]
      pd.ltnc.combinator:_parse_entity()
      pd.ltnc = nil
    end
  end
  -- TODO: Figuire out how to play close sound
end -- Close()

local function change_signal_count(ltnc, e)
  local slot = ltnc.selected_slot
  local signal = ltnc.combinator:get_slot(slot)
  if not signal or not signal.signal then
    ltnc_gui.Close(e.player_index)
    return
  end

  local value = signal.count
  dlog(signal.signal.type)
  local slider_type
  ltnc.signal_value_text.enabled = true
  ltnc.signal_value_text.text = tostring(value)
  ltnc.signal_value_text.focus()
  ltnc.signal_value_confirm.enabled = false
  if signal.signal.type == "item" or signal.signal.type == "fluid" then
    local stack_size
    if signal.signal.type == "item" then
      slider_type = "ltnc-slider-max-items"
      stack_size = game.item_prototypes[signal.signal.name].stack_size
      ltnc.signal_value_stack.enabled = true
      if settings.get_player_settings(e.player_index)["ltnc-use-stacks"].value then
        ltnc.signal_value_stack.focus()
      end
    elseif signal.signal.type == "fluid" then
      slider_type = "ltnc-slider-max-fluid"
      stack_size = 1 --Fluid doesn't have stacks
      ltnc.signal_value_stack.enabled = false
    end
    local max_slider = stack_size * settings.get_player_settings(e.player_index)[slider_type].value
    ltnc.signal_value_stack.text = tostring(value/stack_size)
    ltnc.signal_value_slider.set_slider_minimum_maximum(0,max_slider)
    ltnc.signal_value_slider.set_slider_value_step(stack_size)
    ltnc.signal_value_slider.enabled = true
    ltnc.signal_value_slider.slider_value = 0
    ltnc.signal_value_slider.slider_value = math.abs(value)
    ltnc.stack_size = stack_size
  else
    -- Not Item or Fluid
    ltnc.signal_value_stack.enabled = false
    ltnc.signal_value_slider.enabled = false
    ltnc.stack_size = 1 -- Other signals don't have stacks
  end
end -- change_signal_count()

function ltnc_gui.RegisterTemplates()
  gui.add_templates{
    drag_handle = {type="empty-widget", style="flib_titlebar_drag_handle", elem_mods={ignored_by_interaction=true}},
    frame_action_button = {type="sprite-button", style="frame_action_button", mouse_button_filter={"left"}},
    ltnc_entry_text = {
      type="textfield", style="short_number_textfield",
      style_mods={
        horizontal_align="right",
        horizontally_stretchable="off"
      },
      lose_focus_on_confirm=true,
      clear_and_focus_on_right_click=true,
    },
    confirm_button = {template="frame_action_button", style="item_and_count_select_confirm", sprite="utility/check_mark"},
    cancel_button = {template="frame_action_button", style="red_button", style_mods={size=28, padding=0, top_margin=1}, sprite="utility/close_white"},
    close_button = {template="frame_action_button", sprite="utility/close_white", hovered_sprite="utility/close_black"},
    checkbox = {type="checkbox", state=false, style_mods={top_margin=8}},
  }
end -- RegisterTemplates()

function ltnc_gui.RegisterHandlers()
  gui.add_handlers{
    ltnc_handlers = {
      close_button = {
        on_gui_click = function(e)
          ltnc_gui.Close(e.player_index)
        end -- on_gui_click
      },
      slider = {

        --TODO: validate signal type for negativity
        on_gui_value_changed = function(e)
          local ltnc = global.player_data[e.player_index].ltnc
          ltnc.signal_value_confirm.enabled = true
          ltnc.signal_value_text.text = tostring(e.element.slider_value * -1)
          ltnc.signal_value_stack.text = (tostring((e.element.slider_value * -1) / ltnc.stack_size))
        end
      },
      signal_text = {
        --TODO: validate signal type for negativity
        on_gui_text_changed = function(e)
          local value = tonumber(e.element.text)
          if not value then return end
          local ltnc = global.player_data[e.player_index].ltnc
          ltnc.signal_value_confirm.enabled = true
          if e.element.name == "signal_value" then
            ltnc.signal_value_slider.slider_value = math.abs(value)
            local stack = value / ltnc.stack_size
            ltnc.signal_value_stack.text = tostring(stack >=0 and math.ceil(stack) or math.floor(stack))
          elseif e.element.name == "signal_stack" then
            ltnc.signal_value_slider.slider_value = math.abs(value * ltnc.stack_size)
            ltnc.signal_value_text.text = tostring(value * ltnc.stack_size)
          end
        end,
        on_gui_confirmed = function(e)
          local ltnc = global.player_data[e.player_index].ltnc
          if not ltnc.selected_slot then return end
          local value = tonumber(ltnc.signal_value_text.text)
          if not value then return end
          local type = ltnc.combinator:get_slot(ltnc.selected_slot).signal.type
          if value > 0 and (type == "item" or type == "fluid") then
            value = value * -1
          end
          local min = -2^31
          local max = 2^31-1
          set_new_signal_value(ltnc, value, min, max)
        end
      },
      confirm_button = {
        on_gui_click = function(e)
          local ltnc = global.player_data[e.player_index].ltnc
          if not ltnc.selected_slot then return end
          local value = tonumber(ltnc.signal_value_text.text)
          if not value then return end
          local min = -2^31
          local max = 2^31-1
          set_new_signal_value(ltnc, value, min, max)
        end
      },
      choose_button = {
        on_gui_elem_changed = function(e)
          local bad = {"signal-each", "signal-anything", "signal-everything"}
          if e.element.elem_value == nil or e.element.elem_value.name == nil then
            e.element.elem_value = nil
            return
          elseif table.find(bad, e.element.elem_value.name) then
            print({"ltnc.bad-signal", e.element.elem_value.name})
            e.element.elem_value = nil
            return
          end
          dlog("choose_button - on_gui_elem_changed - "..e.element.elem_value.name)
          local ltnc = global.player_data[e.player_index].ltnc
          local _, _, slot =  string.find(e.element.name, "__(%d+)")
          slot = tonumber(slot)
          ltnc.selected_slot = slot
          local signal = {signal=e.element.elem_value, count=0}
          ltnc.combinator:set_slot(slot, signal)
          e.element.locked = true
          change_signal_count(ltnc, {
            button=defines.mouse_button_type.left,
            element={number=0},
            player_index=e.player_index
          })
        end,
        on_gui_click = function(e)
          dlog("choose_button - on_gui_click: "..e.button)
          local ltnc = global.player_data[e.player_index].ltnc
          local _, _, slot =  string.find(e.element.name, "__(%d+)")
          slot = tonumber(slot)
          if e.button == defines.mouse_button_type.right then
            ltnc.combinator:remove_slot(slot)
            e.element.locked = false
            e.element.elem_value = nil
            e.element.children[1].caption = ""
            if ltnc.selected_slot == slot then
              ltnc.signal_value_confirm.enabled = false
              ltnc.signal_value_text.enabled = false
              ltnc.signal_value_stack.enabled = false
              ltnc.signal_value_slider.enabled = false
            end
          elseif e.button == defines.mouse_button_type.left and e.element.elem_value then
            ltnc.selected_slot = slot
            change_signal_count(ltnc, e)
          end
        end
      },
      on_off_switch = {
        on_gui_switch_state_changed = function(e)
          local ltnc = global.player_data[e.player_index].ltnc
          ltnc.combinator:set_enabled(e.element.switch_state == "right")
        end
      },
      cs_signal_entries = {
        on_gui_text_changed = function(e)
          dlog(e.element.name)
          if not tonumber(e.element.text) then return end
          local ltnc = global.player_data[e.player_index].ltnc
          local _, _, signal = string.find(e.element.name, "__(.*)")
          dlog(signal)
          local value = tonumber(e.element.text)

          -- Make sure input is within bounds
          local min = -2000000000
          local max = 2000000000
          if config.cs_signals[signal] ~= nil then
            min = config.cs_signals[signal].bounds.min
            max = config.cs_signals[signal].bounds.max
          end
          if signal == "cs-locked-slots" then
            max = ltnc_util.get_max_wagon_size()
          end
          ltnc.combinator:set(signal, ltnc_util.clamp(value, min, max))
        end,
        on_gui_checked_state_changed = function(e)
          dlog(e.element.name)
          local ltnc = global.player_data[e.player_index].ltnc
          local _, _, signal = string.find(e.element.name, "__(.*)")
          if e.element.state then
            ltnc.combinator:set(signal, 1)
          else
            ltnc.combinator:set(signal, 0)
          end
        end
      },
    },
  }
  gui.register_handlers()
end -- RegisterHandlers()

-- Main Window
function create_window(player_index, unit_number)
  local rootgui = game.get_player(player_index).gui.screen
  local ltnc = gui.build(rootgui, {
    {type="frame", direction="vertical", save_as="main_window", name="ltnc-main-window", tags={unit_number=unit_number}, children={
      -- Title Bar
      {type="flow", save_as="titlebar.flow", children={
        {type="label", style="frame_title", caption={"ltnc.window-title"}, elem_mods={ignored_by_interaction=true}},
        {template="drag_handle"},
        {template="close_button", name="ltnc-main-window", handlers="ltnc_handlers.close_button"}
      }},
      {type="frame", style="inside_shallow_frame_with_padding", style_mods={padding=8}, children={
        -- Combinator Main Pane
        {type="flow", direction="vertical", style_mods={horizontal_align="center"}, children={
          -- Entity preview
          {type="frame", style="container_inside_shallow_frame", style_mods={bottom_margin=8}, children={
            {type="entity-preview", save_as="ep", style_mods={
              width=280, height=128, horizontally_stretchable=true
            }},
          }},
          -- On/Off siwtch and Stop Type
          {type="table", column_count=3, style_mods={right_cell_padding=10, left_cell_padding=10}, children={
            {type="flow", style_mods={horizontal_align="left"}, direction="vertical", children={
              {type="label", style_mods={top_margin=8}, caption={"ltnc.output"}},
              {type="switch", save_as="on_off", handlers="ltnc_handlers.on_off_switch",
              left_label_caption={"ltnc.off"}, right_label_caption={"ltnc.on"}
              },
            }},
          }},
          {type="line", style_mods={top_margin=5}},
          -- Signal Table
          {type="label", style_mods={top_margin=5}, caption={"ltnc.output-signals"}},
          {type="flow", direction="vertical", style_mods={horizontal_align="center"}, children={
            {type="frame", direction="vertical", style="slot_button_deep_frame",
              children={
                {type="table", style="slot_table", save_as="signal_table",
                style_mods={width=280, minimal_height=80}, column_count=7}
              },
            },
            {type="flow", direction="vertical", children={
              {type="slider", save_as="signal_value_slider",
              elem_mods={enabled=false},
              style_mods={horizontally_stretchable=true},
              minimum_value=-1, maximum_value=50,
              handlers="ltnc_handlers.slider",
              },
              {type="flow", direction="horizontal", style_mods={horizontal_align="right"}, children={
                {type="label", style_mods={top_margin=5}, caption={"ltnc.label-stacks"}},
                {template="ltnc_entry_text", name="signal_stack", save_as="signal_value_stack", enabled=false,
                  elem_mods={numeric=true, text="0", allow_negative=true},
                  handlers="ltnc_handlers.signal_text",
                },
                {type="label", style_mods={top_margin=5}, caption={"ltnc.label-items"}},
                {template="ltnc_entry_text", name="signal_value", save_as="signal_value_text", enabled=false,
                  elem_mods={numeric=true, text="0", allow_negative=true},
                  handlers="ltnc_handlers.signal_text",
                },
                {template="confirm_button", style_mods={left_padding=5}, enabled=false,
                  save_as="signal_value_confirm", handlers="ltnc_handlers.confirm_button"
                }
              }},
            }}
          }},
        }},
        -- LTN Signal Pane,
        {type="flow", direction="vertical", save_as="signal_pane", style_mods={left_padding=8, width=300, horizontal_align="center"}, children={
          {type="frame", direction="vertical", style="container_inside_shallow_frame",
          style_mods={padding=8}, children={
            {type="table", save_as="cs_signals_common", column_count=3,
              style_mods={cell_padding=2, horizontally_stretchable=true},
            },
          }},
        }},
      }},
    }},
  })
  -- TODO: Templatize this
  -- Create the slot buttons.
  local signals = {}
  for i=1, config.ltnc_misc_slot_count do
    signals[i] = {button = nil}
    signals[i].button = ltnc.signal_table.add({
      name = "ltnc-signal-button__"..i,
      type = "choose-elem-button",
      style = "flib_slot_button_default",
      elem_type = "signal",
    })
    signals[i].button.add({
      type = "label",
      style = "signal_count",
      ignored_by_interaction = true,
      caption = "",
    })
  end

  -- Add LTN signals
  for name, details in pairs(config.cs_signals) do
    local signal_table = "cs_signals_common"
    ltnc[signal_table].add({type="sprite", name="ltnc-sprite__"..name, style="ltnc_entry_sprite", sprite="virtual-signal/"..name})
    ltnc[signal_table].add({type="label", name="ltnc-label__"..name, style="ltnc_entry_label", caption={"virtual-signal-name."..name}})
    local elem = ltnc[signal_table].add({
      type="textfield",
      name="ltnc-element__"..name,
      style="ltnc_entry_text",
      text=details.default,
      tooltip=ltnc_util.signal_tooltip(name, details),
      numeric=true,
      allow_decimal=false,
      allow_negative=false,
      clear_and_focus_on_right_click=true,
      lose_focus_on_confirm=true
    })
    if details.bounds.min < 0 then
        elem.allow_negative = true
    end
  end

  gui.update_filters("ltnc_handlers.choose_button", player_index, {"ltnc-signal-button"}, "add")
  gui.update_filters("ltnc_handlers.cs_signal_entries", player_index, {"ltnc-element"}, "add")
  ltnc.titlebar.flow.drag_target = ltnc.main_window
  ltnc.main_window.force_auto_center()
  ltnc.signals = signals
  return ltnc
end -- create_window()

--------------------------
-- Event registration
--------------------------

ltnc_gui.RegisterHandlers()
ltnc_gui.RegisterTemplates()

event.on_init(function()
  gui.init()
  gui.build_lookup_tables()
end)

event.on_load(function()
  gui.build_lookup_tables()
  if global.player_data then
    for _, pd in pairs(global.player_data) do
      if pd and pd.ltnc and pd.ltnc.ep.valid then
        setmetatable(pd.ltnc.combinator, cs_constant_combinator)
      end
    end
  end
end)

event.register(defines.events.on_gui_opened, function(e)
  if gui.dispatch_handlers(e) then return end
  if not (e.entity and e.entity.valid) then return end
  if e.entity.name == "cybersyn-constant-combinator" then
    ltnc_gui.Open(e.player_index, e.entity)
  else
    ltnc_gui.Close(e.player_index)
  end
end)

event.register({"ltnc-close", "ltnc-escape"}, function(e)
  ltnc_gui.Close(e.player_index)
end)

return ltnc_gui
