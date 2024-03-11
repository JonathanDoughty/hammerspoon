-- Wrap the Caffeine spoon
-- luacheck: globals hs spoon load_config script_path

require "utils" -- load_config

local log = hs.logger.new("caffeine", "info")

local caffeine = {}

function caffeine.init(modifiers)
  local config = load_config()
  if not config.disabled then
    if hs.loadSpoon("Caffeine") then
      spoon.Caffeine:bindHotkeys(
        {
          toggle = {modifiers, config.keys["caffeine"]},
        }
      )
      spoon.Caffeine:start()
      caffeine.config = config
    else
      log.ef("You'll need to install %s for %s to work\n",
             "https://www.hammerspoon.org/Spoons/Caffeine.html", script_path())
    end
  else
    caffeine.init = nil
  end
end

return caffeine
