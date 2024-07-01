local hook = require("hook")

local patterns = {
  "%.()([xyzwrgba_][1234xyzwrgba_][1234xyzwrgba_]?[1234xyzwrgba_]?)()[^%w_]",
  "%.()([xyzwrgba_][1234xyzwrgba_][1234xyzwrgba_]?[1234xyzwrgba_]?)()$",
  "%[([\"'])([1234xyzwrgba_][1234xyzwrgba_][1234xyzwrgba_]?[1234xyzwrgba_]?)%1%]()"
}

hook.add("OnSetText", "VectorSwizzling", 80, function(_, text)
  ---@type LuaLS.Plugin.diff[]
  local diffs = {}

  for _, pattern in ipairs(patterns) do
    for _, swizzle, finish in text:gmatch(pattern) do
      diffs[#diffs + 1] = {
        start = finish,
        finish = finish - 1,
        text = "--[====================[@as Vector" .. #swizzle .. "]====================]"
      }
    end
  end

  return diffs
end)
