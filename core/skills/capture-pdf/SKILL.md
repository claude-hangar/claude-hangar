---
name: capture-pdf
description: >
  Website-to-PDF capture (all pages + interactive states).
  Use when: "capture", "pdf", "print", "screenshot", "capture pages".
---

<!-- AI-QUICK-REF
## /capture-pdf — Quick Reference
- **Modes:** start | quick | url <url> | page <paths> | forms
- **Arguments:** `/capture-pdf $0 [$1]` e.g. `/capture-pdf quick`, `/capture-pdf url https://example.com`
- **Tech:** Playwright + pdf-lib + sharp
- **Smart Captures:** Cookie banners, forms, accordions, modals, mobile menu, lightboxes
- **Page Detection:** Sitemap → Framework routes → Crawling → Manual
- **Output:** PDFs in captures/ directory
- **Checkpoints:** [CHECKPOINT: decision] at start (options), [CHECKPOINT: manual] for Playwright install
-->

# /capture-pdf — Universal Website-to-PDF Capture

Captures any website completely as print-ready PDFs — all pages plus interactive states (cookie banners, filled forms, consent embeds, modals, accordions, lightboxes).

**Use cases:** Client presentations, sales documentation, acceptance protocols, design reviews, archiving.

## Modes

Detect the mode from user input:

- **start** → Mode 1 (Interactive: analyze project, detect pages, clarify options)
- **quick** → Mode 2 (No questions: desktop, A4, all pages, smart captures on)
- **url `<url>`** → Mode 3 (Capture external website)
- **page `<paths...>`** → Mode 4 (Only specific pages)
- **forms** → Mode 5 (Only scan and capture forms)

---

## Mode 1: `/capture-pdf start` — Interactive

### Step 1: Detect Project/URL

Prioritized detection:

1. **Running dev server:** Check `localhost:3000`, `localhost:4321` etc.
2. **package.json:** Detect framework (Astro, Next, Nuxt, etc.)
3. **Deployment URL:** From CLAUDE.md, config, or ask user
4. If nothing found → ask user for URL

### Step 2: Find Pages

Try in this order:

1. **Sitemap** — Parse `{base}/sitemap.xml` or `{base}/sitemap-index.xml`
2. **Framework Routes** — For local projects:
   - Astro: Scan `src/pages/` → derive routes
   - Next.js: Scan `app/` or `pages/`
   - Other: Scan `dist/` or build output
3. **Crawling** — Follow all internal links from start page (max 2 levels)
4. **Manual** — Ask user for URLs as fallback

**Exclude Defaults:** API routes (`/api/*`), 404 pages, admin areas (`/admin/*`, `/dashboard/*`), redirect pages, pagination (`?page=*`).

### Step 3: User Confirmation

Show found pages as list and ask:
- Pages OK? (Add/remove possible)
- Viewports? (Desktop 1920x1080 / Tablet 768x1024 / Mobile 375x812 / All)
- Format? (A4 / A3)
- Smart Captures? (Yes — recommended / Clean only / Selection)
- Adjust exclude patterns?

**Recommendation as default:** Desktop + A4 + Smart Captures on.

### Step 4: Generate Script

1. Read template from `templates/capture-script.mjs`
2. Replace placeholders:
   - `{{PROJECT_NAME}}` → Project name (from package.json, `<title>`, or directory)
   - `{{BASE_URL}}` → Base URL (with trailing slash)
   - `{{PAGES_JSON}}` → JSON array of pages `[{"path": "/", "name": "Home"}, ...]`
3. Save script as `scripts/capture-pdf.mjs` in the project
4. If `scripts/capture-pdf.mjs` already exists → ask user: overwrite or use existing?

### Step 5: Check Dependencies

The script checks itself via `ensureDeps()`:
- `playwright` → auto-install + `npx playwright install chromium`
- `pdf-lib` → auto-install
- `sharp` → auto-install

If no `package.json` in `scripts/` directory → create one.

### Step 6: Run Capture

```bash
node scripts/capture-pdf.mjs --viewport desktop --format a4
```

Progress is displayed in the terminal. Skip individual pages on errors.

### Step 7: Result

- Show PDF path: `prints/{name}-{viewport}-{date}.pdf`
- Summary: X/Y pages successful, Z smart captures
- Add `prints/` to `.gitignore` (if not already present)

---

## Mode 2: `/capture-pdf quick`

No questions. Uses defaults:
- Viewport: Desktop (1920x1080)
- Format: A4
- All pages (via sitemap/routes/crawling)
- Smart Captures: On
- Concurrency: 3

