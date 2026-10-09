-- [[ Status info ]]
-- Hand-written, no plugin. The recorded macro, mode, diagnostics, LSP names, position and
-- percentage are drawn at the right of the tabline (`status_info()`, called from tabline.lua),
-- there is no statusline (laststatus=0):
--
--   @q 2e5w 12 luals  42:7  37% N
--
-- - macro: register being recorded, only while recording
-- - diagnostics, pending keys (12 while typing 12j, only then), LSP client names, position,
--   percentage through the file
-- - mode: one letter, background colored per mode, at the very right
--
-- Each part is a block with an arrow, like the starship prompt, in blues. When the line is too
-- wide, blocks are dropped in this order: percentage, pending keys, LSP names.

-- Background of the blocks at the right of the tabline: blues getting darker toward the edge, the
-- last one is the 1Password blue of the starship prompt (starship.toml). The macro is the red of
-- its status block.
local BLOCK_COLORS = { macro = 0xe20000, diag = 0x5469a0, keys = 0x4a5f94, lsp = 0x3f5388, pos = 0x34487c, pct = 0x293f71 }

-- Highlight groups are derived from the colorscheme for the mode colors, so they follow any theme.
local function status_highlights()
  local function fg(name) return vim.api.nvim_get_hl(0, { name = name, link = false }).fg end
  local dark = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg
  -- Black, like the tabline: the command line row at the bottom
  vim.api.nvim_set_hl(0, 'MsgArea', { bg = 0 })

  for name, color in pairs({ Macro = BLOCK_COLORS.macro, Diag = BLOCK_COLORS.diag, Keys = BLOCK_COLORS.keys, Lsp = BLOCK_COLORS.lsp, Pos = BLOCK_COLORS.pos, Pct = BLOCK_COLORS.pct }) do
    vim.api.nvim_set_hl(0, 'SlBlock' .. name, { fg = 0xffffff, bg = color })
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
status_highlights()
vim.api.nvim_create_autocmd('ColorScheme', { callback = status_highlights })

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

-- Redraw the tabline when data shown in it changes outside of a regular redraw, and with the cursor
vim.api.nvim_create_autocmd({ 'ModeChanged', 'DiagnosticChanged', 'LspAttach', 'LspDetach', 'LspProgress', 'RecordingEnter', 'RecordingLeave', 'CursorMoved', 'CursorMovedI' }, {
  callback = vim.schedule_wrap(function() vim.cmd.redrawtabline() end),
})

-- Mode, diagnostics, LSP names, position and percentage, shown at the right of the tabline
-- (see tabline.lua) as blocks with arrows, like the right side of the starship prompt. Returns the rendered text and its width, dropping blocks to fit `room`.
function _G.status_info(room)
  local blocks = {}
  local function block(text, hl, bg, drop) table.insert(blocks, { text = ' ' .. text .. ' ', hl = hl, bg = bg, drop = drop }) end

  -- Hidden by showmode=false otherwise
  local recording = vim.fn.reg_recording()
  if recording ~= '' then block('@' .. recording, 'SlBlockMacro', BLOCK_COLORS.macro) end

  local counts = vim.diagnostic.count(0)
  local severities = { { 'ERROR', 'e' }, { 'WARN', 'w' }, { 'INFO', 'i' }, { 'HINT', 'h' } }
  local diag = ''
  for _, s in ipairs(severities) do
    local n = counts[vim.diagnostic.severity[s[1]]] or 0
    if n > 0 then diag = diag .. n .. s[2] end
  end
  if diag ~= '' then block(diag, 'SlBlockDiag', BLOCK_COLORS.diag) end

  -- Keys typed so far in a pending command (12 in 12j), noice shows them instead of nvim
  local keys = require('noice').api.status.command.get()
  if keys and keys ~= '' then block(keys, 'SlBlockKeys', BLOCK_COLORS.keys, 2) end

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
  if #clients > 0 then block(table.concat(clients, ','), 'SlBlockLsp', BLOCK_COLORS.lsp, 3) end

  local line, last = vim.fn.line('.'), vim.fn.line('$')
  -- No padding: each block is as wide as its content
  block(('%d:%d'):format(line, vim.fn.virtcol('.')), 'SlBlockPos', BLOCK_COLORS.pos)
  block(('%d%%'):format(math.floor(line / last * 100)), 'SlBlockPct', BLOCK_COLORS.pct, 1)

  local mode = vim.api.nvim_get_mode().mode
  local letter = mode:sub(1, 2) == 'no' and 'O' or mode_letters[mode:sub(1, 1)] or 'N'
  block(letter, 'SlMode' .. letter, vim.api.nvim_get_hl(0, { name = 'SlMode' .. letter, link = false }).bg)


  -- Each block is preceded by an arrow
  local function total()
    local width = 0
    for _, b in ipairs(blocks) do
      if not b.hidden then width = width + 1 + vim.api.nvim_strwidth(b.text) end
    end
    return width
  end
  for rank = 1, 4 do
    if total() <= room then break end
    for _, b in ipairs(blocks) do
      if b.drop == rank then b.hidden = true end
    end
  end

  local out, previous = {}, 0
  for _, b in ipairs(blocks) do
    if not b.hidden then
      -- Arrow in the color of the block on the background of the previous one (or of the line)
      vim.api.nvim_set_hl(0, 'SlArrow' .. b.bg .. '_' .. previous, { fg = b.bg, bg = previous })
      table.insert(out, '%#SlArrow' .. b.bg .. '_' .. previous .. '#\u{e0b2}%#' .. b.hl .. '#' .. b.text:gsub('%%', '%%%%'))
      previous = b.bg
    end
  end
  return table.concat(out), total()
end
