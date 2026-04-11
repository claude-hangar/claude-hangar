---
name: rules-distill
description: Scans all skills and rules to extract cross-cutting principles that should become shared rules. Meta-governance tool for keeping rules synchronized with growing skill collections.
user-invocable: true
argument-hint: ""
---

# /rules-distill — Extract Rules from Skills

Analyzes all skills and existing rules to find principles that appear in 2+
skills but aren't yet captured as shared rules. Keeps the governance layer
synchronized with the skill collection.

## Usage

```
/rules-distill              # Full analysis across all skills
/rules-distill --changed    # Only analyze skills changed since last run
/rules-distill --dry-run    # Show candidates without creating files
```

## Three-Phase Workflow

### Phase 1: Collection (Deterministic)

Scan all skill and rule files to build a corpus:

1. **Read all skills**: `core/skills/*/SKILL.md`
2. **Read all rules**: `rules/**/*.md`
3. **Extract principles**: Identify recurring patterns, constraints, requirements
4. **Build cross-reference**: Map which principles appear in which skills

```bash
# Discovery commands
find core/skills -name "SKILL.md" -type f
find rules -name "*.md" -type f
```

### Phase 2: Analysis (LLM-Assisted)

Process the corpus in thematic batches to find candidates:

For each candidate, evaluate:
- **Frequency**: Appears in 2+ skills (hard requirement)
- **Generality**: Applies beyond a single domain
- **Actionability**: Can be expressed as a clear rule
- **Novelty**: Not already covered by existing rules

### Phase 3: Review (User-Controlled)

Present candidates to the user with verdicts:

| Verdict | Meaning | Action |
|---------|---------|--------|
| **Append** | Add to existing rule file | Show which file and where |
| **Revise** | Update existing rule section | Show diff |
| **New Section** | Add section to existing file | Show content |
| **New File** | Principle needs its own rule file | Show proposed file |
| **Already Covered** | Existing rule handles this | Show reference |
| **Too Specific** | Doesn't generalize enough | Skip with explanation |

**Critical rule:** Never modify rule files automatically. Always present changes
for user review and approval.

## Output Format

```markdown
## Rules Distillation Report

### Skills Analyzed: 28
### Existing Rules Reviewed: 19
### Candidates Found: 5

---

### Candidate 1: Input Validation at Boundaries
**Frequency:** Found in 4 skills (security-scan, verification-loop, scan, audit)
**Verdict:** Already Covered
**Reference:** rules/common/coding-style.md → Input Validation section

---

### Candidate 2: Structured JSON Evidence Output
**Frequency:** Found in 3 skills (verification-loop, context-budget, error-analyzer)
**Current coverage:** Not in any rule file
**Verdict:** New Section → rules/common/patterns.md
**Proposed content:**
> ### Evidence-Based Reporting
> Skills that analyze or verify should output structured JSON evidence
> alongside human-readable summaries. Include: timestamp, tool versions,
> pass/fail per check, raw output (truncated to 10KB).

**Approve? [y/n/edit]**
```

## Candidate Quality Gates

A candidate must pass ALL of these to be proposed:

1. **2+ skill rule**: Appears in at least 2 different skills
2. **Not redundant**: Not a restatement of an existing rule
3. **Actionable**: Describes what to DO, not just what to know
4. **Scoped**: Clear about when it applies and when it doesn't
5. **Testable**: Compliance can be verified (by human or tool)

## When to Use

- After adding 3+ new skills — check for emerging patterns
- During quarterly maintenance — ensure rules reflect current practices
- Before major releases — verify governance completeness
- When skills seem to contradict each other — find the authoritative rule

## Integration with skill-stocktake

Run `/rules-distill` after `/skill-stocktake` for a complete governance cycle:
1. `/skill-stocktake` identifies skill quality issues
2. `/rules-distill` ensures cross-cutting principles are captured
3. Together they maintain both skill quality AND rule completeness

Inspired by ECC's rules-distill skill with Hangar's user-approval-first philosophy.
