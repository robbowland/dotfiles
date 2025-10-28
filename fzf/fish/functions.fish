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
function fzf_git_show_commit --description "Fuzzy-select a git commit and show its diff"
    set -l sel (
    git log \
      --pretty=format:'%C(yellow)%h%Creset %Cblue%ad%Creset %Cgreen%an%Creset %s' \
      --date=relative --abbrev-commit --color=always \
    | awk '{print $1"\t"$0}' \
    | fzf \
        --ansi \
        --no-sort \
        --height=45% \
        --layout=default \
        --bind=alt-p:toggle-preview \
        --delimiter='\t' \
        --with-nth=2.. \
        --preview 'git show --color=always {1} | bat --plain --language=diff --color=always' \
        --preview-window=right:60%:border-rounded
  )

    test -z "$sel"; and return
    set -l hash (string split "\t" -- $sel)[1]
    git show $hash | bat --plain --language=diff
end
alias gshow="fzf_git_show_commit"

######################################
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
