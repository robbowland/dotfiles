#!/bin/sh
set -eu

##############################################
# Central theme generator driver
#
# Expects:
#   IN    – template (e.g. theme.ron.in)
#   OUT   – output path
# Optional:
#   THEME_ENV_FILE – .env file with PALETTE_* vars
#
# GEN may be overridden; otherwise defaults to
# ~/.config/.scripts/themes/gen_from_palette.py
##############################################

GEN=${GEN:-"${XDG_CONFIG_HOME:-$HOME/.config}/.scripts/theme/_gen_from_palette.py"}

: "${IN:?IN required}"
: "${OUT:?OUT required}"

if [ "${THEME_ENV_FILE:-}" ]; then
	exec "$GEN" --template "$IN" --out "$OUT" --env-file "$THEME_ENV_FILE"
else
	exec "$GEN" --template "$IN" --out "$OUT"
fi