Runs steps 1-7 automatically.

---

## Mode 3: `/capture-pdf url <url>`

Capture external website. Process:
1. Validate URL + check reachability
2. Try sitemap → on error: crawling → on error: ask user
3. Confirm page list with user
4. Generate script in current project directory
5. Run capture

---

## Mode 4: `/capture-pdf page <paths...>`

Capture only specific pages. Example:
```
/capture-pdf page /contact /about /faq
```

- Smart Captures activated for these pages
- Base URL auto-detect or ask user

---

## Mode 5: `/capture-pdf forms`

Capture only forms:
1. Scan all pages
2. Keep only pages with `<form>` elements
3. Per form:
   - Clean screenshot of the page
   - Fill form with sample data → screenshot
   - Trigger client-side validation → screenshot if errors
4. Generate PDF with only the form pages

---

## Page Detection (Detail)

### Sitemap Parsing
```
GET {base}/sitemap.xml
GET {base}/sitemap-index.xml (if first returns 404)
```
- Extract `<url><loc>` elements
- Derive relative paths
- Apply excludes

### Framework Routes
| Framework | Scan Directory | Route Derivation |
|-----------|---------------|-----------------|
| Astro | `src/pages/` | `index.astro` → `/`, `contact.astro` → `/contact` |
| Next.js | `app/` or `pages/` | `page.tsx` → `/`, `about/page.tsx` → `/about` |
| Nuxt | `pages/` | `index.vue` → `/`, `about.vue` → `/about` |
| Static | `dist/` or `build/` | `*.html` files → routes |

Exclude dynamic routes (`[slug]`, `[...path]`) — these need concrete URLs.

### Crawling
- Load start page, collect all `<a href>` with same origin
- Max 2 levels deep (no infinite recursion)
- Filter duplicates, anchor links (`#`), external links

---

## Element Detection (Smart Captures)

The script analyzes each page and automatically detects interactive elements.

### Detection Selectors

**Cookie Banner:**
```
[role="dialog"], #cookie-*, .cookie-*, .consent-*, #cc-*,
[class*="cookie"], [class*="consent"], [class*="banner"],
[id*="cookie"], [id*="consent"]
```

**Forms:**
```
form:not([data-no-capture]):not([role="search"]),
form:has(textarea), form:has(input[type="email"])
```
Type detection: Contact, application, newsletter, login, search (search is ignored).

**Consent Embeds:**
```
iframe[src*="google.com/maps"], [data-src*="youtube"],
[data-src*="instagram"], .consent-placeholder,
[class*="embed-consent"], [class*="external-content"]
```
Two states: (1) consent placeholder, (2) after consent with active embed.

**Accordions/Tabs:**
```
details, [role="tablist"], [data-accordion],
[class*="accordion"], [class*="collapse"], [class*="faq"],
[class*="expandable"]
```

**Modals/Dialogs:**
```
dialog, [role="dialog"]:not([class*="cookie"]):not([class*="consent"]),
[data-modal], [class*="modal"]:not([class*="cookie"])
```
Triggers: Buttons with `data-modal`, `aria-controls`, `data-dialog`.

**Mobile Menu:**
```
[popover], .mobile-menu, #mobile-nav, button[aria-expanded],
.hamburger, [class*="mobile-menu"], [class*="nav-toggle"]
```
Only capture at mobile viewport.

**Lightboxes:**
```
[data-lightbox], [data-fancybox], [data-gallery],
a[href$=".jpg"] > img, a[href$=".webp"] > img,
[class*="gallery"] a > img
```

---

## Form Sample Data

Load default data from `config/form-data.json`. Field mapping by heuristic:

| Field Type | Detection (name/id/placeholder/label) | Sample Data |
|-----------|---------------------------------------|-------------|
| First Name | `first`, `firstname`, `fname` | "Jane" |
| Last Name | `last`, `lastname`, `lname` | "Doe" |
| Name (generic) | `name` (without more specific match) | "Jane Doe" |
| Email | `type="email"`, `email` | "jane@example.com" |
| Phone | `type="tel"`, `phone`, `telephone` | "+1 555 123 4567" |
| Message | `textarea`, `message` | "This is a test inquiry..." |
| Company | `company`, `organization` | "Acme Corp" |
| Street | `street`, `address` | "123 Main Street" |
| ZIP | `zip`, `postal` | "10001" |
| City | `city`, `town` | "New York" |
| Checkbox (required) | `input[type="checkbox"][required]` | Check |
| Select | `select` | Choose first non-empty option |

