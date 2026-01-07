if status is-interactive
    # Suppress fish greeting
    set -g fish_greeting

    # Initialize starship prompt
    starship init fish | source

    # Configure transient prompt to use same arrow
    function starship_transient_prompt_func
        starship module character
    end

    # Enable transient prompt
    enable_transience
end
