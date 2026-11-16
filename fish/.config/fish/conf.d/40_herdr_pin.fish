# After a Herdr core restart, kept terminals get a fresh shell with the same
# address. If a command was pinned to this terminal (see scripts/herdr-pin.sh),
# rerun it.
status is-interactive; or return
test -n "$HC_TERMINAL_ID"; or return
set -l state (set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo $HOME/.local/state)/herdr-pin
test -f $state/$HC_TERMINAL_ID; or return
~/dotfiles/scripts/herdr-pin.sh --restore
