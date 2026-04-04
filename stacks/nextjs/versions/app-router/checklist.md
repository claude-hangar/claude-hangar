# Next.js App Router — Best Practices Checklist

42 checkpoints in 10 areas. For projects using Next.js 15+ with the App Router.
Finding prefix: `NXT-NN`

---

## ENV — Environment (3 Checks)

- [ ] **NXT-ENV-01** [CRITICAL] Node.js >= 20 on all environments
  - Next.js 16 requires Node 20+, recommended: Node 22 LTS or newer
  - `.nvmrc` with version present
- [ ] **NXT-ENV-02** [HIGH] React version compatible
  - Next.js 16 requires React 19+
  - Check `package.json` for react and react-dom versions
- [ ] **NXT-ENV-03** [MEDIUM] Turbopack enabled for development
  - `next dev --turbopack` — significantly faster than Webpack
  - Check if `next.config` has Turbopack-incompatible plugins

---

## CFG — Configuration (4 Checks)

- [ ] **NXT-CFG-01** [HIGH] `next.config.mjs` or `next.config.ts` (ESM)
  - No CommonJS `next.config.js` — use `.mjs` or `.ts`
- [ ] **NXT-CFG-02** [HIGH] Output mode correct
  - `output: 'standalone'` for Docker/self-hosted
  - Default for Vercel/managed platforms
- [ ] **NXT-CFG-03** [MEDIUM] No deprecated experimental flags
  - Check for flags that became stable in Next.js 16
  - `serverActions`, `appDir` etc. are now default
- [ ] **NXT-CFG-04** [MEDIUM] Image optimization configured
  - `images.remotePatterns` for external images
  - `images.formats` includes `webp` and/or `avif`

---

## RSC — React Server Components (5 Checks)

- [ ] **NXT-RSC-01** [CRITICAL] Server Components by default
  - Components in `app/` are Server Components unless marked `'use client'`
  - Verify no unnecessary `'use client'` directives
- [ ] **NXT-RSC-02** [HIGH] Client Components minimal
  - `'use client'` only where interactivity is needed (forms, state, effects)
  - Push `'use client'` boundary as deep as possible in the component tree
- [ ] **NXT-RSC-03** [HIGH] No client-side data fetching in Server Components
  - Use `async` Server Components with direct DB/API access
  - No `useEffect` + `fetch` for data that can be loaded server-side
- [ ] **NXT-RSC-04** [MEDIUM] Streaming with Suspense boundaries
  - `<Suspense fallback={<Loading />}>` around slow data fetches
  - Prevents full-page blocking on slow queries
- [ ] **NXT-RSC-05** [MEDIUM] Server-only imports protected
  - Use `import 'server-only'` in modules that must never reach the client
  - Prevents accidental bundling of secrets or DB code

---

## ROUT — Routing (4 Checks)

- [ ] **NXT-ROUT-01** [HIGH] File-based routing correct
  - `app/page.tsx` for pages, `app/layout.tsx` for layouts
  - `app/not-found.tsx` for 404, `app/error.tsx` for error boundaries
- [ ] **NXT-ROUT-02** [HIGH] Route groups used for organization
  - `(marketing)`, `(dashboard)` — group without URL segment
  - Separate layouts per group
- [ ] **NXT-ROUT-03** [MEDIUM] Dynamic routes with validation
  - `[slug]` parameters validated in the page/layout
  - `generateStaticParams()` for known dynamic pages
- [ ] **NXT-ROUT-04** [MEDIUM] Parallel routes and intercepting routes
  - `@modal` slots for modals, `(.)photo/[id]` for interception
  - Only use when routing pattern requires it — don't over-engineer

---

## DATA — Data Fetching (5 Checks)

- [ ] **NXT-DATA-01** [CRITICAL] Server Actions for mutations
  - `'use server'` functions for form submissions and mutations
  - No API routes for simple CRUD when Server Actions suffice
- [ ] **NXT-DATA-02** [HIGH] Caching strategy defined
  - `fetch()` cache behavior understood (`force-cache`, `no-store`, `revalidate`)
  - `unstable_cache` or `cache()` for non-fetch data sources
- [ ] **NXT-DATA-03** [HIGH] Revalidation configured
  - `revalidatePath()` or `revalidateTag()` after mutations
  - Time-based: `{ next: { revalidate: 3600 } }` where appropriate
- [ ] **NXT-DATA-04** [MEDIUM] No data waterfall
  - Parallel fetches with `Promise.all()` or Suspense boundaries
  - Avoid sequential `await` in layouts that cascade to child pages
