-- [[ Completion ]]
-- blink.cmp: completion menu while typing, from LSP, file paths, snippets and words of the buffer.
-- The version range pulls a release tag, which comes with a prebuilt fuzzy matcher binary.
vim.pack.add({
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') },
  -- Ready-made VS Code snippets per language, picked up automatically by blink.cmp
  'https://github.com/rafamadriz/friendly-snippets',
})
require('blink.cmp').setup({
  -- Enter and Tab accept like VS Code/WebStorm. Tab jumps to the next snippet placeholder when
  -- the menu is closed. Ctrl+Space opens the menu, Ctrl+E closes it, Ctrl+N/P and arrows move.
  keymap = {
    preset = 'enter',
    ['<Tab>'] = { 'select_and_accept', 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
  },
  completion = {
    -- Menu only on Ctrl+Space, never while typing
    trigger = {
      show_on_keyword = false,
      show_on_trigger_character = false,
      show_on_insert_on_trigger_character = false,
      show_on_backspace_after_accept = false,
      show_on_backspace_after_insert_enter = false,
    },
    -- Documentation of the selected item next to the menu
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
    -- Preview of the selected item, in grey, inside the code
    ghost_text = { enabled = true },
  },
  -- Signature of the called function while typing its arguments
  signature = { enabled = true },
  -- TypeScript also gets the JavaScript snippets (friendly-snippets and mine), like in VS Code
  sources = {
    providers = {
      snippets = { opts = { extended_filetypes = { typescript = { 'javascript' } } } },
    },
  },
})
