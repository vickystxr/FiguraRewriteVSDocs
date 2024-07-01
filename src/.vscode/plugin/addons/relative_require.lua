local plugin = require("plugin")
local file_uri = require("file-uri")
local hook = require("hook")

---@param base string
---@param file string
---@param relative string
---@return string
local function package_path(base, file, relative)
  if file:sub(1, #base) ~= base then return relative end

  return file:sub(#base + 1):gsub("^[/\\]", ""):gsub("[^/\\]*$", ""):gsub("[/\\]", ".")
      .. relative:gsub("^%.[/\\]", ""):gsub("%.lua$", ""):gsub("[/\\]", ".")
end

local patterns = {
  'require%s*%(%s*"()([^"\n]*)()"%s*%)',
  "require%s*%(%s*'()([^'\n]*)()'%s*%)",
  'require%s*"()([^"\n]*)()"',
  "require%s*'()([^'\n]*)()'"
}

hook.add("OnSetText", "RelativeRequire", 100, function(uri, text)
  ---@type LuaLS.Plugin.diff[]
  local diffs = {}

  for _, pattern in ipairs(patterns) do
    for start, module_name, finish in text:gmatch(pattern) do
      if module_name:match("^%.[/\\]") then
        local req_path = package_path(
          plugin.workspace_path,
          file_uri.decode(uri):gsub("\\", "/"):gsub("[^/]*$", ""),
          module_name
        )

        diffs[#diffs + 1] = {
          start = start,
          finish = finish - 1,
          text = req_path
        }
      end
    end
  end

  return diffs
end)