- [ ] **NXT-DATA-05** [MEDIUM] Loading and error states
  - `loading.tsx` for route-level loading states
  - `error.tsx` for error boundaries (with reset functionality)

---

## SEC — Security (5 Checks)

- [ ] **NXT-SEC-01** [CRITICAL] Environment variables separated
  - `NEXT_PUBLIC_*` for client-safe values only
  - Server-only secrets: NO `NEXT_PUBLIC_` prefix
  - Verify with `grep -rn 'NEXT_PUBLIC_' .env*`
- [ ] **NXT-SEC-02** [CRITICAL] Server Actions validated
  - All Server Action inputs validated (Zod, manual validation)
  - Authentication checked in every Server Action
  - `'use server'` only at top of files, never inside client components
- [ ] **NXT-SEC-03** [HIGH] Middleware for auth guards
  - `middleware.ts` at project root for route protection
  - Matcher config for protected routes
  - Session validation on every protected request
- [ ] **NXT-SEC-04** [HIGH] No sensitive data in client bundles
  - `import 'server-only'` on sensitive modules
  - Check bundle analyzer output for leaked modules
- [ ] **NXT-SEC-05** [MEDIUM] CSP headers configured
  - `next.config` headers or middleware CSP
  - Nonce-based script loading for inline scripts

---

## PERF — Performance (4 Checks)

- [ ] **NXT-PERF-01** [HIGH] Image optimization with `next/image`
  - `<Image>` component instead of `<img>` tags
  - `priority` on LCP image, `sizes` prop set
- [ ] **NXT-PERF-02** [HIGH] Font optimization with `next/font`
  - `next/font/google` or `next/font/local`
  - `display: 'swap'` for font loading strategy
  - Self-hosted for GDPR compliance (no Google CDN)
- [ ] **NXT-PERF-03** [MEDIUM] Dynamic imports for heavy components
  - `next/dynamic` with `{ ssr: false }` for client-only components
  - Reduces initial bundle size
- [ ] **NXT-PERF-04** [MEDIUM] Static generation where possible
  - `generateStaticParams()` for known pages
  - ISR with `revalidate` for semi-dynamic content

---

## META — Metadata & SEO (3 Checks)

- [ ] **NXT-META-01** [HIGH] Metadata API used
  - `export const metadata` or `generateMetadata()` in layouts/pages
  - Title, description, openGraph, twitter card per page
- [ ] **NXT-META-02** [MEDIUM] Sitemap and robots
  - `app/sitemap.ts` for dynamic sitemap generation
  - `app/robots.ts` for robots.txt
- [ ] **NXT-META-03** [MEDIUM] Structured data (JSON-LD)
  - Schema.org markup for relevant content types
  - Validate with Google Rich Results Test

---

## DCI — Docker/CI (4 Checks)

- [ ] **NXT-DCI-01** [HIGH] Standalone output for Docker
  - `output: 'standalone'` in `next.config`
  - Minimal Docker image with `.next/standalone` + `.next/static` + `public/`
- [ ] **NXT-DCI-02** [HIGH] Multi-stage Docker build
  - `deps` → `build` → `runner` stages
  - Final image: `node:22-alpine`, non-root user
- [ ] **NXT-DCI-03** [MEDIUM] CI pipeline correct
  - `next build` (not `next export`) for App Router
  - `next lint` in CI
- [ ] **NXT-DCI-04** [MEDIUM] `.nvmrc` with Node version
  - `node-version-file: '.nvmrc'` in GitHub Actions

---

## TOOL — Dev Tooling (3 Checks)

- [ ] **NXT-TOOL-01** [HIGH] ESLint with `next/core-web-vitals`
  - `eslint-config-next` configured
  - `next lint` passes without errors
- [ ] **NXT-TOOL-02** [MEDIUM] TypeScript strict mode
  - `strict: true` in `tsconfig.json`
  - `next.config.ts` (TypeScript config) preferred
- [ ] **NXT-TOOL-03** [MEDIUM] Prettier configured
  - `.prettierrc` with consistent formatting
  - Prettier + ESLint integration without conflicts

---

## DB — Database Integration (2 Checks)

- [ ] **NXT-DB-01** [CRITICAL] DB access only in Server Components/Actions
  - No database imports in `'use client'` components
  - Connection pooling configured (Drizzle, Prisma, etc.)
- [ ] **NXT-DB-02** [HIGH] Migrations managed
  - Migration tool configured (drizzle-kit, prisma migrate)
  - Migration scripts versioned in git

---

As of: 2026-04-04 (created for Next.js 16.2.2, React 19, App Router, Turbopack)
