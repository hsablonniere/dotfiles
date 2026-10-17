if status is-interactive
    # Suppress fish greeting
    set -g fish_greeting

    # Powerline separators: starship cannot know which optional segment comes next, so the
    # format only emits a bare \ue0b0 after each segment and this wrapper colours it with the
    # background of the segment before (fg) and after (bg). The last one becomes a rounded \ue0b4
    function __starship_powerline
        set -l out (command starship $argv | string collect)
        set -l tokens (string match -ra \ue0b0'|(?<=\e\[|;)48;2;\d+;\d+;\d+' -- $out)
        set -l prev
        for i in (seq (count $tokens))
            if test "$tokens[$i]" != \ue0b0
                set prev (string replace -r '^48' 38 -- $tokens[$i])
                continue
            end
            set -l sep \e\[{$prev}m
            # \x02 marks the rounded end, used when no segment follows
            set -l glyph \x02
            set -l j (math $i + 1)
            if test $j -le (count $tokens); and test "$tokens[$j]" != \ue0b0
                set sep $sep\e\[{$tokens[$j]}m
                set glyph \x01
            end
            # \x01/\x02 stand in for the glyph so the next replace targets the next bare one
            set out (string replace -- \ue0b0 $sep$glyph\e\[0m $out | string collect)
        end
        printf %s (string replace -a -- \x01 \ue0b0 $out | string replace -a -- \x02 \ue0b4 | string collect)
    end

    # Initialize starship prompt, routed through the wrapper above
    starship init fish --print-full-init | string replace -r '\S*starship prompt ' '__starship_powerline prompt ' | source

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
