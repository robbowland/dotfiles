#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/yabai-stacking-tests.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT INT TERM

fail() {
  printf >&2 'FAIL: %s\n' "$1"
  exit 1
}

assert_files_equal() {
  expected="$1"
  actual="$2"
  message="$3"

  if ! diff -u "$expected" "$actual"; then
    fail "$message"
  fi
}

test_whole_space_rearms_stack_insertion() {
  scenario="$tmp_dir/whole-space"
  mkdir -p "$scenario/bin"
  log="$scenario/yabai.log"
  : > "$log"

  cat > "$scenario/bin/yabai" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$YABAI_LOG"

if [ "$*" = '-m query --windows --space' ]; then
  cat <<'JSON'
[
  {"id":11,"is-minimized":false,"is-hidden":false,"is-floating":false,"can-move":true,"can-resize":true,"has-ax-reference":true,"role":"AXWindow","subrole":"AXStandardWindow","frame":{"x":0,"y":0}},
  {"id":12,"is-minimized":false,"is-hidden":false,"is-floating":false,"can-move":true,"can-resize":true,"has-ax-reference":true,"role":"AXWindow","subrole":"AXStandardWindow","frame":{"x":100,"y":0}},
  {"id":13,"is-minimized":false,"is-hidden":false,"is-floating":false,"can-move":true,"can-resize":true,"has-ax-reference":true,"role":"AXWindow","subrole":"AXStandardWindow","frame":{"x":0,"y":100}},
  {"id":14,"is-minimized":false,"is-hidden":false,"is-floating":false,"can-move":true,"can-resize":true,"has-ax-reference":true,"role":"AXWindow","subrole":"AXStandardWindow","frame":{"x":100,"y":100}}
]
JSON
fi
SH

  cat > "$scenario/bin/sketchybar" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$scenario/bin/yabai" "$scenario/bin/sketchybar"

  PATH="$scenario/bin:$PATH" YABAI_LOG="$log" \
    "$repo_root/skhd/scripts/enter-stack-layout"

  cat > "$scenario/expected.log" <<'LOG'
-m query --windows --space
-m window 11 --insert stack
-m window 12 --warp 11
-m window 11 --insert stack
-m window 13 --warp 11
-m window 11 --insert stack
-m window 14 --warp 11
-m window 11 --focus
LOG

  assert_files_equal "$scenario/expected.log" "$log" \
    'whole-space stacking must re-arm insertion before every warp'
}

test_whole_space_rearms_stack_insertion
printf 'PASS: yabai stacking tests\n'
