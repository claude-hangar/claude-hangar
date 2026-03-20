---
name: auth-audit
description: >
  Custom auth security audit (bcryptjs + sessions, no OAuth/external provider).
  Use when: "auth-audit", "auth check", "auth security", "login audit", "session audit", "password audit".
---

<!-- AI-QUICK-REF
## /auth-audit — Quick Reference
- **Modes:** start | continue | status | report | auto
- **Auto-Detection:** package.json (bcryptjs, argon2, jose), session handling, hooks.server.ts, middleware/guards
- **Focus:** Custom auth — bcryptjs + sessions. No NextAuth/Lucia/Auth.js/OAuth
- **State:** .auth-audit-state.json (v2.1)
- **Finding IDs:** AUTH-NN
- **Areas:** HASH, SESS, CSRF, COOK, REG, LOGIN, RESET, AUTHZ, STORE, LOG
- **Checkpoints:** [CHECKPOINT: decision] at framework detection, [CHECKPOINT: verify] after each area
- **OWASP Reference:** ASVS v4.0.3 — V2 (Authentication), V3 (Session Management)
- **Complementary to /audit** — this skill only checks auth-specific topics
-->

# /auth-audit — Custom Auth Security Audit

Security audit for custom auth implementations with bcryptjs/argon2 + session-based authentication. Checks against OWASP ASVS v4.0.3 (V2: Authentication, V3: Session Management).

**Scope:** Custom auth — NO NextAuth, Lucia, Auth.js, or external OAuth provider. Focus on self-built registration, login, sessions, password reset.

**Complementary to /audit:** This skill checks auth-specific security. The generic /audit checks code quality, performance, SEO, a11y, etc.

## Modes

Detect the mode from user input:

- **start** -> Mode 1 (Scan project, detect auth stack)
- **continue** -> Mode 2 (Process next areas/fixes)
- **status** -> Mode 3 (Show progress)
- **report** -> Mode 4 (Structured Markdown report)
- **auto** -> Mode 5 (Fully autonomous run)

---

## Mode 1: `/auth-audit start` — Scan Project

### Auto-Detection (in this order)

1. **package.json** -> Auth-relevant dependencies:
   - Hashing: `bcryptjs`, `bcrypt`, `argon2`, `@oslojs/crypto`
   - Tokens: `jose`, `jsonwebtoken`, `paseto`
   - Sessions: `express-session`, `iron-session`, `cookie`, `@sveltejs/kit` (built-in cookies)
   - Validation: `zod`, `valibot` (for auth input)
   - Rate limiting: `rate-limiter-flexible`, `express-rate-limit`
2. **Framework detection:**
   - SvelteKit: `src/hooks.server.ts` with auth logic, `+page.server.ts` with form actions
   - Express/Fastify: Middleware files, route guards
   - Astro: `middleware.ts`, API routes under `src/pages/api/`
3. **Search for auth files:**
   - `**/auth/**`, `**/login/**`, `**/register/**`, `**/session/**`
   - `**/middleware.*`, `**/guard.*`, `**/protect.*`
   - `**/*auth*.*`, `**/*session*.*`, `**/*password*.*`
4. **Database schema:**
   - Drizzle: `schema.ts` / `schema/*.ts` -> Users table, Sessions table
   - Prisma: `schema.prisma` -> User/Session models
   - Raw SQL: `*.sql` migration files
5. **Environment:**
   - `.env`, `.env.example` -> Auth-relevant secrets (SESSION_SECRET, JWT_SECRET, etc.)

### Flow After Detection

1. Display result table: Framework, hashing lib, session type, DB schema, rate limiter
2. [CHECKPOINT: decision] Confirm framework + auth approach
3. Prioritize areas by severity order (max 2 per session)
4. Check each checkpoint against the project (cite OWASP ASVS reference)
5. Save findings to `.auth-audit-state.json`
6. Display summary + prioritized list
7. Session end: "Start next session with `/auth-audit continue`"

---

## Mode 2: `/auth-audit continue` — Resume

