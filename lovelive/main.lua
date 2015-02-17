-- -*- Mode: lua; tab-width: 2; lua-indent-level: 2; indent-tabs-mode: nil; -*-

--
-- if you want use lovelive then
--   use app.lua instead of main.lua
-- end
--

function load_module(mod, reload)
  local m = require(mod)
  if reload then
    if m.reload then
      m.reload()
    end
  else
    if m.load then
      m.load()
    end
  end
  return m
end

function reload_module(mod, gc)
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


local app = load_module("app")

local function loadliveconf()
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

local errormsg = nil

local function draw_msg(msg)
  love.graphics.clear()
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.printf(msg, 0, 0, love.graphics.getWidth())
  -- love.graphics.present()
end

local function set_error(msg)
  if msg then
    errormsg = debug.traceback("Error: " .. tostring(msg)):gsub("\n[^\n]+$", "")
    if conf.error_file then
      f = io.open(conf.error_file, "a+")
      f:write(errormsg .. "\n\n")
      f:flush()
    end
  else
    errormsg = nil
  end
end

local function reload()
  app, msg = reload_module("app", conf.gc_before_reload)
  set_error(msg)
end


local function call(name, ...)
  if not app[name] then
    return
  end
  if conf.use_pcall then
    local ok, obj = pcall(app[name], ...)
    if not ok then
      set_error(obj)
    end
  else
    app[name](...)
  end
end


-- love callbacks

function love.load()
  conf = loadliveconf()
  t0 = love.timer.getTime()
end

function love.update(dt)
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

function love.keypressed(key, isrepeat)
  if conf.reloadkey and conf.reloadkey == key then
    reload()
  end
  call("keypressed", key, isrepeat)
end

function love.draw(...)
  if errormsg then
    draw_msg(errormsg)
    love.timer.sleep(0.1)
  else
    call("draw", ...)
  end
end

function love.keyreleased(...) call("keyreleased", ...) end
function love.mousefocus(...) call("mousefocus", ...) end
function love.mousemoved(...) call("mousemoved", ...) end
function love.mousepressed(...) call("mousepressed", ...) end
function love.mousereleased(...) call("mousereleased", ...) end
function love.quit(...) call("quit", ...) end
function love.resize(...) call("resize", ...) end
function love.textinput(...) call("textinput", ...) end
function love.threaderror(...) call("threaderror", ...) end
function love.visible(...) call("visible", ...) end

function love.gamepadaxis(...) call("gamepadaxis", ...) end
function love.gamepadpressed(...) call("gamepadpressed", ...) end
function love.gamepadreleased(...) call("gamepadreleased", ...) end
function love.joystickadded(...) call("joystickadded", ...) end
function love.joystickaxis(...) call("joystickaxis", ...) end
function love.joystickhat(...) call("joystickhat", ...) end
function love.joystickpressed(...) call("joystickpressed", ...) end
function love.joystickreleased(...) call("joystickreleased", ...) end
function love.joystickremoved(...) call("joystickremoved", ...) end

-- vim: set ts=2 sw=2 tw=72 expandtab:
