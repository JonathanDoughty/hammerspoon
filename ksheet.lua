-- Wrapper for http://www.hammerspoon.org/Spoons/KSheet.html
-- luacheck: globals hs spoon script_path

local ksheet = {}

ksheet.log = hs.logger.new('ksheet','debug')

function ksheet.init(modifiers, config)
    if config["enabled"] then
      if hs.loadSpoon("KSheet") then
        spoon.KSheet:bindHotkeys(
          {
            toggle = {modifiers, config["key"]},
          }
        )
        spoon.KSheet:init()
      else
        ksheet.log.ef("You'll need to install %s for %s to work",
                      "http://www.hammerspoon.org/Spoons/KSheet.html", script_path())
      end
    else
      ksheet.log.f("ksheet NOT enabled")
    end
end

return ksheet
