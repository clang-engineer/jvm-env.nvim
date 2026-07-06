# jvm-env.nvim — demo recording script for VHS (https://github.com/charmbracelet/vhs)
#
# Regenerate the GIF from the repo root:
#   vhs demo/demo.tape        # writes demo/demo.gif
#
# Requires: vhs (brew install vhs) and at least JDK 17 + 21 installed,
# so :checkhealth jvm-env has real paths to resolve.

Output demo/demo.gif

Require nvim

Set Shell zsh
Set FontSize 16
Set Width 1280
Set Height 800
Set Padding 20
Set Theme "Catppuccin Mocha"

# Boot Neovim with only jvm-env loaded (see demo/init.lua).
Hide
Type "nvim -u demo/init.lua"
Enter
Sleep 1s
Show
Sleep 400ms

# Run the health check: OS detection, manager presence, resolved JDK paths.
Type ":checkhealth jvm-env"
Sleep 800ms
Enter
Sleep 4s

# Let the green OK lines — JDTLS/GRADLE_JAVA_HOME resolved paths — land.
Sleep 2s
