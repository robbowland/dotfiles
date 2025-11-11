#!/bin/sh
set -eu

# ==================================================
#  Orchestrate discovery of module installers and
#  execute them in the order they are registered
# ==================================================

CONFIG_ROOT=$(
	CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd
)

# shellcheck source=_install/lib.sh
. "$CONFIG_ROOT/_install/lib.sh"

ensure_command_line_tools
ensure_homebrew

# Discover module installers (depth 2), excluding this file
scripts=$(find "$CONFIG_ROOT" -mindepth 2 -maxdepth 2 -name install.sh \
	! -path "$CONFIG_ROOT/_install/install.sh" | sort)

# Split on newlines only
old_ifs=$IFS
IFS='
'
# shellcheck disable=SC2086     # deliberate splitting on newline
set -- $scripts
IFS=$old_ifs

# Source each installer so it can call register_installer()
for script in "$@"; do
	# shellcheck source=/dev/null
	. "$script"
done

run_installers
