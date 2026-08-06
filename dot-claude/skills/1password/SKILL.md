---
name: 1password
description: >
  Load this skill only when the user explicitly mentions 1Password or "1pass". Use it to work with 1Password CLI secret references, run commands with secrets injected, inject templates, or manage 1Password items without exposing secret values. Do not load for general secrets or credential management unless 1Password is specifically referenced.

  Examples of when to load this skill:
  - "use 1pass to inject secrets into the config file"
  - "run the dev server with secrets from 1Password"
  - "set DATABASE_URL from 1Password and run the migration"
  - "set up the .env references using our 1Password vault"
  - "save this new token reference to 1Password"
  - "what's the secret reference syntax for 1pass?"
---

# 1Password CLI (`op`)

Use the 1Password CLI to pass secrets to commands without exposing secret values to the model, terminal transcript, logs, or committed files.

Run `op [command] --help` for full details on any command.

## Priority rules

1. Secret values must not enter model context. Do not print, read, summarize, transform, paste, or store resolved secret values.
2. Prefer `op://` references, `op run`, and `op inject` templates. These let secrets flow directly from 1Password into a target process or ignored local file.
3. If the user asks to reveal a secret value, refuse briefly and offer to use the secret in a command instead.
4. Never read generated files that contain resolved secrets. If verification is needed, verify by checking exit status, file existence, permissions, command behavior, or non-secret metadata.
5. Treat generated secret-bearing files as local temporary artifacts. Ensure they are ignored before creating them, and delete them when they are no longer needed.

## Secret reference syntax

References follow this format:

```text
op://<vault>/<item>/<field>
```

Examples of references, not resolved values:

```text
op://app-prod/db/password
op://app-prod/db/username
op://app-prod/ssh-key/private key?ssh-format=openssh
op://app-prod/db/one-time password?attribute=otp
```

## Safe workflows

### Run a process with secrets as environment variables

`op run` scans environment variables for `op://` references and resolves them only for the child process.

```bash
export DB_PASSWORD="op://app-prod/db/password"
op run -- node server.js
```

With an env file containing references only:

```bash
op run --env-file=.env.1password -- npm start
```

The env file should contain unresolved references:

```text
DATABASE_URL=op://app-prod/db/url
API_KEY=op://app-prod/service/api-key
```

Do not read or print the resolved environment inside the agent session.

### Inject secrets into a local config from a template

Templates use `{{ op://vault/item/field }}` syntax.

```bash
op inject -i config.yml.tpl -o config.local.yml
```

Before writing a resolved output file:

1. Confirm the output path is not tracked by git.
2. Confirm the output path is ignored by git, or ask before adding an ignore rule.
3. Do not read the output file after injection.
4. Delete the output file when no longer needed if it contains live secrets.

Template example:

```yaml
database_url: "{{ op://app-prod/db/url }}"
api_key: "{{ op://app-prod/service/api-key }}"
```

### Create reference-only env files

It is safe to write files containing `op://` references when the file does not contain resolved secret values.

```bash
cat > .env.1password <<'EOF'
DATABASE_URL=op://app-prod/db/url
API_KEY=op://app-prod/service/api-key
EOF
```

Still avoid committing env files unless the repository explicitly allows reference-only env files.

### Manage item metadata

Prefer metadata-only commands or field names that do not expose secret values.

```bash
op item list --vault <vault>
op item get <item-name> --vault <vault> --format json
```

Before using `op item get`, check whether the selected fields include secret values. Do not request fields such as `password`, `credential`, `token`, `secret`, `private key`, or `one-time password` unless the output goes directly into a non-printing workflow.

### Create or update 1Password items

Use `op item create` or `op item edit` only when the user intentionally wants to mutate 1Password data.

```bash
op item create --category login --title <title> --vault <vault>
op item edit <item-name> --vault <vault> field=value
```

If `field=value` includes a secret supplied by the user, avoid echoing it back. Prefer reading the value from a local non-logged input mechanism when possible.

## Refusal behavior

If the user asks to reveal, print, decode, inspect, or paste a secret value from 1Password, respond with:

```text
I can't reveal or read the secret value into the transcript. I can use the 1Password reference with `op run` or `op inject` so the secret goes directly to the target command instead.
```

Then offer a safe command pattern.

## Unsafe patterns

Do not run commands that print secret values to stdout, place secret values in shell arguments, or save secret values where the agent may read them.

Forbidden pattern categories:

- Directly reading a secret reference so the value appears in stdout or model-visible tool output.
- Using command substitution to place resolved secret values into another command's arguments.
- Writing a resolved secret file that the agent might later read, print, commit, or leave behind.

If a tool requires a secret on stdin or in a file, use a safe wrapper that avoids printing the secret and ensure any generated file is ignored, tightly permissioned, and not read by the agent.

## Global flags

- `--vault <name>` — target a specific vault
- `--account <shorthand>` — target a specific account
- `--format json` — machine-readable output for metadata and non-secret fields

Avoid `--no-masking`. Leave masking enabled so accidental output is redacted when 1Password supports masking.

## Common safe patterns

### Run a migration with injected credentials

```bash
export DATABASE_URL="op://staging/database/url"
op run -- bin/rails db:migrate
```

### Run a one-off command with a reference env file

```bash
op run --env-file=.env.1password -- npm run sync
```

### Generate a local config file from a template

```bash
git check-ignore -q config.local.yml && op inject -i config.yml.tpl -o config.local.yml
```

If `git check-ignore` fails, ask before creating the resolved file or adding an ignore rule.

### Verify a secret-backed command without exposing the secret

Use command behavior, exit status, or non-secret output:

```bash
op run --env-file=.env.1password -- npm test
```

Do not run commands like `env`, `printenv`, `echo $SECRET`, or debug modes that dump environment variables.
