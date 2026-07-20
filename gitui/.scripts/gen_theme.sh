#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
IN="$BASE/gitui/theme.ron.in"
GEN="$BASE/.scripts/theme/gen_theme.sh"

render() {
	IN="$IN" OUT="$1" "$GEN"
}

render "$BASE/gitui/theme.ron"
render "$BASE/gitui/micrographics.ron"
