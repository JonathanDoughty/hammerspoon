-- Configuration for sleepwatcher preferences

local sleepwatcher_config = {
  loglevel = "debug",
  enabled = false,
  unmounts = { --  Volumes to unmount on sleep
    "ExternalDisk",
  },
}

return sleepwatcher_config
