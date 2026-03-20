# Website Audit: Quick-Fix Templates

## Fix Protocol (v4.9 — MANDATORY)

Every fix must go through this 5-step protocol:

```
1. IDENTIFY  — Name finding-ID + location (e.g. SEC-02, src/server.ts:45)
2. RUN       — Implement fix (change code, set config)
3. READ      — Re-read the changed file (NOT from memory!)
4. VERIFY    — Test (build, curl, Lighthouse, etc.)
5. CLAIM     — Only now mark as "fixed" in state
```

**Step 3 (READ) and 4 (VERIFY) must NEVER be skipped.**

---

Ready-made fix templates for common findings. For each fix:
1. Show template, 2. Get user confirmation, 3. Implement, 4. Verify (5-step protocol).

---

## SEC — Security

### SEC: Missing Security Headers (Traefik)

```yaml
# docker-compose.yml — add labels
labels:
  - "traefik.http.middlewares.security-headers.headers.customResponseHeaders.X-Frame-Options=SAMEORIGIN"
  - "traefik.http.middlewares.security-headers.headers.customResponseHeaders.X-Content-Type-Options=nosniff"
  - "traefik.http.middlewares.security-headers.headers.customResponseHeaders.Referrer-Policy=strict-origin-when-cross-origin"
  - "traefik.http.middlewares.security-headers.headers.customResponseHeaders.Permissions-Policy=camera=(), microphone=(), geolocation=()"
  - "traefik.http.middlewares.security-headers.headers.stsSeconds=31536000"
  - "traefik.http.middlewares.security-headers.headers.stsIncludeSubdomains=true"
```

**Verify:**
```bash
curl -sI https://{{DOMAIN}} | grep -iE '(strict-transport|content-security|x-frame|x-content-type|referrer-policy|permissions-policy)'
# Expected: All 6 headers present
```

### SEC: Secrets in .env Committed to Repo

```bash
# 1. Update .gitignore
echo ".env" >> .gitignore
echo ".env.*" >> .gitignore
echo "!.env.example" >> .gitignore

# 2. Create .env.example (without values)
# Copy .env > .env.example, replace values with placeholders

# 3. Remove .env from Git history
git rm --cached .env
git commit -m "fix: remove .env from tracking"
```

**Verify:** `git ls-files | grep .env` — only .env.example visible?

### SEC: Missing Rate Limiting (Fastify)

```javascript
// Register in Fastify app
import rateLimit from '@fastify/rate-limit';

await fastify.register(rateLimit, {
  max: 100,
  timeWindow: '1 minute',
  // Stricter for sensitive routes:
  // keyGenerator: (req) => req.ip
});
```

**Verify:** 101 requests in 1 minute > 429 status?

### SEC: Create security.txt (RFC 9116)

```text
# /.well-known/security.txt
Contact: mailto:{{SECURITY_EMAIL}}
Expires: 2027-01-01T00:00:00.000Z
Preferred-Languages: en
Canonical: https://{{DOMAIN}}/.well-known/security.txt
Policy: https://{{DOMAIN}}/security-policy
```

```nginx
# nginx — serve static file
location /.well-known/security.txt {
    alias /var/www/security.txt;
    default_type text/plain;
}
```

```yaml
# Traefik — via file provider or Docker label
# Easiest: security.txt as static file in project
# e.g. public/.well-known/security.txt (Astro/Static Sites)
```

**Required fields:** `Contact` + `Expires` (ISO 8601).
**Renew Expires regularly** — an expired security.txt is worse than none.

**Verify:** `curl https://{{DOMAIN}}/.well-known/security.txt` — content correct? Expires in the future?

### SEC: SRI for External Scripts

```html
<!-- Generate hash: -->
<!-- openssl dgst -sha384 -binary lib.js | openssl base64 -A -->
<!-- Or: https://www.srihash.org/ -->

<!-- Before: -->
<script src="https://cdn.example.com/lib.js"></script>

<!-- After: -->
<script src="https://cdn.example.com/lib.js"
        integrity="sha384-INSERT_HASH_HERE"
        crossorigin="anonymous"></script>

<!-- For stylesheets: -->
<link rel="stylesheet"
      href="https://cdn.example.com/style.css"
      integrity="sha384-INSERT_HASH_HERE"
      crossorigin="anonymous" />
```

