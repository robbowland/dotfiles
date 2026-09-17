# -- navigate and inspect Worktrunk-managed worktrees
alias ws='wt switch'
alias wl='wt list'
alias wlf='wt list --full'
# -- preview integrated worktrees eligible for cleanup; execution stays explicit
alias wclean='wt step prune --dry-run'
# -- remove the current worktree while retaining its branch
alias wr='wt remove --no-delete-branch'
