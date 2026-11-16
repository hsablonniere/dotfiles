# Feed the Herdr pane status bar (mod my-pane-status): at every prompt, compute the
# Starship-like info in the background (scripts/herdr-status.sh) and write it where the mod
# watches. Last status and duration are kept from fish_postexec and consumed by the next prompt.
status is-interactive; or return
test -n "$HC_TERMINAL_ID"; or return

set -g __herdr_status_code 0
set -g __herdr_status_ms 0

function __herdr_status_postexec --on-event fish_postexec
    set -g __herdr_status_code $status
    set -g __herdr_status_ms $CMD_DURATION
end

function __herdr_status_prompt --on-event fish_prompt
    command ~/dotfiles/scripts/herdr-status.sh $HC_TERMINAL_ID $PWD $__herdr_status_code $__herdr_status_ms &
    disown
    set -g __herdr_status_code 0
    set -g __herdr_status_ms 0
end

function __herdr_status_exit --on-event fish_exit
    rm -f (set -q XDG_RUNTIME_DIR; and echo $XDG_RUNTIME_DIR; or echo /tmp)/herdr-status/$HC_TERMINAL_ID.json
end
