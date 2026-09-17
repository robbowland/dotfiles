# Repository Guidance

## Workflow

- Pull the intended upstream and resolve any divergence or conflicts before editing.
- Validate and commit every task-owned change; do not leave agent-authored changes uncommitted.

## Organization

- Treat each top-level tool directory as the owner of that tool's configuration, shell integration, documentation, and tests. Inspect comparable tool directories before adding files.
- Keep tool-specific Fish files under `<tool>/fish/`: startup integration in `init.fish`, aliases in `aliases.fish`, functions in `functions.fish`, and environment settings in `exports.fish`. The shared `fish/config.fish` discovers these files dynamically.
- Reserve the top-level `fish/` directory for shell-wide behaviour and dependencies that genuinely have no tool owner. When an installer writes tool-specific files there, prefer an owner-local integration supported by the tool and avoid committing redundant generated completions or wrappers.
- Put tool-specific maintenance guidance in that tool's directory. Keep machine-local runtime state, caches, credentials, and generated installation data out of this repository unless an established tracked pattern explicitly requires them.

## Commits

- Do not use conventional commit prefixes in this repository.
- Use short imperative subjects that name the affected tool or area when useful, for example `Update \`yazi\` filetype theme rules`.
- Keep subjects imperative and compact, matching the existing repository style.
- Include a useful commit body when the reason, compatibility note, or audit context is not obvious from the subject.
- Combine related changes into one coherent commit when it would make sense as a squashed PR.
- Stage explicit paths only; this repository often has unrelated local worktree changes.
