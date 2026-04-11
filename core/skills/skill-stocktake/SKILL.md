---
name: skill-stocktake
description: Audits skill quality across four dimensions (actionability, scope fit, uniqueness, currency). Quick Scan for changed skills, Full Stocktake for complete audit. Use for maintenance as the skill collection grows.
user-invocable: true
argument-hint: "quick|full"
---

# /skill-stocktake — Skill Quality Audit

Systematic audit of all skills to identify what to keep, improve, update,
retire, or merge. Prevents skill bloat and maintains collection quality.

## Usage

```
/skill-stocktake              # Full audit of all skills
/skill-stocktake quick        # Only skills changed since last stocktake
/skill-stocktake <skill>      # Audit a single skill
```

## Audit Dimensions

Each skill is evaluated against four dimensions:

### 1. Actionability (Weight: 30%)

Does the skill provide clear, executable guidance?

| Score | Criteria |
|-------|----------|
| **High** | Step-by-step workflow, concrete commands, clear output format |
| **Medium** | Good guidance but some steps are vague |
| **Low** | Mostly conceptual, lacks concrete actions |

### 2. Scope Fit (Weight: 25%)

Does the skill belong in Hangar's mission?

| Score | Criteria |
|-------|----------|
| **High** | Core developer workflow tool, framework-agnostic |
| **Medium** | Useful but niche, applies to specific tech stacks |
| **Low** | Out of scope, overlaps with external tools |

### 3. Uniqueness (Weight: 25%)

Is this skill distinct from other skills and rules?

| Score | Criteria |
|-------|----------|
| **High** | No overlap with other skills, fills a unique gap |
| **Medium** | Some overlap but adds distinct value |
| **Low** | Mostly duplicates another skill or rule |

### 4. Currency (Weight: 20%)

Is the skill up-to-date with current tools and practices?

| Score | Criteria |
|-------|----------|
| **High** | References current tool versions, modern patterns |
| **Medium** | Mostly current, minor outdated references |
| **Low** | Outdated commands, deprecated tool references |

## Verdicts

Based on the weighted score, each skill receives a verdict:

| Verdict | Score Range | Action |
|---------|------------|--------|
| **Keep** | 80-100% | No changes needed |
| **Improve** | 60-79% | Specific improvements identified |
| **Update** | 40-59% | Needs significant updates to stay relevant |
| **Merge** | Any | Better combined with another skill |
| **Retire** | Below 40% | Remove from collection |

## Workflow

### Step 1: Inventory

```bash
# Count and list all skills
ls -d core/skills/*/
```

### Step 2: Per-Skill Analysis

For each skill, read the SKILL.md and evaluate:

1. Read the skill content
2. Score each dimension (1-10)
3. Check for overlap with other skills (grep for similar keywords)
4. Check for outdated references (tool versions, deprecated APIs)
5. Assign verdict

### Step 3: Cross-Skill Analysis

After individual audits:

- **Overlap detection**: Find skills that cover similar ground
- **Gap detection**: Find workflow stages with no skill coverage
- **Dependency mapping**: Which skills reference or complement each other

### Step 4: Report

## Output Format

```markdown
## Skill Stocktake Report

**Date:** 2026-04-05
**Skills Audited:** 28
**Mode:** Full Stocktake

### Summary

| Verdict | Count | Skills |
|---------|-------|--------|
| Keep | 18 | scan, verify, context-budget, ... |
| Improve | 5 | polish, handoff, ... |
| Update | 3 | lighthouse-quick, capture-pdf, ... |
| Merge | 1 | audit-runner → audit |
| Retire | 1 | (none) |

### Detailed Results

#### scan — KEEP (Score: 88%)
| Dimension | Score | Notes |
|-----------|-------|-------|
| Actionability | 9/10 | Clear 4-phase workflow |
| Scope Fit | 9/10 | Core Hangar functionality |
| Uniqueness | 9/10 | Only onboarding skill |
| Currency | 8/10 | Current patterns |

#### polish — IMPROVE (Score: 72%)
| Dimension | Score | Notes |
|-----------|-------|-------|
| Actionability | 8/10 | Good workflow |
| Scope Fit | 7/10 | Frontend-specific |
| Uniqueness | 6/10 | Overlaps with design-system |
| Currency | 7/10 | Mostly current |

**Improvements needed:**
1. Clarify distinction from design-system skill
2. Add non-frontend polish checks (API response times, DB queries)
```

## Quick Scan Mode

When using `quick` mode:

1. Check git log for skills changed since last stocktake
2. Only audit changed skills
3. Cross-reference changes against existing verdicts
4. Report changes in verdict (e.g., "Improved: polish moved from IMPROVE to KEEP")

```bash
# Find changed skills since last stocktake
git log --name-only --since="2026-03-01" -- core/skills/
```

## Reason Quality Requirements

Every verdict MUST include:
- **Specific evidence** — Quote the exact line or section that supports the score
- **Actionable recommendation** — What specifically to change (not just "improve")
- **Comparison reference** — How this compares to similar skills in the collection

Vague verdicts like "could be better" are not acceptable.

## When to Use

- **Monthly maintenance** — Run full stocktake to catch drift
- **After adding skills** — Quick scan to ensure new skills meet standards
- **Before releases** — Verify collection quality
- **After rules-distill** — Complete the governance cycle

Inspired by ECC's skill-stocktake with strict reason quality requirements.
