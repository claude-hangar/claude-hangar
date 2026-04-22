---
name: vault-bootstrap
description: >
  Intelligent first-time onboarding of a repo into the central Obsidian vault.
  Reads the repo structure, proposes a .repomind.yml, seeds the vault
  subfolder from gold-standard templates, then runs the first sync. Use when:
  "onboard repo", "bootstrap vault", "add to vault", "/vault-bootstrap".
effort: medium
user-invocable: true
argument-hint: "<repo-path>"
---

<!-- AI-QUICK-REF
## /vault-bootstrap — Quick Reference
- **Input:** path to a repo (default: cwd)
- **Output:** new `.repomind.yml` + seeded vault subfolder + first sync
- **This is the intelligent half of repomind** — does what the deterministic
  CLI cannot: understand repo structure, propose config, seed templates.
- **User confirmation required** before writing anything.
-->

# /vault-bootstrap — Onboard a repo into the central Obsidian vault

This is the **intelligent** companion to `/vault-sync`. It reads an unprepared
repository, proposes configuration and a vault layout, seeds the vault
subfolder from gold-standard templates, and only then hands off to
`repomind sync`.

## When to use

- First time adding a repo to the central Obsidian vault
- Rebuilding a vault subfolder from scratch
- Adding a new project that needs gold-standard structure

Do **not** use for routine syncing — that's `/vault-sync`.

## Flow

### Step 1 — Validate repo path

Default: current working directory. If an argument is passed, resolve it.
Stop with a clear error if the path does not exist or is not a directory.

If `.repomind.yml` already exists: confirm with the user whether to
re-bootstrap (destructive) or abort.

### Step 2 — Inspect the repo

Read the repo structure to understand what to track. Look for:

| Signal | What to learn |
|--------|---------------|
| `README.md` title / first heading | Candidate `project.name` |
| Top-level `docs/` folder with sub-dirs | Area layout for _INDEX files |
| Existing `Dashboard.md` | Keep vs. overwrite decision |
| `CLAUDE.md` | Claude-hangar project; exclude `.claude/` |
| `.git/` | Always exclude |
| `raw/`, `scripts/`, `archive/` | Exclude by default |
| `node_modules/`, `.venv/`, `dist/` | Exclude if present |
| `templates/` folder | Usually exclude from sync |

**Do not read large binaries.** Sample up to ~20 files to form the picture;
past that, trust what you've seen.

### Step 3 — Propose `.repomind.yml`

Render a config preview and show it to the user. Use
`repomind.config.render_config_yaml` internally via a one-shot Python call,
or hand-build the YAML from the observations.

Ask the user to confirm:
1. Project name (extracted from README/repo-folder-name — let them override)
2. Vault root (default: `D:\Obsidian-Vault`)
3. Subfolder (default: project name, sanitized — no spaces, no special chars)
4. Include/exclude globs (default: see gold-standard below)

Default include/exclude:

```yaml
include:
  - "*.md"
  - "docs/**/*.md"
  - "docs/**/*.drawio"
  - "docs/**/*.png"
  - "docs/**/*.svg"
  - ".obsidian/**"
exclude:
  - "raw/**"
  - "scripts/**"
  - "archive/**"
  - ".git/**"
  - ".claude/**"
  - "node_modules/**"
  - ".venv/**"
  - "dist/**"
  - ".repomind/**"
```

### Step 4 — Seed the vault subfolder from gold-standard templates

Templates live in `tools/repomind/templates/gold-standard/`:

| Template | Target in vault |
|----------|-----------------|
| `Dashboard.md` | `<vault>/<subfolder>/Dashboard.md` |
| `docs/INDEX.md` | `<vault>/<subfolder>/docs/INDEX.md` |
| `docs/_INDEX.md` | `<vault>/<subfolder>/docs/<area>/_INDEX.md` per detected area |
| `OBSIDIAN-SETUP.md` | `<vault>/<subfolder>/OBSIDIAN-SETUP.md` |

Placeholder substitution (simple string replace, not Jinja):

| Placeholder | Value |
|-------------|-------|
| `{{PROJECT_NAME}}` | from config |
| `{{PROJECT_DESCRIPTION}}` | from config (may be empty) |
| `{{DATE}}` | today in `YYYY-MM-DD` |
| `{{AREA_NAME}}` | for _INDEX: human-readable area name |
| `{{AREA_SLUG}}` | for _INDEX: lowercase kebab-case |
| `{{AREA_DESCRIPTION}}` | one-sentence description (from README or user) |
| `{{AREA_NAV}}` | Dashboard navigation block (auto-assembled) |
| `{{AREA_LIST}}` | INDEX area list (auto-assembled) |
| `{{AREA_CONTENT}}` | _INDEX body stub |

**Never overwrite an existing file in the vault** during seeding. If a file
is already there, skip it and note it in the chat summary.

### Step 5 — Run `repomind init`

Write `.repomind.yml` via the CLI (not manually) so validation runs:

```bash
python -m repomind init \
  --project-name "$NAME" \
  --vault-root "$VAULT_ROOT" \
  --subfolder "$SUBFOLDER" \
  --description "$DESC"
```

### Step 6 — First sync

```bash
python -m repomind sync
```

Report counts + any skipped template-seed files.

## Output shape

```
Bootstrap complete — <NAME>
  vault subfolder: D:\Obsidian-Vault\<NAME>
  seeded templates: 4 (0 skipped)
  first sync:       12 new, 0 changed, 0 deleted
  next steps:       open vault in Obsidian → enable CSS snippets
```

## Rules

- **Confirm before writing.** Every destructive step gets user confirmation.
- **Never overwrite user-authored files.** Templates are seed-only.
- **No secret sniffing.** The secret-leak-check hook handles that; this
  skill just respects the include/exclude globs.
- **Honor `/vault-audit` findings first.** If the vault already has a
  subfolder with structural issues, recommend running `/vault-audit` before
  a full re-bootstrap.

## Related

- `/vault-sync` — routine syncing after bootstrap
- `/vault-audit` — structural review of an existing subfolder
