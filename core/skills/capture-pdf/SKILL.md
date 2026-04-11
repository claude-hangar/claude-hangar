---
name: capture-pdf
description: >
  Website-to-PDF capture (all pages + interactive states).
  Use when: "capture", "pdf", "print", "screenshot", "capture pages".
user-invocable: true
argument-hint: "[url]"
---

<!-- AI-QUICK-REF
## /capture-pdf — Quick Reference
- **Modes:** start | quick | url <url> | page <paths> | forms
- **Arguments:** `/capture-pdf $0 [$1]` e.g. `/capture-pdf quick`, `/capture-pdf url https://example.com`
- **Tech:** Playwright + pdf-lib + sharp (Screencast: Playwright >= 1.59)
- **Smart Captures:** Cookie banners, forms, accordions, modals, mobile menu, lightboxes
- **Video:** Animated walkthroughs with chapters, overlays, responsive comparison (auto if PW >= 1.59)
- **Auth:** `--auth <file>` or `--auth-login <url>` for protected pages
- **Page Detection:** Sitemap → Framework routes → Crawling → Manual
- **Output:** PDFs + videos in prints/ directory, thumbnails in prints/thumbs/
- **Checkpoints:** [CHECKPOINT: decision] at start (options), [CHECKPOINT: manual] for Playwright install
-->

# /capture-pdf — Universal Website-to-PDF Capture

Captures any website completely as print-ready PDFs and annotated video walkthroughs — all pages plus interactive states (cookie banners, filled forms, consent embeds, modals, accordions, lightboxes).

**Use cases:** Client presentations, sales documentation, acceptance protocols, design reviews, archiving, audit evidence, responsive verification.

**Screencast (Playwright >= 1.59):** Automatically produces video walkthroughs alongside PDFs with chapter markers, action annotations, custom overlays, and responsive comparisons. Falls back to screenshot-only for older Playwright versions.

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
- Video walkthrough? (Yes — recommended if PW >= 1.59 / No / Video only)
- Responsive comparison? (Record all viewports in one video)
- Auth required? (No / Load state file / Interactive login)
- Adjust exclude patterns?

**Recommendation as default:** Desktop + A4 + Smart Captures on + Video on (if available).

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
- `sharp` → auto-install (also used for thumbnail generation + frame analysis)

If no `package.json` in `scripts/` directory → create one.

**Feature detection after install:**
```js
const HAS_SCREENCAST = semverGte(playwrightVersion, '1.59.0');
if (HAS_SCREENCAST) console.log('✓ Screencast API available — video features enabled');
else console.log('ℹ Playwright < 1.59 — video features disabled, PDF-only mode');
```

### Step 6: Run Capture

```bash
# PDF + Video (default when Playwright >= 1.59)
node scripts/capture-pdf.mjs --viewport desktop --format a4

# Video only with responsive comparison
node scripts/capture-pdf.mjs --video-only --video-responsive

# Authenticated pages
node scripts/capture-pdf.mjs --auth-login https://example.com/login

# Full audit mode with overlays + thumbnails
node scripts/capture-pdf.mjs --video --video-meta --thumbs --dashboard
```

Progress is displayed in the terminal. Skip individual pages on errors.
When `--dashboard` is used, the live capture is observable in the Playwright dashboard.

### Step 7: Result

- Show PDF path: `prints/{name}-{viewport}-{date}.pdf`
- Show video path: `prints/{name}-walkthrough-{date}.webm` (if video enabled)
- Show responsive video: `prints/{name}-responsive-{date}.webm` (if `--video-responsive`)
- Show thumbnail index: `prints/index.html` (if `--thumbs`)
- Summary: X/Y pages successful, Z smart captures, video duration
- Add `prints/` to `.gitignore` (if not already present)

---

## Mode 2: `/capture-pdf quick`

