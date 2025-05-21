#!/bin/bash

######################################
# Perform git checkout using fzf to select branch.
######################################
fzf_git_checkout() {
    git checkout "$(git branch --all | fzf --border --no-scrollbar --color=dark | tr -d '[:space:]')"
}

######################################
# Setup fzf path & autocompletion.
######################################
_fzf_setup() {
    # Setup fzf
    if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
        PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
    fi

    # Auto-completion
    [[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null
}

# setup fzf
_fzf_setup
