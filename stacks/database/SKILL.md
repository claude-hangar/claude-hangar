---
name: db-audit
description: >
  Database audit for Drizzle ORM + PostgreSQL with state persistence.
  Use when: "db-audit", "database audit", "drizzle check", "db check", "schema audit", "migration check", "postgresql audit".
user_invocable: true
argument_hint: "start|continue"
---

<!-- AI-QUICK-REF
## /db-audit — Quick Reference
- **Modes:** start | continue | status | report | refresh | auto
- **Auto-Detection:** package.json (drizzle-orm, pg, postgres), drizzle.config, db/ directory, Docker PostgreSQL, .env DATABASE_URL
- **Focus:** Drizzle ORM + PostgreSQL (extensible for other ORMs/DBs)
- **State:** .db-audit-state.json (v2.1)
- **Finding IDs:** DB-NN
- **Checkpoints:** [CHECKPOINT: decision] at setup detection, [CHECKPOINT: verify] after each area
- **Complementary to /audit and /project-audit** — this skill only checks DB-specific topics
-->

# /db-audit — Database Audit (Drizzle ORM + PostgreSQL)

Skill for database projects focused on Drizzle ORM and PostgreSQL. Automatically detects the DB configuration, checks schema design, migrations, connection setup, security, and performance. Patterns are general enough for other ORMs/DBs, but checks and templates are PostgreSQL-optimized.

**Complementary to /audit and /project-audit:** This skill checks exclusively database-specific topics. Generic code quality, SEO, a11y, etc. belong to /audit or /project-audit.

## Modes

Detect the mode from user input:

- **start** -> Mode 1 (Scan project, identify areas)
- **continue** -> Mode 2 (Process next areas/fixes)
- **status** -> Mode 3 (Show progress)
- **report** -> Mode 4 (Structured Markdown report)
- **refresh** -> Mode 5 (Check for new Drizzle/PostgreSQL releases)
- **auto** -> Mode 6 (Fully autonomous run)

---

## Mode 1: `/db-audit start` — Scan Project

### Auto-Detection (in this order)

1. **package.json** -> `drizzle-orm`, `drizzle-kit`, `pg`, `postgres`, `@neondatabase/serverless`, other DB packages
2. **drizzle.config.ts/js** -> Dialect, schema path, migrations directory, connection config
3. **Schema directory** -> `src/lib/server/db/`, `src/db/`, `db/`, `src/schema/` — tables, relations, enums
4. **Docker Compose** -> PostgreSQL service, volumes, health checks, env variables
5. **.env / .env.example** -> `DATABASE_URL` pattern, credentials handling
6. **Framework integration** -> SvelteKit (`$lib/server/db`), Astro (server endpoints), Next.js (server actions)

### Version Check

After detection:

1. Read installed Drizzle version from `package.json`
2. Check latest version: `npm view drizzle-orm version` + `npm view drizzle-kit version`
3. Determine PostgreSQL version (Docker image, managed service, or `psql --version`)
4. Display result table

### Flow After Detection

1. Display result table: Drizzle version, PostgreSQL version, framework, schema path, connection type
2. Prioritize areas by relevance (max 2 per session)
3. Check each checkpoint against the project
4. Save findings to `.db-audit-state.json`
5. Display summary + prioritized list
6. Session end: "Start next session with `/db-audit continue`"

---

## Mode 2: `/db-audit continue` — Resume

1. Read `.db-audit-state.json`
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

## Mode 3: `/db-audit status` — Progress

1. Read `.db-audit-state.json`
2. Display table: Done/Open/Total per area + severity
3. Next recommended action

---

## Mode 4: `/db-audit report` — Markdown Report

Generate a structured Markdown report.

1. Read state file
2. Group all findings by area
3. Report with executive summary, findings per area, recommendations
4. **Insert trend analysis** (if history available):
   ```
   Trend (recent audits):
     CRITICAL: 3 -> 1 -> 0  (resolved)
     HIGH:     5 -> 3 -> 2  (declining)
     Total:   12 -> 8 -> 5
   Assessment: Project is steadily improving.
   ```
5. Save report as `DB-AUDIT-REPORT-{YYYY-MM-DD}.md` in project root
6. If previous reports exist: Diff section (new/resolved since last report)

---

## Mode 5: `/db-audit refresh` — Check New Releases

1. `npm view drizzle-orm version` + `npm view drizzle-kit version` -> latest version
2. If newer version than in state: check release notes via context7 or WebSearch
3. **Show delta:**
   ```
   Last checked: drizzle-orm 0.38.x / drizzle-kit 0.30.x
   Current:      drizzle-orm 0.39.x / drizzle-kit 0.31.x
   New changes:  Breaking changes, new features
   -> Schema/migration review recommended
   ```
