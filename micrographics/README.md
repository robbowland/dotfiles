# Micrographics terminal suite

Micrographics is the default theme across the terminal stack. Fish loads `activate.fish` for shell-level integrations, while each tool also selects Micrographics in its normal config so direct launches remain consistent.

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
- Pi and Neovim use their separate Micrographics themes

The shared dark palette is `#000000` paper, `#ffffff` ink, `#999999` metadata, `#616161` faint scaffolding, `#ff3b2f` danger, and `#303030` only where a tool cannot safely render pure reverse selection.

## Theme generation

The generated defaults continue to use the repository's existing simple theme pipeline:

```sh
~/.config/.scripts/theme/gen_themes.sh
```

`micrographics/palette.env` supplies the default `PALETTE_*` values. Module templates remain the source of truth for Delta, GitUI, Serie, Starship, Yazi, and Zellij; their `.scripts/gen_theme.sh` wrappers produce both the normal config and any compatibility profile.

`micrographics-shell` and `micrographics-terminal` remain available as compatibility launchers, but normal Fish and Ghostty sessions are already themed.

## Validate

Run `~/.config/micrographics/check.sh`. The check verifies generated-file parity, active selectors, theme formats, installed loaders, and the fixed palette contract.