1. Read `.auth-audit-state.json`
2. **Generate smart recommendation:**
   ```
   IF open CRITICAL findings > 0:
     -> "Recommendation: Fix {N} CRITICAL findings first ({IDs})"
   IF open HIGH findings > 3:
     -> "Recommendation: Fix HIGH findings, then continue"
   ELSE IF areas open:
     -> "Recommendation: Next areas ({area names})"
   ELSE:
     -> "Recommendation: Fix remaining findings"
   ```
3. If areas open -> process next 2 areas
4. If all areas done -> next 5 findings by priority
5. **Load fix templates** (from `fix-templates.md`) where applicable
6. Ask user: Follow recommendation? Choose different? Skip?
7. Implement fixes -> verify -> update state

---

## Mode 3: `/auth-audit status` — Progress

1. Read `.auth-audit-state.json`
2. Display table: Done/Open/Total per area + severity
3. Show OWASP coverage (V2/V3 sections)
4. Next recommended action

---

## Mode 4: `/auth-audit report` — Markdown Report

Generate a structured Markdown report.

1. Read state file
2. Group all findings by area
3. Report with executive summary, findings per area, OWASP coverage, recommendations
4. **Insert trend analysis** (if history available):
   ```
   Trend (recent audits):
     CRITICAL: 3 -> 1 -> 0  (resolved)
     HIGH:     5 -> 3 -> 2  (declining)
     Total:   12 -> 8 -> 5
   Assessment: Project is steadily improving.
   ```
5. Save report as `AUTH-AUDIT-REPORT-{YYYY-MM-DD}.md` in project root
6. If previous reports exist: Diff section (new/resolved since last report)

---

## Mode 5: `/auth-audit auto` — Autonomous Run

Fully autonomous auth audit without prompts.

### Flow

1. Auto-detection as in `start`
2. **All areas** processed (no 2-area limitation)
3. Document findings with fix templates from `fix-templates.md`
4. **Context management:** When context runs low:
   - Write state immediately
   - Create task in `.tasks.json` with handoff note
   - "New session with `/auth-audit continue`"
5. At end: Summary with prioritized fix list

### Severity Order of Areas in Auto Mode

CRITICAL areas first:
`HASH -> SESS -> CSRF -> COOK -> STORE -> LOGIN -> REG -> RESET -> AUTHZ -> LOG`

---

## Areas

### HASH — Password Hashing
**OWASP ASVS:** V2.4 (Credential Storage)

| Check | Priority | Description |
|-------|----------|-------------|
| Hashing algorithm | [MUST] | bcryptjs or argon2 (NOT md5, sha256, scrypt without config) |
| bcrypt rounds | [MUST] | Minimum 10 rounds, recommended 12 (ASVS 2.4.4) |
| Salt handling | [MUST] | bcryptjs.genSalt() or auto-salt via bcryptjs.hash(pw, rounds) |
| Timing-safe compare | [MUST] | Use bcryptjs.compare(), NEVER `===` on hashes |
| Pepper | [CAN] | HMAC pepper before hashing (server-side secret) |

### SESS — Session Management
**OWASP ASVS:** V3.1-V3.7 (Session Management)

| Check | Priority | Description |
|-------|----------|-------------|
| Session ID entropy | [MUST] | Min. 128-bit random value (crypto.randomUUID or @oslojs/crypto) |
| Session expiry | [MUST] | Absolute + idle timeout set (ASVS 3.3.1) |
| Session rotation | [MUST] | New session ID after login (ASVS 3.3.2 — session fixation prevention) |
| Session invalidation | [MUST] | Logout deletes server-side + cookie (ASVS 3.3.1) |
| Server-side storage | [MUST] | Sessions in DB, not client-cookie only (ASVS 3.2.1) |
| Concurrent sessions | [SHOULD] | Limit or display of active sessions |

### CSRF — CSRF Protection
**OWASP ASVS:** V4.2.2 (Anti-CSRF)

