fish_add_path /opt/homebrew/bin/
fish_add_path "$HOME/.config"

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

# -- Colours
source $HOME/.config/fish/palettes/github_dark.fish

# Define reusable colors (from GitHub Dark theme)
set -l darkgreen 238636 # Selection background
set -l darkred 442626 # Search match background

# Set fish shell colors using the defined variables
set -g fish_color_normal "$PALETTE_GRAY"
set -g fish_color_command "$PALETTE_MAGENTA"
set -g fish_color_quote "$PALETTE_CYAN"
set -g fish_color_redirection "$PALETTE_RED"
set -g fish_color_end "$PALETTE_GREEN"
set -g fish_color_error "$PALETTE_RED"
set -g fish_color_param "$PALETTE_WHITE"
set -g fish_color_comment "$PALETTE_GRAY"
set -g fish_color_operator "$PALETTE_RED"
set -g fish_color_escape "$PALETTE_ORANGE"
set -g fish_color_cyan "$PALETTE_CYAN"
set -g fish_color_status "$PALETTE_YELLOW"
# TODO(robbow): Figure out these two
set -g fish_color_selection --background="$darkgreen"
set -g fish_color_search_match --background="$darkred" --underline

# Autosuggestions and prompt colors
set -g fish_color_autosuggestion "$PALETTE_GRAY"

# Pager colors (command completions)
set -g fish_pager_color_progress "$PALETTE_CYAN"
set -g fish_pager_color_prefix "$PALETTE_RED" --bold
set -g fish_pager_color_completion "$PALETTE_GRAY"
set -g fish_pager_color_description "$PALETTE_GRAY"

# <------------------ Inits ------------------
fzf --fish | source
starship init fish | source
zoxide init fish | source
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
