# Auth Audit: Fix Templates

Ready-made fix templates for common auth security findings.
For each fix: 1. Show template, 2. User confirmation, 3. Implement, 4. Verify.

---

## HASH — bcryptjs Hash + Verify Setup

### AUTH: bcrypt Rounds Too Low / Missing Hashing

```typescript
import bcrypt from 'bcryptjs';

// Recommended: 12 rounds (OWASP ASVS 2.4.4)
// 10 = minimum, 12 = recommended, 14+ = high-security (slower)
const BCRYPT_ROUNDS = 12;

// Hash password (on registration / password change)
async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, BCRYPT_ROUNDS);
}

// Verify password (on login)
// bcrypt.compare() is timing-safe — NEVER compare manually with ===!
async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}
```

**Verify:** `node -e "const b=require('bcryptjs'); b.hash('test',12).then(h=>{console.log(h); b.compare('test',h).then(r=>console.log('match:',r))})"` -> Hash + match: true?

---

## SESS — Session Cookie Config (SvelteKit)

### AUTH: Insecure Session Cookie Configuration

```typescript
// src/lib/server/session.ts
import { dev } from '$app/environment';
import crypto from 'crypto';

const SESSION_EXPIRY_HOURS = 24;
const SESSION_EXPIRY_MS = SESSION_EXPIRY_HOURS * 60 * 60 * 1000;

export function createSessionCookie(cookies: Cookies, sessionId: string) {
  cookies.set('session', sessionId, {
    path: '/',
    httpOnly: true,         // REQUIRED: JavaScript cannot read cookie
    secure: !dev,           // REQUIRED: HTTPS only in production
    sameSite: 'lax',        // REQUIRED: basic CSRF protection
    maxAge: SESSION_EXPIRY_HOURS * 60 * 60  // in seconds
  });
}

export function generateSessionId(): string {
  // 128-bit entropy (ASVS 3.2.2)
  return crypto.randomUUID();
}

export function deleteSessionCookie(cookies: Cookies) {
  cookies.delete('session', { path: '/' });
}
```

**Verify:** Browser DevTools -> Application -> Cookies -> Session-Cookie: httpOnly, Secure, SameSite=Lax?

---

## SESS — Session Rotation After Login

### AUTH: No Session Rotation (Session Fixation Possible)

```typescript
// src/routes/login/+page.server.ts
import { generateSessionId, createSessionCookie } from '$lib/server/session';
import { db } from '$lib/server/db';
import bcrypt from 'bcryptjs';

export const actions = {
  default: async ({ request, cookies }) => {
    const data = await request.formData();
    const email = String(data.get('email')).toLowerCase().trim();
    const password = String(data.get('password'));

    const user = await db.getUserByEmail(email);

    // Timing-safe: ALWAYS hash, even if user does not exist
    if (!user) {
      // Dummy hash to prevent timing attack (ASVS 2.2.1)
      await bcrypt.hash(password, 12);
      return { error: 'Invalid credentials.' };
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return { error: 'Invalid credentials.' };
    }

    // IMPORTANT: Delete old session (session fixation prevention)
    const oldSessionId = cookies.get('session');
    if (oldSessionId) {
      await db.deleteSession(oldSessionId);
    }

    // Create new session (ASVS 3.3.2)
    const sessionId = generateSessionId();
    await db.createSession({
      id: sessionId,
      userId: user.id,
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000)
    });

    createSessionCookie(cookies, sessionId);
    return { success: true };
  }
};
```

**Verify:** Login -> old session cookie is replaced -> old session ID deleted from DB?

---

## CSRF — SvelteKit CSRF Protection

### AUTH: CSRF Protection Disabled or Missing

```typescript
// svelte.config.js — Do NOT disable CSRF!
const config = {
  kit: {
    // WRONG — NEVER in production:
    // csrf: { checkOrigin: false }

    // CORRECT — Leave default (checkOrigin: true is the default)
    // SvelteKit automatically checks the Origin header
  }
};

// For additional protection on API endpoints:
// Double-Submit Cookie Pattern

// src/lib/server/csrf.ts
import crypto from 'crypto';

export function generateCsrfToken(): string {
  return crypto.randomBytes(32).toString('hex');
}

export function validateCsrfToken(
  cookieToken: string | undefined,
  headerToken: string | undefined
): boolean {
  if (!cookieToken || !headerToken) return false;
  // Timing-safe comparison
  if (cookieToken.length !== headerToken.length) return false;
  return crypto.timingSafeEqual(
    Buffer.from(cookieToken),
    Buffer.from(headerToken)
  );
}

// src/hooks.server.ts — CSRF for API routes
// (SvelteKit's origin check only applies to form submissions)
export async function handle({ event, resolve }) {
  if (event.url.pathname.startsWith('/api/') && event.request.method !== 'GET') {
    const cookieToken = event.cookies.get('csrf-token');
    const headerToken = event.request.headers.get('x-csrf-token');

    if (!validateCsrfToken(cookieToken, headerToken)) {
      return new Response('CSRF validation failed', { status: 403 });
    }
  }

  return resolve(event);
}
```

