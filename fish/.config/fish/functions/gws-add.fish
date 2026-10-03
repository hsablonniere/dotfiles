function gws-add --description "Add a new gws account" --argument-names name
    if test -z "$name"
        echo "Usage: gws-add <name> [auth-flags...]" >&2
        return 1
    end

    set -l accounts_dir ~/.config/gws-accounts
    set -l active_link ~/.config/gws

    set -l target $accounts_dir/$name
    if test -e $target
        echo "Account '$name' already exists" >&2
        return 1
    end

    # First run after `gws auth setup`: ~/.config/gws is a real directory, move it into accounts_dir
    if test -d $active_link; and not test -L $active_link
        set -l email (gws auth status 2>/dev/null | sed -n '/^{/,$p' | jq -r '.user // "?"')
        read -l -P "Name for the existing account ($email): " existing
        or return 1
        if test -z "$existing"; or test "$existing" = "$name"; or test -e $accounts_dir/$existing
            echo "Invalid account name '$existing'" >&2
            return 1
        end
        mkdir -p $accounts_dir
        mv $active_link $accounts_dir/$existing
        ln -s $accounts_dir/$existing $active_link
        echo "→ $existing (migrated from $active_link)"
    end

    mkdir -p $target

    set -l existing_secret (ls $accounts_dir/*/client_secret.json 2>/dev/null | head -n 1)
    test -n "$existing_secret"; and cp $existing_secret $target/client_secret.json

    ln -sfn $target $active_link
    gws auth login $argv[2..]
end
