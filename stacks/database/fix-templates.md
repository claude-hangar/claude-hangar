# DB Audit: Quick-Fix Templates

Ready-made fix templates for common database findings (Drizzle ORM + PostgreSQL).
For each fix: 1. Show template, 2. User confirmation, 3. Implement, 4. Verify.

---

## SCHEMA — Drizzle Schema Best Practices

### DB: pgTable with Constraints

```typescript
// src/lib/server/db/schema/users.ts
import { pgTable, serial, text, timestamp, boolean, varchar } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  name: text('name').notNull(),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});
```

**Verify:** `npx drizzle-kit generate` -> migration created without errors?

### DB: Define Relations

```typescript
// src/lib/server/db/schema/relations.ts
import { relations } from 'drizzle-orm';
import { users } from './users';
import { posts } from './posts';

export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
}));

export const postsRelations = relations(posts, ({ one }) => ({
  author: one(users, {
    fields: [posts.authorId],
    references: [users.id],
  }),
}));
```

**Verify:** Query mit `with` works: `db.query.users.findFirst({ with: { posts: true } })`

### DB: pgEnum Instead of String

```typescript
// Before (fragile, no DB-level constraint):
// role: text('role').notNull().default('user'),

// After (type-safe + DB constraint):
import { pgEnum } from 'drizzle-orm/pg-core';

export const roleEnum = pgEnum('role', ['user', 'admin', 'moderator']);

export const users = pgTable('users', {
  // ...
  role: roleEnum('role').notNull().default('user'),
});
```

**Verify:** `npx drizzle-kit generate` -> enum migration correct?

### DB: Split Schema Files

```
src/lib/server/db/
  schema/
    index.ts          <- Re-exports everything
    users.ts           <- User table + relations
    posts.ts           <- Posts table + relations
    sessions.ts        <- Auth sessions
  index.ts             <- DB client export
  migrate.ts           <- Migration runner
```

```typescript
// src/lib/server/db/schema/index.ts
export * from './users';
export * from './posts';
export * from './sessions';
```

```typescript
// drizzle.config.ts — adjust schema path
export default defineConfig({
  schema: './src/lib/server/db/schema/index.ts',
  // ...
});
```

---

## CONN — Connection Pool Setup

### DB: pg Pool with Recommended Defaults

```typescript
// src/lib/server/db/index.ts
import { drizzle } from 'drizzle-orm/node-postgres';
import pg from 'pg';
import * as schema from './schema';

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10,                    // Max connections (adjust to server size)
  idleTimeoutMillis: 30000,   // Close idle connection after 30s
  connectionTimeoutMillis: 5000, // Connection timeout 5s
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: true }
    : false,
});

// Graceful Shutdown
process.on('SIGTERM', async () => {
  await pool.end();
  process.exit(0);
});

export const db = drizzle(pool, { schema });
```

**Verify:** App starts without connection errors? Pool size fits the server?

### DB: Neon Serverless Connection

```typescript
// src/lib/server/db/index.ts — for Neon/Serverless
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';
import * as schema from './schema';

const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql, { schema });
```

**Verify:** Serverless function connects correctly? Cold start < 1s?

### DB: Singleton Pattern (Hot Reload)

```typescript
// src/lib/server/db/index.ts — prevents connection leak on dev hot reload
import { drizzle } from 'drizzle-orm/node-postgres';
import pg from 'pg';
import * as schema from './schema';

const globalForDb = globalThis as unknown as {
  pool: pg.Pool | undefined;
};

const pool = globalForDb.pool ?? new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10,
});

if (process.env.NODE_ENV !== 'production') {
  globalForDb.pool = pool;
}

export const db = drizzle(pool, { schema });
```

**Verify:** `netstat -an | grep 5432` -> connection count stable on dev restarts?

---

## MIG — Migration Workflow

### DB: generate -> migrate -> verify

