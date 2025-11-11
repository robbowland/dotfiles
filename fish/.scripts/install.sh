#!/bin/sh

install_fish() {
  brew_install_formulas fish

  if ! command -v fish >/dev/null 2>&1; then
    echo "fish installation failed or fish not on PATH" >&2
    return 1
  fi

  if ! fish -c 'functions -q fisher' >/dev/null 2>&1; then
    fish -c 'curl -sL https://git.io/fisher | source; and fisher install jorgebucaran/fisher'
  fi

  fish -c 'fisher install edc/bass'
}

register_installer install_fish
