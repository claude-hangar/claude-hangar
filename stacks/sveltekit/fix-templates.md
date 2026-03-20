# SvelteKit Audit: Quick-Fix Templates

Ready-made fix templates for common SvelteKit / Svelte 5 findings.
For each fix: 1. Show template, 2. User confirmation, 3. Implement, 4. Verify.

---

## CODE — Svelte 5 Runes Migration

### SKT: `let` -> `$state()` Migration

```svelte
<!-- Before (Svelte 4 / Legacy): -->
<script>
  let count = 0;
  let name = 'World';
  let items = [];
</script>

<!-- After (Svelte 5 Runes): -->
<script>
  let count = $state(0);
  let name = $state('World');
  let items = $state([]);
</script>
```

**Verify:** `npx svelte-check` -> no warnings about legacy reactivity?

### SKT: `$:` -> `$derived()` / `$effect()` Migration

```svelte
<!-- Before (Svelte 4 / Legacy): -->
<script>
  let count = 0;
  $: doubled = count * 2;
  $: quadrupled = doubled * 2;
  $: {
    console.log('Count changed:', count);
    localStorage.setItem('count', count.toString());
  }
  $: if (count > 10) {
    alert('High!');
  }
</script>

<!-- After (Svelte 5 Runes): -->
<script>
  let count = $state(0);
  let doubled = $derived(count * 2);
  let quadrupled = $derived(doubled * 2);

  $effect(() => {
    console.log('Count changed:', count);
    localStorage.setItem('count', count.toString());
  });

  $effect(() => {
    if (count > 10) {
      alert('High!');
    }
  });
</script>
```

**Rule:** `$derived` for pure computations, `$effect` ONLY for side effects.

**Verify:** Test functionality in browser — reactivity works as before?

### SKT: `on:click` -> `onclick` Event Migration

```svelte
<!-- Before (Svelte 4): -->
<button on:click={handleClick}>Click</button>
<input on:input={handleInput} on:focus={handleFocus} />
<form on:submit|preventDefault={handleSubmit}>

<!-- After (Svelte 5): -->
<button onclick={handleClick}>Click</button>
<input oninput={handleInput} onfocus={handleFocus} />
<form onsubmit={(e) => { e.preventDefault(); handleSubmit(e); }}>
```

**Important:** `|preventDefault` modifier no longer exists. Use `e.preventDefault()` in the handler instead.

**Verify:** All event handlers work? `grep -rn 'on:' src/ --include='*.svelte'` -> 0 matches?

### SKT: `export let` -> `$props()` Migration

```svelte
<!-- Before (Svelte 4): -->
<script>
  export let name;
  export let age = 25;
  export let className = '';
</script>

<!-- After (Svelte 5): -->
<script>
  let { name, age = 25, class: className = '', ...rest } = $props();
</script>
```

**Verify:** Check all component usages — are props passed correctly?

### SKT: Slots -> Snippets Migration

```svelte
<!-- Before (Svelte 4 — Slots): -->
<!-- Card.svelte -->
<div class="card">
  <header><slot name="header" /></header>
  <main><slot /></main>
  <footer><slot name="footer" /></footer>
</div>

<!-- Usage: -->
<Card>
  <h2 slot="header">Title</h2>
  <p>Content</p>
  <span slot="footer">Footer</span>
</Card>

<!-- After (Svelte 5 — Snippets): -->
<!-- Card.svelte -->
<script>
  let { header, children, footer } = $props();
</script>
<div class="card">
  <header>{@render header?.()}</header>
  <main>{@render children?.()}</main>
  <footer>{@render footer?.()}</footer>
</div>

<!-- Usage: -->
<Card>
  {#snippet header()}<h2>Title</h2>{/snippet}
  <p>Content</p>
  {#snippet footer()}<span>Footer</span>{/snippet}
</Card>
```

