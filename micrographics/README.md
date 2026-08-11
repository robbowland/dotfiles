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
- delta, GitUI, Hunk, Serie, and gh-dash Git surfaces
- Posting API client
- tuicr code review TUI
- rainfrog database TUI (via terminal palette; app config stays under `~/.config/rainfrog`)
- Codex CLI syntax and Desktop dark chrome
- Pi and Neovim use their separate Micrographics themes

The shared dark palette is `#000000` paper, `#ffffff` ink, `#999999` metadata, `#404040` faint scaffolding, `#39d97a` success and additions, `#ff3b2f` danger and deletions, and `#303030` only where a tool cannot safely render pure reverse selection.

Diff surfaces remain literal black; green and red are signal colors rather than tinted backgrounds. The shared TextMate inserted and deleted scopes explicitly set black backgrounds, suppressing consumer-specific tint fallbacks, including Codex's.

## Theme generation

The generated defaults continue to use the repository's existing simple theme pipeline:

```sh
~/.config/.scripts/theme/gen_themes.sh
```

`micrographics/palette.env` supplies the default `PALETTE_*` values. Module templates remain the source of truth for Delta, GitUI, Serie, Starship, Yazi, and Zellij; their `.scripts/gen_theme.sh` wrappers produce both the normal config and any compatibility profile.

`micrographics-shell` and `micrographics-terminal` remain available as compatibility launchers, but normal Fish and Ghostty sessions are already themed.

## tuicr

`tuicr/config.toml` selects the local `micrographics` theme, and `tuicr/themes/micrographics.toml` keeps the full UI palette inside the shared terminal contract. The local theme also reuses the shared Bat TextMate file through:

```toml
syntax_theme = "../../bat/themes/Micrographics.tmTheme"
```

so diff/code syntax stays aligned with Bat, GitUI, Yazi previews, and Codex.

## rainfrog

Rainfrog currently supports a managed config file but not a configurable color palette. Micrographics therefore reaches Rainfrog through the terminal palette rather than a Rainfrog-native theme table.

`micrographics/activate.fish` exports:

```fish
set -gx RAINFROG_CONFIG "$HOME/.config/rainfrog"
set -gx RAINFROG_FAVORITES "$HOME/.config/rainfrog/favorites"
```

and the tracked config lives at `rainfrog/rainfrog_config.toml`, so Rainfrog state stays in the dotfiles repo even on macOS where the default would otherwise live under `~/Library/Application Support`.

## Codex

Install the shared TextMate theme:

```bash
~/.config/micrographics/install-codex.sh
```

Then merge the TUI settings into the existing Codex config:

```toml
[tui]
theme = "micrographics"
status_line_use_colors = false
```

The full Desktop tables live in `micrographics/codex.config.toml`. Merge them rather than replacing `~/.codex/config.toml`, which contains machine-local settings. Codex TUI chrome remains terminal-adaptive, while the shared TextMate file controls syntax and theme-derived accents.

## Validate

Run `~/.config/micrographics/check.sh`. The check verifies generated-file parity, active selectors, theme formats, installed loaders, and the fixed palette contract.
