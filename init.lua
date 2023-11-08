-- init.lua -- hammerspoon controller
-- luacheck: globals hs load_module load_config mod ins cfg notify cls

require "utils"

hs.logger.defaultLogLevel = "info"
local log = hs.logger.new("init")

cfg = load_config()

local function local_modules(mod, modifiers)
  mod.bindings = load_module("bindings") -- ModalMgr set up and miscellaneous key bindings
  mod.bindings.init(modifiers, cfg.script_config['bindings'])

  mod.passwords = load_module("passwords") -- Passwords from Keychain at a key press
  mod.passwords.init(modifiers)

  mod.sleepwatcher = load_module("sleepwatcher") -- Act on sleep/wake events
  mod.sleepwatcher.init()

  mod.webviews = load_module("webviews") -- Web page browsers and related key bindings
  mod.webviews.init(modifiers)

  mod.wifi = load_module("wifi") -- Watch for Wifi changes, toggle network location
  mod.wifi.init(modifiers)

  mod.switcher = load_module("switcher") -- Raise on activation
  mod.switcher.init(modifiers)

  mod.fs_watcher = load_module("fs_watcher") -- Act on filesystem activity
  mod.fs_watcher.init()
end

local function spoon_wrappers(mod, modifiers)
  -- Configure and load official Spoons - https://github.com/Hammerspoon/Spoons

  mod.usb = load_module("usb") -- Watch for USB events
  mod.usb.init(modifiers)

  mod.tm_progress = load_module("tm_progress") -- TimeMachineProgress
  mod.tm_progress = mod.tm_progress.init("info", false)

  mod.window_mgr = load_module("window_mgr") -- Window management
  mod.window_mgr.init(modifiers, cfg.script_config['window_mgr'])

  mod.caffeine = load_module("caffeine") -- Caffeine/caffeinate replacement
  mod.caffeine.init(modifiers)

  mod.ksheet = load_module("ksheet") -- Cheatsheet replacement
  mod.ksheet.init(modifiers, cfg.script_config['ksheet'])
end

local function work_config(mod, modifiers)
  local this_host = hs.host.localizedName()

  -- Work specific initialization
  if cfg.work then
    if not ( this_host == cfg.hostname or this_host == cfg.work.hostname ) then
      notify("Hostname " .. this_host .. " not recognized for work config", 0)
    elseif this_host == cfg.work.hostname then
      mod.log.i("\n%s\nInitializing work functions", string.rep('_', 50))
      mod.work = cfg.work.init(modifiers, cfg.work.defs)
      mod.log.vf("work init returned %s", hs.inspect(mod.work))
    else
      mod.log.f("No work functions for host %s, unloading.", cfg.hostname)
      cfg.work = nil
    end
  end
end

local function watch_config(mod)
  -- Finally, a watcher for when any of this changes
  -- ToDo Is there a way to just check a list of required scripts?
  mod.autoreloader = load_module("auto_reload") -- Watch for config file changes
  mod.autoreloader.init()
end

local function hammerspoon_tweaks(mod)
  load_module("hs.ipc") -- enable Hammerspoon access from the command line

  if mod.log.level < 4 then
    hs.console.clearConsole()
  else
    -- debug or greater leave console as is, except add convenience aliases
    cls = hs.console.setConsole
  end
end

local function init()
  log.i("Started")
  mod = {}
  mod.log = log

  mod.log.setLogLevel(cfg.log_level)

  load_module("utils")

  ins = hs.inspect -- convenience function

  local modifiers = cfg.hyper or "alt"

  local_modules(mod, modifiers)
  spoon_wrappers(mod, modifiers)
  work_config(mod, modifiers)
  hammerspoon_tweaks(mod)
  watch_config(mod)
end

init()
