-- Top level configuration
-- Borrowers will want to modify this to their own needs
-- You will also likely comment out the portions of init.lua you don't want.

local m = {}

m.log_level = "debug"

local hyper
 -- My preferred global Hammerspoon key modifier (-- attempts that I gave up on)
-- hyper = {"ctrl", "⌥", "⌘"} -- {"ctrl", "option/alt", "cmd"} -- definitely unique but carpel tunnel inducing
hyper = {"⌥", "⌘"} -- {"option/alt", "cmd"}
-- hyper = {"right_command" } -- https://mattorb.com/level-up-shortcuts-hammerspoon-home-row/ -- Did not work out
m.hyper = hyper

m.hostname = "localhost" -- pertains to special configuration for work laptop, see init.lua

-- Configuration for scripts corresponding to top level keys
-- There are some inconsistencies here still, e.g., some key bindings are here while
-- most have been migrated to a examples/module_config.lua

-- The following are more top level or too minor to have migrated yet.
m.script_config = {
  bindings = {
    showbindings = "b",
    modalMgr = "tab",
    sleep = "q",
    hammerspoon = "z",
    kill = "r", -- kill switch: relaunch
  },
  ksheet = {
    key = "k",
    enabled = false, -- currently causing beach balling
  },
  window_mgr = {
    fullscreen = "f",
    down = "down",
    left = "left",
    right = "right",
    up = "up",
  },
  work = {
    hostname = "WorkHostName",
  }
}

-- See urls.lua

m.urls_defs = {
  default_handler = 'org.mozilla.firefox',
}

return m
