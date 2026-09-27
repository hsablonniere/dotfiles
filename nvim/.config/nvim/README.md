# Neovim config

My Neovim configuration, written from scratch for Neovim 0.12. It aims to stay small and
readable, with habits carried over from WebStorm.

## Structure

- `init.lua` - Entry point, loads the modules in order
- `lua/config/` - One module per topic (options, picker, LSP, completion, statusline...)
- `snippets/` - My own snippets, in VS Code format
- `docs/cheatsheet.md` - Keymaps and habits, especially the ones replacing WebStorm
- `docs/snippets.md` - Reference of the ready-made snippets
- `TODO.md` - Ideas for the config

## Plugins

Plugins are managed with `vim.pack`, the package manager built into Neovim 0.12. They are cloned
outside this repository, under `~/.local/share/nvim/site/pack/`, so a fresh install needs a first
`nvim` run. Their versions are pinned in `nvim-pack-lock.json`.

Update them with `:lua vim.pack.update()`.

Language servers, formatters and linters are installed automatically by mason on startup
(`:Mason` to see them), except `rust-analyzer` (`rustup component add rust-analyzer`).
