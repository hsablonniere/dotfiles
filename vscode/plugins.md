# VS Code extensions

VS Code was removed from the machine on 2026-10-03. This file keeps the list of extensions that were installed, in case it comes back.

## Extensions

| Extension | Version | Purpose |
|-----------|---------|---------|
| `anthropic.claude-code` | 2.0.50 | Claude Code IDE integration |
| `be5invis.toml` | 0.6.0 | TOML syntax support |
| `davidanson.vscode-markdownlint` | 0.62.1 | Markdown linting (rules in `.markdownlintrc.json`) |
| `gera2ld.markmap-vscode` | 0.2.12 | Markdown to mind map |
| `github.github-vscode-theme` | 6.3.5 | GitHub theme |
| `nmsmith89.incrementor` | 1.0.3 | Increment numbers across multiple cursors |
| `shd101wyy.markdown-preview-enhanced` | 0.8.35 | Enhanced Markdown preview |
| `streetsidesoftware.code-spell-checker` | 4.9.3 | Spell checker |
| `streetsidesoftware.code-spell-checker-french` | 0.4.4 | French dictionary for the spell checker |
| `tyriar.sort-lines` | 1.12.0 | Sort lines |
| `wmaurer.change-case` | 1.0.0 | Change identifier case |
| `yzhang.markdown-all-in-one` | 3.6.3 | Markdown editing helpers |

## Reinstall

```bash
for id in \
  anthropic.claude-code \
  be5invis.toml \
  davidanson.vscode-markdownlint \
  gera2ld.markmap-vscode \
  github.github-vscode-theme \
  nmsmith89.incrementor \
  shd101wyy.markdown-preview-enhanced \
  streetsidesoftware.code-spell-checker \
  streetsidesoftware.code-spell-checker-french \
  tyriar.sort-lines \
  wmaurer.change-case \
  yzhang.markdown-all-in-one
do
  code --install-extension "$id"
done
```

## Settings, keybindings and markdownlint rules

They are in the git history of this repository, in the `vscode/` folder, before the commit that removed it:

```bash
git log --diff-filter=D --oneline -- vscode
git show <commit>^:vscode/.config/Code/User/settings.json
git show <commit>^:vscode/.config/Code/User/keybindings.json
git show <commit>^:vscode/.markdownlintrc.json
```

Restore them with `stow vscode` after checking out the `vscode/` folder from that commit.
