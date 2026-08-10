#!/bin/sh
set -eu

BASE="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
INSTALLER="$BASE/micrographics/install-codex.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

make_config_home() {
  config_home="$1"
  mkdir -p "$config_home/bat/themes"
  cp "$BASE/bat/themes/Micrographics.tmTheme" \
    "$config_home/bat/themes/Micrographics.tmTheme"
}

CONFIG_HOME="$TMP/config"
CODEX_TEST_HOME="$TMP/custom-codex"
SOURCE="$CONFIG_HOME/bat/themes/Micrographics.tmTheme"
TARGET="$CODEX_TEST_HOME/themes/micrographics.tmTheme"
make_config_home "$CONFIG_HOME"

XDG_CONFIG_HOME="$CONFIG_HOME" CODEX_HOME="$CODEX_TEST_HOME" "$INSTALLER"
test -L "$TARGET" || fail "first install did not create a symlink"
test "$TARGET" -ef "$SOURCE" || fail "installed link does not resolve to the shared theme"

XDG_CONFIG_HOME="$CONFIG_HOME" CODEX_HOME="$CODEX_TEST_HOME" "$INSTALLER"
test "$TARGET" -ef "$SOURCE" || fail "repeat install changed the correct link"

MISSING_CONFIG="$TMP/missing-config"
if XDG_CONFIG_HOME="$MISSING_CONFIG" CODEX_HOME="$TMP/missing-codex" \
  "$INSTALLER" >"$TMP/missing.out" 2>"$TMP/missing.err"; then
  fail "missing source unexpectedly succeeded"
fi
grep -q 'Shared Micrographics theme not found' "$TMP/missing.err" || \
  fail "missing-source error was not actionable"

FILE_HOME="$TMP/file-codex"
mkdir -p "$FILE_HOME/themes"
printf 'keep me\n' >"$FILE_HOME/themes/micrographics.tmTheme"
if XDG_CONFIG_HOME="$CONFIG_HOME" CODEX_HOME="$FILE_HOME" \
  "$INSTALLER" >"$TMP/file.out" 2>"$TMP/file.err"; then
  fail "regular-file target unexpectedly succeeded"
fi
grep -q 'Refusing to replace unrelated Codex theme target' "$TMP/file.err" || \
  fail "regular-file refusal was not actionable"
grep -q '^keep me$' "$FILE_HOME/themes/micrographics.tmTheme" || \
  fail "regular-file target was changed"

OTHER="$TMP/other.tmTheme"
printf 'other\n' >"$OTHER"
LINK_HOME="$TMP/link-codex"
mkdir -p "$LINK_HOME/themes"
ln -s "$OTHER" "$LINK_HOME/themes/micrographics.tmTheme"
if XDG_CONFIG_HOME="$CONFIG_HOME" CODEX_HOME="$LINK_HOME" \
  "$INSTALLER" >"$TMP/link.out" 2>"$TMP/link.err"; then
  fail "different symlink unexpectedly succeeded"
fi
test "$(readlink "$LINK_HOME/themes/micrographics.tmTheme")" = "$OTHER" || \
  fail "different symlink was changed"

BROKEN_HOME="$TMP/broken-codex"
mkdir -p "$BROKEN_HOME/themes"
ln -s "$TMP/absent.tmTheme" "$BROKEN_HOME/themes/micrographics.tmTheme"
if XDG_CONFIG_HOME="$CONFIG_HOME" CODEX_HOME="$BROKEN_HOME" \
  "$INSTALLER" >"$TMP/broken.out" 2>"$TMP/broken.err"; then
  fail "broken symlink unexpectedly succeeded"
fi
test -L "$BROKEN_HOME/themes/micrographics.tmTheme" || \
  fail "broken symlink was removed"

printf '%s\n' 'Codex theme installer: OK'
