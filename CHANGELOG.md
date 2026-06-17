# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `:checkhealth jvm-env` reports detected managers, resolved JDK paths, and current `vim.env` values.
- `false` opt-out for `jdtls` / `gradle` options to skip writing one env var.
- macOS Homebrew (`/opt/homebrew/opt/openjdk@<ver>`, `/usr/local/opt/openjdk@<ver>`) and SDKMAN fallback after `jenv` / `java_home`.

### Changed
- Multi-patch matches now resolve in natural (numeric) version order, so `jdk-21.0.10` outranks `jdk-21.0.9`.
- macOS detection guards `executable("jenv")` before spawning and runs the exact-version fallback in Lua instead of a shell pipeline.
- Windows detection uses forward-slash glob patterns and respects `%ProgramW6432%` / `%ProgramFiles%` before falling back to `C:\Program Files`.
- Linux glob patterns tightened from `<ver>*` to `<ver>.*` to avoid spurious matches.

### Removed
- Hand-written `doc/jvm-env.txt`. Vimdoc is now generated automatically from `README.md` by panvimdoc.

## [0.1.0] - 2026-06-17

### Added
- Initial release: per-OS JDK detection (jEnv / `/usr/libexec/java_home` / SDKMAN / `/usr/lib/jvm/*` / Windows Adoptium-Java-Microsoft / scoop) writing to `JDTLS_JAVA_HOME` and `GRADLE_JAVA_HOME`.
