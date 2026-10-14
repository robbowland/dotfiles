#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SOURCE="$BASE/micrographics/claude-theme.json"
TARGET_DIR="$CLAUDE_DIR/themes"
TARGET="$TARGET_DIR/micrographics.json"

if [ ! -f "$SOURCE" ]; then
  printf 'Claude Code Micrographics theme not found: %s\n' "$SOURCE" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

if [ -L "$TARGET" ]; then
  if [ "$TARGET" -ef "$SOURCE" ]; then
    printf 'Claude Code Micrographics theme already installed: %s\n' "$TARGET"
    exit 0
  fi
  printf 'Refusing to replace unrelated Claude Code theme target: %s\n' "$TARGET" >&2
  exit 1
fi

if [ -e "$TARGET" ]; then
  printf 'Refusing to replace unrelated Claude Code theme target: %s\n' "$TARGET" >&2
  exit 1
fi

ln -s "$SOURCE" "$TARGET"
printf 'Installed Claude Code Micrographics theme: %s -> %s\n' "$TARGET" "$SOURCE"