**Verify:** All slot usages migrated? `grep -rn 'slot=' src/ --include='*.svelte'` -> 0 matches?

---

## ROUT — SvelteKit 2 Routing

### SKT: Load Function Types

```typescript
// +page.server.ts — Server Load
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
  // DB queries, auth checks, secrets here
  const post = await db.query.posts.findFirst({
    where: eq(posts.slug, params.slug)
  });

  if (!post) {
    throw error(404, 'Post not found');
  }

  return { post };
};

// +page.ts — Universal Load (no server-only access)
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch, data }) => {
  // Runs on server AND client
  // `data` comes from server load (if present)
  const res = await fetch('/api/public-data');
  return { items: await res.json() };
};
```

**Verify:** `npx svelte-check` -> no type errors in load functions?

### SKT: Error Handling in Load Functions

```typescript
// +page.server.ts
import { error, redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
  if (!locals.user) {
    throw redirect(303, '/login');
  }

  const item = await getItem(params.id);

  if (!item) {
    throw error(404, {
      message: 'Not found',
      code: 'NOT_FOUND'
    });
  }

  if (item.ownerId !== locals.user.id) {
    throw error(403, 'Access denied');
  }

  return { item };
};
```

---

## FORM — Form Actions

### SKT: Form Actions Setup

```typescript
// +page.server.ts
import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
  if (!locals.user) throw redirect(303, '/login');
  return { user: locals.user };
};

export const actions: Actions = {
  updateProfile: async ({ request, locals }) => {
    if (!locals.user) throw redirect(303, '/login');

    const formData = await request.formData();
    const name = formData.get('name')?.toString().trim();
    const email = formData.get('email')?.toString().trim();

    // Validation
    const errors: Record<string, string> = {};
    if (!name || name.length < 2) errors.name = 'Name must be at least 2 characters';
    if (!email || !email.includes('@')) errors.email = 'Invalid email';

    if (Object.keys(errors).length > 0) {
      return fail(400, { name, email, errors });
    }

    // Update DB
    await db.update(users).set({ name, email }).where(eq(users.id, locals.user.id));

    return { success: true };
  }
};
```

```svelte
<!-- +page.svelte -->
<script>
  import { enhance } from '$app/forms';
  let { form, data } = $props();
</script>

<form method="POST" action="?/updateProfile" use:enhance>
  <label>
    Name
    <input name="name" value={form?.name ?? data.user.name} />
    {#if form?.errors?.name}<span class="error">{form.errors.name}</span>{/if}
  </label>

  <label>
    Email
    <input name="email" type="email" value={form?.email ?? data.user.email} />
    {#if form?.errors?.email}<span class="error">{form.errors.email}</span>{/if}
  </label>

  <button type="submit">Save</button>
  {#if form?.success}<p class="success">Saved!</p>{/if}
</form>
```

**Verify:** Form works with and without JavaScript?

---

## HOOK — hooks.server.ts

### SKT: Auth Guard Setup

```typescript
// src/hooks.server.ts
import type { Handle, HandleServerError } from '@sveltejs/kit';
import { redirect } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { sessions, users } from '$lib/server/db/schema';
import { eq, and, gt } from 'drizzle-orm';

// Routes that MUST be accessible without login
const PUBLIC_ROUTES = ['/login', '/register', '/api/health'];

function isPublicRoute(pathname: string): boolean {
  return PUBLIC_ROUTES.some(route => pathname.startsWith(route));
}

export const handle: Handle = async ({ event, resolve }) => {
  // 1. Read session from cookie
  const sessionId = event.cookies.get('session_id');

  if (sessionId) {
    // 2. Validate session in DB (including expiry check)
    const [session] = await db.select()
      .from(sessions)
      .innerJoin(users, eq(sessions.userId, users.id))
      .where(and(
        eq(sessions.id, sessionId),
        gt(sessions.expiresAt, new Date())
      ))
      .limit(1);

    if (session) {
      event.locals.user = {
        id: session.users.id,
        email: session.users.email,
        name: session.users.name
      };
    } else {
      // Expired session — delete cookie
      event.cookies.delete('session_id', { path: '/' });
    }
  }

  // 3. Auth guard — check protected routes
  if (!event.locals.user && !isPublicRoute(event.url.pathname)) {
    throw redirect(303, '/login');
  }

  return resolve(event);
};

export const handleError: HandleServerError = async ({ error, event, status, message }) => {
  const errorId = crypto.randomUUID();

  // Log server-side (with details)
  console.error(`[${errorId}] ${event.url.pathname}:`, error);

  // To client: only generic message + ID for support
  return {
    message: status === 404 ? 'Page not found' : 'An error occurred',
    errorId
  };
};
```

