# repomind

Deterministic repo-to-Obsidian-vault sync. Lives inside the claude-hangar
repo and is consumed by three skills (`/vault-sync`, `/vault-bootstrap`,
`/vault-audit`) that orchestrate intelligent onboarding and auditing on top
of the deterministic file copy this CLI performs.

## What it does

- Reads a `.repomind.yml` in a repo root.
- Walks the repo with gitignore-style include/exclude globs.
- Hashes each matched file (SHA-256, streamed).
- Copies new/changed files into `<vault>/<subfolder>/<relpath>`.
- Moves files that dropped out of the include set to
  `<vault>/<subfolder>/_deleted/YYYY-MM-DD/<relpath>` (never hard-delete).
- Tracks state in `.repomind/state.json` so repeated runs are idempotent.

## What it deliberately does not do

- No network calls — it is a pure local tool.
- No GUI.
- No bidirectional sync (repo → vault, one-way).
- No merge-conflict handling (vault is a read-only view).
- No encryption (Obsidian Sync handles that).

## Install

```bash
# with uv (recommended)
uv tool install --editable D:\backupblu\github\claude-hangar\claude-hangar\tools\repomind

# or with pipx
pipx install -e D:\backupblu\github\claude-hangar\claude-hangar\tools\repomind
```

After install, `repomind --version` should print the current version.

## Usage

```bash
# in the repo you want to sync:
repomind init --project-name MyProject --vault-root "D:\Obsidian-Vault" --subfolder MyProject
repomind sync --dry-run
repomind sync
```

`.repomind.yml` — minimal example:

```yaml
version: 1
project:
  name: Entenbach
  description: Wohnstift am Entenbach — IT-Sanierung
  tags: [infrastruktur, seniorenheim]
vault:
  root: 'D:\Obsidian-Vault'
  subfolder: Entenbach
sync:
  include:
    - "*.md"
    - "docs/**/*.md"
    - ".obsidian/**"
  exclude:
    - "raw/**"
    - "scripts/**"
    - ".git/**"
```

Add `.repomind/` to your `.gitignore` — the state file is machine-local.

## Development

```bash
cd tools/repomind
pip install -e ".[dev]"
pytest           # coverage gate >=80%
ruff check .
mypy --strict src
```

## Relationship to the skills

- `/vault-sync` — wraps `repomind sync` and surfaces the result in chat.
- `/vault-bootstrap` — inspects a new repo, proposes `.repomind.yml`,
  seeds the vault subfolder from gold-standard templates, then calls sync.
- `/vault-audit` — inspects a vault subfolder against gold-standard
  structure and reports gaps. No automatic fixes in the MVP.

The CLI is the deterministic engine. The skills are the intelligent layer.