No questions. Uses defaults:
- Viewport: Desktop (1920x1080)
- Format: A4
- All pages (via sitemap/routes/crawling)
- Smart Captures: On
- Video: On (if Playwright >= 1.59, with status + viewport overlays)
- Thumbnails: On (if video enabled)
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
│   └── capture-pdf.mjs         # Generated script
└── prints/                      # Output (gitignored)
    ├── {name}-desktop-YYYY-MM-DD.pdf        # PDF capture
    ├── {name}-walkthrough-YYYY-MM-DD.webm   # Video walkthrough
    ├── {name}-responsive-YYYY-MM-DD.webm    # Responsive comparison
    ├── auth-state.json                       # Saved auth state (reusable)
    ├── vision-report.json                    # Frame analysis results
    ├── comparison-YYYY-MM-DD.json            # Before/after report
    ├── index.html                            # Visual thumbnail index
    ├── thumbs/                               # Page thumbnails
    │   ├── home.jpg
    │   ├── about.jpg
    │   └── contact.jpg
    └── diffs/                                # Comparison diff images
        ├── home-diff.png
        └── about-diff.png
```

- If `scripts/capture-pdf.mjs` exists → ask user: overwrite or use
- Automatically add `prints/` to `.gitignore`
- Auto-install dependencies (playwright, pdf-lib, sharp)

---

## CLI Options of the Generated Script

```
node scripts/capture-pdf.mjs [options]

Core:
  --url <url>            Base URL (default: from script config)
  --viewport <name>      desktop|tablet|mobile (default: desktop)
  --format <size>        a4|a3 (default: a4)
  --pages <json>         JSON array of pages (override)
  --no-smart             No smart captures
  --forms-only           Only form pages
  --concurrency <n>      Parallel captures (default: 3)
  --output <dir>         Output directory (default: prints/)
  --name <name>          PDF filename prefix
  --help                 Show help

Video (Playwright >= 1.59):
  --video                Video walkthrough alongside PDFs (auto-enabled)
  --video-only           Video only, skip PDF generation
  --video-responsive     Record each page at 3 viewports sequentially
  --no-video             Force disable video even if PW >= 1.59

Overlays:
  --video-meta           Show title/description/canonical overlay per page
  --video-audit <file>   Show finding badges from JSON file
  --no-overlays          Disable all overlays (clean recording)

Auth:
  --auth <file>          Load storage state for authenticated captures
  --auth-login <url>     Interactive login via browser, save state for reuse

Debug & Observation:
  --dashboard            Open Playwright dashboard for live observation
  --trace                Enable live tracing alongside video

Thumbnails & Analysis:
  --thumbs               Generate page thumbnails + index.html from frames
  --vision-analyze       Enable local frame analysis (CLS, FOUT, blank)
  --compare <file>       Compare against baseline recording
```

---

## Screencast Integration (Playwright 1.59+)

When Playwright >= 1.59.0 is detected, capture-pdf transforms from a screenshot tool into a multi-modal capture platform. All Screencast features activate automatically and degrade gracefully.

### Feature Detection

```js
const HAS_SCREENCAST = semverGte(playwrightVersion, '1.59.0');
// If true: video + overlays + chapters + frame capture available
// If false or --no-video: existing screenshot pipeline runs unchanged
```

### Core Recording Flow

For every capture session (regardless of mode), the video pipeline runs in parallel with the screenshot pipeline:

```js
// Start recording once for the entire session
await page.screencast.start({ path: outputPath });
await page.screencast.showActions({ position: 'top-right', duration: 800 });

for (const pageInfo of pages) {
  // Chapter marker per page
  await page.screencast.showChapter(pageInfo.name, {
    description: `${pageInfo.path} — ${viewport.label}`,
    duration: 1500
  });

  // Status overlay: "Page 3/12 — Contact"
  await showStatusOverlay(page, index, total, pageInfo.name);

  // Navigate and wait for stable render
  await page.goto(pageInfo.url);
  await page.waitForLoadState('networkidle');

  // Screenshot for PDF (existing pipeline)
  const screenshot = await page.screenshot({ fullPage: true });

  // Smart captures as animated interactions (see below)
  await captureSmartElements(page, pageInfo);
}

