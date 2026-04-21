# Astro 6 Beta — Changelog

Chronological overview of all beta releases with the most important changes.
Source: [Astro CHANGELOG.md](https://github.com/withastro/astro/blob/main/packages/astro/CHANGELOG.md)

---

## beta.0 — Initial Release

- First beta release of Astro 6
- Node 18 + 20 dropped -> Node 22 minimum
- Legacy Content Collections removed (Astro v2 API)
- Backwards-compat flag `legacy.collections` removed
- `Astro.glob()` removed -> `import.meta.glob()`
- `<ViewTransitions />` removed -> `<ClientRouter />`
- `emitESMImage()` removed
- `import.meta.env` values are always inlined
- Markdown heading ID generation changed
- `getStaticPaths()` params must be strings
- `i18n.routing.redirectToDefaultLocale` default: `true` -> `false`
- -> PR #14427 (Node 22), PR #14445 (Vite 7)

## beta.2

- CSP (Content Security Policy) now optional (no longer automatic)
- Session defaults — adapters provide default driver
- CommonJS config support removed (ESM only)
- Styles fix for SSR projects
- `handleForms` prop on `<ClientRouter />` removed

## beta.3

- Shiki highlighter caching — significantly faster Markdown processing
- Performance improvements in build

## beta.4

- Cloudflare styles fix
- Dev Server security fix
- Minor bugfixes

## beta.5

- CSS fix for SSR + prerender mix
- Projects with mixed output (static + server) worked correctly again

## beta.6

- **Fonts API stable** — `experimental.fonts` -> `fonts`
  - Google, Fontsource, Bunny, Local provider
  - Automatic optimization + self-hosting
- Frontmatter parsing improved
- `renderMarkdown` API changes

## beta.7

- Cloudflare `worker-configuration.d.ts` auto-generation
- Live Loader: collection name now available in loader context
- Bugfixes for Content Collections

## beta.8

- **Static Headers stable** — `experimentalStaticHeaders` -> `staticHeaders`
- CSS cleanup in production builds
- `<Picture />` component fix

## beta.9

- CSP Dev Server fix — CSP now works correctly in dev mode
- Adapter type improvements
- TypeScript improvements

## beta.10

- Custom Prerenderer API
- `emitClientAsset()` — programmatically emit client assets
- `getRemoteSize()` — retrieve remote image dimensions
- CLI security fix

## beta.11

- **New Adapter API** — fundamentally redesigned adapter interface
- SVG rasterization — SVGs can now be converted to raster formats
- Race condition fix in parallel builds
- Image cropping now default behavior

## beta.12

- **Vite 7** — major upgrade of the build engine
  - -> PR #14445
  - No more CommonJS support
  - Plugin API changes
- `loadManifest()` and `loadApp()` deprecated
- CLI styling overhaul
- **Responsive Images + CSP** — now work together
- Zod 4 integration (-> PR #14956)

## beta.13

- **[BREAKING] Shiki code block styles CSP-compatible** — styles are emitted differently
  - Instead of inline styles, styles are generated at build-time (hashable for CSP)
  - Check custom CSS for Shiki blocks
  - -> PR #15451
- **`npm` font provider** — new built-in provider for fonts from NPM packages
  - `fontProviders.npm()` for local or CDN-based fonts
  - -> PR #15529
- **`embeddedLangs` prop for `<Code />`** — embedded languages highlight correctly
  - e.g., TSX within `.vue` files
  - -> PR #15548
- **`streaming` option for `createApp()`** — HTML streaming can be disabled
  - Relevant for adapters that need non-streamed HTML caching
  - -> PR #15483
- `hidden="until-found"` attribute is correctly preserved (-> PR #15542)
- SSR renderers are no longer bundled for API-only projects (-> PR #15507)
- CSP dev warnings only in production (-> PR #15459)
- `@astrojs/markdown-remark` to v7.0.0-beta.7

## beta.14

- Route cache cleared on content changes — slug-based pages in dev mode now update correctly (-> PR #15573)
- X-Forwarded-Proto validation fix — protocol check with `allowedDomains` corrected (-> PR #15560)
- Build warnings with official adapters fixed — unnecessary warnings removed (-> PR #15563)
- Pure bugfix release, no breaking changes

## beta.15

- **Experimental `queuedRendering`** — queue-based rendering engine (two-pass), significantly faster and more memory-efficient for large projects (poolSize, contentCache)
- **Experimental `rustCompiler`** — Rust-based Astro compiler, faster compilation, better error messages, stricter with invalid HTML
- **SSR rendering up to 2x faster** — performance optimization in server rendering
- Fix: Font flash during ClientRouter navigation fixed
- Fix: Cloudflare Vite plugin compatibility
- Fix: Server Action body size limit implemented
- Fix: Build error with projects having many static routes fixed
- Fix: Image optimization for SSR builds corrected
- **[BREAKING]** Types for deprecated `astro:ssr-manifest` module removed
- **Note:** `rustCompiler` is stricter than the previous Go-based compiler — existing invalid HTML might throw errors

## beta.16

- **fetchpriority support** — `<Image>` and `<Picture>` components natively support `fetchpriority` attribute
  - `fetchpriority="high"` for hero images (LCP optimization)
  - No manual `<img>` needed for priority hints
- **SVG deadlock fix** — race condition in parallel SVG processing during build fixed
  - Large projects with many SVGs could hang during build
- **cssesc dependency removed** — internal CSS escaping logic replaces external dependency
  - Smaller bundle, less supply-chain risk
- **Font flash with ClientRouter fixed** — FOUT (Flash of Unstyled Text) during view transitions navigation fixed
  - Fonts are now correctly preserved during SPA navigation
  - Relevant for projects with ClientRouter + custom fonts

## beta.17

- **[BREAKING] `middlewareMode` replaces `edgeMiddleware`** — adapter API change
  - `edgeMiddleware` option in adapters becomes `middlewareMode`
  - Migration: `edgeMiddleware: true` -> `middlewareMode: 'edge'`
  - Affects custom adapters and adapter configurations
- **`actionBodySizeLimit` config** — new configuration option for server action payload sizes
  - Default: `"1MB"`, configurable in `astro.config.*`
  - Relevant for forms with large file uploads via actions
  - ```javascript
    // astro.config.mjs
    export default defineConfig({
      server: { actionBodySizeLimit: '5MB' }
    });
    ```
- Bugfixes for Content Collections with Zod 4

## beta.18

- **[BREAKING] TypeScript configuration changed** — new TS config structure
  - Follow v6 upgrade guidance
  - -> PR #15668
- **Shiki v4** — major update of the syntax highlighting engine
  - `@astrojs/markdown-remark` requires Shiki v4
  - Check custom Shiki themes and transformers for v4 compatibility
  - -> PR #15726, [Shiki v4 Upgrade Guide](https://shiki.style/blog/v4)
- **`preserveBuildClientDir` adapter option** — adapters can preserve client/server directory structure for static builds
  - `adapterFeatures: { buildOutput: 'static', preserveBuildClientDir: true }`
  - Relevant for platforms with special file structure requirements
  - -> PR #15694
- **Experimental Route Caching API** — platform-agnostic SSR response caching
  - `experimental.cache` with cache provider (e.g., `memoryCache()`)
  - `experimental.routeRules` for declarative cache rules (Nitro-style shortcuts)
  - `Astro.cache.set()` / `context.cache.set()` for per-route caching
  - Tag-based and path-based invalidation
  - Built-in memory LRU cache provider with SWR support
  - -> PR #15579, [Route Caching RFC](https://github.com/withastro/roadmap/pull/1245)
- **[SECURITY] X-Forwarded-For validation** — `clientAddress` now respects `allowedDomains`
  - Without match: Fallback to socket remote address
  - -> PR #15742
- **[SECURITY] URL normalization** — multiple leading slashes (`//admin`) are normalized
  - Middleware pathname checks now work consistently
  - -> PR #15717
- **[SECURITY] Action route hardening** — 404 for prototype method names (`constructor`, `toString`)
  - -> PR #15721
- **[SECURITY] Redirect hardening** — prevents protocol-relative URLs in Location header
  - -> PR #15743
- **[SECURITY] Attribute escaping** — consistent escaping for URL values with `&`
  - -> PR #15740
- **[SECURITY] Internal header leak fix** — internal headers no longer exposed on error pages
  - -> PR #15718
- Fix: `session.regenerate()` lost session data under new ID (-> PR #15749)
- Fix: Session cookie without server-side data now generates new ID (-> PR #15752)
- Fix: i18n fallback middleware incorrectly intercepted 3xx/403/5xx responses (-> PR #15704)
- Fix: SVG images in Content Collection `image()` fields can be rendered as inline components again (-> PR #15685)
- Fix: Server Islands 500 error in dev mode with adapters without `buildOutput` (-> PR #15703)
- Fix: MDX images with Cloudflare adapter (-> PR #15696)
- Fix: Cookie handling during error page rendering (-> PR #15744)
- Fix: Docs links updated to v6 structure (-> PR #15693)
- `@astrojs/markdown-remark` to v7.0.0-beta.9

## beta.19

- Fix: Queued Rendering — saved nodes are correctly reused (-> PR #15760)
- Fix: View Transition persisted elements — WebGL context loss in Safari, CSS transition/iFrame resets in Chromium/Firefox avoided (-> PR #15728)
- **[SECURITY] Dev Server Sec-Fetch hardening** — validation of Sec-Fetch metadata headers against cross-origin subresource requests (-> PR #15756)
- Fix: Dev Server leading slash on some requests (-> PR #15414)
- `@astrojs/markdown-remark` to v7.0.0-beta.10

## beta.20

- **[BREAKING] `getImage()` throws on client** — `getImage()` from `astro:assets` now throws error when called on the client
  - Only use server-side, not in client scripts or framework components
  - [v6 Upgrade Guidance](https://v6.docs.astro.build/en/guides/upgrade-to/v6/#changed-getimage-throws-when-called-on-the-client)
  - -> PR #15424
- **`clientAddress` in `createContext()`** — new option for adapters/middleware
  - Gives adapter authors explicit control over client IP
  - Official Netlify/Vercel adapters already use this
  - -> PR #15781
- **`security.serverIslandBodySizeLimit` config** — body size limit for server island POST endpoints
  - Default: `1048576` (1 MB), configurable independently from `actionBodySizeLimit`
  - Requests over limit are rejected with 413
  - -> PR #15755
- **`@astrojs/node` `bodySizeLimit` option** — maximum request body size for Node standalone server
  - Default: 1 GB, configurable in bytes or `0` to disable
  - -> PR #15759
- **[SECURITY] envPrefix leak prevention** — `vite.envPrefix` misconfiguration can no longer expose `access: "secret"` env variables in client bundles
  - Astro throws clear error at startup if `envPrefix` matches a secret
  - -> PR #15780
- **[SECURITY] clientAddress injection fix** — `clientAddress` is now validated (only IP-valid characters)
  - Multiple values in a single header are handled correctly
  - -> PR #15778
- **[SECURITY] Error page framing header hardening** — framing headers from original response are no longer passed to error pages
  - -> PR #15776
- **[SECURITY] Cookie parsing hardening** — null-prototype object for fallback cookie parsing
  - -> PR #15768
- **[SECURITY] URL pathname backslash normalization** — backslash characters after decoding are consistently normalized
  - Middleware and router see identical canonical pathnames
  - -> PR #15757
- **[SECURITY] CSRF origin port fix** — correct port passing to `createRequest` fixes origin mismatch
  - `X-Forwarded-Proto` only trusted with `allowedDomains`
  - -> PR #15777
- Fix: TSConfig templates reverted — beta.18 TS config changes rolled back (-> PR #15788)
- Fix: Form actions no longer auto-executed during error page rendering (-> PR #15764)
- Fix: `experimental.queuedRendering.poolSize` can now be set to `0` (-> PR #15761)
- Fix: `astro info` clipboard support for more operating systems (-> PR #15712)
- `@astrojs/internal-helpers` to v0.8.0-beta.3
- `@astrojs/markdown-remark` to v7.0.0-beta.11

---

## 6.0.0 Stable — March 10, 2026

**Astro 6 is officially stable!** All beta changes (beta.0 through beta.20) are included.

Highlights from the release blog:
- **Fonts API** — built-in font optimization with Google, Fontsource, Bunny, Local, npm providers
- **Content Security Policy** — `security.csp` for automatic script/style hashing
- **Live Content Collections** — externally hosted content without rebuild
- **Redesigned Dev Server** — Vite Environment API, production runtime in dev mode
- **Experimental Rust Compiler** — successor to the Go-based .astro compiler
- **Responsive Images** — `layout` attribute for automatic `srcset` + `sizes`
- **Route Caching** (experimental) — platform-agnostic SSR response caching

No additional breaking changes compared to beta.20.

Patch releases:
- **6.0.1** — First bugfixes after stable release
- **6.0.2** — Further stabilization
- **6.0.3** — Additional fixes
- **6.0.4** — i18n redirect fix, server islands in prerendered pages, CSS missing on new pages, dev toolbar prebundling, prefetch warning fix
- **6.0.5–6.0.8** — Continued stabilization and bug fixes

-> [Astro 6.0 Blog Post](https://astro.build/blog/astro-6/)
-> [Upgrade Guide](https://docs.astro.build/en/guides/upgrade-to/v6/)

---

## 6.1.0 — March 2026

-> [Astro 6.1 Blog Post](https://astro.build/blog/astro-610/)

### New Features

- **Sharp Codec-Specific Image Defaults** — `image.service.config` for global encoding settings
  - Codec-level optimization: JPEG (mozjpeg), WebP, AVIF, PNG with per-codec compression options
  - Applied to every image processed during build — no need to repeat per-image
- **Advanced SmartyPants Configuration** — `markdown.smartypants` as object
  - Per-punctuation control: French guillemets, German quotation marks, custom dash styles
  - Replaces boolean-only toggle with fine-grained localization support
- **i18n Fallback Routes for Integrations** — `fallbackRoutes` on `astro:routes:resolved` hook
  - Routes with `fallbackType: 'rewrite'` now exposed to integrations
  - Enables `@astrojs/sitemap` to include fallback pages in sitemaps

### Improvements

- **Mobile View Transitions** — client router skips animations when browsers provide native transitions (iOS Safari swipe gestures)
- **CSRF checkOrigin fix** — `X-Forwarded-Proto` correctly interpreted behind TLS-terminating reverse proxies
- React hydration fixes for conditional slot rendering and `experimentalReactChildren` mismatches

### Patch Releases

- **6.1.1** — Cloudflare adapter dev rendering fixes, additional stabilization
- **6.1.2** — Zod v4 validation error formatting (human-readable messages instead of raw JSON)
- **6.1.3** — Cloudflare adapter dev rendering, skew protection query params for rolling deployments, HMR with Cloudflare prerenderEnvironment, MDX AstroContainer HTML escaping, cross-page CSS leak, SSR "No matching renderer" without src/pages/
- **6.1.4** — Cloudflare adapter miniflare restart fix (in-place Vite restart instead of new server), React 19 Float mechanism injecting into islands instead of document, pages with dotted filenames, unused re-exports from assets/utils barrel file

---

## 6.1.5 — April 8, 2026

- Fix: `<Picture>` component build error when prerendered pages used alongside pages calling `render()` on content collection entries
- Fix: Sync content inside `<Fragment>` elements wasn't streaming to the browser until all async sibling expressions completed
- Fix: UnoCSS dev mode restored when used with client router (partial revert of Vue component styles persistence change)
- Fix: `astro add cloudflare` now sets `compatibility_date` to today's date instead of deriving from locally installed packages
- Chore: Removed `dlv` dependency from codebase

---

## 6.1.8 — April 18, 2026

- Fix: Build output files could contain special characters (`!`, `~`, `{`, `}`) in their names, causing deploy failures on platforms like Netlify (-> PR #16367)

Pure bugfix release — no breaking changes, no new features.

## 6.1.7 — April 2026

- Fix: Remote image dimensions were not validated during static builds on Netlify (-> PR #16027)
- Fix: `--port` flag was ignored after a Vite-triggered server restart (e.g. when a `.env` file changes) (-> PR #16311)
- **SECURITY Fix:** `/_image` endpoint accepted arbitrary `f=svg` query parameter and served non-SVG content as `image/svg+xml`. Now validates source is actually SVG before honoring `f=svg` (-> PR #16316)

Pure bugfix release — no breaking changes, no new features. Security fix included.

## 6.1.6 — April 2026

- Fix: Actions failed with `ActionsWithoutServerOutputError` when using `output: 'static'` together with an adapter (-> PR #16202)
- Fix: Improved handling of special characters in inline `<script>` content — previously prone to HTML escaping issues (-> PR #16303)
- Fix: SCSS and CSS module file changes triggered a full page reload instead of hot-updating styles in place during development (-> PR #14924)

Pure bugfix release — no breaking changes, no new features.

---

As of: 2026-04-21 (updated for Astro 6.1.8)
