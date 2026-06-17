-- :checkhealth jvm-env
local M = {}

local detect = require("jvm-env.detect")
local config = require("jvm-env.config")

function M.check()
  vim.health.start("jvm-env")

  local u = vim.uv.os_uname()
  local is_windows = u.sysname:match("Windows") ~= nil
  local is_macos = u.sysname == "Darwin"
  vim.health.info(("OS: %s %s (%s)"):format(u.sysname, u.release, u.machine))

  if is_macos then
    if vim.fn.executable("jenv") == 1 then
      vim.health.ok("jenv: installed")
    else
      vim.health.info("jenv: not installed (will fall back to /usr/libexec/java_home)")
    end
    if vim.fn.executable("/usr/libexec/java_home") == 1 then
      vim.health.ok("/usr/libexec/java_home: available")
    else
      vim.health.warn("/usr/libexec/java_home: missing")
    end
  elseif not is_windows then
    local sdkman = (vim.env.HOME or "") .. "/.sdkman/candidates/java"
    if vim.fn.isdirectory(sdkman) == 1 then
      vim.health.ok("SDKMAN: " .. sdkman)
    else
      vim.health.info("SDKMAN: not detected at " .. sdkman)
    end
    if vim.fn.isdirectory("/usr/lib/jvm") == 1 then
      vim.health.ok("/usr/lib/jvm: present")
    else
      vim.health.info("/usr/lib/jvm: not present")
    end
  end

  local targets = {
    { key = "jdtls",  env = "JDTLS_JAVA_HOME"  },
    { key = "gradle", env = "GRADLE_JAVA_HOME" },
  }
  for _, t in ipairs(targets) do
    local version = config.get(t.key)
    if version == nil or version == false then
      vim.health.info(("%s: disabled (opt-out)"):format(t.key))
    else
      local path = detect.find_java(version)
      if path then
        vim.health.ok(("%s -> JDK %s at %s"):format(t.env, version, path))
      else
        vim.health.error(("%s: JDK %s not found"):format(t.env, version))
      end
      local current = vim.env[t.env]
      if current and current ~= "" then
        vim.health.info(("vim.env.%s = %s"):format(t.env, current))
      else
        vim.health.warn(("vim.env.%s is unset (setup() not called yet?)"):format(t.env))
      end
    end
  end
end

return M
