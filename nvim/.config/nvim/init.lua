-- Space as the leader key, before any mapping that uses it.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable the arrow keys to force learning hjkl and the real motions.
-- Normal, insert and visual modes only: command-line mode keeps its arrows
-- so that history navigation and completion menus still work.
for _, key in ipairs({ '<Up>', '<Down>', '<Left>', '<Right>' }) do
  vim.keymap.set({ 'n', 'i', 'v' }, key, '<Nop>')
end

-- Line numbers: absolute on the cursor line, relative elsewhere, so that
-- counted motions like 7k can be read straight off the gutter.
vim.o.number = true
vim.o.relativenumber = true

-- Searching: case insensitive, unless the pattern contains an upper case letter.
vim.o.ignorecase = true
vim.o.smartcase = true

-- Share the system clipboard, so that y and p work with the rest of the desktop.
vim.o.clipboard = 'unnamedplus'

-- Keep a few lines of context around the cursor when scrolling.
vim.o.scrolloff = 5

-- Undo history kept across sessions, in ~/.local/state/nvim/undo. This is the
-- safety net for the autosave below: without it, closing a file would drop every
-- undo step, and an accidental deletion is already on disk.
vim.o.undofile = true

-- Reopen a file where it was left, rather than on line one.
vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('restore_cursor', { clear = true }),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Built-in completion, no plugin needed. Manual on purpose: the menu only shows
-- up when asked for, with <C-n>, rather than popping up while typing.
-- Completion sources: current buffer and other open buffers.
vim.o.autocomplete = false
vim.o.completeopt = 'menuone,noselect,popup'

-- Word list used by dictionary completion.
-- Same file the VS Code spell checker reads through cSpell.customDictionaries.
vim.o.dictionary = vim.fn.expand('~/.dictionary.txt')

-- Completion sources for <C-n>, in order: current buffer, other windows, other
-- buffers, unloaded buffers, the dictionary above, then the French and English
-- spell dictionaries.
vim.opt.complete = { '.', 'w', 'b', 'u', 'k', 'kspell' }

-- The kspell source needs spell checking to be on, but the point here is
-- completion, not correction. Clearing the spell highlight groups keeps the word
-- lists available while showing no underline at all.
-- Reapplied on every colorscheme change, since colorschemes define these groups.
local function mute_spell_highlights()
  for _, group in ipairs({ 'SpellBad', 'SpellCap', 'SpellRare', 'SpellLocal' }) do
    vim.api.nvim_set_hl(0, group, {})
  end
end

vim.api.nvim_create_autocmd('ColorScheme', { callback = mute_spell_highlights })

-- Automatic saving, like VS Code's files.autoSave with a short delay: the buffer
-- is written once typing has paused. Debounced, so a burst of keystrokes writes
-- once. Only real, modifiable, named file buffers are ever written.
local autosave_group = vim.api.nvim_create_augroup('autosave', { clear = true })
local autosave_timer = assert(vim.uv.new_timer())

vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'InsertLeave', 'FocusLost' }, {
  group = autosave_group,
  callback = function(args)
    local buf = args.buf
    autosave_timer:stop()
    autosave_timer:start(250, 0, vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local bo = vim.bo[buf]
      if bo.modified and bo.modifiable and bo.buftype == '' and vim.api.nvim_buf_get_name(buf) ~= '' then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd('silent! write')
        end)
      end
    end))
  end,
})

