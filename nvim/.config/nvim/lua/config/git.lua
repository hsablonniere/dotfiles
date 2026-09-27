-- [[ Git signs ]]
-- Marks added/changed/removed lines in the sign column and exposes per-buffer diff counts,
-- used by the statusline through `vim.b.gitsigns_status_dict`.
vim.pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' })
require('gitsigns').setup()

-- [[ Git TUI ]]
-- Alt+V runs gtui (my git TUI) in a floating terminal, at the git root of the current file. The
-- window closes when gtui exits, then files changed by git operations are reloaded.
local function open_gtui()
  local root = vim.fs.root(0, '.git') or vim.fn.getcwd()
  local width, height = math.floor(vim.o.columns * 0.9), math.floor(vim.o.lines * 0.85)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    border = 'rounded',
    style = 'minimal',
  })
  -- Same look as the file explorer: editor background, border line only
  vim.wo[win].winhighlight = 'NormalFloat:Normal,FloatBorder:NeoTreeFloatBorder'
  vim.fn.jobstart({ 'gtui' }, {
    term = true,
    cwd = root,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
        if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
        vim.cmd('checktime')
      end)
    end,
  })
  vim.cmd.startinsert()
end
vim.keymap.set('n', '<M-v>', open_gtui, { desc = 'Git TUI (gtui)' })
