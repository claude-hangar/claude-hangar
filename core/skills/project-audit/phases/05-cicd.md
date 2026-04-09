# Phase 05: CI/CD & Automation

Workflows, Actions Security, Deployment-Pipelines, Automation-Hooks.
Finding-Prefix: `CICD`

---

## Checks

### 1. CI/CD Workflows

- [ ] CI/CD vorhanden? (GitHub Actions, GitLab CI, Jenkins, etc.)
- [ ] Build-Step: Code wird gebaut/kompiliert?
- [ ] Test-Step: Tests laufen automatisch?
- [ ] Lint-Step: Linting automatisiert?
- [ ] Deploy-Step: Automatisch oder manuell? Dokumentiert?
- [ ] Letzte Runs: Gruen oder rot? Seit wann?
- [ ] Pipeline-Laufzeit: Akzeptabel? (<10 Min fuer PR-Checks)

### 2. GitHub Actions Security

- [ ] `permissions:` Block explizit gesetzt? (nicht default `write-all`)
- [ ] Secrets als Repository/Environment Secrets? (nicht hardcodiert)
- [ ] Third-Party Actions: Per SHA gepinnt? (nicht `@latest` oder `@v1`)
- [ ] `GITHUB_TOKEN` Scope: Minimal noetige Permissions?
- [ ] Keine Secrets in Logs/Artifacts?
- [ ] `pull_request_target`: Nicht verwendet? (oder sicher konfiguriert)
- [ ] Environment Protection Rules fuer Prod-Deployments?
- [ ] **Timezone Cron (Maerz 2026):** `timezone` Feld neben cron-Expression? (IANA, z.B. `Europe/Berlin`) — verhindert UTC-Versatz
- [ ] **Environments ohne Deployment (Maerz 2026):** `deployment: false` wenn Environment nur fuer Secrets/Approval, nicht fuer Deployments genutzt wird
- [ ] **GitHub Agentic Workflows (Technical Preview, Feb 2026):** `.github/workflows/` Markdown-Dateien werden via `gh aw` CLI in Actions konvertiert — pruefen ob fuer das Projekt relevant

### 3. Deployment-Pipeline

- [ ] Deploy-Prozess dokumentiert?
- [ ] Staging-Umgebung vorhanden? (nicht direkt auf Prod)
- [ ] Rollback-Strategie: Wie kommt man zurueck?
- [ ] Blue/Green oder Rolling Updates?
- [ ] Manuelles Approval vor Prod-Deploy?
- [ ] Deploy-Logs: Nachvollziehbar wer wann was deployed hat?

### 4. Automation & Bots

- [ ] Dependabot / Renovate konfiguriert?
- [ ] Auto-Merge fuer Dependabot-PRs? (verhindert Branch-Ansammlung)
- [ ] Branch-Cleanup nach Merge automatisiert?
- [ ] Release-Automation: Automatische Changelogs, Tag-Erstellung?
- [ ] Issue/PR-Templates vorhanden?

**Fix-Templates:** Wenn Dependabot fehlt oder Auto-Merge nicht eingerichtet:
→ Templates aus `claude-hangar/templates/ci/` ins Projekt kopieren:
- `dependabot.yml` → `.github/dependabot.yml`
- `dependabot-automerge.yml` → `.github/workflows/dependabot-automerge.yml`
Severity: MEDIUM wenn Dependabot fehlt, LOW wenn nur Auto-Merge fehlt.

### 5. Pipeline-Qualitaet

- [ ] DRY: Keine Copy-Paste zwischen Workflows?
- [ ] Reusable Workflows / Composite Actions genutzt?
- [ ] Caching: Dependencies gecacht? (node_modules, pip cache)
- [ ] Matrix-Builds: Mehrere OS/Versionen getestet?
- [ ] Fail-Fast: Pipeline bricht bei erstem Fehler ab?
- [ ] Artifacts: Sinnvoll archiviert? (Test-Reports, Coverage, Builds)

### 6. Notifications

- [ ] Pipeline-Fehler: Team wird benachrichtigt?
- [ ] Deploy-Notifications: Slack, E-Mail, Telegram?
- [ ] Eskalation: Wer wird bei CRITICAL-Fehlern alarmiert?

---

## Ergebnis

Findings als CICD-01, CICD-02, ... dokumentieren.
Actions mit write-all Permissions: HIGH. Keine CI/CD: MEDIUM. Kein Caching: LOW.

---

As of: 2026-04-09 (added GitHub Agentic Workflows tech preview note, GitHub Actions timezone cron, deployment:false environments)
