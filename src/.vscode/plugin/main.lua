---@meta _
---@diagnostic disable: undefined-global, codestyle-check

---@type function, string, string[]
local this, path, iargs = ...

print("PLUGIN LOADED")

local plugin = require("plugin")
local file_uri = require("file-uri")
local hook = require("hook")

path = file_uri.decode(path):gsub("\\", "/")
plugin.workspace_path = path

---@type {[string]: boolean | number | string}
local args = {}
for _, iarg in ipairs(iargs) do
  if type(iarg) == "string" then
    local name, value = iarg:match("^([%a_][%w_]*)=(.*)$")
    if name and value then
      if value == "true" or value == "false" then
        args[name] = value == "true"
      elseif tonumber(value) then
        args[name] = tonumber(value)
      elseif value:match("^\".*\"$") or value:match("^'.*'$") then
        args[name] = value:sub(2, -2)
      else
        args[name] = value
      end
    else
      args[iarg] = true
    end
  end
end

plugin.args = args

pcall(require, "plugin-debug")
require("addons.__loader")

---@type unknown
local ENV = _ENV

---==================================================================================================================---

local diffs

---@param cb_diffs LuaLS.Plugin.diff[]
local function collectDiffs(cb_diffs)
  if type(cb_diffs) == "table" then
    for _, v in ipairs(cb_diffs) do
      if type(v.start) == "number"
        and type(v.finish) == "number"
        and type(v.text) == "string"
      then
        diffs[#diffs + 1] = v
      end
    end
  end
end

---@param text string
---@return boolean
local function pluginBlocked(text)
  return not not (
    text:match("^%-%-%-@meta _")
    or text:match("^%-%-%-@noplugin")
    or text:match("^%-%-%-@meta[^\n]*\n%-%-%-@noplugin")
  )
end

---@param uri string
---@param text string
---@return LuaLS.Plugin.diff[]?
function ENV.OnSetText(uri, text)
  if pluginBlocked(text) then return end
  --print(...)
  diffs = {}
  hook.foreach("OnSetText", collectDiffs, uri, text)
  return #diffs > 0 and diffs or nil
end


function ENV.OnTransformAST(uri, ast)
  if ast.state and ast.state.lua and pluginBlocked(ast.state.lua) then return end
  hook.runall("OnTransformAST", uri, ast)
end

if ENV.VM then
  function ENV.VM.OnCompileFunctionParam(default, func, param)
    return hook.empty("OnCompileFunctionParam") or hook.run("OnCompileFunctionParam", default, func, param)
  end
end
