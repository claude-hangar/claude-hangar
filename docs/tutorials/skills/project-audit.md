# Projekt-Audit — Generelles Projekt-Audit

> Systematischer Qualitaets-Check fuer jedes Repository. Prueft Struktur, Dependencies, Code-Qualitaet, Git, CI/CD, Dokumentation, Testing, Security, Deployment und Maintenance — unabhaengig vom Tech-Stack. Mit Dreischicht-Modell und Stack-Supplements.

## Wann brauche ich das?

- Du willst ein Repo gruendlich durchpruefen (egal ob Webseite, CLI-Tool oder Management-Repo)
- Du willst sicherstellen dass Basics stimmen (Doku, Tests, Secrets, Git, Deployment)
- Du willst ein Projekt auf Uebergabe-Qualitaet bringen
- Du brauchst einen strukturierten Report ueber den Projektzustand

## Abgrenzung zu /audit

| | `/audit` | `/project-audit` |
|---|---------|------------------|
| Zielgruppe | Webseiten | Alle Repos |
| SEO, A11y, DSGVO | Ja | Nein |
| Lighthouse, Bilder | Ja | Nein |
| Git-Hygiene | Basis | Gruendlich |
| CI/CD Security | Basis | Gruendlich |
| Dokumentation | Basis | Gruendlich |
| Code-Qualitaet | Basis | Gruendlich |
| Deployment | Basis | Gruendlich |
| Maintenance | Nein | Ja |
| Stack-Supplements | 8 (Web-fokussiert) | 5 (allgemein) |
| Report-Modus | Ja | Ja |

## Architektur: Dreischicht-Modell

```
Schicht 1: Basis-Phase (phases/*.md)           ~70-100 Zeilen, universell
Schicht 2: Stack-Supplement (stacks/*.md)       ~10-15 Zeilen pro §-Sektion
Schicht 3: Projekt-Override (project-audit-context.md)  projektspezifisch
```

Stack-Supplements werden automatisch erkannt und geladen:
- **Node.js** — erkannt durch `package.json`
- **Python** — erkannt durch `pyproject.toml`, `setup.py`, `requirements.txt`
- **Shell/Bash** — erkannt durch Mehrheit `*.sh` Dateien
- **Docker** — erkannt durch `Dockerfile`, `docker-compose.*`
- **Monorepo** — erkannt durch `workspaces` in package.json

## So geht's

### Schritt 1: Audit starten

```
/project-audit start
```

Was passiert:
1. **Projekt-Typ** wird erkannt (management-repo, cli-tool, library, backend-service, monorepo, etc.)
2. **Stack** wird erkannt (Node.js, Python, Shell, Docker, Monorepo)
3. **Frage:** Komplett (alle 10 Phasen) oder Fokus?
4. **Erste 2 Phasen** werden durchlaufen (mit Stack-Supplements)
5. **Findings** dokumentiert (z.B. STRUC-01, DEP-02)
6. **State** in `.project-audit-state.json` gespeichert

### Schritt 2: Weiterarbeiten

```
/project-audit weiter
```

Naechste 2 Phasen oder max 5 Findings fixen.

### Schritt 3: Fortschritt

```
/project-audit status
```

### Schritt 4: Report generieren

```
/project-audit report
```

Generiert `PROJECT-AUDIT-REPORT-{DATUM}.md` im Projekt-Root.

## Die 10 Phasen

