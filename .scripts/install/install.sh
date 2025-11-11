#!/bin/sh
set -eu

# ==================================================
#  Orchestrate discovery of module installers and
#  execute them in the order they are registered
# ==================================================

# Resolve repo root from .../.scripts/install/install.sh → <root>
CONFIG_ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)"

# shellcheck source=.scripts/install/lib.sh
. "$CONFIG_ROOT/.scripts/install/lib.sh"

ensure_command_line_tools
ensure_homebrew

# Save IFS and set newline-only to avoid splitting on spaces/tabs
old_ifs=$IFS
IFS='
'

scripts=$(
	find "$CONFIG_ROOT" -type f -path '*/.scripts/install.sh' \
		! -path "$CONFIG_ROOT/.scripts/install/install.sh" |
		sort
)

for script in $scripts; do
	# shellcheck source=/dev/null
	. "$script"
done

IFS=$old_ifs

run_installers
