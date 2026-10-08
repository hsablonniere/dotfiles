-- [[ Command line and messages ]]
-- noice.nvim: ":" and "/" open in a small popup at the top of the screen instead of the bottom
-- line, messages (errors, "written", command output) go to the notifications (snacks). The
-- bottom line is hidden (cmdheight=0), so the screen ends with the editor.
vim.pack.add({
  { src = 'https://github.com/folke/noice.nvim', version = vim.version.range('4') },
  -- Required by noice, also used by neo-tree
  'https://github.com/MunifTanjim/nui.nvim',
})
vim.o.cmdheight = 0
require('noice').setup({
  -- Hover, signature help and progress are handled elsewhere (lsp.lua, status_info.lua)
  lsp = {
    progress = { enabled = false },
    hover = { enabled = false },
    signature = { enabled = false },
  },
  views = {
    -- Popups at the top of the screen, just under the tabline
    cmdline_popup = { position = { row = 2, col = '50%' }, size = { width = 60, height = 'auto' } },
    popupmenu = { relative = 'editor', position = { row = 5, col = '50%' }, size = { width = 60, height = 10 }, border = { style = 'rounded', padding = { 0, 1 } } },
  },
  presets = {
    -- Long command output (:messages, :lua =...) opens in a split instead of a notification
    long_message_to_split = true,
  },
})

-- Pending keys (12 in 12j), shown in the tabline (status_info.lua). Noice keeps the last showcmd
-- text once nvim clears it, so it is removed here, and the tabline is redrawn on each change.
local msg = require('noice.ui.msg')
local manager = require('noice.message.manager')
msg.on_showcmd = function(event, content)
  local message = msg.get(event)
  if vim.tbl_isempty(content) then
    manager.remove(message)
  else
    message:set(content)
    manager.add(message)
  end
  pcall(vim.api.nvim__redraw, { tabline = true, flush = true })
end
