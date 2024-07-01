local this = {}

---@type {[string]: Plugin.Hook.callback[]}
local hooks = {}

function this.add(hook, name, priority, func)
  if not hooks[hook] then hooks[hook] = {} end

  local callback = {
    name = name,
    priority = priority,
    func = func
  }

  local hook_table = hooks[hook]
  local len = #hook_table
  if len < 1 then
    hook_table[1] = callback
    return
  end

  -- Attempt to put the hook where it belongs with a max number of attempts.
  local left, right = 1, len
  local attempts = 64
  while true do
    if attempts <= 0 then error("Adding hook callback took too long!") end
    attempts = attempts - 1
    local i = math.floor((left + right) * 0.5)
    local icb = hook_table[i]
    local eq_pri = priority == icb.priority
    if eq_pri and name == icb.name then
      hook_table[i] = callback
      return
    elseif priority > icb.priority or eq_pri and name < icb.name then
      -- This if statement might actually be impossible, doesn't hurt to have though.
      if i == right then
        table.insert(hook_table, i, callback)
        return
      end
      right = i
    elseif i == left then
      table.insert(hook_table, i + 1, callback)
      return
    else
      left = i
    end
  end
end

---@param hook string
---@param name string
---@param priority integer
---@return boolean
function this.remove(hook, name, priority)
  if not hooks[hook] then return false end
  for i, callback in ipairs(hooks[hook]) do
    if callback.name == name and callback.priority == priority then
      table.remove(hooks[hook], i)
      return true
    end
  end

  return false
end

---@param hook string
---@return boolean
function this.empty(hook)
  return not hooks[hook] or #hooks[hook] == 0
end

---@param hook string
---@param ... any
---@return any ...
function this.run(hook, ...)
  if not hooks[hook] then return end
  for _, callback in ipairs(hooks[hook]) do
    local ret = table.pack(callback.func(...))
    if ret.n > 0 then
      return table.unpack(ret, 1, ret.n)
    end
  end
end

---@param hook string
---@param ... any
---@return any ...
function this.runall(hook, ...)
  if not hooks[hook] then return end
  for _, callback in ipairs(hooks[hook]) do
    callback.func(...)
  end
end

---@param hook string
---@param func function
---@param ... any
function this.foreach(hook, func, ...)
  if not hooks[hook] then return end
  for _, callback in ipairs(hooks[hook]) do
    func(callback.func(...))
  end
end

---@param hook string
---@param ... any
---@return any ...
function this.chain(hook, ...)
  if not hooks[hook] then return ... end
  local values = table.pack(...)
  for _, callback in ipairs(hooks[hook]) do
    local cb_values = table.pack(callback.func(table.unpack(values, 1, values.n)))
    if cb_values.n > 0 then
      values = cb_values
    end
  end

  return table.unpack(values, 1, values.n)
end

return this