await page.screencast.stop();
```

---

### Animated Smart Captures (P1)

Each Smart Capture becomes a **video chapter with action annotations** instead of a static screenshot. The interaction (animation, timing, flow) is visible.

| Element | Screencast Flow |
|---------|----------------|
| Cookie Banner | Chapter → banner appears → dismiss click annotated → banner animates out |
| Form | Chapter "Form — Contact" → field-by-field filling → tab order visible → validation triggered → errors shown |
| Accordion | Chapter per accordion → click trigger annotated → slide animation → content revealed |
| Modal | Chapter → trigger click → modal opens with animation → scroll content → close |
| Mobile Menu | Chapter → hamburger click → slide-in animation → navigate links → close |
| Lightbox | Chapter → thumbnail click → zoom animation → gallery swipe → close |

**Implementation pattern per Smart Capture type:**

```js
async function captureSmartElement(page, element, type) {
  // Chapter marker for this element
  await page.screencast.showChapter(`${type} — ${element.label}`, {
    description: element.description || `Interactive ${type} capture`,
    duration: 1200
  });

  // Form state overlay (forms only)
  if (type === 'form') {
    await showFormStateOverlay(page, 'empty');
  }

  // Enable action annotations for the interaction
  await page.screencast.showActions({ position: 'top-right', duration: 600 });

  // Execute type-specific interaction
  switch (type) {
    case 'cookie':
      await interactCookieBanner(page, element);
      break;
    case 'form':
      await showFormStateOverlay(page, 'filling');
      await fillFormFields(page, element);
      await showFormStateOverlay(page, 'validation');
      await triggerValidation(page, element);
      break;
    case 'accordion':
      await interactAccordion(page, element);
      break;
    case 'modal':
      await interactModal(page, element);
      break;
    case 'mobile-menu':
      await interactMobileMenu(page, element);
      break;
    case 'lightbox':
      await interactLightbox(page, element);
      break;
  }

  // Hide action annotations after interaction completes
  await page.screencast.hideActions();

  // Still take a screenshot for the PDF (dual output)
  const screenshot = await page.screenshot({ fullPage: false, clip: element.bounds });
  return screenshot;
}
```

**Fallback:** When `--no-video` or Playwright < 1.59, the existing screenshot-only smart capture runs unchanged.

---

### Overlay System (P2)

Five overlay types injected via `page.screencast.showOverlay()`. All overlays are HTML positioned with `position:fixed` and high `z-index`.

**1. Status Overlay (always on in video mode)**

```js
async function showStatusOverlay(page, index, total, pageName) {
  await page.screencast.showOverlay(`
    <div style="position:fixed;top:12px;left:12px;background:rgba(0,0,0,0.75);
      color:#fff;padding:6px 14px;border-radius:6px;font:13px/1 system-ui;
      z-index:99999;backdrop-filter:blur(4px)">
      Page ${index + 1}/${total} — ${pageName}
    </div>
  `);
}
```

**2. Viewport Overlay (first 2s per page)**

```js
async function showViewportOverlay(page, viewport) {
  const overlay = await page.screencast.showOverlay(`
    <div style="position:fixed;top:12px;right:12px;background:rgba(59,130,246,0.85);
      color:#fff;padding:6px 14px;border-radius:6px;font:13px/1 system-ui;z-index:99999">
      ${viewport.label} ${viewport.width}×${viewport.height}
    </div>
  `);
  // Auto-hide after 2 seconds
  setTimeout(() => overlay.dispose(), 2000);
}
```

**3. Meta Overlay (opt-in: `--video-meta`)**

Extracts and displays page metadata as a bottom bar:

```js
async function showMetaOverlay(page) {
  const meta = await page.evaluate(() => ({
    title: document.title,
    description: document.querySelector('meta[name="description"]')?.content || '—',
    canonical: document.querySelector('link[rel="canonical"]')?.href || '—'
  }));

  await page.screencast.showOverlay(`
    <div style="position:fixed;bottom:0;left:0;right:0;background:rgba(0,0,0,0.88);
      color:#fff;padding:10px 16px;font:12px/1.5 system-ui;z-index:99999">
      <strong>Title:</strong> ${escapeHtml(meta.title)}<br>
      <strong>Description:</strong> ${escapeHtml(meta.description.slice(0, 120))}<br>
      <strong>Canonical:</strong> ${escapeHtml(meta.canonical)}
    </div>
  `);
}
```

**4. Finding Overlay (opt-in: `--video-audit <findings.json>`)**

Reads audit findings and positions badges near matching elements:

```js
// findings.json format:
// [{ "id": "SEC-03", "severity": "high", "message": "Mixed Content", "selector": "img[src^='http:']" }]

