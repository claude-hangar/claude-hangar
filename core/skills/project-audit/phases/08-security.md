# Phase 08: Security & Secrets

Secrets, Supply-Chain, Container-Security, Runtime-Security, SAST.
Finding-Prefix: `SEC`

---

## Checks

### 1. Secrets im Repo

- [ ] `.env` in `.gitignore`?
- [ ] `.env.example` vorhanden mit allen Keys (ohne echte Werte)?
- [ ] `git log -p -- .env` / `git log -p -- *.key`: Jemals Secrets committet?
- [ ] Keine API-Keys, Passwoerter, Tokens hardcodiert im Code?
- [ ] Suche nach Patterns: `password=`, `secret=`, `api_key=`, `token=`, `PRIVATE KEY`
- [ ] Secret-Scanning: Tooling aktiv? (GitHub Secret Scanning, gitleaks, trufflehog)

### 2. Credentials & API-Keys

- [ ] API-Keys: Minimale Permissions? (nicht Admin-Key fuer Read-Only)
- [ ] Rotation: Werden Keys regelmaessig erneuert?
- [ ] Verschiedene Keys fuer Dev/Staging/Prod?
- [ ] Dokumentiert: Welche Secrets braucht das Projekt? Wo bekommt man sie?
- [ ] Vault/Secrets-Manager: Genutzt fuer sensitive Config?

### 3. Supply-Chain Security

- [ ] Lock-File committet? Integritaets-Hashes?
- [ ] Dependabot / Renovate konfiguriert?
- [ ] Keine Pakete von unbekannten/aufgegebenen Autoren?
- [ ] Typosquatting: Paket-Namen korrekt geschrieben?
- [ ] Registry-Scoping: Interne Pakete aus privatem Registry?
- [ ] SBOM generierbar?

### 4. Container-Security (falls Docker vorhanden)

- [ ] Keine Secrets in Dockerfile (ENV, ARG, COPY .env)?
- [ ] Multi-Stage Build: Build-Secrets nicht im finalen Image?
- [ ] Base-Image: Aktuell? Keine bekannten CVEs? (`docker scout`, `trivy`)
- [ ] Non-Root User im Container? (`USER` Direktive)
- [ ] Read-Only Filesystem wo moeglich?
- [ ] Capabilities: `cap_drop: ALL` + nur noetige zurueck?
- [ ] Pinned Base-Image: Digest oder konkreter Tag (nicht `:latest`)?

### 5. Runtime-Security

- [ ] HTTPS: Alle URLs im Code mit https:// (nicht http://)?
- [ ] Error-Messages: Keine Stack-Traces in User-facing Errors?
- [ ] Logging: Keine Secrets/PII in Log-Output?
- [ ] Input-Validierung: Alle externen Eingaben validiert?
- [ ] Rate Limiting: Bei APIs vorhanden?
- [ ] CORS: Korrekt konfiguriert? (nicht `*` in Prod)

### 6. File Permissions

- [ ] Sensitive Dateien (Keys, Configs): Nicht world-readable?
- [ ] Executable-Bit: Nur auf Dateien die es brauchen?
- [ ] SSH-Keys: 600 Permissions?
- [ ] .git/ Verzeichnis: Nicht oeffentlich zugaenglich (Webserver)?

### 7. Static Analysis (SAST)

- [ ] SAST-Tool konfiguriert? (CodeQL, Semgrep, Bandit, gosec)
- [ ] In CI integriert?
- [ ] Findings reviewed? Keine ignorierten Critical?
- [ ] Custom Rules fuer projektspezifische Patterns?

### 8. Backup & Recovery

- [ ] Sensitive Daten verschluesselt gesichert?
- [ ] Backup-Strategie dokumentiert?
- [ ] Recovery getestet?
- [ ] Encryption-at-Rest fuer Datenbanken?

---

## Ergebnis

Findings als SEC-01, SEC-02, ... dokumentieren.
Secrets im Git-Repo: CRITICAL. Fehlende Validierung: HIGH. Fehlende .env.example: MEDIUM.
