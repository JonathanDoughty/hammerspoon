-- WebViews - set up bindings to display some web page viewers
-- luacheck: globals hs load_config describe

require("utils")

local m = {}
local log = hs.logger.new('webviews','info')
m.log = log

local screen_fraction = .85

m.refs = {}

local function browserCallback(action, webview, frame_state)
   if action == "closing" then
     log.df("action %s, webview %s,\n  frame_state: %s", action, webview, hs.inspect(frame_state))
      hs.fnutils.each(m.refs,
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
   -- Create a hs.webview browser that is screen_fraction of the main screen's height and width
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

local function toggle_view(item)
  local ref = m.refs[item.key]
  if ref == nil then
    log.df("Creating view for %s at %s on key", item.desc, item.url, item.key)
    ref = wvBrowser(item)
    log.df("Opened view %s", item.key)
  else
    -- TODO check state and toggle off/on instead of removing key
    -- (though you need to deal with deleteOnClose too)
    log.df("Deleting %s", ref)
    ref = nil
  end
  m.refs[item.key] = ref
end

local function toggle_doc(item)
  -- Start/stop the Hammerspoon internal documentation web server
  local ref = m.refs[item.key]
  if not ref then
    log.df("Starting %s at %s on key %s", item.desc, item.url, item.key)
    ref = require("hs.doc.hsdocs").start()
    local cmd = string.format("open location \"%s\"", item.url)
    local result = hs.osascript.applescript(cmd)
    if not result then
      log.ef("%s resulted in %s", cmd, result)
    end
  else
    hs.doc.hsdocs.stop()
    ref = nil
  end
  m.refs[item.key] = ref
end

function m.toggle (obj)
  -- Invoke functions that will maintain a table of viewers, indexed by key, toggling them on/off

  local type_funcs = {
    view = toggle_view,
    doc  = toggle_doc,
  }

  type_funcs[obj.type](obj)
end

function m.setupBindings (config, modifiers)

  local function binder(modal_key)
    local mode_name = "Webview mode"
    if modal_key then
      local modal = hs.hotkey.modal.new(modifiers, modal_key, mode_name)
      modal:bind('', 'escape', function() modal:exit() end)
      if log.level >= 4 then -- debug or verbose
        -- luacheck: push no unused args
        function modal:entered()
          log.df('Entered modal %s', mode_name)
        end
        function modal:exited()
          log.df('Exited modal %s', mode_name)
        end
        -- luacheck: pop
      end

      return function (item)
        log.df("Binding %s modal key %s %s for %s", mode_name, table.concat(modifiers), item.key, item.desc)
        modal:bind(modifiers, item.key, mode_name,
                   function()
                     log.df("Toggling %s for %s on %s", mode_name, item.desc, item.key)
                     modal:exit()
                     m.toggle(item)
                   end
        )
      end
    else -- not using modal keys
      return function (item)
        log.df("Binding key %s %s for %s", table.concat(modifiers), item.key, item.desc)
        hs.hotkey.bind(modifiers, item.key, describe("Toggle for " .. item.desc), m.toggle(item))
      end

    end
  end

  local bind_func = binder( config['modal'] or nil, modifiers )
  hs.fnutils.each(config.views, bind_func)
end

function m.receiveFromSystem(text)
   -- Handle text sent via Services... Send to Hammerspoon or drag and drop
   m.log.f("Received text %s - further processing yet to be implemented", text)
   -- TBD - this wasn't as useful as I'd hoped; which was to get URLs from links
end

function m.receiveFile(filePath)
   -- Handle files sent via Services... Send to Hammerspoon or drag and drop
   m.log.f("Received path %s - further processing yet to be implemented", filePath)
   -- TBD - Here as a placeholder
end

function m.init(modifiers)

  local config = load_config()
  if config.logLevel then
    m.log.setLogLevel(config.logLevel)
  end

  m.setupBindings(config, modifiers)

  -- Register drag & drop / Services... Send to Hammerspoon callbacks
  hs.textDroppedToDockIconCallback = m.receiveFromSystem
  hs.fileDroppedToDockIconCallback = m.receiveFile
end

return m