async function showFindingOverlays(page, findings) {
  for (const finding of findings) {
    const element = page.locator(finding.selector).first();
    if (await element.isVisible()) {
      const box = await element.boundingBox();
      if (!box) continue;

      const color = finding.severity === 'high' ? '#ef4444'
        : finding.severity === 'medium' ? '#f59e0b' : '#6b7280';

      await page.screencast.showOverlay(`
        <div style="position:fixed;top:${box.y - 24}px;left:${box.x}px;
          background:${color};color:#fff;padding:2px 8px;border-radius:4px;
          font:11px/1 system-ui;z-index:99999;white-space:nowrap">
          ${finding.id}: ${finding.message}
        </div>
      `);
    }
  }
}
```

**5. Form State Overlay (automatic during form captures)**

```js
const FORM_STATES = ['Empty', 'Filling', 'Validation', 'Complete'];

async function showFormStateOverlay(page, currentState) {
  const bar = FORM_STATES.map(s =>
    s.toLowerCase() === currentState
      ? `<span style="background:#3b82f6;color:#fff;padding:2px 8px;border-radius:3px">${s}</span>`
      : `<span style="color:#9ca3af">${s}</span>`
  ).join(' → ');

  await page.screencast.showOverlay(`
    <div style="position:fixed;bottom:60px;left:50%;transform:translateX(-50%);
      background:rgba(0,0,0,0.85);color:#fff;padding:8px 16px;border-radius:8px;
      font:12px/1 system-ui;z-index:99999;display:flex;gap:4px;align-items:center">
      ${bar}
    </div>
  `);
}
```

**Overlay control:**
- `--no-overlays` disables all overlays (clean recording)
- All overlays use `hideOverlays()` before clean screenshots (no overlay bleed into PDF)

---

### Responsive Comparison Mode (P3)

**Flag:** `--video-responsive`

Records each page at three viewports sequentially in one video:

```js
async function captureResponsive(page, pages, screencast) {
  const viewports = [
    { label: 'Desktop', width: 1920, height: 1080 },
    { label: 'Tablet',  width: 768,  height: 1024 },
    { label: 'Mobile',  width: 375,  height: 812 }
  ];

  await screencast.start({ path: responsiveOutputPath });
  await screencast.showActions({ position: 'top-right' });

  for (const pageInfo of pages) {
    for (const vp of viewports) {
      // Chapter: "Home — Desktop 1920×1080"
      await screencast.showChapter(
        `${pageInfo.name} — ${vp.label} ${vp.width}×${vp.height}`,
        { duration: 1200 }
      );

      await page.setViewportSize({ width: vp.width, height: vp.height });
      await showViewportOverlay(page, vp);

      await page.goto(pageInfo.url);
      await page.waitForLoadState('networkidle');

      // Mobile-only smart captures
      if (vp.label === 'Mobile') {
        await captureMobileMenu(page);
      }

      // Scroll through page to show full content
      await autoScroll(page);
      await waitForStableFrame(500);
    }
  }

  await screencast.stop();
}
```

**Output:** `prints/{name}-responsive-{date}.webm` — one video with chapters per page×viewport.

---

### Authenticated Page Captures (P4)

**Approach 1 — Pre-saved state:**
```bash
node scripts/capture-pdf.mjs --auth auth-state.json
```

```js
if (args.auth) {
  const state = JSON.parse(fs.readFileSync(args.auth, 'utf8'));
  await context.setStorageState(state);
  console.log(`✓ Auth state loaded from ${args.auth}`);
}
```

**Approach 2 — Interactive login:**
```bash
node scripts/capture-pdf.mjs --auth-login https://example.com/login
```

```js
if (args.authLogin) {
  // Launch visible browser for manual login
  const authBrowser = await chromium.launch({ headless: false });
  const authContext = await authBrowser.newContext();
  const authPage = await authContext.newPage();

  // Bind for external observation
  await authBrowser.bind('capture-auth');
  console.log('Login manually in the browser window.');
  console.log('Watch via: playwright-cli attach capture-auth');

  await authPage.goto(args.authLogin);

  // Wait for user to press Enter after login
  await new Promise(resolve => {
    process.stdout.write('Press Enter when logged in...');
    process.stdin.once('data', resolve);
  });

  // Save state
  const state = await authContext.storageState();
  const statePath = path.join(outputDir, 'auth-state.json');
  fs.writeFileSync(statePath, JSON.stringify(state, null, 2));
  console.log(`✓ Auth state saved to ${statePath}`);

  await authBrowser.close();

  // Load saved state into capture context
  await context.setStorageState(state);
}
```

**Reset between different auth levels:**
```js
// Capture admin pages with auth
await capturePages(adminPages, { auth: true });
// Reset to guest state
await context.setStorageState({ cookies: [], origins: [] });
// Capture public pages without auth
await capturePages(publicPages, { auth: false });
```

---

### Thumbnail Generation (P5)

**Flag:** `--thumbs`

Captures the first visually stable frame of each page as a thumbnail:

```js
async function captureThumbnail(page, pageInfo, outputDir) {
  let lastHash = null;
  let stableCount = 0;
  let saved = false;

  return new Promise((resolve) => {
    page.screencast.start({
      onFrame: async ({ data }) => {
        if (saved) return;

        const hash = quickHash(data); // Fast 32-bit hash of pixel data
        if (hash === lastHash) {
          stableCount++;
          if (stableCount >= 3) { // 3 identical frames = visually stable
            saved = true;
            const thumbPath = path.join(outputDir, 'thumbs', `${pageInfo.slug}.jpg`);
            await sharp(data)
              .resize(300) // 300px width, auto height
              .jpeg({ quality: 85 })
              .toFile(thumbPath);
            resolve(thumbPath);
          }
        } else {
          stableCount = 0;
          lastHash = hash;
        }
      },
      size: { width: 600, height: 400 }
    });
  });
}

