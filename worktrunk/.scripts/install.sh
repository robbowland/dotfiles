#!/bin/sh

install_worktrunk() {
  brew_install_formulas worktrunk

  if command -v pi >/dev/null 2>&1; then
    wt config plugins pi install --yes
  fi
  if command -v codex >/dev/null 2>&1; then
    wt config plugins codex install --yes
  fi
  if command -v claude >/dev/null 2>&1; then
    wt config plugins claude install --yes
  fi
}

register_installer install_worktrunk
