#!/bin/sh
# Rex's look, as Ghostty's: what Rex keeps in its Settings (macOS
# preferences) rather than init.lua, which cannot set it. Run on a new
# machine, with Rex open and Remote Control on (Settings, Rex Server) for
# the theme; rerunning is safe. Rex takes each change as it is written.
#
# Not here: the padding, which Rex has no setting for.
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
# Tabs: down the sidebar, on the right.
w tabStyle -string vertical
w sidebarPosition -string right
w sidebarShowsActivity -bool false
w inactivePaneFadeMode -string both
w animationStyle -string snappy
w appearance -string dark
w interfaceStyle -string useTheme

# Theme: Ghostty's Micrographics, for dark. Rex keeps imported themes in its
# settings in a form of its own, so its importer reads the Ghostty file, once:
# a rerun finds the theme by name and only selects it.
theme=Micrographics
theme_id() {
	themes=$(mktemp)
	defaults export com.superlogical.rex - |
		plutil -extract 'Workspace\.customThemes' raw -o - - 2>/dev/null |
		base64 -D >"$themes" 2>/dev/null || true
	i=0
	while name=$(plutil -extract "$i.name" raw -o - "$themes" 2>/dev/null); do
		if [ "$name" = "$theme" ]; then
			plutil -extract "$i.id" raw -o - "$themes"
			break
		fi
		i=$((i + 1))
	done
	rm -f "$themes"
}
id=$(theme_id)
if [ -z "$id" ]; then
	rex do client.theme.import path="$HOME/.config/ghostty/themes/$theme" >/dev/null ||
		{ echo "settings.sh: open Rex with Remote Control on (Settings, Rex Server) to import its theme" >&2; exit 1; }
	id=$(theme_id)
fi
[ -n "$id" ] || { echo "settings.sh: Rex did not keep the $theme theme" >&2; exit 1; }
w darkThemeID -string "$id"
