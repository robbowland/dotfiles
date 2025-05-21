#!/bin/bash

FRONT_APP_SCRIPT='source "$HOME/.config/sketchybar/icon_map.sh"; FOCUSED="$(yabai -m query --windows --window | jq -r '.app')"; ICON="$(__icon_map "$FOCUSED")"; sketchybar --set $NAME label="$ICON" label.drawing=on'

yabai=(
  script="$PLUGIN_DIR/yabai.sh"
  updates=on
  drawing=off
  icon.font="$FONT:Bold:20.0"
  icon.width=30
  icon=$YABAI_GRID
  icon.color=$ORANGE
  associated_display=active
)

right_items=()

front_app=(
  script="$FRONT_APP_SCRIPT"
  label.font="sketchybar-app-font:Regular:20.0"
  label.color=$WHITE
  label.padding_right=5
  label.padding_left=5
  width=30
  associated_display=active
)

other_apps=(
  label.font="sketchybar-app-font:Regular:15.0"
  label.color=$GREY
  label.padding_right=5
  padding_right=7
  associated_display=active
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

sketchybar --add event window_focus             \
           --add item yabai left                \
           --set yabai "${yabai[@]}"           \
           --subscribe yabai window_focus      \
                             mouse.clicked     \
            			     space_change \
            			     space_windows_change \
            			     front_app_switched \
                	   \
	    --add item front_app right          \
        --set front_app "${front_app[@]}"   \
        --subscribe front_app front_app_switched \
                    		  space_windows_change \
                    		  space_change \
	    --add item other_apps right \
        --set other_apps "${other_apps[@]}"   \
        --subscribe other_apps front_app_switched \
	  \
        --add event svim_update \
        --add item svim right   \
        --set svim "${svim[@]}" \
        --subscribe svim svim_update \
	  --add bracket right_items front_app other_apps svim \
	  --set         right_items background.color=$BLACK \
                                background.corner_radius=12  \
                                background.height=35 \
                                background.border_width=2
