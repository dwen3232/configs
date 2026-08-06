---
name: agent-browser
description: Browser automation CLI for AI agents. Use when the user needs to interact with websites, including navigating pages, filling forms, clicking buttons, taking screenshots, extracting data, testing web apps, logging into a site, automating browser tasks, exploratory testing, Slack, Electron apps, or cloud browser providers.
---

# agent-browser

Fast browser automation CLI for AI agents. Chrome/Chromium via CDP with accessibility-tree snapshots and compact `@eN` element refs.

This skill is adapted from the official Vercel Labs `agent-browser` discovery skill. The full workflow guide ships with the installed CLI and stays version-matched. Do not rely on memory for command details.

## Start here

Before running browser automation commands, load the official workflow content:

```bash
agent-browser skills get core
agent-browser skills get core --full
```

Use `--full` when you need the command reference, templates, troubleshooting, or an unfamiliar workflow.

## Specialized skills

Load a specialized official skill when the task matches:

```bash
agent-browser skills get electron          # Electron desktop apps: VS Code, Slack, Discord, Figma, Notion, Spotify
agent-browser skills get slack             # Slack workspace automation
agent-browser skills get dogfood           # Exploratory testing, QA, bug hunts, app-quality review
agent-browser skills get vercel-sandbox    # agent-browser inside Vercel Sandbox microVMs
agent-browser skills get agentcore         # AWS Bedrock AgentCore cloud browsers
agent-browser skills list                  # all skills available in this installed version
```

## Core workflow

Use the snapshot-and-ref loop for interactive pages:

```bash
agent-browser open <url>
agent-browser snapshot -i
agent-browser click @e3
agent-browser snapshot -i
```

Rules:

1. Re-run `agent-browser snapshot -i` after any page-changing action. `@eN` refs become stale after navigation, form submission, dialog changes, dynamic renders, and content updates.
2. Prefer `snapshot -i` for interactive work. Use `read [url]` for documentation or text extraction where no refs are needed.
3. Prefer `@eN` refs from snapshots. Use semantic locators (`find role`, `find text`, `find label`, `find placeholder`, `find testid`) when refs are unavailable. Use raw CSS selectors as a fallback.
4. Wait deliberately after navigation or async UI updates. Choose the wait described by the official core skill instead of sleeping blindly.
5. Keep browser state only when useful for the task. Close sessions with `agent-browser close` or `agent-browser close --all` when done.

## Safety

Ask for confirmation before submitting forms or clicking controls that purchase, publish, delete, send messages, change account settings, or otherwise mutate external state unless the user explicitly requested that exact action.

Do not expose secrets, cookies, session tokens, or private page content. When credentials are needed, ask the user for the authorized flow or use an existing authenticated browser state if the user directs you to do so.

For broad web research, use dedicated search/fetch tools when available. Use `agent-browser` when rendered UI interaction, authentication state, screenshots, app testing, or browser-only behavior matters.
