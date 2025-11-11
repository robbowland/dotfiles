#!/bin/sh

install_skhd() {
  brew_install_formulas skhd
  if command -v skhd >/dev/null 2>&1; then
    skhd --restart-service >/dev/null 2>&1 || skhd --start-service >/dev/null 2>&1 || true
  fi
}

register_installer install_skhd
