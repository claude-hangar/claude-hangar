---
name: session-recap
description: >
  Summarize the pre-compact snapshot produced by the PreCompact hook into a
  human-readable recap. Equivalent to Claude Code's `/recap` but driven by
  Hangar snapshots so it works across sessions even without telemetry.
  Use when: "recap", "where did we stop", "what was going on", "session summary",
  "catch me up", "session-recap".
effort: high
user-invocable: true
argument-hint: "full | brief | tasks-only"
---

# /session-recap

Converts the Hangar pre-compact snapshot into a short human-readable summary. Complements Claude Code's native `/recap` (v2.1.108+) by surviving compaction, session-end, and handoff boundaries.

## Data sources (in order)

1. `${TEMP}/claude-pre-compact-snapshot-<session>.json` — pre-compact hook output
2. `.tasks.json` — active task list at time of compaction
3. `STATUS.md` — project-level status file
4. `HANDOFF.md` — explicit handoff note if the user wrote one
5. `git status --porcelain` + `git log --oneline -5` — recent repo activity

If no snapshot exists, fall back to sources 2–5 and mark the recap as "live" rather than "restored".

## Output modes

### `brief` (default)

```
Session recap — <timestamp>
Branch: <branch>    Uncommitted: <N files>
Last commit: <sha> <subject>
Active tasks (<N>):
  - <task 1 subject>
  - <task 2 subject>
Next: <recommended next action from STATUS.md or last in-progress task>
```

### `full`

Brief output + last 5 commits, uncommitted file preview, HANDOFF.md inline, STATUS.md inline.

### `tasks-only`

Just the active task list with status indicators. Use when pivoting between features.

## Behavior

- Never mutates files — read-only recap
- Never invokes other agents — pure data aggregation
- Exits cleanly when no snapshot exists (fallback to live state)
- Recap is plain markdown, safe to quote back to the user
