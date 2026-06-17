-- Per-OS JDK path detection.
-- Supported managers / locations:
--   macOS:   jenv (major -> exact fallback) -> /usr/libexec/java_home
--   Linux:   /usr/lib/jvm/* + SDKMAN (~/.sdkman/candidates/java)
--   Windows: Eclipse Adoptium / Java / Microsoft / scoop (openjdk<version>)
local M = {}

local uname = vim.uv.os_uname()
local is_windows = uname.sysname:match("Windows") ~= nil
local is_macos = uname.sysname == "Darwin"

-- Glob a pattern and return the alphabetically-largest match. Within a major
-- version that's a close-enough proxy for "most recent patch" (e.g.
-- jdk-21.0.10 sorts after jdk-21.0.9). Returns nil when nothing matches.
local function pick_largest(pattern)
  local expanded = vim.fn.glob(pattern)
  if expanded == "" then return nil end
  local matches = vim.fn.split(expanded, "\n")
  table.sort(matches)
  return matches[#matches]
end

local function find_windows(version)
  local roots = {
    vim.env.ProgramW6432,
    vim.env.ProgramFiles,
    "C:\\Program Files",
  }
  local vendors = { "Eclipse Adoptium", "Java", "Microsoft" }
  for _, root in ipairs(roots) do
    if root and root ~= "" then
      for _, vendor in ipairs(vendors) do
        local bare = root .. "\\" .. vendor .. "\\jdk-" .. version
        if vim.fn.isdirectory(bare) == 1 then return bare end
        local hit = pick_largest(root .. "\\" .. vendor .. "\\jdk-" .. version .. ".*")
        if hit then return hit end
      end
    end
  end
  local scoop_path = (vim.env.USERPROFILE or "") .. "\\scoop\\apps\\openjdk" .. version .. "\\current"
  if vim.fn.isdirectory(scoop_path) == 1 then
    return scoop_path
  end
  return nil
end

local function find_macos(version)
  if vim.fn.executable("jenv") == 1 then
    -- 1. jenv major version match
    local jenv = vim.fn.trim(vim.fn.system("jenv prefix " .. version .. " 2>/dev/null"))
    if vim.v.shell_error == 0 and jenv ~= "" then
      return jenv
    end
    -- 2. jenv exact version (e.g. "21" doesn't match but "21.0.1" does)
    local exact = vim.fn.trim(vim.fn.system("jenv versions --bare 2>/dev/null | grep '^" .. version .. "\\.' | tail -1"))
    if vim.v.shell_error == 0 and exact ~= "" then
      jenv = vim.fn.trim(vim.fn.system("jenv prefix " .. exact .. " 2>/dev/null"))
      if vim.v.shell_error == 0 and jenv ~= "" then
        return jenv
      end
    end
  end
  -- 3. /usr/libexec/java_home
  if vim.fn.executable("/usr/libexec/java_home") == 1 then
    local result = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v " .. version .. " 2>/dev/null"))
    if vim.v.shell_error == 0 and result ~= "" then
      return result
    end
  end
  return nil
end

local function find_linux(version)
  local exact_paths = {
    "/usr/lib/jvm/java-" .. version .. "-openjdk",
    "/usr/lib/jvm/java-" .. version .. "-openjdk-amd64",
    "/usr/lib/jvm/jdk-" .. version,
  }
  for _, path in ipairs(exact_paths) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  -- Versioned fallbacks (pick highest patch within the major).
  local patterns = {
    "/usr/lib/jvm/jdk-" .. version .. ".*",
    "/usr/lib/jvm/java-" .. version .. ".*",
    (vim.env.HOME or "") .. "/.sdkman/candidates/java/" .. version .. ".*",
  }
  for _, pattern in ipairs(patterns) do
    local hit = pick_largest(pattern)
    if hit then return hit end
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
