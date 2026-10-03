function u --description "Update all packages (yay, go)"
    echo "==> Updating system packages (yay)..."
    yay -Syu --noconfirm

    echo ""
    echo "==> Updating go packages..."
    gup update
end
