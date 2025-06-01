######################################
# Add SSH keys to the Apple Keychain,
# ensuring passwords only need to be input once.
######################################
function __add_ssh_keys_to_keychain --on-event fish_prompt
    # Only run once
    functions -e __add_ssh_keys_to_keychain

    # Skip if keys already added
    ssh-add -l >/dev/null 2>&1
    or ssh-add --apple-use-keychain 2>/dev/null &
end
