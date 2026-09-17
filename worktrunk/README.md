# Worktrunk

[Worktrunk](https://worktrunk.dev) is the control plane for manually managed Git worktrees. Worktrees live under a hidden directory beside their primary repository group, for example:

```text
~/projects/.worktrees/example/fix-app-1234-description
```

Git and `gh-stack` continue to own branch history. Removing a worktree retains its branch, and this setup does not use `wt merge`.

## Everyday commands

| Command | Action |
| --- | --- |
| `ws` | Open Worktrunk's interactive worktree picker |
| `wl` | List worktree status and divergence |
| `wlf` | List worktrees with PR and CI information |
| `wnew BRANCH` | Fetch and create from the remote default branch |
| `wnew BRANCH @` | Create from the current HEAD, useful for stacked work |
| `wi [KIND] ISSUE_URL` | Derive a branch from an issue and create its worktree |
| `wr` | Remove the current worktree but retain its branch |
| `wclean` | Preview integrated cleanup candidates without deleting anything |

`wi` defaults to `feature`. Supported explicit kinds are `feature`, `fix`, `refactor`, `chore`, `investigate`, `research`, and `test`:

```fish
wi fix https://linear.app/example/issue/APP-1234/fix-the-login-flow
# fix/app-1234-fix-the-login-flow

wi --print APP-1234
# feature/app-1234
```

With no URL, `wi` reads the macOS clipboard. GitHub issue URLs use `gh` to obtain the issue title.

## Cleanup

Use `ws` and `Alt-x` to remove an individual non-current worktree safely. Worktrunk never forces picker removal, and the configuration retains branch refs.

`wclean` is deliberately a dry run. A live `wt step prune` also deletes integrated branches, so it is not part of this workflow. Bulk removal should review the dry-run output and invoke `wt remove --no-delete-branch` for selected worktrees.

Long-lived baselines can be protected explicitly:

```sh
git worktree lock --reason "comparison baseline" /path/to/worktree
```

## Agent integrations

The installer enables Worktrunk's available Pi, Codex, and Claude integrations. They add configuration guidance where supported and expose active/waiting markers in `wt list`.

Native worktrees created by Codex, Claude, or Pi remain owned and cleaned up by that agent tool; Worktrunk owns only manually initiated worktrees.
