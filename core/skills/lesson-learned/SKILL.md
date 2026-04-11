---
name: lesson-learned
description: >
  Extract learnings and save as memory files (file-based memory system).
  Use when: "lesson learned", "what did we learn", "learning", "remember".
user-invocable: true
argument-hint: "session|review"
---

<!-- AI-QUICK-REF
## /lesson-learned — Quick Reference
- **Modes:** auto | review | session
- **Output:** 1-2 lessons -> memory file (feedback/project type) or CLAUDE.md
- **Rule:** Max 2 lessons per invocation, always anchored to real files
- **No duplicates:** Read memory directory and MEMORY.md index, only add new items
- **Format:** Problem -> Root Cause -> Solution -> Why -> How to apply -> Reference
- **No noise:** Only insights that will save time in the future
-->

# /lesson-learned — Extract and Save Learnings

Analyzes current work (git diff, errors, fixes) and extracts
1-2 concrete learnings. Saves them as memory files in the file-based
memory system and references them in the MEMORY.md index.

## Problem

Errors and learnings are only captured manually. After a debugging session
or fix round, one often forgets to write down the insights.
Next time, the same mistake is repeated.

## Memory System

The memory system is file-based:
- **Memory directory:** `.claude/projects/.../memory/` (project-specific)
- **MEMORY.md:** Index file with links to individual memory files
- **Memory files:** Individual `.md` files with frontmatter (name, description, type)
- Each lesson is saved as a standalone memory file, not directly in MEMORY.md

## Modes

| Mode | Trigger | Description |
|------|---------|-------------|
| `auto` | `/lesson-learned auto` | After a fixing round: analyze git diff, extract lessons |
| `review` | `/lesson-learned review` | Analyze last commit |
| `session` | `/lesson-learned session` | Retrospective evaluation of entire session |

---

## Mode: auto

Automatically after a fixing round. Analyzes recent changes.

### Procedure

1. **Load prior context:** Read existing audit states for fixing pattern analysis:
   - `.audit-state.json` -> Which findings were fixed? Identify patterns
   - `.project-audit-state.json` -> Code quality fixing patterns
   - `.astro-audit-state.json` -> Extract migration learnings
   - **Purpose:** Extract patterns from fixed findings (e.g., "Fixed 3x missing type annotations -> Lesson: enable strict mode")
2. Read `git diff HEAD~3..HEAD` (last 3 commits)
3. Identify change patterns:
   - Bug fix pattern: What was broken? Why? How was it fixed?
   - Refactoring pattern: What was restructured? Why is it better?
   - New feature: What decision was made? Why?
4. **Read memory directory and MEMORY.md index**
5. Check: Does a memory file on this topic already exist?
6. If new: Formulate 1-2 lessons and save as memory files:
   - Create memory file in memory directory (filename: `{short-title-kebab-case}.md`)
   - Update MEMORY.md index (add link to new file)
7. If existing topic: Update existing memory file instead of creating a new one

### Memory File Format

```markdown
---
name: {short-title}
description: {one-line description}
type: feedback
---

**Problem:** {what went wrong}
**Root Cause:** {root cause}
**Solution:** {what worked}
**Why:** {why this matters}
**How to apply:** {when this insight is relevant}
**Reference:** `{file}:{line}`
```

### Filename Convention

- Kebab-case from the short title: `hook-stderr-windows.md`, `parallel-bash-calls.md`
- No numbering, no date prefixes
- Descriptive enough to guess content without opening

---

## Mode: review

Analyzes the last commit specifically.

### Procedure

1. Read `git log -1 --stat` (last commit)
2. Read `git diff HEAD~1..HEAD`
3. Analyze commit message (what was the goal?)
4. Compare changes against goal
5. Extract learning if relevant
6. Create memory file (same as auto, step 6)

---

## Mode: session

Retrospective on the entire session. For use at session end.

### Procedure

1. Read `git log --since="3 hours ago" --stat`
2. Summarize all commits from the session
3. Identify overarching patterns:
   - Recurring error categories
   - Tools/workarounds that helped
   - Architecture decisions that were made
4. Formulate 1-2 overarching lessons
5. Create memory files (same as auto, step 6)

---

## Rules

1. **Max 2 lessons per invocation** — Quality over quantity
2. **Always anchored to real files** — No abstract wisdom
3. **No duplicates** — Read memory directory and MEMORY.md index first
4. **No noise** — Only insights that will concretely save time in the future
5. **Project-specific vs. global:**
   - Project-specific learning -> project-specific memory directory
   - General learning -> global memory directory or CLAUDE.md
6. **Update existing memory files** instead of creating new ones when the topic already exists
7. **Frontmatter required** — Every memory file needs name, description, and type (feedback)
8. **Maintain MEMORY.md index** — Update the index after every new memory file

## When to Recommend

- After a bug-fixing session with >3 fixes
- After a debugging process that took >20 minutes
- After an architecture decision
- At the end of a major work phase
- When the same error type occurs for the second time

## Files

```
lesson-learned/
└── SKILL.md    <- This file
```
