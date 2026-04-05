---
name: consult
description: Interactive project consultant. Scans your project, asks targeted questions, and creates a structured improvement plan.
user_invocable: true
argument_hint: ""
---

<!-- AI-QUICK-REF
## /consult — Quick Reference
- **Modes:** start | quick | plan
- **Arguments:** `/consult $0` e.g. `/consult start`, `/consult quick`, `/consult plan`
- **Flow:** Understand (scan) → Ask (targeted questions) → Recommend → Plan
- **Depends on:** /scan (runs internally, or reads .scan-profile.json)
- **Output:** Consultation report with prioritized improvement plan
- **State:** .consult-state.json in project root
- **Interactive:** Uses AskUserQuestion for targeted questions
- **Context Protection:** Max 10 questions per session, plan fits one session
-->

# /consult — Project Consultant

Interactive project consultant that understands your project and guides improvements
through targeted, context-aware questions. Like sitting down with a senior developer
who looks at your codebase and asks the right questions.

## Problem

Developers know something is off but cannot pinpoint what to improve first.
Generic advice ("add tests", "update dependencies") is not helpful without understanding
the project's context, constraints, and goals. A good consultant asks before prescribing.

---

## 3 Modes

| Mode | Trigger | Description | Interactive? |
|------|---------|-------------|-------------|
| `start` | `/consult` or `/consult start` | Full consultation: scan → questions → plan | Yes |
| `quick` | `/consult quick` | Skip deep questions, scan + auto-recommend | Minimal |
| `plan` | `/consult plan` | Generate plan from previous consultation state | No |

---

## Mode: start

Full interactive consultation. This is the primary mode.

### Phase 1 — Understand (Automatic)

Run `/scan full` internally or read existing `.scan-profile.json` if recent (< 7 days old).

**Decision logic:**
```
IF .scan-profile.json exists AND scanDate < 7 days ago:
  -> Read existing profile, skip scan
  -> Tell user: "Using existing scan from {date}"
IF .scan-profile.json exists AND scanDate >= 7 days ago:
  -> Re-scan, profile is stale
IF .scan-profile.json does not exist:
  -> Run /scan full internally
```

After scan, compile an internal understanding of the project:
- What is this project? (type, purpose, architecture)
- What stack does it use?
- What is present? (tests, CI, docs, deployment)
- What is missing? (gaps from quality indicators)
- What is the apparent maturity level? (prototype, MVP, production, legacy)

### Phase 2 — Ask (Interactive)

Ask targeted questions based on scan findings. Questions are **conditional** — only ask
what is relevant. Use AskUserQuestion for each question.

