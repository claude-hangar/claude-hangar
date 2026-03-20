# Astro 5 Stable — Best Practices Checklist

Checkpoints for projects running on Astro 5.x that are NOT currently migrating.
Focus: Best practices, known issues, optimizations.

---

## ENV — Environment (2 Checks)

- [ ] **V5-ENV-01** [HIGH] Node.js >= 18.17.1 (recommended: Node 24 LTS for later migration)
  - Astro 5 supports Node 18+, but Node 24 (Active LTS) is future-proof
- [ ] **V5-ENV-02** [MEDIUM] `.nvmrc` present with matching Node version

---

## CFG — Configuration (3 Checks)

- [ ] **V5-CFG-01** [HIGH] Config file is ESM (.mjs or .ts)
  - CommonJS will no longer be supported in Astro 6 — switch now
- [ ] **V5-CFG-02** [MEDIUM] No `experimental.*` flags that are already stable
  - Check if experimental features used are already stable in current minor
- [ ] **V5-CFG-03** [MEDIUM] `output` mode correct (`static`, `server`, `hybrid`)
  - Hybrid is removed in Astro 6 -> prefer `server` with `prerender: true`

---

## CODE — Code Quality (4 Checks)

- [ ] **V5-CODE-01** [HIGH] No `Astro.glob()` — switch to `import.meta.glob()` now
  - Will be removed in Astro 6, migration is easier now
- [ ] **V5-CODE-02** [HIGH] No `<ViewTransitions />` — switch to `<ClientRouter />`
  - Will be removed in Astro 6, `<ClientRouter />` is available since Astro 5
- [ ] **V5-CODE-03** [MEDIUM] `getStaticPaths()` params as strings
  - Astro 6 enforces strings, adapt now to avoid later issues
- [ ] **V5-CODE-04** [MEDIUM] TypeScript Strict Mode enabled
  - For better Astro 6 compatibility

---

## COLL — Content Collections (3 Checks)

- [ ] **V5-COLL-01** [CRITICAL] Using Content Layer API (not legacy v2 API)
  - Legacy API will be completely removed in Astro 6
  - Migrate now: `glob()` / `file()` loaders instead of direct access
- [ ] **V5-COLL-02** [HIGH] Zod import from `astro/zod`
  - Zod 4 is released (v4.3.6, Feb 2026). Astro 5 still bundles Zod 3 — use `astro/zod` import.
  - Zod 4 becomes default in Astro 6. Prepare now.
- [ ] **V5-COLL-03** [MEDIUM] Collection schemas documented and typed
  - Facilitates later Zod 4 migration

---

## PERF — Performance (4 Checks)

- [ ] **V5-PERF-01** [MEDIUM] Image optimization active (`astro:assets`)
  - `<Image />` component instead of raw `<img>` tags
- [ ] **V5-PERF-02** [MEDIUM] Prefetch strategy configured
  - `prefetch: { defaultStrategy: 'viewport' }` for better navigation
- [ ] **V5-PERF-03** [LOW] Build output analyzed
  - Check `astro build` output: bundle size, unexpected assets
- [ ] **V5-PERF-04** [MEDIUM] Fonts API usage (from Astro 5.18)
  - First-party font management with auto-preloading + fallback generation
  - Providers: Google, Fontsource, Bunny, or local files
  - Privacy-relevant: Local fonts are automatically optimized (no external CDN calls)
  - `fonts: { providers: [...], families: [...] }` in `astro.config.mjs`

---

## SEC — Security (3 Checks)

- [ ] **V5-SEC-01** [HIGH] `import.meta.env` server secrets not in client code
  - Check now in Astro 5 — in Astro 6 ALL values are inlined
- [ ] **V5-SEC-02** [MEDIUM] Dependencies up to date (no known CVEs)
  - Run `npm audit`
- [ ] **V5-SEC-03** [MEDIUM] `security.actionBodySizeLimit` configured (from Astro 5.18)
  - Limit maximum size for Astro Actions request bodies
  - Prevents denial-of-service via oversized payloads

---

## DCI — Docker/CI (2 Checks)

- [ ] **V5-DCI-01** [MEDIUM] Dockerfile prepared for Node 24
  - Testing now saves work during Astro 6 migration
- [ ] **V5-DCI-02** [LOW] CI/CD pipeline tested with Node 24
  - Parallel tests with Node 24 if possible

---

## Astro 6 Preparation (3 Checks)

- [ ] **V5-PREP-01** [HIGH] All Astro 5 deprecation warnings resolved
  - Run `astro check` and check warnings
- [ ] **V5-PREP-02** [MEDIUM] Adapter on latest v5-compatible version
  - Latest minor versions often have better v6 compatibility
- [ ] **V5-PREP-03** [LOW] Read Astro 6 upgrade guide
  - https://v6.docs.astro.build/en/guides/upgrade-to/v6/

---

As of: 2026-02-28 (updated for Astro 5.18 — Fonts API, actionBodySizeLimit)
