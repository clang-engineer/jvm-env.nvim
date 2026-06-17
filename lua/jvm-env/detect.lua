-- Per-OS JDK path detection.
-- Supported managers / locations:
--   macOS:   jenv (major -> exact fallback) -> /usr/libexec/java_home
--   Linux:   /usr/lib/jvm/* + SDKMAN (~/.sdkman/candidates/java)
--   Windows: Eclipse Adoptium / Java / Microsoft / scoop (openjdk<version>)
local M = {}

local uname = vim.uv.os_uname()
local is_windows = uname.sysname:match("Windows") ~= nil
local is_macos = uname.sysname == "Darwin"

local function find_windows(version)
  local patterns = {
    "C:\\Program Files\\Eclipse Adoptium\\jdk-" .. version .. "*",
    "C:\\Program Files\\Java\\jdk-" .. version .. "*",
    "C:\\Program Files\\Microsoft\\jdk-" .. version .. "*",
  }
  for _, pattern in ipairs(patterns) do
    local expanded = vim.fn.glob(pattern)
    if expanded ~= "" then
      return vim.fn.split(expanded, "\n")[1]
    end
  end
  -- fallback: scoop
  local scoop_path = (vim.env.USERPROFILE or "") .. "\\scoop\\apps\\openjdk" .. version .. "\\current"
  if vim.fn.isdirectory(scoop_path) == 1 then
    return scoop_path
  end
  return nil
end

local function find_macos(version)
  -- 1. jenv major version match
  local jenv = vim.fn.trim(vim.fn.system("jenv prefix " .. version .. " 2>/dev/null"))
  if vim.v.shell_error == 0 and jenv ~= "" then
    return jenv
  end
  -- 2. jenv exact version (e.g. when "21" doesn't match but "21.0.1" does)
  local exact = vim.fn.trim(vim.fn.system("jenv versions --bare 2>/dev/null | grep '^" .. version .. "\\.' | tail -1"))
  if vim.v.shell_error == 0 and exact ~= "" then
    jenv = vim.fn.trim(vim.fn.system("jenv prefix " .. exact .. " 2>/dev/null"))
    if vim.v.shell_error == 0 and jenv ~= "" then
      return jenv
    end
  end
  -- 3. /usr/libexec/java_home
  local result = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v " .. version .. " 2>/dev/null"))
  if vim.v.shell_error == 0 and result ~= "" then
    return result
  end
  return nil
end

local function find_linux(version)
  local paths = {
    "/usr/lib/jvm/java-" .. version .. "-openjdk",
    "/usr/lib/jvm/java-" .. version .. "-openjdk-amd64",
    "/usr/lib/jvm/jdk-" .. version,
    (vim.env.HOME or "") .. "/.sdkman/candidates/java/" .. version .. "*",
  }
  for _, path in ipairs(paths) do
    local expanded = vim.fn.glob(path)
    if expanded ~= "" then
      return vim.fn.split(expanded, "\n")[1]
    end
  end
  return nil
end

-- Take a major-version string ("21", "17", ...) and return a JDK home path, or nil if not found.
function M.find_java(version)
  if is_windows then
    return find_windows(version)
  elseif is_macos then
    return find_macos(version)
  else
    return find_linux(version)
  end
end

return M
