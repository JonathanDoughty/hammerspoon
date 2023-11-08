-- Wrapper for http://www.hammerspoon.org/Spoons/KSheet.html
-- luacheck: globals hs spoon

local ksheet = {}

ksheet.log = hs.logger.new('ksheet','debug')

function ksheet.init(modifiers, config)
    -- http://www.hammerspoon.org/Spoons/KSheet.html
    if config["enabled"] then
      hs.loadSpoon("KSheet")
      spoon.KSheet:bindHotkeys(
        {
          toggle = {modifiers, config["key"]},
        }
      )
      spoon.KSheet:init()
    else
      ksheet.log.f("ksheet NOT enabled")
    end
end

return ksheet
