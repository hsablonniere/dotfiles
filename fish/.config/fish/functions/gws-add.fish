function gws-add --description "Add a new gws account" --argument-names name
    if test -z "$name"
        echo "Usage: gws-add <name> [auth-flags...]" >&2
        return 1
    end

    set -l target ~/.config/gws-accounts/$name
    if test -e $target
        echo "Account '$name' already exists" >&2
        return 1
    end

    mkdir -p $target

    set -l existing_secret (ls ~/.config/gws-accounts/*/client_secret.json 2>/dev/null | head -n 1)
    test -n "$existing_secret"; and cp $existing_secret $target/client_secret.json

    ln -sfn $target ~/.config/gws
    gws auth login $argv[2..]
end
