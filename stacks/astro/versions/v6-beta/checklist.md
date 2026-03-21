# Astro 5 -> 6 Migration Checklist

74 checkpoints in 21 areas. Severity: CRITICAL > HIGH > MEDIUM > LOW.
Finding prefix: `MIG-NN`

**Status:** Astro 6.0 Stable since March 10, 2026. This checklist is the definitive migration guide from Astro 5.x to 6.x.
For best practices on already-migrated projects -> `v6-stable/checklist.md`.

---

## ENV — Environment (3 Checks, Top: CRITICAL)

- [ ] **ENV-01** [CRITICAL] Node.js >= 22.12.0 on all environments (local, CI/CD, Docker, VPS)
  - Astro 6 dropped Node 18 + Node 20 completely
  - Check `node --version`, create `.nvmrc` with `24` (Maintenance LTS, Minimum: 22.12.0)
  - -> PR #14427
  - Note: From October 2026, Node.js switches to annual releases (every version becomes LTS)
- [ ] **ENV-02** [HIGH] .nvmrc updated to `24`
  - v24 = Maintenance LTS (support until April 2028), v22 = EOL
- [ ] **ENV-03** [MEDIUM] Hosting platform supports Node 24
  - Check VPS, Docker images, CI/CD runners

---

## CFG — Configuration (6 Checks, Top: CRITICAL)

- [ ] **CFG-01** [CRITICAL] Config file is ESM (.mjs or .ts), not .cjs
  - Vite 7 no longer supports CommonJS
  - -> PR #14445
- [ ] **CFG-02** [CRITICAL] Vite plugins compatible with Vite 7
  - Check all plugins in `vite.plugins`
  - Follow Vite 7 Migration Guide
- [ ] **CFG-03** [HIGH] Vitest v3.2 if `getViteConfig()` is used
  - Older Vitest versions incompatible with Vite 7
- [ ] **CFG-04** [HIGH] `i18n.routing.redirectToDefaultLocale` explicitly set
  - Default changed: `true` -> `false`
  - If i18n is used: explicitly set to `true` for previous behavior
- [ ] **CFG-05** [MEDIUM] `security.csp` instead of `experimental.csp`
  - CSP is now stable, remove experimental flag
- [ ] **CFG-06** [MEDIUM] `fonts` instead of `experimental.fonts`
  - Fonts API is now stable, remove experimental flag

---

## CODE — Code Cleanup / Removed APIs (6 Checks, Top: CRITICAL)

- [ ] **CODE-01** [CRITICAL] No `Astro.glob()` — replaced by `import.meta.glob()`
  - Alternatively: use Content Collections
  - -> `import.meta.glob()` is the direct replacement
- [ ] **CODE-02** [CRITICAL] No `<ViewTransitions />` — replaced by `<ClientRouter />`
  - Change import: `astro:transitions` stays, rename component
- [ ] **CODE-03** [CRITICAL] No `emitESMImage()` — completely removed
  - Adapt custom image service if used
- [ ] **CODE-04** [HIGH] No `handleForms` prop on `<ClientRouter />`
  - Was removed, forms now work by default
- [ ] **CODE-05** [HIGH] All `getStaticPaths()` params return strings
  - Numbers are no longer automatically converted
  - Use `.toString()` or template literals
- [ ] **CODE-06** [CRITICAL] `import.meta.env` checked — no server secrets in client bundles
  - Values are now ALWAYS inlined
  - Check all `import.meta.env.SECRET_*` usage

---

## COLL — Content Collections (5 Checks, Top: CRITICAL)

- [ ] **COLL-01** [CRITICAL] No legacy Content Collections (Astro v2 API)
  - `legacy.collections` flag no longer exists
  - Migration to Content Layer API with loaders is mandatory
- [ ] **COLL-02** [CRITICAL] All collections use Content Layer API with loaders
  - `glob()` or `file()` loader instead of direct file access
- [ ] **COLL-03** [CRITICAL] Zod schemas checked for Zod 4
  - Community codemod available for Zod 3->4
  - -> PR #14956
- [ ] **COLL-04** [HIGH] Zod import from `astro/zod` (not direct `zod` package)
  - Ensures compatibility with Astro's bundled Zod
