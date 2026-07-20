#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
IN="$BASE/yazi/theme.toml.in"
GEN="$BASE/.scripts/theme/gen_theme.sh"

render() {
	IN="$IN" OUT="$1" "$GEN"
}

render "$BASE/yazi/theme.toml"
render "$BASE/yazi/profiles/micrographics/theme.toml"
