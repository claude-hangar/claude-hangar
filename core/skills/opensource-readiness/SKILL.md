---
name: opensource-readiness
description: >
  Pre-publication audit for repositories about to go public or already public. Catches
  what other skills miss: secrets in git history (not just HEAD), license compliance,
  internal references (private URLs, internal hostnames, employee names), trademark
  exposure, attribution gaps, and community-readiness gaps (CONTRIBUTING, CODE_OF_CONDUCT,
  SECURITY.md, LICENSE headers). Use when: "open source readiness", "ready to publish",
  "going public", "pre-publish audit", "publish check", "open-source audit".
effort: high
user-invocable: true
argument-hint: "scan | full | history"
---

<!-- AI-QUICK-REF
## /opensource-readiness — Quick Reference
- **Modes:** scan (HEAD only, fast) | full (HEAD + community readiness) | history (git log scan, slow)
- **10 Lens Categories** — adapted from RepoLens open-source-readiness domain (13 lenses consolidated into 10 for Hangar)
- **Finding-IDs:** OSR-S-01 (secrets), OSR-L-01 (license), OSR-I-01 (internal exposure),
  OSR-G-01 (git history), OSR-C-01 (community), OSR-D-01 (docs), OSR-A-01 (attribution),
  OSR-B-01 (branding), OSR-P-01 (PII), OSR-R-01 (reproducibility)
- **Severity:** CRITICAL (do not publish) > HIGH > MEDIUM > LOW (Hangar-wide convention, no BLOCKER tier)
- **State:** .opensource-readiness-state.json
- **Complements:** security-scan (Claude Code config) and secret-leak-check hook (HEAD only)
-->

# /opensource-readiness — Pre-Publication Audit

Audit a repository for everything that becomes a problem the moment it goes public.
Read-only by default. Reports findings; never rewrites git history automatically.

## Why a Dedicated Skill

`security-scan` checks Claude Code config (MCP, hooks, settings). The `secret-leak-check`
hook scans HEAD on commit. Neither covers:

- **Secrets in git history** (rotated locally but still in `git log -p`)
- **License compliance** of dependencies (GPL contamination, missing notices)
- **Internal URLs/hostnames** (`*.internal`, `vpn.company.com`, Jira IDs, employee emails)
- **Branding/trademark exposure** (former employer logos, vendor marks)
- **Community-readiness gaps** (no CONTRIBUTING, no CODE_OF_CONDUCT, no SECURITY.md)
- **Attribution gaps** (vendored code without LICENSE/NOTICE, missing AUTHORS)
- **PII leakage** (real names in test fixtures, customer IDs in seed data)
- **Build reproducibility** (lockfiles missing, Docker images not pinned)

This skill targets exactly that gap. Inspired by RepoLens' `open-source-readiness` domain
(13 lenses), adapted to Hangar's report format and Claude Code workflow.

## Modes

| Mode | When | Cost |
|------|------|------|
| `scan` (default) | Quick HEAD-only sweep before first publish | Low |
| `full` | scan + community-readiness + attribution check | Medium |
| `history` | Adds full `git log -p` secret scan (can be slow on large repos) | High |

## The 10 Lens Categories

Each category is a single-concern check. All are independent; the orchestrator runs them
in parallel where possible.

### OSR-S — Secret Leaks (HEAD)
Same patterns as `secret-leak-check.sh` hook but applied to the entire working tree, not
just staged changes. Flags: API keys, JWT tokens, AWS keys, private keys, database URLs
with embedded passwords, `.env` files committed by accident.

### OSR-G — Git History Secrets (history mode only)
Secrets rotated in HEAD but still recoverable via `git show <old-sha>` remain leaked.
**Performance warning:** `git log --all -p -G '<pattern>'` on a 10k+ commit repo takes
minutes to hours. Lens enforces a wall-clock time cap via
`HANGAR_OSR_HISTORY_MAX_SECONDS` (default 120) and an optional `--since <date>`
scope limit. For large repos, lens recommends delegating to a dedicated scanner
(`gitleaks detect --redact --log-opts='--all --since=<date>'` or `trufflehog git`)
rather than pattern-by-pattern git traversal. Recommends `git filter-repo` or BFG
with concrete commands for remediation; never executes them.

### OSR-L — License Compliance
- Project has a LICENSE file at root.
- LICENSE matches what `package.json` / `pyproject.toml` / `Cargo.toml` declares.
- All direct dependencies are license-compatible (no GPL contamination in MIT/Apache projects).
- Vendored code (`vendor/`, `third_party/`) carries its original LICENSE + NOTICE.

