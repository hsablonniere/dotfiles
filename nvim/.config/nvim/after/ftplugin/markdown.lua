-- Markdown specific settings. Reading and browsing notes is the main use case,
-- writing code in them is not.

-- Treesitter highlighting. The markdown and markdown_inline parsers ship with
-- Neovim, but highlighting is not enabled by default.
pcall(vim.treesitter.start)

-- Hide the markup itself (**, _, link targets) for a calmer read, except on the
-- line being edited, where the raw syntax is needed.
vim.wo.conceallevel = 2
vim.wo.concealcursor = ''

-- Soft wrap on word boundaries, with wrapped lines indented like the first one.
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.breakindent = true

-- With wrapping on, j and k should move by visual line, unless a count is given:
-- 3j still means three real lines down.
vim.keymap.set({ 'n', 'v' }, 'j', function()
  return vim.v.count == 0 and 'gj' or 'j'
end, { buffer = true, expr = true })
vim.keymap.set({ 'n', 'v' }, 'k', function()
  return vim.v.count == 0 and 'gk' or 'k'
end, { buffer = true, expr = true })

-- Folding by section, driven by the treesitter tree: one fold per heading,
-- nested like the headings are. Everything starts unfolded.
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.wo.foldlevel = 99

-- Spell checking is on only to feed the kspell completion source with French and
-- English words. Nothing is underlined: the spell highlight groups are cleared
-- in init.lua. No correction, no noise, just more words behind <C-n>.
vim.wo.spell = true
vim.bo.spelllang = 'fr,en'

-- Check box toggling. On a list item without a box, one is added unticked, so a
-- plain bullet becomes a task in one keystroke.
local function toggle_check_box(line)
  local bullet, state = line:match('^(%s*[-*+]%s+)%[([ xX])%]')
  if bullet then
    local box = state == ' ' and '[x]' or '[ ]'
    return line:gsub('^(%s*[-*+]%s+)%[[ xX]%]', '%1' .. box, 1)
  end
  if line:match('^%s*[-*+]%s+') then
    return line:gsub('^(%s*[-*+]%s+)', '%1[ ] ', 1)
  end
  return line
end

local function toggle_check_boxes(first, last)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  for i, line in ipairs(lines) do
    lines[i] = toggle_check_box(line)
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, lines)
end

vim.keymap.set('n', '<leader>x', function()
  local line = vim.fn.line('.')
  toggle_check_boxes(line, line)
end, { buffer = true, desc = 'Toggle the check box' })

vim.keymap.set('v', '<leader>x', function()
  -- Leave visual mode first, so that the '< and '> marks are set.
  vim.cmd('normal! \27')
  toggle_check_boxes(vim.fn.line("'<"), vim.fn.line("'>"))
end, { buffer = true, desc = 'Toggle the check boxes' })