**Best Practice:** Prefer self-hosting (privacy + security). SRI only for resources that must remain external.

**Verify:** Browser console > no SRI errors? `integrity` attribute on all external resources?

### SEC: Extended Security Headers (CORP/COOP)

```yaml
# docker-compose.yml — additional Traefik labels
labels:
  # Cross-Origin-Resource-Policy — prevents cross-origin reads (Spectre protection)
  - "traefik.http.middlewares.security-headers.headers.customResponseHeaders.Cross-Origin-Resource-Policy=same-origin"
  # Cross-Origin-Opener-Policy — isolates browsing context
  - "traefik.http.middlewares.security-headers.headers.customResponseHeaders.Cross-Origin-Opener-Policy=same-origin"
  # Cross-Origin-Embedder-Policy — only if SharedArrayBuffer needed
  # - "traefik.http.middlewares.security-headers.headers.customResponseHeaders.Cross-Origin-Embedder-Policy=require-corp"
```

**Note:** COOP `same-origin` can break popups/OAuth flows. For OAuth: use `same-origin-allow-popups`.
**COEP:** Only enable if `SharedArrayBuffer`/`performance.measureUserAgentSpecificMemory()` is needed.

**Verify:**
```bash
curl -sI https://{{DOMAIN}} | grep -iE '(cross-origin-resource-policy|cross-origin-opener-policy)'
# Expected: Both headers present (CORP + COOP)
```

---

## PERF — Performance

### PERF: Unoptimized Images (Astro)

```astro
---
// Before: <img src="/image.jpg" />
// After:
import { Image } from 'astro:assets';
import photo from '../assets/photo.jpg';
---
<Image src={photo} alt="Description" widths={[400, 800, 1200]} />
```

**Verify:** Check build output — `.webp`/`.avif` files present?

### PERF: Missing Prefetch Strategy (Astro)

```javascript
// astro.config.mjs
export default defineConfig({
  prefetch: {
    defaultStrategy: 'viewport',
    prefetchAll: false
  }
});
```

**Verify:** DevTools Network > prefetch requests on hover/viewport?

### PERF: Missing Caching Headers (Traefik/nginx)

```yaml
# Traefik Middleware
labels:
  - "traefik.http.middlewares.cache-static.headers.customResponseHeaders.Cache-Control=public, max-age=31536000, immutable"
```

```nginx
# nginx — for static assets
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

**Verify:** `curl -I https://{{DOMAIN}}/style.css` > `Cache-Control` header?

### PERF: Speculation Rules API

```html
<!-- In <head> or at end of <body> -->
<script type="speculationrules">
{
  "prerender": [
    {
      "where": { "href_matches": "/products/*" },
      "eagerness": "moderate"
    }
  ],
  "prefetch": [
    {
      "where": { "selector_matches": "a[href]" },
      "eagerness": "conservative"
    }
  ]
}
</script>
```

**Eagerness levels:**
- `conservative`: Only on click intention (hover >200ms, pointerdown)
- `moderate`: On hover
- `eager`: Immediately on visibility (use carefully — traffic!)

**Browser support:** Chromium-based (Chrome, Edge, Opera). Firefox/Safari ignore it.
**Astro:** `prefetch` config uses similar mechanisms — check for duplication.

**Verify:** DevTools > Application > Speculative Loads > rules visible?

---

## SEO — Search Engine Optimization

### SEO: Missing Meta Tags (Astro)

```astro
---
// src/components/SEO.astro
interface Props {
  title: string;
  description: string;
  image?: string;
  canonical?: string;
}
const { title, description, image = '/og-default.jpg', canonical } = Astro.props;
const canonicalURL = canonical || new URL(Astro.url.pathname, Astro.site);
---
<title>{title}</title>
<meta name="description" content={description} />
<link rel="canonical" href={canonicalURL} />
<meta property="og:title" content={title} />
<meta property="og:description" content={description} />
<meta property="og:image" content={new URL(image, Astro.site)} />
<meta property="og:type" content="website" />
<meta name="twitter:card" content="summary_large_image" />
```

