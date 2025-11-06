#!/bin/sh

install_gh_dash() {
  ensure_brew_tap robbowland/kegs
  brew_install_formulas robbowland/kegs/gh-dash
}

register_installer install_gh_dash
