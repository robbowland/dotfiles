#!/bin/sh
set -eu

##############################################
# Central theme generator driver
#
# Expects:
#   IN    – template (e.g. theme.ron.in)
#   OUT   – output path
# Optional:
#   THEME_ENV_FILE – .env file with PALETTE_* vars; defaults to Micrographics
#
# GEN may be overridden; otherwise defaults to
# ~/.config/.scripts/theme/_gen_from_palette.py
##############################################

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
GEN=${GEN:-"$BASE/.scripts/theme/_gen_from_palette.py"}
THEME_ENV_FILE=${THEME_ENV_FILE:-"$BASE/micrographics/palette.env"}

: "${IN:?IN required}"
: "${OUT:?OUT required}"

if [ "${THEME_ENV_FILE:-}" ]; then
	exec "$GEN" --template "$IN" --out "$OUT" --env-file "$THEME_ENV_FILE"
else
	exec "$GEN" --template "$IN" --out "$OUT"
fi
