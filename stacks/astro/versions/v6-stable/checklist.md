# Astro 6 Stable — Best Practices Checklist

28 checkpoints in 10 areas. For projects already running on Astro 6.x stable.
Focus: Best practices, optimizations, adopting new features.
Finding prefix: `MIG-NN` (consistent with v5-stable and v6-beta)

**For migration from Astro 5 -> 6:** The `v6-beta/checklist.md` (74 checks) contains all breaking changes and migration steps.
This checklist is for projects already successfully running on 6.x.

---

## ENV — Environment (2 Checks)

- [ ] **V6-ENV-01** [HIGH] Node.js >= 22.12.0 on all environments
  - Local, CI/CD, Docker, VPS — identical version everywhere
  - `.nvmrc` with `24` present (Maintenance LTS, Minimum: 22.12.0)
  - Note: From October 2026, Node.js switches to annual releases (every version becomes LTS)
- [ ] **V6-ENV-02** [MEDIUM] Node 24 LTS features utilized
  - Native Fetch, Web Streams, node:test if relevant

---

## CFG — Configuration (3 Checks)

- [ ] **V6-CFG-01** [HIGH] Config is ESM (.mjs or .ts)
  - No CommonJS — Vite 8 enforces ESM
- [ ] **V6-CFG-02** [MEDIUM] No `experimental.*` flags that are stable in v6
  - `fonts`, `csp`, `responsiveImages` etc. — remove experimental
- [ ] **V6-CFG-03** [HIGH] Output mode correct (`static` or `server`)
  - `output: 'hybrid'` has NOT existed since Astro 5
  - Instead: `output: 'server'` + `export const prerender = true` per page
  - See fix-templates.md -> "MIG: Adapter Config Changes"

---

## CODE — Code Quality (3 Checks)

- [ ] **V6-CODE-01** [HIGH] TypeScript Strict Mode enabled
  - Astro 6 benefits greatly from strict typing
- [ ] **V6-CODE-02** [MEDIUM] No deprecated Astro APIs in code
  - `Astro.glob()`, `ViewTransitions`, `emitESMImage()` — all removed
  - `grep -rn 'Astro.glob\|ViewTransitions\|emitESMImage' src/`
- [ ] **V6-CODE-03** [MEDIUM] Client directives minimal (`client:load` only when necessary)
  - Prefer `client:idle`, `client:visible`
  - Islands architecture: as little client JS as possible

---

## COLL — Content Collections (3 Checks)

- [ ] **V6-COLL-01** [HIGH] Content Layer API with loaders active
  - `glob()`, `file()`, or custom loader in `content.config.ts`
- [ ] **V6-COLL-02** [HIGH] Zod import via `astro:content` or `astro/zod`
  - Do not import directly from `zod` — Zod 4 is bundled
- [ ] **V6-COLL-03** [MEDIUM] Schemas documented and validated
  - Run `astro check` — schema errors will be reported

---

## PERF — Performance (3 Checks)

- [ ] **V6-PERF-01** [HIGH] Image optimization with `astro:assets`
  - `<Image>` component instead of raw `<img>` tags
  - Responsive images with `widths` and `sizes`
- [ ] **V6-PERF-02** [MEDIUM] Prefetch strategy configured
  - `prefetch: { defaultStrategy: 'viewport' }`
- [ ] **V6-PERF-03** [LOW] Build output analyzed
  - Bundle size, unexpected assets, tree-shaking effective?

---

## SEC — Security (3 Checks)

- [ ] **V6-SEC-01** [CRITICAL] `import.meta.env` secrets not in client bundles
  - In Astro 6 ALL values are inlined — check server secrets
  - `grep -rn 'import.meta.env' src/` — only PUBLIC_ in client code
- [ ] **V6-SEC-02** [HIGH] CSP (Content Security Policy) configured
  - `security.csp` in astro.config — automatic script/style hashing
- [ ] **V6-SEC-03** [MEDIUM] Dependencies up to date (no CVEs)
  - `npm audit` + `npx npm-check-updates`

---

## FONT — Fonts (2 Checks)

- [ ] **V6-FONT-01** [MEDIUM] Using Fonts API instead of manual font embedding
  - `fonts` in astro.config — automatic optimization
  - Privacy: `fontsource`, `local` or `npm` provider (no Google CDN)
- [ ] **V6-FONT-02** [LOW] Font loading strategy optimized
  - `font-display: swap` or `optional` depending on context

---

## VITE — Vite 8 (2 Checks)

- [ ] **V6-VITE-01** [HIGH] All Vite plugins compatible with Vite 8
  - Vite 8 plugin API changes apply (Environment API stable)
  - `npx astro build` without warnings?
- [ ] **V6-VITE-02** [MEDIUM] Vite 8 Environment API features utilized
  - Dev/prod parity improved — check custom middleware

---

## DCI — Docker/CI (3 Checks)

- [ ] **V6-DCI-01** [HIGH] Docker base image Node 24
  - `FROM node:24-alpine` in all stages
- [ ] **V6-DCI-02** [MEDIUM] CI uses `.nvmrc` instead of hardcoded version
  - `node-version-file: '.nvmrc'` in GitHub Actions
- [ ] **V6-DCI-03** [LOW] Multi-stage build optimized
  - Build dependencies not in runtime image

---

## NEW — Evaluate New v6 Features (4 Checks)

- [ ] **V6-NEW-01** [LOW] Evaluate Live Content Collections
  - CMS/API/DB data without rebuild — relevant for dynamic content
- [ ] **V6-NEW-02** [LOW] Evaluate Responsive Images (`layout` attribute)
  - Automatic `srcset` + `sizes` with layout hints
- [ ] **V6-NEW-03** [LOW] Use Dev Server improvements
  - Vite Environment API, better HMR, faster reloads
- [ ] **V6-NEW-04** [LOW] Check View Transition API updates
  - `<ClientRouter>` with improved features

---

As of: 2026-03-22 (updated for Astro 6.0.8, Vite 8.0.1, Zod 4.3.6)
