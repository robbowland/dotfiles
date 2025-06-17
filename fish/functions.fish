#!/usr/bin/env fish

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

######################################
# Load custom vi-mode bindings
######################################
function fish_user_keybindings
    # Ensure Vi-mode is active without clearing defaults
    fish_vi_key_bindings --no-erase

    # i-mode: map jk to escape (exit insert)
    bind -M insert jk "if commandline -P; commandline -f cancel; else; set fish_bind_mode default; commandline -f backward-char force-repaint; end"

    # Normal mode H and L to beginning/end of line
    bind -M default H beginning-of-line
    bind -M default L end-of-line
    bind -M visual H beginning-of-line
    bind -M visual L end-of-line

    # Move visual block 3 lines
    bind -M visual J 'commandline -f beginning-of-history; commandline -A ";m \'>+3"; repaint'
    bind -M visual K 'commandline -f beginning-of-history; commandline -A ";m \'<-3"; repaint'
end