**Rules for questions:**
- Max 5-8 questions per consultation (respect user's time)
- Always offer a recommended answer as first option
- Questions must be specific to what was found, never generic
- Group related questions when possible
- Skip questions where the answer is obvious from the scan

#### Question Framework

Questions are organized by category. Only ask questions from categories where
the scan found gaps or ambiguity.

##### Category: Project Goals

Always ask (exactly one question to start):

> **What is the main thing you want to improve about this project?**
> 1. Performance (speed, resource usage)
> 2. Developer Experience (easier to work with, better tooling)
> 3. User Experience (design, usability, accessibility)
> 4. Reliability (fewer bugs, better error handling, monitoring)
> 5. Security (hardening, auth, data protection)
> 6. Architecture (structure, scalability, maintainability)
> 7. Everything — give me a full assessment

##### Category: Testing (only if scan found gaps)

| Scan Finding | Question |
|-------------|----------|
| No test files found | "Your project has no tests. What would be most critical to test first? (1. API endpoints, 2. Business logic, 3. UI components, 4. Not a priority right now)" |
| Tests exist but no coverage | "Tests exist but no coverage tracking. Would you like to add coverage reporting to your CI?" |
| Unit tests only, no E2E | "You have unit tests but no E2E tests. For a {framework} project, would Playwright E2E tests be valuable?" |
| Tests exist but not in CI | "Tests exist but CI does not run them. Should we integrate test runs into your workflow?" |

##### Category: Dependencies (only if scan found gaps)

| Scan Finding | Question |
|-------------|----------|
| No dep automation | "There is no automated dependency update tool (Dependabot/Renovate). Would you like to set one up?" |
| Major version gaps detected | "Some dependencies are behind major versions: {list top 3}. Should we prioritize updating them, or is stability more important right now?" |
| Large node_modules / many deps | "The project has {N} dependencies. Are you open to auditing them for unused packages?" |

##### Category: CI/CD (only if scan found gaps)

| Scan Finding | Question |
|-------------|----------|
| No CI at all | "There is no CI/CD pipeline. Would you like to set one up? Which platform: (1. GitHub Actions (recommended), 2. GitLab CI, 3. Other)?" |
| CI exists but no deploy | "CI runs tests but does not deploy. Would you like to automate deployment?" |
| No security scanning in CI | "CI does not include security scanning. Should we add dependency auditing or SAST?" |

##### Category: Code Quality (only if scan found gaps)

| Scan Finding | Question |
|-------------|----------|
| No TypeScript in JS project | "The project uses JavaScript without TypeScript. Would TypeScript be valuable for your use case, or is JS preferred?" |
| No linting/formatting | "No linter or formatter configured. Would you like to add one? (1. Biome (recommended — fast, all-in-one), 2. ESLint + Prettier, 3. Not now)" |
| No strict mode (TS) | "TypeScript is configured but not in strict mode. Would you like to enable it for better type safety?" |

##### Category: Documentation (only if scan found gaps)

| Scan Finding | Question |
|-------------|----------|
| No CLAUDE.md | "No CLAUDE.md found. This file helps AI tools understand your project. Generate one?" |
| README is minimal (<20 lines) | "The README is quite minimal. Should we expand it with setup instructions and usage examples?" |
| No API documentation | "The project has API endpoints but no API documentation. Would OpenAPI/Swagger docs be useful?" |

##### Category: Deployment & Operations (only if scan found gaps)

| Scan Finding | Question |
|-------------|----------|
| Docker but no health check | "Docker setup exists but has no health checks. Want to add production hardening (health checks, resource limits, graceful shutdown)?" |
| No Docker at all | "No containerization found. Would Docker be useful for consistent dev/prod environments?" |
| No monitoring/logging | "No monitoring or structured logging detected. Is observability a priority?" |

##### Category: Architecture (only if scan found ambiguity)

| Scan Finding | Question |
|-------------|----------|
| Mixed patterns detected | "The codebase mixes {pattern A} and {pattern B}. Is this intentional, or should we consolidate?" |
| No clear folder structure | "The project structure is flat. Would you benefit from a more organized folder convention?" |
| Monorepo without tooling | "This looks like a monorepo but has no monorepo tooling (Turborepo/Nx). Would that help?" |

##### Category: Constraints

Always ask (exactly one question to close):

> **What are the constraints for improvements?**
> 1. Quick fixes only — I need results today (30 minutes)
> 2. A focused afternoon — I can invest 2-4 hours
> 3. Proper refactor — I have a few days
> 4. Full rebuild is on the table — whatever it takes
>
> **Who maintains this project?**
> 1. Just me (solo developer)
> 2. Small team (2-5 people)
> 3. Larger team or open source

### Phase 3 — Recommend (Automatic)

Based on scan results + user answers, generate a prioritized recommendation list.

**Priority tiers:**

| Tier | Name | Criteria | Typical effort |
|------|------|----------|---------------|
| 1 | **Quick Wins** | High impact, low effort, no risk | 5-30 minutes each |
| 2 | **Medium Effort** | Significant improvement, moderate effort | 1-4 hours each |
| 3 | **Strategic** | Architectural or stack changes, high effort | Days to weeks |

**Recommendation generation rules:**
- Quick Wins first — always give the user something they can do right now
- Match recommendations to the user's stated time constraint
- If user said "quick fixes only", only show Tier 1 items
- If user said "full rebuild", include Tier 3 items
- Never recommend changing something that is working well
- Respect the user's stack preference (if they said "optimize current", no stack changes)
- Include reasoning for every recommendation — "why" matters

### Phase 4 — Plan (Automatic)

Generate the consultation report and structured plan.

---

## Mode: quick

Automated recommendations without deep questions. For when you want fast answers.

### Procedure

1. Run `/scan full` internally (or read existing profile)
2. Skip Phase 2 (no interactive questions)
3. Assume defaults:
   - Goal: "Everything — full assessment"
   - Constraints: "Focused afternoon (2-4 hours)"
   - Maintainer: "Solo developer"
4. Generate recommendations (Phase 3) based on scan gaps alone
5. Output compact report

### Output Format (quick mode)

```
Quick Consultation: {project-name}
============================================

Based on scan, here are the top improvements:

QUICK WINS (do these now):
  1. [+CLAUDE.md] Generate a CLAUDE.md — run /scan generate
  2. [+Linting] Add Biome for formatting/linting consistency
  3. [+.editorconfig] Add .editorconfig for cross-editor consistency

RECOMMENDED (invest an afternoon):
  4. [+Tests] Add Vitest for critical business logic
  5. [+CI] Set up GitHub Actions: test + lint + build on PR
  6. [+Deps] Add Dependabot for automated dependency updates

STRATEGIC (plan when ready):
  7. [TypeScript] Migrate from JavaScript to TypeScript
  8. [Docker] Add containerization for deployment consistency

Run /consult start for a guided consultation with targeted questions.
```

---

## Mode: plan

Re-generate or refine the plan from a previous consultation.

### Procedure

1. Read `.consult-state.json`
   - If not found: Tell user to run `/consult start` first
2. Re-generate plan based on stored answers and current scan
3. Optionally re-scan if profile is stale (> 7 days)
4. Output the plan (same format as start mode Phase 4)

Useful when: The user ran `/consult start` previously, made some improvements,
and wants an updated plan based on current state.

---

## Consultation Report Format

Generated at the end of `start` and `quick` modes.

```
Project Consultation: {project-name}
Date: {date}
============================================

PROJECT UNDERSTANDING:
  Type: {architecture} ({framework})
  Stack: {language} + {framework} + {css} + {database}
  Maturity: {prototype | mvp | production | legacy}
  Maintainer: {solo | small-team | large-team}

HEALTH ASSESSMENT:
  Overall: {score}/10
  +-----------------+-------+----------------------------------+
  | Category        | Score | Assessment                       |
  +-----------------+-------+----------------------------------+
  | Stack           |  9/10 | Modern, well-chosen              |
  | Testing         |  3/10 | No tests, significant risk       |
  | CI/CD           |  7/10 | CI exists, deploy is manual      |
  | Documentation   |  4/10 | README only, no CLAUDE.md        |
  | Code Quality    |  8/10 | TypeScript strict, linting good  |
  | Security        |  6/10 | Basics covered, no dep scanning  |
  | Deployment      |  5/10 | Docker exists, no health checks  |
  +-----------------+-------+----------------------------------+

USER PRIORITIES:
  Primary goal: {from question 1}
  Time budget: {from constraints question}
  Stack changes: {open to changes | optimize current}

IMPROVEMENT PLAN:

Phase 1 — Quick Wins (Today, ~1 hour total)
  1. Generate CLAUDE.md
     Why: Helps AI tools and new contributors understand the project
     How: Run /scan generate
     Effort: 2 minutes

  2. Add .editorconfig
     Why: Consistent formatting across editors and contributors
     How: Create .editorconfig with indent, charset, EOL rules
     Effort: 5 minutes

  3. Add Dependabot configuration
     Why: Automated security updates for dependencies
     How: Create .github/dependabot.yml
     Effort: 10 minutes

Phase 2 — Medium Effort (This week, ~4 hours total)
  4. Set up Vitest for critical paths
     Why: {user said reliability is important} + no tests exist
     How: Install vitest, create test for {most critical module}
     Effort: 2 hours
     Dependencies: None

  5. Add health checks to Docker setup
     Why: Production containers should self-report health
     How: Add HEALTHCHECK to Dockerfile, health endpoint to app
     Effort: 1 hour
     Dependencies: None

Phase 3 — Strategic (Plan for next sprint)
  6. Migrate to TypeScript strict mode
     Why: Catches bugs at compile time, better DX
     How: Enable strict in tsconfig, fix type errors incrementally
     Effort: 2-5 days (depending on codebase size)
     Dependencies: Items 4-5 should be done first

NEXT STEPS:
  - Start with Phase 1 items — they take minutes and have immediate impact
  - Run /project-audit for a thorough code-level review
  - After implementing changes, run /consult plan to get an updated plan
```

---

## State File (.consult-state.json)

Written after every consultation. Enables `/consult plan` to regenerate.

```json
{
  "version": "1.0",
  "consultDate": "2026-03-20",
  "mode": "start",
  "project": "my-project",
  "scanProfile": ".scan-profile.json",
  "answers": {
    "primaryGoal": "reliability",
    "timeBudget": "afternoon",
    "maintainer": "solo",
    "testing": "add-unit-tests",
    "cicd": "keep-current",
    "typescript": "not-now",
    "docker": "add-health-checks",
    "claudeMd": "yes-generate"
  },
  "recommendations": [
    {
      "id": 1,
      "tier": "quick-win",
      "title": "Generate CLAUDE.md",
      "status": "open",
      "effort": "2 minutes"
    },
    {
      "id": 2,
      "tier": "medium",
      "title": "Set up Vitest",
      "status": "open",
      "effort": "2 hours"
    }
  ],
  "healthScore": {
    "overall": 6,
    "categories": {
      "stack": 9,
      "testing": 3,
      "cicd": 7,
      "documentation": 4,
      "codeQuality": 8,
      "security": 6,
      "deployment": 5
    }
  }
}
```

---

## Maturity Assessment

Automatically determined from scan results. Guides the tone of recommendations.

| Level | Criteria | Consultation style |
|-------|----------|--------------------|
| **Prototype** | Few files, no tests, no CI, no deployment config | "Get the basics right first" |
| **MVP** | Working app, some structure, missing tests/CI | "Solidify what you have before adding features" |
| **Production** | Tests, CI, deployment, docs present | "Optimize and harden" |
| **Legacy** | Outdated deps, old patterns, large codebase | "Modernize incrementally, do not rewrite" |

**Detection heuristics:**

```
prototype:  sourceFiles < 20 AND no tests AND no CI
mvp:        sourceFiles < 100 AND (no tests OR no CI)
production: tests AND CI AND deployment config
legacy:     framework version > 2 majors behind OR node < current LTS - 2
```

---

## Question Quality Rules

Questions make or break the consultation. These rules ensure they are valuable.

1. **Context-aware** — Every question references a specific finding from the scan
2. **Actionable options** — Each answer maps to a concrete recommendation
3. **Opinionated defaults** — Always mark the recommended option (first position)
4. **No dead-end answers** — "Not now" is valid but still generates alternative advice
5. **Progressive depth** — Start broad (goals), narrow down (specifics), close with constraints
6. **No repetition** — If the scan already answered it, do not ask
7. **Grouped when related** — "Tests + CI" can be one compound question if both are missing
8. **Max 8 questions** — Hard limit. Prioritize questions by impact of the answer

---

## Integration with Other Skills

### Depends On

| Skill | Relationship |
|-------|-------------|
| `/scan` | Runs internally or reads `.scan-profile.json` |

### Recommends After

| Condition | Recommendation |
|-----------|---------------|
| Plan generated | "Start implementing Phase 1 quick wins" |
| Testing gaps | "Run `/project-audit` to identify critical test targets" |
| Security gaps | "Run `/project-audit` with security focus" |
| Design/UX mentioned | "Run `/polish scan` for frontend assessment" |
| Large codebase | "Run `/project-audit auto` for systematic review" |
| After implementation | "Run `/consult plan` to regenerate your plan with progress" |

### State Contract

| State File | Role |
|-----------|------|
| `.scan-profile.json` | Read (input from `/scan`) |
| `.consult-state.json` | Write (own state) |
| `.project-audit-state.json` | Read (if exists — enrich understanding) |
| `.audit-state.json` | Read (if exists — enrich understanding) |

---

## Anti-Patterns (What NOT to Do)

| Anti-Pattern | Why it is bad | Instead |
|-------------|---------------|---------|
| Generic advice ("add tests") | User already knows that | "Add Vitest tests for your auth middleware — it handles login and has no coverage" |
| Recommending everything | Overwhelming, no prioritization | Tier the recommendations, respect time budget |
| Stack shaming | "Your stack is outdated" is not helpful | "Your stack works. Here is what would improve DX: ..." |
| Ignoring constraints | Recommending a rewrite when user has 30 minutes | Match recommendations to stated time budget |
| Over-engineering | Suggesting Kubernetes for a 50-file project | Right-size recommendations to project scale |
| Asking obvious questions | "Do you use TypeScript?" when tsconfig.json exists | Only ask what the scan could not determine |

---

## Context Protection

- **Max 10 questions** per consultation session (hard limit)
- **Max 15 recommendations** in the plan
- **Write state after Phase 2** (answers preserved even if session ends)
- **Write state after Phase 4** (full plan preserved)
- **On context limit:** Save state, recommend `/consult plan` in next session

---

## Rules

1. **Scan before consulting** — Never recommend without understanding the project first
2. **Ask before prescribing** — Phase 2 exists for a reason. Do not skip it in start mode
3. **Respect user answers** — If they said "not now" to TypeScript, do not sneak it into the plan
4. **Concrete over abstract** — Every recommendation must have a "How" with specific steps
5. **Effort estimates are honest** — Do not underestimate. Include setup time
6. **No stack shaming** — Every stack was chosen for a reason. Improve, do not judge
7. **Quick wins are real** — Tier 1 items must genuinely take under 30 minutes
8. **Plans are actionable** — Someone should be able to follow the plan step by step
9. **State enables continuity** — A consultation can span multiple sessions via state
10. **Read-only by default** — The consultant does not modify files. It creates a plan. Execution is separate

---

## Files

```
consult/
└── SKILL.md    <- This file
```
