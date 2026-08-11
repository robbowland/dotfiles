#!/bin/sh

validate_pi_link() (
  source_path="$1"
  target_path="$2"
  label="$3"

  if [ ! -f "$source_path" ]; then
    printf '%s source not found: %s\n' "$label" "$source_path" >&2
    return 1
  fi

  if [ -L "$target_path" ]; then
    if [ "$(readlink "$target_path")" = "$source_path" ]; then
      return 0
    fi
    printf 'Refusing to replace unrelated Pi symlink: %s\n' "$target_path" >&2
    return 1
  fi

  if [ -e "$target_path" ]; then
    printf 'Refusing to replace unrelated Pi file: %s\n' "$target_path" >&2
    return 1
  fi
)

link_pi_file() (
  source_path="$1"
  target_path="$2"
  label="$3"

  validate_pi_link "$source_path" "$target_path" "$label" || return 1

  if [ -L "$target_path" ]; then
    printf '%s already linked\n' "$label"
    return 0
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  printf 'Linked %s: %s\n' "$label" "$target_path"
)

install_pi_context_status() (
  link_pi_file \
    "$CONFIG_ROOT/pi/extensions/context-status.ts" \
    "$HOME/.pi/agent/extensions/context-status.ts" \
    "Pi context status extension"
)

install_pi_modal_editor() (
  extension_source="$CONFIG_ROOT/pi/extensions/modal-editor.ts"
  extension_target="$HOME/.pi/agent/extensions/modal-editor.ts"
  state_source="$CONFIG_ROOT/pi/lib/modal-editor-state.ts"
  state_target="$HOME/.pi/agent/lib/modal-editor-state.ts"

  validate_pi_link \
    "$extension_source" \
    "$extension_target" \
    "Pi modal editor extension" || return 1

  validate_pi_link \
    "$state_source" \
    "$state_target" \
    "Pi modal editor state" || return 1

  link_pi_file \
    "$extension_source" \
    "$extension_target" \
    "Pi modal editor extension" || return 1

  link_pi_file \
    "$state_source" \
    "$state_target" \
    "Pi modal editor state"
)

register_installer install_pi_context_status
register_installer install_pi_modal_editor
