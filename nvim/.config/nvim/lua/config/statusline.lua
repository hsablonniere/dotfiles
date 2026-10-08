-- [[ Statusline ]]
-- Hand-written, no plugin. Target layout (colors and order act as separators):
--
--   N main a1b2c3d4 M3S1?2 +3~1-2          2e5w luals 42:7 37%
--
-- - mode: one letter, background colored per mode
-- - repo: branch, short hash, status counts (same format as the starship prompt)
-- - file: lines added/changed/removed in the current buffer (gitsigns)
-- - diagnostics, LSP client names, position, percentage through the file
--
-- When the line is too wide, segments are dropped in this order:
-- percentage, hash, LSP names, file diff.

-- Highlight groups are derived from the colorscheme so the statusline follows any theme.
local function statusline_highlights()
  local function fg(name) return vim.api.nvim_get_hl(0, { name = name, link = false }).fg end
  local statusline = vim.api.nvim_get_hl(0, { name = 'StatusLine', link = false })
  -- Black, like the tabline: the statusline and the command line row under it
  local bg = 0
  vim.api.nvim_set_hl(0, 'StatusLine', { fg = statusline.fg, bg = bg })
  vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = statusline.fg, bg = bg })
  vim.api.nvim_set_hl(0, 'MsgArea', { bg = bg })
  local dark = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg

  -- Secondary text: statusline foreground faded toward its background. Themes usually pick
  -- `Comment` for this, but it is meant for the editor background and is barely readable here.
  local function blend(from, to, ratio)
    local out = 0
    for shift = 16, 0, -8 do
      local a, b = bit.band(bit.rshift(from, shift), 0xff), bit.band(bit.rshift(to, shift), 0xff)
      out = out + bit.lshift(math.floor(a + (b - a) * ratio + 0.5), shift)
    end
    return out
  end
  local faded = blend(statusline.bg, statusline.fg, 0.8)

  -- Winbars, editor background: faded file of the unfocused splits (the focused one is TlFile,
  -- see tabline.lua)
  vim.api.nvim_set_hl(0, 'SlTabName', { fg = faded, bg = dark, bold = true })
  vim.api.nvim_set_hl(0, 'SlTabNameDir', { fg = faded, bg = dark })
  vim.api.nvim_set_hl(0, 'WinBar', { bg = dark })
  vim.api.nvim_set_hl(0, 'WinBarNC', { bg = dark })

  vim.api.nvim_set_hl(0, 'SlHash', { fg = faded, bg = bg })
  vim.api.nvim_set_hl(0, 'SlLsp', { fg = faded, bg = bg })
  vim.api.nvim_set_hl(0, 'SlPct', { fg = faded, bg = bg })

  local text = {
    Macro = 'DiagnosticError',
    Branch = 'Keyword',
    Repo = 'Number',
    Add = 'Added',
    Change = 'Changed',
    Delete = 'Removed',
    Error = 'DiagnosticError',
    Warn = 'DiagnosticWarn',
    Info = 'DiagnosticInfo',
    Hint = 'DiagnosticHint',
  }
  for name, source in pairs(text) do
    vim.api.nvim_set_hl(0, 'Sl' .. name, { fg = fg(source), bg = bg })
  end

  local modes = {
    N = 'Function',
    O = 'Function',
    I = 'String',
    V = 'Statement',
    L = 'Statement',
    B = 'Statement',
    S = 'Statement',
    R = 'DiagnosticError',
    C = 'Type',
    T = 'Constant',
  }
  for letter, source in pairs(modes) do
    vim.api.nvim_set_hl(0, 'SlMode' .. letter, { fg = dark, bg = fg(source), bold = true })
  end
end
statusline_highlights()
vim.api.nvim_create_autocmd('ColorScheme', { callback = statusline_highlights })

-- `nvim_get_mode()` codes to one letter. Operator-pending ("no...") is checked separately.
local mode_letters = {
  n = 'N',
  i = 'I',
  v = 'V',
  V = 'L',
  ['\22'] = 'B', -- Ctrl-V
  s = 'S',
  S = 'S',
  ['\19'] = 'S', -- Ctrl-S
  R = 'R',
  c = 'C',
  ['!'] = 'C',
  t = 'T',
  r = 'N',
}

-- Repo status, starship style. `git status` runs asynchronously and the result is cached
-- per directory, so the statusline itself never waits on git.
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
  vim.b[buf].statusline_git_dir = dir
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
      vim.cmd.redrawstatus()
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

-- LSP progress (indexing, loading the project...): client id -> { progress token -> percentage or false }
local lsp_progress = {}
vim.api.nvim_create_autocmd('LspProgress', {
  callback = function(args)
    local id, token, value = args.data.client_id, args.data.params.token, args.data.params.value
    lsp_progress[id] = lsp_progress[id] or {}
    if value.kind == 'end' then
      lsp_progress[id][token] = nil
    else
      lsp_progress[id][token] = value.percentage or false
    end
  end,
})

