-- Wrap my currently preferred window manager
-- luacheck: globals hs spoon script_path

local window_mgr = {}

local log = hs.logger.new("window_mgr", "info")

function window_mgr.init(modifiers, keys)
  -- See https://github.com/miromannino/miro-windows-manager
  -- Alternatives:
  -- https://www.hammerspoon.org/Spoons/WindowHalfsAndThirds.html -- uses a large keymap
  -- https://github.com/peterklijn/hammerspoon-shiftit - large keymap with incremental control

  if hs.loadSpoon("MiroWindowsManager") then
    window_mgr.spoon = spoon
    hs.window.animationDuration = 0.1

    -- Note that full-height (hyper + up + down arrow) and
    -- full-width (hyper + left + right arrow) do not toggle

    spoon.MiroWindowsManager:bindHotkeys(
      {
        up = {modifiers, keys["up"]},
        right = {modifiers, keys["right"]},
        down = {modifiers, keys["down"]},
        left = {modifiers, keys["left"]},
        fullscreen = {modifiers, keys["fullscreen"]}
      }
    )
    hs.hotkey.bind(modifiers, "0", hs.grid.show)
  else
    log.ef("You'll need to install %s for %s to work\n",
           "https://github.com/miromannino/miro-windows-manager", script_path())
  end
end

return window_mgr
