#!/bin/sh
set -eu

# ==================================================
#  Orchestrate discovery of module installers and
#  execute them in the order they are registered
# ==================================================

CONFIG_ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)"

# shellcheck source=.scripts/install/lib.sh
. "$CONFIG_ROOT/.scripts/install/lib.sh"

ensure_command_line_tools
ensure_homebrew

scripts=$(find "$CONFIG_ROOT" -mindepth 2 -maxdepth 2 -name install.sh \
	! -path "$CONFIG_ROOT/.scripts/install/install.sh" | sort)

old_ifs=$IFS
IFS='
'
# shellcheck disable=SC2086     # deliberate splitting on newline
set -- $scripts
IFS=$old_ifs

for script in "$@"; do
	# shellcheck source=/dev/null
	. "$script"
done

run_installers
