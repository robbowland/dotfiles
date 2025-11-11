#!/bin/sh

install_delta() {
  brew_install_formulas git-delta

  local config_path="$HOME/.config/delta/config"
  if [ -f "$config_path" ]; then
    local includes
    includes="$(git config --global --get-all include.path 2>/dev/null || true)"
    case "$includes" in
      *"$config_path"*)
        ;;
      *)
        git config --global --add include.path "$config_path"
        ;;
    esac
  fi
}

register_installer install_delta
