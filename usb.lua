-- Watch / act on USB events and USB related devices
-- luacheck: globals hs notify spoon load_config describe devices toLogLevel

require("utils")

local m = {}
-- Spoon (someday) metadata
m.name = "USB"
m.version = "0.2"
m.author = "Jonathan Doughty <jwd630@gmail.com>"
m.homepage = "https://github.com/JonathanDoughty/hammerspoon"
m.license = "MIT - https://opensource.org/licenses/MIT"

local options = { ["newline"] = " " } -- used for hs.inspect to flatten tables

local log = hs.logger.new("usb", "info")
m.log = log

m.usbEvents = {}
m.devices = { -- built-in devices
    ["Apple Internal Keyboard / Trackpad"] = { fn = 'report' }, -- {dis}connected on lid close/open
    ["Apple T2 Controller"] = { fn = 'ignore' }, -- security chip
    ["Ambient Light Sensor"] = { fn = 'ignore' },
    ["Bluetooth USB Host Controller"] = { fn = 'ignore' },
    ["FaceTime HD Camera (Built-in)"] = { },
    ["Internal Memory Card Reader"] = { fn = 'ignore' },
    ["TPS DMC Family"] = { fn = 'ignore' },
    ["Touch Bar Backlight"] = { fn = 'ignore' },
    ["Touch Bar Display"] = { fn = 'ignore' },
    ["USB Audio"] = { },
    ["USB audio CODEC"] = { },
}

m.ignored_volumes = { -- substrings of names of volumes to ignore
  "TimeMachine.localsnapshots",
  ".timemachine",
  "Backups of ",
  "AppTranslocation",
}

-- ToDo: should use hs.task / hs.timer, not hs.execute
-- See https://github.com/Hammerspoon/hammerspoon/issues/2334 for some help
-- and https://github.com/Hammerspoon/hammerspoon/issues/911

local function mountEncrypted(mounted)

  local function mountContainer()
    log.df("executing %s", m.config.mount_container)
    hs.execute(m.config.mount_container, false)
    log.vf("m.config %s", hs.inspect(m.config, options))
    local volumes = hs.fs.volume.allVolumes()
    m.container = volumes[m.config.container]
  end

  local function checkMount()
    if m.container then
      notify("Encrypted container mounted")
      log.f("%s mounted", m.config.container)
    else
      notify("Encrypted container NOT mounted")
      log.ef("%s NOT mounted; volumes:%s", m.config.container,
             hs.inspect(hs.fs.volume.allVolumes(), options))
    end

  end

  if mounted then
    mountContainer()
    checkMount()
  else
    log.f("Too late, volume no longer mounted")
  end
end

local function dismountEncrypted()

  local function dismount()
    hs.notify.show("USB", "", "Dismounting...")
    log.df("executing %s on %s", m.config.dismount_container, m.config.container)
    local output, status, _, _ = hs.execute(m.config.dismount_container, false)
    log.vf("container dismounted with:%s (%s)", output, status)
  end

  -- Check if Encrypted container is mounted and dismount that
  local volumes = hs.fs.volume.allVolumes()
  m.container = volumes[m.config.container]
  if m.container then
    dismount()
  else
    log.vf("container not mounted")
  end
end

local function reportDevices(device_table)
  -- Simply report on device connect/disconnect evebts that are observed: handy when starting
  -- to define specific functionality.

  -- Replace direct devices usage of this function; instead generating repetitious code to
  -- report on the device. The resulting function gets called when the device association is
  -- ["device Name"] = { fn = 'report' }.  By default all devices initially get registered to
  -- use this.

  -- The Yak Shave plan: add additional arguments to devices table to generate alternate code
  -- where USBDeviceActions' boolean connected/disconnected is insufficient.

  local function inc(dev, event)
    local eventType
    if event then
      eventType = "connected"
    else
      eventType = "disconnected"
    end
    if not m.usbEvents[dev] then
      m.usbEvents[dev] = {}
      m.usbEvents[dev]['connected'] = 0
      m.usbEvents[dev]['disconnected'] = 0
    end
    log.vf("incrementing usbEvent[%s][%s]", dev, eventType)
    m.usbEvents[dev][eventType] = m.usbEvents[dev][eventType] + 1
    return m.usbEvents[dev]['connected'], m.usbEvents[dev]['disconnected']
  end

  for dev, t in pairs(device_table) do
    if t.fn == reportDevices then
      device_table[dev] = {
        -- Generate function to report device connections
        fn = function(connected)
          local connects, disconnects = inc(dev, connected)
          local msg = string.format("%s: connects %d disconnects: %d", dev, connects, disconnects)
          log.df("%s", msg)
          if disconnects >- connects then
            notify(msg, 15)
          end
        end
      }
      log.df("Created function to report '%s'", dev)
    else
      log.vf("Skipping redefinition for %s (%s != %s)", dev, t.fn, reportDevices)
    end
  end
end

local function ejectDisks(mounted)

  if not mounted then
    dismountEncrypted()
    local volumes = hs.fs.volume.allVolumes()
    hs.fnutils.each(volumes, function(vol)
                      local path = '/Volumes/' .. vol['NSURLVolumeLocalizedNameKey']
                      if not (hs.fnutils.contains(m.config.eject_menu.config.never_eject, path) or
                              vol["NSURLVolumeIsInternalKey"]) then
                        log.df("dismount vol:%s", hs.inspect(vol, options))
                        local result, err = hs.fs.volume.eject(path)
                        if result then
                          log.df("Save info about %s for remount", hs.inspect(vol, options))
                        else
                          log.ef("Error ejecting %s:%s", path, err)
                        end
                      end
    end)
    hs.notify.show("USB", "", "Ejected ")
  else
    log.vf("ejectDisks called via key binding or device registration; mounted:%s",
           hs.inspect(mounted), options)
  end
