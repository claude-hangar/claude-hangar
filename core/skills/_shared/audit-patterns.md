# Shared Audit Patterns

Shared concepts for `/audit`, `/project-audit`, `/astro-audit`, `/sveltekit-audit`, and `/auth-audit`. Referenced by all audit skills.

---

## Verification-Depth (v4.9)

Every finding must be verified beyond Level 1 (Existence):

| Level | Question | Action |
|-------|----------|--------|
| **1. Existence** | Does the artifact exist? | Check if file/config is present |
| **2. Substantive** | Is the content meaningful (not a stub)? | No placeholder, no default values |
| **3. Wired** | Is it wired/active? | Integrated into build/server/pipeline? |
| **4. Functional** | Does it work? | Test with tools (curl, build, test) |

**Rule:** A check only passes from Level 2 onwards. Level 4 is mandatory when Live/Runtime layer is available.

### Stub Detection

Actively search for stubs:
- Functions that only `return null/undefined/true`
- Empty catch blocks or error swallowing
- Config files with only default values
- Files < 5 lines that should be complex

---

## Fix Protocol: Verification-Before-Completion (v4.9)

No fix may be considered complete without verification. 5 steps:

```
1. IDENTIFY  — Name finding-ID + location
2. RUN       — Implement fix
3. READ      — Re-read the changed file (not from memory)
4. VERIFY    — Test (build, curl, Lighthouse, npm test, etc.)
5. CLAIM     — Only now set status: "fixed" in state
```

**Step 3 (READ) and 4 (VERIFY) must NEVER be skipped.**
If VERIFY is not possible (server/tool offline): document as note in state.

---

## Check Priorities: MUST / SHOULD / COULD

| Marker | Meaning | Consequence |
|--------|---------|-------------|
| **[MUST]** | Mandatory check | Phase is INCOMPLETE if not executed |
| **[SHOULD]** | Standard check | Can be skipped with justification |
| **[COULD]** | Nice-to-have | Can be omitted under time pressure, no quality loss |

**Rule:** A phase with <100% MUST-checks can NOT be marked as `done`.
Skipped MUST-checks must be documented with justification in `checksSkipped[]`.

---

## Completeness Tracking

At the end of each phase a completeness count MUST be performed:

```
Phase NN — Completeness:
  MUST: X/Y (Z%)
  SHOULD: X/Y (Z%) — N skipped (reason)
  COULD: X/Y (Z%)
  Total: X/Y (Z%)
```

Data is stored in state per phase (completeness object in phase entry).

---

## Smart Recommendation (Decision Logic)

In `continue` mode, analyze state before asking user:

```
IF open CRITICAL findings > 0:
  > "Recommendation: Fix {N} CRITICAL findings first ({IDs})"
IF open HIGH findings > 3:
  > "Recommendation: Fix {N} HIGH findings, then continue with phases"
ELSE IF phases open:
  > "Recommendation: Next phases ({phase names})"
ELSE:
  > "Recommendation: Fix remaining findings ({N} open)"
```

Show recommendation as **first option** in AskUserQuestion, with brief justification.

---

## Layer Status Standard

All audit skills use uniform string enums for layer status:

| Value | Meaning |
|-------|---------|
| `"done"` | Layer fully checked |
| `"pending"` | Layer not yet checked |
| `"in-progress"` | Layer currently being checked |
| `"not-applicable"` | Layer not relevant for this phase |

**Layer types per skill:**

| Skill | Layer 1 | Layer 2 |
|-------|---------|---------|
| `/audit` | `source` (Code/Config) | `live` (curl, Lighthouse, Playwright) |
| `/project-audit` | `source` (Code/Config) | `runtime` (npm audit, tsc, docker scout) |
| `/astro-audit` | `source` (Code/Config) | `runtime` (npm view, Build-Test) |
| `/sveltekit-audit` | `source` (Code/Config) | `runtime` (npm view, Build-Test, svelte-check) |
| `/auth-audit` | `source` (Code/Config) | `runtime` (Login-Tests, Cookie-Check) |

**Migration:** Old boolean values (`true`/`false`) are automatically migrated: `true` > `"done"`, `false` > `"pending"`.

---

## Context Protection (CRITICAL)

- **Max 2 phases OR 5 fixes per session** — never both (except `auto` mode)
- **Write state immediately** after each phase and each fix
- **No auto-fix** — document findings, user decides (except `auto` mode)
- **Always read existing docs first** — no duplicates from previous audits
- **On interruption:** State is always current, next session can resume seamlessly
- **Completeness requirement:** MUST-checks count; phase with <100% MUST cannot be `done`
- **Layer tracking:** Document both layer statuses per phase

---

## Skill Synergy (v6.0)

Skills that are aware of each other, build upon each other, and tell the user what makes sense next — without forced coupling.

### Principles

