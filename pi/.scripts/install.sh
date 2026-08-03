#!/bin/sh

install_pi_context_status() (
  source_path="$CONFIG_ROOT/pi/extensions/context-status.ts"
  target_dir="$HOME/.pi/agent/extensions"
  target_path="$target_dir/context-status.ts"

  if [ ! -f "$source_path" ]; then
    printf 'Pi context status source not found: %s\n' "$source_path" >&2
    return 1
  fi

  mkdir -p "$target_dir"

  if [ -L "$target_path" ]; then
    if [ "$(readlink "$target_path")" = "$source_path" ]; then
      printf 'Pi context status extension already linked\n'
      return 0
    fi
    printf 'Refusing to replace unrelated Pi extension symlink: %s\n' "$target_path" >&2
    return 1
  fi

  if [ -e "$target_path" ]; then
    printf 'Refusing to replace unrelated Pi extension file: %s\n' "$target_path" >&2
    return 1
  fi

  ln -s "$source_path" "$target_path"
  printf 'Linked Pi context status extension: %s\n' "$target_path"
)

register_installer install_pi_context_status
