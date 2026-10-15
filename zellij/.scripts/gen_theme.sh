#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
MOD_DIR="$BASE/zellij"
GEN="$BASE/.scripts/theme/gen_theme.sh"

render() {
	IN="$1" OUT="$2" "$GEN"
}

render "$MOD_DIR/config.kdl.in" "$MOD_DIR/config.kdl"
render "$MOD_DIR/config.kdl.in" "$MOD_DIR/profiles/micrographics.kdl"
render "$MOD_DIR/layouts/default.kdl.in" "$MOD_DIR/layouts/default.kdl"
render "$MOD_DIR/layouts/default.kdl.in" "$MOD_DIR/layouts/micrographics.kdl"
