# jvm-env.nvim — :JvmEnvInit demo recording script for VHS
#
# Regenerate the GIF from the repo root:
#   vhs demo/jvminit.tape     # writes demo/jvminit.gif
#
# Shows the per-project flow: :JvmEnvInit writes a .nvim.lua for you.
# Note: recording creates .nvim.lua in the cwd — delete it afterwards.

Output demo/jvminit.gif

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
Sleep 500ms

# Ask jvm-env to write a per-project .nvim.lua pinning jdtls=21, gradle=17.
# The notify shows the target path + the exact setup line it wrote.
Type ":JvmEnvInit 21 17"
Sleep 600ms
Enter
Sleep 4s
