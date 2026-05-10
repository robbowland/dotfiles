#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/icon_map.sh"

window_state() {
  WINDOW=$(yabai -m query --windows --window 2>/dev/null) || return
  [ -n "$WINDOW" ] || return

  CURRENT=$(echo "$WINDOW" | jq -r '.["stack-index"] // 0')

  args=()
  if [[ $CURRENT -gt 0 ]]; then
    APP=$(echo "$WINDOW" | jq -r '.app // empty')
    ICON="$(__icon_map "$APP")"
    LAST=$(yabai -m query --windows --window stack.last 2>/dev/null | jq -r '.["stack-index"] // empty')
    [ -n "$LAST" ] || return
    args+=(
      --set yabai_stack_icon
      label="$ICON"
      label.drawing=on
      drawing=on
      --set yabai_stack_count
      label=$(printf "%s/%s" "$CURRENT" "$LAST")
      label.drawing=on
      drawing=on
    )
  else
    args+=(
      --set yabai_stack_icon
      label.drawing=off
      drawing=off
      --set yabai_stack_count
      label.drawing=off
      drawing=off
    )
  fi

  sketchybar -m "${args[@]}"
}

windows_on_spaces () {
  # Need to split this using `tr` as it's returned as a single line
  CURRENT_SPACES="$(yabai -m query --displays | jq -r '.[].spaces | @sh' | tr ' ' '\n')"

  args=(--set spaces_bracket drawing=off --set '/space\..*/' background.drawing=on)
  while read -r line
  do
    for space in $line
    do
      icon_strip=" "
      apps=$(yabai -m query --windows --space "$space" 2>/dev/null | jq -r ".[].app")
      if [ "$apps" != "" ]; then
        while IFS= read -r app; do
          icon_strip+=" $(__icon_map "$app")"
        done <<< "$apps"
      fi
      args+=(--set other_apps label="$icon_strip" label.drawing=on)
    done
  done <<< "$CURRENT_SPACES"

  sketchybar -m "${args[@]}"
}

inactive_windows_on_current_space () {
  # Query the current space and focused window
  CURRENT_SPACE=$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty') || return
  [ -n "$CURRENT_SPACE" ] || return

  if [ "$SENDER" = "front_app_switched" ] && [ -n "${INFO:-}" ]; then
    FOCUSED_APP="$INFO"
  else
    FOCUSED_APP=$(yabai -m query --windows --window 2>/dev/null | jq -r '.app // empty') || return
  fi
  [ -n "$FOCUSED_APP" ] || return

  # Fetch app names on the current space, excluding the focused app
  WINDOWS=$(yabai -m query --windows --space "$CURRENT_SPACE" 2>/dev/null) || return
  apps=$(printf '%s\n' "$WINDOWS" | jq -r ".[].app" | grep -F -x -v "$FOCUSED_APP" | sort -u)

  # Build the icon strip with non-focused apps
  icon_strip="•"
  if [ "$apps" != "" ]; then
    icon_strip=""
    while IFS= read -r app; do
      icon_strip+=" $(__icon_map "$app")"
    done <<< "$apps"
  fi

  # Update the label in sketchybar with non-focused icons
  sketchybar -m --set other_apps label="$icon_strip" label.drawing=on
}

mouse_clicked() {
  if yabai -m query --windows --window 2>/dev/null | jq -e '.["stack-index"] > 0' >/dev/null; then
    yabai -m window --focus stack.next || yabai -m window --focus stack.first
  else
    yabai -m window --toggle float
  fi
  window_state
}

mouse_scrolled() {
  if [ "${SCROLL_DIRECTION:-}" = "up" ]; then
    yabai -m window --focus stack.prev || yabai -m window --focus stack.last
  else
    yabai -m window --focus stack.next || yabai -m window --focus stack.first
  fi

  window_state
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  "mouse.scrolled") mouse_scrolled
  ;;
  "forced") exit 0
  ;;
  "window_focus") window_state
  ;;
  "window_created") window_state
  ;;
  "window_destroyed") window_state
  ;;
  "windows_on_spaces") windows_on_spaces
  ;;
  "space_windows_change") inactive_windows_on_current_space
  ;;
  "space_change") inactive_windows_on_current_space
  ;;
  "front_app_switched") inactive_windows_on_current_space
  ;;
esac
