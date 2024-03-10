-- Key bindings for Keychain password access
-- luacheck: globals hs load_config notify

local m = {}

-- WIP: Spoon (someday) metadata
m.name = "Passwords"
m.version = "0.7"
m.author = "Jonathan Doughty <jwd630@gmail.com>"
m.homepage = "https://github.com/JonathanDoughty/hammerspoon"
m.license = "MIT - https://opensource.org/licenses/MIT"

-- This predates the [Keychain Spoon](https://www.hammerspoon.org/Spoons/Keychain.html) that I
-- discovered a couple years after this became a crutch for continuous requests for login and
-- password manager credentials. While the basic idea is similar this uses 'internet' - host
-- specific - as well as 'generic' Keychain passwords.  The Keychain Spoon would provide a nice
-- Hammerspoon interface to adding passwords to macOS Keychain, something I just use a terminal
-- and the included update_password.sh script for.

local log = hs.logger.new('passwords','info')
local exe = '/usr/bin/security' -- used to access to Keychain content

require "utils"

m.log = log

function m.secureInputNotEnabled()
  local enabled = hs.eventtap.isSecureInputEnabled() -- 11.3 seems to have broken
  log.vf("secure input enabled %s", enabled)
  return not enabled
end

-- Pull the type (generic/internet) password associated with service from Keychain
function m.extractPassword(pwType, service)
  local keychainCmd = "find-" .. pwType .. "-password"
  local cmd = string.format("%s %s -s '%s' -a %s -w", exe, keychainCmd, service, os.getenv("USER"))
  local p, _ = hs.execute(cmd)
  if string.len(p) > 0 then
    log.df("extracted with `%s`", cmd)
    p = string.gsub(p, "\n", "") -- trim newline
  else
    log.wf("%s returned nil or 0 length string", cmd)
    notify("Unable to extract password from Keychain using " .. cmd)
  end
  return p
end

local keyboard_chars = {
  -- ToDo: seems hs.keycodes should have a better way
  -- it does, though '+' is at least one oddity
  ['~'] = { mod='shift', chr='`'}, ['!'] = { mod='shift', chr='1'},
  ['@'] = { mod='shift', chr='2'}, ['#'] = { mod='shift', chr='3'},
  ['$'] = { mod='shift', chr='4'}, ['%'] = { mod='shift', chr='5'},
  ['^'] = { mod='shift', chr='6'}, ['&'] = { mod='shift', chr='7'},
  ['*'] = { mod='shift', chr='8'}, ['('] = { mod='shift', chr='9'},
  [')'] = { mod='shift', chr='0'}, ['_'] = { mod='shift', chr='-'},
  ['+'] = { mod='shift', chr='='},
  ['{'] = { mod='shift', chr='['}, ['}'] = { mod='shift', chr=']'},
  ['|'] = { mod='shift', chr='\\'},
  [':'] = { mod='shift', chr=';'}, ['"'] = { mod='shift', chr='\''},
  ['<'] = { mod='shift', chr=','}, ['>'] = { mod='shift', chr='.'},
  ['?'] = { mod='shift', chr='/'},
  [' '] = { mod=nil, chr='space'},
  ["\n"] = { mod=nil, chr='return'},
  ["	"] = { mod=nil, chr='tab'},
}


function m.keyStrokeCharacter(c)
  local delay = 200 -- key down/up delay in microseconds
  if string.match(c, "[%u]") then  -- uppercase
    hs.eventtap.keyStroke({"shift"}, c, delay)
  elseif string.match(c, "[%l%d]") then -- lowercase or digit
    hs.eventtap.keyStroke(nil, c, delay)
  else
    local keyboard_char = keyboard_chars[c]
    if keyboard_char then
      hs.eventtap.keyStroke(keyboard_char.mod, keyboard_char.chr, delay)
    else
      local no_err, msg = pcall(function () hs.eventtap.keyStroke(nil, c, delay) end)
      if not no_err then
        log.wf("No mapping for %s err:", c, msg)
      end
    end
  end
end

-- formerly used
function m.keyStrokeCharacters(chars)
    local delay = 200 -- key down/up delay in microseconds
    log.vf("keyStrokeCharacters %s", chars)
    chars:gsub(".",
               function(c)
                 if string.match(c, "[%u]") then  -- uppercase
                   hs.eventtap.keyStroke({"shift"}, c, delay)
                 elseif string.match(c, "[%l%d]") then -- lowercase or digit
                   hs.eventtap.keyStroke(nil, c, delay)
                 else
                   local code = hs.keycodes.map[c]
                   log.ef("Char %s NOT stroked",  code)
                 end
    end)
end

function m.keystrokeFromPasteboardContents()
  log.vf("Keystroke pasteboard contents from %s", hs.inspect(m.lastPassword))
  if m.lastPassword then
    local passPhrase = m.extractPassword(m.lastPassword.pwType, m.lastPassword.service)
    if passPhrase then
      hs.pasteboard.setContents(passPhrase)
      -- Clear this from pasteboard after the configured timeout, default being 10 secs
      hs.timer.doAfter(m.config.timeout, function()
                         hs.pasteboard.clearContents()
                         log.df("Cleared passPhrase from pasteboard")
      end)
    end
    -- else lastPassword has expired, fall through to stroking raw pasteboard contents
  end
  local content = hs.pasteboard.getContents()
  if content then
    content:gsub(".", m.keyStrokeCharacter)
  else
    log.ef("No content in pasteboard:%s", hs.pasteboard.getContents())
  end
end

function m.getPasswordAndKeystroke(pwDef)
  local passPhrase = m.extractPassword(pwDef.pwType, pwDef.service)
  if m.secureInputNotEnabled() then
    hs.eventtap.keyStrokes(passPhrase)
  else
    if m.config.timeout and m.config.timeout > 0 then
      log.df("Secure input enabled, keyStroking from clipboard")
      m.lastPassword = pwDef -- save for keystrokeFromPasteboardContents use
      hs.timer.doAfter(m.config.timeout, function() m.lastPassword = nil end)
      m.keystrokeFromPasteboardContents()
    else
      log.f("timeout %d - secure input field key stroking disabled", m.config.timeout)
    end
  end
end

function m.strokingFunctions(pwd_mapping)
  -- Set up and return a table of functions to stroke password characters

  local function strokePassword()
    if m.modal then
      m.modal:exit()
    end
    log.vf("Stroke password for %s", pwd_mapping.desc)
    m.getPasswordAndKeystroke(pwd_mapping)
  end

  local function strokeFromPasteboard()
    if m.modal then
      m.modal:exit()
    end
    log.vf("Stroke from pasteboard for %s", pwd_mapping.desc)
    m.keystrokeFromPasteboardContents()
  end

  local stroke_funcs = {
    ["internet"] = strokePassword,
    ["generic"] = strokePassword,
    ["clipboard"] = strokeFromPasteboard,
  }
  return stroke_funcs
end

function m.modalKeyBinder(modifiers, modal_keys)
  local modal = hs.hotkey.modal.new(modifiers, modal_keys, "Password mode")
  m.modal = modal
  modal:bind('', 'escape', function() modal:exit() end)
  if log.level >= 4 then -- debug or verbose
    -- luacheck: push no unused args
    function modal:entered()
      log.d('Entered password mode')
    end
    function modal:exited()
      log.d('Exited password mode')
    end
    -- luacheck: pop
  end

  -- Return a function that will be called for each key to be mapped for a modal
  local binder = function (pwd_mapping)
    log.f("Binding password mode key %s of type %s for %s", pwd_mapping.bindTo,
          pwd_mapping.pwType, pwd_mapping.desc)
    local funcs = m.strokingFunctions(pwd_mapping)
    local func = funcs[pwd_mapping.pwType]
    if (func) then
      modal:bind('', pwd_mapping.bindTo, func)
    else
      log.ef("Unrecognized password stroking type %s", pwd_mapping.pwType)
    end
  end
  return binder
end

function m.modifierKeyBinder(modifiers)

  -- Return a function that will be called for each key to be direct mapped
  local binder = function (pwd_mapping)
    log.f("Binding password key %s%s of type %s for %s",
           table.concat(modifiers), string.upper(pwd_mapping.bindTo),
           pwd_mapping.pwType, pwd_mapping.desc)
    local binding
    local funcs = m.strokingFunctions(pwd_mapping)
    local func = funcs[pwd_mapping.pwType]
    if (func) then
      binding = hs.hotkey.bind(modifiers, pwd_mapping.bindTo, func)
      pwd_mapping.bindTo = binding -- replace key with actual binding
    else
      log.ef("Unrecognized password stroking type %s", pwd_mapping.pwType)
    end
  end
  return binder
end

function m.init(modifiers)
  local config = load_config()
  m.config = config
  if config.loglevel then
    log.setLogLevel(config.loglevel)
  end

  local modal_keys = config['modal'] or nil
  local keyBinder
  -- Select function to bind either modal/key or modifier/key mapping
  if modal_keys then
    keyBinder = m.modalKeyBinder(modifiers, modal_keys)
  else -- not modal, bind to global keyboard shortcut
    keyBinder = m.modifierKeyBinder(modifiers)
  end

  -- bind each defined password definition to its key
  if config['passwords'] then
    hs.fnutils.each(config['passwords'], keyBinder)
  end

end

return m
