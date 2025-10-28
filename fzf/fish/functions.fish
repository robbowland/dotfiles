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
        --bind=alt-p:toggle-preview \
        --preview-window=right:60%:border-rounded \
        --preview 'bash -lc "git log --color=always -n 10 {} | bat --plain --language=diff --color=always"')
    test -n "$branch"; and git checkout "$branch"
end

#######################################
# Fuzzy-select a git commit and show its diff.
#######################################
####
# fzf_git_show_commit
# Fuzzy-select one or two commits (use <Tab> to multi-select):
#  - Single commit → show its diff and copy hash to clipboard (gray status)
#  - Two commits   → show diff between them and copy "old..new" to clipboard
####
####
# fzf_git_show_commit
# Fuzzy-select one or two commits (use <Tab> to multi-select):
#  - Single commit → show its diff and copy hash to clipboard (gray status)
#  - Two commits   → show diff between them and copy "old..new" to clipboard
####
####
# fzf_git_show_commit
# Fuzzy-select one or two commits (use <Tab> to multi-select):
#  - Single commit → show its diff and copy short hash to clipboard (gray status)
#  - Two commits   → show diff between them and copy "old..new" to clipboard
####
function fzf_git_show_commit --description "View or diff git commits with bat; copies hash or range"
    set -l selection (
    git log \
      --pretty=format:'%h%x09%C(yellow)%h%Creset %Cblue%ad%Creset %Cgreen%an%Creset %s' \
      --date=relative --abbrev-commit --color=always \
    | fzf \
        --ansi \
        --multi \
        --height=45% \
        --layout=default \
        --bind=alt-p:toggle-preview \
        --delimiter='\t' \
        --with-nth=2.. \
        --preview 'git show --color=always {1} | bat --plain --language=diff --color=always' \
        --preview-window=right:60%:border-rounded
  )
    test -z "$selection"; and return

    # Use real tab when splitting
    set -l TAB (printf '\t')

    # Extract short hashes (first field)
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
            printf "%scopied hash: %s%s\n" (set_color brblack) $h (set_color normal)
            git show --color=always $h | bat --plain --language=diff --color=always

        case 2
            set -l old $hashes[2]
            set -l new $hashes[1]
            set -l range "$old..$new"
            echo -n $range | fish_clipboard_copy 2>/dev/null; or echo -n $range | pbcopy 2>/dev/null; or echo -n $range | wl-copy 2>/dev/null; or echo -n $range | xclip -selection clipboard 2>/dev/null
            printf "%scopied range: %s%s\n" (set_color brblack) $range (set_color normal)
            git diff --color=always $old $new | bat --plain --language=diff --color=always

        case '*'
            echo "Select one or two commits only."
    end
end
alias gshow="fzf_git_show_commit"
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
