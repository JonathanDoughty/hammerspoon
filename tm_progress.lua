-- Wrapper for Time Machine progress meter
-- http://www.hammerspoon.org/Spoons/TimeMachineProgress.html
-- luacheck: globals hs spoon

local obj = {}

function obj.init(logLevel, disable)
  hs.loadSpoon("TimeMachineProgress")
  if not (disable) then
    spoon.TimeMachineProgress.logger.setLogLevel(logLevel)
    spoon.TimeMachineProgress:start()
  end
  return spoon.TimeMachineProgress
end

return obj