-- Redraw when data shown in the statusline changes outside of a regular redraw
vim.api.nvim_create_autocmd({ 'ModeChanged', 'DiagnosticChanged', 'LspAttach', 'LspDetach', 'LspProgress', 'RecordingEnter', 'RecordingLeave' }, {
  callback = vim.schedule_wrap(function() vim.cmd.redrawstatus() end),
})
vim.api.nvim_create_autocmd('User', {
  pattern = 'GitSignsUpdate',
  callback = function() vim.cmd.redrawstatus() end,
})

-- A segment is a list of { text, highlight } parts. `drop` is its removal rank when space is
-- missing (1 goes first), nil means never dropped.
local function segment(parts, drop) return { parts = parts, drop = drop } end

local function segment_width(seg)
  local width = 0
  for _, part in ipairs(seg.parts) do
    width = width + vim.api.nvim_strwidth(part[1])
  end
  return width
end

local function render(segments)
  local out = {}
  for _, seg in ipairs(segments) do
    local text = {}
    for _, part in ipairs(seg.parts) do
      -- `%` is special in the statusline, escape it in dynamic text (branch names, etc.)
      table.insert(text, '%#' .. part[2] .. '#' .. part[1]:gsub('%%', '%%%%'))
    end
    table.insert(out, table.concat(text))
  end
  return table.concat(out, '%#StatusLine# ')
end

function _G.statusline()
  local left, right = {}, {}

  local mode = vim.api.nvim_get_mode().mode
  local letter = mode:sub(1, 2) == 'no' and 'O' or mode_letters[mode:sub(1, 1)] or 'N'
  table.insert(left, segment({ { ' ' .. letter .. ' ', 'SlMode' .. letter } }))

  -- Hidden by showmode=false otherwise
  local recording = vim.fn.reg_recording()
  if recording ~= '' then table.insert(left, segment({ { '@' .. recording, 'SlMacro' } })) end

  local git = git_cache[vim.b.statusline_git_dir or '']
  if git then
    if git.branch ~= '' then table.insert(left, segment({ { git.branch, 'SlBranch' } })) end
    if git.hash ~= '' then table.insert(left, segment({ { git.hash, 'SlHash' } }, 2)) end
    if git.status ~= '' then table.insert(left, segment({ { git.status, 'SlRepo' } })) end
  end

  local diff = vim.b.gitsigns_status_dict
  if diff then
    local parts = {}
    if (diff.added or 0) > 0 then table.insert(parts, { '+' .. diff.added, 'SlAdd' }) end
    if (diff.changed or 0) > 0 then table.insert(parts, { '~' .. diff.changed, 'SlChange' }) end
    if (diff.removed or 0) > 0 then table.insert(parts, { '-' .. diff.removed, 'SlDelete' }) end
    if #parts > 0 then table.insert(left, segment(parts, 4)) end
  end

  local counts = vim.diagnostic.count(0)
  local severities = { { 'ERROR', 'e', 'SlError' }, { 'WARN', 'w', 'SlWarn' }, { 'INFO', 'i', 'SlInfo' }, { 'HINT', 'h', 'SlHint' } }
  local diag = {}
  for _, s in ipairs(severities) do
    local n = counts[vim.diagnostic.severity[s[1]]] or 0
    if n > 0 then table.insert(diag, { n .. s[2], s[3] }) end
  end
  if #diag > 0 then table.insert(right, segment(diag)) end

  -- "lua_ls" -> "luals", with "…" or the lowest percentage while the server is working ("tsc 45%")
  local clients = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    local name = client.name:gsub('[_%-]', '')
    local jobs = lsp_progress[client.id]
    if jobs and next(jobs) then
      local lowest
      for _, percentage in pairs(jobs) do
        if percentage and (not lowest or percentage < lowest) then lowest = percentage end
      end
      name = name .. (lowest and ' ' .. lowest .. '%' or '…')
    end
    table.insert(clients, name)
  end
  if #clients > 0 then table.insert(right, segment({ { table.concat(clients, ','), 'SlLsp' } }, 3)) end

  local line, last = vim.fn.line('.'), vim.fn.line('$')
  table.insert(right, segment({ { line .. ':' .. vim.fn.virtcol('.'), 'StatusLine' } }))
  table.insert(right, segment({ { math.floor(line / last * 100) .. '%', 'SlPct' } }, 1))

  -- Drop segments by rank until everything fits (1 space between segments, 1 at the right edge)
  local all = vim.list_extend(vim.list_extend({}, left), right)
  local function total()
    local width = 1
    for _, seg in ipairs(all) do
      if not seg.hidden then width = width + segment_width(seg) + 1 end
    end
    return width
  end
  for rank = 1, 4 do
    if total() <= vim.o.columns then break end
    for _, seg in ipairs(all) do
      if seg.drop == rank then seg.hidden = true end
    end
  end
  local function visible(list)
    return vim.tbl_filter(function(seg) return not seg.hidden end, list)
  end

  return render(visible(left)) .. '%#StatusLine#%=' .. render(visible(right)) .. '%#StatusLine# '
end

vim.o.statusline = '%!v:lua.statusline()'