**Captcha/Turnstile:** Do NOT fill out. Screenshot BEFORE submit, note in PDF: "Captcha-protected form".

**Submit:** NEVER actually submit. Instead:
1. Fill form → screenshot "Form filled"
2. Trigger client-side validation (via `form.reportValidity()`) → screenshot if errors
3. If no client-side validation: only show filled state

---

## PDF Structure

### Layout
```
Page 1:     Cover
            - Project name (from <title>, package.json, or directory)
            - Viewport + format
            - Date + time
            - Number of captured pages
            - Base URL

Page 2:     Table of Contents
            - All pages with PDF page number (clickable)
            - Smart captures indented under their page

Page 3+:    Page Captures
            Per website page:
            ├── Page name as heading (subtle, at top)
            ├── Clean screenshot (1+ PDF pages, smartly split)
            └── Smart captures (if present):
                ├── "Cookie Banner" (with label)
                ├── "Form — filled" (with label)
                ├── "Google Maps — Consent Placeholder" (with label)
                └── etc.
```

### Layout Rules
- Subtle header: page name left, page number right
- Screenshot maximum width, clean margins (40pt)
- Labels for smart captures: small gray box above screenshot
- Long pages: Split across PDF pages (no cutting in the middle of content)
- JPEG compression (quality 92) for screenshots

---

## Script Location

The generated script is saved **in the project**:
```
project/
├── scripts/
│   └── capture-pdf.mjs    # Generated script
└── prints/                 # Output (gitignored)
    ├── {name}-desktop-YYYY-MM-DD.pdf
    ├── {name}-tablet-YYYY-MM-DD.pdf
    └── {name}-mobile-YYYY-MM-DD.pdf
```

- If `scripts/capture-pdf.mjs` exists → ask user: overwrite or use
- Automatically add `prints/` to `.gitignore`
- Auto-install dependencies (playwright, pdf-lib, sharp)

---

## CLI Options of the Generated Script

```
node scripts/capture-pdf.mjs [options]

  --url <url>        Base URL (default: from script config)
  --viewport <name>  desktop|tablet|mobile (default: desktop)
  --format <size>    a4|a3 (default: a4)
  --pages <json>     JSON array of pages (override)
  --no-smart         No smart captures
  --forms-only       Only form pages
  --concurrency <n>  Parallel captures (default: 3)
  --output <dir>     Output directory (default: prints/)
  --name <name>      PDF filename prefix
  --help             Show help
```

---

## Video Evidence (Playwright 1.59+ Screencast API)

When Playwright >= 1.59.0 is available, capture-pdf can generate **video walkthroughs** alongside PDFs using the Screencast API. This is optional and activated via `--video` flag.

### Video Mode

```bash
node scripts/capture-pdf.mjs --video --viewport desktop
```

**How it works:**

1. `page.screencast.start({ path: 'prints/{name}-walkthrough.webm' })` — start recording
2. `page.screencast.showActions({ position: 'top-right' })` — annotate every click/scroll
3. Per page: `page.screencast.showChapter(pageName, { description })` — chapter markers
4. Smart captures show as annotated actions in the video
5. `page.screencast.stop()` — stop recording

**Use case:** Client presentations where a video walkthrough is more engaging than a PDF, or audit evidence where the navigation flow matters.

### CLI Options (Video)

```
  --video            Generate video walkthrough alongside PDFs
  --video-only       Generate only video, no PDFs
  --video-actions    Show action annotations in video (default: on)
  --video-chapters   Show chapter titles per page (default: on)
```

### Frame Capture for AI Vision

For audit workflows, real-time frame capture can feed screenshots to an AI vision model:

```js
await page.screencast.start({
  onFrame: ({ data }) => analyzeWithVision(data),
  size: { width: 1280, height: 720 }
});
```

This enables automated visual regression detection during audits.

---

## Rules

- **Privacy:** Everything local, no external services. Only Playwright + local rendering.
- **No real submit:** Only visually fill forms, never submit. `event.preventDefault()` on all submit events.
- **Error tolerance:** Skip individual failed pages/captures, show summary at the end.
- **No hardcoded versions:** Install dependencies without fixed version numbers.
- **Cross-platform:** Use `/` not `\` for paths, no OS-specific commands.
- **No state file:** One-time action, no multi-session tracking needed.
- **Project-specific customization:** Selectors and sample data can be extended per project. The script is a generatable template, not a rigid tool.
- **Performance:** Parallel captures (default 3), screenshot reuse where possible.
- **Video:** Screencast requires Playwright >= 1.59.0. Falls back to PDF-only when unavailable.
