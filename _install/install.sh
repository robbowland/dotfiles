#!/bin/sh
set -eu
######################################
# Bootstrap Homebrew, source module
# installers, and execute them.
######################################

CONFIG_ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

# shellcheck source=_install/lib.sh
. "$CONFIG_ROOT/_install/lib.sh"

ensure_command_line_tools
ensure_homebrew

# Discover module installers (depth 2) excluding this orchestrator
scripts=$(find "$CONFIG_ROOT" -mindepth 2 -maxdepth 2 -name install.sh \
  ! -path "$CONFIG_ROOT/_install/install.sh" | sort)

old_ifs=$IFS
IFS='
'
set -- $scripts
IFS=$old_ifs

for script in "$@"; do
  # shellcheck source=/dev/null
  . "$script"
done

run_installers
