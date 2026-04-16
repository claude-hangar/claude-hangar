# Audit-Orchestrator — Team Mode (Parallel Audit Execution)

When the user selects team mode in step 5b, the orchestrator runs the audits as an Agent Team. The orchestrator itself is the team lead and coordinates everything. Team mode is optional and requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

Team mode is a Phase 2 execution strategy inside the universal four-phase workflow. The team spawns during Phase 2; Phase 3 (Optimization) and Phase 4 (Report) happen after all teammates join back.

## Pre-Audit: Orchestrator Runs Itself

The orchestrator does the pre-audit itself (no dedicated teammate):

1. Run `/freshness-check` (when > 7 days since last check)
2. Check GitHub settings (when detected)
3. VPS quick check (when detected)
4. Persist results in orchestrator state + `01-prescan/findings.md`

The team starts only after the pre-audit completes.

## T1 — Create Team

```
TeamCreate:
  team_name: "audit-{project-name}"
  description: "Parallel audit for {ProjectName}"
```

## T2 — Create Tasks

Create one task per detected audit:

```
TaskCreate per audit:
  subject: "/audit auto — {ProjectName}"
  description: Project path, detected stack, active phases, delegated phases
  activeForm: "Running /audit auto..."
```

## T3 — Dependencies (Sequencing)

Model the audit order from step 4 as task blockers:

| Sequencing Scenario | Task Dependencies |
|---------------------|-------------------|
| Framework Beta/RC | framework-audit → audit (blockedBy) → project-audit (blockedBy) |
| Framework Stable (major upgrade) | framework-audit → audit (blockedBy) → project-audit (blockedBy) |
| Framework Stable (current) | audit + framework-audit + project-audit: ALL parallel (no blockers) |
| No framework-specific audit | audit + project-audit: parallel (no blockers) |

**Rule:** With Beta/RC only ONE audit runs at a time (sequentially via blockers). On stable current versions, all run in parallel.

## T4 — Spawn Teammates

One teammate per audit (general-purpose):

```
Task tool per audit:
  subagent_type: "general-purpose"
  team_name: "audit-{project-name}"
  name: "audit-worker-1" (resp. 2, 3)
  prompt: "You are part of an audit team for {ProjectName}.
           Start the assigned audit skill in /auto mode.
           Work your task to completion.
           Report back to the team lead when done or when blocked."
```

**Important:** Teammates use each skill's `/auto` mode — no manual `start`/`continue`.

## T5 — Monitoring Loop

The orchestrator (team lead) monitors progress:

1. **Wait on messages** — teammates report progress and completion
2. **Read state files** — `.audit-state.json`, `.{framework}-audit-state.json`, `.project-audit-state.json`, and session `STATUS.md`
3. **Release blocked tasks** — when a blocking audit finishes:
   - Verify state: audit complete?
   - Resolve task dependencies: `TaskUpdate` with `status: completed`
   - Start or wake the next teammate
4. **Update orchestrator state** — progress fields in `.audit-orchestrator-state.json` AND `STATUS.md` (universal session dir)

## T6 — Progress Updates

Show the user progress regularly:

```
Audit Team Status: {ProjectName}

[audit-worker-1] /audit:             ████████░░ Phase 5/8  (running)
[audit-worker-2] /{framework}-audit: ██████████ 13/13      (done, 8 findings)
[audit-worker-3] /project-audit:     ░░░░░░░░░░ waiting    (blocked by /audit)

Runtime: 12 min | Findings so far: 14
```

## T7 — Combined Report

When ALL audits are complete:
1. Read all state files (legacy JSON + universal session `02-analysis/findings.md` + `03-optimization/changes.md`)
2. Generate the combined report (existing report logic, identical format)
3. Write `AUDIT-REPORT-COMBINED-{YYYY-MM-DD}.md` (legacy) or `04-report/REPORT.md` (universal)
4. Summary to user

## T8 — Graceful Shutdown

1. Send `shutdown_request` to all teammates
2. Wait for acknowledgments
3. Run `TeamDelete`
4. Finalize orchestrator state (`executionMode: "team"`, `timing`); flip universal `STATUS.md` to `state: completed`

## Error Handling (Team Mode)

| Situation | Reaction |
|-----------|----------|
| **Teammate crash** (no response) | Read state file → accept partial result → take finding count |
| **Timeout (30 min silent)** | Check state → if progress: wait. If no progress: spawn a new teammate |
| **Skill error** (/auto fails) | Teammate reports error → orchestrator notes it → manual fallback for that audit |
| **Full abort** (user cancels) | `shutdown_request` to all teammates → `TeamDelete` → state flipped to "aborted" → fallback to manual mode |
| **Context limit** (teammate full) | State file has progress → a new teammate can resume with `/continue` (or the universal resume protocol) |

**Principle:** A teammate crash is NOT fatal. Orchestrator state and individual audit states survive. The user can always continue in manual mode.
