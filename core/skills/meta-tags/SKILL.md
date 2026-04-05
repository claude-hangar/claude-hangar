---
name: meta-tags
description: >
  OG/Twitter/Structured Data meta tag check.
  Use when: "meta tags", "open graph", "og tags", "twitter card", "structured data", "seo meta".
effort: low
allowed-tools: Read, Glob, Grep, Bash
user_invocable: true
argument_hint: "[url]"
---

<!-- AI-QUICK-REF
## /meta-tags — Quick Reference
- **Micro-skill** — Quick check, no workflow
- **Checks:** OG tags, Twitter Cards, Structured Data, basic meta
- **Output:** Checklist with OK/MISSING + correct markup
- **Recommended:** Before every launch, after content changes
-->

# /meta-tags — Meta Tags & Social Preview Check

Checks whether all important meta tags for SEO and social media previews are set.

## Checklist

### Basic Meta (Required)

| # | Tag | Example |
|---|-----|---------|
| 1 | `<title>` | Page title — max 60 characters |
| 2 | `<meta name="description">` | Description — max 155 characters |
| 3 | `<meta name="viewport">` | `width=device-width, initial-scale=1` |
| 4 | `<html lang="{{LANG}}">` | Language attribute |
| 5 | `<link rel="canonical">` | Canonical URL |

### Open Graph (Recommended)

| # | Tag | Note |
|---|-----|------|
| 6 | `og:title` | May differ from `<title>` |
| 7 | `og:description` | May differ from meta description |
| 8 | `og:image` | Min 1200x630px, absolute URL |
| 9 | `og:url` | Canonical URL |
| 10 | `og:type` | `website` or `article` |
| 11 | `og:site_name` | Website name |

### Twitter Card (Recommended)

| # | Tag | Note |
|---|-----|------|
| 12 | `twitter:card` | `summary_large_image` recommended |
| 13 | `twitter:title` | If different from og:title |
| 14 | `twitter:description` | If different |
| 15 | `twitter:image` | If different from og:image |

### Structured Data (Optional, SEO Boost)

| # | Check | Note |
|---|-------|------|
| 16 | JSON-LD `@type: WebSite` | On homepage |
| 17 | JSON-LD `@type: Organization` | Logo, name, URL |
| 18 | JSON-LD `@type: LocalBusiness` | For local businesses |
| 19 | JSON-LD Breadcrumb | For subpages |

## Procedure

1. Find layout/base template and read `<head>`
2. Spot-check individual pages (homepage + 1 subpage)
3. Output checklist with status per tag
4. For MISSING: provide correct markup as fix suggestion

## Fix Template (Astro)

```astro
---
const { title, description, image } = Astro.props;
const canonicalURL = new URL(Astro.url.pathname, Astro.site);
---
<title>{title}</title>
<meta name="description" content={description} />
<link rel="canonical" href={canonicalURL} />
<meta property="og:title" content={title} />
<meta property="og:description" content={description} />
<meta property="og:image" content={image || '/og-default.png'} />
<meta property="og:url" content={canonicalURL} />
<meta property="og:type" content="website" />
<meta name="twitter:card" content="summary_large_image" />
```

## Structured Output (Optional)

When called in the context of `/polish` or `/audit`, additionally write/extend `.micro-check-results.json`:

```json
{
  "metaTagsCheck": {
    "date": "YYYY-MM-DD",
    "checks": [
      { "id": "META-01", "name": "title", "status": "ok|missing|too-long", "severity": "HIGH" },
      { "id": "META-02", "name": "description", "status": "ok|missing|too-long", "severity": "HIGH" },
      { "id": "META-03", "name": "viewport", "status": "ok|missing", "severity": "HIGH" },
      { "id": "META-04", "name": "lang", "status": "ok|missing", "severity": "MEDIUM" },
      { "id": "META-05", "name": "canonical", "status": "ok|missing", "severity": "MEDIUM" },
      { "id": "META-06", "name": "og:title", "status": "ok|missing", "severity": "MEDIUM" },
      { "id": "META-07", "name": "og:description", "status": "ok|missing", "severity": "MEDIUM" },
      { "id": "META-08", "name": "og:image", "status": "ok|missing", "severity": "MEDIUM" },
      { "id": "META-09", "name": "twitter:card", "status": "ok|missing", "severity": "LOW" },
      { "id": "META-10", "name": "structured-data", "status": "ok|missing", "severity": "LOW" }
    ],
    "summary": { "ok": 7, "missing": 3 }
  }
}
```

**Rule:** Only write when explicitly in the context of a parent skill. For standalone calls, text output only.

## Rules

- Read-only — does not modify files except optional .micro-check-results.json
- Works with any web project
- OG image must be an absolute URL (not relative)
- Check length limits: title <=60, description <=155
