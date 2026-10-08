-- [[ Tabline and winbars ]]
-- Like WebStorm's title bar and editor tabs:
-- - tabline (top, always shown): project name (git root of the current file, else the working
--   directory) in a blue block, then the active branch in a green arrow, like the starship prompt
-- - winbar (top of each split holding a file): the file shown in that split, its path inside the
--   project (relative to the git root, to home outside a repo) after the file icon, with the file
--   name in bold, "+" when modified, "RO" when read-only. The focused split has the name in
--   color, the others faded text.
--   Long paths are shortened fish style from the left (src/components/app.js -> s/c/app.js), then
--   the file name loses its start ("…mponent.js").
-- The list of open files is not displayed, see the picker (<leader>sb) and Tab / Shift+Tab.

local function buffer_flags(buf)
  local flags = ''
  if vim.bo[buf].modified then flags = flags .. ' +' end
  if vim.bo[buf].readonly or not vim.bo[buf].modifiable then flags = flags .. ' RO' end
  return flags
end

-- Git root per file name (false outside a repo), looked up once instead of on every redraw
local git_roots = {}

-- Path of a buffer inside its project, split on "/"
local function path_parts(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if git_roots[name] == nil then git_roots[name] = vim.fs.root(buf, '.git') or false end
  local root = git_roots[name]
  local path = root and vim.fs.relpath(root, name) or vim.fn.fnamemodify(name, ':~')
  return vim.split(path, '/', { plain = true })
end

-- Directory and file name fitting in `room` columns
local function fit_path(parts, room)
  local width = function() return vim.api.nvim_strwidth(table.concat(parts, '/')) end
  for i = 1, #parts - 1 do
    if width() <= room then break end
    -- Keep the leading dot of hidden directories, like fish: .config -> .c
    parts[i] = vim.fn.strcharpart(parts[i], 0, parts[i]:sub(1, 1) == '.' and 2 or 1)
  end
  local name = table.remove(parts)
  local dir = #parts > 0 and table.concat(parts, '/') .. '/' or ''
  local dir_width = vim.api.nvim_strwidth(dir)
  if dir_width + vim.api.nvim_strwidth(name) > room then
    -- Drop the directory, then the start of the name
    dir, dir_width = '', 0
    local full, keep = name, vim.fn.strchars(name)
    while keep > 0 and vim.api.nvim_strwidth(name) > room do
      keep = keep - 1
      name = '…' .. vim.fn.strcharpart(full, vim.fn.strchars(full) - keep)
    end
    if vim.api.nvim_strwidth(name) > room then name = '' end
  end
  return dir, name
end

local function escape(text) return (text:gsub('%%', '%%%%')) end

-- Same blocks and colors as the starship prompt (starship.toml): blue project, green branch,
-- arrow-shaped ends, no rounded start. The text is white and the rest of the line black.
local function define_highlights()
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
  local black = '#000000'
  local function set(name, opts) vim.api.nvim_set_hl(0, name, opts) end
  set('TlProject', { fg = '#ffffff', bg = '#3456a4', bold = true })
  set('TlProjectArrow', { fg = '#3456a4', bg = '#466b3e' })
  set('TlBranch', { fg = '#ffffff', bg = '#466b3e' })
  set('TlProjectEnd', { fg = '#3456a4', bg = black })
  set('TlBranchArrow', { fg = '#466b3e', bg = black })
  -- Winbar: in the focused split the file name in the theme's function color and the directory in
  -- normal text, the others faded (SlTabName)
  local function fg(name) return vim.api.nvim_get_hl(0, { name = name, link = false }).fg end
  set('TlFile', { fg = fg('Function'), bg = normal.bg, bold = true })
  set('TlFileDir', { fg = normal.fg, bg = normal.bg })
  -- Rest of the tabline line
  set('TabLineFill', { bg = black })
end
define_highlights()
vim.api.nvim_create_autocmd('ColorScheme', { callback = define_highlights })

function _G.tabline()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local root = (name ~= '' and vim.fs.root(buf, '.git')) or vim.fn.getcwd()
  local out = { ('%%#TlProject# %s '):format(escape(vim.fs.basename(root))) }
  local branch = vim.b[buf].gitsigns_head
  if branch and branch ~= '' then
    table.insert(out, ('%%#TlProjectArrow#\u{e0b0}%%#TlBranch# \u{e0a0} %s %%#TlBranchArrow#\u{e0b0}'):format(escape(branch)))
  else
    table.insert(out, '%#TlProjectEnd#\u{e0b0}')
  end
  return table.concat(out) .. '%#TabLineFill#'
end

-- Nerd Font icon of the file in its own color, on the winbar background (mini.icons, see explorer.lua)
local function file_icon(buf)
  local icon, icon_hl = require('mini.icons').get('file', vim.api.nvim_buf_get_name(buf))
  local group = 'TlIcon' .. icon_hl
  vim.api.nvim_set_hl(0, group, {
    fg = vim.api.nvim_get_hl(0, { name = icon_hl, link = false }).fg,
    bg = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg,
  })
  return ('%%#%s# %s '):format(group, escape(icon))
end

function _G.winbar()
  local win = vim.g.statusline_winid
  local buf = vim.api.nvim_win_get_buf(win)
  local focused = win == vim.api.nvim_get_current_win()
  local parts, flags = path_parts(buf), buffer_flags(buf)
  local dir, name = fit_path(parts, vim.api.nvim_win_get_width(win) - 4 - #flags)
  local file, file_dir = focused and 'TlFile' or 'SlTabName', focused and 'TlFileDir' or 'SlTabNameDir'
  return ('%s%%#%s#%s%%#%s#%s%%#WinBar#'):format(file_icon(buf), file_dir, escape(dir), file, escape(name .. flags))
end

vim.o.tabline = '%!v:lua.tabline()'
vim.o.showtabline = 2

-- Winbar only on windows showing a file (not on the explorer, terminals, help...), set per window
-- as the same buffer can show up in a window without one
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(win).relative ~= '' then return end
    local file = vim.bo.buftype == '' and vim.api.nvim_buf_get_name(0) ~= ''
    vim.wo[win].winbar = file and '%!v:lua.winbar()' or ''
  end,
})

-- Next / previous buffer. Tab and Ctrl+I are the same key in most terminals, Ghostty tells them
-- apart so Ctrl+I keeps jumping forward in the jump list.
vim.keymap.set('n', '<Tab>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-Tab>', '<cmd>bprevious<cr>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<leader>bn', '<cmd>bnext<cr>', { desc = 'Next' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprevious<cr>', { desc = 'Previous' })
-- Close the current file but keep the splits: every window showing it switches to another file
-- first, then the buffer is deleted
vim.keymap.set('n', '<leader>bd', function() Snacks.bufdelete() end, { desc = 'Close (keep splits)' })
