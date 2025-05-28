#!/bin/fish

# Use fd if available
if type -q fd
    set -x FZF_DEFAULT_COMMAND "fd . $HOME"
    set -x FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -x FZF_ALT_C_COMMAND "fd -t d . $HOME"
end

# Set the theme
set -x FZF_DEFAULT_OPTS "
   --preview='bat --color=always {}'
   --color=fg:-1,fg+:#d0d0d0,bg:-1,bg+:$PALETTE_GRAY_DARKER
   --color=hl:$PALETTE_YELLOW,hl+:$PALETTE_MAGENTA,info:#d0d0d0,marker:$PALETTE_YELLOW
   --color=prompt:"$PALETTE_MAGENTA",spinner:#af5fff,pointer:$PALETTE_MAGENTA,header:#87afaf
   --color=border:#262626,label:#aeaeae,query:#d9d9d9
   --preview-window='border-rounded'
   --prompt='❯ '
   --marker='▸ '
   --pointer='•'
   --separator='─'
   --scrollbar='│'
   --info='right'"
