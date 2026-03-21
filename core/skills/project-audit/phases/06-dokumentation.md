# Phase 06: Dokumentation & Onboarding

README, CLAUDE.md, ADRs, API-Docs, Onboarding-DX, Runbooks.
Finding-Prefix: `DOC`

---

## Checks

### 1. README.md

- [ ] Vorhanden?
- [ ] **Beschreibung:** Was macht das Projekt? Wofuer ist es da?
- [ ] **Setup-Anleitung:** Schritt-fuer-Schritt wie man das Projekt startet?
- [ ] **Prerequisites:** Welche Tools/Versionen braucht man?
- [ ] **Usage:** Wie benutzt man es? Beispiele?
- [ ] **Aktuell:** Stimmt die Beschreibung noch mit dem Code ueberein?
- [ ] **Keine toten Links:** Alle URLs/Pfade erreichbar?
- [ ] **Badges:** Build-Status, Version, License? (bei oeffentlichen Repos)

### 2. CLAUDE.md / Projekt-Kontext

- [ ] Vorhanden? (Projekt-spezifische Claude Code Anweisungen)
- [ ] Architektur-Entscheidungen dokumentiert?
- [ ] DO NOT CHANGE Regeln fuer kritische Bereiche?
- [ ] Key Files Tabelle mit Pfaden und Zweck?
- [ ] Stack/Versionen korrekt angegeben?
- [ ] Deployment-Prozess beschrieben?

### 3. Architecture Decision Records (ADRs)

- [ ] Bei komplexen Projekten: ADRs vorhanden? (docs/adr/ oder docs/decisions/)
- [ ] Format: Kontext, Entscheidung, Konsequenzen?
- [ ] Aktuelle Entscheidungen dokumentiert? (nicht nur historische)
- [ ] Verworfene Alternativen erwaehnt?

### 4. API-Dokumentation

- [ ] Falls API vorhanden: Endpoints dokumentiert?
- [ ] Request/Response-Formate? Beispiele?
- [ ] Fehler-Codes und ihre Bedeutung?
- [ ] OpenAPI/Swagger Spec? Aktuell?
- [ ] Postman/Insomnia Collection?

### 5. Onboarding-DX (Developer Experience)

- [ ] Kann jemand Neues das Projekt in <15 Min starten?
- [ ] Alle Konfigurationsoptionen dokumentiert?
- [ ] .env.example mit allen Keys (ohne Werte)?
- [ ] Undokumentiertes "Tribal Knowledge"?
- [ ] Troubleshooting-Sektion fuer haeufige Probleme?
- [ ] Contributing Guide? (bei Team-/Open-Source-Projekten)

### 6. Runbooks & Operations

- [ ] Deployment-Runbook: Wie deployed man?
- [ ] Rollback-Runbook: Wie geht man zurueck?
- [ ] Incident-Response: Was tun bei Ausfall?
- [ ] Monitoring-Docs: Welche Metriken, wo schauen?
- [ ] Backup/Restore-Doku?

### 7. CHANGELOG & Versionierung

- [ ] CHANGELOG.md oder Releases vorhanden?
- [ ] Aktuell? Letzte Aenderungen dokumentiert?
- [ ] Format konsistent? (Keep a Changelog, Conventional Changelog)
- [ ] Lizenz: LICENSE Datei vorhanden? Typ passend?

### 8. Status-Dokumente

- [ ] STATUS.md / TODO.md: Offene Punkte dokumentiert?
- [ ] ROADMAP: Geplante Features/Aenderungen?
- [ ] Known Issues: Bekannte Probleme dokumentiert?

---

## Ergebnis

Findings als DOC-01, DOC-02, ... dokumentieren.
Fehlende README: HIGH. Fehlende .env.example: HIGH. Veraltete Doku: MEDIUM. Fehlende Lizenz: LOW.
