# Stack-Supplement: nginx

nginx-spezifische Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.

---

## §IST-Analyse

- [ ] nginx-Version: `nginx -v` oder Dockerfile — aktuell?
- [ ] Config-Dateien: `nginx.conf` oder `default.conf`? Aufbau klar?
- [ ] Variante: Offizielles Image? `nginx:alpine`? `nginx-unprivileged`?
- [ ] Server-Blocks: Wie viele? Welche Domains?
- [ ] Upstream-Definitionen: Backend-Server korrekt konfiguriert?

## §Security

- [ ] **TLS:** `ssl_protocols TLSv1.2 TLSv1.3;` (kein TLSv1.0/1.1)
- [ ] **Cipher-Suites:** Moderne Ciphers? (`ssl_prefer_server_ciphers on`)
- [ ] **Security Headers:**
  ```
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-XSS-Protection "0" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  add_header Content-Security-Policy "..." always;
  add_header Permissions-Policy "..." always;
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
  ```
- [ ] **Server-Token:** `server_tokens off;` (Version nicht preisgeben)
- [ ] **Zugriffsbeschraenkung:** Admin-Pfade per `allow`/`deny` oder Basic Auth?
- [ ] **Rate Limiting:** `limit_req_zone` fuer sensible Endpoints?
- [ ] **Upload-Limit:** `client_max_body_size` angemessen?

## §Performance

- [ ] **Compression:** `gzip on;` mit sinnvollen `gzip_types`?
- [ ] **Caching:** Statische Assets mit langem `Cache-Control`?
  ```
  location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2)$ {
      expires 1y;
      add_header Cache-Control "public, immutable";
  }
  ```
- [ ] **HTTP/2:** `listen 443 ssl http2;`? (oder h2 in neueren Versionen)
- [ ] **Keep-Alive:** `keepalive_timeout` sinnvoll? (65s default ok)
- [ ] **Buffer:** `proxy_buffering on;` fuer Upstream?
- [ ] **Open File Cache:** `open_file_cache` fuer statische Seiten?

## §Code-Quality

- [ ] Config klar strukturiert? Includes fuer Wiederverwendung?
- [ ] Keine doppelten Direktiven (ueberschreiben sich)?
- [ ] Error-Seiten: Custom 404/50x konfiguriert?
- [ ] Redirects: 301 fuer permanente, 302 fuer temporaere?
- [ ] Trailing Slash: Konsistent behandelt?

## §Infrastruktur

- [ ] **Logs:** Access + Error Logs konfiguriert? Rotation?
- [ ] **PID/Temp:** Schreibbare Verzeichnisse fuer non-root? (unprivileged Image)
- [ ] **Health Check:** Einfacher Location-Block fuer Docker Health?
- [ ] **Reload:** `nginx -s reload` statt Restart fuer Config-Aenderungen?
- [ ] **Graceful Shutdown:** `worker_shutdown_timeout`?
