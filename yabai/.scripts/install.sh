#!/bin/sh

install_yabai() {
  ensure_brew_tap koekeishiya/formulae
  brew_install_formulas yabai borders jq

  if command -v yabai >/dev/null 2>&1; then
    yabai --restart-service >/dev/null 2>&1 || yabai --start-service >/dev/null 2>&1 || true
  fi

  echo "Remember to load the scripting addition (sudo yabai --load-sa) and grant Accessibility permissions." >&2
}

register_installer install_yabai
