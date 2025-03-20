-- Wrap my currently preferred window manager
-- luacheck: globals hs spoon script_path

local window_mgr = {}

local log = hs.logger.new("window_mgr", "info")
-- Replacement candidates I've come across:
local alternatives = {
  {url = "https://www.hammerspoon.org/Spoons/WindowHalfsAndThirds.html",
   desc = "uses a large keymap"},
  {url = "https://github.com/peterklijn/hammerspoon-shiftit",
   desc = "large keymap with incremental control"},
  {url = "https://github.com/MrKai77/Loop",
   desc = "native app, compares itself to Hammerspoon"}
}

function window_mgr.init(modifiers, keys)

  local spoonURL = "https://github.com/miromannino/miro-windows-manager"

  if hs.loadSpoon("MiroWindowsManager") then
    window_mgr.spoon = spoon
    hs.window.animationDuration = 0.1

    -- Note that full-height (hyper + up + down arrow) and
    -- full-width (hyper + left + right arrow) do not toggle

    spoon.MiroWindowsManager:bindHotkeys( {
        up = {modifiers, keys["up"]},
        right = {modifiers, keys["right"]},
        down = {modifiers, keys["down"]},
        left = {modifiers, keys["left"]},
        fullscreen = {modifiers, keys["fullscreen"]}
      }
    )
    hs.hotkey.bind(modifiers, "0", hs.grid.show)
  else
    log.ef("\n\nYou'll need to install %s for %s to work\nOr consider using:\n",
           spoonURL, script_path())
    for _,v in ipairs(alternatives) do
      log.f("%s - %s\n", v.url, v.desc)
    end
  end
end

return window_mgr
