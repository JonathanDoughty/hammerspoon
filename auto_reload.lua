-- Reload configuration whenever any hammerspoon config files change
-- luacheck: globals hs notify

local m = {}
local log = hs.logger.new("autoreload", "info")
m.log = log

require("utils") -- notify

-- ToDo - see if http://www.hammerspoon.org/Spoons/ReloadConfiguration.html is a replacement
-- or
-- ToDo - integrate this into fs_watcher

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
                                 marker = string.format("\n\n%s Config Reloaded %s\n", marker, marker)
                                 hs.console.clearConsole()
                                 hs.console.printStyledtext(marker)
                                 hs.reload()
                               end
    )
  end
end

function m.init()
  m.myWatcher = hs.pathwatcher.new(hs.configdir, m.reloadConfig):start()
  log.f("Watching for changes in Hammerspoon config files in %s", hs.configdir)
end

return m
