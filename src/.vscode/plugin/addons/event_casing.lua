local hook = require("hook")

local patterns = {
  "^events%.()([%a_][%w_]*)()",
  "[^%w_]events%.()([%a_][%w_]*)()",
}

hook.add("OnSetText", "EventCasing", 90, function(_, text)
  ---@type LuaLS.Plugin.diff[]
  local diffs = {}

  for _, pattern in ipairs(patterns) do
    for start, event_name, finish in text:gmatch(pattern) do
      diffs[#diffs + 1] = {
        start = start,
        finish = finish - 1,
        text = event_name:upper()
      }
    end
  end

  return diffs
end)
