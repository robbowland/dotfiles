# Micrographics terminal suite

This is an opt-in terminal profile. It does not change the active GitHub Dark configurations.

## Start it

- Run `micrographics-terminal` for a new Ghostty window with the full terminal palette and shell profile.
- Run `micrographics-shell` to try the shell and tool themes inside the current terminal window.
- Run `exit` to return to the previous shell. Existing windows and normal shell launches stay on the current themes.

## Covered surfaces

- Ghostty terminal and ANSI palette
- Fish syntax and pager completion
- Starship prompt
- fzf search
- bat and shared TextMate syntax for Yazi and GitUI
- Yazi file manager
- Zellij multiplexer and status layout
- eza and `LS_COLORS`
- delta, GitUI, Serie, and gh-dash Git surfaces
- Posting API client
- Pi and Neovim already use their separate Micrographics themes

The shared dark palette is `#000000` paper, `#ffffff` ink, `#999999` metadata, `#616161` faint scaffolding, `#ff3b2f` danger, and `#303030` only where a tool cannot safely render pure reverse selection.

## Individual previews

```sh
BAT_THEME=Micrographics bat path/to/file
YAZI_CONFIG_HOME="$HOME/.config/yazi/profiles/micrographics" yazi
STARSHIP_CONFIG="$HOME/.config/starship/themes/micrographics.toml" starship prompt
ZELLIJ_CONFIG_FILE="$HOME/.config/zellij/profiles/micrographics.kdl" zellij
GH_DASH_CONFIG="$HOME/.config/gh-dash/micrographics.yml" gh-dash
POSTING_CONFIG_FILE="$HOME/.config/posting/profiles/micrographics.yaml" posting
SERIE_CONFIG_FILE="$HOME/.config/serie/micrographics.toml" serie
```

GitUI uses `gitui --theme micrographics.ron`. Delta uses `DELTA_FEATURES=micrographics`.

## Validate

Run `~/.config/micrographics/check.sh`. The check verifies the theme formats, installed loaders, allowed palette, optional profiles, and that the active theme selectors still point at the existing themes.
