#!/bin/fish

# Use fd if available
if type -q fd
    set -x FZF_DEFAULT_COMMAND "fd . $HOME"
    set -x FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -x FZF_ALT_C_COMMAND "fd -t d . $HOME"
end

# theme
set -x FZF_DEFAULT_OPTS "
  --color=\
fg:$PALETTE_WHITE,\
bg:$PALETTE_BLACK,\
hl:$PALETTE_YELLOW,\
fg+:$PALETTE_WHITE_BRIGHT:bold,\
bg+:$PALETTE_SURFACE_1,\
hl+:$PALETTE_YELLOW_BRIGHT:bold,\
info:$PALETTE_GRAY_DIM,\
border:$PALETTE_GRAY_DIM,\
gutter:$PALETTE_BLACK,\
prompt:$PALETTE_MAGENTA,\
pointer:$PALETTE_YELLOW,\
marker:$PALETTE_YELLOW,\
spinner:$PALETTE_CYAN,\
header:$PALETTE_CYAN,\
label:$PALETTE_GRAY,\
query:$PALETTE_WHITE \
  --prompt='❯ '
  --marker='▸ '
  --pointer='•'
  --separator='─'
  --scrollbar=''
  --info=right
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