- [ ] **COLL-05** [HIGH] Schema functions updated to `createSchema()`
  - If custom schema helpers are used

---

## ADPT — Adapter (4 Checks, Top: CRITICAL)

- [ ] **ADPT-01** [CRITICAL] Adapter updated to v6-compatible version
  - `@astrojs/node`, `@astrojs/cloudflare`, etc.
  - Check versions with `npm view @astrojs/node versions --json`
- [ ] **ADPT-02** [HIGH] Cloudflare: `Astro.locals.runtime` replaced by `cloudflare:workers`
  - Only relevant for Cloudflare projects
- [ ] **ADPT-03** [MEDIUM] `experimentalStaticHeaders` renamed to `staticHeaders`
  - Stable since beta.8
- [ ] **ADPT-04** [MEDIUM] Session driver config checked
  - Adapters now provide defaults, explicit config only needed when necessary

---

## MDLK — Markdown & Links (4 Checks, Top: HIGH)

- [ ] **MDLK-01** [HIGH] Internal anchor links to markdown headings tested
  - ID generation changed in Astro 6
  - Manually check all `#heading-id` links
- [ ] **MDLK-02** [HIGH] `<script>` and `<style>` tag order checked
  - Order may change in Astro 6
- [ ] **MDLK-03** [MEDIUM] No routes with percent-encoded percent signs (`%25`)
  - Handling changed, can lead to 404
- [ ] **MDLK-04** [MEDIUM] Endpoints with file extensions do not use trailing slash
  - e.g., `/api/feed.xml` instead of `/api/feed.xml/`

---

## IMG — Images (3 Checks, Top: HIGH)

- [ ] **IMG-01** [HIGH] Image cropping behavior checked
  - Cropping is now default behavior
  - Check images with unexpected proportions
- [ ] **IMG-02** [HIGH] No image upscaling
  - Astro 6 no longer supports upscaling
  - Check images smaller than the desired size
- [ ] **IMG-03** [MEDIUM] SVG-to-raster conversion tested
  - If SVGs are processed with Sharp
  - New rasterization logic since beta.11

---

## TOOL — Tooling (3 Checks, Top: MEDIUM)

- [ ] **TOOL-01** [MEDIUM] VS Code Extension updated to latest version
  - Astro 6 support in latest extension
- [ ] **TOOL-02** [MEDIUM] `@astrojs/check` updated
  - Ensure compatibility with Astro 6
- [ ] **TOOL-03** [MEDIUM] `@astrojs/language-server` updated
  - Improved TypeScript integration for v6
- [ ] **TOOL-04** [HIGH] Shiki updated to v4 (beta.18)
  - `@astrojs/markdown-remark` requires Shiki v4
  - Check custom Shiki themes and transformers for v4 compatibility

---

## VITE — Vite 7 (3 Checks, Top: CRITICAL)

- [ ] **VITE-01** [CRITICAL] All Vite plugins checked for Vite 7 compatibility
  - Plugin API changes apply
  - -> PR #14445, Vite 7 Migration Guide
- [ ] **VITE-02** [CRITICAL] No CommonJS config files (.cjs)
  - Vite 7 only supports ESM
  - `vite.config.cjs` -> `vite.config.ts` or `.mjs`
- [ ] **VITE-03** [HIGH] Vite Environment API changes noted
  - Dev Server now uses completely new runtime
  - Check custom middleware/plugins

---

## ZOD — Zod 4 (4 Checks, Top: CRITICAL)

- [ ] **ZOD-01** [CRITICAL] Zod import via `astro/zod` (not directly `zod`)
  - Astro bundles Zod 4, direct import can cause version conflicts
  - -> PR #14956
- [ ] **ZOD-02** [CRITICAL] All Content Collection schemas checked for Zod 4 syntax
  - Check `z.object()`, `z.string()` etc. API changes
  - Use community codemod when available
- [ ] **ZOD-03** [HIGH] Custom Zod schemas (outside Collections) checked
  - Form validation, API input schemas, etc.
- [ ] **ZOD-04** [MEDIUM] Zod error message format checked
  - Zod 4 has changed error format

---

## NEW — New Features / Optional (4 Checks, Top: LOW)

