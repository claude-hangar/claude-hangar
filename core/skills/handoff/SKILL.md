---
name: handoff
description: Structured session handoff — preserves context for seamless continuation across sessions.
user_invocable: true
---

# /handoff — Structured Session Handoff

Use when ending a session, switching context, or handing work to another
session/person. Creates a structured handoff document that preserves critical
context for seamless continuation.

Inspired by: GSD HANDOFF.json pattern + Superpowers session continuity

## Problem

When context is lost (compaction, new session, context switch), critical
information disappears: what was done, why decisions were made, what's
remaining, which files were touched, and what issues are known. Without
structured handoff, the next session wastes time rediscovering this context.

## Modes

| Mode | Trigger | Description |
|------|---------|-------------|
| `create` | `/handoff` or `/handoff create` | Generate HANDOFF.md from current session |
| `read` | `/handoff read` | Read and summarize existing HANDOFF.md |
| `clean` | `/handoff clean` | Archive HANDOFF.md after resuming work |

## Handoff Document Structure

Generate `HANDOFF.md` in the project root with this structure:

```markdown
# Session Handoff

**Created:** YYYY-MM-DD HH:MM
**Branch:** [current branch]
**Session Goal:** [what was the user trying to accomplish]

## What Was Done

- [Concrete action with file references]
- [Another action with file:line references]

## Key Decisions Made

- [Decision]: [Why this choice was made]
- [Decision]: [Why this choice was made]

## Files Modified

| File | Change Type | Description |
|------|------------|-------------|
| path/to/file | created/modified/deleted | What changed |

## Known Issues

- [Issue description] — [Status: open/workaround/deferred]

## What Remains

1. [Next step — specific and actionable]
2. [Following step]
3. [etc.]

## Context for Next Session

[Any critical context that would be lost: error patterns observed,
approaches tried and failed, external dependencies, user preferences
discovered during this session]

## Verification State

- Tests: [passing/failing/not run]
- Build: [clean/warnings/errors]
- Lint: [clean/warnings]
```

## Creation Flow

### Step 1: Gather Context

Read these sources (if they exist):
1. `git diff --stat` — files changed in current session
2. `git log --oneline -10` — recent commits
3. `STATUS.md` — current work state
4. `.tasks.json` — task progress
5. Active plan documents in `docs/superpowers/plans/`

### Step 2: Synthesize

Combine gathered context with session memory:
- What did the user ask for?
- What was accomplished?
- What decisions were non-obvious?
- What failed and why?

### Step 3: Write HANDOFF.md

Write the handoff document with:
- **Specificity** — file paths, function names, line numbers
- **Actionability** — next steps must be immediately executable
- **Honesty** — include failures and known issues
- **Context** — explain WHY, not just WHAT

### Step 4: Confirm

Show a summary to the user:
```
Handoff created: HANDOFF.md
- X files documented
- Y remaining tasks
- Z known issues
Ready for session end or context switch.
```

## Read Flow

When `/handoff read`:
1. Read HANDOFF.md
2. Present a concise summary
3. Ask: "Resume from where we left off?"

## Clean Flow

When `/handoff clean`:
1. Move HANDOFF.md to `.claude/handoff-archive/YYYY-MM-DD-HH-MM.md`
2. Confirm: "Handoff archived. Fresh start."

## Rules

- **One handoff per session** — update, don't create multiples
- **No secrets** — never include API keys, passwords, tokens
- **Relative paths** — use project-relative paths, not absolute
- **No speculation** — only document what actually happened
- **Proportional detail** — complex session = detailed handoff, quick fix = brief handoff
- **Iron Law: Evidence over memory** — reference git log and file state, not session recall

## Integration

- `session-stop.sh` can remind about `/handoff` if significant work was done
- `session-start.sh` detects HANDOFF.md and suggests `/handoff read`
- `post-compact.sh` includes HANDOFF.md in context reload if it exists