end

local function runUserScript()
  log.w("Running user script not implemented yet")
  -- And need a way to get the actual script name here
end

-- Set up mapping between config.usb.devices and functions above
local fnc_mapping = {
  report = reportDevices,
  mount_encrypted = mountEncrypted,
  unmount_encrypted = dismountEncrypted,
  eject = ejectDisks,
  user_script = runUserScript,
  ignore = nil,
}

local volumeActions = {
  [hs.fs.volume.didMount] = "mounted",
  [hs.fs.volume.didRename] = "renamed",
  [hs.fs.volume.didUnmount] = "unmounted",
  [hs.fs.volume.willUnmount] = "will unmount",
}

local function watchVolumes()

  local function checkVolume(item, eventType, info)
    log.vf("Checking %s", hs.inspect(item, options))
    if eventType == hs.fs.volume.didMount then
      log.df("%s mounted, checking for watch path", info['path'])
      if (item['volume'] == info['path']) and item['mount'] then
        if info['mount'] and info['path'] then
          log.df("calling %s for %s", info['mount'], info['path'])
          if fnc_mapping[info['mount']] then
            log.df("Call %s function %s", info['mount'],
                   hs.inspect(fnc_mapping[info['mount']], options))
          end
        end
      else
        log.vf("('%s' ~= '%s') or %s", item['volume'], info['path'],
               item['mount'])
      end
    elseif eventType == hs.fs.volume.willUnmount then
      log.df("%s unmounted, checking for watch path", info.path)
      if (item['volume'] == info['path']) and item['unmount'] then
        if info['mount'] and info['path'] then
          log.df("calling %s for %s", info['unmount'], info['path'])
          dismountEncrypted()
          if fnc_mapping[info['unmount']] then
            log.df("Calling %s function %", info['unmount'],
                   hs.inspect(fnc_mapping[info['mount']], options))
          else
            log.vf("('%s' != '%s') or %s", item['volume'], info['path'],
                   item['unmount'])
          end
        end
      end
    end
  end

  local function volumeEvent(eventType, info)
    if not hs.fnutils.find(m.ignored_volumes,
                           function(element)
                             if string.match(info.path, element) then
                               return true
                             end
                             return false
                          end) then
      log.df("Received %s for %s, checking", volumeActions[eventType], info["path"])
      hs.fnutils.each(m.watch,
                      function(item)
                        checkVolume(item, eventType, info)
                      end
      )
    else
      log.vf("Ignoring %s for %s", volumeActions[eventType], hs.inspect(info, options))
    end
  end

  -- watch for volume, e.g., disk mount/unmount, events
  local watcher = hs.fs.volume.new(volumeEvent):start()
  return watcher
end

local function checkDevices (device_table)
  -- Generate initial 'reportDevices' definitions for all unregistered but attached USB devices
  local name
  local checked = {}
  for _, dev in ipairs(hs.usb.attachedDevices()) do
    name = dev["productName"]
    name = string.gsub(name, "%s+$", "") -- get rid of trailing spaces
    if name then
      if device_table[name] then
        -- Redundant with registerFunctions below?
        if type(device_table[name].fn) == "string" then
          local key = device_table[name].fn
          log.df("Replacing %s with %s", key, fnc_mapping[key])
          device_table[name].fn = fnc_mapping[key]
        else
          log.vf("Already checked \"%s\"", name)
        end
      else
        if not checked[name] then
          log.f("Registering attached [\"%s\"] = { fn = reportDevices },", name)
          device_table[name] = { fn = reportDevices }
        end
      end
      checked[name] = true
    end
  end
end

local function registerFunctions(device_table)
  -- Replace devices' config fnc_mapping with the function reference itself
  for name, _ in pairs(device_table) do
    if type(device_table[name].fn) == "string" then
      local key = device_table[name].fn
      log.vf("Registering %s with mapping for %s: %s", name, key, fnc_mapping[key])
      device_table[name].fn = fnc_mapping[key]
    else
      log.vf("Already registered \"%s\"", name)
    end
  end
end

local function configureSpoons(modifiers)
    -- related spoon initialization
  hs.loadSpoon("SpoonInstall")
  local  Install=spoon.SpoonInstall

  -- http://www.hammerspoon.org/Spoons/USBDeviceActions.html
  -- spoon at https://github.com/Hammerspoon/Spoons/blob/master/Spoons/USBDeviceActions.spoon.zip
  Install:andUse("USBDeviceActions", {
                   config = {
                     devices = m.devices
                   },
                   start = true,
                   disable = false,
  })

  -- http://www.hammerspoon.org/Spoons/EjectMenu.html
  m.config.eject_menu.hotkeys.ejectAll = { modifiers, m.config.keys.ejectall }
  log.vf("config.eject_menu:%s", hs.inspect.inspect(m.config.eject_menu, options))
  Install:andUse("EjectMenu", m.config.eject_menu)
end

function m.init(modifiers)
  m.config = load_config()
  if ( log.getLogLevel() ~= toLogLevel(m.config.loglevel) ) then
    log.df("Setting usb log level to %s", m.config.loglevel)
    log.setLogLevel(m.config.loglevel)
  end

  -- Merge/override personal devices into built-ins (typically ignored)
  for k, v in pairs(m.config.devices) do m.devices[k] = v end

  -- adjust devices' function calls
  registerFunctions(m.devices)
  checkDevices(m.devices)
  reportDevices(m.devices)
  configureSpoons(modifiers)

  -- Is this duplicative with EjectMenu spoon?
  hs.hotkey.bind(modifiers, m.config.keys["eject"], describe("Eject disks"), ejectDisks)

  m.watch = m.config.watch
  m.fs_watcher = watchVolumes()
end

return m
