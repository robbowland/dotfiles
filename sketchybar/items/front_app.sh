#!/bin/bash

FRONT_APP_SCRIPT='source "$HOME/.config/sketchybar/icon_map.sh"; FOCUSED="${INFO:-}"; if [ -z "$FOCUSED" ]; then FOCUSED="$(yabai -m query --windows --window 2>/dev/null | jq -r ".app // empty")"; fi; [ -n "$FOCUSED" ] || exit 0; ICON="$(__icon_map "$FOCUSED")"; sketchybar --set "$NAME" label="$ICON" label.drawing=on'

yabai_stack_icon=(
  script="$PLUGIN_DIR/yabai.sh"
  updates=on
  drawing=off
  label.font="sketchybar-app-font:Regular:20.0"
  label.color=$ORANGE
  label.padding_right=5
  label.padding_left=5
  label=:terminal:
  width=30
  display=1
)

yabai_stack_count=(
  script="$PLUGIN_DIR/yabai.sh"
  updates=on
  drawing=off
  label.font="$FONT:ExtraBold:15.0"
  label.color=$WHITE
  label.padding_right=5
  padding_right=7
  display=1
  y_offset=-1
)

right_items=()

front_app=(
  script="$FRONT_APP_SCRIPT"
  label.font="sketchybar-app-font:Regular:20.0"
  label.color=$WHITE
  label.padding_right=5
  label.padding_left=5
  width=30
  display=1
)

other_apps=(
  label.font="sketchybar-app-font:Regular:15.0"
  label.color=$GREY
  label.padding_right=5
  padding_right=7
  display=1
  y_offset=-1
)

# TODO(Move elsewhere)
svim=(
  script="$PLUGIN_DIR/svim.sh"
  updates=on
  label.font="$FONT:Bold:16.0"
  icon.font="sketchybar-app-font:Regular:16.0"
  # icon.width=50
  align=left
  # padding_right=5
  # icon.padding_left=8
  # label.padding_left=-18
  # label.padding_right=10
)

sketchybar --add event window_focus \
  --add item front_app right \
  --set front_app "${front_app[@]}" \
  --subscribe front_app front_app_switched \
  --add item other_apps right \
  --set other_apps "${other_apps[@]}" \
  --subscribe other_apps front_app_switched \
  --add item yabai_stack_icon right \
  --set yabai_stack_icon "${yabai_stack_icon[@]}" \
  --subscribe yabai_stack_icon window_focus \
                               mouse.clicked \
                               mouse.scrolled \
                               window_created \
                               window_destroyed \
                               space_change \
                               space_windows_change \
                               front_app_switched \
  --add item yabai_stack_count right \
  --set yabai_stack_count "${yabai_stack_count[@]}" \
  --subscribe yabai_stack_count window_focus \
                                mouse.clicked \
                                mouse.scrolled \
                                window_created \
                                window_destroyed \
                                space_change \
                                space_windows_change \
                                front_app_switched \
  --add event svim_update \
  --add item svim right \
  --set svim "${svim[@]}" \
  --subscribe svim svim_update \
  --add bracket right_items front_app other_apps yabai_stack_icon yabai_stack_count svim \
  --set right_items background.color=$BLACK \
                    background.corner_radius=12 \
                    background.height=35 \
                    background.border_width=2
