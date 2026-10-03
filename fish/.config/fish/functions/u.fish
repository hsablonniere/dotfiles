function u --description "Update system (yay), mise tools, flatpaks"
    __u_step "Updating system packages (yay)"
    yay -Syu --noconfirm; or return

    __u_step "Updating mise tools"
    mise -C ~ upgrade

    __u_step "Updating flatpaks"
    flatpak update -y
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
