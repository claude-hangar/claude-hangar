# Phase 02: Security

Sicherheitspruefung nach OWASP Top 10:2025 (8. Edition) und Web-Security Best Practices.
Finding-Prefix: `SEC`

> **OWASP Top 10:2025 (8. Edition)** — 2 neue Kategorien: A03 Software Supply Chain Failures
> (erweitert aus "Vulnerable and Outdated Components") und A10 Mishandling of Exceptional Conditions.
> 589 CWEs in 248 Kategorien analysiert (175.000 CVE Records).
> A01 Broken Access Control bleibt #1, Security Misconfiguration stieg auf #2.

---

## Checks

### 1. HTTP Security Headers

- [ ] `Content-Security-Policy`: Definiert? Restriktiv genug? Kein `unsafe-inline` / `unsafe-eval`?
- [ ] `Strict-Transport-Security`: Gesetzt mit max-age >= 31536000? includeSubDomains?
- [ ] `X-Content-Type-Options: nosniff`
- [ ] `X-Frame-Options: DENY` oder `SAMEORIGIN`
- [ ] `Referrer-Policy`: Sinnvoller Wert (z.B. `strict-origin-when-cross-origin`)?
- [ ] `Permissions-Policy`: Kamera, Mikrofon, Geolocation eingeschraenkt?
- [ ] Headers per curl/Browser DevTools gegen Live-URL pruefen

### 2. Authentifizierung & Autorisierung

- [ ] Admin-Bereiche geschuetzt? (Basic Auth, JWT, Session)
- [ ] Staging-Umgebung: Zugang eingeschraenkt? (Basic Auth, IP-Whitelist)
- [ ] API-Endpoints: Authentifizierung erforderlich wo noetig?
- [ ] CORS: Nur erlaubte Origins? Kein Wildcard `*` bei authentifizierten Requests?
- [ ] Rate Limiting: Auf Login-, Formular- und API-Endpoints?

### 3. Input Validation & Injection

- [ ] Server-seitige Validierung: Alle User-Inputs validiert?
- [ ] SQL/NoSQL Injection: Prepared Statements / Parameterized Queries?
- [ ] XSS: Output-Encoding? Framework-eigene Sanitization genutzt?
- [ ] Path Traversal: Datei-Uploads und -Zugriffe abgesichert?
- [ ] Command Injection: Kein `exec()` / `eval()` mit User-Input?

### 4. Secrets & Konfiguration

- [ ] `.env` in `.gitignore`? Keine Secrets im Repo?
- [ ] `git log` nach versehentlich committeten Secrets durchsuchen
- [ ] API-Keys: Rotiert? Minimale Berechtigungen?
- [ ] Staging vs. Prod: Unterschiedliche Credentials?
- [ ] Docker: Keine Secrets in Image-Layers? Multi-Stage Build?

### 5. Dependencies & Supply Chain (OWASP 2026: A03 Software Supply Chain Failures)

- [ ] `npm audit`: CRITICAL/HIGH Vulnerabilities?
- [ ] Dependabot / Renovate konfiguriert?
- [ ] Lock-File committet? (Supply-Chain-Angriffe verhindern)
- [ ] Unbekannte oder kaum gewartete Dependencies?
- [ ] Build-System-Integritaet: CI/CD Pipeline gegen Manipulation geschuetzt?
- [ ] Distribution-Integritaet: Package-Publishing-Prozess abgesichert?

### 5b. AI Agent Security (wenn AI-Agenten eingesetzt)

Basierend auf OWASP Top 10 for Agentic Applications 2026:

- [ ] Setzt das Projekt AI-Agenten ein? (Claude Code, LangChain, AutoGPT, Custom Agents)
- [ ] **Goal Hijacking:** Sind Agent-Ziele gegen Prompt Injection geschuetzt?
- [ ] **Tool Misuse:** Haben Agenten minimale Tool-Berechtigungen? (Least Privilege)
- [ ] **Rogue Agents:** Koennen Agenten unkontrolliert andere Agenten starten?
- [ ] **Cascading Failures:** Fehlerbehandlung bei Agent-Ketten? (kein unkontrolliertes Retry)
- [ ] **Identity & Auth:** Agenten-Aktionen nachvollziehbar? (Audit Trail)
- [ ] **Data Exfiltration:** Koennen Agenten sensitive Daten nach aussen senden?

### 6. CI/CD Pipeline Security

- [ ] GitHub Actions / CI Workflows vorhanden?
- [ ] Workflow-Permissions: Minimal? (`permissions:` Block explizit gesetzt?)
- [ ] Secrets: Korrekt als Repository/Environment Secrets? Nicht hardcodiert?
- [ ] Third-Party Actions: Gepinnt per SHA? (nicht `@latest` oder `@v1`)
- [ ] Branch-Protection: Push auf main/master geschuetzt? PR-Review erforderlich?
- [ ] Artifacts: Keine Secrets in Build-Outputs oder Logs?

### 7. SSL/TLS

- [ ] HTTPS erzwungen? HTTP → HTTPS Redirect?
- [ ] TLS-Version: Mindestens 1.2? (1.0/1.1 deaktiviert?)
- [ ] Zertifikat: Gueltig? Auto-Renewal (Let's Encrypt)?
- [ ] Mixed Content: Keine HTTP-Ressourcen auf HTTPS-Seiten?

---

## Ergebnis

Findings als SEC-01, SEC-02, ... dokumentieren.
Security-Findings immer mindestens HIGH, bei Datenexposition CRITICAL.
AI-Agent ohne Berechtigungsgrenzen: HIGH. Agent-Datenexfiltration: CRITICAL.

---

As of: 2026-04-04 (updated for OWASP Top 10:2025 8th edition — new A03 Software Supply Chain Failures, A10 Mishandling of Exceptional Conditions; A01 BAC #1, SecMisconfig #2)
