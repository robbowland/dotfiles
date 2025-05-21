#!/bin/fish

######################################
# Use bat to show zsh alias files.
######################################
function bat_fish_aliases
    for alias_file in $HOME/.config/*/fish/*.fish
        set file_output (bat --force-colorization --style=plain $alias_file)
        printf "%s\n" $file_output
    end
end
