#!/bin/sh
# SessionStart hook: tell herdr-pin.sh which session to resume if this terminal
# is pinned (see scripts/herdr-pin.sh). Does nothing outside a pinned terminal.
[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
id="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null)"
[ -n "$id" ] || exit 0
exec "$HOME/dotfiles/scripts/herdr-pin.sh" --set claude --resume "$id"
