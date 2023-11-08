-- Wrap the Caffeine spoon
-- luacheck: globals hs spoon load_config

require "utils" -- load_config

local caffeine = {}

function caffeine.init(modifiers)
  local config = load_config()
  if not config.disabled then
    -- https://www.hammerspoon.org/Spoons/Caffeine.html
    hs.loadSpoon("Caffeine")
    spoon.Caffeine:bindHotkeys(
      {
        toggle = {modifiers, config.keys["caffeine"]},
      }
    )
    spoon.Caffeine:start()
    caffeine.config = config
  else
    caffeine.init = nil
  end
end

return caffeine
