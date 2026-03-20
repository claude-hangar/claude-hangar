---
name: favicon-check
description: >
  Favicon/app icon completeness check.
  Use when: "favicon", "icon check", "app icon", "icons".
effort: low
allowed-tools: Read, Glob, Grep, Bash
---

<!-- AI-QUICK-REF
## /favicon-check — Quick Reference
- **Micro-skill** — Quick check, no workflow
- **Checks:** favicon.ico, apple-touch-icon, SVG, manifest, OG image
- **Output:** Checklist with OK/MISSING + fix suggestions
- **Recommended:** Before every launch, after rebranding
-->

# /favicon-check — Favicon & App Icon Check

Checks whether a web project has all important favicons and icons.

## Checklist

| # | Check | Where to look | Required |
|---|-------|---------------|----------|
| 1 | `favicon.ico` (32x32) | `/public/` or root | YES |
| 2 | `favicon.svg` (scalable) | `/public/` or root | Recommended |
| 3 | `apple-touch-icon.png` (180x180) | `/public/` or root + `<link>` in `<head>` | YES |
| 4 | `manifest.json` / `site.webmanifest` | `/public/` — icons array with 192x192 + 512x512 | Recommended |
| 5 | `<link rel="icon">` in HTML `<head>` | Layout/base template | YES |
| 6 | OG image (`og:image` meta tag) | Layout/base template | Recommended |
| 7 | Theme color meta tag | `<head>` + manifest | Recommended |

## Procedure

1. Search project root and `/public/` for icon files
2. Check HTML `<head>` in layout/base template
3. Read manifest.json (if present)
4. Output checklist with status per check
5. For MISSING: provide concrete fix suggestion

## Fix Suggestions

**favicon.ico missing:**
```html
<!-- In <head> -->
<link rel="icon" href="/favicon.ico" sizes="32x32">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
```

**apple-touch-icon missing:**
```html
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

**manifest missing:**
```json
{
  "name": "{{PROJECT_NAME}}",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ],
  "theme_color": "#ffffff",
  "background_color": "#ffffff"
}
```

## Structured Output (Optional)

When called in the context of `/polish` or `/audit`, additionally write/extend `.micro-check-results.json`:

```json
{
  "faviconCheck": {
    "date": "YYYY-MM-DD",
    "checks": [
      { "id": "FAV-01", "name": "favicon.ico", "status": "ok|missing|incomplete", "severity": "HIGH" },
      { "id": "FAV-02", "name": "favicon.svg", "status": "ok|missing", "severity": "MEDIUM" },
      { "id": "FAV-03", "name": "apple-touch-icon", "status": "ok|missing", "severity": "HIGH" },
      { "id": "FAV-04", "name": "manifest.json", "status": "ok|missing", "severity": "MEDIUM" },
      { "id": "FAV-05", "name": "link-rel-icon", "status": "ok|missing", "severity": "HIGH" },
      { "id": "FAV-06", "name": "og-image", "status": "ok|missing", "severity": "MEDIUM" },
      { "id": "FAV-07", "name": "theme-color", "status": "ok|missing", "severity": "LOW" }
    ],
    "summary": { "ok": 5, "missing": 2 }
  }
}
```

**Rule:** Only write when explicitly in the context of a parent skill. For standalone calls, text output only.

## Rules

- Read-only — does not create files except optional .micro-check-results.json
- Works with any web project (Astro, Next.js, Hugo, static)
- For Astro: check `src/layouts/` and `public/`