-- Plugins, managed by vim.pack, the package manager built into Neovim 0.12.
-- Plugins are cloned under ~/.local/share/nvim/site/pack/, outside this repo.
-- Update them all with :lua vim.pack.update()
vim.pack.add({
  { src = 'https://github.com/catppuccin/nvim' },
  { src = 'https://github.com/stevearc/aerial.nvim' },
  { src = 'https://github.com/ibhagwan/fzf-lua' },
  { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },
  { src = 'https://github.com/folke/zen-mode.nvim' },
  { src = 'https://github.com/folke/snacks.nvim' },
  { src = 'https://github.com/dhruvasagar/vim-table-mode' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' },
})

vim.cmd.colorscheme('catppuccin-mocha')

-- Document outline in a side panel. The markdown backend reads headings from
-- the treesitter tree, so no language server is involved.
require('aerial').setup({
  backends = { 'markdown', 'treesitter', 'lsp', 'man' },
  layout = { default_direction = 'right', width = 35 },
  -- Show every symbol kind rather than the code oriented default selection.
  filter_kind = false,
  show_guides = true,
  -- Forced, because the "auto" detection looks for an icon plugin rather than
  -- for the terminal font, and no icon plugin is installed here.
  nerd_font = true,
})

vim.keymap.set('n', '<leader>o', '<Cmd>AerialToggle<CR>', { desc = 'Toggle the outline panel' })

-- Fuzzy finding, backed by the fzf and rg binaries already on this machine.
-- This is how notes get opened and searched across the whole vault.
require('fzf-lua').setup({ 'default' })

vim.keymap.set('n', '<leader>f', '<Cmd>FzfLua files<CR>', { desc = 'Find files by name' })
vim.keymap.set('n', '<leader>g', '<Cmd>FzfLua live_grep<CR>', { desc = 'Search text in files' })
vim.keymap.set('n', '<leader>b', '<Cmd>FzfLua buffers<CR>', { desc = 'Switch buffer' })
vim.keymap.set('n', '<leader>r', '<Cmd>FzfLua oldfiles<CR>', { desc = 'Recently opened files' })
vim.keymap.set('n', '<leader>h', '<Cmd>FzfLua helptags<CR>', { desc = 'Search the help' })

-- The notes vault, reachable from anywhere, whatever the current directory is.
local vault = vim.fn.expand('~/dev/notes')

vim.keymap.set('n', '<leader>n', function()
  require('fzf-lua').files({ cwd = vault })
end, { desc = 'Find a note in the vault' })

vim.keymap.set('n', '<leader>N', function()
  require('fzf-lua').live_grep({ cwd = vault })
end, { desc = 'Search text in the vault' })

-- Richer markdown rendering: headings as banners, bullets, check boxes, aligned
-- tables and fenced code blocks. Relies on the conceal settings applied in
-- after/ftplugin/markdown.lua.
require('render-markdown').setup({})

-- Distraction free reading: a centred column of text, no signs, no numbers.
require('zen-mode').setup({
  window = { width = 80, options = { number = false, relativenumber = false, signcolumn = 'no' } },
})

vim.keymap.set('n', '<leader>z', '<Cmd>ZenMode<CR>', { desc = 'Toggle zen mode' })

-- Inline images, drawn straight in the terminal through the kitty graphics
-- protocol, which Ghostty speaks. Conversions go through the ImageMagick binary,
-- so there is no luarocks dependency to keep alive.
-- Only the image module of snacks is turned on, the rest stays inert.
require('snacks').setup({
  image = { enabled = true },
})

-- Markdown tables: columns kept aligned while typing, once the mode is on.
-- Off by default, since it changes how | and other keys behave.
vim.g.table_mode_corner = '|'

vim.keymap.set('n', '<leader>t', '<Cmd>TableModeToggle<CR>', { desc = 'Toggle table mode' })

-- Sticky scroll: the heading of the section being read stays pinned at the top
-- of the window once it has scrolled off. The markdown query matches sections,
-- so nested headings stack.
require('treesitter-context').setup({
  max_lines = 3,
  multiline_threshold = 1,
  trim_scope = 'outer',
})

vim.keymap.set('n', '<leader>c', '<Cmd>TSContext toggle<CR>', { desc = 'Toggle sticky headings' })
vim.keymap.set('n', '<leader>w', '<Cmd>setlocal wrap!<CR>', { desc = 'Toggle soft wrapping' })
