---
name: github
description: >
  Load this skill when using the `gh` CLI for GitHub work, especially stacked
  PRs via `gh stack` (the gh-stack extension), reading repo files without
  cloning, checking out PRs into worktrees, or newer `gh` features not covered
  by pretraining knowledge.

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

## gh-stack

Stack metadata: `.git/gh-stack` (untracked JSON). Rebase state:
`.git/gh-stack-rebase-state`.

```bash
gh stack init [branches...]     # -b/--base sets trunk (default: repo default branch)
gh stack add [branch]
gh stack add -Am "message"      # stage all + commit + auto-name branch from message
gh stack view [-s|--json]
gh stack up/down [n]            # default 1
gh stack top / bottom / trunk
gh stack switch                 # interactive branch picker
gh stack checkout <stack|pr|url|branch>

gh stack rebase [branch]        # cascade rebase; auto-handles merged-PR detection
gh stack rebase --continue
gh stack rebase --abort
gh stack rebase --downstack     # only down to current branch
gh stack rebase --upstack       # only up to top
gh stack modify                 # interactive TUI: drop/fold/insert/reorder/rename
                                 # requires clean tree, no rebase in progress, linear history

gh stack submit                 # push + create/update PRs; interactive editor
gh stack submit --auto          # skip editor, auto-generate titles (new PRs default draft)
gh stack submit --auto --open   # mark PRs ready-for-review
gh stack push                   # push only, per-branch --force-with-lease, non-atomic
gh stack sync [--prune]         # fetch, reconcile, rebase, push, sync PRs, prune merged
gh stack link <branch|pr> ...   # link existing PRs into a stack without local tracking

gh stack merge [stack|pr]       # merge up to selection, all-or-nothing, respects merge queues
gh stack merge -y --squash
gh stack unstack [stack-number] # remove from GitHub + local tracking (alias: delete)
gh stack unstack --local
```

Env vars: `GH_STACK_THEME=light|dark|auto`, `GH_STACK_HYPERLINKS=0|1`.

`gh stack alias [name] --remove` — create/remove wrapper (default `gs`) in
`~/.local/bin/`.

Gotchas:
- Changing trunk requires rebasing the whole stack.
- `gh stack merge` only checks basic PR state locally; branch protection still applies at merge time.
- Diverged local/remote stacks trigger interactive resolution in `gh stack sync` (use remote / delete remote / cancel).

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

gh skill search terraform   # preview; GitHub-hosted agent skills for Copilot etc — not dot-claude/skills
gh skill install github/awesome-copilot documentation-writer
gh skill list
gh skill update --all
```

- `gh extension install` no longer requires authentication.
- `gh extension uninstall` is now an alias for `gh extension remove`.
- `gh release download` works on public repos without authentication.
