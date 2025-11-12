#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
IN="$BASE/starship/starship.toml.in"
OUT="$BASE/starship/starship.toml"

IN="$IN" OUT="$OUT" THEME_ENV_FILE="${THEME_ENV_FILE:-}" \
	exec "$BASE/.scripts/theme/gen_theme.sh"
