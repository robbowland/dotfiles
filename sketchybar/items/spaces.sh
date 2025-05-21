#!/bin/bash

SPACE_ICONS=("1" "2" "3" "4" "5" "•" "•" "•" "•" "•" "•" "•" "•" "•" "•")

# Destroy space on right click, focus space on left click.
# New space by left clicking separator (>)

sid=0
spaces=()
for i in "${!SPACE_ICONS[@]}"; do
	sid=$(($i + 1))

	space=(
	    icon.font="$FONT:ExtraBold:15.0"
		associated_space=$sid
		icon="${SPACE_ICONS[i]}"
		icon.padding_left=10
		icon.padding_right=10
		padding_left=2
		padding_right=2
		icon.color=$GREY
		icon.highlight_color=$WHITE
		label.color=$GREY
		label.highlight_color=$WHITE
		label.y_offset=-1
		background.color=$BLACK
		background.border_color=$BACKGROUND_2
		background.drawing=off
		label.drawing=off
		script="$PLUGIN_DIR/space.sh"
		updates=on
	)

	sketchybar --add space space.$sid left \
		       --set space.$sid "${space[@]}" \
		   --subscribe space.$sid mouse.clicked
done

spaces_bracket=(
	background.color=$BLACK
	background.border_color=$BACKGROUND_2
	background.border_width=0
)

separator=(
	icon=􀆊
	icon.font="$FONT:Heavy:16.0"
	padding_left=10
	padding_right=8
	label.drawing=off
	associated_display=active
	click_script='yabai -m space --create && sketchybar --trigger space_change'
	icon.color=$WHITE
)

yabai=(
	script="$PLUGIN_DIR/yabai.sh"
	updates=on
	drawing=off
	icon.font="$FONT:Bold:16.0"
	label.drawing=off
	icon.width=30
	icon=$YABAI_GRID
	icon.color=$ORANGE
	associated_display=active
)

sketchybar --add bracket spaces '/space\..*/'               \
	       --set         spaces background.color=$BLACK \
                         background.corner_radius=12  \
                         background.height=35 \
                         background.border_width=2



# --add item separator left                   \
# --set separator "${separator[@]}"