```bash
# 1. Change schema (TypeScript files)
# 2. Generate migration
npx drizzle-kit generate

# 3. Review generated SQL (ALWAYS read it!)
# migrations/XXXX_*.sql

# 4. Run migration
npx drizzle-kit migrate

# 5. Verify
npx drizzle-kit studio  # visual check
```

### DB: Migration Runner for Production

```typescript
// src/lib/server/db/migrate.ts
import { migrate } from 'drizzle-orm/node-postgres/migrator';
import { drizzle } from 'drizzle-orm/node-postgres';
import pg from 'pg';

async function runMigrations() {
  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    max: 1, // Only 1 connection for migrations
  });

  const db = drizzle(pool);

  console.log('Running migrations...');
  await migrate(db, { migrationsFolder: './migrations' });
  console.log('Migrations complete.');

  await pool.end();
}

runMigrations().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
```

**Verify:** Migrations run without errors?

### DB: drizzle.config.ts

```typescript
// drizzle.config.ts
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  dialect: 'postgresql',
  schema: './src/lib/server/db/schema/index.ts',
  out: './migrations',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  verbose: true,
  strict: true, // Warns on destructive changes
});
```

---

## ENV — PostgreSQL Docker-Compose Setup

### DB: Docker Compose with Health Check

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:17-alpine  # Do NOT hardcode version — check current
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_USER:-app}
      POSTGRES_PASSWORD: ${DB_PASSWORD}  # From .env, NOT hardcoded
      POSTGRES_DB: ${DB_NAME:-appdb}
    ports:
      - '127.0.0.1:5432:5432'  # Only locally reachable
    volumes:
      - pgdata:/var/lib/postgresql/data  # REQUIRED: persistent data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${DB_USER:-app} -d ${DB_NAME:-appdb}']
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

volumes:
  pgdata:  # Named volume — survives container restarts
```

**Verify:** `docker compose up -d` -> `docker compose ps` shows "healthy"?

### DB: Environment Variables (.env)

```bash
# .env (gitignored!)
DATABASE_URL=postgresql://user:pw@localhost:5432/dbname

# Individual (alternative):
DB_USER=app
DB_PASSWORD=  # Set secure password
DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
```

```bash
# .env.example (committed — without real values!)
DATABASE_URL=postgresql://user:pw@localhost:5432/dbname
DB_USER=user
DB_PASSWORD=  # Set password
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dbname
```

**Verify:** `.env` in `.gitignore`? `git log --all -p -- .env` -> 0 matches?

---

## PERF — Index Creation

### DB: Indexes with Drizzle

```typescript
import { pgTable, serial, text, timestamp, index, uniqueIndex } from 'drizzle-orm/pg-core';

