# Stack-Supplement: Docker

Docker-spezifische Projekt-Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.
Erkennung: `Dockerfile` oder `docker-compose.*` vorhanden.

---

## §Struktur

- [ ] Dockerfile(s): Welche vorhanden? Multi-Stage?
- [ ] docker-compose.yml: Services, Netzwerke, Volumes definiert?
- [ ] `.dockerignore`: Vorhanden und vollstaendig?
- [ ] Compose-Profiles: Dev vs. Prod getrennt? (profiles oder Override-Files)
- [ ] Separate Dockerfiles: Fuer verschiedene Services/Stages?
- [ ] Image-Groesse: `docker image ls` — aufgeblaeht?

## §Dependencies

- [ ] Base-Images: Mit konkretem Tag (nicht `:latest`)?
- [ ] Base-Images: Alpine oder Distroless bevorzugt?
- [ ] Docker-Version: `compose` v2 statt `docker-compose` v1?
- [ ] Buildx: Genutzt fuer Multi-Arch Builds?
- [ ] Image-Registry: Wo werden Images gespeichert? (GHCR, Docker Hub, privat)

## §Code

- [ ] Dockerfile Best Practices:
  - `COPY` statt `ADD` (ausser fuer tar/URL)
  - Ein `RUN` Befehl pro logische Einheit (Layer minimieren)
  - `WORKDIR` statt `cd`
  - `ENTRYPOINT` + `CMD` korrekt kombiniert?
- [ ] docker-compose: Services klar benannt?
- [ ] Labels: Maintainer, Version, Description? (OCI-Standard)
- [ ] Layer-Caching: Dependencies vor Source kopieren?
- [ ] Signal-Handling: `exec` Form fuer ENTRYPOINT? (PID 1 Problem)

## §Git

- [ ] `.gitignore`: Docker-Volumes, lokale Override-Files?
- [ ] `.dockerignore`: `.git/`, `node_modules/`, `.env`?
- [ ] docker-compose.override.yml: In `.gitignore`? (lokale Overrides)

## §CICD

- [ ] Docker-Build in CI? (GitHub Actions, GitLab CI)
- [ ] Image-Push: Automatisch bei Merge auf main?
- [ ] Cache: Docker Layer-Cache in CI? (`--cache-from`)
- [ ] Multi-Arch: `linux/amd64` + `linux/arm64`?
- [ ] Image-Scanning in CI? (Trivy, Snyk, Docker Scout)
- [ ] Tag-Strategie: `latest`, SemVer, Git-SHA?

## §Dokumentation

- [ ] Docker-Setup in README dokumentiert?
- [ ] `docker compose up` als Quick-Start?
- [ ] Environment-Variablen: Alle in docker-compose.yml oder .env dokumentiert?
- [ ] Volumes: Was wird persistiert, was nicht?
- [ ] Port-Mapping dokumentiert?

## §Testing

- [ ] Container startet? (`docker compose up` ohne Fehler)
- [ ] Health Checks: Alle Services mit HEALTHCHECK?
- [ ] Integration Tests: Docker-basiert? (testcontainers)
- [ ] Compose-Test: `docker compose config` validiert?
- [ ] Build-Test: `docker build` ohne Warnings?

## §Security

- [ ] **Non-Root User:** `USER` Direktive im Dockerfile?
- [ ] **Secrets:** Keine Secrets in Dockerfile (ENV, ARG, COPY .env)?
- [ ] **Build-Secrets:** `--mount=type=secret` fuer Build-Time-Secrets?
- [ ] **Image-Scanning:** `docker scout` / `trivy` — bekannte CVEs?
- [ ] **Read-Only:** `read_only: true` in Compose wo moeglich?
- [ ] **Capabilities:** `cap_drop: ALL` + nur noetige zurueck?
- [ ] **No-New-Privileges:** `security_opt: no-new-privileges:true`?
- [ ] **Netzwerk-Isolation:** Services in separaten Netzwerken?
- [ ] **Exposed Ports:** Nur noetige? Nicht `0.0.0.0:PORT` wenn nur intern?

## §Deployment

- [ ] Restart Policy: `unless-stopped` oder `always`?
- [ ] Log-Rotation: `logging.driver: json-file` mit `max-size`?
- [ ] Volumes: Persistente Daten korrekt gemountet? Named Volumes?
- [ ] Image-Cleanup: Alte Images/Container regelmaessig entfernt?
- [ ] Watchtower/Diun: Auto-Updates konfiguriert? Nur eigene Images?
- [ ] Reverse Proxy: Traefik/nginx Labels korrekt?
- [ ] Health Checks: Compose + Dockerfile? Restart bei Unhealthy?

## §Maintenance

- [ ] Base-Image Updates: Regelmaessig aktualisiert?
- [ ] Docker-Version: Aktuell? (Docker Engine, Compose)
- [ ] Pruning: `docker system prune` automatisiert?
- [ ] Image-Groesse: Trend ueber Zeit? Wird groesser?
- [ ] Deprecated Compose-Syntax: v2 statt v1?
- [ ] Buildkit: Aktiviert? (DOCKER_BUILDKIT=1)
