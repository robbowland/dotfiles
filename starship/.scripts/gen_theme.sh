#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
IN="$BASE/starship/starship.toml.in"
GEN="$BASE/.scripts/theme/gen_theme.sh"

render() {
	IN="$IN" OUT="$1" "$GEN"
}

render "$BASE/starship/starship.toml"
render "$BASE/starship/themes/micrographics.toml"
