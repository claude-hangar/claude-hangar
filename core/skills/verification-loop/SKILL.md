---
name: verification-loop
description: Pre-PR verification pipeline that runs build, types, lint, test, security, and diff review in sequence. Use before creating a PR or merging.
user_invocable: true
---

# /verify — Pre-PR Verification Loop

Systematic 6-phase quality check before any PR or merge. Catches issues
that would otherwise become review comments or CI failures.

## Usage

```
/verify              # Full 6-phase verification
/verify quick        # Phases 1-4 only (skip security + diff review)
/verify security     # Security phase only
```

## The 6 Phases

Run each phase in order. Stop on first failure, fix, then restart.

### Phase 1: Build
```bash
# Detect and run the project's build command
npm run build    # Node.js
go build ./...   # Go
cargo build      # Rust
python -m py_compile *.py  # Python
```
**Pass criteria:** Exit code 0, no errors in output.

### Phase 2: Type Check
```bash
npx tsc --noEmit          # TypeScript
mypy src/                 # Python
go vet ./...              # Go
cargo check               # Rust
```
**Pass criteria:** Zero type errors.

### Phase 3: Lint
```bash
npx eslint . --max-warnings 0   # JS/TS
ruff check .                     # Python
golangci-lint run                # Go
cargo clippy -- -D warnings      # Rust
shellcheck **/*.sh               # Shell
```
**Pass criteria:** Zero warnings (not just zero errors).

### Phase 4: Test
```bash
npm test                  # Node.js
pytest --cov=src          # Python
go test -race ./...       # Go
cargo test                # Rust
```
**Pass criteria:** All tests pass. Coverage >= 80%.

### Phase 5: Security Scan
- Check for hardcoded secrets (grep for API keys, tokens, passwords)
- Run `npm audit` / `pip audit` / `go vet`
- Check for common vulnerabilities (SQL injection, XSS, CSRF)
- Verify no .env files are staged

**Pass criteria:** No critical or high severity findings.

### Phase 6: Diff Review
```bash
git diff main...HEAD --stat
git diff main...HEAD
```
- Review all changes for:
  - Unintended file modifications
  - Debug code left in (console.log, print, debugger)
  - TODO/FIXME comments that should be resolved
  - Large files that should be split
  - Missing test coverage for new code

**Pass criteria:** No unintended changes, no debug code.

## Output Format

```
## Verification Results

| Phase | Status | Details |
|-------|--------|---------|
| Build | PASS | No errors |
| Types | PASS | 0 type errors |
| Lint | FAIL | 3 warnings in src/auth.ts |
| Test | SKIP | (blocked by lint failure) |
| Security | SKIP | |
| Diff Review | SKIP | |

### Action Required
Fix lint warnings in src/auth.ts, then re-run /verify.
```

## Philosophy

**Fix forward, not around.** When a phase fails:
1. Fix the actual issue (not suppress the warning)
2. Re-run from Phase 1 (earlier fixes may introduce new issues)
3. Only proceed when all phases pass

Inspired by ECC's verification-loop and GSD v2's verification commands.
