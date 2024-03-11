-- WebViews - set up for some standard web page views
-- luacheck: globals hs load_config describe

require("utils")

local m = {}
local log = hs.logger.new('webviews','info')
m.log = log

local screen_fraction = .85

local wv_browsers = {}

local function browserCallback(action, webview, frame_state)
   if action == "closing" then
     log.df("action %s, webview %s,\n  frame_state: %s", action, webview, hs.inspect(frame_state))
      hs.fnutils.each(wv_browsers,
                      function(entry)
                         log.df("entry %s", entry)
                         if entry == webview then
                            log.df("entry match: %s", entry)
                         else
                            log.df("no match: %s", entry)
                         end
                      end
      )
   else
      log.vf("no further action for %s", action)
   end
end

local function wvBrowser(def)
   local screenFrame = hs.screen.mainScreen():frame()
   local w = screenFrame.w * screen_fraction
   local h = screenFrame.h * screen_fraction
   local x = screenFrame.x + screenFrame.w / 2 - w / 2
   local y = screenFrame.y + screenFrame.h / 2 - h / 2
   local rect = hs.geometry.rect(x, y, w, h)
   local wv = hs.webview.newBrowser(rect)
   wv :url(def.url)
      -- :deleteOnClose(true)
      :windowCallback(browserCallback)
      :show()
   -- bringToFront keeps the browser on top of applications
   -- I just want it focused (on the top, temporarily, of other apps
   local win = wv:hswindow()
   win:focus()
   return wv
end

function m.toggle_webview (item)
  local key = item.key
  local browser = wv_browsers[key]
  if browser == nil then
    log.df("Creating browser for %s at %s on key", item.desc, item.url, key)
    wv_browsers[key] = wvBrowser(item)
    log.df("Opened %s", wv_browsers[key])
  else
    -- TODO check state and toggle off/on instead of removing key
    -- (though you need to deal with deleteOnClose too)
    log.df("Deleting %s", browser)
    wv_browsers[key] = nil
  end
end

-- Keep a table of browser objects, indexed by key, and toggle them on/off
-- TODO add default dimensions; replace state with preferred dimensions; pass def into wvBrowser instead of just url

function m.init(modifiers)

  local config = load_config()
  if config.logLevel then
    m.log.setLogLevel(config.logLevel)
  end

  local modal_key = config['modal'] or nil
  local bind_func

  if modal_key then
    local mode_name = "Webview mode"
    local modal = hs.hotkey.modal.new(modifiers, modal_key, mode_name)
    modal:bind('', 'escape', function() modal:exit() end)
    if log.level >= 4 then -- debug or verbose
      -- luacheck: push no unused args
      function modal:entered()
        log.df('Entered %s', mode_name)
      end
      function modal:exited()
        log.df('Exited %s', mode_name)
      end
      -- luacheck: pop
    end

    bind_func = function (item)
      log.df("Binding %s key %s for %s", mode_name, item.key, item.desc)
      modal:bind(modifiers, item.key,
                 function()
                   log.df("Toggling %s for %s on ", mode_name, item.desc, item.key)
                   modal:exit()
                   m.toggle_webview(item)
                 end
      )
    end

  else -- not modal_key

    bind_func = function (item)
      hs.hotkey.bind(modifiers, item.key, describe("Toggle web view for " .. item.desc), m.toggle_webview(item))
    end

  end
  hs.fnutils.each(config.views, bind_func)

end

m["browsers"] = wv_browsers

return m
