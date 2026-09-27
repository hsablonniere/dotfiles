-- [[ Snacks ]]
-- snacks.nvim: a collection of small modules, only the ones enabled below are active.
-- - picker: fuzzy search for files, grep, symbols, buffers... (keymaps in picker.lua)
-- - indent: indentation guides, the scope under the cursor highlighted
-- - input: nicer vim.ui.input prompt (LSP rename...)
-- - notifier: notifications in a corner instead of the message area
-- - bigfile: very large files open without treesitter, LSP and other slow features
-- Loaded early so the notifier catches messages of the other modules.
vim.pack.add({ { src = 'https://github.com/folke/snacks.nvim', version = vim.version.range('2.*') } })
require('snacks').setup({
  bigfile = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true },
  picker = {
    enabled = true,
    win = {
      -- One Esc closes the picker, instead of switching the prompt to normal mode first
      input = { keys = { ['<Esc>'] = { 'close', mode = { 'n', 'i' } } } },
    },
  },
})