export const posts = pgTable('posts', {
  id: serial('id').primaryKey(),
  title: text('title').notNull(),
  slug: text('slug').notNull(),
  authorId: serial('author_id').notNull(),
  status: text('status').notNull().default('draft'),
  publishedAt: timestamp('published_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
}, (table) => [
  // B-Tree index on foreign key (REQUIRED)
  index('posts_author_id_idx').on(table.authorId),

  // Unique index on slug
  uniqueIndex('posts_slug_idx').on(table.slug),

  // Composite index for frequent queries
  index('posts_status_published_idx').on(table.status, table.publishedAt),

  // Partial index (published posts only)
  index('posts_published_idx')
    .on(table.publishedAt)
    .where(sql`${table.status} = 'published'`),
]);
```

**Verify:** `npx drizzle-kit generate` -> index migration correct? EXPLAIN ANALYZE on query?

### DB: GIN Index for JSONB

```typescript
import { pgTable, serial, jsonb, index } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const products = pgTable('products', {
  id: serial('id').primaryKey(),
  metadata: jsonb('metadata'),
}, (table) => [
  // GIN index for JSONB queries
  index('products_metadata_idx')
    .using('gin', table.metadata),
]);

// Query: Search in JSONB
// db.select().from(products).where(sql`${products.metadata} @> '{"category": "electronics"}'`)
```

### DB: SQL-based Indexes

```sql
-- B-Tree index (default, for equality + range)
CREATE INDEX idx_users_email ON users (email);

-- Partial index (only for subset, saves space)
CREATE INDEX idx_sessions_active ON sessions (user_id)
  WHERE expires_at > NOW();

-- GIN index for JSONB columns
CREATE INDEX idx_settings_data ON user_settings USING GIN (data);

-- Composite index (order matters!)
CREATE INDEX idx_logs_user_created ON audit_logs (user_id, created_at DESC);
```

---

## BAK — Backup with pg_dump

### DB: Backup Script

```bash
#!/bin/bash
# scripts/backup-db.sh

set -euo pipefail

# Configuration from .env
source .env

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.dump"

mkdir -p "$BACKUP_DIR"

# pg_dump with compression
PGPASSWORD="$DB_PASSWORD" pg_dump \
  -h "${DB_HOST:-localhost}" \
  -p "${DB_PORT:-5432}" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  --format=custom \
  --compress=9 \
  > "$BACKUP_FILE"

echo "Backup created: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"

# Delete old backups (older than 30 days)
find "$BACKUP_DIR" -name "backup_*.dump" -mtime +30 -delete
echo "Old backups cleaned up."
```

### DB: Restore Script

```bash
#!/bin/bash
# scripts/restore-db.sh

set -euo pipefail

source .env

BACKUP_FILE="${1:?Usage: $0 <backup-file>}"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "WARNING: Database $DB_NAME will be overwritten!"
read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

PGPASSWORD="$DB_PASSWORD" pg_restore \
  -h "${DB_HOST:-localhost}" \
  -p "${DB_PORT:-5432}" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  --clean \
  --if-exists \
  "$BACKUP_FILE"

echo "Restore complete."
```

**Verify:** Create backup -> test restore -> data present?

### DB: Docker Backup (Container)

```bash
# Backup from Docker container
docker compose exec -T db pg_dump \
  -U "${DB_USER:-app}" \
  -d "${DB_NAME:-appdb}" \
  --format=custom \
  --compress=9 \
  > "backup_$(date +%Y%m%d_%H%M%S).dump"

# Restore into Docker container
docker compose exec -T db pg_restore \
  -U "${DB_USER:-app}" \
  -d "${DB_NAME:-appdb}" \
  --clean \
  --if-exists \
  < backup_file.dump
```

---

## SEC — SSL Connection Setup

### DB: SSL for Production

```typescript
// src/lib/server/db/index.ts
import { drizzle } from 'drizzle-orm/node-postgres';
import pg from 'pg';
import * as schema from './schema';

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production'
    ? {
        rejectUnauthorized: true,
        // Optional: CA certificate for self-signed
        // ca: fs.readFileSync('/path/to/ca-cert.pem').toString(),
      }
    : false,
});

export const db = drizzle(pool, { schema });
```

### DB: Separate DB User (Least Privilege)

```sql
-- Run as superuser (one-time setup)
-- Passwords NOT here, set via .env instead

-- App user with minimal privileges
CREATE ROLE app_user WITH LOGIN PASSWORD '...';
GRANT CONNECT ON DATABASE appdb TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- For future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO app_user;

-- Migration user (needs DDL privileges)
CREATE ROLE app_migrator WITH LOGIN PASSWORD '...';
GRANT ALL PRIVILEGES ON DATABASE appdb TO app_migrator;
```

**Verify:** App works with `app_user`? `DROP TABLE` fails with `app_user`?

---

## QUERY — Prepared Statements vs Raw Queries

### DB: Prepared Statements

```typescript
import { eq, and, gte } from 'drizzle-orm';

// Before (DANGEROUS — SQL injection!):
// const result = await db.execute(sql`SELECT * FROM users WHERE email = '${email}'`);

// After (safe — parameterized):
const user = await db.query.users.findFirst({
  where: eq(users.email, email),
});

