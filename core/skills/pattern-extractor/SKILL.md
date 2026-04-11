---
name: pattern-extractor
description: Analyzes captured patterns from continuous learning to extract reusable workflows and anti-patterns. Use when you want to review what's been learned across sessions.
effort: low
user-invocable: true
argument-hint: ""
---

# /pattern-extractor — Learn from History

Analyzes the command patterns captured by the continuous-learning hook
and extracts actionable insights.

## What It Does

1. Reads pattern logs from `~/.claude/.patterns/`
2. Identifies recurring success/failure patterns
3. Extracts reusable workflows (commands that consistently succeed)
4. Flags anti-patterns (commands that consistently fail)
5. Generates a summary with recommendations

## Usage

```
/pattern-extractor              # Analyze all patterns
/pattern-extractor last-week    # Analyze last 7 days
/pattern-extractor project      # Analyze current project only
```

## Analysis Process

### Step 1: Load Pattern Data

Read all `.jsonl` files from `~/.claude/.patterns/`:

```bash
cat ~/.claude/.patterns/session-*.jsonl
```

### Step 2: Categorize Patterns

Group commands by:
- **Recovery patterns**: Command that succeeded after a similar command failed
- **Workflow patterns**: Sequences of commands that appear together
- **Failure patterns**: Commands that consistently fail in certain contexts
- **Tool preferences**: Which tools are used most for which tasks

### Step 3: Generate Insights

For each pattern category, produce:

```markdown
## Recovery Patterns
| Failed Command | Successful Recovery | Frequency |
|----------------|---------------------|-----------|
| npm run build  | npm ci && npm run build | 5 times |

## Workflow Patterns
| Workflow | Steps | Frequency |
|----------|-------|-----------|
| TDD cycle | test → edit → test | 23 times |

## Anti-Patterns (Avoid)
| Command | Failure Rate | Recommendation |
|---------|-------------|----------------|
| git push -f | 80% blocked | Use regular push |
```

### Step 4: Save Insights

Write analysis to `~/.claude/.patterns/insights-YYYY-MM-DD.md`.
If insights reveal a reusable pattern, suggest creating a skill for it.

## Output

Summary with:
- Top 5 recovery patterns
- Top 5 workflow patterns
- Top 5 anti-patterns
- Recommendation: patterns worth formalizing as skills
