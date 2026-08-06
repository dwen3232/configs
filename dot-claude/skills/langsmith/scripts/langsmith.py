#!/usr/bin/env python3
"""LangSmith REST API helper for cross-workspace thread/trace lookups.

Resolves a human workspace name to its workspace (tenant) id and sends the
id as the X-Tenant-Id header on a per-request basis, so a single API key can
be used against any workspace in the org without per-workspace connections.

Auth: reads LANGSMITH_API_KEY (required) and LANGSMITH_ENDPOINT (optional,
defaults to https://api.smith.langchain.com) from the environment. Never
pass the key as a CLI argument.
"""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API_BASE = os.environ.get("LANGSMITH_ENDPOINT", "https://api.smith.langchain.com")
CACHE_PATH = Path(
    os.environ.get("LANGSMITH_SKILL_CACHE", Path.home() / ".cache" / "langsmith-skill" / "workspaces.json")
)
CACHE_TTL_SECONDS = 3600


def api_key():
    key = os.environ.get("LANGSMITH_API_KEY")
    if not key:
        sys.exit("LANGSMITH_API_KEY is not set")
    return key


def request(method, path, headers=None, body=None):
    url = f"{API_BASE}{path}"
    hdrs = {"X-API-Key": api_key(), "Content-Type": "application/json"}
    if headers:
        hdrs.update(headers)
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers=hdrs, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        detail = e.read().decode()
        sys.exit(f"{method} {path} -> HTTP {e.code}: {detail}")


def load_workspaces(refresh=False):
    if not refresh and CACHE_PATH.exists():
        age = time.time() - CACHE_PATH.stat().st_mtime
        if age < CACHE_TTL_SECONDS:
            return json.loads(CACHE_PATH.read_text())
    workspaces = request("GET", "/api/v1/workspaces")
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.write_text(json.dumps(workspaces))
    return workspaces


def resolve_workspace(name_or_id, refresh=False):
    workspaces = load_workspaces(refresh=refresh)

    for w in workspaces:
        if w["id"] == name_or_id:
            return w

    needle = name_or_id.strip().lower()

    def matches(pred):
        return [w for w in workspaces if pred(w)]

    exact = matches(
        lambda w: w["display_name"].lower() == needle or (w.get("tenant_handle") or "").lower() == needle
    )
    if len(exact) == 1:
        return exact[0]
    if len(exact) > 1:
        sys.exit(f"Ambiguous workspace name '{name_or_id}': {[w['id'] for w in exact]}")

    partial = matches(lambda w: needle in w["display_name"].lower())
    if len(partial) == 1:
        return partial[0]
    if len(partial) > 1:
        candidates = ", ".join(f"{w['display_name']} ({w['id']})" for w in partial)
        sys.exit(f"Ambiguous workspace name '{name_or_id}', candidates: {candidates}")

    if not refresh:
        return resolve_workspace(name_or_id, refresh=True)

    known = ", ".join(w["display_name"] for w in workspaces)
    sys.exit(f"No workspace matching '{name_or_id}'. Known workspaces: {known}")


def cmd_workspaces(args):
    workspaces = load_workspaces(refresh=args.refresh)
    out = [{"id": w["id"], "name": w["display_name"], "handle": w.get("tenant_handle")} for w in workspaces]
    print(json.dumps(out, indent=2))


def cmd_resolve(args):
    w = resolve_workspace(args.name)
    print(json.dumps({"id": w["id"], "name": w["display_name"]}))


def cmd_projects(args):
    w = resolve_workspace(args.workspace)
    params = [f"limit={args.limit}"]
    if args.name_contains:
        params.append(f"name_contains={urllib.parse.quote(args.name_contains)}")
    path = f"/api/v1/sessions?{'&'.join(params)}"
    resp = request("GET", path, headers={"X-Tenant-Id": w["id"]})
    out = [{"id": p["id"], "name": p["name"]} for p in resp]
    print(json.dumps(out, indent=2))


def cmd_threads_query(args):
    w = resolve_workspace(args.workspace)
    body = {"page_size": args.page_size}
    for key, val in (
        ("filter", args.filter),
        ("project_id", args.project_id),
        ("min_start_time", args.min_start_time),
        ("max_start_time", args.max_start_time),
    ):
        if val:
            body[key] = val

    results = []
    cursor = None
    while True:
        if cursor:
            body["cursor"] = cursor
        resp = request("POST", "/api/v2/threads/query", headers={"X-Tenant-Id": w["id"]}, body=body)
        items = resp.get("items", [])
        for item in items:
            item["_workspace"] = w["display_name"]
        results.extend(items)
        cursor = resp.get("next_cursor")
        if not cursor or len(results) >= args.limit:
            break

    print(json.dumps(results[: args.limit], indent=2))


def cmd_thread_traces(args):
    w = resolve_workspace(args.workspace)
    path = f"/api/v2/threads/{args.thread_id}/traces?project_id={args.project_id}"
    resp = request("GET", path, headers={"X-Tenant-Id": w["id"]})
    print(json.dumps(resp, indent=2))


def main():
    parser = argparse.ArgumentParser(description="LangSmith multi-workspace API helper")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("workspaces", help="List all workspaces visible to the API key")
    p.add_argument("--refresh", action="store_true", help="Bypass the local cache and refetch")
    p.set_defaults(func=cmd_workspaces)

    p = sub.add_parser("resolve", help="Resolve a human workspace name to its id")
    p.add_argument("name")
    p.set_defaults(func=cmd_resolve)

    p = sub.add_parser("projects", help="List tracing projects (sessions) within a workspace")
    p.add_argument("--workspace", required=True, help="Workspace display name, tenant handle, or id")
    p.add_argument("--name-contains", help="Filter projects by partial name match")
    p.add_argument("--limit", type=int, default=100)
    p.set_defaults(func=cmd_projects)

    p = sub.add_parser("threads-query", help="Query threads within a workspace, paginating automatically")
    p.add_argument("--workspace", required=True, help="Workspace display name, tenant handle, or id")
    p.add_argument("--filter", help="LangSmith filter expression, e.g. eq(status, \"error\")")
    p.add_argument("--project-id", help="Restrict to one tracing project (UUID)")
    p.add_argument("--min-start-time", help="RFC3339 lower bound, default 1 day ago")
    p.add_argument("--max-start-time", help="RFC3339 upper bound, default now")
    p.add_argument("--page-size", type=int, default=20)
    p.add_argument("--limit", type=int, default=50, help="Max threads to return across all pages")
    p.set_defaults(func=cmd_threads_query)

    p = sub.add_parser("thread-traces", help="Get trace detail for one thread")
    p.add_argument("--workspace", required=True)
    p.add_argument("--thread-id", required=True)
    p.add_argument("--project-id", required=True)
    p.set_defaults(func=cmd_thread_traces)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
