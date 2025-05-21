#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

if [ "$SENDER" = "svim_update" ]; then
  DRAWING=on
  DRAW_CMD=off
  COLOR=$WHITE

  case "$MODE" in
    "I") ICON=":vim_insert_mode:" COLOR=$MAGENTA
    ;;
    "N") ICON=":vim_normal_mode:" COLOR=$CYAN
    ;;
    "V") ICON=":vim_visual_mode:" COLOR=$ORANGE
    ;;
    "C") ICON=":vim_command_mode:" DRAW_CMD=on COLOR=$RED
    ;;
    *) ICON="•"
    ;;
  esac

  # TODO(robbow): Re-arrange to make configureaiton easier e.g. for resizimg
  sketchybar --set $NAME drawing="$DRAWING" \
                         label.drawing="$DRAW_CMD" \
                         icon="$ICON" \
                         icon.font.size=19.0 \
                         icon.color="$COLOR" \
                         label="$CMDLINE"
fi
