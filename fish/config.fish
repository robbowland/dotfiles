fish_add_path "/opt/homebrew/bin/"
fish_add_path "$HOME/.config"

export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml

# Greeting begone
set fish_greeting

# Vim stuff
fish_vi_key_bindings
# Set the cursor shape for different modes
set -U fish_cursor_default block        # Normal mode
set -U fish_cursor_insert line          # Insert mode
set -U fish_cursor_replace underscore   # Replace mode
set -U fish_cursor_visual block         # Visual mode
fish_vi_cursor

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Colour theme
# Define reusable colors (from GitHub Dark theme)
set -l foreground c9d1d9   # Light gray (default text)
set -l blue 58a6ff        # Primary blue (commands)
set -l cyan 79c0ff        # Cyan-like light blue (parameters, variables)
set -l green 3fb950       # Success green (end-of-command)
set -l red f85149         # Error red (errors, redirections)
set -l orange ffa657      # Orange (escapes, constants)
set -l yellow d29922      # Yellow (status, warnings)
set -l purple bc8cff      # Purple (quoted text)
set -l gray 8b949e        # Dim gray (comments, hostname)
set -l dimgray 484f58     # Autosuggestions
set -l darkgreen 238636   # Selection background
set -l darkred 442626     # Search match background
set -l white f0f6fc

# Set fish shell colors using the defined variables
set -g fish_color_normal "$foreground"
set -g fish_color_command "$purple"
set -g fish_color_quote "$cyan"
set -g fish_color_redirection "$red"
set -g fish_color_end "$green"
set -g fish_color_error "$red"
set -g fish_color_param "$white"
set -g fish_color_comment "$gray"
set -g fish_color_operator "$red"
set -g fish_color_escape "$orange"
set -g fish_color_cyan "$cyan"
set -g fish_color_selection --background="$darkgreen"
set -g fish_color_search_match --background="$darkred" --underline
set -g fish_color_status "$yellow"

# Autosuggestions and prompt colors
set -g fish_color_autosuggestion "$dimgray"

# Pager colors (command completions)
set -g fish_pager_color_progress "$cyan"
set -g fish_pager_color_prefix "$red" --bold
set -g fish_pager_color_completion "$foreground"
set -g fish_pager_color_description "$gray"

# TODO(robbow): Move these to ansible eventually
# <---------------- Exports ------------------
# --- Colour Palette
# TODO(robbow): Check that these match the  colours I'm using elsewhere
export PALETTE_GITHUB_DARK_BLUE="#58a6ff"
export PALETTE_GITHUB_DARK_GREEN="#3fb950"
export PALETTE_GITHUB_DARK_YELLOW="#d29922"
export PALETTE_GITHUB_DARK_ORANGE="#db6d28"
export PALETTE_GITHUB_DARK_RED="#f85149"
export PALETTE_GITHUB_DARK_PURPLE="#bc8cff"
export PALETT_GITHUB_DARKE_PINK="#ff7b72"
# >---------------- Exports ------------------

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

prompt_to_bottom
