-- Configuration for wifi.lua preferences
-- luacheck: globals hs

local config_log = hs.logger.new('wifi', 'debug')

local wifi_config = {
  log = config_log,
  home_ssids = { "Home_WiFi_SSID", "Other_Recognized_Wifi_SSID",},
  home_network_actions = { -- functions called when joining or leaving home_ssids
    join = function()
      config_log.df("Joined home network")
    end,
    leave = function()
      config_log.df("Left home network")
    end,
  },
  -- These require the definition of System Settings ... Network ... ... Locations
  -- with 'locations' defined for on_line and off_line interface states
  on_line = "AllInterfacesEnabled",
  off_line = "AllInterfacesDisabled",
  toggle_key = "o", -- key binding: think online/offline
}
return wifi_config
