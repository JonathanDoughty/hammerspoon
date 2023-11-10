-- Unminimize/Open applications when they are activated via the macOS Application Switcher
-- A standard macos application switcher (Cmd-Tab) behavior I have always hated:
-- * Why if I select the app with Commmand-Tab would I NOT want the application to unminimize?
-- * What's the point of apps like Archive Utility that stay active when their job is done?
-- luacheck: globals hs load_config notify describe toLogLevel

local m = {}

-- WIP: Spoon (someday) metadata
m.name = "Switcher"
m.version = "0.5"
m.author = "Jonathan Doughty <jwd630@gmail.com>"
m.homepage = "https://github.com/JonathanDoughty/hammerspoon"
m.license = "MIT - https://opensource.org/licenses/MIT"

local log = hs.logger.new('switcher', 'info') -- debug/verbose for details while developing
m.log = log

require "utils" -- notify, describe, load_config

local watcher = hs.application.watcher

m.events = {} -- make 'em understandable
m.events[watcher.activated] = "activated"
m.events[watcher.deactivated] = "deactivated"
m.events[watcher.hidden] = "hidden"
m.events[watcher.launched] = "launched"
m.events[watcher.launching] = "launching"
m.events[watcher.terminated] = "terminated"
m.events[watcher.unhidden] = "unhidden"
m.currentApp = hs.application.frontmostApplication() -- don't start with nil

m.appState = {}

