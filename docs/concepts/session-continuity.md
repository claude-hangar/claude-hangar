# Session Continuity

Claude Code sessions are stateless by default -- each new session starts with a blank context. Claude Hangar bridges this gap through a system of hooks, files, and conventions that maintain continuity across sessions.

## The Continuity Stack

```
MEMORY.md          -- Persistent learnings (survives all sessions)
STATUS.md          -- Current work state (read at start, updated at stop)
.tasks.json        -- Task queue with progress tracking
State files        -- Audit/skill progress (per-skill JSON)
Token tracking     -- Context utilization monitoring (per-session)
Cost log           -- Session cost history (append-only)
Checkpoint stash   -- Git stash snapshots before edits
```

## STATUS.md Pattern

STATUS.md tracks what is currently in progress. The `session-start` hook reads it at the beginning of every session and injects the "Current Work" or "In Progress" section (first 500 characters) into the model's context.

**Cycle:** Session start reads STATUS.md. During work, Claude updates it. At session end, it reflects the latest state for the next session. If no matching section heading is found, the hook falls back to the first 300 characters.

## MEMORY.md System

MEMORY.md is auto-memory that persists across all conversations in a project. It lives at `~/.claude/projects/{encoded-path}/memory/MEMORY.md`.

**Contents:** Repository structure, tool versions, configuration decisions, debugging learnings, user preferences, audit findings.

**Size monitoring:** The `session-start` hook warns if MEMORY.md exceeds 3KB, since large memory files consume context tokens on every session start.

**Hygiene checks:** The hook scans MEMORY.md for potentially injected content -- control override phrases ("skip security"), accidentally stored secrets, suspicious external links, and eval/exec calls. This protects against context poisoning (ASI06).

## Token Tracking

The `token-warning` hook monitors context utilization throughout a session.

**Primary:** Uses `used_percentage` from hook input when provided by Claude Code. **Fallback:** Tracks cumulative input bytes against a 3.84M character budget (~960k tokens after system prompt).

**Warning thresholds:**

| Threshold | Message |
|-----------|---------|
| 70% | CONTEXT NOTICE: Will need `/compact` soon |
| 80% | CONTEXT WARNING: Running `/compact` now is recommended |

Each warning fires only once per session. As a secondary fallback, warnings also trigger at 300+ and 400+ tool calls.

**Performance:** The hook runs on every `PostToolUse` event but evaluates at most every 30 seconds via a cooldown file. Per-session state (`calls`, `bytes`, `warned70`, `warned80`) is stored in `${TEMP}/claude-token-track-${SESSION_ID}`.

## Compaction Handling

When context is compacted, the `post-compact` hook:

1. Saves a context snapshot (timestamp, calls, bytes, STATUS.md summary)
2. Adjusts token tracking -- resets bytes to 30% (approximate post-compaction size)
3. Resets warning flags so they can fire again in the new context window

The snapshot is stored at `${TEMP}/claude-compact-snapshot-${SESSION_ID}.json` and cleaned up by `session-stop`.

## Checkpoint System

The `checkpoint` hook creates git stash snapshots before file edits, providing a safety net for recovery.

**How it works:** Fires on `PreToolUse` for Write and Edit operations. Only creates a checkpoint if uncommitted changes exist. Uses `git stash create` (does not modify the working tree) and stores the ref with a descriptive message including timestamp and filename.

**Cooldown:** Maximum one checkpoint every 5 minutes.

**Recovery:** Use `git stash list` to see all checkpoints, `git stash show stash@{N}` to inspect, and `git stash apply stash@{N}` to restore.

## Cost Tracking

The `session-stop` hook logs session cost data to `${LOCALAPPDATA}/claude-statusline/cost-log.jsonl` in append-only JSONL format. Each entry records timestamp, session ID, cost in USD, duration, and working directory. This data feeds the statusline and enables cost analysis across sessions.

## Task System

The `.tasks.json` file tracks in-session progress and enables handoffs between sessions.

**Task states:**

| Status | Meaning |
|--------|---------|
| `"open"` | Queued, not yet started |
| `"in-progress"` | Currently being worked on |
| `"done"` | Completed |

**Session start integration:** The `session-start` hook reads `.tasks.json` and surfaces open/in-progress tasks as context for the model, e.g.:

```
Tasks: 1 in progress, 2 open
  - [in-progress] Continue audit from phase 05
  - [open] Fix SEC-01 (missing CSP header)
```

**Auto-created tasks:** Skills create tasks automatically when context runs low during `auto` mode. The task includes a handoff note describing what was completed and what remains. The next session picks up from where the previous session left off.

## Cleanup

The `session-stop` hook ensures the workspace is clean:

1. Scans project root for temp files (`*.tmp`, `*.bak`, `*.backup-*`, `screenshot-*`, `capture-*`, `*.debug.log`)
2. Lists up to 5 leftover temp files as a warning
3. Removes token tracking and compact snapshot files from the temp directory

## End-to-End Flow

```
Session N starts
  |-> session-start.sh reads STATUS.md + .tasks.json + MEMORY.md
  |-> User works (tool calls trigger PreToolUse/PostToolUse hooks)
  |-> token-warning.sh tracks utilization (every 30s)
  |-> checkpoint.sh creates git stash snapshots (every 5min)
  |-> [If /compact] -> post-compact.sh resets tracking
  |-> Session N ends
  |-> session-stop.sh checks for temp files, logs cost
  v
Session N+1 starts
  |-> session-start.sh reads STATUS.md -> context restored
```