**Verify:** Protected route without login -> redirect to `/login`? Login -> access OK?

---

## ADPT — Adapter-Node Configuration

### SKT: adapter-node Setup

```javascript
// svelte.config.js
import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  kit: {
    adapter: adapter({
      // Default settings — explicitly documented
      out: 'build',
      precompress: true,    // gzip + brotli for static assets
      envPrefix: ''         // Default: all env vars available
    }),
    alias: {
      $components: 'src/lib/components',
      $server: 'src/lib/server'
    }
  }
};

export default config;
```

```dockerfile
# Dockerfile for SvelteKit with adapter-node
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN npm prune --production

FROM node:22-alpine AS runtime
WORKDIR /app
COPY --from=build /app/build ./build
COPY --from=build /app/node_modules ./node_modules
COPY package.json .
USER node
EXPOSE 3000
ENV NODE_ENV=production
# ORIGIN must be set to the actual domain
ENV ORIGIN=https://your-domain.com
ENV PORT=3000
CMD ["node", "build"]
```

**Important:** `ORIGIN` must be set in production — SvelteKit needs it for CSRF protection.

**Verify:** `docker build -t app . && docker run -p 3000:3000 app` -> app accessible?

---

## SSR — Environment Variables

### SKT: Using $env correctly

```typescript
// Server-Only (Secrets) — NEVER importable in client
import { DATABASE_URL, JWT_SECRET } from '$env/static/private';
import { API_KEY } from '$env/dynamic/private';

// Client-safe (PUBLIC_ prefix required)
import { PUBLIC_APP_NAME } from '$env/static/public';
import { PUBLIC_API_URL } from '$env/dynamic/public';
```

```bash
# .env — Example structure (do NOT commit real values!)
DATABASE_URL=<connection-string>
JWT_SECRET=<secret-key>
API_KEY=<external-api-key>

# PUBLIC_ prefix = visible in client
PUBLIC_APP_NAME=MyApp
PUBLIC_API_URL=https://api.example.com
```

**Important:**
- `$env/static/*` — inlined at build time (tree-shakeable, faster)
- `$env/dynamic/*` — read at runtime (more flexible, for Docker/VPS)
- Do NOT use `process.env` — SvelteKit's `$env` modules are type-safe

**Verify:** Build with `npx vite build` -> no errors about missing env vars?

---

## TOOL — svelte-check + TypeScript Setup

### SKT: svelte-check Configuration

```json
// package.json — Scripts
{
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "preview": "vite preview",
    "check": "svelte-check --tsconfig ./tsconfig.json",
    "check:watch": "svelte-check --tsconfig ./tsconfig.json --watch",
    "lint": "eslint .",
    "format": "prettier --write ."
  }
}
```

```json
// tsconfig.json
{
  "extends": "./.svelte-kit/tsconfig.json",
  "compilerOptions": {
    "strict": true,
    "allowJs": true,
    "checkJs": true,
    "moduleResolution": "bundler"
  }
}
```

```yaml
# .github/workflows/ci.yml — CI integration
- name: Type Check
  run: npx svelte-check --fail-on-warnings
```

