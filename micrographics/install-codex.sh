#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
SOURCE="$BASE/bat/themes/Micrographics.tmTheme"
TARGET_DIR="$CODEX_DIR/themes"
TARGET="$TARGET_DIR/micrographics.tmTheme"

if [ ! -f "$SOURCE" ]; then
  printf 'Shared Micrographics theme not found: %s\n' "$SOURCE" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

if [ -L "$TARGET" ]; then
  if [ "$TARGET" -ef "$SOURCE" ]; then
    printf 'Codex Micrographics theme already installed: %s\n' "$TARGET"
    exit 0
  fi
  printf 'Refusing to replace unrelated Codex theme target: %s\n' "$TARGET" >&2
  exit 1
fi

if [ -e "$TARGET" ]; then
  printf 'Refusing to replace unrelated Codex theme target: %s\n' "$TARGET" >&2
  exit 1
fi

ln -s "$SOURCE" "$TARGET"
printf 'Installed Codex Micrographics theme: %s -> %s\n' "$TARGET" "$SOURCE"
