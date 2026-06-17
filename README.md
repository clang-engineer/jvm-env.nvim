# jvm-env.nvim

> **Status**: experimental (v0.1.x) — actively used by the author on macOS,
> partially tested on Linux/Windows. Feedback and issues welcome.

**Auto-detect installed JDKs by major version and inject their paths into Neovim env vars.**
Configure separate JDKs for jdtls (the language server) and Gradle (the build tool).

```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
-- → vim.env.JDTLS_JAVA_HOME  = <JDK 21 home>
-- → vim.env.GRADLE_JAVA_HOME = <JDK 17 home>
```

## What it does

- Tries `jenv prefix` / `/usr/libexec/java_home` / `~/.sdkman` / `/usr/lib/jvm/*` / standard Windows JDK paths / scoop **per OS, in order** to locate the JDK home for the requested major version.
- Writes the resolved path into `vim.env.JDTLS_JAVA_HOME` and `vim.env.GRADLE_JAVA_HOME`.
- If nothing is found, warns via `vim.notify` and keeps going — never blocks other startup.

## What it does NOT do

- **Does not start any LSP.** Your jdtls spec (nvim-jdtls, LazyVim Java extras, etc.) is still yours to write.
- **Does not install JDKs.** It only finds JDKs you already installed (via jEnv, SDKMAN, brew, apt, scoop, …).
- **Does not touch standard `JAVA_HOME`.** Your shell's `JAVA_HOME` is left alone; jvm-env uses two dedicated variables instead, deliberately avoiding conflicts with other tools.

## Why

A common Java setup:

- jdtls wants a recent JDK (e.g. 21) to run reliably.
- The project itself targets an LTS JDK (e.g. 17) for Spring Boot 3.x, Android, etc.

Toggling shell `JAVA_HOME` for every project is awkward, and the `nvim-jdtls` README's hard-coded `cmd = { '/usr/lib/jvm/...' }` does not survive cross-platform / multi-version setups. jvm-env is a **thin helper that takes a major-version string and resolves the right path for the current OS**.

## Adjacent tools

| Tool | Scope |
|---|---|
| **mason.nvim** | Installs LSP servers like jdtls. Does not install JDKs. |
| **nvim-jdtls** | jdtls integration for Neovim. JDK paths are your responsibility. |
| **nvim-java** | Full stack (LSP + DAP + tests). Can install JDKs via mason. |
| **LazyVim java extras** | Auto-wires jdtls. Recommends a hard-coded `vim.env.JAVA_HOME = ...`. |
| **jvm-env (this plugin)** | **OS/manager detection + split jdtls/Gradle env vars.** No LSP. |

These are complementary. If you already use a full-stack solution like `nvim-java`, you don't need this. jvm-env is for users layering light automation on top of `nvim-jdtls` or LazyVim Java extras.

## Install

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "clang-engineer/jvm-env.nvim",
  lazy = false,           -- vim.env must be set before jdtls starts
  priority = 100,         -- load before LSP/jdtls related plugins
  opts = {
    jdtls = "21",
    gradle = "11",
  },
}
```

Leave `opts` empty to keep the defaults (`jdtls = "21"`, `gradle = "11"`).

## Usage

### Default

```lua
require("jvm-env").setup()
-- fills both env vars with the defaults (jdtls=21, gradle=11)
```

### Custom versions

```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
```

### Wiring up jdtls (LazyVim + nvim-jdtls)

`lua/plugins/java.lua`:

```lua
return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local function present(v) return v ~= nil and v ~= "" end

      -- Fallback if jvm-env was not set up yet (e.g. .nvim.lua not trusted).
      if not present(vim.env.JDTLS_JAVA_HOME) then
        require("jvm-env").setup()
      end

      local jdtls_home  = vim.env.JDTLS_JAVA_HOME
      local gradle_home = vim.env.GRADLE_JAVA_HOME
      if not present(jdtls_home) then return opts end

      local cmd = { vim.fn.exepath("jdtls") }
      table.insert(cmd, "--java-executable")
      table.insert(cmd, jdtls_home .. "/bin/java")

      opts.jdtls = vim.tbl_deep_extend("force", opts.jdtls or {}, {
        cmd = cmd,
        cmd_env = present(gradle_home) and {
          JAVA_HOME   = gradle_home,
          GRADLE_OPTS = "-Dorg.gradle.java.home=" .. gradle_home,
        } or nil,
      })
    end,
  },
}
```

Key points:

- `cmd` uses `--java-executable` to pin the JDK that runs jdtls → reads `JDTLS_JAVA_HOME`.
- `cmd_env.JAVA_HOME` isolates the JDK used by the Gradle process spawned by jdtls → reads `GRADLE_JAVA_HOME`.

### Per-project versions via `.nvim.lua`

`.nvim.lua` (loaded per directory via Neovim 0.9+ `exrc`):

```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
```

Enable with `vim.o.exrc = true` and `:trust` the file once. Reopening Neovim inside that directory switches to the project-specific versions automatically.

## Detection order

| OS | Order |
|---|---|
| **macOS** | 1. `jenv prefix <ver>` (major match) → 2. `jenv versions --bare \| grep '^<ver>\\.'` (exact fallback) → 3. `/usr/libexec/java_home -v <ver>` |
| **Linux** | 1. `/usr/lib/jvm/java-<ver>-openjdk` → 2. `/usr/lib/jvm/java-<ver>-openjdk-amd64` → 3. `/usr/lib/jvm/jdk-<ver>` → 4. `~/.sdkman/candidates/java/<ver>*` |
| **Windows** | 1. Eclipse Adoptium `jdk-<ver>*` → 2. Java `jdk-<ver>*` → 3. Microsoft `jdk-<ver>*` → 4. scoop `openjdk<ver>/current` |

The order is: precise version managers first, then standard install paths, then per-manager fallbacks.

## Environment variable naming

`JDTLS_JAVA_HOME` / `GRADLE_JAVA_HOME` are **not** standard variables recognized by jdtls or Gradle. They are this plugin's convention, and your jdtls spec must explicitly read them (see the wiring example above).

Why not reuse `JAVA_HOME`:

- A single `JAVA_HOME` cannot separate jdtls from Gradle.
- Overriding the shell `JAVA_HOME` affects unrelated tools.

Possible future option:

- `setup({ env = { jdtls = "MY_HOME" } })` env-var overrides — open to add if there's demand.

## API

### `setup(opts)`

| Key | Type | Default | Description |
|---|---|---|---|
| `jdtls` | string | `"21"` | JDK major version used to run jdtls |
| `gradle` | string | `"11"` | JDK major version used by Gradle |

Versions are major-version strings (e.g. `"21"`). Exact versions (e.g. `"21.0.1"`) also work if `jenv` / `java_home` can match them, but the major version is usually enough.

## Migration (from a private `config.java-env`)

Old:

```lua
require("config.java-env").setup({ jdtls = "21", gradle = "17" })
```

New:

```lua
require("jvm-env").setup({ jdtls = "21", gradle = "17" })
```

Update any `.nvim.lua` files in your projects, or regenerate them with your generator script.

## License

MIT
