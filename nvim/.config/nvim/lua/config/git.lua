-- [[ Git signs ]]
-- Marks added/changed/removed lines in the sign column and exposes per-buffer diff counts,
-- available through `vim.b.gitsigns_status_dict`.
vim.pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' })
require('gitsigns').setup()
