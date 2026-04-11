---
name: deploy-check
description: >
  Deployment readiness check for Docker/Traefik projects.
  Use when: "deploy check", "deployment check", "ready for deployment",
  "deploy-check", "before deploy", "production ready".
user-invocable: true
argument-hint: ""
---

<!-- AI-QUICK-REF
## /deploy-check — Quick Reference
- **Modes:** check (all), docker, env, ssl
- **Checks:** Docker Compose, .env completeness, Traefik labels, SSL certs, health endpoint
- **Output:** Checklist with OK/ERROR/WARNING per check
- **Prerequisite:** Docker Compose project with Traefik
-->

# /deploy-check — Deployment Readiness

Checks whether a project is ready for deployment.
Focus on Docker + Traefik stack.

## Modes

| Mode | Argument | Checks |
|------|----------|--------|
| **check** | `/deploy-check` (default) | All 5 checks |
| **docker** | `/deploy-check docker` | Docker Compose only |
| **env** | `/deploy-check env` | .env comparison only |
| **ssl** | `/deploy-check ssl example.com` | SSL cert check only |

## Checks

### 1. Validate Docker Compose

```bash
docker compose config --quiet 2>&1
```

- Find syntax errors in `docker-compose.yml` / `compose.yml`
- Verify service names, ports, volumes
- Finding: `DEPLOY-01: Docker Compose syntax error`

### 1b. Docker Engine Version

```bash
docker version --format '{{.Server.Version}}' 2>/dev/null
```

- Minimum: 29.3.1 (CVE-2026-34040 fix: AuthZ plugin bypass via >1MB request body, CVSS 8.8)
- Finding: `DEPLOY-01b: Docker Engine {version} < 29.3.1 — critical security vulnerability`

### 2. Environment Comparison

Compare `.env.example` with `.env` (or `.env.production`):
- Missing variables in `.env` that exist in `.env.example`
- Empty values for required variables (DB credentials, secrets)
- Variables in `.env` not documented in `.env.example`
- Finding: `DEPLOY-02: Variable {NAME} missing in .env`
- Finding: `DEPLOY-03: Variable {NAME} is empty`

### 3. Traefik Labels

Check in `docker-compose.yml`:
- `traefik.enable=true` present
- `traefik.http.routers.*.rule=Host(...)` set
- `traefik.http.routers.*.tls.certresolver` set (Let's Encrypt)
- `traefik.http.routers.*.entrypoints=websecure` (HTTPS)
- Finding: `DEPLOY-04: Traefik label {label} missing`

### 4. SSL Cert Expiry

Only when domain is provided or readable from Traefik labels:

```bash
echo | openssl s_client -servername DOMAIN -connect DOMAIN:443 2>/dev/null | openssl x509 -noout -dates
```

- Check expiry date (>30 days: OK, 7-30: WARNING, <7: ERROR)
- Finding: `DEPLOY-05: SSL cert for {DOMAIN} expires in {N} days`

### 5. Health Endpoint

Only when domain/URL is provided or derivable from Compose:

```bash
curl -sf -o /dev/null -w "%{http_code}" https://DOMAIN/health
```

- HTTP 200: OK
- Other status or timeout: WARNING
- Finding: `DEPLOY-06: Health endpoint responds with {STATUS}`

## Output Format

```
## Deploy Check: [Project Name]

### 1. Docker Compose
   OK: Syntax valid, 3 services defined

### 2. Environment
   WARNING: 2 missing variables
   - DEPLOY-02: DATABASE_URL missing in .env
   - DEPLOY-03: JWT_SECRET is empty

### 3. Traefik Labels
   OK: Host, TLS, entrypoints configured

### 4. SSL Cert
   OK: Valid until 2026-06-15 (93 days)

### 5. Health Endpoint
   OK: HTTP 200 in 120ms

---
Result: 5 checks, 3 OK, 1 WARNING, 1 ERROR
Recommendation: Set missing .env variables before deploy
```

### 6. AI Act Compliance (Conditional)

Only for projects that deploy or integrate AI models/agents:

- GPAI provider obligations (transparency, documentation, copyright compliance)
- High-risk AI system classification check
- AI content labeling requirements (extended to Feb 2027)
- Finding: `DEPLOY-07: AI component detected but no AI Act compliance documentation`

**Context:** EU AI Act GPAI enforcement powers effective August 2, 2026.
Fines up to EUR 15M or 3% of global turnover (Art. 101).

### 7. DSA Platform Obligations (Conditional)

Only for platforms with user-generated content or advertising:

- Age verification measures for restricted content
- Advertising repository transparency
- Researcher data access provisions
- Minor protection measures
- Finding: `DEPLOY-08: UGC platform without DSA compliance measures`

**Context:** DSA enforcement 2026. First fine: EUR 120M (X). Focus: age verification, minor protection.

## Rules

- **Read-only** — does not modify any files
- Works even without a running Docker daemon (config check)
- SSL/health check only when domain is reachable
- If `docker compose` is unavailable: file-based checks only
- AI Act / DSA checks only triggered when project type warrants it