**Verify:** Check `<head>` in HTML — all meta tags present?

### SEO: Missing Sitemap (Astro)

```bash
npx astro add sitemap
```

```javascript
// astro.config.mjs
import sitemap from '@astrojs/sitemap';
export default defineConfig({
  site: 'https://{{DOMAIN}}',
  integrations: [sitemap()]
});
```

**Verify:** `https://{{DOMAIN}}/sitemap-index.xml` reachable?

### SEO: Missing Structured Data

```astro
<script type="application/ld+json" set:html={JSON.stringify({
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "{{COMPANY_NAME}}",
  "url": "https://{{DOMAIN}}",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "{{STREET}}",
    "addressLocality": "{{CITY}}",
    "postalCode": "{{POSTAL_CODE}}",
    "addressCountry": "{{COUNTRY_CODE}}"
  }
})} />
```

**Verify:** Test with Google Rich Results Test using URL.

### SEO: IndexNow Integration

```javascript
// Post-build or deployment hook — ping URLs to IndexNow
// Bing, Yandex and others use IndexNow (NOT Google)

const INDEXNOW_KEY = 'your-api-key-here';
const SITE_URL = 'https://{{DOMAIN}}';

async function pingIndexNow(urls) {
  const response = await fetch('https://api.indexnow.org/indexnow', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      host: new URL(SITE_URL).host,
      key: INDEXNOW_KEY,
      keyLocation: `${SITE_URL}/${INDEXNOW_KEY}.txt`,
      urlList: urls
    })
  });
  return response.status; // 200 = ok, 202 = accepted
}

// Provide key file:
// public/{INDEXNOW_KEY}.txt > content: the key itself
```

**When useful:** Blogs, news sites, price lists — content that changes.
**Not needed for:** Static company websites with rarely changing content.

**Verify:** `curl -I https://{{DOMAIN}}/{KEY}.txt` > 200? IndexNow ping > 200/202?

### SEO: AI Crawler robots.txt

```text
# robots.txt — Document a deliberate decision!

# === Block AI crawlers (if desired) ===
User-agent: GPTBot
Disallow: /

User-agent: ClaudeBot
Disallow: /

User-agent: Google-Extended
Disallow: /

User-agent: CCBot
Disallow: /

User-agent: PerplexityBot
Disallow: /

User-agent: Bytespider
Disallow: /

# === OR: Allow AI crawlers ===
# (omit robots.txt rules for these bots)
# Advantage: Content appears in AI responses

# Regular crawlers
User-agent: *
Allow: /
Sitemap: https://{{DOMAIN}}/sitemap-index.xml
```

**Recommendation:** Make a deliberate decision and document it. No "we didn't think about it".
**Note:** Not all AI crawlers respect robots.txt. Meta tags (`noai`, `noimageai`) provide additional protection.

**Verify:** `curl https://{{DOMAIN}}/robots.txt` > AI crawler rules present?

---

## A11Y — Accessibility

### A11Y: Missing Alt Texts

```bash
# Find all <img> without alt:
grep -rn '<img' src/ | grep -v 'alt='
# Also check Astro <Image>:
grep -rn '<Image' src/ | grep -v 'alt='
```

Fix: Add descriptive `alt` to every `<img>`. Decorative images: `alt=""`.

**Verify:** `astro check` — no A11y warnings?

### A11Y: Contrast Below 4.5:1

```css
/* Typical problem areas — gray on white */
/* Before: color: #999 (3.0:1 on white) */
/* After: */
color: #595959; /* 7.0:1 on white */

/* Or for larger text (>=18px bold / >=24px): */
color: #767676; /* 4.5:1 — minimum for large text */
```

**Verify:** Browser DevTools > Accessibility > check Contrast Ratio.

### A11Y: Missing Skip Navigation

```astro
<!-- At the very top of <body> -->
<a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:bg-white focus:px-4 focus:py-2 focus:rounded">
  Skip to content
</a>
<!-- ... -->
<main id="main-content">
```

