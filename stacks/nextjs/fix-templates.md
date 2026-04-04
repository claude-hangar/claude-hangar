# Next.js — Fix Templates

Common fixes for Next.js audit findings. Copy-paste ready.

---

## NXT-CFG-02: Standalone Output for Docker

```js
// next.config.mjs
export default {
  output: 'standalone',
  // ... other config
};
```

## NXT-RSC-05: Server-Only Import Guard

```ts
// src/lib/server/db.ts
import 'server-only';
import { drizzle } from 'drizzle-orm/postgres-js';
// This module will throw a build error if imported from a client component
```

## NXT-SEC-02: Server Action with Validation

```ts
// app/actions.ts
'use server';

import { z } from 'zod';
import { auth } from '@/lib/auth';

const schema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
});

export async function createPost(formData: FormData) {
  const session = await auth();
  if (!session) throw new Error('Unauthorized');

  const data = schema.parse({
    title: formData.get('title'),
    content: formData.get('content'),
  });

  // ... DB operation
}
```

## NXT-SEC-03: Middleware Auth Guard

```ts
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const publicPaths = ['/', '/login', '/register', '/api/auth'];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Allow public paths
  if (publicPaths.some(p => pathname.startsWith(p))) {
    return NextResponse.next();
  }

  // Check session cookie
  const session = request.cookies.get('session');
  if (!session) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
```

## NXT-DCI-01: Standalone Dockerfile

```dockerfile
# Stage 1: Dependencies
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

# Stage 2: Build
FROM node:22-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Runner
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs
COPY --from=build /app/public ./public
COPY --from=build --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=build --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT=3000 HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
```

## NXT-PERF-02: Self-Hosted Fonts (GDPR)

```ts
// app/layout.tsx
import localFont from 'next/font/local';

const inter = localFont({
  src: [
    { path: '../public/fonts/Inter-Regular.woff2', weight: '400' },
    { path: '../public/fonts/Inter-Medium.woff2', weight: '500' },
    { path: '../public/fonts/Inter-Bold.woff2', weight: '700' },
  ],
  variable: '--font-inter',
  display: 'swap',
});

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={inter.variable}>
      <body>{children}</body>
    </html>
  );
}
```

## NXT-META-01: Metadata with generateMetadata

```ts
// app/blog/[slug]/page.tsx
import type { Metadata } from 'next';

export async function generateMetadata({ params }): Promise<Metadata> {
  const post = await getPost(params.slug);
  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [{ url: post.image, width: 1200, height: 630 }],
    },
  };
}
```
