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
    -- Native keys without a usable description
    { 'gr', group = 'LSP' },
    { 'grn', desc = 'Rename symbol' },
    { 'gra', desc = 'Code action', mode = { 'n', 'x' } },
    { 'grx', desc = 'Run codelens' },
    { 'gO', desc = 'Symbols of the file' },
    { 'g%', desc = 'Match backwards' },
    { 'gJ', desc = 'Join lines without space' },
    { 'gp', desc = 'Paste after, cursor after text' },
    { 'gP', desc = 'Paste before, cursor after text' },
    { 'g_', desc = 'Last non-blank character of line' },
    { 'ga', desc = 'Character code under cursor' },
  },
})
