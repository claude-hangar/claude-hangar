# Phase 09: Deployment & Operations

Docker, Server, Monitoring, Rollback, Health-Checks, Infrastruktur.
Finding-Prefix: `DEPLOY`

---

## Checks

### 1. Deployment-Prozess

- [ ] Deployment dokumentiert? (README, Runbook, CLAUDE.md)
- [ ] Automatisiert? (CI/CD Pipeline, Skripte)
- [ ] Reproduzierbar? (Gleicher Input = gleicher Output)
- [ ] Versioniert? (Welcher Code-Stand ist deployed?)
- [ ] Deploy-History nachvollziehbar?

### 2. Docker / Container

- [ ] Dockerfile vorhanden und funktionsfaehig?
- [ ] docker-compose fuer lokale Entwicklung?
- [ ] Multi-Stage Build? (Build-Tools nicht im finalen Image)
- [ ] Image-Groesse optimiert? (Alpine, distroless)
- [ ] Health Checks im Dockerfile/Compose definiert?
- [ ] .dockerignore: Vollstaendig?
- [ ] Restart Policy: `unless-stopped` oder `always`?
- [ ] Log-Rotation konfiguriert?

### 3. Server & Infrastruktur

- [ ] Server dokumentiert? (IP, Provider, OS, Zweck)
- [ ] SSH-Zugang: Key-basiert? Kein Passwort-Login?
- [ ] Firewall: UFW/iptables konfiguriert?
- [ ] Updates: Unattended-Upgrades aktiviert?
- [ ] Disk-Space: Genug Platz? Monitoring?
- [ ] Reverse Proxy: Traefik/nginx/Caddy konfiguriert?
- [ ] SSL/TLS: Let's Encrypt? Automatische Erneuerung?

### 4. Monitoring & Alerting

- [ ] Uptime-Monitoring: Seite/API wird regelmaessig geprueft?
- [ ] Log-Aggregation: Zentrales Logging?
- [ ] Metriken: CPU, RAM, Disk ueberwacht?
- [ ] Alerting: Benachrichtigung bei Ausfall?
- [ ] Error-Tracking: Sentry, LogRocket o.ae.?
- [ ] Health-Check Endpoint: `/health` oder `/status`?

### 5. Rollback-Strategie

- [ ] Rollback moeglich? Wie schnell?
- [ ] Vorherige Version jederzeit deploybar?
- [ ] Datenbank-Rollback: Migrations rueckwaerts moeglich?
- [ ] Blue/Green oder Canary Deployment?
- [ ] Rollback dokumentiert und getestet?

### 6. Skalierung

- [ ] Horizontal skalierbar? (mehrere Instanzen)
- [ ] Stateless Design? (kein lokaler Session-State)
- [ ] Load Balancing konfiguriert? (falls mehrere Instanzen)
- [ ] Auto-Scaling Regeln? (falls Cloud)
- [ ] Resource Limits definiert? (CPU, RAM pro Container)

### 7. Environment-Management

- [ ] Environments getrennt? (Dev, Staging, Prod)
- [ ] Config pro Environment? (nicht hardcodiert)
- [ ] Prod-Daten nie in Dev/Staging?
- [ ] Feature-Flags: Kontrolliertes Rollout?

---

## Ergebnis

Findings als DEPLOY-01, DEPLOY-02, ... dokumentieren.
Kein Rollback moeglich: HIGH. Fehlendes Monitoring: HIGH. Kein Health-Check: MEDIUM.