| Check | Priority | Description |
|-------|----------|-------------|
| SvelteKit origin check | [MUST] | Automatically active — NOT disabled (`csrf.checkOrigin: false`) |
| State-changing GET | [MUST] | No state changes via GET requests |
| Custom token | [SHOULD] | Double-submit cookie or synchronizer token for APIs |
| Fetch requests | [SHOULD] | Custom header (X-Requested-With) on AJAX calls |

### COOK — Cookie Security
**OWASP ASVS:** V3.4 (Cookie-based Session Management)

| Check | Priority | Description |
|-------|----------|-------------|
| httpOnly | [MUST] | Session cookie httpOnly: true (ASVS 3.4.2) |
| secure | [MUST] | secure: true in production (ASVS 3.4.1) |
| sameSite | [MUST] | sameSite: 'lax' or 'strict' (ASVS 3.4.3) |
| path | [SHOULD] | path: '/' (or more restrictive) |
| maxAge | [MUST] | Reasonable maxAge set (not unlimited) |
| domain | [SHOULD] | Explicitly set, not too broad |
| Cookie name | [CAN] | No default name (session_id instead of connect.sid) |

### REG — Registration Flow
**OWASP ASVS:** V2.1 (Password Security)

| Check | Priority | Description |
|-------|----------|-------------|
| Email validation | [MUST] | Server-side validation (not client-only) |
| Password policy | [MUST] | Min. 8 chars, no max limit under 64 (ASVS 2.1.1) |
| Password strength | [SHOULD] | Breached-password check or zxcvbn approach (ASVS 2.1.7) |
| Rate limiting | [MUST] | Registration endpoint rate-limited (ASVS 2.2.1) |
| Email uniqueness | [MUST] | Case-insensitive unique check (toLowerCase()) |
| Duplicate handling | [SHOULD] | No information disclosure ("email already registered") |

### LOGIN — Login Flow
**OWASP ASVS:** V2.2 (General Authenticator Security)

| Check | Priority | Description |
|-------|----------|-------------|
| Generic error | [MUST] | Same message for wrong user/password (ASVS 2.2.1) |
| Brute-force protection | [MUST] | Rate limiting on login endpoint (ASVS 2.2.1) |
| Account lockout | [SHOULD] | Progressive delays or temporary lock (ASVS 2.2.3) |
| Timing attacks | [MUST] | Same response time for existing/non-existing user |
| Secure transport | [MUST] | Login only over HTTPS (ASVS 2.1.6) |
| Post-login redirect | [SHOULD] | Open redirect prevention on redirect URLs |

### RESET — Password Reset
**OWASP ASVS:** V2.5 (Credential Recovery)

| Check | Priority | Description |
|-------|----------|-------------|
| Token entropy | [MUST] | Min. 128-bit cryptographically secure token (ASVS 2.5.6) |
| Token expiry | [MUST] | Max. 1 hour valid (ASVS 2.5.2) |
| One-time use | [MUST] | Token invalidated immediately after use |
| Secure delivery | [MUST] | Token only via email, not in URL response |
| Rate limiting | [SHOULD] | Reset request rate-limited |
| No user enumeration | [MUST] | Same response regardless of whether email exists (ASVS 2.5.1) |

### AUTHZ — Authorization
**OWASP ASVS:** V4.1-V4.3 (Access Control)

| Check | Priority | Description |
|-------|----------|-------------|
| Route guards | [MUST] | All protected routes have auth check (ASVS 4.1.1) |
| Role-based access | [SHOULD] | Role check on admin/moderator routes |
| API protection | [MUST] | API endpoints authenticated (not just frontend routes) |
| IDOR prevention | [MUST] | Object access checked against user ownership (ASVS 4.2.1) |
| Default deny | [MUST] | New routes are protected by default |
| Privilege escalation | [SHOULD] | Role cannot be changed client-side |

### STORE — Credential Storage
**OWASP ASVS:** V2.4 (Credential Storage), V6.4 (Secret Management)

| Check | Priority | Description |
|-------|----------|-------------|
| No plaintext | [MUST] | Passwords NEVER stored in plaintext (ASVS 2.4.1) |
| DB schema | [MUST] | Password field sufficiently long (VARCHAR(255) for bcrypt) |
| Env secrets | [MUST] | SESSION_SECRET, DB credentials in .env, not in code |
| .env in .gitignore | [MUST] | .env NOT in repository |
| Secret rotation | [SHOULD] | Documented process for secret rotation |
| Backup security | [CAN] | DB backups encrypted |

