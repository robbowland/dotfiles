#!/bin/fish

# Micrographics fzf profile. Source after other fzf exports when reapplying it.
set -gx FZF_DEFAULT_OPTS "
  --style=minimal
  --color=fg:#ffffff,bg:#000000,hl:#999999,fg+:#000000:bold,bg+:#ffffff,hl+:#000000:bold,info:#404040,border:#404040,gutter:#000000,prompt:#999999,pointer:#000000:bold,marker:#000000:bold,spinner:#999999,header:#999999,label:#404040,query:#ffffff
  --prompt='[FND] '
  --marker='+ '
  --pointer='> '
  --separator='─'
  --scrollbar=''
  --info=inline-right
  --layout=default
  --bind=ctrl-p:toggle-preview
"
