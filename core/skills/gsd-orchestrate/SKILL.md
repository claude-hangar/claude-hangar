---
name: gsd-orchestrate
description: >
  Orchestrates GSD v1 end-to-end (map → discuss → plan → execute → verify) with three intelligence modes.
  Default: checkpoint mode (ask on architecture only). Full-auto for overnight batch runs across multiple projects.
  Always uses Opus-grade reasoning — never generic defaults. Use when: "gsd orchestrate", "autonomous gsd run",
  "over night optimize", "batch optimize projects", "gsd-orchestrate".
effort: high
user-invocable: true
argument-hint: "<goal> [--mode=checkpoint|full-auto|assisted] [--batch=<file>] [--to=<phase>]"
---

<!-- AI-QUICK-REF
## /gsd-orchestrate — Quick Reference
- **Prerequisite:** GSD v1.34+ installed globally (`npx get-shit-done-cc --claude --global`)
- **Three modes:** checkpoint (default) | full-auto | assisted
- **Full-auto rule:** ALWAYS Opus, ALWAYS evidence-based, NEVER generic defaults
- **Answer discipline:** Read project context BEFORE answering every GSD question
- **Batch mode:** --batch=projects.txt → overnight run across multiple repos
- **Safety:** Pre-flight validation, auto feature branch, rate-limit backoff, resource guards
- **Always use --dry-run first** for new batch configurations
- **Headless:** `claude -p` + `--notify=file:<path>` for true overnight runs
- **Scheduled:** Via Hangar `/schedule` skill (cron-style)
- **State:** .gsd-orchestrate-state.json per project
- **Reports:** .planning/orchestrator/run-<timestamp>.md with decision log + per-phase diffs
- **Rollback:** /gsd-orchestrate rollback <batch-id>
-->

# /gsd-orchestrate — Intelligent GSD v1 Automation

Meta-skill that drives GSD v1 through its full lifecycle (map → milestone → discuss → plan → execute → verify) with three intelligence levels and an evidence-first answering protocol.

## Why this skill exists

GSD v1 has `/gsd-autonomous` and `--auto` flags already. These pick "recommended defaults" — which produce generic output. This orchestrator adds:

1. **Project-aware answers** — Reads CLAUDE.md, STATUS.md, package.json, git history, code structure before answering any GSD question
2. **Opus-grade reasoning** — Every answer goes through a structured reasoning step, never shortcut defaults
3. **Checkpoint gates** — Pauses only for architecture/trade-off decisions, not for routine choices
4. **Batch mode** — Run multiple projects sequentially overnight with per-project isolation
5. **Decision log** — Every answer is documented with its reasoning for later audit

## Three Modes

| Mode | When to use | User prompts | Opus delegation |
|---|---|---|---|
| **checkpoint** (default) | Production code, unfamiliar projects | Only on architecture / irreversible trade-offs | All GSD subagents |
| **full-auto** | Overnight batch runs, prototypes, well-understood repos | Never — fully autonomous | All GSD subagents + answer generator |
| **assisted** | Learning GSD, critical code, first-time use | On every phase question | All GSD subagents |

## Prerequisites

```bash
# Verify GSD v1 is installed globally
ls ~/.claude/skills/ | grep -c gsd    # expect >= 60
cat ~/.claude/get-shit-done/VERSION   # expect 1.34.x or higher
```

If GSD is missing:

```bash
npx get-shit-done-cc --claude --global
```

## Command Syntax

```
/gsd-orchestrate <goal> [options]
```

| Option | Values | Default | Meaning |
|---|---|---|---|
| `--mode` | `checkpoint` \| `full-auto` \| `assisted` | `checkpoint` | Intelligence / autonomy level |
| `--batch` | path to text file | none | One project path per line — process sequentially |
| `--to` | phase number | last phase | Stop after this phase |
| `--skip-map` | flag | false | Skip `/gsd-map-codebase` (use existing `.planning/codebase/`) |
| `--skip-verify` | flag | false | Skip final verification phase |
| `--model` | `opus` \| `inherit` | `opus` | Forced model for all GSD subagent calls |
| `--dry-run` | flag | false | Preview only — show what would happen, no changes, no commits |
| `--branch-prefix` | string | `gsd/` | Feature branch prefix per project (auto-isolation) |
| `--no-branch` | flag | false | Disable auto feature branch (not recommended) |
| `--token-budget` | integer | 500000 | Token cap per project (batch mode) |
| `--notify` | `file` \| `webhook:<url>` | none | Notification when run finishes |
| `--retry-max` | integer | 3 | Max retries per GSD subagent call on transient errors |

## Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Step 0  Preflight — GSD installed? Disk? Goal clear?       │
│          Batch: validate ALL projects upfront               │
├─────────────────────────────────────────────────────────────┤
│  Step 1  Create feature branch: gsd/<ts>-<slug>             │
│          (off current HEAD; main untouched)                 │
├─────────────────────────────────────────────────────────────┤
│  Step 2  /gsd-map-codebase                                  │
│          → .planning/codebase/{stack,architecture,...}.md   │
├─────────────────────────────────────────────────────────────┤
│  Step 3  /gsd-new-milestone "<goal>"                        │
│          → PROJECT.md, REQUIREMENTS.md, ROADMAP.md          │
├─────────────────────────────────────────────────────────────┤
│  Step 4  For each phase in ROADMAP.md:                      │
│          4a  /gsd-discuss-phase  — intercept questions,     │
│              answer via Opus with project-aware context     │
│          4b  /gsd-plan-phase     — create PLAN.md           │
│          4c  [CHECKPOINT: architecture review]              │
│              (skipped in full-auto)                         │
│          4d  /gsd-execute-phase  — wave-parallel execution  │
│          4e  /gsd-verify-work    — UAT validation           │
│          4f  Diff summary → .planning/orchestrator/diffs/   │
├─────────────────────────────────────────────────────────────┤
│  Step 5  /gsd-audit-milestone   — final consistency check   │
├─────────────────────────────────────────────────────────────┤
│  Step 6  Push feature branch with -u                        │
│          (enables PR creation from GitHub UI)               │
├─────────────────────────────────────────────────────────────┤
│  Step 7  Generate orchestrator report                       │
│          → .planning/orchestrator/run-<ts>.md               │
│          Fire notification (if --notify set)                │
└─────────────────────────────────────────────────────────────┘
```

## The Answer Discipline (full-auto mode)

**Fixed rule: NEVER answer a GSD question with a generic default.**

Every answer follows this protocol:

### 1. Load evidence

Before answering, load into context:
- `CLAUDE.md` (project instructions)
- `STATUS.md` (current state, if present)
- `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` (stack)
- `.planning/codebase/*.md` (GSD's own scan)
- Recent `git log --oneline -20` (activity)
- `README.md` top 50 lines
- Relevant source files (sampled via Grep for the topic of the question)

### 2. Reason with Opus

Dispatch to an Opus subagent with this prompt shape:

```
You are answering a GSD v1 planning question on behalf of the project owner.

GSD question: {question}
GSD context: {gsd_context}

Evidence (read carefully before answering):
- CLAUDE.md: {...}
- STATUS.md: {...}
- Stack: {...}
- Recent activity: {...}
- Relevant code: {...}

Rules:
1. Answer ONLY with project-specific information found in the evidence.
2. If evidence is insufficient, respond: "INSUFFICIENT_EVIDENCE: <what is missing>".
3. Prefer existing patterns over introducing new ones.
4. Cite the evidence file and line that supports your answer.
5. No hedging — commit to a decision or flag the gap.

Output format:
<answer>
<reasoning>
<citations>
```

### 3. Gate on checkpoint

| Response | checkpoint mode | full-auto mode |
|---|---|---|
| Clear answer + citations | Auto-submit to GSD | Auto-submit to GSD |
| INSUFFICIENT_EVIDENCE | **Ask user** | Log gap + pick safest fallback + flag in report |
| Architecture trade-off | **Ask user** | Auto-decide + flag in report |
| Irreversible choice (DB migration, auth rewrite, etc.) | **Ask user** | **Still ask user** (hard rule) |

### 4. Log every decision

Append to `.planning/orchestrator/decisions.md`:

```markdown
## Phase 3 — discuss

**Q:** Should we use server-side rendering or static generation?
**A:** Static generation
**Reasoning:** Project is a marketing site (CLAUDE.md:12). No dynamic data per request (package.json has no API deps). Current Astro config uses `output: "static"` (astro.config.mjs:4).
**Evidence:** CLAUDE.md:12, astro.config.mjs:4
**Confidence:** High
**Auto-decided?** Yes (full-auto)
```

## Hard Rules (apply in ALL modes)

1. **Always Opus** — All GSD subagent delegations run with `model: opus`. Never Sonnet or Haiku, even in full-auto batch runs. (Project rule: `feedback_always_opus.md`)

2. **Evidence-first answers** — No answer without citation to a project file. "INSUFFICIENT_EVIDENCE" is preferred over a guess.

3. **Never skip these checkpoints** (even in full-auto):
   - Database schema migrations
   - Auth/authentication changes
   - Breaking API changes
   - Dependency major-version bumps
   - Secrets/config changes
   - Any phase that modifies > 10 files

4. **Git hygiene before execute** — Clean working tree required. Dirty tree in full-auto → abort that project, move to next in batch.

5. **Token budget per project** — Default cap 500k tokens per project in batch mode. Exceeded → pause, append to report, continue with next project.

6. **Atomic commits** — Each phase commits independently (GSD default). Skill verifies commits were created.

7. **Feature branch isolation** — Each project run creates `gsd/<timestamp>-<slug>` branch off HEAD. `main` is never touched directly. Branch gets pushed with `-u` at end of successful run. User merges via PR.

8. **Rate-limit backoff** — On 429 response, exponential backoff (30s → 60s → 120s → 300s → abort). Up to `--retry-max` retries (default 3) per subagent call.

9. **Resource guards** — Before each phase: check free disk > 1 GB, check `.planning/` size < 100 MB. Exceeded → pause, log, continue only after user acknowledgement (or skip project in batch).

## Pre-Flight Batch Validation (runs before any work starts)

For batch runs, the orchestrator validates **every project up front**. Saves hours of wasted runtime from a bad path.

Checks per project in the batch file:

| Check | On failure |
|---|---|
| Path exists and is a directory | Mark "skip", continue validation |
| `.git` directory present | Mark "skip" |
| Git working tree clean (`git status --porcelain` empty) | Mark "skip" |
| Upstream reachable (`git ls-remote --exit-code origin`) | Warning only (allow offline runs) |
| Free disk ≥ 2 GB in project root | Mark "skip" |
| `CLAUDE.md` present (any location) | Warning (evidence pool will be thin) |
| GSD `.planning/` not locked by another process | Mark "skip" |

After validation, the orchestrator prints a summary:

```
Pre-flight: 4 projects scanned
  ✓ marketing-site        ready
  ✓ admin-panel           ready
  ⚠ api-service           WARN: thin CLAUDE.md (3 lines)
  ✗ docs-site             SKIP: dirty git tree (5 uncommitted files)

Proceed? [Y/n]  (in full-auto: auto-yes after 10s)
```

In **full-auto** the summary is logged and the run starts automatically after 10 seconds. Skipped projects are listed in the final report.

## Batch Mode (Overnight Runs)

Create a file `projects.txt`:

```
D:/backupblu/github/my-site
D:/backupblu/github/api-service
D:/backupblu/github/admin-panel
```

Comments and blank lines allowed:

```
# marketing sites
D:/backupblu/github/my-site
D:/backupblu/github/docs-site

# APIs (higher budget + stop after phase 3)
D:/backupblu/github/api-service  ;  --token-budget=1500000 --to=3

# skip for now
# D:/backupblu/github/admin-panel
```

**Per-project option syntax:** Append `; <options>` after the path (e.g. `path ; --to=3`). Overrides the run-level options for that one project.

Run:

```
/gsd-orchestrate "Optimize performance and security" --batch=projects.txt --mode=full-auto
```

Per-project loop:

```
pre-flight validation across ALL projects
for project in validated batch:
    cd project
    create feature branch (gsd/<timestamp>-<goal-slug>)
    run full orchestrator flow
    on success:  push branch with -u, collect report
    on failure:  log, continue to next project
    on token cap: pause project, continue batch
cd back to starting directory
generate batch summary → ~/.claude/orchestrator-batch/<date>/SUMMARY.md
fire notification (if --notify set)
```

Batch summary contains:
- Projects completed / failed / skipped (with reasons)
- Total tokens used
- Per-project decision count (auto-decided vs. gap-flagged)
- Feature branches created (for PR creation)
- Commits created per project
- Next-steps list for user review

## Headless / Scheduled Execution

The skill is designed for unattended overnight runs. Three launch modes:

### Mode A — Print mode (one-shot)

```bash
claude -p "/gsd-orchestrate 'Performance + Security' --batch=~/projects.txt --mode=full-auto --notify=file:~/.claude/orchestrator-done.flag"
```

Claude starts, runs to completion, writes to stdout, exits. Run from a terminal before bed.

### Mode B — Scheduled via Hangar `/schedule`

```
/schedule create --cron="0 23 * * *" --prompt="/gsd-orchestrate 'nightly optimization' --batch=~/projects.txt --mode=full-auto"
```

Runs every night at 23:00 automatically. Requires Hangar's scheduling infrastructure active.

### Mode C — Tmux / background session

```bash
tmux new-session -d -s gsd-overnight "claude -p '/gsd-orchestrate ... --mode=full-auto'"
```

Detach, sleep, check output in the morning with `tmux capture-pane -p -t gsd-overnight`.

### Keep-awake requirements

Rechner darf nicht schlafen während des Laufs:

**Windows:**
```bash
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
# Restore after: powercfg /change standby-timeout-ac 30
```

**macOS:**
```bash
caffeinate -i &
# PID to kill after run: kill <pid>
```

**Linux:**
```bash
systemd-inhibit --what=sleep --who=gsd --why="overnight run" sleep 8h &
```

## Notifications

Pass `--notify=<target>` to get pinged when done.

| Target | Syntax | Effect |
|---|---|---|
| File flag | `--notify=file:~/.claude/done.flag` | Touches file when run completes (watch with any tool) |
| Webhook | `--notify=webhook:https://hooks.slack.com/...` | POSTs JSON summary to URL |
| Sound | `--notify=sound` | Plays system beep (Windows: PowerShell beep; macOS: `afplay /System/Library/Sounds/Glass.aiff`) |

Webhook payload:

```json
{
  "status": "complete",
  "batch_id": "2026-04-13",
  "projects_ok": 3,
  "projects_failed": 1,
  "tokens_used": 824300,
  "gaps_flagged": 3,
  "summary_url": "file:///~/.claude/orchestrator-batch/2026-04-13/SUMMARY.md"
}
```

## Dry-Run Mode

```
/gsd-orchestrate "<goal>" --batch=~/projects.txt --mode=full-auto --dry-run
```

Runs the pre-flight validation, then simulates the orchestrator flow without executing GSD commands or writing files. Output:

```
[DRY RUN]
Projects validated: 4 ready, 1 skip
Estimated tokens: ~620k (based on codebase sizes)
Estimated duration: ~2h 40min
Feature branches that WOULD be created:
  gsd/2026-04-13-performance-security  (marketing-site)
  gsd/2026-04-13-performance-security  (admin-panel)
  ...
Gate triggers likely (based on scan):
  admin-panel:  auth middleware referenced → hard gate will fire
```

Always use `--dry-run` for your first batch run.

## Rollback

```
/gsd-orchestrate rollback <batch-id>
```

Reverts all commits from that batch run (per project, on the created feature branches). Does NOT delete the branches — you can inspect and decide later. The batch-id is the date folder name, e.g. `2026-04-13`.

Per-project rollback:

```
/gsd-orchestrate rollback <batch-id> --project=<path>
```

Uses `/gsd-undo` internally for each commit. Safe — checks dependency order before reverting.

## State File (`.gsd-orchestrate-state.json`)

```json
{
  "version": 1,
  "started": "2026-04-12T22:00:00Z",
  "mode": "full-auto",
  "goal": "Optimize performance and security",
  "current_phase": 3,
  "total_phases": 7,
  "decisions": 24,
  "gaps_flagged": 2,
  "tokens_used": 142300,
  "commits": ["abc123", "def456"],
  "resumable": true
}
```

Resume after interruption:

```
/gsd-orchestrate resume
```

## Report Format (`.planning/orchestrator/run-<timestamp>.md`)

```markdown
# GSD Orchestrator Run — 2026-04-12 22:00

**Goal:** Optimize performance and security
**Mode:** full-auto
**Duration:** 1h 47min
**Tokens:** 142,300
**Phases:** 7/7 completed
**Commits:** 12
**Gaps flagged:** 2 (see below)

## Phase Summary

| # | Phase | Status | Commits | Tokens | Decisions |
|---|---|---|---|---|---|
| 1 | Baseline audit | ✓ | 1 | 18,400 | 3 auto |
| 2 | Image optimization | ✓ | 2 | 22,100 | 5 auto |
| ...

## Gaps Flagged for Review

### Phase 4 — Choice: Redis vs. in-memory cache
**Evidence found:** No cache currently. 50 req/s average (logs).
**Auto-decision:** In-memory (simpler, fits scale).
**Rationale:** No horizontal scaling evidence in deployment config.
**Review needed if:** App will scale to multiple instances.

## Next Steps

- [ ] Review gap 1 (cache choice)
- [ ] Review gap 2 (...)
- [ ] Run `/gsd-verify-work` manually on phase 5 (flagged)
```

## Error Handling

| Failure | Full-auto action | Checkpoint action |
|---|---|---|
| GSD subagent errors | Retry once, then skip phase | Ask user |
| Test failure in verify | Run `/gsd-debug`, retry | Ask user |
| Dirty git tree before phase | Abort project (batch: skip to next) | Ask user |
| `INSUFFICIENT_EVIDENCE` | Log + fallback | Ask user |
| Token budget exceeded | Pause, report, continue batch | Pause, ask user |
| GSD command not found | Abort with install hint | Abort with install hint |

## Usage Examples

```bash
# Default checkpoint mode
/gsd-orchestrate "Add user authentication"

# Full-auto single project
/gsd-orchestrate "Refactor API layer for better testability" --mode=full-auto

# Full-auto overnight batch
/gsd-orchestrate "Modernize dependencies and fix deprecations" --batch=~/projects.txt --mode=full-auto

# Only phases 1-3, reuse existing scan
/gsd-orchestrate "Security hardening" --to=3 --skip-map

# Assisted mode (prompt on every question)
/gsd-orchestrate "Major architecture refactor" --mode=assisted
```

## Checkpoint Mode — User Interaction Pattern

In checkpoint mode, the skill asks the user via `AskUserQuestion` only when:

1. A GSD answer protocol returned `INSUFFICIENT_EVIDENCE`
2. The decision is in the "never skip" list (DB, auth, breaking API, major deps, secrets, >10 files)
3. GSD produces a plan with high-impact changes (flagged by plan-checker agent)

Each checkpoint shows:
- The question
- Evidence loaded (so user can verify)
- Recommended answer (as first option)
- 2-3 alternatives

## Compatibility

- **Hangar hooks:** All hooks fire normally during GSD execution
- **Hangar skills:** Can call `/scan`, `/codebase-map`, `/handoff` alongside
- **Memory:** Saves batch-run summary references to `~/.claude/projects/*/memory/`
- **Status line:** Shows current phase + project during batch runs

## Troubleshooting

**"GSD not found"**
Install: `npx get-shit-done-cc --claude --global`

**"Dirty git tree"**
Commit or stash changes. Full-auto skips dirty projects in batch mode.

**"Token budget exceeded"**
Increase via `--token-budget=<n>` (default 500k per project in batch mode).

**"Resumed state shows stale phase"**
Run `/gsd-health` to diagnose, then `/gsd-orchestrate resume` or start fresh.

**"Full-auto made a bad architectural call"**
Review `.planning/orchestrator/decisions.md`. Revert with `/gsd-undo <commit>`. Rerun in checkpoint mode.

## Design Principles

1. **Evidence or escalation** — Never fabricate, always cite or ask
2. **Opus everywhere** — No Sonnet shortcuts for speed
3. **Document every decision** — Full audit trail in decision log
4. **Safe fallbacks** — When uncertain, pick the reversible option
5. **Batch isolation** — One project's failure never blocks the next
6. **Human override** — Hard checkpoints for irreversible changes stay even in full-auto
