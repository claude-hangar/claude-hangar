# Stack-Supplement: Docker

Docker-spezifische Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.

---

## §IST-Analyse

- [ ] Dockerfile(s): Welche vorhanden? Multi-Stage?
- [ ] docker-compose.yml: Services, Netzwerke, Volumes
- [ ] Base Images: Welche? Version-Tags? (Alpine bevorzugt)
- [ ] .dockerignore: Vorhanden und vollstaendig?
- [ ] Image-Groesse: `docker image ls` — aufgeblaeht?

## §Security

- [ ] **Non-Root User:** `USER` Direktive im Dockerfile? Nicht als root laufen!
- [ ] **Secrets:** Keine Secrets in Dockerfile/docker-compose.yml (ENV, ARG, COPY .env)
- [ ] **Build-Secrets:** `--mount=type=secret` fuer Build-Time-Secrets?
- [ ] **Image-Scanning:** `docker scout` oder `trivy` — bekannte CVEs?
- [ ] **Read-Only Filesystem:** `read_only: true` in Compose wo moeglich?
- [ ] **Capabilities:** `cap_drop: ALL` + nur noetige zurueck? (`NET_BIND_SERVICE`)
- [ ] **No-New-Privileges:** `security_opt: no-new-privileges:true`?
- [ ] **Pinned Versions:** Base-Image mit Digest oder konkretem Tag (nicht `:latest`)?
- [ ] **Netzwerk-Isolation:** Services in separaten Netzwerken? Kein Default-Bridge?
- [ ] **Exposed Ports:** Nur noetige Ports? Nicht `0.0.0.0:PORT` wenn nur intern?

## §Performance

- [ ] Multi-Stage Build: Build-Dependencies nicht im finalen Image?
- [ ] Layer-Caching: `COPY package*.json` vor `COPY . .`?
- [ ] Alpine-Images: Kleiner, schneller Pull
- [ ] Health Checks: Schnell und leichtgewichtig? (kein curl wenn wget reicht)
- [ ] Ressourcen-Limits: `mem_limit`, `cpus` in docker-compose?

## §Code-Quality

- [ ] Dockerfile Best Practices:
  - `COPY` statt `ADD` (ausser fuer tar/URL)
  - Ein `RUN` Befehl pro logische Einheit (Layer minimieren)
  - `WORKDIR` statt `cd`
  - `ENTRYPOINT` + `CMD` korrekt kombiniert?
- [ ] docker-compose: Version 3.x Syntax? Services klar benannt?
- [ ] Labels: Maintainer, Version, Description? (OCI-Standard)

## §Infrastruktur

- [ ] Restart Policy: `unless-stopped` oder `always`?
- [ ] Log-Rotation: `logging.driver: json-file` mit `max-size` / `max-file`?
- [ ] Volumes: Persistente Daten korrekt gemountet? Named Volumes?
- [ ] Image-Cleanup: Alte Images/Container regemaessig entfernt?
- [ ] Watchtower: Konfiguriert fuer Auto-Updates? Nur eigene Images?
- [ ] Compose-Profiles: Fuer Dev vs. Prod unterschiedliche Konfiguration?
- [ ] Backup: Docker Volumes gesichert?