**Verify:** `grep -rn 'checkOrigin.*false' svelte.config.*` -> 0 matches? POST ohne Origin -> 403?

---

## LOGIN — Rate Limiting Middleware

### AUTH: Missing Rate Limiting on Login/Registration

```typescript
// src/lib/server/rate-limit.ts

// Option A: In-memory (for single instance)
const attempts = new Map<string, { count: number; resetAt: number }>();

const WINDOW_MS = 15 * 60 * 1000;    // 15-minute window
const MAX_ATTEMPTS = 5;               // Max 5 attempts per window

export function checkRateLimit(key: string): { allowed: boolean; retryAfter?: number } {
  const now = Date.now();
  const entry = attempts.get(key);

  if (!entry || now > entry.resetAt) {
    attempts.set(key, { count: 1, resetAt: now + WINDOW_MS });
    return { allowed: true };
  }

  if (entry.count >= MAX_ATTEMPTS) {
    const retryAfter = Math.ceil((entry.resetAt - now) / 1000);
    return { allowed: false, retryAfter };
  }

  entry.count++;
  return { allowed: true };
}

// Cleanup old entries (every 5 minutes)
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of attempts) {
    if (now > entry.resetAt) attempts.delete(key);
  }
}, 5 * 60 * 1000);

// Option B: Redis-backed (for multi-instance)
// import { createClient } from 'redis';
// const redis = createClient({ url: process.env.REDIS_URL });
//
// export async function checkRateLimitRedis(key: string): Promise<{ allowed: boolean; retryAfter?: number }> {
//   const redisKey = `rate-limit:${key}`;
//   const current = await redis.incr(redisKey);
//   if (current === 1) await redis.expire(redisKey, WINDOW_MS / 1000);
//   if (current > MAX_ATTEMPTS) {
//     const ttl = await redis.ttl(redisKey);
//     return { allowed: false, retryAfter: ttl };
//   }
//   return { allowed: true };
// }

// Usage in +page.server.ts:
// const ip = event.getClientAddress();
// const { allowed, retryAfter } = checkRateLimit(`login:${ip}`);
// if (!allowed) {
//   return fail(429, { error: `Too many attempts. Wait ${retryAfter} seconds.` });
// }
```

**Verify:** 6x login with wrong password -> 429 response on 6th attempt?

---

## REG — Password Policy Validation

### AUTH: Missing or Weak Password Policy

```typescript
// src/lib/server/password-policy.ts

interface PolicyResult {
  valid: boolean;
  errors: string[];
}

// OWASP ASVS 2.1.1: Min 8 characters
// OWASP ASVS 2.1.2: Max at least 64 characters allowed
// OWASP ASVS 2.1.7: Breached-password check or complexity (zxcvbn approach)
const MIN_LENGTH = 8;
const MAX_LENGTH = 128;  // bcrypt has 72-byte limit, but UI may allow more

export function validatePasswordPolicy(password: string): PolicyResult {
  const errors: string[] = [];

  if (password.length < MIN_LENGTH) {
    errors.push(`At least ${MIN_LENGTH} characters required.`);
  }

  if (password.length > MAX_LENGTH) {
    errors.push(`Maximum ${MAX_LENGTH} characters allowed.`);
  }

  // Simple complexity (alternative: zxcvbn for strength scoring)
  if (!/[a-z]/.test(password)) {
    errors.push('At least one lowercase letter required.');
  }

  if (!/[A-Z]/.test(password)) {
    errors.push('At least one uppercase letter required.');
  }

  if (!/[0-9]/.test(password)) {
    errors.push('At least one digit required.');
  }

  // Optional: Check common passwords
  const commonPasswords = ['password', '12345678', 'qwerty123', 'admin123'];
  if (commonPasswords.includes(password.toLowerCase())) {
    errors.push('This password is too common.');
  }

  return { valid: errors.length === 0, errors };
}

// Advanced: zxcvbn approach (npm install zxcvbn)
// import zxcvbn from 'zxcvbn';
// const result = zxcvbn(password);
// if (result.score < 3) errors.push('Password too weak.');
```