### OSR-I — Internal Exposure
Pattern-based scan for: `*.internal`, `*.intranet`, `*.corp`, `vpn.*`, internal Jira IDs
(`PROJ-1234`), Confluence links, internal Slack channels, employee email patterns
(`firstname.lastname@company.com` for the user's known company).

### OSR-C — Community Readiness
Required files for a healthy open-source project:
- `README.md` (with installation, usage, license sections)
- `LICENSE`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md` (vulnerability disclosure policy)
- `.github/ISSUE_TEMPLATE/` (bug report + feature request)
- `.github/PULL_REQUEST_TEMPLATE.md`
- `CHANGELOG.md` (or release notes practice)

### OSR-D — Documentation Gaps
- README has installation, quickstart, contributing pointer, license badge.
- Public APIs documented (heuristic: exported functions in `src/` that lack docstrings).
- No "TODO: document this" markers in public-facing files.

### OSR-A — Attribution
- All vendored code carries original copyright/license.
- `package.json` `author` / `contributors` populated.
- AUTHORS or CONTRIBUTORS file present (optional but recommended).
- No removed copyright headers (heuristic: forked repos with stripped notices).

### OSR-B — Branding & Trademark
- No logos/marks of former employers in `assets/`, `public/`, `docs/`.
- Repo name not infringing on a known trademark (manual review only — tool flags suspicious names).
- No "Powered by [vendor logo]" without permission.

### OSR-P — PII in Code & Fixtures
- Test fixtures use synthetic data (no real names, real emails, real phone numbers).
- Seed data contains no real customer/user records.
- Screenshots in `docs/` redact identifying info.

### OSR-R — Build Reproducibility
- Lockfile present and committed (`package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`,
  `Cargo.lock`, `go.sum`).
- Dockerfiles pin base images by digest, not just tag.
- `.tool-versions` / `.nvmrc` / `.python-version` declare the runtime.
- CI uses pinned action versions (no `@main`, no floating `@v3`).

## Output

Standard Hangar report format:

```markdown
# Open-Source Readiness Report — <repo> — <date>

**Verdict:** READY | NOT READY (N critical blockers) | NEEDS REVIEW

## Findings (grouped by severity)

### CRITICAL — must fix before publishing
- OSR-S-01 (file:line) — AWS access key found in `src/config.ts`
- OSR-G-03 (commit a1b2c3d) — `OPENAI_API_KEY` recoverable in git history (rotate + filter-repo)
- OSR-L-01 — Missing LICENSE file at repo root

### HIGH
- OSR-I-02 (5 files) — Internal hostname `vpn.acme.corp` referenced

### MEDIUM / LOW
...

## Recommended actions
1. Rotate exposed credentials before any publish (highest priority)
2. Run `git filter-repo --invert-paths --path .env` then force-push
3. Add LICENSE + SECURITY.md (templates suggested below)

## State written to
`.opensource-readiness-state.json`
```

## State Schema

```json
{
  "lastRun": "2026-04-18T10:00:00Z",
  "mode": "scan|full|history",
  "verdict": "ready|not-ready|needs-review",
  "summary": { "critical": 0, "high": 0, "medium": 0, "low": 0 },
  "findings": [
    {
      "id": "OSR-S-01",
      "severity": "critical",
      "lens": "secret-leaks",
      "file": "src/config.ts",
      "line": 42,
      "commit_sha": null,
      "message": "AWS access key pattern detected",
      "recommendation": "Move to environment variable, rotate key"
    },
    {
      "id": "OSR-G-03",
      "severity": "critical",
      "lens": "git-history",
      "file": null,
      "line": null,
      "commit_sha": "a1b2c3d",
      "message": "OPENAI_API_KEY recoverable in historical commit",
      "recommendation": "Rotate key, then rewrite history via filter-repo + force-push"
    }
  ]
}
```

## Rules

- **Read-only.** Never modifies files, never rewrites git history. Suggests commands
  for the user to run themselves.
- **No false intimacy with private data.** When flagging PII or internal identifiers,
  do not echo the value into the report. Use a truncation pattern (`jo***@l***.com`)
  rather than a hash — short strings like emails are trivially reversible against a
  rainbow table even when hashed.
- **Internal-domain detection.** OSR-I needs to know "what is internal" — lens reads
  `git config user.email` to derive the likely company domain, and also accepts an
  explicit `HANGAR_OSR_INTERNAL_DOMAINS` env var (comma-separated). Falls back to a
  generic pattern scan if neither is available.
- **License-compatibility matrix.** OSR-L distinguishes: MIT/BSD/Apache-2.0 mutually
  compatible; LGPL OK as dynamic dependency; MPL-2.0 file-level copyleft;
  GPL/AGPL viral. AGPL is flagged separately since it affects network-deployed code.
- **History mode is opt-in** and subject to `HANGAR_OSR_HISTORY_MAX_SECONDS`
  (default 120). On timeout, lens reports "partial scan — delegate to gitleaks/trufflehog".
- **Complements, does not replace,** `security-scan` (Claude Code config focus) and
  the `secret-leak-check` hook (HEAD on commit). Secret-pattern list is shared via
  `core/lib/secret-patterns.json` (single source of truth for both).
- **Trademark/branding lens is advisory only.** Tool cannot verify trademark status —
  flags suspicious patterns for human review.

## Related

- Pattern inspired by RepoLens `prompts/lenses/open-source-readiness/` (13 lenses)
- Complements `/security-scan`, `/git-hygiene`, `secret-leak-check` hook
- Use before `gsd-ship` or any first public release
