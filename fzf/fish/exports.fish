#!/bin/fish

# Use fd if available
if type -q fd
    set -x FZF_DEFAULT_COMMAND "fd . $HOME"
    set -x FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -x FZF_ALT_C_COMMAND "fd -t d . $HOME"
end

# Micrographics theme
set -x FZF_DEFAULT_OPTS "
  --style=minimal
  --color=fg:$PALETTE_WHITE,bg:$PALETTE_BLACK,hl:$PALETTE_GRAY,fg+:$PALETTE_BLACK:bold,bg+:$PALETTE_WHITE,hl+:$PALETTE_BLACK:bold,info:$PALETTE_GRAY_DIM,border:$PALETTE_GRAY_DIM,gutter:$PALETTE_BLACK,prompt:$PALETTE_GRAY,pointer:$PALETTE_BLACK:bold,marker:$PALETTE_BLACK:bold,spinner:$PALETTE_GRAY,header:$PALETTE_GRAY,label:$PALETTE_GRAY_DIM,query:$PALETTE_WHITE
  --prompt='[FND] '
  --marker='+ '
  --pointer='> '
  --separator='─'
  --scrollbar=''
  --info=inline-right
  --layout=default
  --bind=ctrl-p:toggle-preview
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
