# Audit-Report: {PROJECT_NAME}

**Datum:** {DATE}
**Auditor:** {{AUDITOR_NAME}}
**Stack:** {STACK_SUMMARY}
**Umfang:** {SCOPE} ({PHASES_DONE}/{PHASES_TOTAL} Phasen)

---

## Executive Summary

{SUMMARY_TEXT}

| Severity | Gesamt | Offen | Behoben | Uebersprungen |
|----------|--------|-------|---------|---------------|
| CRITICAL | {C_TOTAL} | {C_OPEN} | {C_FIXED} | {C_SKIPPED} |
| HIGH | {H_TOTAL} | {H_OPEN} | {H_FIXED} | {H_SKIPPED} |
| MEDIUM | {M_TOTAL} | {M_OPEN} | {M_FIXED} | {M_SKIPPED} |
| LOW | {L_TOTAL} | {L_OPEN} | {L_FIXED} | {L_SKIPPED} |
| **Gesamt** | **{TOTAL}** | **{OPEN}** | **{FIXED}** | **{SKIPPED}** |

---

## Findings nach Phase

### Phase 01: IST-Analyse

{IST_FINDINGS_OR_EMPTY}

### Phase 02: Security

{SEC_FINDINGS_OR_EMPTY}

### Phase 03: Performance

{PERF_FINDINGS_OR_EMPTY}

### Phase 04: SEO

{SEO_FINDINGS_OR_EMPTY}

### Phase 05: Accessibility

{A11Y_FINDINGS_OR_EMPTY}

### Phase 06: Code-Qualitaet

{CODE_FINDINGS_OR_EMPTY}

### Phase 07: DSGVO

{DSGVO_FINDINGS_OR_EMPTY}

### Phase 08: Infrastruktur

{INFRA_FINDINGS_OR_EMPTY}

---

## Finding-Detail-Format

Pro Finding:

```
#### {ID}: {TITLE}
- **Severity:** {SEVERITY}
- **Status:** {STATUS}
- **Location:** {LOCATION}
- **Beschreibung:** {DESCRIPTION}
- **Empfehlung:** {RECOMMENDATION}
{- **Behoben in:** Session {N} (falls fixed)}
{- **Notizen:** {NOTES} (falls vorhanden)}
```

---

## Diff seit letztem Report

{DIFF_SECTION_OR_EMPTY}

Falls ein vorheriger Report existiert:
- **Neue Findings:** {NEW_COUNT} seit {PREV_DATE}
- **Behoben:** {FIXED_SINCE_COUNT}
- **Unveraendert offen:** {STILL_OPEN_COUNT}

---

## Empfehlungen (Priorisiert)

1. **Sofort (CRITICAL):** {CRITICAL_RECOMMENDATIONS}
2. **Kurzfristig (HIGH):** {HIGH_RECOMMENDATIONS}
3. **Mittelfristig (MEDIUM):** {MEDIUM_RECOMMENDATIONS}
4. **Optional (LOW):** {LOW_RECOMMENDATIONS}

---

## Naechste Schritte

{NEXT_STEPS}

---

*Report generiert am {DATE} mit audit-v2.*
