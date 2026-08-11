#!/bin/sh
set -eu

BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
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
grep -q '^theme = "micrographics"$' "$BASE/tuicr/config.toml"
grep -q '^transparent_background = false$' "$BASE/tuicr/config.toml"
grep -q '^set -gx RAINFROG_CONFIG "$HOME/.config/rainfrog"$' "$BASE/micrographics/activate.fish"
grep -q '^set -gx RAINFROG_FAVORITES "$HOME/.config/rainfrog/favorites"$' "$BASE/micrographics/activate.fish"
grep -q '^theme = "custom"$' "$BASE/hunk/config.toml"
grep -q '^label = "Micrographics"$' "$BASE/hunk/config.toml"
grep -q '^addedSignColor = "#39d97a"$' "$BASE/hunk/config.toml"
grep -q '^plus-style = "syntax #39d97a"$' "$BASE/delta/config"
grep -q 'diff_line_add:.*Some("#39d97a")' "$BASE/gitui/theme.ron"
grep -q 'micrographics/activate.fish' "$BASE/fish/config.fish"
cmp -s "$BASE/gh-dash/config.yml" "$BASE/gh-dash/micrographics.yml"
cmp -s "$BASE/posting/config.yaml" "$BASE/posting/profiles/micrographics.yaml"
cmp -s "$BASE/yazi/init.lua" "$BASE/yazi/profiles/micrographics/init.lua"
"$BASE/micrographics/tests/install-codex.test.sh" >/dev/null
test -L "$CODEX_DIR/themes/micrographics.tmTheme"
test "$CODEX_DIR/themes/micrographics.tmTheme" -ef \
  "$BASE/bat/themes/Micrographics.tmTheme"

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
plutil -lint "$CODEX_DIR/themes/micrographics.tmTheme" >/dev/null
python3 - "$BASE" "$CODEX_DIR" <<'PY'
import pathlib, plistlib, re, sys, tomllib
base = pathlib.Path(sys.argv[1])
codex_home = pathlib.Path(sys.argv[2])
canonical_green = "#39d97a"
shared_allowed = {"#000000", "#ffffff", "#999999", "#404040", canonical_green, "#ff3b2f", "#303030"}
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
    base / "hunk/config.toml",
    base / "gh-dash/config.yml",
    base / "serie/config.toml",
    base / "posting/themes/micrographics.yaml",
    base / "tuicr/themes/micrographics.toml",
    base / "micrographics/codex.config.toml",
]
for path in paths:
    colors = {c.lower() for c in re.findall(r"#[0-9a-fA-F]{6}", path.read_text())}
    unexpected = colors - shared_allowed
    if unexpected:
        raise SystemExit(f"{path}: unexpected colors {sorted(unexpected)}")

palette = dict(
    line.split("=", 1)
    for line in (base / "micrographics/palette.env").read_text().splitlines()
    if "=" in line
)
for role in ["PALETTE_GREEN_BRIGHT", "PALETTE_GREEN", "PALETTE_GREEN_DIM"]:
    assert palette.get(role) == canonical_green, f"{role} must use canonical green"

ghostty_palette = {}
for line in (base / "ghostty/themes/Micrographics").read_text().splitlines():
    if not re.match(r"^\s*palette\s*=", line):
        continue
    match = re.fullmatch(r"\s*palette\s*=\s*(\d+)\s*=\s*(#[0-9a-fA-F]{6})\s*", line)
    assert match, f"invalid Ghostty palette assignment: {line}"
    slot, color = match.groups()
    slot = int(slot)
    assert slot not in ghostty_palette, f"duplicate Ghostty palette slot {slot}"
    ghostty_palette[slot] = color.lower()
for slot in [2, 10]:
    assert ghostty_palette.get(slot) == canonical_green, \
        f"Ghostty palette slot {slot} must use canonical green"

with (base / "bat/themes/Micrographics.tmTheme").open("rb") as file:
    textmate = plistlib.load(file)
global_settings = [
    item["settings"]
    for item in textmate["settings"]
    if not item.get("scope") and "lineDiffAdded" in item.get("settings", {})
]
assert len(global_settings) == 1, "Bat must have one global lineDiffAdded setting"
assert global_settings[0]["lineDiffAdded"] == canonical_green, \
    "Bat lineDiffAdded must use canonical green"

def scope_settings(scope):
    matches = [
        item["settings"]
        for item in textmate["settings"]
        if scope in {part.strip() for part in item.get("scope", "").split(",")}
    ]
    assert len(matches) == 1, f"Bat must have one {scope} TextMate setting"
    return matches[0]

inserted = scope_settings("markup.inserted")
deleted = scope_settings("markup.deleted")
assert inserted["foreground"] == canonical_green, \
    "Bat markup.inserted foreground must use canonical green"
assert inserted["background"] == "#000000", \
    "Bat markup.inserted background must use literal black"
assert deleted["foreground"] == "#ff3b2f", \
    "Bat markup.deleted foreground must use canonical red"
assert deleted["background"] == "#000000", \
    "Bat markup.deleted background must use literal black"