1. **Independently usable:** Every skill works standalone — synergy is a bonus, not a requirement
2. **State as contract:** State files are the interface between skills — who produces, who reads
3. **Optional read:** If a state file does not exist, the skill still works
4. **nextSteps:** At the end, each skill recommends suitable follow-up skills (based on findings)
5. **priorContext:** At start, each skill reads available states and uses them as context

### nextSteps — Who Recommends Whom

| Skill | Recommends Afterward |
|-------|---------------------|
| `/audit report` | `/astro-audit` (if Astro), `/adversarial-review audit`, `/polish scan`, `/lesson-learned` |
| `/astro-audit` done | `/audit start` (if not yet run), `/project-audit start`, `/lighthouse-quick` |
| `/sveltekit-audit` done | `/audit start` (if not run), `/project-audit start`, `/db-audit`, `/auth-audit` |
| `/project-audit report` | `/adversarial-review audit`, `/lesson-learned` |
| `/polish` done | `/lighthouse-quick`, `/capture-pdf quick` |
| `/auth-audit` done | `/db-audit` (if DB findings), `/audit start` (if not run), `/lesson-learned` |
| `/adversarial-review audit` | Regenerate report after fixes |

### priorContext — Who Reads Whom

| Skill | Reads State From | Benefit |
|-------|-----------------|---------|
| `/polish` | `.audit-state.json` (all phases) | Severity-based prioritization |
| `/polish` | `.micro-check-results.json` | Micro-skill results as input |
| `/lesson-learned` | All 3 audit states | Fixing patterns + migration learnings |
| `/audit auto` | `.audit-orchestrator-state.json` | Skip delegated phases |
| `/project-audit auto` | `.audit-orchestrator-state.json` | Skip delegated phases |
| `/audit-orchestrator` | `.freshness-state.json` opportunities[] | Pre-audit notes with HIGH opportunities |
| `/adversarial-review audit` | `.audit-state.json` / `.project-audit-state.json` | Write back gap findings |

### State Contract Table

| State File | Producer | Consumers |
|------------|----------|-----------|
| `.audit-state.json` | `/audit` | `/polish`, `/lesson-learned`, `/adversarial-review`, `/audit-orchestrator` |
| `.project-audit-state.json` | `/project-audit` | `/lesson-learned`, `/adversarial-review`, `/audit-orchestrator` |
| `.astro-audit-state.json` | `/astro-audit` | `/lesson-learned`, `/audit-orchestrator` |
| `.sveltekit-audit-state.json` | `/sveltekit-audit` | `/lesson-learned`, `/audit-orchestrator` |
| `.auth-audit-state.json` | `/auth-audit` | `/lesson-learned`, `/audit-orchestrator` |
| `.db-audit-state.json` | `/db-audit` | `/lesson-learned`, `/audit-orchestrator` |
| `.audit-orchestrator-state.json` | `/audit-orchestrator` | `/audit auto`, `/project-audit auto` |
| `.freshness-state.json` | `/freshness-check` | `/audit-orchestrator` |
| `.polish-state.json` | `/polish` | (standalone) |
| `.micro-check-results.json` | `/favicon-check`, `/meta-tags`, `/lighthouse-quick` | `/polish` |

### Finding Prefix Registry

No finding-ID collisions between skills:

| Prefix | Skill | Phase/Area |
|--------|-------|------------|
| IST | `/audit` | 01 Baseline Analysis |
| SEC | `/audit` + `/project-audit` | Security (Web vs. Supply-Chain) |
| PERF | `/audit` | 03 Performance |
| SEO | `/audit` | 04 SEO |
| A11Y | `/audit` | 05 Accessibility |
| CODE | `/audit` | 06 Code Quality |
| GDPR | `/audit` | 07 Privacy/GDPR |
| INFRA | `/audit` | 08 Infrastructure |
| CD | `/audit` | 09 Content & Design |
| STRUC | `/project-audit` | 01 Structure |
| DEP | `/project-audit` | 02 Dependencies |
| QUAL | `/project-audit` | 03 Code Quality |
| GIT | `/project-audit` | 04 Git |
| CICD | `/project-audit` | 05 CI/CD |
| DOC | `/project-audit` | 06 Documentation |
| TEST | `/project-audit` | 07 Testing |
| DEPLOY | `/project-audit` | 09 Deployment |
| MAINT | `/project-audit` | 10 Maintenance |
| MIG | `/astro-audit` | Migration |
| BP | `/astro-audit` + `/sveltekit-audit` | Best Practice |
| SKT | `/sveltekit-audit` | SvelteKit-specific |
| AUTH | `/auth-audit` | Authentication & Session Security |
| DB | `/db-audit` | Database (Schema, Migration, Connection, Security, Performance) |
| R- | `/adversarial-review` | Review Findings |

**Note:** SEC is intentionally used in both `/audit` (web security) and `/project-audit` (supply chain) — the orchestrator coordinates the split.
