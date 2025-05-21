#!/bin/zsh

ZSH_ALIAS_PATH="${HOME}/.config/zsh/aliases/*.zsh"

######################################
# Use bat to show zsh aliases.
######################################
bat_zsh_aliases() {
  for alias_file in $~ZSH_ALIAS_PATH; do
    file_output=$( bat --force-colorization --style=plain $alias_file )
    printf "%s\n" "${file_output}"
  done
}