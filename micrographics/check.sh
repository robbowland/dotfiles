#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

# The suite must remain opt-in.
grep -q -- '--theme="GitHubDark"' "$BASE/bat/config"
grep -q '^theme = GitHub Dark$' "$BASE/ghostty/config"
grep -q '^palette = "github-dark"$' "$BASE/starship/starship.toml"
grep -q '^theme "github_dark"$' "$BASE/zellij/config.kdl"
grep -q 'GitHubDark.tmTheme' "$BASE/yazi/theme.toml"
grep -q '^theme: ink$' "$BASE/posting/config.yaml"

# Static formats and the fixed palette contract.
plutil -lint "$BASE/bat/themes/Micrographics.tmTheme" >/dev/null
python3 - "$BASE" <<'PY'
import pathlib, re, sys, tomllib
base = pathlib.Path(sys.argv[1])
allowed = {"#000000", "#ffffff", "#999999", "#616161", "#ff3b2f", "#303030"}
paths = [
    base / "ghostty/themes/Micrographics",
    base / "fish/palettes/micrographics.fish",
    base / "fzf/fish/themes/micrographics.fish",
    base / "starship/themes/micrographics.toml",
    base / "bat/themes/Micrographics.tmTheme",
    base / "yazi/profiles/micrographics/theme.toml",
    base / "zellij/themes/micrographics.kdl",
    base / "zellij/layouts/micrographics.kdl",
    base / "zellij/profiles/micrographics.kdl",
    base / "gitui/micrographics.ron",
    base / "gh-dash/micrographics.yml",
    base / "serie/micrographics.toml",
    base / "posting/themes/micrographics.yaml",
]
for path in paths:
    colors = {c.lower() for c in re.findall(r"#[0-9a-fA-F]{6}", path.read_text())}
    unexpected = colors - allowed
    if unexpected:
        raise SystemExit(f"{path}: unexpected colors {sorted(unexpected)}")
for path in [
    base / "starship/themes/micrographics.toml",
    base / "yazi/profiles/micrographics/theme.toml",
    base / "serie/micrographics.toml",
]:
    tomllib.loads(path.read_text())
PY
ruby -e 'require "yaml"; ARGV.each { |p| YAML.safe_load(File.read(p), permitted_classes: [], aliases: false) }' \
  "$BASE/gh-dash/micrographics.yml" \
  "$BASE/posting/themes/micrographics.yaml" \
  "$BASE/posting/profiles/micrographics.yaml"

# Installed loaders and parsers.
bat cache --build >/dev/null
bat --list-themes | grep -q '^Micrographics$'
printf 'function alpha() { return 1; }\n' > "$TMP/sample.js"
bat --theme Micrographics --color=always --style=plain "$TMP/sample.js" >/dev/null
printf 'theme = Micrographics\n' > "$TMP/ghostty"
ghostty +validate-config --config-file="$TMP/ghostty"
STARSHIP_CONFIG="$BASE/starship/themes/micrographics.toml" starship print-config >/dev/null
fish -n "$BASE/fish/palettes/micrographics.fish" "$BASE/fzf/fish/themes/micrographics.fish" "$BASE/micrographics/activate.fish"
fish --no-config -c 'source ~/.config/micrographics/activate.fish; test "$BAT_THEME" = Micrographics; printf "x\n" | fzf --filter x >/dev/null'
YAZI_CONFIG_HOME="$BASE/yazi/profiles/micrographics" yazi --debug > "$TMP/yazi" 2>&1
grep -q 'profiles/micrographics/init.lua' "$TMP/yazi"
grep -q 'profiles/micrographics/theme.toml' "$TMP/yazi"
! grep -Eqi 'invalid theme|failed to load|parse error' "$TMP/yazi"
ZELLIJ_CONFIG_FILE="$BASE/zellij/profiles/micrographics.kdl" zellij setup --check > "$TMP/zellij" 2>&1
grep -q 'Well defined' "$TMP/zellij"
ZELLIJ_CONFIG_FILE="$BASE/zellij/profiles/micrographics.kdl" zellij setup --dump-layout micrographics >/dev/null

POSTING_PYTHON="$(head -1 "$(command -v posting)" | sed 's/^#!//')"
"$POSTING_PYTHON" - "$BASE/posting/themes/micrographics.yaml" <<'PY'
import sys
from pathlib import Path
from posting.themes import load_user_theme
assert load_user_theme(Path(sys.argv[1])).name == "micrographics"
PY

# Delta's default remains github-dark while the optional feature is discoverable.
grep -q '^features = "github-dark"$' "$BASE/delta/config"
grep -q '^\[delta "micrographics"\]$' "$BASE/delta/config"

printf '%s\n' 'Micrographics terminal suite: OK'
