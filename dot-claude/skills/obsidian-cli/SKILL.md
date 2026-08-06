---
name: obsidian-cli
description: >
  Load this skill when working with notes in an Obsidian vault through the
  official Obsidian CLI. Prefer it for vault-aware search, reading notes,
  creating notes, and appending or prepending content.

  Examples of when to load this skill:
  - "search my Obsidian vault for meeting notes"
  - "read today's daily note"
  - "append this text to my journal"
  - "create a note in Inbox"
  - "find notes mentioning rate limits and show the matching lines"
---

# Obsidian CLI

Use the official `obsidian` CLI for vault content. It talks to the running
Obsidian app and resolves note names like wikilinks.

## Requirements

- Obsidian 1.12+ installed.
- The desktop app is running.
- CLI enabled in `Settings > General > Advanced > Command line interface`.

## Targeting Rules

- Use `file=<name>` when you know the note name. Obsidian resolves it like a
  wikilink.
- Use `path="Folder/Note.md"` for an exact path.
- Use `vault="Name"` when the target vault is not current or could be
  ambiguous.
- Quote values with spaces: `file="Project Plan"`, `vault="Work Notes"`.
- Use `\n` and `\t` inside `content=` values for multi-line text.

## Primary Commands

### Search

- `obsidian search query="term"` returns matching file paths.
- `obsidian search:context query="term"` returns matching lines with context.
- Add `path="Folder"` to scope the search.
- Add `limit=10` to cap results.
- Add `case` for case-sensitive search.
- Add `format=json` when structured output helps.

### Read

- `obsidian read file="Note Name"`
- `obsidian read path="Folder/Note.md"`
- `obsidian daily:read`
- `obsidian outline file="Note Name"` to inspect headings before a targeted
  read.

### Write

- `obsidian create path="Inbox/Follow up.md" content="..."`
- `obsidian append file="Note Name" content="..."`
- `obsidian prepend file="Note Name" content="..."`
- `obsidian daily:append content="..."`
- `obsidian daily:prepend content="..."`

`create overwrite` replaces an existing file. Use it only when replacement is
intended.

## Recommended Workflows

### Search then read

```bash
obsidian search:context query="rate limit" path="Projects" limit=5
obsidian read file="API Notes"
```

### Create a note

```bash
obsidian create path="Inbox/Follow up.md" content="# Follow up\n\n- [ ] Item"
```

### Append to today's note

```bash
obsidian daily:append content="- shipped the CLI skill"
```

### Read from a specific vault

```bash
obsidian read vault="Work" file="Weekly Plan"
```

## Guidance

- Prefer `search:context` over `search` when you need nearby matching lines.
- Prefer `file=` over `path=` when the note name is unique and the exact path is
  unknown.
- Prefer `path=` when duplicate note names are possible or a specific folder is
  required.
- Prefer `format=json` for supported commands when downstream parsing matters.
- The CLI has no general mid-file replace command. For precise in-place edits,
  read the note first and choose the smallest safe operation.
