#!/bin/fish

######################################
# Create a Worktrunk worktree from the latest default branch.
######################################
function wnew --description "Create a Worktrunk worktree from the latest default branch"
    if test (count $argv) -lt 1; or test (count $argv) -gt 2
        echo "usage: wnew BRANCH [BASE]" >&2
        echo "       BASE defaults to the fetched remote default; use @ for the current HEAD" >&2
        return 2
    end

    command git rev-parse --show-toplevel >/dev/null 2>&1
    or begin
        echo "wnew: not inside a Git repository" >&2
        return 1
    end

    set --local branch $argv[1]
    set --local base $argv[2]

    if test -z "$base"
        set --local remotes (command git remote)
        if test (count $remotes) -eq 0
            echo "wnew: this repository has no remotes; pass an explicit BASE" >&2
            return 1
        end

        set --local remote origin
        if not contains -- $remote $remotes
            set remote $remotes[1]
        end

        command git fetch --prune $remote
        or return $status

        set base (command git symbolic-ref --quiet --short "refs/remotes/$remote/HEAD")
        if test -z "$base"
            echo "wnew: $remote/HEAD is unavailable; using Worktrunk's default branch" >&2
            set base ^
        end
    end

    wt switch --create "$branch" --base="$base"
end

######################################
# Create a Worktrunk worktree from an issue URL.
######################################
function wi --description "Create a Worktrunk worktree from an issue URL"
    set --local print_only false
    if test "$argv[1]" = --print
        set print_only true
        set --erase argv[1]
    end

    set --local kinds feature fix refactor chore investigate research test
    set --local kind feature
    if contains -- "$argv[1]" $kinds
        set kind $argv[1]
        set --erase argv[1]
    end

    if test (count $argv) -gt 1
        echo "usage: wi [--print] [KIND] [ISSUE_URL]" >&2
        return 2
    end

    set --local issue $argv[1]
    if test -z "$issue"; and command -q pbpaste
        set issue (pbpaste)
    end
    set issue (string trim -- "$issue")
    if test -z "$issue"
        echo "wi: pass an issue URL or copy one to the clipboard" >&2
        return 2
    end

    set --local issue_id (string match --regex --ignore-case --groups-only '([a-z][a-z0-9]+-[0-9]+)' -- "$issue" | head -n 1)
    set --local issue_slug

    if test -n "$issue_id"
        set issue_slug (string replace --regex --ignore-case "^.*$issue_id/?" '' -- "$issue")
        set issue_slug (string replace --regex '[?#].*$' '' -- "$issue_slug")
    else
        set --local github_number (string match --regex --ignore-case --groups-only '^https?://github\.com/[^/]+/[^/]+/issues/([0-9]+)(?:[/?#].*)?$' -- "$issue")
        if test -z "$github_number"
            echo "wi: expected a Linear/Jira issue URL, issue key, or GitHub issue URL" >&2
            return 2
        end

        set issue_id "gh-$github_number"
        if command -q gh
            set issue_slug (command gh issue view "$issue" --json title --jq .title)
            or set issue_slug
        end
    end

    set issue_id (string lower -- "$issue_id")
    set issue_slug (string lower -- "$issue_slug")
    set issue_slug (string replace --all --regex '[^a-z0-9]+' '-' -- "$issue_slug")
    set issue_slug (string replace --regex "^$issue_id-?" '' -- "$issue_slug")
    set issue_slug (string replace --all --regex '^-+|-+$' '' -- "$issue_slug")
    set issue_slug (string sub --length 48 -- "$issue_slug")
    set issue_slug (string replace --regex -- '-+$' '' "$issue_slug")

    set --local branch "$kind/$issue_id"
    if test -n "$issue_slug"
        set branch "$branch-$issue_slug"
    end

    command git check-ref-format --branch "$branch" >/dev/null
    or begin
        echo "wi: generated invalid branch name: $branch" >&2
        return 1
    end

    if $print_only
        echo $branch
        return
    end

    echo "Creating $branch"
    wnew "$branch"
end
