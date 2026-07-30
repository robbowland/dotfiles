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

test_directional_stack_moves_focused_window() {
  scenario="$tmp_dir/directional"
  mkdir -p "$scenario/bin"
  log="$scenario/yabai.log"
  : > "$log"

  cat > "$scenario/bin/yabai" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$YABAI_LOG"

case "$*" in
  '-m query --windows --window')
    printf '{"id":101}\n'
    ;;
  '-m query --windows --window west')
    [ "${YABAI_NO_NEIGHBOR:-}" != west ] || exit 1
    printf '{"id":201}\n'
    ;;
  '-m query --windows --window south')
    [ "${YABAI_NO_NEIGHBOR:-}" != south ] || exit 1
    printf '{"id":202}\n'
    ;;
  '-m query --windows --window north')
    [ "${YABAI_NO_NEIGHBOR:-}" != north ] || exit 1
    printf '{"id":203}\n'
    ;;
  '-m query --windows --window east')
    [ "${YABAI_NO_NEIGHBOR:-}" != east ] || exit 1
    printf '{"id":204}\n'
    ;;
esac
SH
  chmod +x "$scenario/bin/yabai"

  for direction_and_target in 'west 201' 'south 202' 'north 203' 'east 204'; do
    set -- $direction_and_target
    direction="$1"
    target="$2"

    PATH="$scenario/bin:$PATH" YABAI_LOG="$log" \
      "$repo_root/skhd/scripts/stack-window" "$direction"

    cat >> "$scenario/expected.log" <<LOG
-m query --windows --window
-m query --windows --window $direction
-m window $target --insert stack
-m window 101 --warp $target
-m window 101 --focus
LOG
  done

  assert_files_equal "$scenario/expected.log" "$log" \
    'directional stacking must resolve both windows, move the source, and restore focus'
}

test_missing_directional_neighbour_is_noop() {
  scenario="$tmp_dir/no-neighbour"
  mkdir -p "$scenario/bin"
  log="$scenario/yabai.log"
  : > "$log"

  cat > "$scenario/bin/yabai" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$YABAI_LOG"

case "$*" in
  '-m query --windows --window') printf '{"id":101}\n' ;;
  '-m query --windows --window east') exit 1 ;;
esac
SH
  chmod +x "$scenario/bin/yabai"

  PATH="$scenario/bin:$PATH" YABAI_LOG="$log" \
    "$repo_root/skhd/scripts/stack-window" east

  cat > "$scenario/expected.log" <<'LOG'
-m query --windows --window
-m query --windows --window east
LOG

  assert_files_equal "$scenario/expected.log" "$log" \
    'a missing neighbour must not mutate the layout'
}

test_invalid_direction_fails() {
  if "$repo_root/skhd/scripts/stack-window" diagonal >/dev/null 2>&1; then
    fail 'an invalid stack direction must fail'
  fi
}

test_whole_space_rearms_stack_insertion
test_directional_stack_moves_focused_window
test_missing_directional_neighbour_is_noop
test_invalid_direction_fails
printf 'PASS: yabai stacking tests\n'