**Verify:** Press Tab key > skip link visible?

### A11Y: Focus Appearance Fix (WCAG 2.2)

```css
/* Visible focus indicator — at least 2px, contrast 3:1 */
:focus-visible {
  outline: 2px solid #1a56db; /* Contrast 3:1+ on white */
  outline-offset: 2px;
}

/* Never remove outline completely — always provide an alternative */
/* Before: :focus { outline: none; } */
/* After: */
:focus:not(:focus-visible) {
  outline: none; /* Mouse click: no outline */
}
:focus-visible {
  outline: 2px solid #1a56db; /* Keyboard: visible outline */
  outline-offset: 2px;
}

/* Sticky elements: scroll-padding to prevent covering (2.4.11) */
html {
  scroll-padding-top: 5rem; /* Height of sticky header + buffer */
}
```

**Verify:** Tab through all interactive elements > focus always visible? Not covered by sticky header?

### A11Y: Target Size 24x24px (WCAG 2.2)

```css
/* WCAG 2.2 (2.5.8): Minimum 24x24 CSS pixels */
/* Typical problem areas: icon buttons, close buttons, pagination */

/* Before: */
.icon-btn { width: 16px; height: 16px; }

/* After: */
.icon-btn {
  min-width: 24px;
  min-height: 24px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

/* Recommended: 44x44px (AAA level, better usability) */
/* Tailwind: min-w-6 min-h-6 (24px) or min-w-11 min-h-11 (44px) */
```

**Verify:** DevTools > measure all interactive elements. Smallest target >= 24x24px?

### A11Y: Accessible Authentication — Captcha Alternative (WCAG 2.2)

```javascript
// WCAG 2.2 (3.3.8): No cognitive function test for login
// FORBIDDEN: Puzzle captcha, "type this word", math puzzles

// ALLOWED: Password manager compatible (autocomplete)
<input type="email" name="email" autocomplete="email" />
<input type="password" name="password" autocomplete="current-password" />

// ALLOWED: WebAuthn / Passkeys
// ALLOWED: Magic links (email-based)
// ALLOWED: Object recognition ("click all traffic lights")

// If spam protection needed — honeypot instead of captcha:
<div style="display: none" aria-hidden="true">
  <input type="text" name="website" tabindex="-1" autocomplete="off" />
</div>
// Server: reject request if "website" field is filled
```

**Verify:** Login form usable WITHOUT captcha? Password manager works? Honeypot active?

---

## CODE — Code Quality

### CODE: TypeScript Strict Mode Missing

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true
  }
}
```

**Verify:** `npx astro check` or `tsc --noEmit` — fix errors.

### CODE: Outdated Dependencies

```bash
# Interactive update:
npx npm-check-updates -i

# Only patch/minor (safe):
npx npm-check-updates -u --target minor
npm install

# Individual major updates:
npm install packagename@latest
```

**Verify:** `npm audit` — no known vulnerabilities?

---

## GDPR — Privacy/Data Protection

### GDPR: Google Fonts via CDN

```bash
# 1. Download font (google-webfonts-helper or fontsource)
npm install @fontsource-variable/inter

# 2. Import in layout
import '@fontsource-variable/inter';

# 3. Adjust CSS
@theme {
  --font-sans: 'Inter Variable', system-ui, sans-serif;
}

# 4. Remove all Google Fonts CDN links
grep -rn 'fonts.googleapis.com' src/
```

**Verify:** DevTools Network > no request to `fonts.googleapis.com`?

### GDPR: Missing Cookie Banner Logic

```javascript
// Consent wrapper — blocks scripts until consent
function loadAfterConsent(scriptSrc) {
  if (localStorage.getItem('consent') === 'accepted') {
    const s = document.createElement('script');
    s.src = scriptSrc;
    document.head.appendChild(s);
  }
}

