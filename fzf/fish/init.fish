if command -v fzf >/dev/null
    # Fish's generated CTRL-R widget adds `--color=always`, which leaves
    # command text ANSI-styled and unreadable on our inverted selection row.
    fzf --fish \
        | string replace -a -- 'set -a -- FZF_DEFAULT_COMMAND "--color=always"' '' \
        | source
end
