# Audit Report: {PROJECT_NAME}

**Date:** {DATE}
**Auditor:** {{AUDITOR_NAME}}
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

### Phase 01: Baseline Analysis

{IST_FINDINGS_OR_EMPTY}

### Phase 02: Security

{SEC_FINDINGS_OR_EMPTY}

### Phase 03: Performance

{PERF_FINDINGS_OR_EMPTY}

### Phase 04: SEO

{SEO_FINDINGS_OR_EMPTY}

### Phase 05: Accessibility

{A11Y_FINDINGS_OR_EMPTY}

### Phase 06: Code Quality

{CODE_FINDINGS_OR_EMPTY}

### Phase 07: Privacy/GDPR

{GDPR_FINDINGS_OR_EMPTY}

### Phase 08: Infrastructure

{INFRA_FINDINGS_OR_EMPTY}

### Phase 09: Content & Design

{CD_FINDINGS_OR_EMPTY}

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

Direction indicators:
- (declining/resolved) — Improvement
- (rising) — Deterioration, action needed
- (stable) — Stagnation

### Severity Matrix (Reference)

| Finding Type | Typical Severity | Example |
|-------------|------------------|---------|
| SEC: SSRF, secrets in repo | CRITICAL | Server-side access to internal networks |
| SEC: Missing headers, SRI | MEDIUM | CORP/COOP/SRI missing |
| SEC: security.txt missing | LOW | Best practice |
| PERF: LCP >4s | HIGH | Hero image unoptimized |
| PERF: Speculation Rules missing | LOW | Modern API not used |
| SEO: Sitemap missing | HIGH | Indexing impacted |
| SEO: AI crawlers not configured | LOW | Deliberate decision missing |
| A11Y: Keyboard navigation missing | HIGH | WCAG 2.2 AA requirement |
| A11Y: Focus covered by sticky element | HIGH | WCAG 2.2, 2.4.11 |
| A11Y: Target size <24px | MEDIUM | WCAG 2.2, 2.5.8 |
| A11Y: Captcha without alternative | HIGH | WCAG 2.2, 3.3.8 |
| GDPR: Missing privacy policy | CRITICAL | Legal risk |
| GDPR: Consent Mode v2 missing | HIGH | Google data collection blocked |
| GDPR: Accessibility statement missing | HIGH | Fines possible |
| GDPR: Data processing agreements missing | MEDIUM | Compliance gap |
| INFRA: Docker running as root | HIGH | Container escape risk |
| INFRA: docker-compose (V1) instead of compose | LOW | Deprecated |

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

## Audit Quality

### Completeness Per Phase

| Phase | MUST-Checks | Executed | Skipped | Completeness |
|-------|-------------|----------|---------|-------------|
| 01 Baseline Analysis | {IST_MUST} | {IST_DONE} | {IST_SKIP} | {IST_PCT}% |
| 02 Security | {SEC_MUST} | {SEC_DONE} | {SEC_SKIP} | {SEC_PCT}% |
| 03 Performance | {PERF_MUST} | {PERF_DONE} | {PERF_SKIP} | {PERF_PCT}% |
| 04 SEO | {SEO_MUST} | {SEO_DONE} | {SEO_SKIP} | {SEO_PCT}% |
| 05 Accessibility | {A11Y_MUST} | {A11Y_DONE} | {A11Y_SKIP} | {A11Y_PCT}% |
| 06 Code Quality | {CODE_MUST} | {CODE_DONE} | {CODE_SKIP} | {CODE_PCT}% |
| 07 Privacy/GDPR | {GDPR_MUST} | {GDPR_DONE} | {GDPR_SKIP} | {GDPR_PCT}% |
| 08 Infrastructure | {INFRA_MUST} | {INFRA_DONE} | {INFRA_SKIP} | {INFRA_PCT}% |
| 09 Content & Design | {CD_MUST} | {CD_DONE} | {CD_SKIP} | {CD_PCT}% |
| **Total** | **{TOTAL_MUST}** | **{TOTAL_DONE}** | **{TOTAL_SKIP}** | **{TOTAL_PCT}%** |

**Assessment:**
- 100% MUST-checks = Complete audit
- 80-99% = Largely complete (skipped checks justified)
- <80% = Incomplete — catch up on missing checks

### Check Layers

| Phase | Source Layer | Live Layer | Notes |
|-------|-------------|------------|-------|
{LAYER_TABLE}

Source layer: Code/config analysis (read files, grep, AST)
Live layer: Browser/tool-based checks (curl, Lighthouse, Playwright, axe)

---

## Next Steps

{NEXT_STEPS}

Generation logic for `{NEXT_STEPS}`:

```
1. IF Astro detected AND no .astro-audit-state.json:
   > "- `/astro-audit start` — Check Astro-specific migration/best-practices"
2. IF open CRITICAL/HIGH findings > 3:
   > "- `/adversarial-review audit` — Check report for gaps"
3. IF Phase 09 content findings > 0:
   > "- `/polish scan` — Create design X-ray, identify quick wins"
4. IF no .project-audit-state.json:
   > "- `/project-audit start` — Check code quality, Git, CI/CD"
5. ALWAYS:
   > "- `/lesson-learned session` — Extract learnings from the audit"
```

---

*Report generated on {DATE} with Website Audit v5.0 (OWASP 2025, WCAG 2.2, GDPR, Completeness Tracking).*
