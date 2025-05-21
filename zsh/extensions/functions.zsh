#!/bin/sh

######################################
# Moves prompt to bottom of the terminal window,
# clearing lines above prompt if existing.
######################################
prompt_to_bottom () {
  printf "\n%.0s" {1..$(tput lines)}
}

######################################
# Load and start zsh auto(tab)completions.
######################################
load_zsh_autocomplete() {
  autoload -U compinit
  compinit
}

######################################
# Add ssh keys to the apple keychain, so that
# password only needs to be input a single time.
######################################
add_ssh_keys_to_keychain() {
  ssh-add --apple-use-keychain 2> /dev/null # Always outputs to STDERR, so use 2>
}
