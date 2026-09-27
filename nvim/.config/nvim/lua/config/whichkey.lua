-- [[ Keymap hints ]]
-- which-key: after a prefix key (Space, g, z, [, Ctrl+W...), shows the possible continuations
-- with their description, if the next key does not come within 300ms.
vim.pack.add({ 'https://github.com/folke/which-key.nvim' })
require('which-key').setup({
  delay = 300,
  spec = {
    { '<leader>s', group = 'Search' },
    { '<leader>t', group = 'Toggle' },
    { '<leader>w', group = 'Windows' },
    { '<leader>b', group = 'Buffers' },
  },
})
