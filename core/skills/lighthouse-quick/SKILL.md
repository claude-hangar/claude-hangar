---
name: lighthouse-quick
description: >
  Core Web Vitals performance check (LCP, CLS, INP).
  Use when: "lighthouse", "pagespeed", "performance", "core web vitals", "speed".
effort: low
allowed-tools: Read, Glob, Grep, Bash
user_invocable: true
argument_hint: "[url]"
---

<!-- AI-QUICK-REF
## /lighthouse-quick — Quick Reference
- **Micro-skill** — Code-based performance check, no browser tool
- **Checks:** LCP, CLS, INP, images, fonts, JS bundle, CSS
- **Output:** Findings with severity + fix suggestions
- **Not real Lighthouse** — Static code analysis of performance patterns
- **Recommended:** Before launch, after major UI changes
-->

# /lighthouse-quick — Performance Quick Check

Static code analysis of the most common performance issues.
Not real Lighthouse — checks patterns in code that affect Core Web Vitals.

## Check Catalog

### LCP (Largest Contentful Paint)

| # | Check | What to look for |
|---|-------|-----------------|
| 1 | Hero image optimized? | `<img>` in above-the-fold: `loading="eager"`, `fetchpriority="high"` |
| 2 | Preload for critical assets? | `<link rel="preload">` for hero image, critical fonts |
| 3 | Server response time? | No blocking redirects, no chain loading |
| 4 | Modern image formats? | WebP/AVIF instead of PNG/JPG (Astro: `<Image>` component) |

### CLS (Cumulative Layout Shift)

| # | Check | What to look for |
|---|-------|-----------------|
| 5 | Images with width/height? | All `<img>` need explicit dimensions |
| 6 | Font display? | `font-display: swap` or `optional` |
| 7 | Dynamic content? | Ads, embeds, lazy content without placeholders |
| 8 | CSS animations? | `transform` instead of `top/left/width/height` |

### INP (Interaction to Next Paint)

| # | Check | What to look for |
|---|-------|-----------------|
| 9 | Heavy event handlers? | `click`/`input` handlers with >50ms work |
| 10 | Main thread blocking? | Synchronous loops, DOM manipulation in batches |
| 11 | Debouncing? | Input/scroll handlers without debounce/throttle |

### Assets & Bundle

| # | Check | What to look for |
|---|-------|-----------------|
| 12 | JS bundle size? | Single bundles >200KB (uncompressed) |
| 13 | Tree shaking? | Barrel imports (`import * from`), unused dependencies |
| 14 | CSS unused? | Large CSS files without PurgeCSS/Tailwind |
| 15 | Lazy loading? | Below-the-fold images without `loading="lazy"` |
| 16 | Compression? | Gzip/Brotli in server config or build |

### Fonts

| # | Check | What to look for |
|---|-------|-----------------|
| 17 | Self-hosted? | No Google Fonts CDN links (GDPR!) |
| 18 | Subset? | Font files >100KB? -> Recommend subsetting |
| 19 | Formats? | WOFF2 as primary format |
| 20 | Preload? | Critical fonts via `<link rel="preload">` |
| 21 | FOUT with view transitions? | Font flash during ClientRouter navigation (Astro) |

### View Transitions / ClientRouter

| # | Check | What to look for |
|---|-------|-----------------|
| 22 | FOUT during navigation? | Font flash with ClientRouter SPA navigation (Astro 5.18+/6 beta.16 fixed, check older versions) |
| 23 | fetchpriority on hero? | `<Image fetchpriority="high">` for LCP-critical images (Astro 6 beta.16+) |

## Procedure

1. Find layout/base template -> analyze `<head>`
2. Search components/pages for `<img>`, `<script>`, font references
3. Check build config (vite.config, astro.config, etc.)
4. Output findings with severity (HIGH/MEDIUM/LOW)
5. Fix suggestions per finding

## Output Format

```
Performance Quick Check — {Project}
====================================

[HIGH] LCP: Hero image without fetchpriority="high"
       -> <img src="hero.jpg" fetchpriority="high" loading="eager">

[HIGH] FONTS: Google Fonts via CDN (GDPR violation)
       -> Use self-hosted fonts

[MED]  CLS: 3 images without width/height
       -> Set explicit dimensions

[LOW]  ASSETS: 2 below-fold images without lazy loading
       -> Add loading="lazy"

Result: 4 findings (2 HIGH, 1 MED, 1 LOW)
```

## Structured Output (Optional)

When called in the context of `/polish` or `/audit`, additionally write/extend `.micro-check-results.json`:

```json
{
  "lighthouseQuick": {
    "date": "YYYY-MM-DD",
    "checks": [
      { "id": "PERF-Q01", "name": "hero-fetchpriority", "status": "ok|missing", "severity": "HIGH" },
      { "id": "PERF-Q02", "name": "preload-critical", "status": "ok|missing", "severity": "MEDIUM" },
      { "id": "PERF-Q03", "name": "image-formats", "status": "ok|outdated", "severity": "MEDIUM" },
      { "id": "PERF-Q04", "name": "img-dimensions", "status": "ok|missing", "severity": "HIGH" },
      { "id": "PERF-Q05", "name": "font-display", "status": "ok|missing", "severity": "MEDIUM" },
      { "id": "PERF-Q06", "name": "font-self-hosted", "status": "ok|cdn", "severity": "HIGH" },
      { "id": "PERF-Q07", "name": "lazy-loading", "status": "ok|missing", "severity": "LOW" },
      { "id": "PERF-Q08", "name": "js-bundle-size", "status": "ok|too-large", "severity": "MEDIUM" }
    ],
    "summary": { "ok": 6, "issues": 2 }
  }
}
```

**Rule:** Only write when explicitly in the context of a parent skill. For standalone calls, text output only.

## Rules

- Read-only — does not modify files except optional .micro-check-results.json
- Not real Lighthouse — purely static code analysis
- GDPR check (fonts) is always included
- For Astro: recommend `<Image>` component instead of `<img>`

## Upstream Reference

Real Lighthouse is at version **13.1.0** (minor update from 13.0.3). This is a minor release with potential scoring refinements — no major audit category changes expected. If users ask about Lighthouse score discrepancies, consider whether they upgraded between runs.

As of: 2026-04-09
