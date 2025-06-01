#!/bin/fish

######################################
# Reload fish configuration.
######################################
function reload_fish_config
    source ~/.config/fish/config.fish
end

######################################
# Moves prompt to bottom of the terminal window,
# clearing lines above the prompt if existing.
######################################
function prompt_to_bottom
    set term_lines (tput lines)
    set lines_to_clear (math "max($term_lines, 50)")
    for i in (seq $lines_to_clear)
        echo
    end
end
