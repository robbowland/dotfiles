#!/bin/fish

######################################
# Perform git checkout using fzf to select branch.
######################################
function fzf_git_checkout
    git checkout (git branch --all | fzf --border --no-scrollbar --color=dark | tr -d '[:space:]')
end

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
