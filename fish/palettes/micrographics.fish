#!/bin/fish

# Default Micrographics palette: pure invert, two scaffold tiers, and semantic accents.
set -gx MG_PAPER '#000000'
set -gx MG_INK '#ffffff'
set -gx MG_METADATA '#999999'
set -gx MG_FAINT '#616161'
set -gx MG_SUCCESS '#34c759'
set -gx MG_DANGER '#ff3b2f'
set -gx MG_SELECTION '#303030'

# Compatibility aliases for palette-driven dotfile templates.
set -gx PALETTE_BLACK_BRIGHT $MG_SELECTION
set -gx PALETTE_BLACK $MG_PAPER
set -gx PALETTE_BLACK_DIM $MG_PAPER
set -gx PALETTE_WHITE_BRIGHT $MG_INK
set -gx PALETTE_WHITE $MG_INK
set -gx PALETTE_WHITE_DIM $MG_METADATA
set -gx PALETTE_GRAY_BRIGHT $MG_METADATA
set -gx PALETTE_GRAY $MG_METADATA
set -gx PALETTE_GRAY_DIM $MG_FAINT
set -gx PALETTE_SURFACE_0 $MG_SELECTION
set -gx PALETTE_SURFACE_1 $MG_SELECTION
set -gx PALETTE_SURFACE_2 $MG_SELECTION

for role in BLUE CYAN YELLOW MAGENTA ORANGE PINK
    set -gx PALETTE_{$role}_BRIGHT $MG_INK
    set -gx PALETTE_$role $MG_METADATA
    set -gx PALETTE_{$role}_DIM $MG_FAINT
end

set -gx PALETTE_GREEN_BRIGHT $MG_SUCCESS
set -gx PALETTE_GREEN $MG_SUCCESS
set -gx PALETTE_GREEN_DIM $MG_SUCCESS

set -gx PALETTE_RED_BRIGHT $MG_DANGER
set -gx PALETTE_RED $MG_DANGER
set -gx PALETTE_RED_DIM $MG_DANGER
