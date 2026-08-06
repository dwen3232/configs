---
name: langsmith
description: >
  Load this skill when the user asks about LangSmith threads, traces, runs,
  or workspaces, particularly when the request spans or compares multiple
  LangSmith workspaces.

  Examples of when to load this skill:
  - "find error threads in the Acme workspace from LangSmith"
  - "compare thread volume between our prod and staging LangSmith workspaces"
  - "what workspaces do we have in LangSmith"
  - "pull the trace for thread <id> in workspace <name>"
allowed-tools: Bash(test *) Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/langsmith.py *)
shell: bash
---

# LangSmith (multi-workspace)

## Environment

- LANGSMITH_API_KEY: !`test -n "$LANGSMITH_API_KEY" && echo "set" || echo "NOT SET — ask the user to export it before running scripts/langsmith.py"`
- LANGSMITH_ENDPOINT: !`test -n "$LANGSMITH_ENDPOINT" && echo "$LANGSMITH_ENDPOINT (custom)" || echo "unset — defaults to https://api.smith.langchain.com"`

If LANGSMITH_API_KEY is not set, stop and ask the user to export it (e.g. via
`op run`, or already present in their shell) before running any command
below — do not ask them to paste the key, and do not read whatever file sets
it yourself.

## Workspaces (as of skill load)

!`python3 ${CLAUDE_SKILL_DIR}/scripts/langsmith.py workspaces 2>&1`

This list is fetched fresh each time this skill loads, so it's current as of
now — workspaces don't change often enough to need a refetch mid-conversation.
Use the `id` or exact `name` from this list directly in the commands below.
Only run `workspaces --refresh` yourself if a workspace you expect is missing
(e.g. one created after this skill loaded).

## Why a helper script instead of raw curl

- **Keeps the API key out of context.** The script reads `LANGSMITH_API_KEY`
  with `os.environ`, never echoes it, and never takes it as a CLI argument.
  The flag above only reports presence/absence — never the value.
- **Name -> id resolution is stateful, not a one-liner.** Workspace ids are
  UUIDs; humans refer to workspaces by display name. Resolving that requires
  fetching `/api/v1/workspaces` once, caching it (1 hour TTL at
  `~/.cache/langsmith-skill/workspaces.json`), and matching case-insensitively
  with disambiguation on multiple hits.
- **Workspace scoping is a per-request header, not a connection.** Thread and
  trace endpoints require `X-Tenant-Id` on each call. The script resolves
  the workspace argument to that header automatically, so one process can
  hit N workspaces in a loop with a single API key — which is exactly what
  the MCP server (one workspace per server config) cannot do.
- **Pagination.** `threads-query` follows `next_cursor` until `--limit` is
  hit, so the caller gets one flat JSON array instead of raw pages.

## Commands

Run via `python3 ${CLAUDE_SKILL_DIR}/scripts/langsmith.py <command> ...`.

```text
workspaces [--refresh]
  List every workspace the API key can see (id, name, tenant handle).
  Already shown above for this conversation; only call this yourself to
  force a refetch with --refresh.

resolve <name>
  Resolve a human workspace name (or tenant handle, or id) to {"id", "name"}.
  Rarely needed directly since the list above already has ids, but useful
  if a name is ambiguous — exits non-zero with the candidate list.

threads-query --workspace <name-or-id> [--filter EXPR] [--project-id ID]
              [--min-start-time RFC3339] [--max-start-time RFC3339]
              [--page-size N] [--limit N]
  Query threads in one workspace, auto-paginating up to --limit (default 50).
  --filter uses LangSmith's filter expression language, e.g.
  eq(status, "error") or has(tags, "production"). See
  https://docs.langchain.com/langsmith/trace-query-syntax#filter-query-language

thread-traces --workspace <name-or-id> --thread-id <id> --project-id <id>
  Fetch trace detail for one thread.
```

## Workflow for cross-workspace questions

1. Pick workspace ids/names straight from the list above — don't guess one.
2. For "across all our workspaces" questions, run `threads-query` per
   workspace id from the list in a loop, tagging each result with
   `_workspace` (already included in the script's output) before comparing.
3. Prefer `--filter` and `--min-start-time`/`--max-start-time` to narrow
   results server-side rather than pulling everything and filtering in
   context.
