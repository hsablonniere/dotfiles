-- [[ Tabline ]]
-- Open files at the top of the screen, always shown, aligned on the left: the current file in a
-- pill colored like the normal mode, the others as faded text. Each one shows its path inside
-- the project (relative to the git root, to home outside a repo), the file name in bold, "+"
-- when modified, "RO" when read-only. When they do not fit, the longest paths are shortened
-- fish style from the left (src/components/app.js -> s/c/app.js), then the file name loses its
-- start ("…mponent.js"). Files never get narrower than MIN_SLOT: when they do not all fit, they
-- scroll to keep the current file visible, "…" marking hidden ones. A click on a file switches
-- to it.
local MIN_SLOT = 20

local function listed_buffers()
  return vim.tbl_filter(function(buf) return vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= '' end, vim.api.nvim_list_bufs())
end

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

function _G.tabline_click(buf) vim.api.nvim_set_current_buf(buf) end

function _G.tabline()
  local bufs = listed_buffers()
  if #bufs == 0 then return '%#TabLineFill#' end
  local current = vim.api.nvim_get_current_buf()
  local function escape(text) return (text:gsub('%%', '%%%%')) end

  -- How many pills fit (a space between two), and which ones are shown around the current file
  local columns = vim.o.columns
  local count = #bufs
  if count * MIN_SLOT + count - 1 > columns then
    -- Scrolling: room for the "…" markers on both sides
    count = math.max(1, math.floor((columns - 2 + 1) / (MIN_SLOT + 1)))
  end
  local focus = 1
  for i, buf in ipairs(bufs) do
    if buf == current then focus = i end
  end
  local first = math.max(1, math.min(focus - math.floor((count - 1) / 2), #bufs - count + 1))
  local last = first + count - 1
  local before, after = first > 1 and '…' or '', last < #bufs and '…' or ''

  -- Each pill takes the width of its full path (+2 for its rounded ends) when everything fits.
  -- Otherwise the width is shared: the shortest pills keep their full width, the others split
  -- what is left evenly.
  local pills = {}
  for i = first, last do
    local parts, flags = path_parts(bufs[i]), buffer_flags(bufs[i])
    table.insert(pills, { buf = bufs[i], parts = parts, flags = flags, width = vim.api.nvim_strwidth(table.concat(parts, '/') .. flags) + 2 })
  end
  local by_width = vim.list_slice(pills)
  table.sort(by_width, function(a, b) return a.width < b.width end)
  local room = columns - (count - 1) - vim.api.nvim_strwidth(before .. after)
  for k, pill in ipairs(by_width) do
    pill.width = math.min(pill.width, math.floor(room / (#by_width - k + 1)))
    room = room - pill.width
  end

  -- Aligned on the left. The current file is a pill colored like the normal mode, its rounded
  -- ends are Nerd Font half circles. The others are faded text, spaces in place of the ends.
  local out = { '%#SlTabOther#' .. before }
  for k, pill in ipairs(pills) do
    local dir, name = fit_path(pill.parts, pill.width - 2 - #pill.flags)
    local is_current = pill.buf == current
    local hl = is_current and 'SlTabCurrent' or 'SlTabName'
    local open, close = is_current and '\u{e0b6}' or ' ', is_current and '\u{e0b4}' or ' '
    if k > 1 then table.insert(out, '%#SlTabOther# ') end
    table.insert(out, ('%%%d@v:lua.tabline_click@'):format(pill.buf))
    table.insert(out, ('%%#%sCap#%s%%#%sDir#%s%%#%s#%s%%#%sCap#%s%%X'):format(hl, open, hl, escape(dir), hl, escape(name .. pill.flags), hl, close))
  end
  table.insert(out, '%#SlTabOther#' .. after)
  return table.concat(out) .. '%#TabLineFill#'
end

vim.o.tabline = '%!v:lua.tabline()'
vim.o.showtabline = 2

-- Next / previous buffer. Tab and Ctrl+I are the same key in most terminals, Ghostty tells them
-- apart so Ctrl+I keeps jumping forward in the jump list.
vim.keymap.set('n', '<Tab>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-Tab>', '<cmd>bprevious<cr>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<leader>bn', '<cmd>bnext<cr>', { desc = 'Next' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprevious<cr>', { desc = 'Previous' })
-- Close the current file but keep the splits: every window showing it switches to another file
-- first, then the buffer is deleted
vim.keymap.set('n', '<leader>bd', function() Snacks.bufdelete() end, { desc = 'Close (keep splits)' })
