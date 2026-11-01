#!/bin/sh
# Rex's look, as Ghostty's: what Rex keeps in its Settings (macOS
# preferences) rather than init.lua, which cannot set it. Run once on a new
# machine; Rex takes each change as it is written.
#
# Not here: the theme. In Rex's Settings, import Ghostty's
# ~/.config/ghostty/themes/Micrographics (it takes Ghostty's background
# 000000 and foreground ffffff) and use it for dark. Nor the padding, which
# Rex has no setting for.
set -e
w() { defaults write com.superlogical.rex "Workspace.$1" "$2" "$3"; }

# Font: JetBrainsMono Nerd Font Mono at 16, smoothed (Ghostty's font-thicken).
w terminalFontName -string "JetBrainsMono Nerd Font Mono"
w terminalFontPointSize -float 16
w terminalFontSmoothing -bool true
# Option sends Alt (Ghostty's macos-option-as-alt): weaver's alt+ keys.
w terminalOptionKeyBehavior -string actsAsAlt
w terminalCursorStyle -string bar

# Chrome: as little as there is (Ghostty's hidden titlebar).
defaults write com.superlogical.rex Workspace.hiddenPaneButtons -array splitRight splitDown float zoom close
defaults write com.superlogical.rex Workspace.hiddenChromeButtons -array activity commandPalette newTab
w showsPaneHeaders -bool false
w showsActivePaneBorder -bool false
w tabIconColorMode -string never
w bouncesTabIcons -bool false
w appIconVisibility -string menuBarOnly
w paneDensity -string compact
w sidebarPosition -string right
w sidebarShowsActivity -bool false
w inactivePaneFadeMode -string both
w animationStyle -string snappy
w appearance -string dark
w interfaceStyle -string useTheme
