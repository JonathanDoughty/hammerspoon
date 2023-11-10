-- Reload configuration whenever any hammerspoon config files change
-- luacheck: globals hs notify

local m = {}
local log = hs.logger.new("autoreload", "info")
m.log = log

require("utils") -- notify

-- ToDo - see if http://www.hammerspoon.org/Spoons/ReloadConfiguration.html is a replacement

-- ToDo: YakShave: invoke luacheck and abort reload if there are issues
-- ToDo: yakShave: prior to reload: get history, find previous marker, delete earlier history, set history

function m.reloadConfig(files)
  local fileChanged = nil
  for _, file in pairs(files) do
    log.df("checking %s", file)
    file = file:match(".*/(.*)")
    if file:sub(-4) == ".lua" then
      if file:sub(1,1) == "." then -- skip hidden files, like .# emacs temps
        log.vf("skipping temp file %s", file)
      else
        log.df("reloading because %s changed", file)
        fileChanged = file
        break
      end
    end
  end
  if fileChanged then
    local waitFor = 2
    local msg = "Config being reloaded for " .. fileChanged .. " modification in " .. waitFor .. " seconds"
    m.note = notify(msg, 10)
    log.i(msg)
    m.timer = hs.timer.doAfter(waitFor,
                               function()
                                 local marker = string.rep("*", 40)
                                 marker = string.format("\n\n%s Config Reloaded for %s %s\n",
                                                        marker, fileChanged, marker)
                                 hs.console.printStyledtext(marker)
                                 hs.reload()
                               end
    )
  end
end

function m.init()
  m.myWatcher = hs.pathwatcher.new(hs.configdir, m.reloadConfig):start()
  hs.console.printStyledtext(string.format("\nWatching for changes in config files in %s\n\n", hs.configdir))
end

return m
