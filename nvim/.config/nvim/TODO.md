# Neovim config TODO

Ideas from a review of the config, grouped by theme. Priority: **high** items fill real gaps,
**medium** ones add useful features, **low** ones are comfort.

## Git

- [ ] **high** gitsigns keymaps (`git.lua`). The signs are only displayed today, every action
      needs gtui.
  - `]h` / `[h`: next / previous hunk
  - `Space g p`: preview the hunk under the cursor
  - `Space g s` / `Space g r`: stage / reset the hunk
  - `Space g b`: blame the line
  - `ih`: hunk text object (`dih`, `vih`)
- [ ] **medium** Snacks git pickers: `Space g l` (log), `Space g s` (changed files), for a quick
      look without opening gtui. Watch for a clash with the stage hunk keymap above.
- [ ] **medium** `Snacks.gitbrowse`: open the current file and line on GitHub / GitLab in Zen.
- [ ] **low** gtui float borrows the `NeoTreeFloatBorder` highlight: use a group of its own, so
      it keeps its color if neo-tree goes away.

## Editing

- [ ] **high** Highlight on yank: `vim.hl.on_yank()` on `TextYankPost`.
- [ ] **high** Restore the cursor position when opening a file outside a session (`nvim file`):
      `BufReadPost` autocmd jumping to the `'"` mark.
- [ ] **medium** Treesitter text objects beyond selection (plugin already installed):
  - move: `]f` / `[f` next / previous function, `]c` / `[c` class
  - swap: `Space a` / `Space A` swaps an argument with the next / previous one
- [ ] **low** `treesitter-context`: `[x` jumps to the start of the context shown at the top.
- [ ] **low** Insert mode `Ctrl+W` (delete previous word) is disabled with the window commands:
      check that `Ctrl+Backspace` covers it in Ghostty.

## Diagnostics and formatting

- [ ] **high** `virtual_lines = { current_line = true }`: full message of the diagnostic under the
      cursor below its line, short `virtual_text` elsewhere.
- [ ] **medium** Format automatically on `BufLeave` / `FocusLost`, with the same guards as today
      (only in projects with a formatter config). Autosave writes every second, so formatting on
      save stays off.

## Snacks

- [ ] **medium** More pickers:
  - `Space s w`: grep the word under the cursor
  - `Space s n`: notification history
  - `Space s u`: undo history with a diff preview, compare with the built-in undotree
- [ ] **medium** `Snacks.toggle` in the `Space t` group, ON/OFF state shown in which-key:
      diagnostics, spell, relative numbers, indent guides, inlay hints (move `Space t h`).
- [ ] **medium** `Snacks.image`: images in the picker preview and in Markdown (Ghostty supports
      the kitty graphics protocol).
- [ ] **low** `Snacks.scratch` (`Space .`): persistent scratch buffer per project.
- [ ] **low** `Snacks.zen`: distraction-free mode for writing and reading.

## Options

- [ ] **low** `vim.o.smoothscroll = true`: smooth scrolling through wrapped lines.
- [ ] **low** `vim.o.jumpoptions = 'stack,view'`: `Ctrl+O` behaves like a browser's back button
      and restores the view.
- [ ] **low** Spell checking in Markdown and git commits only: `spelllang = en,fr`, `]s` next
      mistake, `z=` suggestions.

## Outline

- [ ] **low** neo-tree stays for the outline only (`Space o`). `aerial.nvim` was tried and
      rejected. Moving the file explorer to `Snacks.explorer` only makes sense together with an
      outline replacement, to drop neo-tree, `nui.nvim` and `plenary.nvim`.
