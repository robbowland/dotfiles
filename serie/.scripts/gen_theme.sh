#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
MOD_DIR="$BASE/serie"

IN="$MOD_DIR/config.toml.in"
OUT="$MOD_DIR/config.toml"

IN="$IN" OUT="$OUT" \
	exec "$BASE/.scripts/theme/gen_theme.sh"
