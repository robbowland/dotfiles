#!/bin/sh

install_gitui() {
  ensure_brew_tap robbowland/kegs
  brew_install_formulas robbowland/kegs/gitui
}

register_installer install_gitui
