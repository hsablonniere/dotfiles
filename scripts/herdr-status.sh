#!/usr/bin/env bash
# Compute the prompt info Starship would show (git, node, last status, duration, sudo,
# 1Password) and write it as JSON for the Herdr pane status bar mod (my-pane-status).
#
# Usage: herdr-status.sh <terminal-id> <cwd> <last-status> <last-duration-ms>
#        herdr-status.sh --info <cwd>  (prints {dir, readonly, git} only, used by claude/.claude/statusline.js)
# Output: $XDG_RUNTIME_DIR/herdr-status/<terminal-id>.json (written atomically)
# Called in the background by fish/.config/fish/conf.d/50_herdr_status.fish.
set -u

# git: branch, 8 char hash and per-kind counts (same kinds as starship's git_status).
# Runs in the current directory, sets GIT_JSON (null outside a repo).
git_info() {
GIT_JSON=null
if out=$(git --no-optional-locks -c core.fsmonitor=false status --porcelain=v2 --branch 2>/dev/null); then
  IFS=$'\x1f' read -r branch hash counts < <(awk '
    /^# branch.oid /  { hash = ($3 == "(initial)") ? "" : substr($3, 1, 8) }
    /^# branch.head / { branch = $3 }
    /^# branch.ab /   { ahead = substr($3, 2) + 0; behind = substr($4, 2) + 0 }
    /^\? /            { untracked++ }
    /^u /             { conflicted++ }
    /^[12] /          {
      x = substr($2, 1, 1); y = substr($2, 2, 1)
      if ($1 == "2") renamed++
      if (x != ".") staged++
      if (y == "M") modified++
      if (x == "D" || y == "D") deleted++
    }
    END {
      printf "%s\x1f%s\x1f%d %d %d %d %d %d %d %d\n", branch, hash, conflicted, deleted, renamed, modified, staged, untracked, ahead, behind
    }' <<<"$out")
  read -r c d r m s u a b <<<"$counts"
  GIT_JSON=$(jq -n --arg branch "$branch" --arg hash "$hash" \
    --argjson conflicted "$c" --argjson deleted "$d" --argjson renamed "$r" --argjson modified "$m" \
    --argjson staged "$s" --argjson untracked "$u" --argjson ahead "$a" --argjson behind "$b" \
    '{branch: $branch, hash: $hash, conflicted: $conflicted, deleted: $deleted, renamed: $renamed,
      modified: $modified, staged: $staged, untracked: $untracked, ahead: $ahead, behind: $behind}')
fi
}

# Directory as starship's directory module shows it: truncated to the repo root (repo name
# first), ~ for home, last 3 components at most; plus whether it is read only.
dir_info() {
  local path root text
  DIR_RO=false
  [ -w "$1" ] || DIR_RO=true
  path=$(cd "$1" 2>/dev/null && pwd -P) || path=$1
  if root=$(git -C "$path" rev-parse --show-toplevel 2>/dev/null) && [ -n "${root##*/}" ]; then
    text="${root##*/}${path#"$root"}"
  elif [ "$path" = "$HOME" ]; then
    text="~"
  elif [[ $path == "$HOME"/* ]]; then
    text="~${path#"$HOME"}"
  else
    text=$path
  fi
  local -a parts
  IFS=/ read -ra parts <<<"${text#/}"
  if [ "${#parts[@]}" -gt 3 ]; then
    text=$(IFS=/; printf %s "${parts[*]: -3}")
  fi
  DIR_TEXT=$text
}

if [ "${1:-}" = "--info" ]; then
  cd "${2:?cwd}" 2>/dev/null || exit 0
  dir_info "$PWD"
  git_info
  jq -nc --arg dir "$DIR_TEXT" --argjson readonly "$DIR_RO" --argjson git "$GIT_JSON" '{dir: $dir, readonly: $readonly, git: $git}'
  exit 0
fi

term=${1:?terminal id}
cwd=${2:?cwd}
code=${3:-0}
ms=${4:-0}
dir="${XDG_RUNTIME_DIR:-/tmp}/herdr-status"

mkdir -p "$dir"
cd "$cwd" 2>/dev/null || exit 0
dir_info "$cwd"

git_info

# node version through mise, only where starship's custom.nodejs would show it
node=""
if [ -e package.json ] || [ -e .mise.toml ] || [ -e .tool-versions ]; then
  node=$(timeout 2 mise current node 2>/dev/null)
fi

# non zero status, with the signal name above 128
signal=""
if [ "$code" -gt 128 ] 2>/dev/null; then
  signal=$(kill -l $((code - 128)) 2>/dev/null)
fi

# duration: only from 2s, like starship's cmd_duration
duration=""
if [ "$ms" -ge 2000 ] 2>/dev/null; then
  t=$((ms / 1000))
  h=$((t / 3600)); mi=$((t % 3600 / 60)); sec=$((t % 60))
  [ "$h" -gt 0 ] && duration="${h}h"
  [ "$h" -gt 0 ] || [ "$mi" -gt 0 ] && duration="${duration}${mi}m"
  duration="${duration}${sec}s"
fi

# sudo credentials cached (same check as starship's sudo module)
sudo_on=false
timeout 1 sudo -n true >/dev/null 2>&1 && sudo_on=true

# 1Password flag file refreshed by fish/.config/fish/conf.d/30_prompt_starship.fish
op_on=false
[ -e "${XDG_RUNTIME_DIR:-/tmp}/op-signed-in" ] && op_on=true

tmp="$dir/.$term.$$"
jq -n --arg cwd "$cwd" --arg dir "$DIR_TEXT" --argjson readonly "$DIR_RO" --argjson git "$GIT_JSON" --arg node "$node" \
  --argjson code "$code" --arg signal "$signal" --arg duration "$duration" \
  --argjson sudo "$sudo_on" --argjson op "$op_on" \
  '{cwd: $cwd, dir: $dir, readonly: $readonly, git: $git, node: $node, code: $code, signal: $signal, duration: $duration, sudo: $sudo, op: $op}' \
  >"$tmp" && mv -f "$tmp" "$dir/$term.json"
