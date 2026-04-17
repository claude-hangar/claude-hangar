# Tutorial: RepoLens Patterns in Claude Hangar

This tutorial walks through the four RepoLens-inspired patterns Hangar adopted in v1.2.0 and when to reach for each.

---

## 1. DONE-Streak Convergence

**Problem:** autonomous loops that exit on the first "looks done" signal false-positive; loops without any convergence signal run forever.

**Pattern:** demand N consecutive "DONE" ticks before terminating. Any non-DONE signal resets the counter to zero.

**Helper:** `core/lib/done-streak.sh`

```bash
source "$HOME/.claude/lib/done-streak.sh"
export HANGAR_DONE_STREAK_N=3   # default; override per task

done_streak_init "my-loop"

while true; do
  result=$(run_iteration)
  if echo "$result" | grep -q "^DONE"; then
    done_streak_tick "my-loop" DONE
  else
    done_streak_tick "my-loop" WORKING
  fi

  if done_streak_reached "my-loop"; then
    echo "Converged after $HANGAR_DONE_STREAK_N stable DONE ticks"
    break
  fi
done
```

**When to use:** `/loop`, `loop-operator` agent, `/gsd-autonomous`, any skill that runs until a condition stabilizes. Not for one-shot tasks.

---

## 2. Budget-Cap in cost-tracker

**Problem:** an autonomous loop can keep calling tools indefinitely. Without a session-level budget, runaway runs are only visible after billing.

**Pattern:** compute an estimated session cost at Stop time (`tool_calls × HANGAR_COST_PER_CALL_USD`) and compare against `HANGAR_BUDGET_USD`. Write an alert entry at 80% / 100%.

**Configure in settings.json:**

```json
"env": {
  "HANGAR_BUDGET_USD": "5.00",
  "HANGAR_COST_PER_CALL_USD": "0.02"
}
```

**Alert log:** `~/.claude/.metrics/budget-alerts.jsonl`

```json
{"timestamp":"2026-04-17T09:00:00Z","level":"warning","est_cost_usd":4.20,"budget_usd":5.00,"budget_pct":84,"project":"/path/to/repo"}
```

Empty `HANGAR_BUDGET_USD` disables the feature. The estimate is a rough heuristic — hooks cannot see real billing data.

---

## 3. Dry-Run Preview for Orchestrators

**Problem:** running a full audit orchestrator to see what it would do is expensive. Users want a plan, not an execution.

**Pattern:** an explicit `dry-run` argument that prints the plan without spawning agents or writing state.

**Invocation:**

```
/audit-orchestrator dry-run
```

**Output:**

```
Detected project: web-astro (confidence: high)
Planned Phase-2 tracks:
  - /audit             → performance, SEO, a11y, privacy, security
  - /astro-audit       → v6 migration checklist
  - /project-audit     → Git hygiene, CI health
Estimated cost: ~$0.42 (21 tool calls × $0.02)
Parallelization: 3 independent tracks → 1 wave
Would create: .audit-session/2026-04-17-web-astro/
```

No `.audit-session/` is written. Safe to run anywhere.

---

## 4. Stack Lenses

**Problem:** one big audit prompt hides which checks ran; lens-size checks are easier to debug, cheaper to skip selectively, and parallelizable.

**Pattern:** each stack has a `lenses/` directory with single-concern audit modules. Frontmatter declares `category` and expected `effort_min`/`effort_max` so orchestrators can cost-estimate and pick subsets.

**Example:** `stacks/astro/lenses/content-collections.md`

```yaml
---
name: content-collections
stack: astro
category: data
effort_min: 2
effort_max: 8
---
```

**Rules:**
- **One concern per lens.** If "What this lens checks" has two sections, split into two lenses.
- **Declare effort envelope** so the orchestrator can budget.
- **Structured output** matching a report template.
- **Compose, don't bundle** — the orchestrator picks lenses by `category`.

**Adding a new lens:** copy an existing one, change the frontmatter, rewrite the body. See `stacks/astro/lenses/README.md` for the authoring template.

---

## Related

- Inspiration: [RepoLens](https://github.com/TheMorpheus407/RepoLens)
- `core/agents/loop-operator.md` — DONE-streak and resume-state usage
- `core/hooks/cost-tracker.sh` — budget cap implementation
- `core/skills/audit-orchestrator/SKILL.md` — dry-run mode
- `stacks/astro/lenses/` — lens scaffold
