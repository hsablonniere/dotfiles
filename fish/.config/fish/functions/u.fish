function u --description "Update system (yay) and mise tools"
    echo "==> Updating system packages (yay)..."
    yay -Syu --noconfirm

    echo ""
    echo "==> Updating mise tools..."
    mise -C ~ upgrade
end