function quickHash(buffer) {
  let hash = 0;
  // Sample every 1000th byte for speed
  for (let i = 0; i < buffer.length; i += 1000) {
    hash = ((hash << 5) - hash + buffer[i]) | 0;
  }
  return hash;
}
```

**Index HTML generation:**

```js
function generateThumbnailIndex(pages, thumbsDir) {
  const cards = pages.map(p => `
    <div style="break-inside:avoid;margin:8px">
      <img src="thumbs/${p.slug}.jpg" style="width:100%;border-radius:6px;border:1px solid #e5e7eb">
      <div style="font:13px/1.4 system-ui;color:#374151;padding:6px 2px">
        <strong>${p.name}</strong><br>
        <span style="color:#9ca3af">${p.path}</span>
      </div>
    </div>
  `).join('\n');

  return `<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Capture Index</title>
<style>body{max-width:1200px;margin:40px auto;padding:0 20px;font-family:system-ui}
.grid{columns:3;column-gap:16px}h1{font-size:24px;margin-bottom:24px}
@media(max-width:768px){.grid{columns:2}}@media(max-width:480px){.grid{columns:1}}</style>
</head><body>
<h1>Capture Index — ${new Date().toISOString().slice(0, 10)}</h1>
<div class="grid">${cards}</div>
</body></html>`;
}
```

---

### Browser Dashboard (P6)

Automatic browser binding for live observation:

```js
async function setupDashboard(browser, args) {
  // Always bind (cheap operation)
  const { endpoint } = await browser.bind('capture-session', {
    workspaceDir: process.cwd()
  });
  console.log(`  Live: playwright-cli attach capture-session`);

  // Auto-open dashboard UI if requested
  if (args.dashboard) {
    const { spawn } = require('child_process');
    spawn('npx', ['playwright-cli', 'show'], {
      stdio: 'ignore', detached: true
    }).unref();
    console.log(`  Dashboard opened in browser`);
  }
}
```

**Use cases:**
- Watch capture progress in real-time
- Manually solve captchas, dialog prompts, or 2FA challenges
- Debug stuck pages without restarting the capture
- Team review: multiple clients connect simultaneously via endpoint

---

### AI Vision Frame Pipeline (P7 — Extension Point)

**Flag:** `--vision-analyze`

Local-only frame analysis — no external API calls (privacy rule).

**Built-in analyzers:**

```js
const analyzers = {
  // CLS: Compare consecutive frames for layout shift
  cls: async (currentFrame, previousFrame) => {
    if (!previousFrame) return null;
    const diff = await sharp(currentFrame)
      .composite([{ input: previousFrame, blend: 'difference' }])
      .stats();
    const shiftScore = diff.channels.reduce((sum, c) => sum + c.mean, 0) / 3;
    return shiftScore > CLS_THRESHOLD ? { type: 'cls', score: shiftScore } : null;
  },

  // FOUT: Font rendering change in first 3 seconds
  fout: async (frame, timestamp, baseline) => {
    if (timestamp > 3000 || !baseline) return null;
    const diff = await pixelDiffPercentage(frame, baseline);
    return diff > FOUT_THRESHOLD ? { type: 'fout', diffPct: diff, at: timestamp } : null;
  },

  // Blank page: Frame is mostly white/empty
  blank: async (frame) => {
    const stats = await sharp(frame).stats();
    const brightness = stats.channels.reduce((sum, c) => sum + c.mean, 0) / 3;
    return brightness > 250 ? { type: 'blank', brightness } : null;
  }
};
```

**Integration into capture loop:**

```js
if (args.visionAnalyze) {
  let previousFrame = null;
  const issues = [];

  await page.screencast.start({
    onFrame: async ({ data, timestamp }) => {
      for (const [name, analyzer] of Object.entries(analyzers)) {
        const result = await analyzer(data, timestamp, previousFrame);
        if (result) issues.push({ page: currentPage.name, ...result });
      }
      previousFrame = data;
    },
    size: { width: 1280, height: 720 }
  });
}
```

**Output:** `prints/vision-report.json`
```json
{
  "analyzed": "2026-04-04",
  "pages": 12,
  "issues": [
    { "page": "Home", "type": "cls", "score": 0.15 },
    { "page": "About", "type": "fout", "diffPct": 8.2, "at": 1200 }
  ]
}
```

**Custom analyzer extension:**
```js
// Users can provide their own analyzer via config
const customAnalyzer = config.visionAnalyzer || null;
if (customAnalyzer) {
  await page.screencast.start({
    onFrame: ({ data, timestamp }) => customAnalyzer(data, timestamp, currentPage)
  });
}
```

---

### Before/After Comparison (P8 — Extension Point)

**Flag:** `--compare <baseline.webm>`

Records a new video and generates a comparison report:

```js
async function compareWithBaseline(baselinePath, newVideoPath, pages) {
  const baselineFrames = await extractKeyFrames(baselinePath, pages.length);
  const newFrames = await extractKeyFrames(newVideoPath, pages.length);

  const report = [];
  for (let i = 0; i < Math.min(baselineFrames.length, newFrames.length); i++) {
    const diffPct = await pixelDiffPercentage(baselineFrames[i], newFrames[i]);
    const diffPath = path.join(outputDir, 'diffs', `${pages[i].slug}-diff.png`);

    // Generate visual diff image
    await sharp(newFrames[i])
      .composite([{ input: baselineFrames[i], blend: 'difference' }])
      .toFile(diffPath);

    report.push({
      page: pages[i].name,
      diffPercentage: Math.round(diffPct * 100) / 100,
      changed: diffPct > 1.0, // > 1% pixel difference = changed
      diffImage: diffPath
    });
  }

  return report;
}

