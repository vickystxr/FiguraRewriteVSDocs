---@diagnostic disable: undefined-global

---@type string, string
local this, path = ...

local plugin = require("plugin")
local client = require("client")
local fs = require("bee.filesystem")
local addons_path = path:gsub("[^/]+$", "addons")

local msg_addonError = [[
A plugin addon has errored! Please report this to the author of the plugin addon.
A detailed stack trace has been printed to the Lua Output.
Error: %s
Addon path: %s]]

-- Load built-in addons
for file, status in fs.pairs(addons_path) do
  if status:type() == "regular" then
    local file_name = file:string():match("([^/]*)%.lua$")
    if file_name and file_name ~= "__loader" then require("addons." .. file_name) end
  end
end

if plugin.args.allowAddons ~= true then return end

local addonignore = {
  "%.git$",
  "%.vscode/plugin$"
}

-- Load workspace addons
local function recursiveSearch(dir)
  for file, status in fs.pairs(dir) do
    local file_path = file:string()
    local file_status = status:type()

    local ignored = false
    for _, ignore in ipairs(addonignore) do
      if file_path:match(ignore) then
        ignored = true
        break
      end
    end

    if not ignored then
      if file_status == "directory" then
        recursiveSearch(file_path)
      elseif file_status == "regular" and file_path:match("%.plugin%.[^./\\]+%.lua$") then
        xpcall(dofile, function(e)
          client.showMessage(msg_addonError:format(
            e,
            fs.absolute(file_path):string():gsub("^[a-z]", string.upper, 1)
          ))
          print(debug.traceback(e), 2)
        end, file_path)
      end
    end
  end
end

recursiveSearch(".")