**Verify:** Register with "abc" -> error message? With "Abc12345" -> accepted?

---

## LOGIN — Account Lockout Logic (Progressive Delays)

### AUTH: No Account Lockout / No Progressive Delay

```typescript
// src/lib/server/account-lockout.ts
import { db } from '$lib/server/db';

const MAX_ATTEMPTS = 5;
const LOCKOUT_DURATIONS_MS = [
  0,              // 1st failed attempt: no delay
  0,              // 2nd: no delay
  0,              // 3rd: no delay
  30 * 1000,      // 4th: 30 seconds
  60 * 1000,      // 5th: 1 minute
  5 * 60 * 1000,  // 6th+: 5 minutes
];

export async function checkAccountLockout(userId: string): Promise<{
  locked: boolean;
  retryAfter?: number;
}> {
  const user = await db.getUser(userId);
  if (!user) return { locked: false };

  const { failedAttempts, lockedUntil } = user;

  // Current lock active?
  if (lockedUntil && new Date(lockedUntil) > new Date()) {
    const retryAfter = Math.ceil((new Date(lockedUntil).getTime() - Date.now()) / 1000);
    return { locked: true, retryAfter };
  }

  return { locked: false };
}

export async function recordFailedAttempt(userId: string): Promise<void> {
  const user = await db.getUser(userId);
  if (!user) return;

  const attempts = (user.failedAttempts || 0) + 1;
  const lockIndex = Math.min(attempts, LOCKOUT_DURATIONS_MS.length - 1);
  const lockDuration = LOCKOUT_DURATIONS_MS[lockIndex];

  await db.updateUser(userId, {
    failedAttempts: attempts,
    lockedUntil: lockDuration > 0
      ? new Date(Date.now() + lockDuration).toISOString()
      : null
  });
}

export async function resetFailedAttempts(userId: string): Promise<void> {
  await db.updateUser(userId, {
    failedAttempts: 0,
    lockedUntil: null
  });
}

// DB Schema Erweiterung (Drizzle):
// failedAttempts: integer('failed_attempts').default(0),
// lockedUntil: text('locked_until'),
```

**Verify:** 5x wrong password -> account temporarily locked? After lockout period -> login possible?

---

## RESET — Password Reset Flow

### AUTH: Insecure or Missing Password Reset

```typescript
// src/lib/server/password-reset.ts
import crypto from 'crypto';
import { db } from '$lib/server/db';

const RESET_TOKEN_EXPIRY_MS = 60 * 60 * 1000; // 1 Stunde (ASVS 2.5.2)

export async function createPasswordResetToken(email: string): Promise<string | null> {
  const user = await db.getUserByEmail(email.toLowerCase().trim());

  // IMPORTANT: Same response regardless of whether user exists (ASVS 2.5.1)
  if (!user) return null;

  // 256-bit token (ASVS 2.5.6)
  const token = crypto.randomBytes(32).toString('hex');
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

  // Store hash in DB, NOT the token itself
  await db.createPasswordResetToken({
    userId: user.id,
    tokenHash,
    expiresAt: new Date(Date.now() + RESET_TOKEN_EXPIRY_MS).toISOString(),
    used: false
  });

  // Invalidate all old tokens for this user
  await db.invalidateOldResetTokens(user.id);

  return token; // Send this token via email
}

export async function validateAndConsumeResetToken(token: string): Promise<string | null> {
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

  const resetEntry = await db.getPasswordResetByHash(tokenHash);

  if (!resetEntry) return null;
  if (resetEntry.used) return null;
  if (new Date(resetEntry.expiresAt) < new Date()) return null;

  // Mark token as used (one-time use)
  await db.markResetTokenUsed(resetEntry.id);

  return resetEntry.userId;
}

// DB Schema (Drizzle):
// export const passwordResets = sqliteTable('password_resets', {
//   id: text('id').primaryKey().$defaultFn(() => crypto.randomUUID()),
//   userId: text('user_id').notNull().references(() => users.id),
//   tokenHash: text('token_hash').notNull(),
//   expiresAt: text('expires_at').notNull(),
//   used: integer('used', { mode: 'boolean' }).default(false),
//   createdAt: text('created_at').$defaultFn(() => new Date().toISOString()),
// });
```

