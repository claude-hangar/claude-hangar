# Astro Audit: Quick-Fix Templates

Ready-made fix templates for common Astro migration/best-practice findings.
For each fix: 1. Show template, 2. User confirmation, 3. Implement, 4. Verify.

---

## ENV — Environment

### MIG: Node Version Too Old

```bash
# Create/update .nvmrc (v24 = Active LTS, Astro 6 Minimum: v22.12.0)
echo "24" > .nvmrc

# Update Dockerfile
# FROM node:18-alpine  ->  FROM node:24-alpine
# FROM node:20-alpine  ->  FROM node:24-alpine

# Update CI (.github/workflows/*.yml)
# node-version: '18'  ->  node-version-file: '.nvmrc'

# Local
nvm install 24
nvm use 24
```

**Verify:** `node -v` -> v24.x on ALL environments (local, CI, Docker, VPS)?

---

## CFG — Configuration

### MIG: Old Astro Config Syntax

```javascript
// Before (CJS or outdated patterns):
// const { defineConfig } = require('astro/config');
// module.exports = defineConfig({...});

// After (ESM — required):
import { defineConfig } from 'astro/config';
export default defineConfig({
  // Config here
});
```

**Verify:** `npx astro check` -> no config errors?

### MIG: Outdated Experimental Flags

```javascript
// astro.config.mjs — Remove flags that are now stable
export default defineConfig({
  // REMOVE (now stable in v6):
  // experimental: {
  //   contentLayer: true,    <- stable since v5
  //   fonts: true,           <- stable in v6
  //   responsiveImages: true <- check if stable
  // }
});
```

**Verify:** `npx astro build` -> no warnings about deprecated flags?

---

## CODE — Code Migration

### MIG: Replace Astro.glob()

```javascript
// Before (deprecated in v5, removed in v6):
const posts = await Astro.glob('./posts/*.md');

// After:
const posts = Object.values(
  import.meta.glob('./posts/*.md', { eager: true })
);

// Or better — use Content Collections:
import { getCollection } from 'astro:content';
const posts = await getCollection('blog');
```

**Verify:** `grep -rn 'Astro.glob' src/` -> 0 matches?

### MIG: ViewTransitions -> ClientRouter

```astro
<!-- Before (v4 name, deprecated in v5): -->
<!-- import { ViewTransitions } from 'astro:transitions'; -->
<!-- <ViewTransitions /> -->

<!-- After: -->
---
import { ClientRouter } from 'astro:transitions';
---
<ClientRouter />
```

**Verify:** `grep -rn 'ViewTransitions' src/` -> 0 matches?

### MIG: getStaticPaths Strings Instead of Numbers

```javascript
// Before (can cause issues):
return pages.map(page => ({
  params: { id: page.id }  // id is number
}));

// After (safe):
return pages.map(page => ({
  params: { id: String(page.id) }  // always String
}));
```

---

## COLL — Content Collections

### MIG: Legacy Collections -> Content Layer API

```typescript
// src/content.config.ts (new file name!)
// Before: src/content/config.ts

import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';  // New loader

const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    date: z.coerce.date(),
    description: z.string().optional(),
    draft: z.boolean().default(false),
  }),
});

export const collections = { blog };
```

**Verify:** `npx astro build` -> Collections load correctly?

### MIG: Correct Zod Import

```typescript
// Before (works but fragile):
import { z } from 'zod';

// After (official, future-proof):
import { z } from 'astro:content';
// OR
import { z } from 'astro/zod';
```

**Verify:** `grep -rn "from 'zod'" src/` -> 0 matches (only astro:content/astro/zod)?

---

## ADPT — Adapter

### MIG: Update Adapter to v6

```bash
# Update all @astrojs packages
npx npm-check-updates -u '/^@astrojs/' && npm install

# Specifically:
npm install @astrojs/node@latest
# or
npm install @astrojs/cloudflare@latest
# or
npm install @astrojs/vercel@latest
```

**Verify:** `npx astro build` -> no adapter errors?

### MIG: Adapter Config Changes (Node)

```javascript
// astro.config.mjs
import node from '@astrojs/node';

export default defineConfig({
  // IMPORTANT: 'hybrid' does NOT exist in Astro 5+!
  // Instead: 'server' + per-page prerender
  output: 'server',
  adapter: node({
    mode: 'standalone'  // Check: 'middleware' only if needed
  })
});
```

