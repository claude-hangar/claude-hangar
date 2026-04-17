---
name: effort-tuner
description: >
  Analyzes the current task and recommends the optimal Claude Code effort
  level (low | medium | high | xhigh | max) based on complexity heuristics.
  Helps avoid burning xhigh/max on trivial tasks or shipping undercooked
  analysis at low/medium. Use when: "effort tuner", "what effort", "effort
  level", "which effort should I use", "effort recommendation".
effort: medium
user-invocable: true
argument-hint: "<task description>"
---

# /effort-tuner

Recommends an effort level for the current task. Runs cheap — uses heuristics, not expensive reasoning — so it can sit in front of expensive agent calls without tax.

## Effort ladder (Claude Code v2.1.111+)

| Level | Token budget | Use case |
|-------|-------------|----------|
| `low` | small | Known-good mechanical edits, formatting |
| `medium` | moderate | Focused bug fix, localized refactor, single-file change |
| `high` | generous | Multi-file features, code review, architecture sketches |
| `xhigh` | larger still | Deep analysis, cross-cutting refactor, complex planning |
| `max` | full budget | Opus-scale reasoning: novel design, security audit, race-condition hunt |

## Decision heuristics

Score the task on these dimensions and sum:

1. **Breadth** — files touched: 1 (+0), 2–5 (+1), 6+ (+2)
2. **Novelty** — pattern exists in repo (+0) vs. new pattern (+1) vs. novel domain (+2)
3. **Risk** — style/doc (+0), logic (+1), security/data (+2)
4. **Reversibility** — local change (+0), PR-visible (+1), deployed/shared (+2)
5. **Dependency depth** — self-contained (+0), one module (+1), cross-module (+2)

### Mapping

| Sum | Recommendation |
|-----|----------------|
| 0–2 | `low` or `medium` |
| 3–5 | `high` |
| 6–8 | `xhigh` |
| 9–10 | `max` |

## Output template

```
Effort recommendation: <level>
Task signals:
  - Breadth: <N files> (+<score>)
  - Novelty: <note> (+<score>)
  - Risk: <note> (+<score>)
  - Reversibility: <note> (+<score>)
  - Dependency depth: <note> (+<score>)
Total: <sum>/10
Rationale: <1 sentence>
If unsure: prefer one step down; you can always re-run with higher effort.
```

## Anti-patterns flagged

- **max on trivial** — recommend downgrade + explain token cost
- **low on security** — reject and force ≥high
- **xhigh on single-file edit without dependencies** — flag as possibly wasteful

## Related

- `effortLevel` in settings.json — the session default
- `/effort` slider (v2.1.111) — interactive switch for the current turn
- Per-agent `effort:` frontmatter — agent-level default