// Reject MUST be as easy as Accept
// > Same button size, same visibility
```

**Verify:** Load page without cookies > no tracking active? Reject button equally prominent?

### GDPR: Missing Legal Pages

Required pages for websites (adapt to your jurisdiction):
1. **Legal Notice / Imprint** (`/legal`) — Name, address, contact, registration
2. **Privacy Policy** (`/privacy`) — Purpose, legal basis, rights, cookies
3. **Accessibility Statement** (`/accessibility`) — Required by accessibility laws

**Verify:** All pages linked in footer? Reachable? Content complete?

### GDPR: Consent Mode v2 Implementation

```html
<!-- In <head> — BEFORE all Google scripts -->
<script>
  // 1. Default: everything denied
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('consent', 'default', {
    ad_storage: 'denied',
    ad_user_data: 'denied',
    ad_personalization: 'denied',
    analytics_storage: 'denied',
    wait_for_update: 500  // Wait for CMP
  });
</script>

<!-- 2. After user consent (CMP callback or custom logic): -->
<script>
  function updateConsent(granted) {
    gtag('consent', 'update', {
      ad_storage: granted ? 'granted' : 'denied',
      ad_user_data: granted ? 'granted' : 'denied',
      ad_personalization: granted ? 'granted' : 'denied',
      analytics_storage: granted ? 'granted' : 'denied'
    });
  }
</script>
```

**Required since March 2024** for all websites with Google Ads/Analytics.
Without Consent Mode v2: Google does not collect data from EEA users.

**Verify:** DevTools Console > check `dataLayer`. Before consent: all `denied`? After consent: `granted`?

### GDPR: Accessibility Statement (Legal Requirement)

```astro
---
// src/pages/accessibility.astro
// Required content (adapt to local law)
---
<h1>Accessibility Statement</h1>

<p>{{COMPANY_NAME}} is committed to making the website {{SITE_URL}} accessible
in accordance with applicable accessibility laws.</p>

<h2>Conformance Status</h2>
<p>This website is [fully / largely / partially] conformant with WCAG 2.2 Level AA.</p>

<h2>Non-Accessible Content</h2>
<p>[List known limitations with reasons and alternatives where applicable]</p>

<h2>Feedback and Contact</h2>
<p>If you notice barriers on this website, please contact us:
<br>Email: <a href="mailto:{{CONTACT_EMAIL}}">{{CONTACT_EMAIL}}</a>
<br>Phone: {{CONTACT_PHONE}}</p>

<h2>Enforcement Procedure</h2>
<p>If you do not receive a satisfactory response to your complaint,
you may contact the responsible oversight authority:
<br>[Responsible authority with link]</p>

<p><em>This statement was created on [date] and last reviewed on [date].</em></p>
```

**Verify:** Page `/accessibility` reachable? Linked in footer? All required sections present?

---

## INFRA — Infrastructure

### INFRA: Missing Docker Health Check

```dockerfile
# Dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1
```

```javascript
// Fastify health endpoint
fastify.get('/health', async () => ({ status: 'ok' }));
```

**Verify:** `docker inspect --format='{{.State.Health.Status}}' container` > `healthy`?

### INFRA: Docker Running as Root

```dockerfile
# Dockerfile — non-root user
RUN addgroup --system app && adduser --system --ingroup app app
USER app
```

**Verify:** `docker exec container whoami` > NOT `root`?

### INFRA: Missing Log Rotation

```yaml
# docker-compose.yml
services:
  web:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

**Verify:** `docker inspect container --format='{{.HostConfig.LogConfig}}'`

---

## IST — Baseline Analysis

### IST: Outdated Astro Version

```bash
# Check current version
npm view astro version
# Update
npm install astro@latest
# Update all @astrojs/* packages
npx npm-check-updates -u '/^@astrojs/' && npm install
```

**Verify:** `npx astro check` — no errors? Build successful?

### IST: Node Version Not Pinned

```bash
# Create .nvmrc (v24 = Active LTS, v22 = Maintenance LTS)
echo "24" > .nvmrc

# Check Dockerfile base image
# Before: FROM node:latest
# After: FROM node:24-alpine
```

**Note:** Astro 6 requires at least Node 22. For Astro projects: `.nvmrc` with `22` is okay, `24` is better.

**Verify:** `.nvmrc` present? Dockerfile with specific tag?

---

## SEO — Extended

### SEO: Breadcrumbs Component (Astro)

