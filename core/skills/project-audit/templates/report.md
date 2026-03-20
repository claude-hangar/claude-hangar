# Project Audit Report: {PROJECT_NAME}

**Date:** {DATE}
**Auditor:** {{AUDITOR_NAME}}
**Project Type:** {PROJECT_TYPE}
**Stack:** {STACK_SUMMARY}
**Scope:** {SCOPE} ({PHASES_DONE}/{PHASES_TOTAL} phases)

---

## Executive Summary

{SUMMARY_TEXT}

| Severity | Total | Open | Fixed | Skipped |
|----------|-------|------|-------|---------|
| CRITICAL | {C_TOTAL} | {C_OPEN} | {C_FIXED} | {C_SKIPPED} |
| HIGH | {H_TOTAL} | {H_OPEN} | {H_FIXED} | {H_SKIPPED} |
| MEDIUM | {M_TOTAL} | {M_OPEN} | {M_FIXED} | {M_SKIPPED} |
| LOW | {L_TOTAL} | {L_OPEN} | {L_FIXED} | {L_SKIPPED} |
| **Total** | **{TOTAL}** | **{OPEN}** | **{FIXED}** | **{SKIPPED}** |

---

## Findings by Phase

### Phase 01: Structure & Architecture

{STRUC_FINDINGS_OR_EMPTY}

### Phase 02: Dependencies & Ecosystem

{DEP_FINDINGS_OR_EMPTY}

### Phase 03: Code Quality

{QUAL_FINDINGS_OR_EMPTY}

### Phase 04: Git & Versioning

{GIT_FINDINGS_OR_EMPTY}

### Phase 05: CI/CD & Automation

{CICD_FINDINGS_OR_EMPTY}

### Phase 06: Documentation & Onboarding

{DOC_FINDINGS_OR_EMPTY}

### Phase 07: Testing & QA

{TEST_FINDINGS_OR_EMPTY}

### Phase 08: Security & Secrets

{SEC_FINDINGS_OR_EMPTY}

### Phase 09: Deployment & Operations

{DEPLOY_FINDINGS_OR_EMPTY}

### Phase 10: Maintenance & Hygiene

{MAINT_FINDINGS_OR_EMPTY}

---

## Finding Detail Format

Per finding:

```
#### {ID}: {TITLE}
- **Severity:** {SEVERITY}
- **Status:** {STATUS}
- **Location:** {LOCATION}
- **Description:** {DESCRIPTION}
- **Recommendation:** {RECOMMENDATION}
{- **Fixed in:** Session {N} (if fixed)}
{- **Notes:** {NOTES} (if present)}
```

---

## Audit Quality

### Completeness Per Phase

| Phase | MUST | SHOULD | COULD | Total | Completeness |
|-------|------|--------|-------|-------|-------------|
| 01 Structure | {MUST_DONE}/{MUST_TOTAL} | {SHOULD_DONE}/{SHOULD_TOTAL} | {COULD_DONE}/{COULD_TOTAL} | {DONE}/{TOTAL} | {PERCENT}% |
| 02 Dependencies | ... | ... | ... | ... | ...% |
| 03 Code Quality | ... | ... | ... | ... | ...% |
| 04 Git | ... | ... | ... | ... | ...% |
| 05 CI/CD | ... | ... | ... | ... | ...% |
| 06 Documentation | ... | ... | ... | ... | ...% |
| 07 Testing | ... | ... | ... | ... | ...% |
| 08 Security | ... | ... | ... | ... | ...% |
| 09 Deployment | ... | ... | ... | ... | ...% |
| 10 Maintenance | ... | ... | ... | ... | ...% |

### Assessment Scale

- **100% MUST:** Phase considered fully checked
- **<100% MUST:** Phase INCOMPLETE — skipped MUST-checks documented with reason
- **SHOULD/COULD:** Informational, no completeness requirement

### Check Layers

| Layer | Method | Phases |
|-------|--------|--------|
| Source | Code analysis, config reading | All |
| Runtime | npm audit, tsc --noEmit, docker scout, tests | 02, 03, 07, 08, 09 |

---

## Trend Analysis

{TREND_SECTION_OR_EMPTY}

If history data is available in state:

```
Trend (recent audits):
  CRITICAL: {C_TREND}  {C_DIRECTION}
  HIGH:     {H_TREND}  {H_DIRECTION}
  MEDIUM:   {M_TREND}  {M_DIRECTION}
  Total:    {T_TREND}
Assessment: {TREND_ASSESSMENT}
```

### Severity Matrix (Reference)

| Finding Type | Typical Severity | Example |
|-------------|------------------|---------|
| SEC: Secrets in repo | CRITICAL | API key in Git history |
| SEC: Missing SBOM | LOW | Best practice |
| SEC: Container not signed | LOW | Sigstore/cosign |
| CICD: write-all permissions | HIGH | Overly broad workflow permissions |
| CICD: Actions not SHA-pinned | MEDIUM | Supply chain risk |
| CICD: OIDC not used | MEDIUM | Long-lived secrets |
| CICD: pull_request_target insecure | HIGH | Fork attack possible |
| DEP: CVE in dependency | HIGH | npm audit CRITICAL |
| DEP: Corepack not configured | LOW | Version inconsistency |
| TEST: Coverage <30% | HIGH | Barely tested |
| TEST: Coverage <70% | MEDIUM | Below recommendation |
| DEPLOY: No rollback | HIGH | Outage risk |
| DEPLOY: Container running as root | HIGH | Privilege escalation |
| DEPLOY: docker-compose V1 | LOW | Deprecated |

---

## Diff Since Last Report

{DIFF_SECTION_OR_EMPTY}

If a previous report exists:
- **New findings:** {NEW_COUNT} since {PREV_DATE}
- **Fixed:** {FIXED_SINCE_COUNT}
- **Still open:** {STILL_OPEN_COUNT}

---

## Recommendations (Prioritized)

1. **Immediate (CRITICAL):** {CRITICAL_RECOMMENDATIONS}
2. **Short-term (HIGH):** {HIGH_RECOMMENDATIONS}
3. **Mid-term (MEDIUM):** {MEDIUM_RECOMMENDATIONS}
4. **Optional (LOW):** {LOW_RECOMMENDATIONS}

---

## Next Steps

{NEXT_STEPS}

Generation logic for `{NEXT_STEPS}`:

```
1. IF open CRITICAL/HIGH findings > 3:
   > "- `/adversarial-review audit` — Check report for gaps"
2. IF web project (package.json has frontend framework) AND no .audit-state.json:
   > "- `/audit start` — Check website quality (SEO, A11y, Performance, Privacy)"
3. IF Astro detected AND no .astro-audit-state.json:
   > "- `/astro-audit start` — Astro-specific migration/best-practices"
4. ALWAYS:
   > "- `/lesson-learned session` — Extract learnings from the audit"
```

---

*Report generated on {DATE} with Project Audit v5.0 (OWASP 2025, SLSA, SBOM, Completeness Tracking).*
