-- sleep/wake event watcher
-- luacheck: globals hs load_config toLogLevel

require "utils"

local m = {}
local log = hs.logger.new('sleepwatcher','debug')
m.log = log

--  Appear to be active when screen sleeps
-- hs.caffeinate doesn't quite seem to provide the same user assertion
local look_active = "sh -c \"cd ${HOME}/Downloads && nuhup caffeinate -iu &\""
local kill_look_active = "sh -c \"killall -v -u ${USER} -c caffeinate\""

local function execute(command)
  local result, status
  if command ~= nil then
    result, status = hs.execute(command, false)
    log.df("%s result: %s status: %s", command, result, status)
  else
    log.ef("command nil for %s", command)
  end
end

local unmounted = {}
local function unMountExternal()
  log.df("unMountExternal")
  local vols = hs.fs.volume.allVolumes()
  for mount_point, props in pairs(vols) do
    if props["NSURLVolumeIsInternalKey"] == false then
      table.insert(unmounted, mount_point)
      log.df("unmount %s", mount_point)
    else
      log.df("not unmounting %s", mount_point)
    end
  end
end
local function mountExternal()
  log.df("mountExternal")
  for volumeName in unmounted do
    log.df("re-mount %s", volumeName)
    unmounted[volumeName] = nil
  end
end
local function lookActive()
  log.df("lookActive")
  local command = look_active
  execute(command)
end
local function lookNormal()
  log.df("lookNormal")
  local command = kill_look_active
  execute(command)
end
local function noAction()
  log.vf("no action")
end

local watcher = hs.caffeinate.watcher
m.actions = {
  [watcher.screensDidWake] = lookNormal,
  [watcher.screensDidSleep] = lookActive,
  [watcher.systemWillSleep] = unMountExternal,
  [watcher.systemWillPowerOff] = unMountExternal,
  [watcher.sessionDidResignActive] = unMountExternal,
  [watcher.systemDidWake] = mountExternal,
  [watcher.screensDidLock] = noAction,
  [watcher.screensDidUnlock] = noAction,
  [watcher.screensaverDidStart] = noAction,
  [watcher.screensaverDidStop] = noAction,
  [watcher.screensaverWillStop] = noAction,
  [watcher.sessionDidBecomeActive] = noAction,
}

function m.activateOn(event)
  if m.actions[event] ~= nil then
    log.vf("event:%s", event)
    m.actions[event]()          -- invoke the associated function
  else
    log.df("no actions defined for %s", event)
  end
end

function m.init()
  m.defs = load_config()

  if ( log.getLogLevel() ~= toLogLevel(m.defs.loglevel) ) then
    log.setLogLevel(m.defs.loglevel)
  end

  if m.defs.enabled then
    m.activityWatcher = hs.caffeinate.watcher.new(m.activateOn)
    m.activityWatcher:start()
  else
    log.f("sleepwatcher NOT enabled")
  end
end

return m
