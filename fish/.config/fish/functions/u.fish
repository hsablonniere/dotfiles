function u --description "Update system (yay), mise tools, flatpaks"
    echo "==> Updating system packages (yay)..."
    yay -Syu --noconfirm

    echo ""
    echo "==> Updating mise tools..."
    mise -C ~ upgrade

    echo ""
    echo "==> Updating flatpaks..."
    flatpak update -y
end
