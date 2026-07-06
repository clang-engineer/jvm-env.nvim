-- Minimal Neovim config used only to record the demo GIF.
-- Loads jvm-env from the repo root so the demo needs no install step.
-- Run from the repo root: nvim -u demo/init.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.o.termguicolors = true
vim.o.swapfile = false

require("jvm-env").setup({ jdtls = "21", gradle = "17" })
