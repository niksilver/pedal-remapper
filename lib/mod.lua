-- Module for turning one MIDI pedal into a different kind of MIDI pedal.
--

local mod = require 'core/mods'
local json = include (mod.this_name .. '/lib/json')

--- Our local state
--
local pedal = {
  original_norns_midi_event = nil
}

-- After startup we want to wrap the norns' MIDI event function that
-- processes MIDI events.
--

mod.hook.register("system_post_startup", "Pedal remapper post", function()
  if _norns.midi.event then
    -- We've found the function we want to wrap,
    -- but let's not replace it twice.

    if pedal.original_norns_midi_event == nil then
      pedal.original_norns_midi_event = _norns.midi.event
      _norns.midi.event = mod_norns_midi_event
      print("Replaced original " .. tostring(pedal.original_norns_midi_event) .. " with " .. tostring(_norns.midi.event))
    end
  else
    print("No _norns.midi.event")
  end

end)

-- Our own version of _norns.midi.event.
-- We make a possible translation, and pass this into the original
-- function if we're not in the mod menu.
--
function mod_norns_midi_event(id, data)
  local str = json.encode(data)
  print(str)
  pedal.original_norns_midi_event(id, data)
end

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
