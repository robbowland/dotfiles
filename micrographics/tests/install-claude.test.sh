#!/bin/sh
set -eu

BASE="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
INSTALLER="$BASE/micrographics/install-claude.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

make_config_home() {
  config_home="$1"
  mkdir -p "$config_home/micrographics"
  cp "$BASE/micrographics/claude-theme.json" \
    "$config_home/micrographics/claude-theme.json"
}

CONFIG_HOME="$TMP/config"
CLAUDE_TEST_HOME="$TMP/custom-claude"
SOURCE="$CONFIG_HOME/micrographics/claude-theme.json"
TARGET="$CLAUDE_TEST_HOME/themes/micrographics.json"
make_config_home "$CONFIG_HOME"

XDG_CONFIG_HOME="$CONFIG_HOME" CLAUDE_CONFIG_DIR="$CLAUDE_TEST_HOME" "$INSTALLER"
test -L "$TARGET" || fail "first install did not create a symlink"
test "$TARGET" -ef "$SOURCE" || fail "installed link does not resolve to the shared theme"

XDG_CONFIG_HOME="$CONFIG_HOME" CLAUDE_CONFIG_DIR="$CLAUDE_TEST_HOME" "$INSTALLER"
test "$TARGET" -ef "$SOURCE" || fail "repeat install changed the correct link"

MISSING_CONFIG="$TMP/missing-config"
if XDG_CONFIG_HOME="$MISSING_CONFIG" CLAUDE_CONFIG_DIR="$TMP/missing-claude" \
  "$INSTALLER" >"$TMP/missing.out" 2>"$TMP/missing.err"; then
  fail "missing source unexpectedly succeeded"
fi
grep -q 'Claude Code Micrographics theme not found' "$TMP/missing.err" || \
  fail "missing-source error was not actionable"

FILE_HOME="$TMP/file-claude"
mkdir -p "$FILE_HOME/themes"
printf 'keep me\n' >"$FILE_HOME/themes/micrographics.json"
if XDG_CONFIG_HOME="$CONFIG_HOME" CLAUDE_CONFIG_DIR="$FILE_HOME" \
  "$INSTALLER" >"$TMP/file.out" 2>"$TMP/file.err"; then
  fail "regular-file target unexpectedly succeeded"
fi
grep -q 'Refusing to replace unrelated Claude Code theme target' "$TMP/file.err" || \
  fail "regular-file refusal was not actionable"
grep -q '^keep me$' "$FILE_HOME/themes/micrographics.json" || \
  fail "regular-file target was changed"

OTHER="$TMP/other.json"
printf 'other\n' >"$OTHER"
LINK_HOME="$TMP/link-claude"
mkdir -p "$LINK_HOME/themes"
ln -s "$OTHER" "$LINK_HOME/themes/micrographics.json"
if XDG_CONFIG_HOME="$CONFIG_HOME" CLAUDE_CONFIG_DIR="$LINK_HOME" \
  "$INSTALLER" >"$TMP/link.out" 2>"$TMP/link.err"; then
  fail "different symlink unexpectedly succeeded"
fi
test "$(readlink "$LINK_HOME/themes/micrographics.json")" = "$OTHER" || \
  fail "different symlink was changed"

BROKEN_HOME="$TMP/broken-claude"
mkdir -p "$BROKEN_HOME/themes"
ln -s "$TMP/absent.json" "$BROKEN_HOME/themes/micrographics.json"
if XDG_CONFIG_HOME="$CONFIG_HOME" CLAUDE_CONFIG_DIR="$BROKEN_HOME" \
  "$INSTALLER" >"$TMP/broken.out" 2>"$TMP/broken.err"; then
  fail "broken symlink unexpectedly succeeded"
fi
test -L "$BROKEN_HOME/themes/micrographics.json" || \
  fail "broken symlink was removed"

printf '%s\n' 'Claude Code theme installer: OK'
