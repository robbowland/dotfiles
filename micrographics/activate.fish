#!/bin/fish

# Apply the default Micrographics suite to Fish and terminal tools.
set -gx MICROGRAPHICS_TERMINAL 1
set -gx COLORTERM truecolor

source "$HOME/.config/fish/palettes/micrographics.fish"

set -gx BAT_THEME Micrographics
set -gx DELTA_FEATURES micrographics
set -gx STARSHIP_CONFIG "$HOME/.config/starship/themes/micrographics.toml"
set -gx YAZI_CONFIG_HOME "$HOME/.config/yazi/profiles/micrographics"
set -gx ZELLIJ_CONFIG_FILE "$HOME/.config/zellij/profiles/micrographics.kdl"
set -gx GH_DASH_CONFIG "$HOME/.config/gh-dash/micrographics.yml"
set -gx POSTING_CONFIG_FILE "$HOME/.config/posting/profiles/micrographics.yaml"
set -gx SERIE_CONFIG_FILE "$HOME/.config/serie/micrographics.toml"

# Keep eza and LS_COLORS monochrome; the file kind remains legible by glyph/name.
set -gx EZA_COLORS 'di=1;38;2;255;255;255:ex=1;38;2;255;255;255:fi=38;2;255;255;255:ln=38;2;153;153;153:or=1;38;2;255;59;47:pi=38;2;153;153;153:so=38;2;153;153;153:bd=38;2;153;153;153:cd=38;2;153;153;153:ic=38;2;153;153;153:da=38;2;97;97;97:xx=38;2;97;97;97:hd=1;38;2;255;255;255:lp=38;2;97;97;97:ga=38;2;255;255;255:gm=38;2;153;153;153:gd=38;2;255;59;47:gv=38;2;153;153;153:gc=1;38;2;255;59;47'
set -gx LS_COLORS 'di=1;38;2;255;255;255:ex=1;38;2;255;255;255:fi=38;2;255;255;255:ln=38;2;153;153;153:or=1;38;2;255;59;47:pi=38;2;153;153;153:so=38;2;153;153;153:bd=38;2;153;153;153:cd=38;2;153;153;153'

source "$HOME/.config/fzf/fish/themes/micrographics.fish"

# Fish syntax follows the same code-reading hierarchy as bat and Neovim.
set -g fish_color_normal $MG_INK
set -g fish_color_command $MG_INK --bold
set -g fish_color_quote $MG_INK
set -g fish_color_redirection $MG_FAINT
set -g fish_color_end $MG_FAINT
set -g fish_color_error $MG_DANGER --bold
set -g fish_color_param $MG_INK
set -g fish_color_comment $MG_METADATA --italics
set -g fish_color_operator $MG_FAINT
set -g fish_color_escape $MG_METADATA
set -g fish_color_status $MG_DANGER
set -g fish_color_selection $MG_PAPER --background=$MG_INK
set -g fish_color_search_match $MG_INK --background=$MG_SELECTION --bold
set -g fish_color_autosuggestion $MG_FAINT
set -g fish_pager_color_progress $MG_METADATA
set -g fish_pager_color_prefix $MG_INK --bold
set -g fish_pager_color_completion $MG_INK
set -g fish_pager_color_description $MG_METADATA

# GitUI has a file-level theme switch but no environment variable.
function gitui --wraps gitui --description 'GitUI with the Micrographics theme'
    command gitui --theme micrographics.ron $argv
end