4. Check PostgreSQL major version updates (Docker Hub tags)
5. Inform user + recommendation

---

## Mode 6: `/db-audit auto` — Autonomous Run

Fully autonomous DB audit without prompts.

### Flow

1. Auto-detection as in `start`
2. **All areas** processed (no 2-area limitation)
3. Document findings with fix templates from `fix-templates.md`
4. **Context management:** When context runs low:
   - Write state immediately
   - Create task in `.tasks.json` with handoff note
   - "New session with `/db-audit continue`"
5. At end: Summary with prioritized fix list

### Severity Order of Areas in Auto Mode

CRITICAL areas first:
`ENV -> SCHEMA -> SEC -> CONN -> MIG -> QUERY -> PERF -> BAK -> INT -> TOOL`

---

## Areas

| Code | Area | Description |
|------|------|-------------|
| **ENV** | Environment | PostgreSQL version, connection string, Docker vs managed, .env setup |
| **SCHEMA** | Schema Design | Drizzle tables, relations, constraints, enums, naming |
| **MIG** | Migrations | drizzle-kit generate, push, migrate, migration history |
| **CONN** | Connection | Pool setup (pg Pool), connection limits, idle timeout, SSL |
| **QUERY** | Query Patterns | Select, insert, prepared statements, transactions, type safety |
| **SEC** | Security | Roles, permissions, row-level security, SSL, credential handling |
| **PERF** | Performance | Indexes, EXPLAIN ANALYZE, N+1 queries, pagination, query optimization |
| **BAK** | Backup | pg_dump, point-in-time recovery, Docker volumes, restore tests |
| **TOOL** | Tooling | drizzle-kit studio, pgAdmin, DB monitoring, health checks |
| **INT** | Integration | Framework-specific (SvelteKit server-only, Astro endpoints, env handling) |

---

## Check Priorities + Completeness Tracking

> See `_shared/audit-patterns.md` (MUST/SHOULD/CAN markers, completeness counting, layer status standard).
Area with <100% MUST checks cannot be marked as `done`.

---

## Area Details

### ENV — Environment

**[MUST]** Determine PostgreSQL version (Docker image tag, managed service, or psql)
**[MUST]** DATABASE_URL in .env/.env.example present (not hardcoded in code)
**[MUST]** Credentials NOT in repository (no .env in Git)
**[SHOULD]** .env.example with placeholders present
**[SHOULD]** Docker Compose health check for PostgreSQL
**[CAN]** Separate DB for development/testing/production

### SCHEMA — Schema Design

**[MUST]** All tables with primary key (serial/uuid)
**[MUST]** Foreign keys defined for relations
**[MUST]** NOT NULL constraints where semantically required
**[MUST]** Timestamps (createdAt, updatedAt) on relevant tables
**[SHOULD]** Drizzle relations defined (not just FK columns)
**[SHOULD]** Consistent naming convention (snake_case for DB, camelCase for TypeScript)
**[SHOULD]** Enums via pgEnum instead of string columns
**[SHOULD]** Schema split into separate files (per domain/feature)
**[CAN]** CHECK constraints for value range validation
**[CAN]** Composite indexes for frequent WHERE combinations

### MIG — Migrations

**[MUST]** Migration strategy defined (generate+migrate vs push)
**[MUST]** Migrations directory exists and is in Git
**[MUST]** drizzle.config.ts correctly configured (dialect, schema, out)
**[SHOULD]** Migrations not manually edited after generation
**[SHOULD]** Production uses `migrate()` (not `push`)
**[CAN]** Migration tests or seed data present

### CONN — Connection

**[MUST]** Connection pool configured (not single connections)
**[MUST]** Pool limits set (max connections)
**[SHOULD]** Idle timeout configured
**[SHOULD]** Connection error handling (retry, graceful shutdown)
**[SHOULD]** SSL connection in production
**[CAN]** Connection monitoring/logging

### QUERY — Query Patterns

**[MUST]** No raw SQL with string interpolation (SQL injection risk)
**[MUST]** Prepared statements or Drizzle query builder
**[SHOULD]** Transactions for related operations
**[SHOULD]** Select only needed columns (no `select *` equivalent)
**[SHOULD]** Type-safe queries (use Drizzle infer types)
**[CAN]** Prepared statements for recurring queries

### SEC — Security

**[MUST]** No credentials in source code
**[MUST]** SSL for production connections
**[MUST]** Parameterized queries (no string building)
**[SHOULD]** Separate DB user for app (not postgres superuser)
**[SHOULD]** Least-privilege principle (only required permissions)
**[CAN]** Row-level security for multi-tenant
**[CAN]** Audit logging for critical tables

