---
name: audit-runner
description: >
  Autonomous audit runner (separate sessions, no context limit).
  Use when: "audit-runner", "autonomous audit", "audit automatically".
disable-model-invocation: true
---

<!-- AI-QUICK-REF
## /audit-runner — Quick Reference
- **Modes:** setup | start | status
- **Script:** audit-runner.sh (Bash, each phase in its own `claude -p` session)
- **State:** Uses existing .audit-state.json / .project-audit-state.json / .astro-audit-state.json / .sveltekit-audit-state.json / .db-audit-state.json / .auth-audit-state.json
- **Options:** --audits, --timeout, --max-retries, --dry-run, --skip-orchestrator, --batch
- **Logs:** .audit-runner-logs/ (per session)
- **Checkpoints:** [CHECKPOINT: manual] at setup (Playwright install, claude -p verify)
-->

# /audit-runner — Autonomous Audit Run

Runs all audits (/audit, /astro-audit, /project-audit, /sveltekit-audit, /db-audit, /auth-audit) fully autonomously —
without user interaction. Each phase runs in its own Claude session, so
there is no context limit.

## Problem

A complete 6-audit run requires many manual sessions. The user has to
type `/audit continue` in each session, wait, start the next session — for hours.

## Solution

A Bash script (`audit-runner.sh`) that controls Claude Code via `claude -p`:

1. Call orchestrator (create audit plan)
2. Run each audit via `claude -p` in separate sessions
3. Check state after each session (all phases done?)
4. Generate reports
5. Summary at the end

**Core principle:** Each `claude -p` call = new session = full context.
The state files (.audit-state.json etc.) are the bridge between sessions.

---

## 3 Modes

| Mode | Trigger | Description |
|------|---------|-------------|
| `setup` | `/audit-runner setup` | Check prerequisites, explain usage |
| `start` | `/audit-runner start` | Generate runner command for current project |
| `status` | `/audit-runner status` | Show results from logs and state files |

---

## Mode: setup

### Step 1 — Check Prerequisites

Check the following and show to the user:

1. **Claude Code CLI:** Run `claude --version`
2. **Node.js:** Run `node --version`
3. **Script path:** Check if `~/.claude/skills/audit-runner/audit-runner.sh` exists
4. **Audit skills:** Check if `/audit`, `/astro-audit`, `/project-audit`, `/sveltekit-audit`, `/db-audit`, `/auth-audit` skills are available

### Step 2 — Explain Config (optional)

If the user wants specific settings, they can create a config file in the project.
Show template:

`.audit-runner-config.json`:
```json
{
  "audits": ["audit", "astro-audit", "project-audit", "sveltekit-audit", "db-audit", "auth-audit"],
  "timeout": 600,
  "maxRetries": 3,
  "skipOrchestrator": false
}
```

Without config: runner uses defaults (all 6 audits, 600s timeout, 3 retries).

### Step 3 — Show Usage

```bash
# All audits (default)
bash ~/.claude/skills/audit-runner/audit-runner.sh /path/to/project

# Only specific audits
bash ~/.claude/skills/audit-runner/audit-runner.sh /path/to/project --audits "audit,project-audit"

# Dry run (show plan only)
bash ~/.claude/skills/audit-runner/audit-runner.sh /path/to/project --dry-run
```

---

## Mode: start

1. Briefly check prerequisites (claude, node, script present)
2. Detect current project (pwd)
3. Generate matching command:

```bash
bash ~/.claude/skills/audit-runner/audit-runner.sh "CURRENT_PROJECT_PATH"
```

4. Explain to the user:
   - Run the command in a **separate terminal** (not inside Claude Code)
   - The runner runs autonomously, may take hours
   - `--dangerously-skip-permissions` is built in (required for autonomous operation)
   - View results afterwards with `/audit-runner status`

5. If the user asks which audits make sense:
   - Scan project (package.json, Dockerfile etc.)
   - Give recommendation (e.g., no Astro/SvelteKit → `--audits "audit,project-audit,db-audit,auth-audit"`)

---

## Mode: status

1. Check log directory: `.audit-runner-logs/`
2. Read summary: `.audit-runner-logs/summary.json`
3. Read state files: `.audit-state.json`, `.astro-audit-state.json`, `.project-audit-state.json`, `.sveltekit-audit-state.json`, `.db-audit-state.json`, `.auth-audit-state.json`
4. List reports: `AUDIT-REPORT-*.md`, `PROJECT-AUDIT-REPORT-*.md`

Show everything as overview:

