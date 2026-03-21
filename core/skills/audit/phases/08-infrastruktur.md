# Phase 08: Infrastruktur

Server, Docker, Reverse Proxy, Backup — alles was die Seite am Laufen haelt.
Finding-Prefix: `INFRA`

Hinweis: Diese Phase benoetigt SSH-Zugang zu den Servern.
Wenn kein Server-Zugang verfuegbar → nur Docker/Compose-Dateien lokal pruefen.

**Multi-Server:** Wenn `audit-context.md` mehrere Server definiert, JEDEN Server
separat pruefen. Die audit-context.md enthaelt server-spezifische Pruefpunkte
(z.B. welche Dienste auf welchem Server laufen, spezifische Checks fuer
Monitoring-Tools, Datenbanken, etc.).

---

## Checks

### 1. VPS / Server (SSH erforderlich)

- [ ] OS-Version: Aktuell? LTS? End-of-Life?
- [ ] Updates: `unattended-upgrades` oder aequivalent aktiv?
- [ ] Firewall: UFW/iptables — nur noetige Ports offen (22, 80, 443)?
- [ ] SSH: Key-Only Auth? Root-Login deaktiviert? Port geaendert?
- [ ] fail2ban: Installiert und aktiv?
- [ ] Disk-Platz: Genuegend frei? Monitoring?
- [ ] Swap: Konfiguriert auf kleinen VPS?

### 2. Docker

- [ ] Dockerfile: Multi-Stage Build? Minimales Base-Image?
- [ ] Non-Root User im Container?
- [ ] `.dockerignore`: Vollstaendig? (.git, node_modules, .env, etc.)
- [ ] Health Checks definiert?
- [ ] Ressourcen-Limits: Memory/CPU in docker-compose?
- [ ] Restart Policy: `unless-stopped` oder `always`?
- [ ] Image-Cleanup: Alte Images/Container werden entfernt?
- [ ] Secrets: Nicht in Image-Layers? `.env` nur per Environment-Variable?
- [ ] Trivy/Scout Scan: Keine bekannten Vulnerabilities im Image?

### 3. Docker Compose

- [ ] Services klar benannt und strukturiert?
- [ ] Netzwerke: Intern separiert? Nicht alles im Default-Netzwerk?
- [ ] Volumes: Persistente Daten korrekt gemountet?
- [ ] Logging: Log-Rotation konfiguriert? (json-file mit max-size)
- [ ] Watchtower / Auto-Update: Konfiguriert? Nur fuer eigene Images?

### 4. Reverse Proxy (Traefik/nginx)

- [ ] TLS: Let's Encrypt? Auto-Renewal?
- [ ] TLS-Version: Mindestens 1.2?
- [ ] Redirect: HTTP → HTTPS erzwungen?
- [ ] Headers: Security-Headers ueber Proxy konfiguriert?
- [ ] Rate Limiting: Konfiguriert?
- [ ] Compression: gzip/brotli aktiviert?
- [ ] Access Logs: Aktiviert und rotiert?

### 5. Backup & Recovery

- [ ] Backup-Strategie: Was wird gesichert? (DB, Uploads, Config)
- [ ] Backup-Frequenz: Taeglich? Woechentlich?
- [ ] Backup-Speicherort: Nicht auf demselben Server!
- [ ] Restore getestet? Wann zuletzt?
- [ ] Hetzner Snapshots: Aktiviert? Frequenz?
- [ ] Docker Volumes: Separat gesichert?

### 6. Monitoring

- [ ] Uptime Monitoring: Konfiguriert? (Uptime Kuma, Hetrix, etc.)
- [ ] Alerting: Benachrichtigungen bei Ausfall?
- [ ] Container-Health: Werden Container-Neustarts bemerkt?
- [ ] SSL-Ablauf: Monitoring fuer Zertifikats-Erneuerung?
- [ ] Disk/CPU/RAM: Monitoring vorhanden?

---

## Ergebnis

Findings als INFRA-01, INFRA-02, ... dokumentieren.
Offener DB-Port: CRITICAL. Kein Backup: CRITICAL. Root-Login via SSH: HIGH.
