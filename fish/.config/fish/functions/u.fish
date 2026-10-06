function u --description "Run the update hooks from ~/.config/update-hooks"
    set -l hooks_dir ~/.config/update-hooks
    set -l failed

    if not test -d $hooks_dir
        echo "No hooks directory: $hooks_dir" >&2
        return 1
    end

    for hook in $hooks_dir/*
        test -x $hook; or continue

        # Title is the file name without its numeric prefix (10-yay -> yay)
        set -l name (string replace -r '^\d+-' '' (path basename $hook))
        __u_step "Updating $name"

        $hook
        set -l hook_status $status

        # Ctrl+C in the middle of a hook stops everything
        if test $hook_status -eq 130
            return 130
        else if test $hook_status -ne 0
            set -a failed $name
        end
    end

    if set -q failed[1]
        echo ""
        set_color red
        echo "Failed: $failed"
        set_color normal
        return 1
    end
end

function __u_step --description "Print a highlighted section header for u"
    set -l width 80
    echo ""
    set_color yellow
    echo (string repeat -n $width "▄")
    set_color --background yellow black
    echo -n (string pad -r -w $width " $argv[1]")
    set_color normal
    echo ""
    set_color yellow
    echo (string repeat -n $width "▀")
    set_color normal
    echo ""
end
