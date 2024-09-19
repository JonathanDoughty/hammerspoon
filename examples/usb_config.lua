-- configuration for usb.lua preferences
-- luacheck: globals hs

local usb_config = {
  loglevel = "info",            -- the default, adjust for more or less detail
  devices = {
    --  Personal devices get merged with / override built-in ones from usb.lua
    ["Apple Keyboard"] = { fn = 'report' }, -- External keyboard
    ["Keyboard Hub"] = { fn = 'report' }, -- External Apple keyboard
    ["iPhone"] = { fn = 'report'},
  },
  modal = "u",
  keys = {
    eject = "e",
    ejectall = "a",             -- EjectMenu
  },
  eject_menu = {
    enabled = false,
    config = { -- EjectMenu Spoon http://www.hammerspoon.org/Spoons/EjectMenu.html definitions
      -- see https://zzamboni.org/post/my-hammerspoon-configuration-with-commentary/#unmounting-external-disks-on-sleep
      show_in_menubar = true,
      never_eject = {             -- ignore these volumes
        "/Volumes/Music",         -- Network storage
      },
      notify = true,
      eject_on_lid_close = false, -- normal default
      other_eject_events = {
        -- hs.caffeinate.watcher.systemWillSleep,  -- default
        hs.caffeinate.watcher.systemWillPowerOff,
        hs.caffeinate.watcher.sessionDidResignActive
      },
    },
    hotkeys = { ejectAll = {} }, -- updated by usb.init
    loglevel = 'info',           -- for EjectMenu spoon logger
    start = true,
    disable = false,
  },
  watch = {
    { volume = "/Volumes/ThumbDrive", -- with encrypted conatiner
      mount = "mount_encrypted",      -- script to mount
      unmount = "unmount_encrypted" }, -- script to unmount
  },
}
return usb_config
