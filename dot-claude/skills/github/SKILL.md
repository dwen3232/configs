---
name: github
description: >
  Load this skill when using the `gh` CLI for GitHub work: reading repo files without
  cloning, checking out PRs into worktrees, working with PR stacks
  Examples of when to load this skill:
  - "break this PR into a stack"
  - "use gh stack to submit these branches"
  - "read this file from the repo without cloning it"
  - "check out this PR into a worktree"
  - "search issues semantically"
---

# GitHub CLI (`gh`)

Covers `gh` behavior not reliably in pretraining: the `gh-stack` extension
(unknown entirely) and `gh` features added in recent releases. For everything
else, use existing knowledge or `gh <command> --help`.

## `gh api`

`gh api` is read-only here. Never use it for anything with a side effect —
editing, commenting, creating, merging, closing, labeling — a dedicated
subcommand exists for that (`gh pr comment`, `gh pr review`, `gh pr edit`,
`gh issue comment`, `gh issue edit`, etc.); use it instead. Reserve `gh api`
for reads that have no subcommand equivalent (custom field selection,
GraphQL-only data).

## Stacked PRs (gh-stack)

`gh stack` manages an ordered chain of branches, each with its own PR based on
the branch below it. Non-interactive use is the load-bearing rule: `gh stack`
detects whether stdout is a TTY, and the wrong invocation blocks forever under
an agent harness or a piped shell.

| Always run | Never run bare |
|---|---|
| `gh stack view --json` | `gh stack view` (opens a TUI) |
| `gh stack submit --auto` | `gh stack submit` (prompts per PR) |
| `gh stack merge <target> --yes` | `gh pr merge` (can't merge a stack) |
| `gh stack init <branch>...` | `gh stack init` (prompts for names) |
| `gh stack checkout <target>` | `gh stack checkout` (opens a menu) |
| `gh stack up/down/top/bottom` | `gh stack switch` / `gh stack modify` (menu/TUI only) |

Before creating a stack, before restructuring one, when a command fails, or on
a rebase/merge conflict, read `references/gh-stack/gh-stack.md` — it covers
setup, branch placement, the core loop, syncing, merge scoping, the
`view --json` schema, and exit-code recovery. It in turn points to
`references/gh-stack/references/{stack-design,commands,troubleshooting}.md`
for deeper detail on each of those topics; load only the one that matches the
task.

## Newer `gh` core commands/flags

```bash
gh repo read-file <path> --repo OWNER/REPO [--ref REF] [-o output-path]
gh repo read-dir [<path>] --repo OWNER/REPO [--ref REF]
# preview; support --json/--jq/--template
# read-file blocks terminal escape sequences unless --allow-escape-sequences; --output writes raw bytes

gh pr checkout <number> --worktree /path/to/wt --branch local-branch-name

gh issue create --type Bug --parent 100 --blocked-by 200,201 --blocking 300
# --type sets issue type, --parent makes it a sub-issue, --blocked-by/--blocking set dependency links

gh search issues "query" --search-type semantic   # or hybrid (keyword+semantic)
# default --search-type is lexical; semantic/hybrid: relevance-ranked only (no --sort/--order),
# single page, issues only, unavailable on GHES

gh discussion list --repo OWNER/REPO   # preview
gh discussion create --category "General" --title "Hello" --body "Hello World!"
gh discussion view 123
gh discussion comment 123
```

- `gh extension install` no longer requires authentication.
- `gh extension uninstall` is now an alias for `gh extension remove`.
- `gh release download` works on public repos without authentication.
