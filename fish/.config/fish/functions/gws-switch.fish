function gws-switch --description "Switch active gws account"
    set -l accounts_dir ~/.config/gws-accounts
    set -l active_link ~/.config/gws

    set -l current ""
    test -L $active_link; and set current (basename (readlink $active_link))

    set -l rows
    for dir in $accounts_dir/*/
        set -l name (basename $dir)
        set -l email (GOOGLE_WORKSPACE_CLI_CONFIG_DIR=$dir gws auth status 2>/dev/null \
            | sed -n '/^{/,$p' | jq -r '.user // "?"')
        set -l mark "  "
        test "$name" = "$current"; and set mark "* "
        set -a rows "$mark$name"\t"$email"
    end

    if test (count $rows) -eq 0
        echo "No accounts found in $accounts_dir" >&2
        return 1
    end

    set -l pick (printf '%s\n' $rows | column -t -s \t \
        | fzf --prompt="gws account> " --header="* = current")
    or return 1

    set -l chosen (echo $pick | awk '{print $2}')
    ln -sfn $accounts_dir/$chosen $active_link
    echo "→ $chosen"
end
