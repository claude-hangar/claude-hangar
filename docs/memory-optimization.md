# Memory Optimization Guide

Strategies for efficient memory usage in Claude Code's file-based memory system.

---

## The Problem

MEMORY.md is loaded into every conversation. As it grows, it consumes context tokens
that could be used for actual work. At 200+ entries, you're spending ~10K tokens just
on memory loading before the conversation even starts.

---

## 3-Layer Retrieval Strategy

Organize memory into layers of increasing detail:

### Layer 1: Index (MEMORY.md)
**Always loaded. Must be lean.**

- One line per memory, under 150 characters
- Format: `- [Title](file.md) — one-line hook`
- Organized by topic, not chronologically
- Target: under 50 entries (100 is the practical max)
- Prune regularly: if you haven't referenced it in 30 days, archive it

### Layer 2: Summary Files
**Loaded on demand when a topic is relevant.**

- Each memory file should start with a 1-2 sentence summary
- Front-load the actionable information
- Keep files under 50 lines
- Use the frontmatter `description` field for relevance matching

### Layer 3: Full Detail
**Only accessed when explicitly needed.**

- Detailed context, history, rationale
- Store in subdirectories: `memory/archive/`, `memory/detail/`
- Reference from Layer 2 files, not directly from MEMORY.md

---

## Practical Guidelines

### What Goes in MEMORY.md

| Include | Exclude |
|---------|---------|
| User preferences and role | Code patterns (read the code) |
| Feedback corrections | Git history (use git log) |
| Active project context | Debugging solutions (in code) |
| External system references | Anything in CLAUDE.md |
| Non-obvious decisions | Ephemeral task details |

### Memory Lifecycle

```
Observe → Save → Validate → Prune/Promote
```

1. **Observe**: Notice something worth remembering
2. **Save**: Write memory file + add to MEMORY.md index
3. **Validate**: On next use, check if memory is still accurate
4. **Prune**: Remove stale memories; promote high-value ones to CLAUDE.md rules

### Pruning Checklist (Monthly)

- [ ] Remove memories about completed projects
- [ ] Update memories with outdated information
- [ ] Merge related memories into single files
- [ ] Archive memories not referenced in 30+ days
- [ ] Promote recurring patterns to CLAUDE.md or rules/

---

## Token Budget

| Component | Estimated Tokens | Target |
|-----------|-----------------|--------|
| MEMORY.md index (50 entries) | ~2,000 | Keep under 3,000 |
| Loaded memory files | ~500 each | Load max 3 per conversation |
| Total memory overhead | ~3,500 | Under 5,000 (0.5% of 1M context) |

---

## Example Structure

```
~/.claude/projects/{project}/memory/
├── MEMORY.md              # Index (Layer 1)
├── user_role.md           # Who the user is
├── feedback_testing.md    # How user wants tests done
├── project_goals.md       # Current project goals
├── reference_linear.md    # Where to find tickets
└── archive/               # Old memories (Layer 3)
    ├── project_q1_goals.md
    └── feedback_old_api.md
```