toml_paths = [
    base / "starship/starship.toml",
    base / "yazi/theme.toml",
    base / "serie/config.toml",
    base / "hunk/config.toml",
    base / "tuicr/config.toml",
    base / "tuicr/themes/micrographics.toml",
    base / "rainfrog/rainfrog_config.toml",
]
parsed = {path: tomllib.loads(path.read_text()) for path in toml_paths}
hunk = parsed[base / "hunk/config.toml"]["custom_theme"]
for key in [
    "addedBg",
    "removedBg",
    "movedAddedBg",
    "movedRemovedBg",
    "addedContentBg",
    "removedContentBg",
]:
    assert hunk[key] == "#000000", f"Hunk {key} must use literal black"
for key in ["addedSignColor", "badgeAdded", "fileNew", "fileUntracked"]:
    assert hunk[key] == canonical_green, f"Hunk {key} must use canonical green"
for key in ["removedSignColor", "badgeRemoved", "fileDeleted"]:
    assert hunk[key] == "#ff3b2f", f"Hunk {key} must use canonical red"
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

tuicr_config = parsed[base / "tuicr/config.toml"]
assert tuicr_config["theme"] == "micrographics", "tuicr must select the local Micrographics theme"
assert tuicr_config["transparent_background"] is False, "tuicr must paint the configured panel background"
assert tuicr_config["comment_types"][0]["color"] == "#ffffff"
assert tuicr_config["comment_types"][2]["color"] == "#ff3b2f"
assert tuicr_config["comment_types"][4]["color"] == canonical_green

tuicr_theme = parsed[base / "tuicr/themes/micrographics.toml"]
assert tuicr_theme["syntax_theme"] == "../../bat/themes/Micrographics.tmTheme", \
    "tuicr must reuse the shared Bat TextMate theme"
assert tuicr_theme["panel_bg"] == "#000000"
assert tuicr_theme["diff_add"] == canonical_green
assert tuicr_theme["diff_del"] == "#ff3b2f"
assert tuicr_theme["mode_bg"] == "#ffffff"

rainfrog = parsed[base / "rainfrog/rainfrog_config.toml"]
assert rainfrog["settings"]["mouse_mode"] is True
assert rainfrog["settings"]["autopairs_enabled"] is True
assert rainfrog["db"] == {}, "rainfrog db block should stay empty until explicit connections are added"

expected_tui = {
    "theme": "micrographics",
    "status_line_use_colors": False,
}
expected_desktop = {
    "accent": "#ffffff",
    "contrast": 60,
    "ink": "#ffffff",
    "opaqueWindows": True,
    "surface": "#000000",
}
expected_semantic = {
    "diffAdded": canonical_green,
    "diffRemoved": "#ff3b2f",
    "skill": "#ffffff",
}

def assert_values(actual, expected, label):
    for key, value in expected.items():
        assert actual.get(key) == value, f"{label}: unexpected {key}"

fragment = tomllib.loads((base / "micrographics/codex.config.toml").read_text())
fragment_desktop = fragment["desktop"]["appearanceDarkChromeTheme"]
assert fragment["tui"] == expected_tui, "tracked fragment: unexpected [tui] settings"
assert_values(fragment_desktop, expected_desktop, "tracked fragment Desktop chrome")
assert fragment_desktop["semanticColors"] == expected_semantic, \
    "tracked fragment: unexpected Desktop semantic colors"
assert set(fragment_desktop) == {*expected_desktop, "semanticColors"}, \
    "tracked fragment: unexpected Desktop keys"

live = tomllib.loads((codex_home / "config.toml").read_text())
live_desktop = live["desktop"]["appearanceDarkChromeTheme"]
assert_values(live["tui"], expected_tui, "live Codex [tui]")
assert_values(live_desktop, expected_desktop, "live Codex Desktop chrome")
assert_values(live_desktop["semanticColors"], expected_semantic, \
    "live Codex Desktop semantic colors")
PY
ruby - "$BASE/gh-dash/config.yml" \
  "$BASE/posting/themes/micrographics.yaml" \
  "$BASE/posting/config.yaml" <<'RUBY'
require "yaml"
canonical_green = "#39d97a"
gh_dash, posting_theme, = ARGV.map do |path|
  YAML.safe_load(File.read(path), permitted_classes: [], aliases: false)
end
raise "gh-dash success must use canonical green" unless
  gh_dash.dig("theme", "colors", "text", "success") == canonical_green
raise "Posting success must use canonical green" unless
  posting_theme["success"] == canonical_green
RUBY

# Installed loaders and parsers.
codex --strict-config --version >/dev/null
bat cache --build >/dev/null
bat --list-themes | grep -q '^Micrographics$'
printf 'function alpha() { return 1; }\n' > "$TMP/sample.js"
bat --theme Micrographics --color=always --style=plain "$TMP/sample.js" >/dev/null
printf 'theme = Micrographics\n' > "$TMP/ghostty"
ghostty +validate-config --config-file="$TMP/ghostty"
STARSHIP_CONFIG="$BASE/starship/starship.toml" starship print-config >/dev/null
! grep -Eq '\[(DIR|GIT|STA|TME|PY)\]|\$\{count\}' "$BASE/starship/starship.toml"
fish -n "$BASE/fish/config.fish" "$BASE/fish/palettes/micrographics.fish" "$BASE/fzf/fish/exports.fish" "$BASE/micrographics/activate.fish"
fish --no-config -c 'source "$argv[1]"; test "$MG_SUCCESS" = "#39d97a"' \
  "$BASE/fish/palettes/micrographics.fish"
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
