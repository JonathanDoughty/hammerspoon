-- Configuration for wifi.lua preferences

local wifi_config = {
  network = "o", -- key binding: think online/offline
  home_ssid = "Home_WiFi_SSID",
  -- These require the definition of System Settings ... Network ... ... Locations
  -- with 'locations' defined for on_line and off_line
  on_line = "AllInterfacesEnabled",
  off_line = "AllInterfacesDisabled",
}
return wifi_config
