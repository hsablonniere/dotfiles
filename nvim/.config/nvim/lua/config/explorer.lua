-- [[ Icons ]]
-- Nerd Font file icons, used by the picker
vim.pack.add({ 'https://github.com/nvim-mini/mini.icons' })
require('mini.icons').setup()
-- Serve plugins that expect nvim-web-devicons (neo-tree)
require('mini.icons').mock_nvim_web_devicons()

-- [[ File explorer and outline ]]
-- neo-tree in a sidebar, closed by q, ? lists its keys:
-- - <M-a>: file tree on the right, opened on the current file (a add, d delete, r rename, c copy,
--   m move...)
-- - <M-A> (Alt+Shift+a): outline of the current file on the left (language server symbols)
vim.pack.add({
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range('3') },
  -- Required by neo-tree
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
})
-- Arrow navigation like WebStorm's trees (files and symbols):
-- Right: open a closed node, or go to the first child of an open one
-- Left: close an open node, or go to the parent node
local function tree_toggle(state)
  local source = state.name == 'filesystem' and 'filesystem' or 'common'
  require('neo-tree.sources.' .. source .. '.commands').toggle_node(state)
end
local function tree_expandable(node) return node.type == 'directory' or node:has_children() end
local function tree_right(state)
  local node = state.tree:get_node()
  if not tree_expandable(node) then return end
  if not node:is_expanded() then
    tree_toggle(state)
  elseif node:has_children() then
    require('neo-tree.ui.renderer').focus_node(state, node:get_child_ids()[1])
  end
end
local function tree_left(state)
  local node = state.tree:get_node()
  if tree_expandable(node) and node:is_expanded() then
    tree_toggle(state)
  elseif node:get_parent_id() then
    require('neo-tree.ui.renderer').focus_node(state, node:get_parent_id())
  end
end

require('neo-tree').setup({
  sources = { 'filesystem', 'document_symbols' },
  popup_border_style = 'rounded',
  -- Keep the cursor on the first letter of the file name
  enable_cursor_hijack = true,
  window = {
    position = 'right',
    width = 40,
    mappings = { ['<Right>'] = tree_right, ['<Left>'] = tree_left },
  },
  filesystem = {
    -- Refresh on file changes made outside nvim
    use_libuv_file_watcher = true,
    filtered_items = { hide_dotfiles = false, hide_gitignored = true, hide_by_name = { '.git' } },
  },
  document_symbols = {
    -- Icon and name only, no kind column ("Function", "Class"...)
    renderers = {
      symbol = {
        { 'indent', with_expanders = true },
        { 'kind_icon', default = '?' },
        { 'name', zindex = 10 },
      },
    },
  },
  event_handlers = {
    -- Renaming or moving a file updates its imports through the language servers
    { event = 'file_renamed', handler = function(data) Snacks.rename.on_rename_file(data.source, data.destination) end },
    { event = 'file_moved', handler = function(data) Snacks.rename.on_rename_file(data.source, data.destination) end },
    {
      -- Symbols are collapsed by default: unfold everything, like WebStorm's Structure
      event = 'after_render',
      handler = function(state)
        if state.name ~= 'document_symbols' or state.expanding_all then return end
        state.expanding_all = true
        require('neo-tree.sources.common.commands').expand_all_nodes(state)
        state.expanding_all = false
      end,
    },
  },
  -- Only names, no size/type/date columns
  default_component_configs = {
    file_size = { enabled = false },
    type = { enabled = false },
    last_modified = { enabled = false },
    created = { enabled = false },
  },
})
vim.keymap.set({ 'n', 'i', 'v' }, '<M-a>', '<cmd>Neotree right reveal toggle<cr>', { desc = 'File explorer' })
-- Outline of the current file (LSP symbols), on the left
vim.keymap.set({ 'n', 'i', 'v' }, '<M-A>', '<cmd>Neotree left document_symbols toggle<cr>', { desc = 'Outline' })

-- The inside of the windows uses the editor background, give the border, its title and the
-- sidebar separators the same one so only the line shows (the theme gives them other backgrounds)
local function explorer_border_highlights()
  local function fg(name) return vim.api.nvim_get_hl(0, { name = name, link = false }).fg end
  local bg = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg
  vim.api.nvim_set_hl(0, 'NeoTreeFloatBorder', { fg = fg('FloatBorder'), bg = bg })
  vim.api.nvim_set_hl(0, 'NeoTreeFloatTitle', { fg = fg('FloatTitle'), bg = bg })
  -- Sidebars: same background focused or not, same separator line on both sides
  vim.api.nvim_set_hl(0, 'NeoTreeNormal', { bg = bg })
  vim.api.nvim_set_hl(0, 'NeoTreeNormalNC', { bg = bg })
  vim.api.nvim_set_hl(0, 'NeoTreeWinSeparator', { fg = fg('WinSeparator'), bg = bg })
  vim.api.nvim_set_hl(0, 'NeoTreeVertSplit', { fg = fg('WinSeparator'), bg = bg })
end
explorer_border_highlights()
-- Delayed so it runs after neo-tree redefines its own highlights, which it does asynchronously
vim.api.nvim_create_autocmd('ColorScheme', { callback = function() vim.defer_fn(explorer_border_highlights, 100) end })

-- Hide the cursor in the explorer, only the highlighted line shows where you are. A cursor
-- highlight with full blend makes the terminal hide it. Its input prompts (filter, rename...)
-- have another filetype and keep the cursor.
local default_guicursor = vim.o.guicursor
local function hidden_cursor_highlight() vim.api.nvim_set_hl(0, 'HiddenCursor', { blend = 100, nocombine = true }) end
hidden_cursor_highlight()
vim.api.nvim_create_autocmd('ColorScheme', { callback = hidden_cursor_highlight })
vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter', 'FileType', 'CmdlineEnter', 'CmdlineLeave' }, {
  -- Deferred: in CmdlineLeave the mode is still "c"
  callback = function()
    vim.schedule(function()
      local hide = vim.bo.filetype == 'neo-tree' and vim.fn.mode() ~= 'c'
      vim.o.guicursor = hide and 'a:HiddenCursor' or default_guicursor
    end)
  end,
})
