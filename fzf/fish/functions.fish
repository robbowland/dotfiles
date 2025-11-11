#!/bin/fish

#######################################
# Fuzzy-select a git branch and check it out.
#######################################
function fzf_git_checkout --description "Fuzzy-select a git branch and check it out"
    set -l branch (git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads \
    | fzf \
        --ansi \
        --height=40% \
        --layout=default \
        --bind=ctrl-p:toggle-preview \
        --preview-window=right:60%:border-rounded \
        --preview 'bash -lc "git log --color=always -n 10 {} | bat --plain --language=diff --color=always"')
    test -n "$branch"; and git checkout "$branch"
end

#######################################
# Internal helper for `fzf_git_show_commit*` variants.
# include_author: "with-author" | "no-author"
#######################################
function __fzf_git_show_commit --argument-names include_author
    # First field (before \t) must be the short hash for fzf {1}
    # After the tab: hash (yellow), date (cyan), [author (green)], subject (base)
    set -l log_format "%h%x09%C($PALETTE_YELLOW)%h%Creset  %C($PALETTE_CYAN)%ad%Creset  %s"
    if test "$include_author" = with-author
        set log_format "%h%x09%C($PALETTE_YELLOW)%h%Creset  %C($PALETTE_CYAN)%ad%Creset  %C($PALETTE_GREEN)%an%Creset  %s"
    end

    # Select commits via fzf; show diff/commit on the right
    set -l selection (
        git log \
            --pretty=format:$log_format \
            --date=format:%Y-%m-%d\ %H:%M \
            --abbrev-commit \
            --color=always \
        | fzf \
            --ansi \
            --multi \
            --height=45% \
            --layout=default \
            --bind=ctrl-p:toggle-preview \
            --delimiter='\t' \
            --with-nth=2.. \
            --preview 'git show --color=always {1} | bat --plain --language=diff --color=always' \
            --preview-window=right:60%:border-rounded:hidden
    )
    test -z "$selection"; and return

    # Real tab char for splitting first column
    set -l TAB (printf '\t')

    # Collect selected short hashes (column 1)
    set -l hashes
    for line in (string split -m 0 \n -- $selection)
        set -l h (string split "$TAB" -- $line)[1]
        set -l h (string trim -- $h)
        test -n "$h"; and set -a hashes $h
    end

    switch (count $hashes)
        case 1
            set -l h $hashes[1]
            echo -n $h | fish_clipboard_copy 2>/dev/null; or echo -n $h | pbcopy 2>/dev/null; or echo -n $h | wl-copy 2>/dev/null; or echo -n $h | xclip -selection clipboard 2>/dev/null
            # dim gray notice
            printf "%scopied hash: %s%s\n" (set_color $PALETTE_GRAY_DIM) $h (set_color normal)
            git show --color=always $h | bat --plain --language=diff --color=always

        case 2
            # older first, then newer to form A..B
            set -l old $hashes[2]
            set -l new $hashes[1]
            set -l range "$old..$new"
            echo -n $range | fish_clipboard_copy 2>/dev/null; or echo -n $range | pbcopy 2>/dev/null; or echo -n $range | wl-copy 2>/dev/null; or echo -n $range | xclip -selection clipboard 2>/dev/null
            printf "%scopied range: %s%s\n" (set_color $PALETTE_GRAY_DIM) $range (set_color normal)
            git diff --color=always $old $new | bat --plain --language=diff --color=always

        case '*'
            echo "Select one or two commits only."
    end
end

#######################################
# Fuzzy-select commits showing hash, date, commit message.
#######################################
function fzf_git_show_commit --description "View or diff git commits (hash, date, message)"
    __fzf_git_show_commit no-author
end

#######################################
# Variant showing hash, date, author, commit message.
#######################################
function fzf_git_show_commit_with_author --description "View or diff git commits (hash, date, author, message)"
    __fzf_git_show_commit with-author
end

#######################################
# Setup fzf path & autocompletion.
######################################
function _fzf_setup
    # Ensure fzf is in the PATH
    if not contains /opt/homebrew/opt/fzf/bin $PATH
        set -x PATH $PATH /opt/homebrew/opt/fzf/bin
    end

    # Source fzf completion if interactive
    if status is-interactive
        source /opt/homebrew/opt/fzf/shell/completion.fish 2>/dev/null
    end
end

# Setup fzf
_fzf_setup
