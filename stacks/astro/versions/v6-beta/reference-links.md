# Astro 6 Beta — Reference Links

## Official Documentation

- [Astro 6 Upgrade Guide](https://v6.docs.astro.build/en/guides/upgrade-to/v6/)
- [Astro 6 Beta Blog Post](https://astro.build/blog/)
- [Astro Docs (v6)](https://v6.docs.astro.build/)
- [Astro Docs (Stable)](https://docs.astro.build/)

## Changelogs & Releases

- [Astro CHANGELOG.md](https://github.com/withastro/astro/blob/main/packages/astro/CHANGELOG.md)
- [Astro Releases](https://github.com/withastro/astro/releases)
- [Astro npm Page](https://www.npmjs.com/package/astro)

## Vite 7

- [Vite 7 Migration Guide](https://vite.dev/guide/migration)
- [Vite CHANGELOG](https://github.com/vitejs/vite/blob/main/packages/vite/CHANGELOG.md)
- [Vite Releases](https://github.com/vitejs/vite/releases)

## Zod 4

- [Zod 4 Changelog](https://github.com/colinhacks/zod/releases)
- [Zod 4 Migration Guide](https://github.com/colinhacks/zod)
- [Zod Codemod (Community)](https://github.com/colinhacks/zod) — Search for codemod in Issues/Discussions

## Important PRs (Astro)

| PR | Topic |
|----|-------|
| [#14427](https://github.com/withastro/astro/pull/14427) | Node 22 Minimum |
| [#14445](https://github.com/withastro/astro/pull/14445) | Vite 7 Integration |
| [#14956](https://github.com/withastro/astro/pull/14956) | Zod 4 Integration |
| [#15451](https://github.com/withastro/astro/pull/15451) | Shiki code block styles CSP-compatible (beta.13) |
| [#15529](https://github.com/withastro/astro/pull/15529) | npm font provider (beta.13) |
| [#15548](https://github.com/withastro/astro/pull/15548) | embeddedLangs for Code component (beta.13) |
| [#15483](https://github.com/withastro/astro/pull/15483) | streaming option for createApp (beta.13) |
| [#15573](https://github.com/withastro/astro/pull/15573) | Route cache invalidation on content changes (beta.14) |
| [#15560](https://github.com/withastro/astro/pull/15560) | X-Forwarded-Proto validation fix (beta.14) |
| [#15563](https://github.com/withastro/astro/pull/15563) | Build warnings with adapters fixed (beta.14) |
| [#15668](https://github.com/withastro/astro/pull/15668) | TypeScript configuration changed (beta.18) |
| [#15726](https://github.com/withastro/astro/pull/15726) | Shiki v4 update (beta.18) |
| [#15579](https://github.com/withastro/astro/pull/15579) | Experimental Route Caching API (beta.18) |
| [#15694](https://github.com/withastro/astro/pull/15694) | preserveBuildClientDir adapter option (beta.18) |
| [#15742](https://github.com/withastro/astro/pull/15742) | X-Forwarded-For validation with allowedDomains (beta.18) |
| [#15717](https://github.com/withastro/astro/pull/15717) | URL normalization — leading slashes (beta.18) |
| [#15721](https://github.com/withastro/astro/pull/15721) | Action route hardening (beta.18) |
| [#15740](https://github.com/withastro/astro/pull/15740) | Attribute escaping for URL values (beta.18) |
| [#15728](https://github.com/withastro/astro/pull/15728) | View transition persisted elements fix (beta.19) |
| [#15756](https://github.com/withastro/astro/pull/15756) | Dev Server Sec-Fetch metadata validation (beta.19) |
| [#15424](https://github.com/withastro/astro/pull/15424) | getImage() throws on client (beta.20, BREAKING) |
| [#15781](https://github.com/withastro/astro/pull/15781) | clientAddress in createContext() (beta.20) |
| [#15755](https://github.com/withastro/astro/pull/15755) | serverIslandBodySizeLimit config (beta.20) |
| [#15780](https://github.com/withastro/astro/pull/15780) | envPrefix secret leak prevention (beta.20, SECURITY) |
| [#15778](https://github.com/withastro/astro/pull/15778) | clientAddress injection validation (beta.20, SECURITY) |
| [#15776](https://github.com/withastro/astro/pull/15776) | Error page framing header hardening (beta.20, SECURITY) |
| [#15768](https://github.com/withastro/astro/pull/15768) | Cookie parsing null-prototype (beta.20, SECURITY) |
| [#15757](https://github.com/withastro/astro/pull/15757) | URL pathname backslash normalization (beta.20, SECURITY) |
| [#15777](https://github.com/withastro/astro/pull/15777) | CSRF origin port + X-Forwarded-Proto fix (beta.20, SECURITY) |
| [#15788](https://github.com/withastro/astro/pull/15788) | TSConfig templates revert (beta.20) |
| [#15764](https://github.com/withastro/astro/pull/15764) | Form actions error page fix (beta.20) |
| [#15761](https://github.com/withastro/astro/pull/15761) | queuedRendering poolSize=0 fix (beta.20) |
| [#15759](https://github.com/withastro/astro/pull/15759) | @astrojs/node bodySizeLimit option (beta.20) |

## Adapters

- [@astrojs/node](https://www.npmjs.com/package/@astrojs/node)
- [@astrojs/cloudflare](https://www.npmjs.com/package/@astrojs/cloudflare)
- [@astrojs/vercel](https://www.npmjs.com/package/@astrojs/vercel)
- [@astrojs/netlify](https://www.npmjs.com/package/@astrojs/netlify)

## Tooling

- [Astro VS Code Extension](https://marketplace.visualstudio.com/items?itemName=astro-build.astro-vscode)
- [@astrojs/check](https://www.npmjs.com/package/@astrojs/check)
- [@astrojs/language-server](https://www.npmjs.com/package/@astrojs/language-server)

---

## Shiki v4

- [Shiki v4 Upgrade Guide](https://shiki.style/blog/v4)
- [Shiki GitHub](https://github.com/shikijs/shiki)

## Route Caching

- [Route Caching RFC](https://github.com/withastro/roadmap/pull/1245)
- [Route Caching Docs](https://docs.astro.build/en/reference/experimental-flags/route-caching/)

---

As of: 2026-03-06 (updated for beta.20 — 14 new PRs)
