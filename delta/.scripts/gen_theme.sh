#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
MOD_DIR="$BASE/delta"

IN="$MOD_DIR/config.in"
OUT="$MOD_DIR/config"

IN="$IN" OUT="$OUT" exec \
	"$BASE/.scripts/theme/gen_theme.sh"
