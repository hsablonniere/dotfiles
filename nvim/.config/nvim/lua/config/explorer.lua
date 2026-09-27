-- [[ Icons ]]
-- Nerd Font file icons, used by the picker
vim.pack.add({ 'https://github.com/nvim-mini/mini.icons' })
require('mini.icons').setup()
-- Serve plugins that expect nvim-web-devicons (neo-tree)
require('mini.icons').mock_nvim_web_devicons()

-- [[ File explorer and outline ]]
-- neo-tree in a centered floating window, closed by Esc or q, ? lists its keys:
-- - <leader>e: file tree opened on the current file, opening a file closes it (a add, d delete,
--   r rename, c copy, m move...)
-- - <leader>o: outline of the current file (language server symbols)
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
    position = 'float',
    popup = { size = { width = 60, height = '80%' } },
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
vim.keymap.set('n', '<leader>e', '<cmd>Neotree float reveal toggle<cr>', { desc = 'File [E]xplorer' })
-- Outline of the current file (LSP symbols), in the same window
vim.keymap.set('n', '<leader>o', '<cmd>Neotree float document_symbols toggle<cr>', { desc = '[O]utline' })

-- The inside of the window uses the editor background, give the border and its title the same
-- one so only the line shows (the theme gives them the floating windows background)
local function explorer_border_highlights()
  local function fg(name) return vim.api.nvim_get_hl(0, { name = name, link = false }).fg end
  local bg = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg
  vim.api.nvim_set_hl(0, 'NeoTreeFloatBorder', { fg = fg('FloatBorder'), bg = bg })
  vim.api.nvim_set_hl(0, 'NeoTreeFloatTitle', { fg = fg('FloatTitle'), bg = bg })
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
