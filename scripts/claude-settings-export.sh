#!/usr/bin/env bash
# Export ~/.claude/settings.json (the real file, not tracked) to the public copy
# in this repo, without private top-level keys.
set -euo pipefail

# Top-level keys that must never be published.
private_keys='["autoMode"]'

src="$HOME/.claude/settings.json"
dest="$(cd "$(dirname "$0")/.." && pwd)/claude/.claude/settings.json"

if [ -L "$src" ]; then
  echo "error: $src is a symlink, it must be a real file (see README.md)" >&2
  exit 1
fi

tmp="$(mktemp)"
jq -S --argjson keys "$private_keys" 'delpaths($keys | map([.]))' "$src" > "$tmp"
mv "$tmp" "$dest"
