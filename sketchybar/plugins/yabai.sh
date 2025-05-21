#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/icon_map.sh"

window_state() {
  WINDOW=$(yabai -m query --windows --window)
  CURRENT=$(echo "$WINDOW" | jq '.["stack-index"]')

  args=()
  if [[ $CURRENT -gt 0 ]]; then
    LAST=$(yabai -m query --windows --window stack.last | jq '.["stack-index"]')
    args+=(--set $NAME icon=$YABAI_STACK icon.color=$RED label.drawing=on drawing=on label=$(printf "[%s/%s]" "$CURRENT" "$LAST")
          --bar border_color=$RED)
  else
    args+=(--set $NAME label.drawing=off drawing=off)
    COLOR=$BAR_BORDER_COLOR
    ICON=$YABAI_GRID
    case "$(echo "$WINDOW" | jq '.["is-floating"]')" in
      "false")
        if [ "$(echo "$WINDOW" | jq '.["has-fullscreen-zoom"]')" = "true" ]; then
          ICON=$YABAI_FULLSCREEN_ZOOM
          COLOR=$GREEN
        elif [ "$(echo "$WINDOW" | jq '.["has-parent-zoom"]')" = "true" ]; then
          ICON=$YABAI_PARENT_ZOOM
          COLOR=$BLUE
        fi
        ;;
      "true")
        ICON=$YABAI_FLOAT
        COLOR=$MAGENTA
        ;;
    esac
    args+=(--animate sin 10 --bar border_color=$COLOR)
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
      echo "$space"
      icon_strip=" "
      apps=$(yabai -m query --windows --space $space | jq -r ".[].app")
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
  CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r '.index')
  FOCUSED_APP=$(yabai -m query --windows --window | jq -r '.app')

  # Fetch app names on the current space, excluding the focused app
  apps=$(yabai -m query --windows --space "$CURRENT_SPACE" | jq -r ".[].app" | grep -v "$FOCUSED_APP" | sort | uniq)

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
  yabai -m window --toggle float
  window_state
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  "forced") exit 0
  ;;
  "window_focus") window_state
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
