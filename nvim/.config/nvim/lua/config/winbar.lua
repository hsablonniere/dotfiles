-- [[ Winbar ]]
-- Bar at the top of each split holding a file, like WebStorm's editor tabs and breadcrumbs
-- (dropbar.nvim): the path of the file inside the project, then the symbols around the cursor
-- (class > method...) from the language server, or treesitter when none is attached. Display
-- only: mouse clicks and hover are disabled.
vim.pack.add({ 'https://github.com/Bekaboo/dropbar.nvim' })
require('dropbar').setup({
  bar = { hover = false },
  symbol = { on_click = false },
  sources = {
    path = {
      -- Relative to the git root of the file, to the working directory outside a repo
      relative_to = function(buf, _) return vim.fs.root(buf, '.git') or vim.fn.getcwd() end,
      modified = function(sym) return sym:merge({ name = sym.name .. ' +' }) end,
    },
  },
})

-- Editor background, like the windows below
local function winbar_highlights()
  local bg = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg
  vim.api.nvim_set_hl(0, 'WinBar', { bg = bg })
  vim.api.nvim_set_hl(0, 'WinBarNC', { bg = bg })
end
winbar_highlights()
vim.api.nvim_create_autocmd('ColorScheme', { callback = winbar_highlights })
