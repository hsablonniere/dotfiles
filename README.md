# My Dotfiles

Welcome to my personal dotfiles repository!
This repository contains configuration files for various command-line tools and development environments that I use daily.
Each tool has its own directory with its configuration files organized following the standard `~/.config/` directory structure.

## Overview

This repository is organized as a collection of tool-specific directories, each containing configuration files that should be symlinked or copied to their respective locations in your home directory.

## Tools & Configurations

### [Atuin](https://github.com/atuinsh/atuin)

Atuin is a shell history search engine that syncs your shell history across machines.

**Config location:** `.config/atuin/config.toml`

### [Claude Code](https://docs.claude.com/en/docs/claude-code/overview)

Claude Code is Anthropic's official CLI tool for Claude.

**Config location:** `.claude/`

- `settings.json` - CLI settings and preferences
- `statusline.js` - Custom statusline configuration (caches the `rate_limits` quotas received from Claude Code)
- `claude-quota.js` - Reads the quota cache written by the statusline and prints it with its age (`--json` available)
- `hooks/` - Hook scripts (`speak.sh`: text-to-speech, toggled by `~/.local/state/speak-enabled`; `herdr-pin.sh`: `SessionStart` hook that tells `scripts/herdr-pin.sh` which session to resume)
- `output-styles/` - Custom output styles (`minimaliste.md`)

> **Note:** `~/.claude/settings.json` is a real file, not a symlink, because it holds private keys (e.g. `autoMode`).
> `claude/.claude/settings.json` is a public copy exported from it by `scripts/claude-settings-export.sh`, which strips those keys.
> Stow ignores it (see `claude/.stow-local-ignore`).
> On a new machine, copy it manually: `cp claude/.claude/settings.json ~/.claude/settings.json`.

### [Fish Shell](https://fishshell.com/)

Fish is a user-friendly shell with powerful command-line completions and syntax highlighting.

**Config location:** `.config/fish/`

**Structure:**

- `conf.d/` - Fish configuration files that are sourced automatically on shell startup
  - Includes keybindings for various shortcuts (e.g., `Alt+H`, `Alt+J`, `Alt+K`)
  - History configuration via Atuin integration
- `functions/` - Custom Fish functions (command shortcuts and utilities)
  - Git-related shortcuts (`ga`, `gabs`, `grbim`, `gfom`, etc.)
  - Utility functions (`c`, `cc`, `cert`, `copy`, `cr`, `ex` and many more)

**Update hooks:** `.config/update-hooks/`

The `u` function runs every executable in this directory in alphabetical order.
The title shown for each hook is its file name without the numeric prefix (`10-yay` shows "Updating yay").
A failing hook does not stop the others; `u` lists the failures at the end and returns 1.

- `10-yay` - System packages
- `20-mise` - mise tools
- `30-flatpak` - Flatpaks

> **Note:** Some configuration details are stored in `~/.config/fish/conf.d/private_config.fish` for privacy. Same for some private functions in `~/.config/fish/functions/*`.

### [Ghostty](https://ghostty.org/)

Ghostty is a cross-platform terminal emulator written in Zig.

**Config location:** `.config/ghostty/`

### [Git](https://git-scm.com/)

Git version control system configuration.

**Config location:** `.gitconfig` and `.gitignore_global`

> **Note:** Some configuration details are stored in `~/.gitconfig_private` for privacy.

### [Herdr](https://herdr.dev/)

Herdr is a desktop app for terminals and coding agents (spaces, tabs and splits), backed by `herdr-core` (`hc`), which keeps the terminals running when the window closes.

**Config location:** `.config/herdr-app/`

> **Note:** `~/.config/herdr-app/` also holds files Herdr writes itself (shipped layouts and mods, `AGENTS.md`, type definitions, icons) and private state (open spaces and tabs, mod storage), so stow links only my own files:

