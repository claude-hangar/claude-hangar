# SvelteKit 2 + Svelte 5 — Best-Practice Checklist

51 checkpoints in 16 areas. Severity: CRITICAL > HIGH > MEDIUM > LOW.
Finding prefix: `SKT-NN` (SvelteKit), `BP-NN` (Best Practice)

---

## ENV — Environment (3 Checks, Top: CRITICAL)

- [ ] **ENV-01** [CRITICAL] [MUST] Node.js >= 18.13 on all environments (local, CI/CD, Docker, VPS)
  - SvelteKit 2 minimum: Node 18.13
  - Recommended: Node 22 LTS or Node 24 LTS
  - Check `node --version`, create `.nvmrc`
- [ ] **ENV-02** [HIGH] [MUST] `.nvmrc` present and up to date
  - Consistent Node version for team, CI, and Docker
  - Use `node-version-file: '.nvmrc'` in GitHub Actions
- [ ] **ENV-03** [MEDIUM] [SHOULD] Package manager lock file consistent
  - `package-lock.json` (npm) OR `pnpm-lock.yaml` (pnpm) — never both
  - Lock file NOT in `.gitignore` (must be committed)

---

## CFG — Configuration (4 Checks, Top: CRITICAL)

- [ ] **CFG-01** [CRITICAL] [MUST] `svelte.config.js` correctly configured
  - Adapter set, `kit.alias` for `$lib` etc.
  - No outdated `preprocess` for CSS (Tailwind v4 doesn't need one)
- [ ] **CFG-02** [HIGH] [MUST] `vite.config.ts` uses `sveltekit()` plugin
  - `import { sveltekit } from '@sveltejs/kit/vite'`
  - No manual `svelte()` plugin when SvelteKit is used
- [ ] **CFG-03** [HIGH] [SHOULD] Aliases configured (`$lib`, `$env`, custom)
  - `$lib` -> `src/lib` (SvelteKit default)
  - Custom aliases in `svelte.config.js` under `kit.alias`
- [ ] **CFG-04** [MEDIUM] [SHOULD] `vite.config.ts` server config for development
  - `server.host: true` for network access
  - Proxy config for external APIs if needed

---

## CODE — Svelte 5 Code Patterns (6 Checks, Top: CRITICAL)

- [ ] **CODE-01** [CRITICAL] [MUST] No `let` for reactive variables — use `$state()`
  - Svelte 5: `let count = $state(0)` instead of `let count = 0`
  - Check all `.svelte` files for reactive `let` declarations without `$state`
- [ ] **CODE-02** [CRITICAL] [MUST] No `$:` — use `$derived()` and `$effect()`
  - `$:` reactivity is legacy in Svelte 5
  - `$: doubled = count * 2` -> `let doubled = $derived(count * 2)`
  - `$: { sideEffect() }` -> `$effect(() => { sideEffect() })`
- [ ] **CODE-03** [HIGH] [MUST] Event handling: `onclick` instead of `on:click`
  - Svelte 5: `<button onclick={handler}>` instead of `<button on:click={handler}>`
  - Applies to all DOM events: `oninput`, `onsubmit`, `onkeydown`, etc.
- [ ] **CODE-04** [HIGH] [MUST] Snippets instead of slots (`{#snippet}` / `{@render}`)
  - Svelte 5: Named slots replaced by snippets
  - `<slot name="header" />` -> `{@render header()}`
  - Props via snippet parameters instead of `let:item`
- [ ] **CODE-05** [MEDIUM] [SHOULD] Use `$effect()` sparingly — prefer `$derived()`
  - `$effect` only for real side effects (DOM, API calls, subscriptions)
  - Computations belong in `$derived`, not in `$effect`
- [ ] **CODE-06** [MEDIUM] [SHOULD] `$props()` instead of `export let` for component props
  - Svelte 5: `let { name, age = 25 } = $props()` instead of `export let name; export let age = 25`
  - Rest props: `let { name, ...rest } = $props()`

---

## ROUT — Routing (4 Checks, Top: HIGH)

- [ ] **ROUT-01** [HIGH] [MUST] File-based routing correctly structured
  - `src/routes/` as root, `+page.svelte` for pages
  - `+layout.svelte` for shared layouts
  - `+error.svelte` for error pages
- [ ] **ROUT-02** [HIGH] [MUST] Group-based routing correctly used
  - `(group)` directories for layouts without URL segment
  - Example: `(auth)/login/+page.svelte`, `(app)/dashboard/+page.svelte`
  - No nesting of groups without reason
- [ ] **ROUT-03** [MEDIUM] [SHOULD] Error pages and error boundaries at all levels
  - `src/routes/+error.svelte` as global fallback error page
  - Route-specific `+error.svelte` where appropriate
  - Error page shows meaningful error message (not stack trace)
  - From SvelteKit 2.54: Error boundaries also catch server errors (load function errors)
- [ ] **ROUT-04** [MEDIUM] [SHOULD] Dynamic routes with param validation
  - `[slug]` parameters validated in load function
  - `error(404)` for invalid params instead of undefined errors

---

## LOAD — Load Functions (5 Checks, Top: CRITICAL)

- [ ] **LOAD-01** [CRITICAL] [MUST] Server-only data in `+page.server.ts` (not `+page.ts`)
  - DB queries, API keys, secrets belong in `.server.ts`
  - `+page.ts` (universal load) only for public data
- [ ] **LOAD-02** [HIGH] [MUST] Load function return types correct
  - Use `PageServerLoad` / `PageLoad` / `LayoutServerLoad` types
  - Return type must be serializable (no Date, Map, Set in server load)
- [ ] **LOAD-03** [HIGH] [MUST] No data waterfall — parallel fetches
  - Multiple independent fetches with `Promise.all()` in parallel
  - Not sequential `await fetch1(); await fetch2();`
- [ ] **LOAD-04** [MEDIUM] [SHOULD] `depends()` and `invalidate()` for fine-grained reloading
  - `depends('app:user')` in load function
  - `invalidate('app:user')` instead of `invalidateAll()` where possible
- [ ] **LOAD-05** [LOW] [CAN] Avoid streaming with `await parent()`
  - `parent()` creates waterfall — only use when data is truly needed
  - Alternative: load data in own load function

---

## FORM — Form Actions (4 Checks, Top: HIGH)

- [ ] **FORM-01** [HIGH] [MUST] Form actions defined in `+page.server.ts`
  - `export const actions = { default: async ({ request }) => {...} }`
  - Named actions: `{ login: async () => {}, register: async () => {} }`
- [ ] **FORM-02** [HIGH] [MUST] `use:enhance` for progressive enhancement
  - `<form method="POST" use:enhance>` — form works without JS too
  - Custom `enhance` callback for loading states and error handling
- [ ] **FORM-03** [HIGH] [MUST] `fail()` for validation errors (not `throw error()`)
  - `return fail(400, { errors })` — stays on page, shows errors
  - `throw error(500)` only for real server errors
- [ ] **FORM-04** [MEDIUM] [SHOULD] Return form data on validation error
  - `return fail(400, { email, errors })` — user doesn't need to re-enter everything
  - NEVER return sensitive data (password)

---

## SSR — SSR/CSR/Prerendering (4 Checks, Top: HIGH)

- [ ] **SSR-01** [HIGH] [MUST] Prerender strategy defined
  - `export const prerender = true` on static pages
  - `export const prerender = false` on dynamic pages (explicitly)
  - Global prerendering in `svelte.config.js` only if project is purely static
- [ ] **SSR-02** [HIGH] [MUST] Environment variables correctly separated
  - `$env/static/private` — build-time, server-only (secrets, DB URLs)
  - `$env/static/public` — build-time, client-safe (PUBLIC_ prefix)
  - `$env/dynamic/private` — runtime, server-only
  - `$env/dynamic/public` — runtime, client-safe (PUBLIC_ prefix)
  - NEVER use `process.env` directly
- [ ] **SSR-03** [MEDIUM] [SHOULD] `ssr: false` only used intentionally
  - CSR-only pages (`export const ssr = false`) only for pure client apps
  - SEO-relevant pages MUST have SSR
- [ ] **SSR-04** [MEDIUM] [SHOULD] Evaluate `csr: false` for purely static pages
  - Saves client JS when no interactivity needed
  - Combinable with `prerender = true`

---

## API — API Routes (3 Checks, Top: CRITICAL)

- [ ] **API-01** [CRITICAL] [MUST] `+server.ts` input validation on all endpoints
  - Validate request body (Zod, custom validation)
  - Sanitize URL parameters
  - No uncontrolled data forwarding to DB/external APIs
- [ ] **API-02** [HIGH] [MUST] Error responses with correct HTTP status codes
  - `json({ error: 'Not found' }, { status: 404 })` — not always 200
  - `error()` helper for standard errors
  - No stack traces or internal details in error responses
- [ ] **API-03** [MEDIUM] [SHOULD] Request method handling correct
  - Only exported methods allowed (`GET`, `POST`, `PUT`, `DELETE`, `PATCH`)
  - SvelteKit automatically responds with 405 for non-exported methods
  - `OPTIONS` and `HEAD` are handled automatically

---

## HOOK — SvelteKit Hooks (4 Checks, Top: HIGH)

- [ ] **HOOK-01** [HIGH] [MUST] `hooks.server.ts` present and correct
  - `handle` for request pipeline (auth, locale, logging)
  - `handleError` for server-side error logging (don't leak to client)
  - `handleFetch` only if server-side fetch needs manipulation
- [ ] **HOOK-02** [HIGH] [MUST] Auth guard in `handle` hook
  - Check protected routes before they reach the load function
  - Read session from cookie, set user in `event.locals`
  - Redirect on missing auth: `throw redirect(303, '/login')`
- [ ] **HOOK-03** [MEDIUM] [SHOULD] `handleError` logs meaningfully
  - Generate error ID for correlation
  - Filter sensitive data from error messages
  - Return: only generic message to client (`{ message: 'Internal Error' }`)
- [ ] **HOOK-04** [LOW] [CAN] Locale/language detection in `handle` hook
  - Parse Accept-Language header
  - Store in `event.locals.locale` for layout usage

---

## ADPT — Adapter (3 Checks, Top: CRITICAL)

- [ ] **ADPT-01** [CRITICAL] [MUST] Correct adapter for deployment target
  - `@sveltejs/adapter-node` for Docker/VPS (recommended for self-hosted)
  - `@sveltejs/adapter-auto` only for managed platforms
  - `@sveltejs/adapter-static` for pure static sites
- [ ] **ADPT-02** [HIGH] [MUST] Adapter config complete
  - adapter-node: `envPrefix` configured (default: empty)
  - adapter-node: `origin` set in production env (`ORIGIN=https://domain.com`)
  - adapter-node: `PORT` and `HOST` environment variables documented
- [ ] **ADPT-03** [MEDIUM] [SHOULD] Adapter version compatible with SvelteKit version
  - Check `npm view @sveltejs/adapter-node version`
  - Adapter and SvelteKit version must match

---

## STORE — State Management (3 Checks, Top: HIGH)

- [ ] **STORE-01** [HIGH] [MUST] Svelte 5 Runes instead of legacy stores
  - `$state()` instead of `writable()` / `readable()`
  - `$derived()` instead of `derived()`
  - No `$store` syntax when runes are available
- [ ] **STORE-02** [HIGH] [MUST] Shared state via Context API (not global variables)
  - `setContext()` / `getContext()` in component hierarchy
  - Server-side: No global state (cross-request leaks)
  - Client-side shared state: Module scope only for client-only code
- [ ] **STORE-03** [MEDIUM] [SHOULD] `$state.raw()` for immutable data
  - Large lists/objects that are only read: `$state.raw()` instead of `$state()`
  - Prevents deep proxy overhead on large datasets

---

## TOOL — Dev Tooling (3 Checks, Top: HIGH)

- [ ] **TOOL-01** [HIGH] [MUST] `svelte-check` configured and error-free
  - `npx svelte-check --fail-on-warnings` in CI
  - TypeScript strict mode recommended
  - No suppressed errors without comment
- [ ] **TOOL-02** [MEDIUM] [SHOULD] `prettier-plugin-svelte` configured
  - `.prettierrc` with `plugins: ["prettier-plugin-svelte"]`
  - `svelteStrictMode: false` (default) — HTML attributes without quotes
  - Consistent formatting across all `.svelte` files
- [ ] **TOOL-03** [MEDIUM] [SHOULD] `eslint-plugin-svelte` configured
  - ESLint flat config with `@eslint/svelte`
  - Svelte-specific rules active (no-at-html-tags, valid-compile, etc.)
  - TypeScript integration when TS is used

---

## DB — Drizzle Integration (4 Checks, Top: CRITICAL)

- [ ] **DB-01** [CRITICAL] [MUST] Drizzle schema in `$lib/server/` (server-only)
  - Schema files NEVER importable in client bundle
  - `$lib/server/db/schema.ts` — not `$lib/db/schema.ts`
  - Client import of `$lib/server/*` throws build error (desired)
- [ ] **DB-02** [HIGH] [MUST] Drizzle client correctly initialized
  - Connection pool with reasonable limits
  - Singleton pattern: one DB instance per server process
  - Connection string via `$env/static/private` or `$env/dynamic/private`
- [ ] **DB-03** [HIGH] [MUST] Migration setup present
  - `drizzle-kit` configured (`drizzle.config.ts`)
  - Migration scripts in `drizzle/` directory
  - `npx drizzle-kit push` or `npx drizzle-kit migrate` documented
- [ ] **DB-04** [MEDIUM] [SHOULD] Schema best practices
  - Relations defined (`relations()` from `drizzle-orm`)
  - Timestamps (`createdAt`, `updatedAt`) on relevant tables
  - Indexes on frequently queried columns

---

## AUTH — Auth Patterns (3 Checks, Top: CRITICAL)

- [ ] **AUTH-01** [CRITICAL] [MUST] Session cookie securely configured
  - `httpOnly: true` — no JS access to session cookie
  - `secure: true` — HTTPS only (exception: localhost dev)
  - `sameSite: 'lax'` — CSRF protection (or `'strict'` for sensitive apps)
  - `path: '/'` — cookie valid for entire app
  - `maxAge` or `expires` set — no session cookie without expiry
- [ ] **AUTH-02** [CRITICAL] [MUST] Protected routes secured via `hooks.server.ts`
  - Central auth check in `handle` hook (not per route)
  - Whitelist approach: all routes protected, explicit public list
  - Session validation on every request (token expiry, DB check)
- [ ] **AUTH-03** [HIGH] [MUST] Password handling secure
  - bcryptjs or argon2 for hashing (NEVER MD5, SHA1, SHA256 without salt)
  - Salt rounds >= 10 (bcryptjs)
  - Password NEVER in logs, error messages, or response body

---

## BREAK — SvelteKit 2.56.0 Breaking Changes (5 Checks, Top: HIGH)

- [ ] **BREAK-01** [HIGH] [MUST] Client-driven refreshes reworked
  - Server now controls refreshes via `requested(queryFn, maxLimit)` — only validated args executed
  - Old: `.updates(query1(), query2())` — security risk (DoS vector)
  - New: Import `requested()`, explicitly authorize queries
  - `query.refresh()` no longer requests data when no cache entry exists
  - Command-triggered query refresh failures now isolated per-query
- [ ] **BREAK-02** [HIGH] [MUST] Remote function caching stabilized
  - Object keys now sorted before cache key generation
  - **Maps, Sets, Custom Objects als RF-Parameter nicht mehr erlaubt** — vorher serialisieren (`Object.fromEntries()`)
  - Gleiche Key-Value-Paare = gleicher Cache-Key, unabhängig von Reihenfolge
- [ ] **BREAK-03** [HIGH] [MUST] Queries require `run()` method
  - Query-Daten nur in reaktivem Kontext (top-level Script, `$derived`, `$effect`)
  - Für Event-Handler/Load-Functions: `await query().run()` statt `await query()`
  - Queries now managed in their own `$effect.root`
- [ ] **BREAK-04** [MEDIUM] [SHOULD] TypeScript 6.0 support utilized
  - SvelteKit 2.56.0 adds official TypeScript 6.0 support
  - Check `tsconfig.json` for TS 6.0 features
- [ ] **BREAK-05** [LOW] [CAN] New `form` field default values
  - `field.as(type, value)` for specifying default values
  - Useful for form remote functions with sensible defaults

---

## CSP — Content Security Policy (2 Checks, Top: HIGH) — NEW from 2.57.0

- [ ] **CSP-01** [HIGH] [MUST] Trusted Types directives include SvelteKit values
  - `config.kit.csp.directives['trusted-types']` must include `'svelte-trusted-html'` and `'sveltekit-trusted-url'`
  - When service worker auto-registers: `'sveltekit-trusted-url'` is required
  - Without these: CSP violations in browsers enforcing Trusted Types
- [ ] **CSP-02** [LOW] [CAN] `submit()` return value utilized for validation
  - SvelteKit 2.57.0: `submit()` now returns boolean indicating submission validity
  - Useful for enhanced form remote functions with client-side validation feedback

---

## PERF2 — Performance & Bundling (1 Check, Top: MEDIUM) — NEW from 2.57.0

- [ ] **PERF2-01** [MEDIUM] [SHOULD] Treeshaking for prerendered remote functions verified
  - SvelteKit 2.57.0 reimplemented treeshaking for non-dynamic prerendered remote functions
  - Check bundle size before/after upgrade — should decrease
  - False "inlineDynamicImports ignored with codeSplitting" warnings with Vite 8 eliminated

---

As of: 2026-04-08 (updated for SvelteKit 2.57.0, Svelte 5.55.2 — 2.57.0: submit() returns boolean, CSP trusted-types required, treeshaking reimplemented, Vite 8 code-splitting warnings fixed, Chrome DevTools workspace requests silently 404'd)
