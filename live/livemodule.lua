-- -*- Mode: lua; tab-width: 2; lua-indent-level: 2; indent-tabs-mode: nil; -*-

local reload = function(mod)
  local package = require("package")
  local oldmod = package.loaded[mod]
  package.loaded[mod] = nil
  local ok, obj = pcall(require, mod, true)
  if ok then
    return obj
  else
    print('error while livemodule.reload(): ' .. tostring(obj))
    package.loaded[mod] = oldmod
    return oldmod
  end
end

return { reload = reload }