- [ ] **NEW-01** [LOW] Evaluate Live Content Collections
  - CMS/API/DB data without rebuild — relevant for dynamic content
- [ ] **NEW-02** [LOW] Evaluate Fonts API
  - Google, Fontsource, Bunny, Local with auto-optimization
  - Privacy benefit: Self-hosted fonts automatically
- [ ] **NEW-03** [LOW] Evaluate CSP (Content Security Policy)
  - Automatic script/style hashing
  - Useful for security hardening
- [ ] **NEW-04** [LOW] Use Dev Server improvements
  - Vite Environment API, same runtime in dev + prod
  - Cloudflare workerd in `astro dev`

---

## CSP — Content Security Policy (3 Checks, Top: HIGH)

- [ ] **CSP-01** [MEDIUM] `security.csp` instead of `experimental.csp` in config
  - CSP has been stable since beta.2
- [ ] **CSP-02** [MEDIUM] `Astro.csp?.insertDirective` with optional chaining
  - CSP is optional, without optional chaining runtime errors possible
- [ ] **CSP-03** [HIGH] Shiki code block styles checked after beta.13
  - Styles are now generated at build-time instead of inline (CSP-compatible)
  - Test custom CSS for code blocks and syntax highlighting
  - -> PR #15451

---

## FONT — Fonts API / Optional (3 Checks, Top: LOW)

- [ ] **FONT-01** [LOW] `fonts` instead of `experimental.fonts` in config
  - Fonts API has been stable since beta.6
- [ ] **FONT-02** [LOW] Evaluate font providers
  - Google, Fontsource, Bunny, Local, **npm** (new in beta.13) available
  - Privacy: Prefer Fontsource, Local, or npm
- [ ] **FONT-03** [LOW] Evaluate `npm` font provider (beta.13)
  - `fontProviders.npm()` for fonts from NPM packages (local or CDN)
  - -> PR #15529

---

## DCI — Docker/CI (3 Checks, Top: CRITICAL)

- [ ] **DCI-01** [CRITICAL] Dockerfile base image updated to Node 24
  - `FROM node:24-alpine` or `FROM node:24-slim`
  - Check all build stages
- [ ] **DCI-02** [CRITICAL] CI/CD pipeline Node version updated
  - GitHub Actions: `node-version-file: '.nvmrc'` (recommended) or `node-version: '24'`
  - Other CI: `.tool-versions`, `Dockerfile`, etc.
- [ ] **DCI-03** [HIGH] Docker multi-stage build optimized for Astro 6
  - Check build dependencies, cache layers
  - Vite 7 build output structure may change

---

## MWARE — Middleware/Adapter (2 Checks, Top: HIGH) — NEW from beta.17

- [ ] **MWARE-01** [HIGH] `edgeMiddleware` -> `middlewareMode` migrated
  - Adapter option renamed: `edgeMiddleware: true` -> `middlewareMode: 'edge'`
  - Affects custom adapters and explicit adapter configurations
  - Standard adapters (@astrojs/node, @astrojs/cloudflare) are automatically updated
- [ ] **MWARE-02** [MEDIUM] `actionBodySizeLimit` configured (if large form uploads)
  - New config option for server action payload sizes
  - Default: `"1MB"` — sufficient for normal forms
  - For file uploads via actions: increase explicitly (`"5MB"`, `"10MB"`)
  - ```javascript
    // astro.config.mjs — only when needed:
    export default defineConfig({
      server: { actionBodySizeLimit: '5MB' }
    });
    ```

---

## PERF — Performance (2 Checks, Top: LOW) — NEW from beta.16

- [ ] **PERF-01** [LOW] Use `fetchpriority="high"` on hero images
  - `<Image>` and `<Picture>` natively support `fetchpriority`
  - LCP optimization: Hero image with `fetchpriority="high"` + `loading="eager"`
- [ ] **PERF-02** [LOW] Font flash during ClientRouter navigation tested
  - FOUT (Flash of Unstyled Text) during view transitions was a known issue
  - Fixed in beta.16 — but test whether custom font setups work correctly
  - Especially relevant with `<ClientRouter />` + self-hosted fonts

---

## TSCONF — TypeScript Config (2 Checks, Top: HIGH) — NEW from beta.18

