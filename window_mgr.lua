-- Wrap my currently preferred window manager
-- luacheck: globals hs spoon

local window_mgr = {}

function window_mgr.init(modifiers, keys)
  -- See https://github.com/miromannino/miro-windows-manager
  -- Alternatives
  -- https://www.hammerspoon.org/Spoons/WindowHalfsAndThirds.html -- This uses a large keymap
  -- https://github.com/peterklijn/hammerspoon-shiftit - similar large keymap but has some incremental control
  window_mgr.spoon = hs.loadSpoon("MiroWindowsManager")

  hs.window.animationDuration = 0.1

  -- Note that full-height (hyper + up + down arrow) and full-width (hyper + left + right arrow) do not toggle
  spoon.MiroWindowsManager:bindHotkeys(
    {
      -- Spoon does not expose a way to add alert text/description to hot keys
      -- ksheet.lua has the same issue
      -- The only idea that occurs to me so far is to get
      up = {modifiers, keys["up"]},
      right = {modifiers, keys["right"]},
      down = {modifiers, keys["down"]},
      left = {modifiers, keys["left"]},
      fullscreen = {modifiers, keys["fullscreen"]}
    }
  )
  hs.hotkey.bind(modifiers, "0", hs.grid.show)
end

return window_mgr