```astro
---
// src/components/Breadcrumbs.astro
interface BreadcrumbItem {
  label: string;
  href?: string;
}
interface Props {
  items: BreadcrumbItem[];
}
const { items } = Astro.props;
---
<nav aria-label="Breadcrumb">
  <ol class="flex items-center gap-2 text-sm text-gray-500"
      itemscope itemtype="https://schema.org/BreadcrumbList">
    {items.map((item, i) => (
      <li itemscope itemprop="itemListElement" itemtype="https://schema.org/ListItem">
        {item.href && i < items.length - 1 ? (
          <a href={item.href} itemprop="item" class="hover:text-gray-700">
            <span itemprop="name">{item.label}</span>
          </a>
        ) : (
          <span itemprop="name" aria-current="page">{item.label}</span>
        )}
        <meta itemprop="position" content={String(i + 1)} />
        {i < items.length - 1 && <span aria-hidden="true">/</span>}
      </li>
    ))}
  </ol>
</nav>
```

**Usage:**
```astro
<Breadcrumbs items={[
  { label: "Home", href: "/" },
  { label: "Services", href: "/services" },
  { label: "Current Page" }
]} />
```

**Verify:**
```bash
# Validate Schema.org
curl -s https://{{DOMAIN}}/page | grep -c 'BreadcrumbList'  # Should be >= 1
# Google Rich Results Test: https://search.google.com/test/rich-results
```

### SEO: Complete Favicon Set

```html
<!-- In <head> — all common favicon formats -->
<link rel="icon" type="image/svg+xml" href="/favicon.svg" />
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png" />
<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png" />
<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
<link rel="manifest" href="/site.webmanifest" />
<meta name="theme-color" content="#ffffff" />
```

```json
// public/site.webmanifest
{
  "name": "{{COMPANY_NAME}}",
  "short_name": "{{SHORT_NAME}}",
  "icons": [
    { "src": "/android-chrome-192x192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/android-chrome-512x512.png", "sizes": "512x512", "type": "image/png" }
  ],
  "theme_color": "#ffffff",
  "background_color": "#ffffff",
  "display": "standalone"
}
```

**Tool:** [realfavicongenerator.net](https://realfavicongenerator.net/) — generates all formats from a single SVG/PNG.

**Verify:**
```bash
curl -sI https://{{DOMAIN}}/favicon.svg | head -1  # 200 OK
curl -sI https://{{DOMAIN}}/apple-touch-icon.png | head -1  # 200 OK
curl -sI https://{{DOMAIN}}/site.webmanifest | head -1  # 200 OK
```

### SEO: og:image Validation

```bash
#!/bin/bash
# Check og:image for all pages in sitemap
SITE="https://{{DOMAIN}}"

# 1. Extract all URLs from sitemap
URLS=$(curl -s "$SITE/sitemap-index.xml" | grep -oP '<loc>\K[^<]+')

for URL in $URLS; do
  # 2. Extract og:image
  OG_IMG=$(curl -s "$URL" | grep -oP 'property="og:image".*?content="\K[^"]+')

  if [ -z "$OG_IMG" ]; then
    echo "MISSING: $URL — no og:image"
    continue
  fi

  # 3. Check image size (Content-Length header)
  SIZE=$(curl -sI "$OG_IMG" | grep -i content-length | awk '{print $2}' | tr -d '\r')

  echo "OK: $URL > $OG_IMG (${SIZE:-unknown} bytes)"
done
```

**Recommended:** og:image at least 1200x630px, max 8MB, format: JPG/PNG/WebP.

**Verify:**
```bash
# Check single page
curl -s https://{{DOMAIN}} | grep 'og:image'
# Expected: property="og:image" content="https://..."
```

### SEO: max-image-preview and Social Preview

```html
<!-- In <head> — allow Google to show large preview images -->
<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1" />
```

**Note:** `max-image-preview:large` allows Google to show larger images in search results (e.g. in Discover, News).

**Verify:**
```bash
curl -s https://{{DOMAIN}} | grep 'max-image-preview'
# Expected: max-image-preview:large in robots meta tag
```
