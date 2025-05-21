#!/bin/zsh

######################################
# Update sketchy bar brew notifier when 
# performing a brew command.
######################################
function sketchybar_brew() {
  command brew "$@" 

  if [[ $* =~ "upgrade" ]] || [[ $* =~ "update" ]] || [[ $* =~ "outdated" ]]; then
    sketchybar --trigger brew_update
  fi
}
