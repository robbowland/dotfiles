# Repository Guidance

## Workflow

- Pull the intended upstream and resolve any divergence or conflicts before editing.
- Validate and commit every task-owned change; do not leave agent-authored changes uncommitted.

## Commits

- Do not use conventional commit prefixes in this repository.
- Use short imperative subjects that name the affected tool or area when useful, for example `Update \`yazi\` filetype theme rules`.
- Keep subjects imperative and compact, matching the existing repository style.
- Include a useful commit body when the reason, compatibility note, or audit context is not obvious from the subject.
- Combine related changes into one coherent commit when it would make sense as a squashed PR.
- Stage explicit paths only; this repository often has unrelated local worktree changes.
