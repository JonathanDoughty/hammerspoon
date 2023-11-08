-- Watch for / react to wifi events; Toggle Network location
-- luacheck: globals hs load_config describe

require "utils"

local m = {}

m.log = hs.logger.new('wifi','debug')

-- ToDo Is http://www.hammerspoon.org/Spoons/WifiNotifier.html a (partial) replacement?

function m.ssidChangedCallback()
  local currentSSID = hs.wifi.currentNetwork()

  if currentSSID == nil then
    m.log.v("wifi disabled")
  elseif currentSSID == m.homeSSID and m.lastSSID ~= m.homeSSID then
    -- Joined our home WiFi
    hs.audiodevice.defaultOutputDevice():setVolume(25)
  elseif currentSSID ~= m.homeSSID and m.lastSSID == m.homeSSID then
    -- Departed our home WiFi
    hs.audiodevice.defaultOutputDevice():setVolume(0)
  elseif currentSSID == m.homeSSID then
    -- Still on home WiFi
    hs.audiodevice.defaultOutputDevice():setVolume(25)
  else
    m.log.wf("Joining unrecognized network SSID:%s", currentSSID)
    -- hs.speech.new():speak("Joining " .. currentSSID .. " network")
  end
  m.lastSSID = currentSSID
end

function m.toggleNetwork ()
  -- Designed to enable me to easily switch between two network 'locations', having multiple
  -- wired and wireless interfaces, enabled (on-line) and disabled (off-line).

  local function swapKeysWithValues(t)
    local inverted={}
    for k,v in pairs(t) do
      inverted[v]=k
    end
    return inverted
  end

  local location = m.config:location()
  local uuid = string.gsub(location, "/Sets/", "")
  local locations_by_uuid = m.config:locations()
  local uuids_by_location = swapKeysWithValues(locations_by_uuid)
  local current_location = locations_by_uuid[uuid]
  local desired_location = m.desired_location_from[current_location]
  local msg

  if not desired_location then
    msg = string.format("Configured locations '%s' and '%s' not defined in Network Settings",
                        m.config.on_line, m.config.off_line)
    hs.notify.show("Network", "No Location", msg)
    m.log.e(msg)
    return
  end

  uuid = uuids_by_location[desired_location]
  m.log.df("Setting location to %s (%s) from %s", uuid, desired_location, current_location)
  if m.config:setLocation(uuid) then
    msg = string.format("Changed location to %s", desired_location)
    m.log.i(msg)
  else
    msg = string.format("Unable to change from location %s to %s",
                        current_location, desired_location)
    m.log.e(msg)
  end
  hs.notify.show("Network", "", msg)
end

function m.init(modifiers)
  local config = load_config()
  m.config = config
  m.homeSSID = config["home_ssid"]
  m.lastSSID = hs.wifi.currentNetwork()
  m.wifiWatcher = hs.wifi.watcher.new(m.ssidChangedCallback)
  m.wifiWatcher:start()
  m.desired_location_from = {
    [config.on_line] = config.off_line,
    [config.off_line] = config.on_line
  }
  m.config = hs.network.configuration.open()
  hs.hotkey.bind(modifiers, config["network"], describe("Toggle network on/off line"), m.toggleNetwork)
end

return m