**Verify:** `npx svelte-check` -> 0 errors, 0 warnings?

### SKT: Prettier + ESLint Setup

```json
// .prettierrc
{
  "useTabs": true,
  "singleQuote": true,
  "trailingComma": "none",
  "printWidth": 100,
  "plugins": ["prettier-plugin-svelte"],
  "overrides": [
    { "files": "*.svelte", "options": { "parser": "svelte" } }
  ]
}
```

```javascript
// eslint.config.js (Flat Config)
import js from '@eslint/js';
import ts from 'typescript-eslint';
import svelte from 'eslint-plugin-svelte';
import globals from 'globals';

export default ts.config(
  js.configs.recommended,
  ...ts.configs.recommended,
  ...svelte.configs['flat/recommended'],
  {
    languageOptions: {
      globals: { ...globals.browser, ...globals.node }
    }
  },
  {
    files: ['**/*.svelte'],
    languageOptions: {
      parserOptions: { parser: ts.parser }
    }
  },
  { ignores: ['build/', '.svelte-kit/', 'dist/'] }
);
```

**Verify:** `npx eslint .` and `npx prettier --check .` -> no errors?

---

## DB — Drizzle Server-Only Setup

### SKT: Drizzle in $lib/server/

```typescript
// src/lib/server/db/index.ts — DB Client (Server-Only!)
import { drizzle } from 'drizzle-orm/node-postgres';
import { DATABASE_URL } from '$env/static/private';
import * as schema from './schema';

export const db = drizzle(DATABASE_URL, { schema });
```

```typescript
// src/lib/server/db/schema.ts — Schema Definition
import { pgTable, text, timestamp, boolean, uuid } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
  passwordHash: text('password_hash').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull()
});

export const sessions = pgTable('sessions', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  expiresAt: timestamp('expires_at').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull()
});

export const sessionsRelations = relations(sessions, ({ one }) => ({
  user: one(users, { fields: [sessions.userId], references: [users.id] })
}));
```

```typescript
// drizzle.config.ts
import type { Config } from 'drizzle-kit';

export default {
  schema: './src/lib/server/db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!  // Only in drizzle-kit CLI, not in app
  }
} satisfies Config;
```

**Important:** `$lib/server/` is blocked by SvelteKit — client imports cause build errors. This is intentional and protects secrets.

**Verify:** `npx drizzle-kit push` -> schema synced? Client import of `$lib/server/db` -> build error?

---

## AUTH — Session Cookie Config

### SKT: Secure Cookie Configuration

```typescript
// src/lib/server/auth.ts
import { db } from '$lib/server/db';
import { sessions, users } from '$lib/server/db/schema';
import { eq } from 'drizzle-orm';
import bcrypt from 'bcryptjs';
import type { Cookies } from '@sveltejs/kit';

const SESSION_DURATION = 30 * 24 * 60 * 60 * 1000; // 30 days

export async function createSession(userId: string, cookies: Cookies): Promise<void> {
  const expiresAt = new Date(Date.now() + SESSION_DURATION);

  const [session] = await db.insert(sessions).values({
    userId,
    expiresAt
  }).returning();

  cookies.set('session_id', session.id, {
    path: '/',
    httpOnly: true,        // No JS access
    secure: true,          // HTTPS only (dev: false)
    sameSite: 'lax',       // CSRF protection
    maxAge: SESSION_DURATION / 1000  // in seconds
  });
}

export async function deleteSession(sessionId: string, cookies: Cookies): Promise<void> {
  await db.delete(sessions).where(eq(sessions.id, sessionId));
  cookies.delete('session_id', { path: '/' });
}

export async function verifyPassword(plain: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, 12);  // Salt rounds >= 10
}
```

**Verify:** Check cookie in browser DevTools -> `HttpOnly`, `Secure`, `SameSite=Lax` set?

---

As of: 2026-03-11