### LOG — Auth Logging
**OWASP ASVS:** V7.1-V7.2 (Logging)

| Check | Priority | Description |
|-------|----------|-------------|
| Failed login attempts | [SHOULD] | Log failed logins with timestamp + IP |
| Session creation | [SHOULD] | Log new sessions (user ID, timestamp) |
| Privilege changes | [SHOULD] | Log role changes (ASVS 7.1.1) |
| Password changes | [SHOULD] | Log password changes (without the password!) |
| No sensitive data | [MUST] | NO passwords/tokens in logs (ASVS 7.1.2) |
| Log injection | [SHOULD] | User input in logs sanitized |

---

## Check Priorities + Completeness Tracking

> See `_shared/audit-patterns.md` (MUST/SHOULD/CAN markers, completeness counting, layer status standard).
Area with <100% MUST checks cannot be marked as `done`.

---

## Severity Definitions

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Direct auth bypass, data exfiltration possible | Plaintext passwords, missing CSRF protection, session fixation, broken authentication |
| **HIGH** | Significant weakness, exploitation realistic | bcrypt rounds <10, missing rate limiting, insecure cookies (no httpOnly/secure) |
| **MEDIUM** | Best-practice deviation, indirect risk | Missing account lockout, no session rotation, weak password policy |
| **LOW** | Nice-to-have, minimal risk | Missing auth logging, no "remember me" security, UX improvements |

---

## State Schema v2.1 (.auth-audit-state.json)

-> Full state schema (JSON example) + migration v1->v2.1: See **state-schema.md**

---

## Rules

- **Context protection:** Max 2 areas OR 5 fixes per session. At limit: save state, recommend `/auth-audit continue`.
- **Write state immediately:** Update `.auth-audit-state.json` after every area and every fix.
- **No auto-fix:** Document findings, then ask user whether to fix.
- **Severity rules:** See severity definitions above.
- **Finding prefix:** Always `AUTH-NN`, sequentially numbered.
- **Fix templates:** Load matching template from `fix-templates.md` for findings.
- **OWASP reference:** Cite the ASVS section for every finding.
- **No external auth:** NextAuth, Lucia, Auth.js, Supabase Auth are OUT OF SCOPE. If detected: inform user, end skill.
- **Security first:** All defaults in fix templates must be secure. No insecure examples without warning.

---

## Session Strategy

| Session | Content | Context Protection |
|---------|---------|-------------------|
| 1 | start -> Detection + 2 areas (CRITICAL first: HASH, SESS) | Max 2 areas |
| 2 | continue -> next 2 areas (CSRF, COOK) | Max 2 areas |
| 3 | continue -> next 2 areas (LOGIN, REG) | Max 2 areas |
| 4 | continue -> next 2 areas (RESET, AUTHZ) | Max 2 areas |
| 5 | continue -> last 2 areas (STORE, LOG) | Max 2 areas |
| 6+ | continue -> Fixes (max 5/session) | Fix -> Test -> Next |

---

## Smart Next Steps

After completing the auth audit, recommend relevant follow-up skills:

| Condition | Recommendation | Reason |
|-----------|---------------|--------|
| DB schema findings present | `/db-audit start` | Check database schema and queries |
| SvelteKit project detected | `/sveltekit-audit start` | Check SvelteKit-specific patterns |
| No .audit-state.json present | `/audit start` | Check general website quality |
| No .project-audit-state.json present | `/project-audit start` | Check code/CI/CD quality |
| All areas done | `/lesson-learned session` | Extract learnings from auth audit |

**Output after last area:** "Next steps:" + 2-3 most relevant recommendations.

---

## Additional Files

- `fix-templates.md` — Quick-fix templates for common auth findings
- `state-schema.md` — State schema v2.1 + migration v1->v2.1

As of: 2026-03-20 (State schema v2.1 migration)
