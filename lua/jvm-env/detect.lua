-- Per-OS JDK path detection.
-- Supported managers / locations:
--   macOS:   jenv (major -> exact fallback) -> /usr/libexec/java_home
--            -> Homebrew openjdk@<ver> -> SDKMAN
--   Linux:   /usr/lib/jvm/* + SDKMAN (~/.sdkman/candidates/java)
--   Windows: Eclipse Adoptium / Java / Microsoft / scoop (openjdk<version>)
local M = {}

local uname = vim.uv.os_uname()
local is_windows = uname.sysname:match("Windows") ~= nil
local is_macos = uname.sysname == "Darwin"

-- Natural-order comparison: extract numeric segments and compare them as
-- numbers so "jdk-21.0.10" sorts after "jdk-21.0.9". Falls back to string
-- compare when numeric parts tie.
local function nat_key(s)
  local parts = {}
  for num in s:gmatch("%d+") do
    parts[#parts + 1] = tonumber(num)
  end
  return parts
end

local function lt_natural(a, b)
  local ka, kb = nat_key(a), nat_key(b)
  for i = 1, math.max(#ka, #kb) do
    local va, vb = ka[i] or 0, kb[i] or 0
    if va ~= vb then
      return va < vb
    end
  end
  return a < b
end

-- Glob a pattern and return the highest-versioned match, or nil.
local function pick_largest(pattern)
  -- nosuf=true so 'wildignore'/'suffixes' can't filter JDK paths; list=true
  -- returns a table directly.
  local matches = vim.fn.glob(pattern, true, true)
  if #matches == 0 then
    return nil
  end
  table.sort(matches, lt_natural)
  return matches[#matches]
end

local function find_windows(version)
  -- vim.fn.glob treats `\` as an escape character; use forward slashes so
  -- vendor names like "Java" don't get re-interpreted (e.g. `\J`).
  local roots = {
    vim.env.ProgramW6432,
    vim.env.ProgramFiles,
    "C:/Program Files",
  }
  local vendors = { "Eclipse Adoptium", "Java", "Microsoft" }
  for _, root in ipairs(roots) do
    if root and root ~= "" then
      root = root:gsub("\\", "/")
      for _, vendor in ipairs(vendors) do
        local bare = root .. "/" .. vendor .. "/jdk-" .. version
        if vim.fn.isdirectory(bare) == 1 then
          return bare
        end
        local hit = pick_largest(root .. "/" .. vendor .. "/jdk-" .. version .. ".*")
        if hit then
          return hit
        end
      end
    end
  end
  local userprofile = (vim.env.USERPROFILE or ""):gsub("\\", "/")
  local scoop_path = userprofile .. "/scoop/apps/openjdk" .. version .. "/current"
  if vim.fn.isdirectory(scoop_path) == 1 then
    return scoop_path
  end
  return nil
end

local function find_macos(version)
  local v_esc = vim.fn.shellescape(version)
  if vim.fn.executable("jenv") == 1 then
    -- 1. jenv major-version match
    local jenv = vim.fn.trim(vim.fn.system("jenv prefix " .. v_esc .. " 2>/dev/null"))
    if vim.v.shell_error == 0 and jenv ~= "" then
      return jenv
    end
    -- 2. exact-version fallback (e.g. "21" misses but "21.0.1" matches)
    local lines = vim.fn.systemlist("jenv versions --bare 2>/dev/null")
    if vim.v.shell_error == 0 and type(lines) == "table" then
      local prefix = version .. "."
      local matched = {}
      for _, line in ipairs(lines) do
        if vim.startswith(line, prefix) then
          matched[#matched + 1] = line
        end
      end
      if #matched > 0 then
        table.sort(matched, lt_natural)
        local exact = matched[#matched]
        local jenv2 = vim.fn.trim(vim.fn.system("jenv prefix " .. vim.fn.shellescape(exact) .. " 2>/dev/null"))
        if vim.v.shell_error == 0 and jenv2 ~= "" then
          return jenv2
        end
      end
    end
  end
  -- 3. /usr/libexec/java_home
  if vim.fn.executable("/usr/libexec/java_home") == 1 then
    local result = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v " .. v_esc .. " 2>/dev/null"))
    if vim.v.shell_error == 0 and result ~= "" then
      return result
    end
  end
  -- 4. Homebrew openjdk@<ver>
  local brew_homes = {
    "/opt/homebrew/opt/openjdk@" .. version .. "/libexec/openjdk.jdk/Contents/Home",
    "/usr/local/opt/openjdk@" .. version .. "/libexec/openjdk.jdk/Contents/Home",
  }
  for _, path in ipairs(brew_homes) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  -- 5. SDKMAN
  local sdkman = (vim.env.HOME or "") .. "/.sdkman/candidates/java/" .. version .. ".*"
  return pick_largest(sdkman)
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
  local patterns = {
    "/usr/lib/jvm/jdk-" .. version .. ".*",
    "/usr/lib/jvm/java-" .. version .. ".*",
    (vim.env.HOME or "") .. "/.sdkman/candidates/java/" .. version .. ".*",
  }
  for _, pattern in ipairs(patterns) do
    local hit = pick_largest(pattern)
    if hit then
      return hit
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

-- Exposed for unit tests only. Not part of the public API.
M._internal = {
  nat_key = nat_key,
  lt_natural = lt_natural,
  pick_largest = pick_largest,
}

return M
