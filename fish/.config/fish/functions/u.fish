function u --description "Update all packages (yay, cargo, go)"
    echo "==> Updating system packages (yay)..."
    yay -Syu --noconfirm

    echo ""
    echo "==> Updating cargo packages..."
    cargo install --list | grep -E '^\w' | cut -d' ' -f1 | xargs -r cargo install

    echo ""
    echo "==> Updating go packages..."
    gup update
end