- `settings.json`: theme, font, zoom, sounds off, telemetry off
- `keys.json`: shortcuts, with the AZERTY digit row bound by keysym name (`alt-eacute`, `ctrl-agrave`)
- `themes/hsablonniere-dark.json`: my terminal colors, ported from Ghostty
- `layouts/tmux.json`: clone of the shipped `main` layout with bare panes and 1px split lines
- `mods/nav`: moves tabs left/right, jumps to the n-th main space (git worktrees skipped)
- `mods/my-spaces`, `mods/my-tabs`: clones of the shipped sidebar and tab bar, numbering spaces and tabs, folding worktrees

### [Neovim](https://neovim.io/)

A hyperextensible Vim-based text editor.

**Config location:** `.config/nvim/`

Written from scratch, with habits carried over from WebStorm. See its
[README](nvim/.config/nvim/README.md) for the structure and the
[cheatsheet](nvim/.config/nvim/docs/cheatsheet.md) for the keymaps.

### [Pi](https://pi.dev/)

Pi, a terminal coding agent.

**Config location:** `.pi/agent/`

- `settings.json` - Default provider, model and theme
- `extensions/statusline.ts` - Powerline status bar replacing the footer, inspired by the Claude Code one
- `extensions/herdr-pin.ts` - Tells `scripts/herdr-pin.sh` which session to resume

### [Starship](https://starship.rs/)

A cross-platform prompt that's fast, customizable, and showing the information you need.

**Config location:** `.config/starship.toml`

### [Yazi](https://github.com/sxyazi/yazi)

A blazing fast terminal file manager written in Rust.

**Config location:** `.config/yazi/`

- `yazi.toml` - General settings
- `keymap.toml` - Custom keybindings

## Scripts

`scripts/` holds helper scripts, not meant to be stowed:

- `claude-settings-export.sh` - Exports a public copy of `~/.claude/settings.json` without its private keys
- `herdr-pin.sh` - Pins a command to a Herdr terminal so that it comes back after a core restart or a reboot (see below)

### Herdr pin

After a restart, `herdr-core` gives a kept terminal a fresh shell and never reruns its command. `scripts/herdr-pin.sh` fills the gap, only for commands that ask for it:

- `hp <command>` (fish function) runs a command pinned to the terminal. `claude`, `pi` and `opencode` are fish functions that do it automatically; use `command claude` to skip it.
- The record lives in `~/.local/state/herdr-pin/<HC_TERMINAL_ID>` (folder, command to rerun, original command). It is removed when the command returns, so quitting on purpose never brings it back. A core stop or a reboot kills the script first, so the record stays.
- Agents replace the command with a resume one once their session exists (`claude --resume <id>`, `pi --session <id>`, `opencode --session <id>`) through a hook or extension. When resuming fails right away (empty session), the original command runs instead.
- `fish/.config/fish/conf.d/40_herdr_pin.fish` runs `herdr-pin.sh --restore` in the shell recreated by the core.
- Hooks to declare: `SessionStart` in `~/.claude/settings.json` (`~/.claude/hooks/herdr-pin.sh`), and for opencode the plugin `~/.config/opencode/plugins/herdr-pin.js` (stow does not link it, `~/.config/opencode/` also holds files managed by Herdr: `ln -s` it).

## Management via Stow

This repository uses [GNU Stow](https://www.gnu.org/software/stow/) to manage symlinks.
Stow is a package management tool that creates symlinks from a source directory to a target directory, making it easy to manage dotfiles across multiple tools.

It creates symlinks from files in each tool's directory to your home directory (`~`), preserving the directory structure.
For example:

- `fish/.config/fish/conf.d/` → `~/.config/fish/conf.d/`
- `git/.gitconfig` → `~/.gitconfig`
- `starship/.config/starship.toml` → `~/.config/starship.toml`

This means you can:

- Keep all configurations version-controlled in one place
- Easily update tools by pulling the latest from this repository
- Manage multiple tools with a single command
- Install/uninstall tools without manual cleanup
