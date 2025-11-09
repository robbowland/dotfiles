#!/bin/fish

# Use fd if available
if type -q fd
    set -x FZF_DEFAULT_COMMAND "fd . $HOME"
    set -x FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -x FZF_ALT_C_COMMAND "fd -t d . $HOME"
end

# Set the theme
set -x FZF_DEFAULT_OPTS "
   --color=fg:$PALETTE_WHITE,fg+:$PALETTE_WHITE:bold:italic,bg:-1,bg+:$PALETTE_BLACK
   --color=hl:$PALETTE_YELLOW,hl+:$PALETTE_MAGENTA,info:#d0d0d0,marker:$PALETTE_YELLOW
   --color=prompt:"$PALETTE_MAGENTA",spinner:$PALETTE_MAGENTA,pointer:$PALETTE_YELLOW,header:#87afaf
   --color=border:#262626,label:#aeaeae,query:#d9d9d9
   --prompt='❯ '
   --marker='▸ '
   --pointer='•'
   --separator='─'
   --scrollbar=''
   --info='right'
   --layout=default
   --bind=alt-p:toggle-preview
"

set -x FZF_CTRL_R_OPTS "
   --no-sort
   --exact
   --no-preview
   --preview-window=hidden
"

if type -q fd
    set -x FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
    set -x FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -x FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"
end