```
Audit Runner Status: {{PROJECT_NAME}}

Last Run: 2026-02-18 14:30
Duration: 45 minutes

/audit:          Completed (12 findings in 3 sessions)
/astro-audit:    Completed (8 findings in 2 sessions)
/project-audit:  Completed (5 findings in 2 sessions)
/sveltekit-audit: Completed (6 findings in 2 sessions)
/db-audit:       Completed (4 findings in 1 session)
/auth-audit:     Completed (3 findings in 1 session)

Total: 38 findings (3 CRITICAL, 7 HIGH, 18 MEDIUM, 10 LOW)

Reports:
  AUDIT-REPORT-2026-02-18.md
  PROJECT-AUDIT-REPORT-2026-02-18.md

Recommendation: Fix 2 CRITICAL findings first (SEC-01, MIG-03)
```

If no run found: "No runner run found. Start with `/audit-runner start`."

---

## Script: audit-runner.sh

Located at `~/.claude/skills/audit-runner/audit-runner.sh` (deployed via setup.sh).

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--audits` | `audit,astro-audit,project-audit,sveltekit-audit,db-audit,auth-audit` | Comma-separated audit list |
| `--timeout` | `600` | Timeout per session in seconds |
| `--max-retries` | `3` | Max retries on error |
| `--dry-run` | — | Show plan only, don't execute |
| `--skip-orchestrator` | — | Skip orchestrator phase |
| `--batch` | — | Audit all git repos in directory |
| `--depth` | `3` | Search depth for `--batch` (how many directory levels) |

### Internal Process

```
audit-runner.sh /path/to/project
│
├─ Check prerequisites (claude, node)
├─ Create log directory (.audit-runner-logs/)
│
├─ Phase 1: Orchestrator
│   └─ claude -p → .audit-orchestrator-state.json
│       → Reads activeAudits and follows recommendation
│
├─ Phase 2-7: Per audit (audit, astro-audit, project-audit, sveltekit-audit, db-audit, auth-audit)
│   ├─ claude -p "/{audit-name} auto" (tries all phases)
│   ├─ Check state (.{audit-name}-state.json)
│   │   ├─ All done → generate report
│   │   └─ Still open → claude -p "/{audit-name} continue" (loop)
│   └─ claude -p "/{audit-name} report"
│
└─ Summary
    ├─ Duration, findings per audit
    └─ summary.json + runner-*.log
```

### State Files as Bridge

The runner reads after each session:
- `.audit-state.json` → `phases.*.status`
- `.astro-audit-state.json` → `areas.*` status
- `.project-audit-state.json` → `phases.*.status`
- `.sveltekit-audit-state.json` → `phases.*.status`
- `.db-audit-state.json` → `phases.*.status`
- `.auth-audit-state.json` → `phases.*.status`

When all statuses are `done` or `skipped` → audit completed.

### Error Handling

| Situation | Behavior |
|-----------|----------|
| Claude error | Up to 3 retries with 15s pause |
| Timeout | Each session max 600s (configurable) |
| No state after auto | Fallback to `start` |
| Max sessions reached | Abort after 8 sessions per audit |
| Already completed | Skip audit, report only |

### Output Files

```
.audit-runner-logs/
├── runner-20260218-143000.log    # Main log with timestamps
├── session-143001.log            # Individual session outputs
├── session-143215.log
├── ...
└── summary.json                  # Machine-readable result
```

---

## Batch Mode

With `--batch`, all git repos in a directory are audited sequentially:

```bash
bash ~/.claude/skills/audit-runner/audit-runner.sh /path/to/parent --batch
```

### Process

1. Search for git repos up to specified depth (`--depth`, default 3)
2. List found repos
3. Run a complete audit runner pass for each repo
4. Show batch summary at the end (success/failure per repo)

### Batch Options

```bash
# Search only 1 level deep (direct subdirectories)
bash audit-runner.sh /path --batch --depth 1

# Batch with specific audits
bash audit-runner.sh /path --batch --audits "audit,project-audit"

# Dry run: only show which repos are found
bash audit-runner.sh /path --batch --dry-run
```

### Output

- Each repo gets its own `.audit-runner-logs/` and state files
- Batch log: `<parent>/.audit-runner-batch/batch-*.log`
- At the end: summary with success/failure per repo

---

## Rules

- **Runner is external** — runs in a separate terminal, NOT within a Claude session
- **No fixing** — runner only documents findings, user fixes manually afterwards
- **State is king** — on interruption: restart runner, it resumes from last state
- **--dangerously-skip-permissions** is required for autonomous operation
- **Keep logs** — each run creates its own log file (not overwritten)
- **Config optional** — without config: all 6 audits with default settings
