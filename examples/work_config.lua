-- Work configuration
-- Borrowers will want to modify this to their own needs
-- luacheck: globals hs

local m = {}

m.hostname = "WorkMac"          -- change needed
m.log = hs.logger.new("config_work", "debug")

-- See work_apps.lua

m.defs = {
  apps = {
    { name = "Microsoft Outlook", quit = "Quit Outlook" },
    { name = "Microsoft Teams", quit = "Quit Microsoft Teams" },
    { name = "Slack", quit = "Quit Slack" },
  },
  keys = {
    apps = "x",
    updater = "u",      -- work-apps/updater
  },
}

function m.init(modifiers, defs)
  local work_apps = {}
  -- Some spoons are only needed on work computer
  if hs.host.localizedName() == m.hostname then
    work_apps.apps = require "work_apps" --  Set up to toggle work apps
    work_apps['work'] = work_apps.apps.init(modifiers, defs)

    local updater = require "update_watcher" -- Watch what local admins are doing
    work_apps['updater'] = updater
    updater.init(modifiers, defs)
  else
    m.log.df("%s is not %s", hs.host.localizedName(), m.hostname)
  end
  return work_apps
end

return m
