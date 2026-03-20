---
name: git-hygiene
description: >
  Git repository hygiene check. Stale branches, large files, commit conventions.
  Use when: "git cleanup", "git hygiene", "clean up branches",
  "git-hygiene", "stale branches", "git cleanup".
---

<!-- AI-QUICK-REF
## /git-hygiene — Quick Reference
- **Modes:** scan (all), branches, history, commits
- **Checks:** Stale branches, large files, conventional commits, .gitignore, unmerged branches
- **Output:** Report with findings per category
- **Non-destructive:** Read-only, changes nothing
-->

# /git-hygiene — Git Repository Hygiene

Checks a Git repository for hygiene issues:
stale branches, large files, inconsistent commits.

## Modes

| Mode | Argument | Checks |
|------|----------|--------|
| **scan** | `/git-hygiene` (default) | All 5 checks |
| **branches** | `/git-hygiene branches` | Stale + unmerged branches only |
| **history** | `/git-hygiene history` | Large files in history only |
| **commits** | `/git-hygiene commits` | Conventional commit check only |

## Checks

### 1. Stale Branches

Branches with no commits for >30 days:

```bash
git for-each-ref --sort=committerdate --format='%(refname:short) %(committerdate:relative)' refs/heads/
```

- >30 days: WARNING
- >90 days: Deletion candidate
- Exclude `master`/`main`/`develop`
- Finding: `GIT-01: Branch {name} — last commit {N} days ago`

### 2. Large Files in History

Top 10 largest objects in Git history:

```bash
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk '/^blob/ {print $3, $4}' | sort -rn | head -10
```

- >5MB: WARNING (remove via `git filter-branch` or BFG)
- >50MB: ERROR
- Finding: `GIT-02: {file} is {size}MB in history`

### 3. Conventional Commits

Check last 20 commits:

```bash
git log --oneline -20
```

Valid prefixes: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`, `perf:`, `ci:`, `build:`, `revert:`

- Commit without valid prefix: WARNING
- Calculate compliance rate (X/20)
- Finding: `GIT-03: Commit {hash} has no conventional commit prefix`

### 4. .gitignore Completeness

Check for important entries:

| Entry | Required | Context |
|-------|----------|---------|
| `node_modules/` | If package.json exists | Node.js |
| `.env` | Always | Secrets |
| `.env.local` | Always | Secrets |
| `.env.production` | Always | Secrets |
| `dist/` | If build tool present | Build artifacts |
| `build/` | If build tool present | Build artifacts |
| `.DS_Store` | Always | macOS |
| `Thumbs.db` | Always | Windows |

- Finding: `GIT-04: .gitignore missing entry {entry}`
- Finding: `GIT-05: No .gitignore present`

### 5. Unmerged Branches

Branches not merged into master/main:

```bash
git branch --no-merged master 2>/dev/null || git branch --no-merged main
```

- List with last commit date
- Finding: `GIT-06: Branch {name} is not merged (last commit: {date})`

## Output Format

```
## Git Hygiene: [Project Name]

### 1. Stale Branches
   WARNING: 2 stale branches
   - GIT-01: feature/old-login — last commit 45 days ago
   - GIT-01: hotfix/temp — last commit 120 days ago (deletion candidate)

### 2. Large Files
   OK: No files >5MB in history

### 3. Conventional Commits
   OK: 18/20 commits compliant (90%)
   - GIT-03: abc1234 "quick fix" — no prefix
   - GIT-03: def5678 "update stuff" — no prefix

### 4. .gitignore
   WARNING: 1 missing entry
   - GIT-04: .gitignore missing entry .env.production

### 5. Unmerged Branches
   OK: All branches merged

---
Result: 5 checks, 3 OK, 2 WARNING, 0 ERROR
```

## Rules

- **Read-only** — does not delete branches, changes nothing
- Works with any Git repository
- Check remote branches only if `origin` is reachable
- No force-push recommendations without explicit request
