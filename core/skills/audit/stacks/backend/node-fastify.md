# Stack-Supplement: Node.js + Fastify

Fastify-spezifische Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.

---

## §IST-Analyse

- [ ] Fastify-Version: package.json pruefen (context7 fuer aktuelle Version)
- [ ] Plugin-Registrierung: Welche Plugins? (`@fastify/cors`, `@fastify/rate-limit`, etc.)
- [ ] Route-Inventar: Alle Endpoints auflisten (REST-Konventionen?)
- [ ] Datenbank-Anbindung: Welche DB? Connection-Setup?
- [ ] Queue/Worker: Background-Jobs vorhanden? Welches System?
- [ ] Email: Versand-System? Failover-Strategie?
- [ ] Tests: Framework (Vitest, Jest)? Coverage?
- [ ] TypeScript oder Plain JS?

## §Security

- [ ] `@fastify/cors`: Origins explizit? Kein Wildcard `*` bei Credentials?
- [ ] `@fastify/rate-limit`: Auf sensiblen Routen? (Login, Forms, API)
- [ ] `@fastify/helmet`: Security-Headers automatisch?
- [ ] Input-Validierung: JSON Schema auf allen Routen? (Fastify built-in)
- [ ] File Upload: Magic-Byte-Check? Groessenlimit? MIME-Type-Validierung?
- [ ] Spam-Schutz: Captcha/Turnstile? Honeypot-Felder?
- [ ] Auth: Wie implementiert? JWT-Expiry? Token-Rotation?
- [ ] Error-Responses: Keine Stack-Traces in Production? `fastify.setErrorHandler`?
- [ ] Graceful Shutdown: `fastify.close()` bei SIGTERM?

## §Performance

- [ ] Fastify-Logging: Level in Production? (warn/error, nicht debug)
- [ ] Serialization: `@fastify/response-validation` oder JSON-Schema fuer Responses?
- [ ] Connection Pooling: DB-Connections wiederverwendet?
- [ ] Caching: Responses gecacht wo sinnvoll? (ETags, Cache-Control)
- [ ] Payload-Limits: `bodyLimit` konfiguriert?

## §Code-Quality

- [ ] Plugin-Architektur: Korrekte Nutzung von `fastify-plugin` und `encapsulation`?
- [ ] Decorators: Sinnvoll genutzt? Typisiert?
- [ ] Hooks: `onRequest`, `preHandler` — klar strukturiert?
- [ ] Error Handling: Zentral per `setErrorHandler`? Nicht in jeder Route?
- [ ] Tests: Fastify `inject()` fuer Route-Tests genutzt?
- [ ] Keine synchronen Operationen im Request-Pfad?

## §DSGVO

- [ ] Logging: Keine personenbezogenen Daten in Logs? (IP-Anonymisierung)
- [ ] Daten-Retention: Auto-Loeschung nach definierter Frist?
- [ ] Email-Inhalte: Werden Formular-Daten in der DB gespeichert? Wie lange?
- [ ] AV-Vertrag: Bei externen Email-Diensten (Brevo, SendGrid)?

## §Infrastruktur

- [ ] Dockerfile: Multi-Stage Build? Node-User (non-root)?
- [ ] Health-Endpoint: `/health` oder `/readyz` definiert?
- [ ] Docker: Container-Restart bei Crash?
- [ ] Logs: Structured Logging (JSON)? Log-Rotation?
- [ ] Monitoring: Metriken-Endpoint? Prometheus-kompatibel?