```astro
---
// For static pages: set prerender at page level
// src/pages/about.astro (or any static page)
export const prerender = true;
---
<!-- This page is rendered at build time -->
```

**Migration from `output: 'hybrid'`:**
1. `output: 'hybrid'` -> `output: 'server'` in astro.config.mjs
2. Pages that should be static: add `export const prerender = true`
3. Dynamic pages (SSR) need nothing — they are default with `output: 'server'`

---

## VITE — Vite 7

### MIG: CJS Vite Plugins -> ESM

```javascript
// Before:
// const myPlugin = require('vite-plugin-x');

// After:
import myPlugin from 'vite-plugin-x';

// In astro.config.mjs:
export default defineConfig({
  vite: {
    plugins: [myPlugin()]
  }
});
```

**Verify:** `npx astro build` -> no CJS warnings?

---

## ZOD — Zod 4 (Astro 6)

### MIG: Zod 3 -> Zod 4 Syntax Changes

```typescript
// Most schemas stay the same!
// Check for breaking changes:

// 1. Check z.object().strict() behavior
// 2. z.union() error messages may differ
// 3. Check z.transform() pipeline behavior

// Safest: Always import from astro:content
import { z } from 'astro:content';
```

**Verify:** `npx astro check` -> no type errors in content schemas?

---

## DCI — Docker/CI

### MIG: Update Docker Node Version

```dockerfile
# Before:
FROM node:18-alpine AS build
# or
FROM node:20-alpine AS build

# After:
FROM node:24-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:24-alpine AS runtime
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY package.json .
USER node
EXPOSE 3000
CMD ["node", "./dist/server/entry.mjs"]
```

### MIG: Update CI Node Version

```yaml
# .github/workflows/deploy.yml
steps:
  - uses: actions/setup-node@v4
    with:
      node-version-file: '.nvmrc'  # instead of hardcoded
      cache: 'npm'
```

**Verify:** CI pipeline green? Docker build successful?

---

## PERF — Performance (v5 Best Practices)

### MIG: Enable Image Optimization

```astro
---
import { Image } from 'astro:assets';
import heroImage from '../assets/hero.jpg';
---
<!-- Automatic optimization + responsive -->
<Image
  src={heroImage}
  alt="Hero image"
  widths={[400, 800, 1200]}
  sizes="(max-width: 800px) 100vw, 1200px"
/>
```

### MIG: Configure Prefetch

```javascript
// astro.config.mjs
export default defineConfig({
  prefetch: {
    defaultStrategy: 'viewport',
    prefetchAll: false
  }
});
```

---

## NEW — New v6 Features (optional)

### MIG: Use Fonts API (v6)

```javascript
// astro.config.mjs
export default defineConfig({
  fonts: {
    providers: ['fontsource'],
    families: [
      { name: 'Inter', provider: 'fontsource' }
    ]
  }
});
```

### MIG: Configure CSP (v6)

Astro 6 offers native CSP support via `security.csp`. **Do NOT** use simultaneously with manual CSP headers (Traefik, nginx, meta tag) — this causes conflicts.

**Option A: Astro-native CSP (recommended for Astro 6)**
```javascript
// astro.config.mjs — Astro handles script/style hashing
export default defineConfig({
  security: {
    csp: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],       // Astro adds hashes automatically
        styleSrc: ["'self'"],        // No 'unsafe-inline' needed
        imgSrc: ["'self'", "data:", "https:"],
        fontSrc: ["'self'"],
        connectSrc: ["'self'"],
      }
    }
  }
});
// -> Do NOT set a manual CSP header in the web server!
```

**Option B: Manual CSP Header (for Astro 5 or without security.csp)**
```yaml
# Traefik label or nginx header — WITHOUT security.csp in astro.config
labels:
  - "traefik.http.middlewares.csp.headers.customResponseHeaders.Content-Security-Policy=default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'"
```

**When to use which option:**
- Astro 6 with SSR: Option A (automatic hashing)
- Astro 5 or static with web server control: Option B
- **NEVER both at the same time** — duplicate CSP headers are BOTH enforced (most restrictive wins)

**Verify:** `curl -I https://your-domain.com` -> exactly ONE `Content-Security-Policy` header?
