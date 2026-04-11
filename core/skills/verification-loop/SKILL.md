---
name: verification-loop
description: Pre-PR verification pipeline with plan validation, build, types, lint, test, security, diff review, and consistency checks. Verification gate — use before creating a PR or merging.
user-invocable: true
argument-hint: ""
---

# /verify — Pre-PR Verification Loop

Systematic quality gate before any PR or merge. Validates plans before
execution, runs 6 core verification phases, then checks post-execution
consistency. Catches issues that would otherwise become review comments,
CI failures, or hallucination cascades.

## Usage

```
/verify              # Full 6-phase verification
/verify quick        # Phases 1-4 only (skip security + diff review)
/verify security     # Security phase only
```

## Phase 0: Pre-Execution Plan Validation

When an implementation plan exists (e.g. from the planner agent or a
STATUS.md task list), run these sanity checks **before** any code is written:

1. **File existence** — Verify that key files referenced in the plan
   actually exist in the repo (`ls`, `test -f`). Flag phantom paths early.
2. **Dependency availability** — Confirm that packages/dependencies
   referenced are installable (`npm view <pkg>`, `pip index versions <pkg>`,
   `cargo search <crate>`). Catch typos and yanked versions before they
   become build failures.
3. **Circular dependency check** — Scan the plan for import/dependency
   cycles between proposed modules. A → B → C → A breaks at build time;
   catch it at plan time.

**Pass criteria:** All referenced files exist (or are explicitly marked as
"to be created"), all dependencies resolve, no circular references detected.

> **Tip:** This phase is cheap and fast. Run it even for small plans — the
> cost of skipping it is a wasted verification cycle later.

---

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

---

## Phase 7: Post-Execution Consistency Checks

After all 6 phases pass, run these additional checks to catch
"hallucination cascades" — generated code that references nonexistent
modules, mismatched signatures, or missing test files.

1. **Import resolution** — For every changed file, verify that all imports
   resolve to real modules. Catches phantom imports that compile in one
   context but fail in another.
   ```bash
   # TypeScript: tsc will catch most, but also check dynamic imports
   # Python: python -c "import ast; ..." or use importlib
   # Go: go build already validates, but check test files too
   ```
2. **Signature drift** — Verify that function/method signatures in changed
   files match their callers. A renamed parameter or changed return type in
   one file can silently break consumers.
3. **Test correspondence** — Every new source file or public function must
   have a corresponding test. Check that `foo.ts` has `foo.test.ts`, that
   new exported functions appear in test files.
4. **Dead export detection** — Flag exports in changed files that have zero
   consumers (potential leftover from refactoring).

**Pass criteria:** All imports resolve, no signature mismatches between
callers and callees, every new public API has test coverage.

## Output Format

```
## Verification Results

| Phase | Status | Details |
|-------|--------|---------|
| Plan Validation | PASS | 3 files verified, 2 deps resolved |
| Build | PASS | No errors |
| Types | PASS | 0 type errors |
| Lint | FAIL | 3 warnings in src/auth.ts |
| Test | SKIP | (blocked by lint failure) |
| Security | SKIP | |
| Diff Review | SKIP | |
| Consistency | SKIP | |

### Action Required
Fix lint warnings in src/auth.ts, then re-run /verify.
```

## Verification Evidence Persistence

After every verification run (pass or fail), write a `VERIFY-EVIDENCE.json`
file to the project root. This enables CI integration, trend tracking across
sessions, and provides auditable proof of verification.

```json
{
  "timestamp": "2026-04-09T14:32:00Z",
  "result": "pass",
  "checks": {
    "planValidation": "pass",
    "build": "pass",
    "types": "pass",
    "lint": "warn",
    "test": "pass",
    "security": "pass",
    "diffReview": "pass",
    "consistency": "pass"
  },
  "coverage": "82%",
  "diffStats": {
    "files": 5,
    "insertions": 120,
    "deletions": 30
  },
  "duration": "45s"
}
```

**Rules:**
- Always overwrite, never append (latest run = current state).
- Add `VERIFY-EVIDENCE.json` to `.gitignore` — it is a local artifact, not
  committed. CI can produce its own from pipeline output.
- On failure, `result` is `"fail"` and failing checks show `"fail"` with an
  optional `"details"` string.
- The file is machine-readable by design — hooks, CI scripts, and the
  statusline can consume it.

## Verification Gate Pattern

**Verification is a gate, not an optional step.**

Work must NOT be marked as "complete", "done", or "ready for review" until
the full verification loop passes. This is a hard rule, not a suggestion.

The sequence is always:

> **IDENTIFY** the change → **RUN** verification → **READ** the output →
> **VERIFY** all phases pass → **CLAIM** completion.

Skipping any step produces a **Phantom Fix** — code that appears correct
but has never been proven correct. Phantom Fixes are the single most
common anti-pattern in AI-assisted development.

**Enforcement:**
- The `/verify` skill must run before any commit message claims a fix or
  feature is complete.
- If verification fails, the work is **not done** — regardless of how
  confident the implementation looks.
- STATUS.md should reflect verification state: "implemented" is not
  "verified".

## Philosophy

**Fix forward, not around.** When a phase fails:
1. Fix the actual issue (not suppress the warning)
2. Re-run from Phase 1 (earlier fixes may introduce new issues)
3. Only proceed when all phases pass

Inspired by ECC's verification-loop and GSD v2's verification commands.
