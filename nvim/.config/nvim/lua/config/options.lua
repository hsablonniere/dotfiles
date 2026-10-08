-- [[ Options ]]
-- No statusline, its info (mode, diagnostics, position...) is at the right of the tabline
vim.o.laststatus = 0
-- The mode and the position are already shown in the tabline. Without a statusline, nvim would
-- draw the position (ruler) at the right of the command line
vim.o.showmode = false
vim.o.ruler = false

vim.o.number = true
-- Hybrid numbers: real number on the cursor line, distance to the cursor elsewhere (for 5j, 3dk...).
-- Absolute numbers in insert mode and in unfocused windows, where relative ones are useless.
vim.o.relativenumber = true
vim.api.nvim_create_autocmd({ 'InsertEnter', 'WinLeave', 'FocusLost' }, {
  callback = function()
    if vim.wo.number then vim.wo.relativenumber = false end
  end,
})
vim.api.nvim_create_autocmd({ 'InsertLeave', 'WinEnter', 'FocusGained' }, {
  callback = function()
    if vim.wo.number and vim.api.nvim_get_mode().mode:sub(1, 1) ~= 'i' then vim.wo.relativenumber = true end
  end,
})

vim.o.mouse = 'a'
-- Keep the sign column so text does not shift when git or LSP signs appear
vim.o.signcolumn = 'yes'
vim.o.cursorline = true
-- Lines kept visible above and below the cursor
vim.o.scrolloff = 8
-- Long lines are not wrapped by default, wrapped lines keep their indentation when wrap is on
vim.o.wrap = false
vim.o.breakindent = true
-- Show tabs, trailing spaces and non-breaking spaces
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
-- Live preview of :s substitutions, with off-screen matches in a split
vim.o.inccommand = 'split'

-- Use the system clipboard. Scheduled because detecting the clipboard provider can slow down startup.
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
-- Keep undo history after closing a file
vim.o.undofile = true
-- Case-insensitive search, unless the pattern contains an uppercase letter
vim.o.ignorecase = true
vim.o.smartcase = true
-- Faster CursorHold and swap writes, used by plugins like gitsigns
vim.o.updatetime = 250
-- Ask to save instead of failing on :q with unsaved changes
vim.o.confirm = true

-- New splits open to the right and below
vim.o.splitright = true
vim.o.splitbelow = true