### PERF — Performance

**[MUST]** Indexes on foreign keys
**[MUST]** Indexes on frequently queried columns (WHERE, ORDER BY)
**[SHOULD]** N+1 query detection (loops with DB calls)
**[SHOULD]** Cursor-based pagination instead of OFFSET/LIMIT for large datasets
**[SHOULD]** EXPLAIN ANALYZE for critical queries
**[CAN]** Partial indexes for filtered queries
**[CAN]** GIN indexes for JSONB columns
**[CAN]** Connection pool sizing based on load

### BAK — Backup

**[MUST]** Backup strategy present (pg_dump or managed backups)
**[MUST]** Docker volumes for persistent data (not container-internal)
**[SHOULD]** Automated backup script
**[SHOULD]** Restore tested
**[CAN]** Point-in-time recovery (WAL archiving)
**[CAN]** Offsite backup

### TOOL — Tooling

**[SHOULD]** drizzle-kit studio or pgAdmin for DB management
**[SHOULD]** Health check endpoint for DB connection
**[CAN]** DB monitoring (pg_stat_statements, Grafana)
**[CAN]** Seed script for development data

### INT — Integration

**[MUST]** DB access server-side only (no DB code in client bundle)
**[MUST]** Environment variables loaded correctly (framework-specific)
**[SHOULD]** DB client as singleton (no connection leak on hot reload)
**[SHOULD]** Graceful shutdown (close pool on server stop)
**[CAN]** Type export for frontend (InferSelectModel without DB import)

---

## Severity Definitions

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Data loss risk, SQL injection, unencrypted credentials | Raw SQL with interpolation, credentials in Git, no backup, container without volume |
| **HIGH** | Missing indexes on hot paths, no backup, connection leaks | Missing FK indexes, no pool limit, no SSL in production |
| **MEDIUM** | Missing constraints, suboptimal schema, no migrations | Missing NOT NULL, no updatedAt, push instead of migrate in prod |
| **LOW** | Nice-to-have indexes, monitoring, documentation | GIN indexes, pg_stat_statements, seed data |

---

## State Schema v2.1 (.db-audit-state.json)

-> Full state schema (JSON example) + migration v1->v2.1: See **state-schema.md**

---

## Rules

- **Context protection:** Max 2 areas OR 5 fixes per session. At limit: save state, recommend `/db-audit continue`.
- **Write state immediately:** Update `.db-audit-state.json` after every area and every fix.
- **No auto-fix:** Document findings, then ask user whether to fix.
- **Severity rules:**
  - CRITICAL: Data loss risk, SQL injection, unencrypted credentials
  - HIGH: Missing indexes on hot paths, no backup, connection leaks
  - MEDIUM: Missing constraints, suboptimal schema, no migrations
  - LOW: Nice-to-have indexes, monitoring, documentation
- **Finding prefix:** Always `DB-NN`, not MIG/SEC like other audit skills.
- **Fix templates:** Load matching template from `fix-templates.md` for findings.
- **npm view:** Run `npm view drizzle-orm version` before any version statement. Never from memory.
- **context7:** Use for Drizzle documentation when available.
- **PostgreSQL focus:** Checks are PostgreSQL-specific. For SQLite/MySQL: inform user, adapt checks.

---

## Session Strategy

| Session | Content | Context Protection |
|---------|---------|-------------------|
| 1 | start -> Detection + 2 areas (CRITICAL first) | Max 2 areas |
| 2 | continue -> next 2 areas | Max 2 areas |
| 3+ | continue -> Fixes (max 5/session) | Fix -> Test -> Next |

---

## Smart Next Steps

After completing the DB audit, recommend relevant follow-up skills:

| Condition | Recommendation | Reason |
|-----------|---------------|--------|
| Auth tables found | `/auth-audit start` | Check auth implementation (bcrypt, sessions, CSRF) |
| SvelteKit project | `/sveltekit-audit start` | Framework-specific checks (load, form actions, hooks) |
| No .project-audit-state.json present | `/project-audit start` | Check code/CI/CD quality |
| No .audit-state.json present | `/audit start` | Check website quality (SEO, a11y, performance, privacy) |
| All areas done | `/lesson-learned session` | Extract learnings from DB audit |

**Output after last area:** "Next steps:" + 2-3 most relevant recommendations.

---

## Additional Files

- `fix-templates.md` — Quick-fix templates for common DB findings
- `state-schema.md` — State schema v2.1 + migration v1->v2.1

As of: 2026-03-20 (State schema v2.1 migration)
