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
- `statusline.js` - Custom statusline configuration

### [Fish Shell](https://fishshell.com/)

Fish is a user-friendly shell with powerful command-line completions and syntax highlighting.

**Config location:** `.config/fish/`

**Structure:**

- `conf.d/` - Fish configuration files that are sourced automatically on shell startup
  - Includes keybindings for various shortcuts (e.g., `Alt+H`, `Alt+J`, `Alt+K`)
  - History configuration via Atuin integration
- `functions/` - Custom Fish functions (54 custom command shortcuts and utilities)
  - Git-related shortcuts (`ga`, `gabs`, `grbim`, `gfom`, etc.)
  - Utility functions (`c`, `cc`, `cert`, `copy`, `cr`, `ex` and many more)

> **Note:** Some configuration details are stored in `~/.config/fish/conf.d/private_config.fish` for privacy. Same for some private functions in `~/.config/fish/functions/*`.

### [Ghostty](https://ghostty.org/)

Ghostty is a cross-platform terminal emulator written in Zig.

**Config location:** `.config/ghostty/`

### [Git](https://git-scm.com/)

Git version control system configuration.

**Config location:** `.gitconfig` and `.gitignore_global`

> **Note:** Some configuration details are stored in `~/.gitconfig_private` for privacy.

### [Lazydocker](https://github.com/jesseduffield/lazydocker)

A simple Docker terminal UI.

**Config location:** `.config/lazydocker/config.yml`

### [Lazygit](https://github.com/jesseduffield/lazygit)

A simple Git terminal UI for lazy developers.

**Config location:** `.config/lazygit/config.yml`

### [npm](https://www.npmjs.com/)

npm is the package manager for JavaScript.

**Config location:** `.npmrc`

- `ignore-scripts=true` - Disables automatic script execution for security

### [Starship](https://starship.rs/)

A cross-platform prompt that's fast, customizable, and showing the information you need.

**Config location:** `.config/starship.toml`

### [VS Code](https://code.visualstudio.com/)

Visual Studio Code editor configuration.

**Config location:** `.config/Code/User/`

- `settings.json` - Editor settings and preferences
- `keybindings.json` - Custom keyboard shortcuts
- `.markdownlintrc.json` - Markdown linting rules

### [Window Key Switcher](https://github.com/hsablonniere/window-key-switcher)

Custom tool for managing window management keybindings.

**Config location:** `.config/window-key-switcher/`

### [Yazi](https://github.com/sxyazi/yazi)

A blazing fast terminal file manager written in Rust.

**Config location:** `.config/yazi/yazi.toml`

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
