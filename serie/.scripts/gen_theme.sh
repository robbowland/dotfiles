#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
MOD_DIR="$BASE/serie"
IN="$MOD_DIR/config.toml.in"
GEN="$BASE/.scripts/theme/gen_theme.sh"

render() {
	IN="$IN" OUT="$1" "$GEN"
}

render "$MOD_DIR/config.toml"
render "$MOD_DIR/micrographics.toml"
