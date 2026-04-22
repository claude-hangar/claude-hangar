---
name: vault-audit
description: >
  Audit an Obsidian vault subfolder against the gold-standard structure:
  Dashboard presence, INDEX completeness, _INDEX per area, frontmatter
  validity, broken internal links, tag hierarchy. Produces a findings report
  with severity; no automatic fixes in the MVP. Use when: "vault audit",
  "check vault structure", "vault gold-standard", "/vault-audit".
effort: medium
user-invocable: true
argument-hint: "<subfolder-name-or-path>"
---

<!-- AI-QUICK-REF
## /vault-audit — Quick Reference
- **Input:** subfolder path inside the vault (absolute or name resolved against vault root)
- **Output:** findings report INFO/WARN/ERROR with fix suggestions
- **No writes.** The MVP only reports. Re-run with `/vault-bootstrap` if
  structural issues warrant a rebuild.
-->

# /vault-audit — Gold-standard check for a vault subfolder

Given a vault subfolder, verify that it follows the gold-standard structure
used across the central Obsidian vault. Report gaps. Do not fix them.

## Inputs

- Argument (optional): subfolder name or absolute path.
- If argument is a bare name (e.g. "Entenbach"), resolve against the
  configured vault root (from `.repomind.yml` in cwd, or prompt the user).
- If argument is absolute, use as-is.

## Checks

### A — Structural presence (ERROR if missing)

- `Dashboard.md` in the subfolder root
- `docs/INDEX.md` — top-level navigation index
- `_INDEX.md` in every direct child of `docs/` that contains more than one
  `.md` file (areas without an _INDEX are orphans)
- `OBSIDIAN-SETUP.md` — bootstrap help, one-pager

### B — Frontmatter validity (WARN on violation)

For every `.md` file under the subfolder (except `_deleted/`):

- Has YAML frontmatter block (`---` at top)
- `title:` field present and non-empty
- `stand:` field is a valid ISO date (`YYYY-MM-DD`)
- `status:` one of `aktiv`, `historie`, `verworfen`, `archiv`
- `tags:` is a list (not a single string)

### C — Link integrity (ERROR on broken, INFO on external)

- Every internal wiki-link `[[target]]` resolves to an existing file or
  heading inside the subfolder
- Every relative markdown link `[text](path.md)` resolves
- External links (`http://`, `https://`) are reported as INFO (not checked)

### D — Tag hygiene (WARN)

- Tag hierarchy follows `typ/`, `status/`, `thema/`, `phase/`, `prio/`
  prefixes as used across the gold standard
- Flag tags that are singletons (used exactly once) — possible typos

### E — Dashboard content (INFO)

- `Dashboard.md` references `docs/INDEX.md`
- `Dashboard.md` has navigation blocks for each area detected under `docs/`
- `Dashboard.md` has a "Kennzahlen" or equivalent quick-facts section

### F — Orphan detection (INFO)

- Any `.md` file with no incoming wiki-links is an orphan candidate
- Exclude: `Dashboard.md`, `STATUS.md`, `README.md`, `CLAUDE.md`,
  `OBSIDIAN-SETUP.md`, `docs/INDEX.md`, `_INDEX.md` in any folder

## Output format

```
Vault audit — <SUBFOLDER>
  structure:    ✓ PASS (A: 4/4 present)
  frontmatter:  ⚠ 3 WARN  (files missing `stand` field)
  links:        ✗ 2 ERROR (broken internal links)
  tags:         ⚠ 5 WARN  (singleton tags — possibly typos)
  dashboard:    ℹ INFO  (missing "Kennzahlen" section)
  orphans:      ℹ 2 INFO

## Findings

ERROR — docs/infra/firewall.md:12 — broken link [[does-not-exist]]
ERROR — docs/management/teamviewer.md:34 — broken link [[wrong-target]]
WARN  — docs/referenz/offene-fragen.md — frontmatter missing `stand`
...

## Fix suggestions

- Broken link in firewall.md → check if target was renamed/archived
- 5 singleton tags → review via Tag Wrangler plugin, possibly merge
- ...
```

## Rules

- **Read-only.** Never write to the vault from this skill.
- **Keep the report under 200 lines.** If a category has more than 20
  findings, show the top 10 + a count of the rest.
- **No opinions beyond the checks.** Don't suggest content changes, just
  structural ones.
- **Respect `_deleted/`.** Never audit files under `_deleted/`, those are
  retirement-trash.

## Related

- `/vault-bootstrap` — rebuild the subfolder if the audit finds structural
  issues that warrant a reset
- `/vault-sync` — routine syncing
