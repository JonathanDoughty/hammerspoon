-- Configuration for switcher.lua preferences

local switcher_config = {
  loglevel = "debug",
  move = "m",        -- key to bind with hyper to application screen moves
  never_current = {  -- never make these 'current'
    "Hammerspoon",   -- else debugging is nextto impossible
    "SecurityAgent", -- e.g., gains focus when iTerm asks Finder to access files that need identity check
    "Dock",          -- has no windows to make current
    "ScreenSaverEngine", -- occurs on idle/sleep
    "CoreServicesUIAgent",
    "UserNotificationCenter",
  },
  termination_candidates = {  -- Apps that hang around pointlessly when all windows are closed
    "Archive Utility",
  },
  special_cases = {
    { app = "Finder", action = 'tell application "Finder" to reopen' }, -- will always have nonStandard, Desktop window
    { -- Maybe OBE; Teams will always have at least 2 windows, 1 visible, 0 minimized, 1 standard
      -- see https://apple.stackexchange.com/a/422815/57102 for others wih this issue
      -- and https://apple.stackexchange.com/a/270770/57102 for other alternatives
      app = "Microsoft Teams", action = 'tell application "Microsoft Teams" to reopen' },
  },
}

return switcher_config
