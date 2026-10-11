-- :checkhealth jvm-env
local M = {}

local detect = require("jvm-env.detect")
local config = require("jvm-env.config")

local function path_join(...)
  return table.concat({ ... }, "/")
end

local function basename(path)
  return vim.fn.fnamemodify(path, ":t")
end

local function list_dirs(pattern)
  local dirs = {}
  for _, path in ipairs(vim.fn.glob(pattern, true, true)) do
    if vim.fn.isdirectory(path) == 1 then
      dirs[#dirs + 1] = path
    end
  end
  table.sort(dirs)
  return dirs
end

local function manager_roots()
  local home = vim.env.HOME or ""
  local roots = {}
  local seen = {}

  local function add(name, root, env, exe)
    if root == "" then
      return
    end
    local key = name .. ":" .. root
    if seen[key] then
      return
    end
    seen[key] = true
    roots[#roots + 1] = { name = name, root = root, env = env, exe = exe }
  end

  add("mise", path_join(home, ".local/share/mise"), "MISE_DATA_DIR", "mise")
  add("asdf", path_join(home, ".asdf"), "ASDF_DATA_DIR", "asdf")
  add("mise", vim.env.MISE_DATA_DIR or "", "MISE_DATA_DIR", "mise")
  add("asdf", vim.env.ASDF_DATA_DIR or "", "ASDF_DATA_DIR", "asdf")

  return roots
end

local function java_installs(root)
  return list_dirs(path_join(root, "installs/java/*"))
end

local function has_version_manager_installs()
  for _, manager in ipairs(manager_roots()) do
    if #java_installs(manager.root) > 0 then
      return true
    end
  end
  return false
end

local function check_version_managers()
  local seen_exe = {}
  for _, manager in ipairs(manager_roots()) do
    if not seen_exe[manager.name] then
      seen_exe[manager.name] = true
      if vim.fn.executable(manager.exe) == 1 then
        vim.health.ok(("%s: executable at %s"):format(manager.name, vim.fn.exepath(manager.exe)))
      else
        vim.health.info(("%s: executable not on PATH"):format(manager.name))
      end
    end

    local suffix = manager.env and vim.env[manager.env] == manager.root and (" (from $" .. manager.env .. ")") or ""
    local installs = java_installs(manager.root)
    if #installs > 0 then
      vim.health.ok(("%s data dir: %s%s"):format(manager.name, manager.root, suffix))
      local names = {}
      for _, dir in ipairs(installs) do
        names[#names + 1] = basename(dir)
      end
      vim.health.info(("%s Java installs: %s"):format(manager.name, table.concat(names, ", ")))
    else
      vim.health.info(("%s Java installs: none at %s"):format(manager.name, path_join(manager.root, "installs/java")))
    end
  end
end

function M.check()
  vim.health.start("jvm-env")

  local u = vim.uv.os_uname()
  local is_windows = u.sysname:match("Windows") ~= nil
  local is_macos = u.sysname == "Darwin"
  vim.health.info(("OS: %s %s (%s)"):format(u.sysname, u.release, u.machine))

  check_version_managers()

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
    { key = "jdtls", env = "JDTLS_JAVA_HOME" },
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
        if has_version_manager_installs() then
          vim.health.info(
            "Version-manager Java installs were detected. Check that the requested major version is installed; "
              .. "if this is a new lazy.nvim install, also check lazy-lock.json and try :Lazy update jvm-env.nvim."
          )
        end
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
