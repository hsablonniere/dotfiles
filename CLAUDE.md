# Dotfiles project instructions

This repository is managed via GNU Stow (see README.md). Every config file lives under a
tool directory here (e.g. `fish/.config/fish/functions/`) and is symlinked into `~` by stow.

## Rule: never write directly under `~/.config` (or any other stowed target)

- Always create/edit files inside this repo, in the matching tool directory
  (e.g. new fish function → `fish/.config/fish/functions/<name>.fish`).
- After writing, propose running `stow -R <tool>` (or `stow <tool>` for a new file) from
  the dotfiles root to (re)create the symlink. Do not run stow without confirmation.
- Before creating a new config file, check whether a real file already exists at the
  target path outside this repo (not a symlink) — that's likely untracked user config,
  not something to overwrite silently.
- Some files are intentionally kept outside this repo for privacy (e.g.
  `~/.config/fish/conf.d/private_config.fish`, private fish functions, `~/.gitconfig_private`).
  Don't migrate these into the repo unless explicitly asked.
