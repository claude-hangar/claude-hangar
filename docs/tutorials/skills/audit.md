# Audit — Generischer Website-Audit

> Systematischer Qualitaets-Check fuer jedes Webprojekt. Erkennt den Tech-Stack automatisch, laedt passende Pruef-Module und fuehrt strukturierte Pruefungen in 8 Phasen durch.

## Wann brauche ich das?

- Du willst ein Webprojekt gruendlich durchpruefen (Code, Performance, Security, DSGVO...)
- Du willst vor einem Release sicherstellen dass alles sauber ist
- Du willst gezielt einen Bereich pruefen (z.B. nur Security oder nur Accessibility)
- Du willst einen strukturierten Report erstellen

## So geht's

### Schritt 1: Audit starten

```
/audit start
```

Was passiert:
1. **Auto-Detection** — Der Stack wird erkannt (Astro? Tailwind v4? Docker? Traefik? Fastify? SQLite?)
2. **Kontext laden** — Projekt-CLAUDE.md, audit-context.md (falls vorhanden), bestehende Docs
3. **Frage:** Komplett-Audit (alle 8 Phasen) oder Fokus auf bestimmte Phasen?
4. **Erste 2 Phasen** werden durchlaufen
5. **Findings** werden dokumentiert (z.B. SEC-01, PERF-03, A11Y-02)
6. **State** wird in `.audit-state.json` gespeichert

### Schritt 2: Weiterarbeiten

```
/audit weiter
```

Was passiert:
- Falls noch Phasen offen: naechste 2 Phasen durchlaufen
- Falls alle Phasen durch: naechste 5 Findings zum Fixen anbieten (hoechste Severity zuerst)
- Du entscheidest: fixen, ueberspringen oder andere auswaehlen

### Schritt 3: Fortschritt pruefen

```
/audit status
```

Zeigt Fortschritt aller 8 Phasen + Findings-Statistik nach Severity.

### Schritt 4: Report erstellen

```
/audit report
```

Generiert einen strukturierten Markdown-Report (`AUDIT-REPORT-{Datum}.md`) mit:
- Executive Summary, Findings nach Phase, priorisierte Empfehlungen
- Diff zu vorherigem Report (falls vorhanden)

## Die 8 Phasen

| Phase | Prueft | Finding-Prefix |
|-------|--------|---------------|
| 01 IST-Analyse | Versionen, Config, Architektur, Build | IST |
| 02 Security | OWASP, Headers, Secrets, Auth, CORS | SEC |
| 03 Performance | Lighthouse, Core Web Vitals, Bilder, Caching | PERF |
| 04 SEO | Meta-Tags, Structured Data, Sitemap, URLs | SEO |
| 05 Accessibility | WCAG AA, Kontrast, ARIA, Keyboard, Touch | A11Y |
| 06 Code-Qualitaet | Linting, Types, Tests, Dependencies | CODE |
| 07 DSGVO | Cookies, Fonts, Analytics, Consent, Impressum | DSGVO |
| 08 Infrastruktur | VPS, Docker, Reverse Proxy, Backup, Monitoring | INFRA |

## Dreischicht-Modell

Der Audit kombiniert automatisch drei Wissensquellen:

```
Schicht 1: Basis-Phase (universell)         — gilt fuer alle Webprojekte
Schicht 2: Stack-Supplement (spezifisch)    — z.B. Astro, Docker, Traefik Checks
Schicht 3: Projekt-Override (individuell)   — audit-context.md im Projekt-Root
```

**Stack-Supplements** werden automatisch geladen wenn erkannt:
Astro, Fastify, Tailwind v4, Docker, Traefik, nginx, SQLite

**audit-context.md** ist optional — fuer projektspezifischen Kontext wie verwandte Projekte, Server, Architektur-Entscheidungen, Audit-Fokus.

## Findings verstehen

| Severity | Bedeutung | Beispiel |
|----------|-----------|---------|
| CRITICAL | Sofort handeln! Security, Datenverlust | Offener DB-Port, fehlende Auth, kein Backup |
| HIGH | Wichtig, zeitnah fixen | Performance >2s, fehlende Validierung, XSS |
| MEDIUM | Sollte man verbessern | Fehlende Alt-Texte, kein Error Handling |
| LOW | Nice-to-have | Veraltete Dependency, fehlende Docs |

**Reihenfolge:** CRITICAL → HIGH → MEDIUM → LOW. Security vor Funktional vor Optisch.

## Beispiel-Session

```
Session 1:
Du: /audit start
→ "Astro 6, Tailwind v4, Docker, Traefik erkannt"
→ "audit-context.md gefunden ✓"
→ "Komplett-Audit oder Fokus?" → Du: "Komplett"
→ IST-Analyse: 2 Findings (1 MEDIUM, 1 LOW)
→ Security: 3 Findings (1 HIGH, 2 MEDIUM)
→ "5 Findings insgesamt. /audit weiter fuer naechste Phasen"

Session 2:
Du: /audit weiter
→ Performance: 2 Findings (1 HIGH, 1 MEDIUM)
→ SEO: 1 Finding (MEDIUM)
→ "8 Findings insgesamt. /audit weiter fuer Accessibility + Code"

Session 3:
Du: /audit weiter
→ Accessibility: 3 Findings (1 HIGH, 2 MEDIUM) — BFSG besonders gruendlich
→ Code-Qualitaet: 1 Finding (LOW)
→ "12 Findings. /audit weiter fuer DSGVO + Infrastruktur"

Session 4:
Du: /audit weiter
→ DSGVO: 1 Finding (MEDIUM)
→ Infrastruktur: 2 Findings (1 HIGH, 1 MEDIUM)
→ "15 Findings. Alle Phasen abgeschlossen! /audit weiter fuer Fixes"

Session 5:
Du: /audit weiter
→ "4 HIGH Findings zuerst. Angehen?"
→ Du: "Ja"
→ 4 Fixes umgesetzt und getestet
→ "4 gefixt. Noch 11 offen. /audit report fuer Report"

Session 6:
Du: /audit report
→ Generiert AUDIT-REPORT-2026-02-17.md
```

## Haeufige Fragen

- **Kann ich nur bestimmte Phasen pruefen?** → Ja, bei `/audit start` sagen: "Nur Security und DSGVO" oder "Nur Performance".
- **Was wenn ein Finding gar kein Problem ist?** → Finding ueberspringen (`skipped`). Nicht alles muss gefixt werden.
- **Wie lange dauert ein kompletter Audit?** → Typisch 4-6 Sessions (8 Phasen + Fixes).
- **Wird automatisch etwas geaendert?** → Nein. Findings werden dokumentiert, du entscheidest was gefixt wird.
- **Was ist der Unterschied zu /astro-audit?** → `/audit` prueft alles (Code, Server, Security, DSGVO...). `/astro-audit` prueft nur Astro-Versions- und Migrationsthemen.
- **Brauche ich audit-context.md?** → Nein, ist optional. Der Audit funktioniert auch ohne — dann nur mit Auto-Detection und Basis-Phasen.
- **Kann ich einen Report generieren?** → Ja, `/audit report` erstellt einen strukturierten Markdown-Report mit allen Findings.

## Naechste Schritte

- [Astro-Audit](astro-audit.md) — Astro-spezifischer Versions-Audit
- [Explorer](explorer.md) — Code analysieren ohne etwas zu aendern
- [Pipeline-Uebersicht](../pipeline-uebersicht.md) — Gesamtsystem verstehen
