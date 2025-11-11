#!/bin/sh

install_sketchybar() {
  ensure_brew_tap felixkratz/formulae
  brew_install_formulas sketchybar borders jq

  if [ -d "$HOME/.config/sketchybar/helper" ]; then
    (cd "$HOME/.config/sketchybar/helper" && make)
  fi

  brew services restart sketchybar
}

register_installer install_sketchybar
