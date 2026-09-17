# Worktrunk configuration guidance

## Ownership

- Keep Worktrunk configuration and shell helpers under `worktrunk/`.
- Put Fish startup integration in `worktrunk/fish/init.fish`, aliases in `worktrunk/fish/aliases.fish`, and functions in `worktrunk/fish/functions.fish`. The root Fish config discovers those files; do not add Worktrunk-specific entries to the shared `fish/aliases.fish` or `fish/functions.fish`.
- Use Homebrew's vendor completion for `wt`. Do not commit generated files under the shared `fish/functions/` or `fish/completions/` directories.

## Workflow contract

- Worktrunk owns manually managed worktree creation, navigation, status, and checkout cleanup.
- Git and `gh-stack` own branch history and branch cleanup. Keep `remove.delete-branch = false`, retain branch refs when removing worktrees, and do not introduce `wt merge` into this workflow.
- Tool-managed agent worktrees, including native Codex, Claude, or Pi isolation, remain under the lifecycle ownership of the tool that created them.
- Keep Worktrunk-managed paths centralized through `worktree-path`; do not return to direct sibling worktree directories.

## Helper behaviour

- `wnew BRANCH` fetches and prunes the preferred remote, then creates from its remote default branch. `wnew BRANCH BASE` uses an explicit base; `@` means current HEAD.
- `wi [KIND] ISSUE_URL` derives a lowercase branch from a Linear/Jira key or GitHub issue. It defaults to `feature`; supported kinds are declared in the function. With no URL it reads the macOS clipboard. `--print` must remain side-effect free.
- Cleanup aliases may preview or safely remove a single worktree, but must not force deletion or hide destructive bulk cleanup behind an alias.

## Validation

- Run `fish -n` on every file under `worktrunk/fish/`.
- Exercise `wi --print` with a ticket URL, an explicit kind, and a bare ticket key.
- Test `wnew` in a disposable repository with a remote default branch, and remove all test worktrees and temporary directories afterward.
- Run `wt config show` and a bounded `wt list --format=json` check in a real repository.
