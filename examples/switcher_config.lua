-- Configuration for switcher.lua preferences
-- luacheck: globals hs

local switcher_config = {
  loglevel = "info",
  bindings = {
       move_all = "m",              -- move all application windows
       move_focused = ",",          -- move just currently focused window
  },
  never_current = {  -- never make these 'current'
    "Hammerspoon",   -- else debugging this is next to impossible
    "loginwindow",   -- Becomes 'active' on sleep request and thus cancels sleep
    "SecurityAgent", -- UI for Security Service, requests authentication for privileges
    "ScreenSaverEngine", -- occurs on idle/sleep
    "Screen Saver",
    "System Information", -- making it current will auto-enable the More Info window
    "UserNotificationCenter",
    -- Apps that you may use with helpers to ignore
    -- "Little Snitch Agent",
    -- "bzmenu" -- Backblaze
    -- "ZoomAutoUpdater",    -- Zoom
    -- augmented below with Hammerspoon's own list
  },
  termination_candidates = {  -- Apps that hang around pointlessly after all windows are closed
    "Archive Utility",
    -- Other candidates I find annoying
    -- "Numbers",
    -- "Preview",
    -- "TextEdit",
  },
  special_cases = {
    { app = "Finder", action = 'tell application "Finder" to reopen' }, -- will always have nonStandard, Desktop window
    { -- Maybe OBE; Teams will always have at least 2 windows, 1 visible, 0 minimized, 1 standard
      -- see https://apple.stackexchange.com/a/422815/57102 for others wih this issue
      -- and https://apple.stackexchange.com/a/270770/57102 for other alternatives
      app = "Microsoft Teams", action = 'tell application "Microsoft Teams" to reopen' },
  },
}

-- Augment the list of applications that are never 'current' for switcher with
-- those whose windows Hammerspoon's hs.window.filter ignores.
for k, _ in pairs(hs.window.filter.ignoreAlways) do
  table.insert(switcher_config.never_current, k)
end

return switcher_config