**Verify:** Request reset -> token in email? Token after 1h -> expired? Use token 2x -> error?

---

## AUTHZ — hooks.server.ts Auth Guard Pattern (SvelteKit)

### AUTH: Missing or Incomplete Route Protection

```typescript
// src/hooks.server.ts
import { redirect, type Handle } from '@sveltejs/kit';
import { db } from '$lib/server/db';

// Routes that do NOT require login
const PUBLIC_ROUTES = [
  '/',
  '/login',
  '/register',
  '/reset-password',
  '/impressum',
  '/datenschutz'
];

// Routes that require admin role
const ADMIN_ROUTES = [
  '/admin'
];

function isPublicRoute(pathname: string): boolean {
  return PUBLIC_ROUTES.some(route =>
    pathname === route || pathname.startsWith(route + '/')
  );
}

function isAdminRoute(pathname: string): boolean {
  return ADMIN_ROUTES.some(route =>
    pathname === route || pathname.startsWith(route + '/')
  );
}

export const handle: Handle = async ({ event, resolve }) => {
  // Session aus Cookie lesen
  const sessionId = event.cookies.get('session');

  if (sessionId) {
    const session = await db.getSession(sessionId);

    if (session && new Date(session.expiresAt) > new Date()) {
      const user = await db.getUser(session.userId);
      if (user) {
        // Set user in locals (available in all +page.server.ts)
        event.locals.user = {
          id: user.id,
          email: user.email,
          role: user.role
        };
      }
    } else if (session) {
      // Expired session: clean up cookie + DB
      await db.deleteSession(sessionId);
      event.cookies.delete('session', { path: '/' });
    }
  }

  // Route Protection
  const { pathname } = event.url;

  // Public routes: no auth needed
  if (isPublicRoute(pathname)) {
    return resolve(event);
  }

  // Let static assets through
  if (pathname.startsWith('/_app/') || pathname.startsWith('/favicon')) {
    return resolve(event);
  }

  // Not logged in -> login
  if (!event.locals.user) {
    throw redirect(303, `/login?redirect=${encodeURIComponent(pathname)}`);
  }

  // Admin routes: check role
  if (isAdminRoute(pathname) && event.locals.user.role !== 'admin') {
    throw redirect(303, '/');
  }

  return resolve(event);
};
```

```typescript
// src/app.d.ts — TypeScript types for locals
declare global {
  namespace App {
    interface Locals {
      user?: {
        id: string;
        email: string;
        role: 'user' | 'admin';
      };
    }
  }
}

export {};
```

**Verify:** Without login on protected route -> redirect to /login? As user on /admin -> redirect?

---

## AUTHZ — Role-Based Authorization (SvelteKit locals.user Pattern)

### AUTH: Missing Role Check in Server Endpoints

```typescript
// src/lib/server/auth-helpers.ts
import { error, redirect } from '@sveltejs/kit';
import type { RequestEvent } from '@sveltejs/kit';

// Guard: User must be logged in
export function requireAuth(event: RequestEvent) {
  if (!event.locals.user) {
    throw redirect(303, `/login?redirect=${encodeURIComponent(event.url.pathname)}`);
  }
  return event.locals.user;
}

// Guard: User must have specific role
export function requireRole(event: RequestEvent, role: 'admin' | 'user') {
  const user = requireAuth(event);
  if (user.role !== role) {
    throw error(403, 'Access denied.');
  }
  return user;
}

// Guard: User must be owner of the object (IDOR prevention)
export function requireOwnership(event: RequestEvent, ownerId: string) {
  const user = requireAuth(event);
  if (user.id !== ownerId) {
    throw error(403, 'Access denied.');
  }
  return user;
}

// Usage in +page.server.ts:
// export const load = async (event) => {
//   const user = requireAuth(event);
//   // oder: requireRole(event, 'admin');
//   // oder: requireOwnership(event, resource.userId);
// };
```

**Verify:** API call without auth header -> 303? As user on admin endpoint -> 403?

---

## Notes

- **No external auth provider:** These templates are for custom auth. NextAuth, Lucia, Auth.js have their own patterns.
- **OWASP ASVS v4.0.3** is the reference for all recommendations.
- **Security first:** All default values in templates are optimized for security.
- **bcrypt 72-byte limit:** bcrypt only hashes the first 72 bytes. For very long passwords: consider pre-hashing with SHA-256.
- **Production checks:** `secure: !dev` ensures cookies work in development without HTTPS.

---

As of: 2026-03-11