// Prepared statement for recurring queries
const getUserByEmail = db.query.users.findFirst({
  where: eq(users.email, sql.placeholder('email')),
}).prepare('get_user_by_email');

// Call
const user = await getUserByEmail.execute({ email: 'test@example.com' });
```

**Verify:** No `${}` in `sql` templates (except Drizzle column references)?

### DB: Transaction Patterns

```typescript
import { db } from './db';
import { users, accounts } from './db/schema';

// Simple transaction
const result = await db.transaction(async (tx) => {
  const [user] = await tx.insert(users).values({
    email: 'new@example.com',
    name: 'New User',
  }).returning();

  await tx.insert(accounts).values({
    userId: user.id,
    type: 'free',
  });

  return user;
});

// Transaction with rollback handling
try {
  await db.transaction(async (tx) => {
    await tx.update(accounts)
      .set({ balance: sql`balance - ${amount}` })
      .where(eq(accounts.id, fromId));

    await tx.update(accounts)
      .set({ balance: sql`balance + ${amount}` })
      .where(eq(accounts.id, toId));

    // On error: automatic rollback via exception
  });
} catch (error) {
  console.error('Transaction failed:', error);
  // Rollback has already happened
}
```

---

## INT — Framework-Integration

### DB: SvelteKit Server-Only

```typescript
// src/lib/server/db/index.ts — MUSS in $lib/server/ liegen!
// SvelteKit automatically prevents client imports
import { drizzle } from 'drizzle-orm/node-postgres';
import pg from 'pg';
import * as schema from './schema';
import { DATABASE_URL } from '$env/static/private'; // SvelteKit env

const pool = new pg.Pool({
  connectionString: DATABASE_URL,
  max: 10,
});

export const db = drizzle(pool, { schema });
```

```typescript
// src/routes/api/users/+server.ts — Server Endpoint
import { db } from '$lib/server/db';
import { users } from '$lib/server/db/schema';
import { json } from '@sveltejs/kit';

export async function GET() {
  const allUsers = await db.select().from(users);
  return json(allUsers);
}
```

**Verify:** `import { db } from '$lib/server/db'` in `.svelte` file -> build error? (expected!)

### DB: Astro Server Endpoints

```typescript
// src/lib/db/index.ts
import { drizzle } from 'drizzle-orm/node-postgres';
import pg from 'pg';
import * as schema from './schema';

const pool = new pg.Pool({
  connectionString: import.meta.env.DATABASE_URL,
  max: 10,
});

export const db = drizzle(pool, { schema });
```

```typescript
// src/pages/api/users.ts — Server Endpoint (output: 'server' or prerender: false)
import type { APIRoute } from 'astro';
import { db } from '../../lib/db';
import { users } from '../../lib/db/schema';

export const GET: APIRoute = async () => {
  const allUsers = await db.select().from(users);
  return new Response(JSON.stringify(allUsers), {
    headers: { 'Content-Type': 'application/json' },
  });
};
```

### DB: Type Export for Frontend

```typescript
// src/lib/server/db/schema/users.ts
import { pgTable, serial, text, timestamp } from 'drizzle-orm/pg-core';
import type { InferSelectModel, InferInsertModel } from 'drizzle-orm';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

// Type exports (can be imported in frontend — no DB code)
export type User = InferSelectModel<typeof users>;
export type NewUser = InferInsertModel<typeof users>;
```

**Verify:** Frontend can import `User` type without DB bundle? Check build size.

### DB: Health-Check Endpoint

```typescript
// src/routes/api/health/+server.ts (SvelteKit)
import { db } from '$lib/server/db';
import { sql } from 'drizzle-orm';

export async function GET() {
  try {
    await db.execute(sql`SELECT 1`);
    return new Response(JSON.stringify({ status: 'ok', db: 'connected' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ status: 'error', db: 'disconnected' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
```

---

As of: 2026-03-11
