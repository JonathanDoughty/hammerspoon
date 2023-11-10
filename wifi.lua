-- Watch for / react to wifi events; Toggle Network location
-- luacheck: globals hs load_config describe

require "utils"

local m = {}

m.log = hs.logger.new('wifi','debug')

-- ToDo Is http://www.hammerspoon.org/Spoons/WifiNotifier.html a (partial) replacement?

function m.ssidChangedCallback(_, _, _)

  local function previousWiFiWasHome()
    local function wifiWasHomeSSID(e)
      m.log.vf("last %s == %s", m.lastSSID, e)
      local lastSSIDWasHome = m.lastSSID == e
      return lastSSIDWasHome
    end
    local lastWifiWasHome = hs.fnutils.some(m.homeSSIDs, wifiWasHomeSSID)
    m.log.df("LastWifiWasHome: %q", lastWifiWasHome)
    return lastWifiWasHome
  end

  local function joinedHomeSSID(currentSSID)
    local home = hs.fnutils.contains(m.homeSSIDs, currentSSID)
    local lastWasHome = previousWiFiWasHome()
    local joinedHome = home and not lastWasHome
    m.log.vf("%s, joined home? returning %q home: %q last (%s) home? %q",
             currentSSID, joinedHome, home, m.lastSSID, lastWasHome)
    return joinedHome
  end

  local function leftHomeSSID(currentSSID)
    local notHome = not hs.fnutils.contains(m.homeSSIDs, currentSSID)
    local lastWasHome = previousWiFiWasHome()
    local leftHome = notHome and lastWasHome
    m.log.vf("leftHomeSSID %s, home? returning %q not home: %q? last (%s) was home? %q",
             currentSSID, leftHome, notHome, m.lastSSID, lastWasHome)
    return leftHome

  end

  local function actOnChangeTo(currentSSID)
    if currentSSID == nil or currentSSID == "" then
      m.log.v("Wi-Fi disabled")
    elseif joinedHomeSSID(currentSSID) then
      m.log.df("Joined home SSID %s", currentSSID)
      if m.config.home_network_actions and m.config.home_network_actions.join then
        m.config.home_network_actions['join']()
      else
        m.log.w("No joining home network action defined")
      end
    elseif leftHomeSSID(currentSSID) then
      m.log.df("Left home SSID to join %s", currentSSID)
      if m.config.home_network_actions and m.config.home_network_actions.leave then
        m.config.home_network_actions['leave']()
      else
        m.log.w("No leaving home network action defined")
      end
    else
      m.log.wf("Joining unrecognized network SSID:%s", currentSSID)
    end
  end

  local currentSSID = hs.wifi.currentNetwork() or ""
  actOnChangeTo(currentSSID)
  m.lastSSID = currentSSID
end

function m.toggleNetwork ()
  -- Intended to easily switch between two network 'locations', having multiple
  -- wired and wireless interfaces, enabled (on-line) and disabled (off-line).

  local function swapKeysWithValues(t)
    local inverted={}
    for k,v in pairs(t) do
      inverted[v]=k
    end
    return inverted
  end

  local location = m.netconfig:location()
  local uuid = string.gsub(location, "/Sets/", "")
  local locations_by_uuid = m.netconfig:locations()
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
  if m.netconfig:setLocation(uuid) then
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
  if config.log then
    m.log = config.log          -- replace default log
  end
  m.config = config
  m.homeSSIDs = config["home_ssids"]
  m.desired_location_from = {  -- state transitions for toggling network
    [config.on_line] = config.off_line,
    [config.off_line] = config.on_line
  }
  m.lastSSID = hs.wifi.currentNetwork() or ""
  m.wifiWatcher = hs.wifi.watcher.new(m.ssidChangedCallback)
  m.wifiWatcher:start()
  m.netconfig = hs.network.configuration.open()
  if config["toggle_key"] then
    hs.hotkey.bind(modifiers, config["toggle_key"], describe("Toggle network on/off line"), m.toggleNetwork)
  end
end

return m
