#!/bin/sh
set -eu

: "${CONFIG_INSTALLERS:=}"

######################################
# Track module installer functions for
# execution by the orchestrator.
######################################
register_installer() {
  local fn="$1"
  local existing
  [ -n "$fn" ] || return
  for existing in $CONFIG_INSTALLERS; do
    if [ "$existing" = "$fn" ]; then
      return
    fi
  done
  if [ -n "${CONFIG_INSTALLERS:-}" ]; then
    CONFIG_INSTALLERS="$CONFIG_INSTALLERS $fn"
  else
    CONFIG_INSTALLERS="$fn"
  fi
}

######################################
# Execute all registered installers in
# the order they were discovered.
######################################
run_installers() {
  local fn
  for fn in $CONFIG_INSTALLERS; do
    printf '\n==> %s\n' "$fn"
    if command -v "$fn" >/dev/null 2>&1; then
      "$fn"
    else
      echo "Installer function '$fn' is not defined" >&2
    fi
  done
}

######################################
# Ensure Xcode Command Line Tools exist
# before running Homebrew installs.
######################################
ensure_command_line_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    return
  fi
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install || true
  echo "Re-run the installer after the Command Line Tools finish installing."
  exit 0
}

######################################
# Install Homebrew when missing and add
# it to the current shell environment.
######################################
ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return
  fi

  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

######################################
# Add the specified taps if they are not
# already present in Homebrew.
######################################
ensure_brew_tap() {
  local tap
  for tap in "$@"; do
    if ! brew tap | grep -qx "$tap" 2>/dev/null; then
      brew tap "$tap"
    fi
  done
}

######################################
# Install Homebrew formulae only when
# they are not already installed.
######################################
brew_install_formulas() {
  local formula
  for formula in "$@"; do
    if brew list --formula "$formula" >/dev/null 2>&1; then
      printf "brew formula %s already installed\n" "$formula"
    else
      brew install "$formula"
    fi
  done
}

######################################
# Install Homebrew casks only when they
# are not already installed.
######################################
brew_install_casks() {
  local cask
  for cask in "$@"; do
    if brew list --cask "$cask" >/dev/null 2>&1; then
      printf "brew cask %s already installed\n" "$cask"
    else
      brew install --cask "$cask"
    fi
  done
}
