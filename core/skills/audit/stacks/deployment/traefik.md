# Stack-Supplement: Traefik

Traefik Reverse-Proxy-spezifische Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.

---

## §IST-Analyse

- [ ] Traefik-Version: v2 oder v3? (Labels/Config-Syntax unterschiedlich)
- [ ] Konfiguration: Statisch (traefik.yml) + Dynamisch (Docker Labels)?
- [ ] Entrypoints: HTTP (80) und HTTPS (443) definiert?
- [ ] Dashboard: Aktiviert? Geschuetzt? (Nicht oeffentlich erreichbar!)
- [ ] Provider: Docker? File? Kubernetes?
- [ ] Zertifikate: Let's Encrypt? Welcher Resolver? (httpChallenge, tlsChallenge, dnsChallenge)

## §Security

- [ ] **TLS:** Mindestens Version 1.2? (`minVersion: VersionTLS12`)
- [ ] **HTTPS-Redirect:** Entrypoint 80 → 443 erzwungen?
- [ ] **Security Headers Middleware:**
  - `browserXssFilter: true`
  - `contentTypeNosniff: true`
  - `frameDeny: true` oder `customFrameOptionsValue: SAMEORIGIN`
  - `stsIncludeSubdomains: true`
  - `stsSeconds: 31536000`
  - `referrerPolicy: strict-origin-when-cross-origin`
  - `permissionsPolicy` konfiguriert?
- [ ] **Rate Limiting Middleware:** `rateLimit` auf sensiblen Routen?
- [ ] **IP-Whitelist:** Fuer Admin-Bereiche / Staging?
- [ ] **Basic Auth:** Fuer Staging-Umgebungen? (bcrypt-Hash, nicht Klartext)
- [ ] **Dashboard:** `api.insecure: false`? Wenn Dashboard → Basic Auth + IP-Whitelist
- [ ] **Docker Socket:** Traefik hat Zugriff — Read-Only? (`/var/run/docker.sock:ro`)
- [ ] **Access Logs:** Aktiviert? IP-Anonymisierung?

## §Performance

- [ ] **Compression Middleware:** `compress: true`? (gzip/brotli)
- [ ] **Buffering:** `buffering` Middleware fuer grosse Payloads?
- [ ] **Headers:** `Cache-Control` fuer statische Assets per Middleware?
- [ ] **HTTP/2:** Automatisch bei TLS — pruefen ob aktiv

## §Infrastruktur

- [ ] **Zertifikat-Speicher:** `acme.json` persistiert? (Docker Volume)
- [ ] **Zertifikat-Erneuerung:** Let's Encrypt Auto-Renewal funktioniert?
- [ ] **Log-Level:** In Production `ERROR` oder `WARN` (nicht `DEBUG`)
- [ ] **Restart:** Traefik-Container mit `restart: unless-stopped`?
- [ ] **Updates:** Traefik-Version aktuell? Security-Patches?
- [ ] **Monitoring:** Prometheus-Metrics aktiviert? (`metrics.prometheus`)
- [ ] **Fallback:** Was passiert wenn Traefik ausfaellt? (Restart-Policy, Health Check)
