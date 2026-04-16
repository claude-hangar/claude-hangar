# Audit-Orchestrator — Combined Report

When all active audits have completed, a combined report is produced. The structure below is the legacy web-orchestration format — the universal mode's Phase 4 output (`04-report/REPORT.md`) follows the same shape plus an "Applied Changes" section and the project profile from `01-prescan/`.

## Format

```markdown
# Overall Audit Report: {ProjectName}
Date: {YYYY-MM-DD}
Stack: {detected stack}

## Executive Summary
- {N} audits run: /audit, /{framework}-audit, /project-audit
- {N} findings total ({N} CRITICAL, {N} HIGH, {N} MEDIUM, {N} LOW)
- {N} fixed, {N} open, {N} skipped
- Estimated remaining effort: {N} sessions

## Critical Findings (cross-audit)
All CRITICAL + HIGH findings sorted by severity, with source audit annotated.

## Findings by Category
### Security (Web + Supply-Chain)
Findings from /audit Phase 02 + /project-audit Phase 08 merged.

### Performance & SEO
Findings from /audit Phases 03 and 04.

### Accessibility
Findings from /audit Phase 05. Mark regulatory relevance (WCAG 2.2, regional laws).

### Privacy
Findings from /audit Phase 07. Mark applicable privacy regulations.

### Framework Migration
Findings from /{framework}-audit (all sections).

### Code & CI/CD
Findings from /project-audit Phases 03 and 05.

### Infrastructure & Deployment
Findings from /audit Phase 08 + /project-audit Phase 09 merged.

### Maintenance & Hygiene
Findings from /project-audit Phase 10.

## Regulatory Compliance
| Standard | Status | Relevant Findings |
|----------|--------|-------------------|
| WCAG 2.2 (Accessibility) | {Status} | A11Y-* |
| Data Protection (GDPR / regional) | {Status} | PRIV-* |
| Digital Services (platform regulations) | {Status} | PRIV-* |

Add/remove rows based on detected jurisdiction and applicable laws.

## Related Projects
Status and recommendations for related projects (cross-repo dependencies).

## Trend Analysis
If prior reports exist: comparison against the last audit.

## Recommended Fix Order
Prioritized: CRITICAL → HIGH → MEDIUM → LOW, security before functional, migration blockers before quality issues.
```

## Generate Report

```
/audit-orchestrator report
```

Reads all state files (legacy: `.audit-state.json`, `.{framework}-audit-state.json`, `.project-audit-state.json`; universal: `.audit-session/<slug>/02-analysis/findings.md` + `03-optimization/changes.md`) and writes `AUDIT-REPORT-COMBINED-{YYYY-MM-DD}.md` (legacy) or `04-report/REPORT.md` inside the session directory (universal).

## Universal Mode Mapping

When a universal session is active, the combined report sections map to universal phase artifacts:

| Report Section | Universal Source |
|----------------|------------------|
| Executive Summary | aggregated from `INDEX.md` counts + `02-analysis/findings.md` |
| Critical Findings | `02-analysis/findings.md` filtered by severity |
| Findings by Category | `02-analysis/findings.md` grouped by ID prefix (SEC-, PERF-, A11Y-, PRIV-, MIG-, DEP-, CI-, INFRA-, DOC-, ...) |
| Regulatory Compliance | `02-analysis/findings.md` where tagged with a regulatory ID |
| Related Projects | `01-prescan/project-profile.md` → `relatedProjects` block |
| Trend Analysis | prior `04-report/REPORT.md` files in sibling session directories |
| Recommended Fix Order | `02-analysis/TODO.md` severity ordering + `03-optimization/TODO.md` deferred tail |

The `03-optimization/changes.md` log is added to the report as a standalone "Applied Changes" section so the reader sees both what was found and what was actually fixed.
