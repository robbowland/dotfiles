fish_add_path /opt/homebrew/bin/
fish_add_path "$HOME/.config"
fish_add_path /opt/homebrew/opt/llvm/bin

export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml

# Greeting begone
set fish_greeting

# Vim stuff
fish_vi_key_bindings
# Set the cursor shape for different modes
set -U fish_cursor_default block # Normal mode
set -U fish_cursor_insert line # Insert mode
set -U fish_cursor_replace underscore # Replace mode
set -U fish_cursor_visual block # Visual mode
fish_vi_cursor

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Colour theme
source "$HOME/.config/micrographics/activate.fish"

# <------------------ Inits ------------------
for script in $HOME/.config/*/fish/init.fish
    if test -r $script
        source $script
    end
end
# >------------------ Inits ------------------

# Source fish files from main and nested config dirs
for file in $HOME/.config/{,*/}fish/{aliases,functions,exports}.fish
    if test -r $file
        source $file
    end
end

if status --is-interactive
    fish_user_keybindings
    prompt_to_bottom
end
