#!/bin/sh

install_gh() {
  brew_install_formulas gh
  if command -v gh >/dev/null 2>&1; then
    gh extension install github/gh-copilot || true
  fi
}

register_installer install_gh
