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
---

# LangSmith (multi-workspace)

## Why a helper script instead of raw curl

- **Keeps the API key out of context.** `LANGSMITH_API_KEY` must be set in
  the shell environment (e.g. injected via 1Password `op run`, or already
  exported). The script reads it with `os.environ`, never echoes it, and
  never takes it as a CLI argument. Do not read whatever file sets this
  variable, and do not print the key.
- **Name -> id resolution is stateful, not a one-liner.** Workspace ids are
  UUIDs; humans refer to workspaces by display name. Resolving that requires
  fetching `/api/v1/workspaces` once, caching it (1 hour TTL at
  `~/.cache/langsmith-skill/workspaces.json`), and matching case-insensitively
  with disambiguation on multiple hits. Redoing this by hand in every
  `curl` call is slow and error-prone.
- **Workspace scoping is a per-request header, not a connection.** Thread and
  trace endpoints require `X-Tenant-Id` on each call. The script resolves
  the workspace argument to that header automatically, so one process can
  hit N workspaces in a loop with a single API key — which is exactly what
  the MCP server (one workspace per server config) cannot do.
- **Pagination.** `threads-query` follows `next_cursor` until `--limit` is
  hit, so the caller gets one flat JSON array instead of raw pages.

## Setup

Requires `LANGSMITH_API_KEY` in the environment. Optionally `LANGSMITH_ENDPOINT`
for self-hosted/regional deployments (defaults to `https://api.smith.langchain.com`).

## Commands

Run via `python3 scripts/langsmith.py <command> ...` from this skill's directory.

```text
workspaces [--refresh]
  List every workspace the API key can see (id, name, tenant handle).
  Cached for 1 hour; pass --refresh to force a refetch (e.g. after a new
  workspace was created).

resolve <name>
  Resolve a human workspace name (or tenant handle, or id) to {"id", "name"}.
  Exits non-zero with candidate list if the name is ambiguous or unknown.

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

1. If the workspace name isn't already known to be valid, run `resolve` (or
   `workspaces` to list all of them) before querying — don't guess an id.
2. For "across all our workspaces" questions, call `workspaces` once, then
   run `threads-query` per workspace id in a loop, tagging each result with
   `_workspace` (already included in the script's output) before comparing.
3. Prefer `--filter` and `--min-start-time`/`--max-start-time` to narrow
   results server-side rather than pulling everything and filtering in
   context.
