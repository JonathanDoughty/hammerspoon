-- Some common functions
-- luacheck: globals hs load_module load_config script_path script_name find_script describe notify
-- luacheck: globals starts_with toLogLevel

local log = hs.logger.new("utils", "info")

local stack_level = 3 -- we want the info of the caller's source file

-- Deal with script metadata
local function script_directory()
  -- https://stackoverflow.com/a/23535333/1124740
  local str = debug.getinfo(stack_level, "S").source:sub(2)
  local path = str:match("(.*[/\\])") or "./"
  log.df("path: %s", path)
  return path
end

function script_name()
  local str = debug.getinfo(stack_level, "S").source:sub(2)
  local name = str:match(".*[/\\](.*)") or "??"
  log.df("name: %s", name)
  return name
end

function script_path()
  local path = script_directory() .. script_name()
  return path
end


function find_script(target, base_dir)
  local scripts_path = hs.fs.pathToAbsolute(base_dir)
  if scripts_path then
    -- Can't use pathToAbsolute because it resolves sym links
    -- and I've forgotten why it was necessary to avoid that
    local path = scripts_path .. '/' .. target
    if hs.fs.displayName(path) then
      return path
    else
      return nil
    end
  else
     log.wf("Can't resolve %s from %s", target, base_dir)
  end
end

-- Loading local functionality and configuration

local config_paths = {
  script_directory() .. 'configs/',  -- where personalized versions are looked for first
  script_directory() .. 'examples/', -- public, generic examples
}

function load_config()
  -- Load a configuration file found in a like-named config collection
  local name = script_name()
  local config_file = string.gsub( name, "(.lua)$", "_config%1")
  local directory = hs.fnutils.find(config_paths,
                                    function(directory)
                                      local path = directory .. config_file
                                      log.vf("find: %s", path)
                                      local f = io.open(path, "r")
                                      return f ~= nil and io.close(f)
                                    end
  )
  if directory then
    local handle
    local path = directory .. config_file
    handle = dofile(path)
    if handle then
      log.df("loaded config file %s for %s", path, name)
      return handle
    end
  else
    log.ef("Unable to load config file for %s from %s", name, directory)
    return nil
  end
end

function load_module(file)
  -- require file and report if loaded
  -- otherwise capture and report errors, providing a dummy handle with an init function
  local handle
  local loaded, msg
  loaded, msg = pcall(function () handle = require(file) end)
  if loaded then
    log.f("loaded %s", file)
  else
    log.ef("did NOT load %s\nmsg:%s\n", file, msg)
    handle = {
      init = function() log.f("module for %s was NOT loaded", file) end
    }
  end
  return handle
end

-- Expose what hs.logger does not
local LEVELS={nothing=0,error=1,warning=2,info=3,debug=4,verbose=5}
function toLogLevel(lvl)
  if type(lvl)=='string' then
    return LEVELS[string.lower(lvl)] or error('invalid log level',3)
  elseif type(lvl)=='number' then
    return math.max(0,math.min(5,lvl))
  else error('loglevel must be a string or a number',3) end
end

-- Other crutches

function describe(msg)
  return script_name() .. " - " .. msg
end

function notify(msg, seconds)
  if not seconds then
    seconds = 10
  end
  local note = hs.notify.new(
    {
      title = "Hammerspoon",
      informativeText = msg,
      withdrawAfter = seconds
    }
  )
  note:send()
  return note
end

function starts_with(str, start)
  return str:sub(1, #start) == start
end
