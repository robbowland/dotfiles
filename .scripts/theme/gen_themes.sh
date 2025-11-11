#!/bin/sh
set -eu

##############################################
# Regenerate all module themes
##############################################

find "${XDG_CONFIG_HOME:-$HOME/.config}" \
	-type f -path '*/.scripts/gen_theme.sh' \
	-exec {} \;
