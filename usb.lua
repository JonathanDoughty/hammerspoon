-- Watch / act on USB events and USB related devices
-- luacheck: globals hs notify spoon load_config describe devices

require("utils")

local m = {}

local log = hs.logger.new("usb", "debug")
m.log = log
m.usbEvents = {}
m.devices = { -- built-in devices
    ["Apple Internal Keyboard / Trackpad"] = { }, -- {dis}connected on lid open/close
    ["Apple T2 Controller"] = { }, -- security chip
    ["Ambient Light Sensor"] = { },
    ["Bluetooth USB Host Controller"] = { },
    ["FaceTime HD Camera (Built-in)"] = { },
    ["Touch Bar Backlight"] = { fn = 'ignore' },
    ["Touch Bar Display"] = { fn = 'ignore' },
    ["USB audio CODEC"] = { },
}


-- These should use hs.task / hs.timer or otherwise deal with not tying up Hammerspoon's single thread
-- See https://github.com/Hammerspoon/hammerspoon/issues/2334 for some help
-- and https://github.com/Hammerspoon/hammerspoon/issues/911

local function mountEncrypted(mounted)

  local function mountContainer()
    hs.execute("sleep 4") -- give automount a chance to complete
    log.df("executing %s", m.config.mount_container)
    hs.execute(m.config.mount_container, false)
    log.vf("m.config %s", hs.inspect(m.config))
    local volumes = hs.fs.volume.allVolumes()
    m.container = volumes[m.config.container]
  end

  local function checkMount()
    if m.container then
      notify("Encrypted container mounted")
      log.f("%s mounted", m.config.container)
    else
      notify("Encrypted container NOT mounted")
      log.ef("%s NOT mounted; volumes:%s", m.config.container, hs.inspect(hs.fs.volume.allVolumes()))
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

local function watchForEncrypted()

  local function volumeEvent(eventType, info)
    if eventType == hs.fs.volume.didMount then
      log.vf("%s mounted, checking for watch path", info['path'])
      hs.fnutils.each(m.watch, function(item)
                        log.vf("Consider watch item %s", hs.inspect(item))
                        if (item['volume'] == info['path']) and item['mount'] then
                          log.df("calling mountEncrypted for %s", info['path'])
                          mountEncrypted(true)
                        else
                          log.vf("('%s' ~= '%s') or %s", item['volume'], info['path'], item['mount'])
                          end
      end)
    elseif eventType == hs.fs.volume.willUnmount then
      hs.fnutils.each(m.watch, function(item)  -- is this one of the volumes being watched?
                        log.vf("Consider watch item %s", hs.inspect(item))
                        if (item['volume'] == info['path']) and item['unmount'] then
                          log.df("calling dismountEncrypted for %s", info['path'])
                          dismountEncrypted()
                        else
                          log.vf("('%s' != '%s') or %s", item['volume'], info['path'], item['unmount'])
                        end
      end)
    end
  end
  local watcher = hs.fs.volume.new(volumeEvent):start()
  return watcher
end

local function ejectDisks(mounted)

  if not mounted then
    dismountEncrypted()
    local volumes = hs.fs.volume.allVolumes()
    hs.fnutils.each(volumes, function(vol)
                      local path = '/Volumes/' .. vol['NSURLVolumeLocalizedNameKey']
                      if not (hs.fnutils.contains(m.config.eject_menu.config.never_eject, path) or
                              vol["NSURLVolumeIsInternalKey"]) then
                        log.df("dismount vol:%s", hs.inspect(vol))
                        local result, err = hs.fs.volume.eject(path)
                        if result then
                          log.df("Save info about %s for remount", hs.inspect(vol))
                        else
                          log.ef("Error ejecting %s:%s", path, err)
                        end
                      end
    end)
    hs.notify.show("USB", "", "Ejected ")
  else
    log.vf("ejectDisks called via key binding or device registration; mounted:%s", hs.inspect(mounted))
  end
end

local function reportDevices(device_table)
  -- replace devices usage of this function; instead generating repetitious code to report on the device
  -- The Yak Shave plan: add additional arguments to devices table to generate alternate code
  -- where USBDeviceActions' boolean connected/disconnected is insufficient.

  local function inc(key, event)
    local eventType
    if event then
      eventType = "connected"
    else
      eventType = "disconnected"
    end
    if not m.usbEvents[key] then
      m.usbEvents[key] = {}
      m.usbEvents[key]['connected'] = 0
      m.usbEvents[key]['disconnected'] = 0
    end
    log.vf("incrementing usbEvent[%s][%s]", key, eventType)
    m.usbEvents[key][eventType] = m.usbEvents[key][eventType] + 1
    return m.usbEvents[key]['connected'], m.usbEvents[key]['disconnected']
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
      log.vf("Created function to report %s", dev)
    else
      log.vf("Skipping redefinition for %s (%s != %s)", dev, t.fn, m.reportDevice)
    end
  end
end

-- Set up mapping between config.usb.devices and functions above
local function_mapping = {
  report = reportDevices,
  mount_encrypted = mountEncrypted,
  unmount_encrypted = dismountEncrypted,
  eject = ejectDisks,
  ignore = nil,
}

local function checkDevices (device_table)
  -- Generate initial 'reportDevices' definitions for all unregistered but attached USB devices
  local name
  local checked = {}
  for _, dev in ipairs(hs.usb.attachedDevices()) do
    name = dev["productName"]
    if name then
      if device_table[name] then
        -- Redundant with registerFunctions below?
        if type(device_table[name].fn) == "string" then
          local key = device_table[name].fn
          log.df("Replacing %s with %s", key, function_mapping[key])
          device_table[name].fn = function_mapping[key]
        else
          log.vf("Already checked %s", name)
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
  -- Replace devices' config function_mapping with the function reference itself
  for name, _ in pairs(device_table) do
    if type(device_table[name].fn) == "string" then
      local key = device_table[name].fn
      log.vf("Registering %s with mapping for %s: %s", name, key, function_mapping[key])
      device_table[name].fn = function_mapping[key]
    else
      log.vf("Already registered %s", name)
    end
  end
end

function m.init(modifiers)
  local config = load_config()
  m.config = config

  -- Merge/override personal devices into built-ins (typically ignored)
  for k, v in pairs(config.devices) do m.devices[k] = v end

  -- adjust devices reporting function calls
  registerFunctions(m.devices)
  checkDevices(m.devices)
  reportDevices(m.devices)

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
  config.eject_menu.hotkeys.ejectAll = { modifiers, config.keys.ejectall }
  log.vf("config.eject_menu:%s", hs.inspect.inspect(config.eject_menu))
  Install:andUse("EjectMenu", config.eject_menu)
  -- duplicative?
  hs.hotkey.bind(modifiers, config.keys["eject"], describe("Eject disks"), ejectDisks)

  m.watch = config.watch
  m.fs_watcher = watchForEncrypted()
end

return m
