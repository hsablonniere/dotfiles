if status is-interactive
    # Suppress fish greeting
    set -g fish_greeting

    # Initialize starship prompt
    starship init fish | source

    # Enable transient prompt
    enable_transience

    # Status bar: the starship `statusbar` profile is drawn on the last terminal row,
    # kept out of scrolling with a scroll region (DECSTBM), so the prompt is only the arrow.
    # `statusbar off` falls back to a two-line prompt.
    set -q statusbar_enabled; or set -g statusbar_enabled 1

    # Last starship arguments, kept so the bar can be redrawn outside fish_prompt (ctrl-l)
    set -g __statusbar_args

    function __statusbar_render
        starship prompt --profile statusbar --terminal-width="$COLUMNS" $__statusbar_args
    end

    function __statusbar_sequence
        set -l bar (__statusbar_render | string collect)
        set -l rows (math $LINES - 1)
        # \e7/\e8 save/restore the cursor around DECSTBM, which homes it.
        # Reset the region, then IND + RI make sure the cursor is not on the last row
        # (scrolling once if it is) without changing its column.
        # Then reserve the last row and draw the bar there with autowrap disabled.
        printf '\e7\e[r\e8\eD\eM\e7\e[1;%dr\e[%d;1H\e[?7l\e[2K%s\e[0m\e[?7h\e8' $rows $LINES "$bar"
    end

    function __statusbar_draw
        test "$statusbar_enabled" = 1; or return
        __statusbar_sequence >/dev/tty
    end

    function __statusbar_clear
        printf '\e7\e[r\e[%d;1H\e[2K\e8' $LINES >/dev/tty
    end

    function __statusbar_clear_on_exit --on-event fish_exit
        test "$statusbar_enabled" = 1; and __statusbar_clear
    end

    # clear-screen wipes the last row too
    bind ctrl-l clear-screen __statusbar_draw

    # fish repaints after a resize and wipes the bar, so draw it again a bit later
    function __statusbar_on_resize --on-signal WINCH
        test "$statusbar_enabled" = 1; or return
        command sh -c 'sleep 0.1; printf %s "$1" >/dev/tty' sh (__statusbar_sequence | string collect) &
        disown
    end

    function statusbar --description 'Toggle the bottom status bar (on/off)'
        switch "$argv[1]"
            case on
                set -g statusbar_enabled 1
            case off
                set -g statusbar_enabled 0
                __statusbar_clear
            case '*'
                echo "usage: statusbar on|off" >&2
                return 1
        end
    end

    # Replace starship's fish_prompt to draw the bar and print only the arrow
    function fish_prompt
        switch "$fish_key_bindings"
            case fish_hybrid_key_bindings fish_vi_key_bindings fish_helix_key_bindings
                set STARSHIP_KEYMAP "$fish_bind_mode"
            case '*'
                set STARSHIP_KEYMAP insert
        end
        set STARSHIP_CMD_PIPESTATUS $pipestatus
        set STARSHIP_CMD_STATUS $status
        set STARSHIP_DURATION "$CMD_DURATION$cmd_duration"
        __starship_set_job_count
        set -g __statusbar_args --status=$STARSHIP_CMD_STATUS --pipestatus="$STARSHIP_CMD_PIPESTATUS" --keymap=$STARSHIP_KEYMAP --cmd-duration=$STARSHIP_DURATION --jobs=$STARSHIP_JOBS

        if test "$statusbar_enabled" = 1
            contains -- --final-rendering $argv; or __statusbar_draw
        else if not contains -- --final-rendering $argv
            __statusbar_render
            echo
        end
        starship module character
    end

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
