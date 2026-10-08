-- [[ Tabline ]]
-- Like WebStorm's title bar (the file bar of each split is in winbar.lua): project name (git
-- root of the current file, else the working directory) in a blue block, then the git
-- block (branch, short hash, status counts) in green, like the starship prompt. The list of
-- open files is not displayed, see the picker (<leader>sb) and Tab / Shift+Tab.

local function escape(text) return (text:gsub('%%', '%%%%')) end

-- Same blocks and colors as the starship prompt (starship.toml): blue project, green git,
-- arrow-shaped ends, no rounded start. The text is white.
local function define_highlights()
  local black = '#000000'
  local project, branch, text = '#3456a4', '#466b3e', '#ffffff'
  local function set(name, opts) vim.api.nvim_set_hl(0, name, opts) end
  set('TlProject', { fg = text, bg = project, bold = true })
  set('TlProjectArrow', { fg = project, bg = branch })
  set('TlBranch', { fg = text, bg = branch })
  set('TlProjectEnd', { fg = project, bg = black })
  set('TlBranchArrow', { fg = branch, bg = black })
  -- Dotted line filling the rest, like starship's fill
  set('TlFill', { fg = '#333333', bg = black })
  -- Rest of the tabline line
  set('TabLineFill', { bg = black })
end
define_highlights()
vim.api.nvim_create_autocmd('ColorScheme', { callback = define_highlights })

-- Repo status, starship style. `git status` runs asynchronously and the result is cached
-- per directory, so the tabline itself never waits on git.
local git_cache = {} -- dir -> { branch, hash, status } or false when not a repo
local git_running = {} -- dir -> true while running, 'again' if a refresh was requested meanwhile
-- dir -> true when its cached status is up to date. Cleared for every directory by events that
-- may change a repo, since several cached directories can belong to the same repo.
local git_fresh = {}

local function git_parse(output)
  local result = { branch = '', hash = '', status = '' }
  local count = { u = 0, D = 0, R = 0, M = 0, S = 0, ['?'] = 0 }
  local ahead, behind = 0, 0

  for line in vim.gsplit(output, '\n', { plain = true, trimempty = true }) do
    local key, value = line:match('^# branch%.(%S+) (.*)$')
    if key == 'oid' and value ~= '(initial)' then
      result.hash = value:sub(1, 8)
    elseif key == 'head' and value ~= '(detached)' then
      result.branch = value
    elseif key == 'ab' then
      local a, b = value:match('^%+(%d+) %-(%d+)$')
      ahead, behind = tonumber(a) or 0, tonumber(b) or 0
    else
      -- Porcelain v2 entries: "1"/"2" changed/renamed (XY = index/worktree), "u" unmerged, "?" untracked
      local kind = line:sub(1, 1)
      if kind == '?' then
        count['?'] = count['?'] + 1
      elseif kind == 'u' then
        count.u = count.u + 1
      elseif kind == '1' or kind == '2' then
        local x, y = line:sub(3, 3), line:sub(4, 4)
        if x == 'D' or y == 'D' then count.D = count.D + 1 end
        if x == 'R' then count.R = count.R + 1 end
        if y == 'M' then count.M = count.M + 1 end
        if x ~= '.' then count.S = count.S + 1 end
      end
    end
  end

  -- Same order and symbols as starship's $all_status$ahead_behind
  local parts = {}
  local symbols = { { 'u', '\u{f071}' }, { 'D', 'D' }, { 'R', 'R' }, { 'M', 'M' }, { 'S', 'S' }, { '?', '?' } }
  for _, symbol in ipairs(symbols) do
    local n = count[symbol[1]]
    if n > 0 then table.insert(parts, symbol[2] .. n) end
  end
  if ahead > 0 and behind > 0 then
    table.insert(parts, behind .. '\u{eb6f}\u{eb70}' .. ahead)
  elseif ahead > 0 then
    table.insert(parts, '\u{eb70}' .. ahead)
  elseif behind > 0 then
    table.insert(parts, behind .. '\u{eb6f}')
  end
  result.status = table.concat(parts)

  return result
end

-- `if_stale`: only run git when the cached status of this directory is not up to date
local function git_refresh(buf, if_stale)
  if vim.bo[buf].buftype ~= '' then return end
  local name = vim.api.nvim_buf_get_name(buf)
  local dir = name ~= '' and vim.fs.dirname(name) or vim.fn.getcwd()
  if vim.fn.isdirectory(dir) == 0 then return end
  vim.b[buf].tabline_git_dir = dir
  if if_stale and git_fresh[dir] then return end

  if git_running[dir] then
    git_running[dir] = 'again'
    return
  end
  git_running[dir] = true

  vim.system(
    -- Untracked files are listed one by one (not collapsed into their directory), like starship counts them
    { 'git', 'status', '--porcelain=v2', '--branch', '--untracked-files=all' },
    -- Avoid taking the index lock, so a concurrent git command in a terminal never fails because of us
    { cwd = dir, text = true, env = { GIT_OPTIONAL_LOCKS = '0' } },
    vim.schedule_wrap(function(res)
      git_cache[dir] = res.code == 0 and git_parse(res.stdout) or false
      git_fresh[dir] = true
      local again = git_running[dir] == 'again'
      git_running[dir] = nil
      vim.cmd.redrawtabline()
      if again and vim.api.nvim_buf_is_valid(buf) then git_refresh(buf) end
    end)
  )
end

-- Switching file reuses the cached status of its directory while it is up to date. Events that may
-- change a repo mark every directory stale and refresh the current file. In a terminal (gtui...),
-- the refresh happens when entering the next file.
vim.api.nvim_create_autocmd('BufEnter', {
  callback = function(args) git_refresh(args.buf, true) end,
})
vim.api.nvim_create_autocmd({ 'BufWritePost', 'FocusGained', 'ShellCmdPost', 'TermLeave', 'TermClose' }, {
  callback = function(args)
    git_fresh = {}
    git_refresh(args.buf)
  end,
})

function _G.tabline()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local root = (name ~= '' and vim.fs.root(buf, '.git')) or vim.fn.getcwd()
  local project = ' ' .. vim.fs.basename(root) .. ' '
  local out = { '%#TlProject#' .. escape(project) }
  local used = vim.api.nvim_strwidth(project) + 1
  -- Branch, short hash and status, same content as the starship git block
  local git = git_cache[vim.b[buf].tabline_git_dir or '']
  local content = {}
  if git then
    for _, part in ipairs({ git.branch, git.hash, git.status }) do
      if part ~= '' then table.insert(content, part) end
    end
  end
  if #content > 0 then
    local text = ' ' .. table.concat(content, ' ') .. ' '
    table.insert(out, '%#TlProjectArrow#\u{e0b0}%#TlBranch#' .. escape(text) .. '%#TlBranchArrow#\u{e0b0}')
    used = used + vim.api.nvim_strwidth(text) + 1
  else
    table.insert(out, '%#TlProjectEnd#\u{e0b0}')
  end
  -- Mode, diagnostics, LSP, position and percentage at the right (colored blocks), the dots fill
  -- what is left, a space on each side
  local info, info_width = _G.status_info(vim.o.columns - used - 4)
  table.insert(out, '%#TlFill# ' .. ('·'):rep(math.max(0, vim.o.columns - used - info_width - 2)) .. ' ' .. info)
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
