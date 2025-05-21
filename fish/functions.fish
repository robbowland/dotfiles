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
    for i in (seq (tput lines))
        echo
    end
end

######################################
# Add SSH keys to the Apple Keychain,
# ensuring passwords only need to be input once.
######################################
function add_ssh_keys_to_keychain
    ssh-add --apple-use-keychain 2>/dev/null
end
