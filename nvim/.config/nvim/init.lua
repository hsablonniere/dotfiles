-- [[ Leader keys ]]
-- Must be set before any mapping is defined, otherwise those mappings keep the old leader.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Each module is one section of the config. Order matters: later ones rely on earlier ones
-- (colorscheme before the highlights derived from it, snacks before the picker and LSP keymaps...).
require('config.options')
require('config.snacks')
require('config.autosave')
require('config.sessions')
require('config.editing')
require('config.colorscheme')
require('config.explorer')
require('config.git')
require('config.picker')
require('config.completion')
require('config.lsp')
require('config.treesitter')
require('config.formatting')
require('config.whichkey')
require('config.status_info')
require('config.tabline')
require('config.winbar')
