-- Module for turning one MIDI pedal into a different kind of MIDI pedal.
--

local mod = require 'core/mods'
local json = include (mod.this_name .. '/lib/json')
local Midi = require 'core/midi'

--- Our local state
--
local state = {
  original_norns_midi_event = nil,    -- Original function we'll wrap
  cc = 64,    -- The MIDI CC of the pedal
  channel = 1,    -- The MIDI channel of the pedal
  threshold = 100,    -- What the pedal needs to reach to register "pressed".
  is_pressed = false,    -- If the pedal is pressed
}

-- After startup we want to wrap the norns' MIDI event function that
-- processes MIDI events.
--

mod.hook.register("system_post_startup", "Pedal remapper post", function()
  if _norns.midi.event then
    -- We've found the function we want to wrap,
    -- but let's not replace it twice.

    if state.original_norns_midi_event == nil then
      state.original_norns_midi_event = _norns.midi.event
      _norns.midi.event = mod_norns_midi_event
    end
  else
    print("No _norns.midi.event, no pedal remapping")
  end

end)

-- Our own version of _norns.midi.event.
-- We make a possible translation, and pass this into the original function.
--
function mod_norns_midi_event(id, data)
  local msg = Midi.to_msg(data)
  local str = json.encode(msg)
  print(str)

  if msg.cc == state.cc and msg.ch == state.channel then
    -- This is from our pedal.
    -- We should only send a message if we've flipped from
    -- not-pressed to pressed.

    if is_pressed(msg.val) ~= state.is_pressed then
      -- The pressed state has changed
      state.is_pressed = not state.is_pressed

      -- Maybe send a trigger message, otherwise just swallow it
      if state.is_pressed then
        msg.val = 127
        print("    Changed msg to " .. json.encode(msg))
        data = Midi.to_data(msg)
      else
        -- The pedal is not pressed, so swallow the message
        print("    Swallowing message (pedal no longer pressed)")
        return
      end
    else
      -- The pressed state is the same, so swallow the message
      print("    Swallowing message (pedal state unchanged)")
      return
    end
  end

  state.original_norns_midi_event(id, data)
end

-- Is this a "pressed" value - ie at or above our threshold?
--
function is_pressed(v)
  return v >= state.threshold
end

-- Create a toggle pedal

--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--

local m = {}

m.key = function(n, z)
  if n == 2 and z == 1 then
    mod.menu.exit()
  end
end

m.enc = function(n, d) end

-- Show what might be sent to keyboard.process(). We cannot call this
-- redraw() because... of some reason which means it won't get called
-- if it is.
--
function mod_redraw()
  screen.clear()

  screen.move(0, 60); screen.text("K2 to exit")

  screen.update()
end

m.redraw = mod_redraw

-- Called on menu entry.
--
m.init = function()
end

-- Called on menu exit.
--
m.deinit = function()
end

-- register the mod menu
--
mod.menu.register(mod.this_name, m)
