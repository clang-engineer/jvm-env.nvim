-- Minimal Neovim config used only to record the demo GIF.
-- Loads jvm-env from the repo root so the demo needs no install step.
-- Run from the repo root: nvim -u demo/init.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.o.termguicolors = true
vim.o.swapfile = false
vim.o.cmdheight = 2 -- 2-line :JvmEnvInit notify shows without a "Press ENTER" prompt

require("jvm-env").setup({ jdtls = "21", gradle = "17" })
