#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

# Micrographics must be selected by the normal configs, not only preview profiles.
grep -q -- '--theme="Micrographics"' "$BASE/bat/config"
grep -q '^theme = Micrographics$' "$BASE/ghostty/config"
grep -q '^palette = "micrographics"$' "$BASE/starship/starship.toml"
grep -q '^theme "micrographics"$' "$BASE/zellij/config.kdl"
grep -q '^default_layout "default"$' "$BASE/zellij/config.kdl"
grep -q 'Micrographics.tmTheme' "$BASE/yazi/theme.toml"
grep -q '^theme: micrographics$' "$BASE/posting/config.yaml"
grep -q '^features = "micrographics"$' "$BASE/delta/config"
grep -q 'syntax:[[:space:]]*Some("Micrographics")' "$BASE/gitui/theme.ron"
grep -q 'micrographics/activate.fish' "$BASE/fish/config.fish"
cmp -s "$BASE/gh-dash/config.yml" "$BASE/gh-dash/micrographics.yml"
cmp -s "$BASE/posting/config.yaml" "$BASE/posting/profiles/micrographics.yaml"
cmp -s "$BASE/yazi/init.lua" "$BASE/yazi/profiles/micrographics/init.lua"

# Generated defaults and compatibility profiles must match their templates.
rendered() {
  template="$1"
  output="$2"
  env -i PATH="$PATH" HOME="$HOME" \
    "$BASE/.scripts/theme/_gen_from_palette.py" \
    --template "$template" \
    --out "$TMP/rendered" \
    --env-file "$BASE/micrographics/palette.env" >/dev/null
  cmp -s "$TMP/rendered" "$output"
}

rendered "$BASE/delta/config.in" "$BASE/delta/config"
rendered "$BASE/gitui/theme.ron.in" "$BASE/gitui/theme.ron"
rendered "$BASE/gitui/theme.ron.in" "$BASE/gitui/micrographics.ron"
rendered "$BASE/serie/config.toml.in" "$BASE/serie/config.toml"
rendered "$BASE/serie/config.toml.in" "$BASE/serie/micrographics.toml"
rendered "$BASE/starship/starship.toml.in" "$BASE/starship/starship.toml"
rendered "$BASE/starship/starship.toml.in" "$BASE/starship/themes/micrographics.toml"
rendered "$BASE/yazi/theme.toml.in" "$BASE/yazi/theme.toml"
rendered "$BASE/yazi/theme.toml.in" "$BASE/yazi/profiles/micrographics/theme.toml"
rendered "$BASE/zellij/config.kdl.in" "$BASE/zellij/config.kdl"
rendered "$BASE/zellij/config.kdl.in" "$BASE/zellij/profiles/micrographics.kdl"
rendered "$BASE/zellij/layouts/default.kdl.in" "$BASE/zellij/layouts/default.kdl"
rendered "$BASE/zellij/layouts/default.kdl.in" "$BASE/zellij/layouts/micrographics.kdl"

# Static formats and the fixed palette contract.
plutil -lint "$BASE/bat/themes/Micrographics.tmTheme" >/dev/null
python3 - "$BASE" <<'PY'
import pathlib, re, sys, tomllib
base = pathlib.Path(sys.argv[1])
allowed = {"#000000", "#ffffff", "#999999", "#616161", "#ff3b2f", "#303030"}
paths = [
    base / "micrographics/palette.env",
    base / "ghostty/themes/Micrographics",
    base / "fish/palettes/micrographics.fish",
    base / "fzf/fish/themes/micrographics.fish",
    base / "starship/starship.toml",
    base / "bat/themes/Micrographics.tmTheme",
    base / "yazi/theme.toml",
    base / "zellij/config.kdl",
    base / "zellij/layouts/default.kdl",
    base / "gitui/theme.ron",
    base / "gh-dash/config.yml",
    base / "serie/config.toml",
    base / "posting/themes/micrographics.yaml",
]
for path in paths:
    colors = {c.lower() for c in re.findall(r"#[0-9a-fA-F]{6}", path.read_text())}
    unexpected = colors - allowed
    if unexpected:
        raise SystemExit(f"{path}: unexpected colors {sorted(unexpected)}")

toml_paths = [
    base / "starship/starship.toml",
    base / "yazi/theme.toml",
    base / "serie/config.toml",
]
parsed = {path: tomllib.loads(path.read_text()) for path in toml_paths}
yazi = parsed[base / "yazi/theme.toml"]
assert yazi["indicator"]["current"] == {
    "fg": "#000000",
    "bg": "#ffffff",
    "bold": True,
}, "Yazi current selection must remain solid white with black text"
assert yazi["indicator"]["padding"] == {
    "open": " ",
    "close": "",
}, "Yazi selection must keep one alignment cell without bracket glyphs"
PY
ruby -e 'require "yaml"; ARGV.each { |p| YAML.safe_load(File.read(p), permitted_classes: [], aliases: false) }' \
  "$BASE/gh-dash/config.yml" \
  "$BASE/posting/themes/micrographics.yaml" \
  "$BASE/posting/config.yaml"

# Installed loaders and parsers.
bat cache --build >/dev/null
bat --list-themes | grep -q '^Micrographics$'
printf 'function alpha() { return 1; }\n' > "$TMP/sample.js"
bat --theme Micrographics --color=always --style=plain "$TMP/sample.js" >/dev/null
printf 'theme = Micrographics\n' > "$TMP/ghostty"
ghostty +validate-config --config-file="$TMP/ghostty"
STARSHIP_CONFIG="$BASE/starship/starship.toml" starship print-config >/dev/null
! grep -Eq '\[(DIR|GIT|STA|TME|PY)\]|\$\{count\}' "$BASE/starship/starship.toml"
fish -n "$BASE/fish/config.fish" "$BASE/fish/palettes/micrographics.fish" "$BASE/fzf/fish/exports.fish" "$BASE/micrographics/activate.fish"
fish --no-config -c 'source ~/.config/micrographics/activate.fish; test "$BAT_THEME" = Micrographics; printf "x\n" | fzf --filter x >/dev/null'
YAZI_CONFIG_HOME="$BASE/yazi" yazi --debug > "$TMP/yazi" 2>&1
grep -q '/yazi/init.lua' "$TMP/yazi"
grep -q '/yazi/theme.toml' "$TMP/yazi"
! grep -Eqi 'invalid theme|failed to load|parse error' "$TMP/yazi"
ZELLIJ_CONFIG_FILE="$BASE/zellij/config.kdl" zellij setup --check > "$TMP/zellij" 2>&1
grep -q 'Well defined' "$TMP/zellij"
ZELLIJ_CONFIG_FILE="$BASE/zellij/config.kdl" zellij setup --dump-layout default >/dev/null
ZELLIJ_CONFIG_FILE="$BASE/zellij/config.kdl" zellij setup --dump-layout micrographics >/dev/null

POSTING_PYTHON="$(head -1 "$(command -v posting)" | sed 's/^#!//')"
"$POSTING_PYTHON" - "$BASE/posting/themes/micrographics.yaml" <<'PY'
import sys
from pathlib import Path
from posting.themes import load_user_theme
assert load_user_theme(Path(sys.argv[1])).name == "micrographics"
PY

printf '%s\n' 'Micrographics defaults: OK'
