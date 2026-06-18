-- Merge user options with defaults, expose getter.
local M = {}

local defaults = {
  jdtls = "21", -- JDK major version used to run jdtls
  gradle = "17", -- JDK major version used by Gradle
}

local options = vim.deepcopy(defaults)

function M.setup(opts)
  options = vim.tbl_deep_extend("force", options, opts or {})
end

function M.get(key)
  return options[key]
end

return M
