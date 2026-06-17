-- Inject detected JDK paths into vim.env (or warn if not found).
local M = {}

local detect = require("jvm-env.detect")

local function apply(env_var, version, label)
  if version == nil or version == false then
    return
  end
  local path = detect.find_java(version)
  if path then
    vim.env[env_var] = path
  else
    vim.notify(
      "[jvm-env] JDK " .. version .. " (" .. label .. ") not found",
      vim.log.levels.WARN,
      { title = "jvm-env" }
    )
  end
end

function M.apply_jdtls(version)
  apply("JDTLS_JAVA_HOME", version, "jdtls")
end

function M.apply_gradle(version)
  apply("GRADLE_JAVA_HOME", version, "gradle")
end

return M
