-- Wrapper for Time Machine progress meter
-- http://www.hammerspoon.org/Spoons/TimeMachineProgress.html
-- luacheck: globals hs spoon script_path

local obj = {}

local log = hs.logger.new("tm_progress", "info")

require "utils"

function obj.init(logLevel, disable)
  if hs.loadSpoon("TimeMachineProgress") then
    if not (disable) then
      spoon.TimeMachineProgress.logger.setLogLevel(logLevel)
      spoon.TimeMachineProgress:start()
    end
    return spoon.TimeMachineProgress
  else
    log.ef("You'll need to install %s for %s to work\n",
           "https://www.hammerspoon.org/Spoons/TimeMachineProgress.html", script_path())
  end
end

return obj