local function actOnAppActivation(appName, appObject)
  local windows = appObject:allWindows()
  local minimized = 0
  local standard = 0
  local visible = 0

  local function collectAllMinimizedWindowStats (w)
    if w:isVisible() then
      visible = visible + 1
    end
    if w:isMinimized() then
      minimized = minimized + 1
    end
    if w:isStandard() then
      standard = standard + 1
    end
    log.vf("minimized %s visible: %s standard %s",
           w:isMinimized(), w:isVisible(), w:isStandard())
    return w:isMinimized()
  end

  local function unMinimize (w)
    if w:isMinimized() then
      log.df("Unminimizing %s window for %s", (w:isStandard() and 'standard' or 'non-standard'),
             w:application():name())
      w:unminimize()
    else
      log.vf("Ignoring window for %s", w:application():name())
    end
  end

  local function executeSpecialCaseAction (e)
    -- Some apps are special, run their associated action
    -- Finder is one, since it always has a Desktop window
    local result = false
    if e.app == appName then
      if e.action then
        log.df("Last app %s event %s", m.lastApp, m.lastEvent)
        if m.lastEvent ~= "terminated" then
          result = hs.osascript.applescript(e.action)
          log.df("Invoked '%s' on %s -  returned %s", e.action, appName, result)
        else
          -- Avoid unneccesary Finder activations
          -- Is this the right thing for all special cases?
          log.df("Previous event was termination of %s, ignoring special case activation of %s", m.lastApp, appName)
        end
      end
    end
    return result
  end

  local function terminateWindowless(candidates)
    log.vf("checking for any apps in termination candidates %s", hs.inspect(m.config.termination_candidates))
    local apps = hs.application.runningApplications()

    hs.fnutils.each(apps,
                    function(app)
                      if hs.fnutils.contains(candidates, app:name()) then
                        local ws = app:allWindows()
                        if #ws == 0 then -- Note: this is only in current Space
                          log.f("terminating windowless %s", app:name())
                          app:kill()
                        else
                          log.vf("not terminating %s with %d windows", app:name(), #ws )
                        end
                      end
    end)
  end

  log.vf("%s has %d windows", appName, #windows)
  if #windows > 0 and hs.fnutils.every(windows, collectAllMinimizedWindowStats) then
    -- ... when every app window is minimized, then unminimize ALL minimized windows
    log.f("Unminimizing %d minimized, %d visible, %d standard windows?", visible, minimized, standard)
    -- if this was reduce rather than each we might unminimize just the first minimized window
    hs.fnutils.each(windows, unMinimize)
  elseif m.lastObserved ~= m.currentApp then
    log.f("Not acting on activated never current %s", m.lastObserved:name())
  elseif hs.fnutils.some(m.config.special_cases, executeSpecialCaseAction) then
    log.vf("Special case for %s with %d windows, %d visible, %d minimized, %d standard",
          appObject:name(), #windows, visible, minimized, standard)
  elseif #windows == 0 then
    hs.application.launchOrFocus(appName)
    log.f("Launched/focused %s", appName)
  elseif visible > 0 then
    -- at least one is visible? Normal switching behavior is what I like
    log.vf("No action taken for %s with %d windows, %d visible, %d minimized, %d standard",
          appObject:name(), #windows, visible, minimized, standard)
  else
    log.f("Unexpected state for %s with %d windows, %d visible, %d minimized, %d standard",
          appObject:name(), #windows, visible, minimized, standard)
  end

  -- After current actions complete
  hs.timer.doAfter(2, function ()
                     terminateWindowless(m.config.termination_candidates)
  end)
end

function m.applicationWatcher(appName, eventType, appObject)
  -- Override 'normal' Mac behavior: when app has been activated under certain conditions.
  -- Unminimizes apps where all windows are minimized or when activated app has no windows,
  -- allowing for special cases and ignoring some activated apps that don't have the usual
  -- GUI behavior.

  if appName and appName ~= "Hammerspoon" then
    m.lastObserved = appObject  -- check all but Hammerspoon
    if not hs.fnutils.contains(m.config.never_current, appName) then
      -- Keep track of 'current' app - modulo those that are never 'current' - to have an event
      m.currentApp = appObject
    else
      log.vf("%s never current, ignoring %s", appName, m.events[eventType])
      return
    end

    if eventType == watcher.activated then
      log.vf("acting on activation of %s", appName)
      actOnAppActivation(appName, appObject)
    else
      m.lastEvent = m.events[eventType]
      m.lastApp = appName
      m.appState[appName] = m.events[eventType]
      log.vf("%s %s", appName, m.events[eventType])
    end
  elseif not appObject then
    -- appName and appObject can (rarely) be nil when the application has been quit
    log.df("appName/appObject nil, %s; lastApp %s", m.events[eventType], m.lastApp)
  end
end

local function windowSubscriber(window, appName, event)
  -- Records the last event associated with an app, e.g, hidden, windowNotVisible when hidden or minimized.
  -- Not currently used otherwise.
  log.df("subscriber: %s window %s event %s", appName, window:title(), event)
  m.appState[appName] = event
end

local function nextScreen(screen)
  -- Rotate through the available screens
  local screens = hs.screen.allScreens()
  for n, s in ipairs(screens) do
    if screen == s then
      local nextScreenNumber = n + 1
      if nextScreenNumber > #screens then
        nextScreenNumber = 1
      end
      log.vf("Next screen for %d is %d %s", n, nextScreenNumber, screens[nextScreenNumber])
      return screens[nextScreenNumber]
      end
  end
end

local function moveAppWindow()
  -- Move the currently focused window's app's windows (those that are on the same screen) to the next screen
  local focusedWindow = hs.window.focusedWindow()
  local focusedApp = focusedWindow:application()
  if focusedApp then
    local screens = hs.screen.allScreens()
    if #screens > 1 then
      local windows = focusedApp:allWindows()
      local initialScreen = focusedWindow:screen()
      local destinationScreen = nextScreen(initialScreen)
      local moved = 0
      for _, w in ipairs(windows) do
        -- Move visible windows - including popups, modals, floating - from same screen as
        -- focused window. (Only standard windows misses those apps that annoyingly start as popups.)
        log.vf("Window %s (visible %s) on screen %s", w:title(), w:isVisible(), w:screen())
        if w:screen() == initialScreen and w:isVisible() then
          log.df("Moving window %s with role %s on screen %s to %s", w:title(), w:role(), w:screen(), destinationScreen)
          w:moveToScreen(destinationScreen, true, true)
          moved = moved + 1
        end
      end
      log.f("Moved %d of %d %s windows to %s", moved, #windows, focusedApp:name(), destinationScreen)
    else
      log.i("No destinationScreen to move to, centering")
      focusedWindow:centerOnScreen(nil, true)
    end
  else
    log.i("No focused app")
  end
end

function m.init(modifiers)
  m.config = load_config()
  if ( log.getLogLevel() ~= toLogLevel(m.config.loglevel) ) then
    log.setLogLevel(m.config.loglevel)
  end
  m.appWatcher = hs.application.watcher.new(m.applicationWatcher)
  m.appWatcher:start()

  local wf = hs.window.filter
  local subscribedEvents = {
    wf.windowCreated,
    wf.windowDestroyed,
    wf.windowFocused,
    wf.windowHidden,
    wf.windowMinimized,
    wf.windowNotVisible,
  }
  wf.setLogLevel('warning') -- the default of info (3) is a bit too verbose
  m.windowFilter = wf.new(true, 'wf', 'info' )
  if m.config["subscribe"] then
    -- Disabled when it seemed like subscriber handling was causing modal password mis-handling.
    -- That turned out not to be the case, so I made enabling subscribed events a config option.
    m.windowFilter:subscribe(subscribedEvents, windowSubscriber)
  end
  -- hotkey based screen mover
  hs.hotkey.bind(modifiers, m.config["move"], describe("Move app"), moveAppWindow)

end

return m
