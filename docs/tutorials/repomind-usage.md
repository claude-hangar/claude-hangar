# Repomind — Usage Tutorial

Repomind is the deterministic repo-to-Obsidian-vault sync that ships inside
claude-hangar. It solves the one-Obsidian-Sync-account-means-one-vault problem:
keep one central Obsidian vault with per-project subfolders, and sync each
project's documentation from its git repo into its subfolder.

The actual filesystem mechanic is a small Python CLI (`tools/repomind/`).
The intelligence around it — onboarding a new repo, auditing structure —
lives in three claude-hangar skills.

## Architecture at a glance

```
            ┌───────────────── claude-hangar ─────────────────┐
            │                                                 │
            │   core/skills/                                  │
            │     ├── vault-sync       (wraps the CLI)        │
            │     ├── vault-bootstrap  (intelligent setup)    │
            │     └── vault-audit      (structural check)     │
            │                                                 │
            │   core/hooks/                                   │
            │     └── repomind-autosync.sh  (opt-in)          │
            │                                                 │
            │   tools/repomind/    ← pure Python CLI          │
            │     ├── src/repomind/*.py                       │
            │     └── templates/gold-standard/                │
            └─────────────────────────────────────────────────┘
```

**Bits vs. semantics:** the CLI does nothing creative. It walks globs,
hashes files, copies deltas, moves deletions into `_deleted/YYYY-MM-DD/`.
The skills do the creative parts: inspect a repo, propose config, seed
templates, audit structure.

## Install the CLI

With `uv` (preferred):

```bash
uv tool install --editable D:\backupblu\github\claude-hangar\claude-hangar\tools\repomind
```

Or with `pipx`:

```bash
pipx install -e D:\backupblu\github\claude-hangar\claude-hangar\tools\repomind
```

Verify:

```bash
repomind --version
```

If the console script isn't on PATH, `python -m repomind` works anywhere
Python 3.11+ is installed and the package is importable.

## Typical workflows

### 1. First-time onboarding of a repo (use `/vault-bootstrap`)

Inside the repo you want to track:

```
/vault-bootstrap
```

The skill will:
1. Inspect your repo structure.
2. Propose a `.repomind.yml` (project name, vault path, include/exclude).
3. Ask you to confirm.
4. Seed the vault subfolder from gold-standard templates (Dashboard.md,
   docs/INDEX.md, _INDEX.md per detected area, OBSIDIAN-SETUP.md).
5. Run the first sync.

You end up with `.repomind.yml` in the repo and a populated vault subfolder.

### 2. Routine sync (use `/vault-sync`)

After making changes in the repo:

```
/vault-sync
```

or, from a shell:

```bash
repomind sync --dry-run   # preview
repomind sync             # apply
```

The CLI prints a table:

```
new:       3
changed:   1
deleted:   0
unchanged: 42
```

Unchanged files never touch the vault. Changed files are overwritten.
Deleted files (i.e. files that dropped out of the include set) are moved
into `<vault>/<subfolder>/_deleted/YYYY-MM-DD/` rather than hard-deleted.

### 3. Structure check (use `/vault-audit`)

When a vault subfolder starts to feel messy or after a manual edit spree:

```
/vault-audit Entenbach
```

Produces a findings report with severity INFO / WARN / ERROR and
fix suggestions. **No automatic fixes** — this skill is read-only.

### 4. Automatic sync on session end (optional)

Enable the opt-in hook:

```bash
# in your user-level Claude Code settings / shell profile:
export HANGAR_REPOMIND_AUTOSYNC=true
```

With the flag set and `.repomind.yml` present in the session's cwd,
`repomind sync` fires automatically when Claude Code ends the session.
The sync runs detached and logs to
`%LOCALAPPDATA%\claude-statusline\repomind-autosync-<session>.log`.

Default is off — Hangar does not sync without you asking.

## `.repomind.yml` reference

```yaml
version: 1
project:
  name: Entenbach                                  # required
  description: Wohnstift am Entenbach — IT-Sanierung  # optional
  tags: [infrastruktur, seniorenheim]              # optional
vault:
  root: 'D:\Obsidian-Vault'                        # required
  subfolder: Entenbach                             # required
sync:
  include:                                         # at least one pattern
    - "*.md"
    - "docs/**/*.md"
    - "docs/**/*.drawio"
    - "docs/**/*.png"
    - "docs/**/*.svg"
    - ".obsidian/**"
  exclude:                                         # optional
    - "raw/**"
    - "scripts/**"
    - "archive/**"
    - ".git/**"
    - ".claude/**"
    - "node_modules/**"
    - ".repomind/**"
```

Patterns are gitignore-style (powered by `pathspec`). Add `.repomind/` to
`.gitignore` so the state file stays machine-local.

## State file

`.repomind/state.json` records per relative path:
- SHA-256 hash at the last sync
- Timestamp of the copy
- Absolute vault target path

Used to detect `new` / `changed` / `unchanged` / `deleted` on subsequent
runs. If this file gets corrupted or deleted, the next sync simply
re-copies everything — no crash, no data loss.

## Troubleshooting

**"No repomind project here" (from `/vault-sync`)**
The skill refuses to sync without `.repomind.yml`. Run `/vault-bootstrap`
first, or write the config by hand with `repomind init`.

**`repomind: command not found`**
Re-run the install. Check that `$HOME/.local/bin` (pipx) or
`$HOME/.cargo/bin` (uv) is on your PATH. `python -m repomind` always works.

**Sync copied files I did not expect**
Check the `include`/`exclude` patterns. `*.md` in gitignore-style matches
`.md` at any depth. Narrow to `*.md` (root only — won't match subdirs in
pathspec) and explicit `docs/**/*.md` for nested paths.

**Idempotency broken: unchanged files show as changed**
The hash algorithm is SHA-256 over raw bytes. If you see phantom changes,
check whether line-ending normalization differs between Git and your editor
(`.gitattributes` `text=auto eol=lf` recommended for this reason).

## Development

Inside `tools/repomind/`:

```bash
python -m venv .venv
.venv/Scripts/python -m pip install -e ".[dev]"
.venv/Scripts/python -m pytest          # coverage gate: 80%
.venv/Scripts/python -m ruff check .
.venv/Scripts/python -m mypy --strict src
```

Coverage currently runs at ~92%, mypy is strict-clean, ruff is clean.

## Scope boundaries (deliberate non-goals)

- No network calls — pure local sync.
- No GUI.
- No bidirectional sync — repo is source of truth, vault is the view.
- No merge-conflict handling.
- No encryption (Obsidian Sync handles that).
- No PyPI publication — the CLI lives inside claude-hangar.
