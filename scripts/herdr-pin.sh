#!/usr/bin/env bash
# Pin a command to the current Herdr terminal so that it comes back after a
# core restart or a reboot.
#
# The core gives a kept terminal a fresh shell after a restart but never reruns
# its command. This script records what to rerun in
# ~/.local/state/herdr-pin/<HC_TERMINAL_ID> and removes it when the command
# returns normally. A core stop or a reboot kills this script before it can
# remove the record, so the shell recreated by the core finds it and restores it.
#
# Usage:
#   herdr-pin.sh <command...>     run a command, pinned to this terminal
#   herdr-pin.sh --set <command...>
#                                 replace what a pinned terminal will rerun (used by
#                                 agent hooks to store "claude --resume <id>"). Does
#                                 nothing if the terminal is not pinned.
#   herdr-pin.sh --restore        rerun the pinned command, if any (used by fish at startup)
#
# Record format: line 1 is the folder, then the argv to rerun one item per line,
# then a "--" line, then the original argv one item per line. The original argv
# is the fallback when a resume command fails right away (e.g. an empty session).
# Arguments containing newlines are not supported.

set -u

state="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-pin"
tid="${HC_TERMINAL_ID:-}"
file="$state/$tid"
cwd=
resume=()
orig=()

write_record() {
  mkdir -p "$state" || return 1
  {
    printf '%s\n' "$cwd"
    printf '%s\n' "${resume[@]}"
    echo --
    printf '%s\n' "${orig[@]}"
  } > "$file.tmp" && mv "$file.tmp" "$file"
}

read_record() {
  local lines line section=1
  mapfile -t lines < "$file" || return 1
  cwd="${lines[0]}"
  resume=()
  orig=()
  for line in "${lines[@]:1}"; do
    if [ "$section" = 1 ] && [ "$line" = -- ]; then
      section=2
    elif [ "$section" = 1 ]; then
      resume+=("$line")
    else
      orig+=("$line")
    fi
  done
}

# Run "${resume[@]}" with the record in place, then forget the record.
run_pinned() {
  local status start="$SECONDS"
  write_record
  "${resume[@]}"
  status=$?
  # A resume command that fails right away (nothing to resume) falls back to the original command.
  if [ "$status" -ne 0 ] && [ "$((SECONDS - start))" -lt 10 ] && [ "${resume[*]}" != "${orig[*]}" ]; then
    resume=("${orig[@]}")
    write_record
    "${resume[@]}"
    status=$?
  fi
  rm -f "$file"
  exit "$status"
}

case "${1:-}" in
  --set)
    shift
    [ -n "$tid" ] && [ -f "$file" ] && [ "$#" -gt 0 ] || exit 0
    read_record || exit 0
    resume=("$@")
    write_record
    ;;
  --restore)
    [ -n "$tid" ] && [ -f "$file" ] || exit 0
    read_record || exit 0
    rm -f "$file"
    [ "${#resume[@]}" -gt 0 ] || exit 0
    [ "${#orig[@]}" -gt 0 ] || orig=("${resume[@]}")
    cd "$cwd" 2>/dev/null || true
    run_pinned
    ;;
  "")
    echo "usage: herdr-pin.sh <command...> | --set <command...> | --restore" >&2
    exit 2
    ;;
  *)
    # Outside Herdr there is nothing to pin: just run the command.
    [ -n "$tid" ] || exec "$@"
    orig=("$@")
    resume=("$@")
    cwd="$PWD"
    run_pinned
    ;;
esac
