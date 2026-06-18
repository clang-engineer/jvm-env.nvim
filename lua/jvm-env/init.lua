-- jvm-env.nvim entry point
-- Usage:
--   require("jvm-env").setup()                              -- defaults (jdtls=21, gradle=17)
--   require("jvm-env").setup({ jdtls = "21", gradle = "17" })
local M = {}

function M.setup(opts)
  local config = require("jvm-env.config")
  config.setup(opts)

  local env = require("jvm-env.env")
  env.apply_jdtls(config.get("jdtls"))
  env.apply_gradle(config.get("gradle"))

  vim.api.nvim_create_user_command("JvmEnvInit", function(args)
    local jdtls = args.fargs[1] or config.get("jdtls")
    local gradle = args.fargs[2] or config.get("gradle")
    local body = string.format('require("jvm-env").setup({ jdtls = "%s", gradle = "%s" })', jdtls, gradle)
    local path = vim.fs.joinpath(vim.fn.getcwd(), ".nvim.lua")
    local f = assert(io.open(path, "w"))
    f:write(body .. "\n")
    f:close()
    vim.notify(("Wrote %s\n%s"):format(path, body), vim.log.levels.INFO, { title = "jvm-env" })
  end, {
    nargs = "*",
    desc = "Write .nvim.lua with jvm-env.setup for the current cwd",
  })
end

return M
