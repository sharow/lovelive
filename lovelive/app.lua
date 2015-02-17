-- -*- Mode: lua; tab-width: 2; lua-indent-level: 2; indent-tabs-mode: nil; -*-

local app = {}

-- config
function app.liveconf(t)
  t.live = true
  t.use_pcall = true
  t.autoreload.enable = true
  t.autoreload.interval = 1.0
  t.reloadkey = "f5"
  t.gc_before_reload = false
  t.error_file = nil  -- "error.txt"
end


-- callbacks

function app.load()
  -- initial load (== love.load())
  app.reload()
end

function app.reload()
  -- reload by lovelive
end

function app.update(dt)
end

function app.draw()
end




return app

-- vim: set ts=2 sw=2 tw=72 expandtab:
