-- -*- Mode: lua; tab-width: 2; lua-indent-level: 2; indent-tabs-mode: nil; -*-

--
-- if you want use lovelive then
--   use app.lua instead of main.lua
-- end
--


local arg, app, conf, t0
local errormsg

local load_module = function(mod, reload)
  local m = require(mod)
  if reload then
    if m.reload then
      m.reload()
    end
  else
    if m.load then
      m.load(arg)
    end
  end
  return m
end

local reload_module = function(mod, gc)
  -- this return (module, errormsg) pair
  local package = require("package")
  if package.loaded[mod] == nil then
    -- initial load
    return load_module(mod, false), nil 
  else
    -- reload
    local oldmod = package.loaded[mod]
    package.loaded[mod] = nil
    if gc then
      collectgarbage("collect")
    end
    local ok, obj = pcall(load_module, mod, true)
    if ok then
      return obj, nil
    else
      package.loaded[mod] = oldmod
      return oldmod, obj
    end
  end
end

local loadliveconf = function()
  local c = {
    -- default config
    live = true,
    use_pcall = true,
    autoreload = {
      enable = true,
      interval = 1.0
    },
    reloadkey = "f5",
    gc_before_reload = false,
    error_file = nil
  }
  if app.liveconf then
    app.liveconf(c)
  end
  if not c.live then
    c.autoreload.enable = false
    c.use_pcall = false
    c.reloadkey = nil
  end
  return c
end

local draw_msg = function(msg)
  love.graphics.clear()
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.print(msg, 0, 0)
end

local set_error = function(msg)
  if msg then
    if msg ~= errormsg then
      errormsg = msg
      print(errormsg)
    end
    if conf.error_file then
      local f = io.open(conf.error_file, "a+")
      f:write(errormsg .. "\n\n")
      f:flush()
      f:close()
    end
  else
    errormsg = nil
  end
end

local reload = function()
  local msg
  app, msg = reload_module("app", conf.gc_before_reload)
  if (not msg) and errormsg then
    print("live: recover from error state.")
  end
  set_error(msg)
end


local call = function(name, ...)
  if not app[name] then
    return
  end
  if conf.use_pcall then
    local ok, err = pcall(app[name], ...)
    if not ok then
      print('error from '.. name .. '(): ' .. tostring(err))
      set_error(err)
      return err
    end
  else
    app[name](...)
  end
end


-- love callbacks


love.load = function(arg)
  arg = arg
  app = load_module("app")
  conf = loadliveconf()
  t0 = love.timer.getTime()
end

love.update = function(dt)
  if conf.autoreload.enable then
    local t1 = love.timer.getTime()
    local elapsed = t1 - t0
    if elapsed > conf.autoreload.interval then
      t0 = t0 + elapsed
      reload()
    end
  end
  call("update", dt)
end

love.keypressed = function(key, scancode, isrepeat)
  if conf.reloadkey and conf.reloadkey == key then
    reload()
  end
  call("keypressed", key, isrepeat)
end

love.draw = function(...)
  if errormsg then
    draw_msg(errormsg)
    love.timer.sleep(0.1)
  else
    local err = call("draw", ...)
    if err then
      draw_msg(err)
      love.timer.sleep(0.1)
    end
  end
end

local lovecallbacks = [[
  keyreleased
  mousefocus
  mousemoved
  directorydropped
  filedropped
  focus
  keyreleased
  lowmemory
  mousefocus
  mousemoved
  mousepressed
  mousereleased
  quit
  resize
  textedited
  textinput
  threaderror
  touchmoved
  touchpressed
  touchreleased
  visible

  gamepadaxis
  gamepadpressed
  gamepadreleased
  joystickadded
  joystickaxis
  joystickhat
  joystickpressed
  joystickreleased
  joystickremoved
]]
-- errorhandler

local override = function(name)
  local s = "love." .. name .. " = function(...) call('" .. name .. "', ...) end"
  local func, err = load(s, nil, 't', {call=call, love=love})
  assert(func, err)
  local ok, _ = pcall(func)
  assert(ok)
end

for name in string.gmatch(lovecallbacks, "%S+") do
  override(name)
end


-- vim: set ts=2 sw=2 tw=72 expandtab:
