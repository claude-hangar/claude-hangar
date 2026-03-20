# Tutorial: Your First Audit

This tutorial walks you through running a website audit, understanding the output, and acting on findings.

## Prerequisites

- Claude Code installed and configured
- Claude Hangar deployed (`bash setup.sh` completed)
- A project with a website (any framework)

## Step 1: Start the Audit

Navigate to your project directory, start Claude Code, and run:

```
/audit start
```

The audit auto-detects your stack (framework, CSS, deployment tools) and shows a detection table. You will be asked about audit scope (complete vs. focused) and phase order (sequential vs. smart). For your first audit, choose **Complete** with **Smart Order** (security first).

After setup, the audit runs the first 2 phases and produces findings like:

```
SEC-03 [HIGH] -- Missing CSP Header
  Location: docker-compose.yml:traefik-labels
  Problem:  Content-Security-Policy header is completely missing
  Impact:   XSS attacks are not restricted by browser policy
  Fix:      Configure CSP header in Traefik labels or middleware
```

### Severity levels

| Level | Meaning | Action |
|-------|---------|--------|
| CRITICAL | Security vulnerability, data loss risk | Fix immediately |
| HIGH | Functional bug, major performance issue | Fix soon |
| MEDIUM | Code quality, UX issue | Fix when convenient |
| LOW | Cosmetic, nice-to-have | Document, no pressure |

Finding IDs use phase-specific prefixes: IST (Baseline), SEC (Security), PERF (Performance), SEO, A11Y (Accessibility), CODE, GDPR (Privacy), INFRA (Infrastructure), CD (Content & Design). IDs are stable across sessions.

## Step 2: Check Progress

After the first session:

```
/audit status
```

This shows phase completion, finding counts by severity, and completeness percentages.

## Step 3: Continue and Fix

In your next session:

```
/audit continue
```

The skill generates a smart recommendation (e.g., "Fix 1 CRITICAL finding first"). You can follow it or continue with the next phases instead.

When fixing, the audit works through findings by severity (CRITICAL first):

1. Problem shown with context
2. Fix template loaded (if available)
3. User confirms before applying
4. Fix implemented and verified
5. State updated (`"fixed"` with session number)

Maximum 5 fixes per session to prevent context exhaustion.

## Step 4: Adversarial Review

After completing all phases:

```
/adversarial-review audit
```

This critically reviews your audit for missing categories, severity misratings, incomplete phases, and copy-paste findings. It produces at least 5 findings. "Gap" findings can be written back to the audit state.

## Step 5: Generate the Report

```
/audit report
```

Generates `AUDIT-REPORT-{date}.md` with executive summary, findings by phase, trend analysis (if previous reports exist), and next steps.

## Step 6: View the State File

The complete state is in `.audit-state.json`:

```bash
cat .audit-state.json | jq .
```

Key sections: `phases[]` (status/completeness), `findings[]` (all findings), `stack` (detected tech), `session` (session count).

## What Next?

| Situation | Next step |
|-----------|-----------|
| Astro project | `/astro-audit` for framework-specific checks |
| Many open findings | Fix CRITICAL/HIGH, then `/audit continue` |
| Deeper analysis | `/adversarial-review code` on recent changes |
| Multiple projects | `/audit-orchestrator` for coordinated audits |

## Quick Reference

```
/audit start      -- begin new audit (detection + first 2 phases)
/audit continue   -- next phases or fix findings
/audit status     -- show progress
/audit report     -- generate markdown report
/audit auto       -- fully autonomous run (all phases, no prompts)
```