- [ ] **TSCONF-01** [HIGH] TypeScript configuration adapted to v6 structure
  - beta.18 changes the TypeScript config structure
  - Follow [v6 Upgrade Guidance](https://v6.docs.astro.build/en/guides/upgrade-to/v6/#changed-typescript-configuration)
  - -> PR #15668
- [ ] **TSCONF-02** [MEDIUM] `tsconfig.json` extends path updated
  - If `extends: "astro/tsconfigs/..."` is used — check if path still works

---

## SECFIX — Security Hardening (4 Checks, Top: HIGH) — NEW from beta.18/19

- [ ] **SECFIX-01** [HIGH] `allowedDomains` configured when behind reverse proxy
  - `X-Forwarded-For` is now only accepted with `allowedDomains`
  - Without match: Fallback to socket remote address — can change `clientAddress`
  - -> PR #15742
- [ ] **SECFIX-02** [MEDIUM] No assumptions about URL path normalization
  - Multiple leading slashes (`//admin`) are now normalized
  - Middleware pathname checks work more consistently
  - -> PR #15717
- [ ] **SECFIX-03** [MEDIUM] Dev Server tested behind corporate proxy
  - Sec-Fetch metadata validation can block cross-origin dev requests
  - Relevant for proxy-based setups (e.g., corporate firewall)
  - -> PR #15756
- [ ] **SECFIX-04** [LOW] Redirect configurations checked
  - Catch-all parameters in redirects no longer produce protocol-relative URLs
  - -> PR #15743

---

## RCACHE — Route Caching (2 Checks, Top: LOW) — NEW from beta.18

- [ ] **RCACHE-01** [LOW] Evaluate experimental Route Caching API
  - `experimental.routeCaching` for platform-agnostic response caching
  - Relevant for SSR projects with high traffic
  - Adapters must support route caching
- [ ] **RCACHE-02** [LOW] Evaluate `preserveBuildClientDir` adapter option
  - Prevents deletion of client build directory with static+SSR mix
  - Relevant for projects with separate static asset handling

---

## ASSET — Assets / getImage (2 Checks, Top: CRITICAL) — NEW from beta.20

- [ ] **ASSET-01** [CRITICAL] `getImage()` only called server-side
  - beta.20: `getImage()` from `astro:assets` throws error when called on client
  - Check all usage in client scripts, React/Vue/Svelte components
  - Migration: Server-side image processing or `<Image>` component
  - -> PR #15424, [v6 Upgrade Guidance](https://v6.docs.astro.build/en/guides/upgrade-to/v6/#changed-getimage-throws-when-called-on-the-client)
- [ ] **ASSET-02** [MEDIUM] `@astrojs/node` `bodySizeLimit` configured (if large uploads)
  - New server-side body size limit for Node standalone server
  - Default: 1 GB — only change for special requirements
  - -> PR #15759

---

## SISLAND — Server Islands (2 Checks, Top: MEDIUM) — NEW from beta.20

- [ ] **SISLAND-01** [MEDIUM] `security.serverIslandBodySizeLimit` configured (if server islands used)
  - POST endpoints for server islands now have body size limit
  - Default: 1 MB (`1048576` bytes), configurable in `astro.config.*`
  - Requests over limit are rejected with 413
  - -> PR #15755
- [ ] **SISLAND-02** [LOW] Server island framing headers checked
  - Error page rendering no longer passes original response framing headers
  - Relevant for custom error pages with server islands
  - -> PR #15776

---

## SECFIX2 — Security Hardening beta.20 (2 Checks, Top: HIGH) — NEW

- [ ] **SECFIX2-01** [HIGH] `vite.envPrefix` checked against `env.schema` secrets
  - beta.20: Astro throws error if `envPrefix` matches an `access: "secret"` variable
  - Critical with custom `envPrefix` in `vite` config
  - -> PR #15780
- [ ] **SECFIX2-02** [MEDIUM] Cookie parsing and URL normalization tested
  - Null-prototype cookie parsing + backslash URL normalization
  - Usually transparent, but check custom middleware
  - -> PR #15768, PR #15757

---

As of: 2026-03-11 (Astro 6.0 Stable — definitive 5->6 migration guide. All beta.0-beta.20 breaking changes included)
