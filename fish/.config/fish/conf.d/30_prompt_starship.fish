if status is-interactive
    # Suppress fish greeting
    set -g fish_greeting

    # Initialize starship prompt
    starship init fish | source

    # Configure transient prompt to use same arrow
    function starship_transient_prompt_func
        starship module character
    end

    # Enable transient prompt
    enable_transience

    # `op whoami` takes ~1s when signed out, so refresh a flag file in the background
    # and let starship only test for it (state lags one prompt behind)
    function __op_signed_in_check
        op whoami >/dev/null 2>&1
        and touch $XDG_RUNTIME_DIR/op-signed-in
        or rm -f $XDG_RUNTIME_DIR/op-signed-in
    end

    function __op_signed_in_refresh --on-event fish_prompt
        command sh -c 'op whoami >/dev/null 2>&1 && touch "$1" || rm -f "$1"' sh $XDG_RUNTIME_DIR/op-signed-in &
        disown
    end

    # After an `op` command, check synchronously so the very next prompt is accurate
    function __op_signed_in_postexec --on-event fish_postexec
        string match -qr '^\s*(eval\s*\(\s*)?op\b' -- $argv[1]
        and __op_signed_in_check
    end
end