async function extractKeyFrames(videoPath, expectedCount) {
  // Extract one frame per chapter using ffprobe/sharp
  // Falls back to evenly-spaced frame extraction
  // ...
}
```

**Output:** `prints/comparison-{date}.json` + `prints/diffs/*.png`

---

## Rules

- **Privacy:** Everything local, no external API calls. Frame analysis local only. Vision pipeline is extension point, not a built-in cloud call.
- **No real submit:** Only visually fill forms, never submit. `event.preventDefault()` on all submit events.
- **Graceful degradation:** Playwright < 1.59 or `--no-video` → entire video pipeline skipped, existing screenshot+PDF pipeline runs unchanged. No errors, no warnings beyond initial detection message.
- **`await using`:** All Page and BrowserContext objects use async disposables for automatic cleanup on errors. No resource leaks even on crash.
- **Error tolerance:** Skip individual failed pages/captures, show summary at the end. Video continues recording even if one page fails.
- **No hardcoded versions:** Install dependencies without fixed version numbers.
- **Cross-platform:** Use `/` not `\` for paths, no OS-specific commands.
- **No state file:** One-time action, no multi-session tracking needed. Auth state file is an explicit user-requested output, not automatic state.
- **Overlay hygiene:** All overlays are hidden before taking PDF screenshots — no overlay bleed into static captures.
- **Project-specific customization:** Selectors, sample data, and vision analyzers can be extended per project. The script is a generatable template, not a rigid tool.
- **Performance:** Parallel captures (default 3), screenshot reuse where possible. Frame analysis sampling (every 1000th byte) keeps thumbnail/CLS detection fast.
- **Dashboard always bound:** `browser.bind()` is always called (negligible overhead). The `--dashboard` flag only controls whether the UI auto-opens.
