---
name: vault-sync
description: >
  Sync the current repo into its Obsidian vault subfolder via the repomind CLI.
  Deterministic copy — new/changed files go to the vault, removed files move
  to `_deleted/YYYY-MM-DD/`. Use when: "vault sync", "sync to obsidian",
  "update vault", "push to vault", "/vault-sync".
effort: low
user-invocable: true
argument-hint: "dry-run|force|path"
---

<!-- AI-QUICK-REF
## /vault-sync — Quick Reference
- **What it does:** Runs `repomind sync` in the current repo and reports the result.
- **Arguments:** none (default) | `dry-run` | `force` | `<config-path>`
- **Precondition:** `.repomind.yml` must exist in the current directory.
- **No intelligence:** This skill is a thin wrapper. For inspection or setup,
  use `/vault-bootstrap` (new repo) or `/vault-audit` (structure check).
-->

# /vault-sync — Wrap `repomind sync`

Deterministic wrapper around the `repomind` Python CLI. This skill exists so
that "sync the vault" is a first-class chat verb — underneath it just calls
`python -m repomind sync` and summarizes the result.

## Flow

1. **Verify `.repomind.yml` exists** in the current working directory.
   - If not: stop and tell the user "No repomind project here. Run
     `/vault-bootstrap` to onboard this repo first."
2. **Parse arguments:**
   - no args → `repomind sync`
   - `dry-run` → `repomind sync --dry-run`
   - `force` → `repomind sync --force`
   - starts with `/` or `\` or contains `:` → treat as explicit config path
     and pass via `--config`
3. **Invoke the CLI** in the current directory.
4. **Parse output:** the CLI prints a Rich table with `new`, `changed`,
   `deleted`, `unchanged` counts. Surface those counts in chat as a compact
   summary, and mention if it was a dry-run.
5. **On non-zero exit:** show the CLI's stderr verbatim. Do not retry.

## Invocation

```bash
# from the skill:
python -m repomind sync                    # normal
python -m repomind sync --dry-run          # preview
python -m repomind sync --force            # ignore cached hashes
python -m repomind sync --config ./foo.yml # custom config location
```

If `repomind` is not on PATH and `python -m repomind` fails, fall back to:

```bash
python -c "import repomind" && echo "module importable but not wired"
```

Then tell the user to run `pipx install -e <repo>/tools/repomind` or
`uv tool install --editable <repo>/tools/repomind`.

## Output shape

Report **only** the numbers, plus a single pointer:

```
Vault sync — {{PROJECT_NAME}}
  new:       3
  changed:   1
  deleted:   0
  unchanged: 42
  target: D:\Obsidian-Vault\Entenbach
```

Do not regurgitate unchanged file lists. Silence on success is the goal.

## Rules

- **No repo inspection.** This skill does not read project files — that is
  `/vault-bootstrap`'s job.
- **No writes to the repo.** Never modify `.repomind.yml` from here.
- **Fail loudly on missing config.** Silence when config is missing would
  hide real user errors.
- **One shot per invocation.** No loops, no polling.

## Related

- `/vault-bootstrap` — first-time setup for a repo
- `/vault-audit` — structural review of a vault subfolder against the gold standard
