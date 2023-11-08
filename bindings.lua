-- Key binding display as well as key binding definitions I could not find a better place for yet
-- luacheck: globals hs spoon describe

local m = {}
local log = hs.logger.new('bindings','debug')

require "utils"

function m.sleep()
  -- I like this because it keeps my network connection alive (I think)
  hs.caffeinate.set("system", true, false) -- true: prevent sleep; false: only when on AC
  log.i("systemSleep")
  hs.caffeinate.systemSleep()
  log.i("post systemSleep")
  -- Alternatives tried:
  -- hs.caffeinate.startScreensaver()
  -- hs.execute("pmset displaysleepnow") -- and require password
  -- hs.caffeinate.lockScreen()
end

function m.modalMgrInit(modifiers, keys)
  -- Borrowed heavily from https://github.com/ashfinal/awesome-hammerspoon
  local modalMgr_key = keys['modalMgr'] or "tab"
  local modal_keys = {modifiers, modalMgr_key}
  spoon.ModalMgr.supervisor:bind(modal_keys[1], modal_keys[2], nil , -- 'Show Window Hints'
                                 function()
                                   spoon.ModalMgr:deactivateAll()
                                   hs.hints.windowHints()
                                 end
  )

  -- Register Hammerspoon console
  local hammerspoonConsole_key = keys['hammerspoon'] or "H"
  keys = {modifiers, hammerspoonConsole_key}
  spoon.ModalMgr.supervisor:bind(keys[1], keys[2], "Toggle Hammerspoon Console",
                                 function()
                                   hs.toggleConsole()
                                 end
  )

  -- initialize ModalMgr supervisor
  spoon.ModalMgr.supervisor:enter()
end

function m.killSwitch()
  local logPath = hs.configdir .. '/console.log'
  log.df("Saving console text to %s", logPath)
  local consoleText = hs.console.getConsole()
  local logFile = assert(io.open(logPath, 'a')) -- append to existing (so an accidental repeat does not lose)
  logFile:write(consoleText)
  io.close(logFile)
  hs.relaunch()
end

function m.init(modifiers, keys)

  hs.loadSpoon("ModalMgr")
  m.modalMgrInit(modifiers, keys)

  -- These are not yet using modalMgr

  -- Instead of https://www.hammerspoon.org/Spoons/HSKeyBindings.html
  hs.hotkey.showHotkeys(modifiers, keys["showbindings"])

  -- Toggle the Hammerspoon console
  hs.hotkey.bind(modifiers, keys["hammerspoon"], describe("Hammerspoon console"), function()
                   hs.openConsole()
  end)

  -- Kill switch / fail safe / Relaunch  - normally on hyper-r
  hs.hotkey.bind(modifiers, keys["kill"], describe("Relaunch Hammerspoon"), m.killSwitch)

  -- Sleep the display(s), causing a lock screen; alternative to the old Command-Shift-Power)
  hs.hotkey.bind(modifiers, keys["sleep"], describe("Sleep/Lock"), m.sleep)

  -- Somewhat like Windows Alt-E, make a new Finder Window
  hs.hotkey.bind({"cmd"}, "E", describe("New Finder Window"), function()
      hs.osascript.applescript(
        'tell application "Finder" to make new Finder window to home')
  end)
end

return m
