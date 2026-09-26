function nn --description 'Launch the in-progress dotfiles nvim config (isolated from kickstart.nvim)'
    env \
        XDG_CONFIG_HOME=$HOME/dotfiles/nvim/.config \
        XDG_DATA_HOME=$HOME/.local/share/nvim-nn \
        XDG_STATE_HOME=$HOME/.local/state/nvim-nn \
        XDG_CACHE_HOME=$HOME/.cache/nvim-nn \
        nvim $argv
end
