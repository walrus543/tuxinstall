-- Leader d'abord
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Options équivalentes (Lua natives)
vim.opt.showmatch = true
vim.opt.ignorecase = true
vim.opt.mouse = "v"
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.number = true
vim.opt.wildmode = "longest,list"
vim.opt.colorcolumn = "80"
vim.opt.filetype = "on"
vim.opt.syntax = "on"
vim.opt.mouse = "a"

vim.opt.clipboard = "unnamedplus"
-- En SSH : copier via OSC 52 (Kitty le supporte nativement)
if vim.env.SSH_TTY then
  local osc52 = require("vim.ui.clipboard.osc52")

  -- Le "paste" renvoie simplement le contenu du registre interne de Neovim,
  -- car Kitty demande une confirmation pour lire le presse-papier local.
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end

  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = paste,
      ["*"] = paste,
    },
  }
end

vim.opt.cursorline = true
vim.opt.ttyfast = true

-- Charger lazy.nvim
require("config.lazy")
