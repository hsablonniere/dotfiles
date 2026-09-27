-- [[ Keymaps ]]
vim.keymap.set('n', '<leader>tw', function() vim.wo.wrap = not vim.wo.wrap end, { desc = '[T]oggle [W]rap' })

-- Undo history as a tree (built-in plugin): every past state of the file, even undone branches
vim.cmd.packadd('nvim.undotree')
vim.keymap.set('n', '<leader>u', function() require('undotree').open({ command = '60vnew' }) end, { desc = '[U]ndo tree' })

-- Move lines like WebStorm: Alt+Shift+Up/Down moves the line or the selection, Alt+Shift+Left/Right
-- changes its indentation. Works in normal, visual and insert mode.
vim.pack.add({ 'https://github.com/nvim-mini/mini.move' })
require('mini.move').setup({
  mappings = {
    left = '<M-S-Left>',
    right = '<M-S-Right>',
    down = '<M-S-Down>',
    up = '<M-S-Up>',
    line_left = '<M-S-Left>',
    line_right = '<M-S-Right>',
    line_down = '<M-S-Down>',
    line_up = '<M-S-Up>',
  },
})
for key, direction in pairs({ ['<M-S-Up>'] = 'up', ['<M-S-Down>'] = 'down', ['<M-S-Left>'] = 'left', ['<M-S-Right>'] = 'right' }) do
  vim.keymap.set('i', key, function() require('mini.move').move_line(direction) end, { desc = 'Move line ' .. direction })
end

-- Code-aware selection like WebStorm: Alt+E selects the syntax node under the cursor, then grows
-- to its parent (word, expression, statement, function...), Alt+Shift+E shrinks it back. Relies
-- on the native treesitter incremental selection (an / in in visual mode).
vim.keymap.set('n', '<M-e>', 'van', { remap = true, desc = 'Select syntax node' })
vim.keymap.set('x', '<M-e>', 'an', { remap = true, desc = 'Grow selection to parent node' })
vim.keymap.set('x', '<M-E>', 'in', { remap = true, desc = 'Shrink selection to child node' })

-- Multiple cursors like WebStorm/VS Code: Alt+R adds a cursor on the next occurrence of the word
-- or selection, Alt+Shift+R removes the last added one, Esc goes back to a single cursor. With
-- several cursors, every normal/insert/visual command applies to all of them. Text typed in insert
-- mode shows at the main cursor and is copied to the others when leaving insert mode.
vim.pack.add({ { src = 'https://github.com/jake-stewart/multicursor.nvim', version = '1.0' } })
local mc = require('multicursor-nvim')
mc.setup()
vim.keymap.set({ 'n', 'x' }, '<M-r>', function() mc.matchAddCursor(1) end, { desc = 'Add cursor on next occurrence' })
-- Ctrl+click adds a cursor where you click
vim.keymap.set('n', '<C-LeftMouse>', mc.handleMouse)
vim.keymap.set('n', '<C-LeftDrag>', mc.handleMouseDrag)
vim.keymap.set('n', '<C-LeftRelease>', mc.handleMouseRelease)
mc.addKeymapLayer(function(layer_set)
  -- Only active while there are several cursors
  layer_set({ 'n', 'x' }, '<M-R>', mc.deleteCursor)
  layer_set('n', '<Esc>', mc.clearCursors)
end)
vim.api.nvim_set_hl(0, 'MultiCursorCursor', { reverse = true })
vim.api.nvim_set_hl(0, 'MultiCursorVisual', { link = 'Visual' })

-- Windows (splits): Space w replaces Ctrl+W, taken by the terminal, with its main commands, each
-- listed in the which-key menu. Ctrl+H/J/K/L move between splits.
for keys, spec in pairs({
  v = { '<C-w>v', 'Split vertically' },
  s = { '<C-w>s', 'Split horizontally' },
  h = { '<C-w>h', 'Go to the left window' },
  j = { '<C-w>j', 'Go to the lower window' },
  k = { '<C-w>k', 'Go to the upper window' },
  l = { '<C-w>l', 'Go to the right window' },
  w = { '<C-w>w', 'Go to the next window' },
  q = { '<C-w>q', 'Close the window' },
  o = { '<C-w>o', 'Close all other windows' },
  ['='] = { '<C-w>=', 'Equalize window sizes' },
  x = { '<C-w>x', 'Swap with the next window' },
  H = { '<C-w>H', 'Move the window to the far left' },
  L = { '<C-w>L', 'Move the window to the far right' },
}) do
  vim.keymap.set('n', '<leader>w' .. keys, spec[1], { desc = spec[2] })
end
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Go to the left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Go to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Go to the upper window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Go to the right window' })
-- Ctrl+L used to clear the search highlight, Esc does it now
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })

-- Surround: add, delete or replace brackets, quotes, tags... around text. sa + motion (or on a
-- selection) + character adds (saiw) wraps a word in parentheses), sd( deletes, sr"' replaces.
-- In visual mode, ( [ { ` and * wrap the selection directly, like VS Code. * makes Markdown bold.
vim.pack.add({ 'https://github.com/nvim-mini/mini.surround' })
require('mini.surround').setup({
  custom_surroundings = {
    ['*'] = {
      input = function() return { vim.bo.filetype == 'markdown' and '%*%*().-()%*%*' or '%*().-()%*' } end,
      output = function()
        local marker = vim.bo.filetype == 'markdown' and '**' or '*'
        return { left = marker, right = marker }
      end,
    },
  },
})
-- Closing characters add no inner space: ( wraps as (text), not ( text )
for key, char in pairs({ ['('] = ')', ['['] = ']', ['{'] = '}', ['`'] = '`', ['*'] = '*' }) do
  vim.keymap.set('x', key, 'sa' .. char, { remap = true, desc = 'Surround selection with ' .. key })
end
-- Native [n / ]n (select the previous / next sibling node) would make [ wait for a second key
pcall(vim.keymap.del, 'x', '[n')
pcall(vim.keymap.del, 'x', ']n')

-- Ctrl+W disabled, including its native bindings (window commands, delete word in insert mode)
pcall(vim.keymap.del, 'n', '<C-w>d')
pcall(vim.keymap.del, 'n', '<C-w><C-d>')
vim.keymap.set({ 'n', 'v', 'i' }, '<C-w>', '<Nop>')

-- [[ Indentation ]]
-- Defaults for new files: 2 spaces. Existing files: the indentation is detected from their
-- content (guess-indent), unless an .editorconfig sets it (read natively by nvim).
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
-- Built-in YAML and Markdown ftplugins force their "recommended style" after the detection
vim.g.yaml_recommended_style = 0
vim.g.markdown_recommended_style = 0
vim.pack.add({ 'https://github.com/NMAC427/guess-indent.nvim' })
require('guess-indent').setup()
