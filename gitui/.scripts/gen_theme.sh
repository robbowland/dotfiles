#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
IN="$BASE/gitui/theme.ron.in"
OUT="$BASE/gitui/theme.ron"

IN="$IN" OUT="$OUT" \
	exec "$BASE/.scripts/theme/gen_theme.sh"
