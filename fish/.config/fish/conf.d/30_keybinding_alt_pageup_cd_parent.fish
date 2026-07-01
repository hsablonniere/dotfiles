if status is-interactive
    # Alt+PageUp: cd to parent directory
    function _cd_parent_dir
        cd ..
        commandline -f repaint
    end

    bind alt-pageup _cd_parent_dir
end