| Phase | Prueft | Finding-Prefix |
|-------|--------|---------------|
| 01 Struktur & Architektur | Ordnerstruktur, Patterns, Coupling, Layering | STRUC |
| 02 Dependencies & Ecosystem | Pakete, Versionen, Ecosystem Health, Lizenzen | DEP |
| 03 Code-Qualitaet | Patterns, Complexity, Dead Code, Types, Linting | CODE |
| 04 Git & Versionierung | .gitignore, Commits, Branches, Tags, History | GIT |
| 05 CI/CD & Automation | Workflows, Actions Security, Pipelines, Hooks | CICD |
| 06 Dokumentation & Onboarding | README, ADRs, API-Docs, Runbooks, DX | DOC |
| 07 Testing & QA | Test-Pyramide, Coverage, E2E, Performance Tests | TEST |
| 08 Security & Secrets | Secrets, Supply-Chain, Container-Sec, SAST | SEC |
| 09 Deployment & Operations | Docker, Server, Monitoring, Rollback | DEPLOY |
| 10 Maintenance & Hygiene | Tech Debt, Lifecycle, Deprecations, Cleanup | MAINT |

## Beispiel-Session

```
Session 1:
Du: /project-audit start
→ "Projekt-Typ: management-repo (Shell/Bash)"
→ "Stack: Shell, Docker erkannt"
→ "Komplett oder Fokus?" → Du: "Komplett"
→ Struktur: 2 Findings (1 MEDIUM, 1 LOW)
→ Dependencies: 0 Findings (kein package.json)
→ "2 Findings. /project-audit weiter"

Session 2:
Du: /project-audit weiter
→ Code-Qualitaet: 1 Finding (MEDIUM — shellcheck Warnungen)
→ Git: 1 Finding (LOW — stale Branches)
→ "4 Findings gesamt. /project-audit weiter"

Session 3:
Du: /project-audit weiter
→ CI/CD: 2 Findings (1 HIGH — Actions ohne Permissions, 1 MEDIUM)
→ Dokumentation: 1 Finding (MEDIUM — fehlende Setup-Anleitung)
→ "7 Findings. /project-audit weiter"

Session 4:
Du: /project-audit weiter
→ Testing: 1 Finding (HIGH — keine Tests)
→ Security: 0 Findings (alles sauber)
→ "8 Findings. /project-audit weiter"

Session 5:
Du: /project-audit weiter
→ Deployment: 1 Finding (MEDIUM — kein Health-Check)
→ Maintenance: 1 Finding (LOW — fehlender Changelog)
→ "10 Findings. Alle 10 Phasen durch! /project-audit report"

Session 6:
Du: /project-audit report
→ PROJECT-AUDIT-REPORT-2026-02-17.md generiert
```

## Projekt-spezifischer Kontext

Lege eine `project-audit-context.md` im Projekt-Root an, um projektspezifische Regeln hinzuzufuegen:

```markdown
# Project-Audit Kontext

## Bekannte Ausnahmen
- STRUC: Flache Struktur ist gewollt (Management-Repo)
- DEP: Keine package.json — reines Bash-Projekt

## Fokus-Bereiche
- Security ist kritisch (Infrastruktur-Repo mit SSH-Keys)
- Git-Hygiene wichtig (viele Contributors)

## Zusaetzliche Checks
- Alle age-verschluesselten Backups aktuell?
- SSH-Config konsistent mit server.json?
```

## Haeufige Fragen

- **Funktioniert das auch ohne package.json?** → Ja. Stack-Detection erkennt Python, Shell und Docker automatisch. Checks passen sich an.
- **Kann ich Phasen ueberspringen?** → Ja, bei `start` "Nur Security und Deployment" sagen.
- **Was ist der Unterschied zu /audit?** → `/audit` = Web-spezifisch (SEO, A11y, DSGVO). `/project-audit` = generisch (Git, Code, Deployment, Maintenance).
- **Wie funktionieren die Stack-Supplements?** → Pro Phase werden automatisch zusaetzliche Checks geladen, basierend auf dem erkannten Stack. Ein Node.js-Projekt bekommt z.B. `npm audit` Checks in der Security-Phase.
- **Kann ich einen Report generieren?** → Ja, mit `/project-audit report`. Generiert Markdown mit Executive Summary und priorisierten Empfehlungen.

## Naechste Schritte

- [Audit](audit.md) — Website-spezifischer Audit
- [Pipeline-Uebersicht](../pipeline-uebersicht.md) — Gesamtsystem
