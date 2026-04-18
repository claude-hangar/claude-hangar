---
name: server-load-security
stack: sveltekit
category: security
effort_min: 2
effort_max: 6
---

# Lens: Server Load Security

Single-concern audit of SvelteKit server-side load functions for auth bypass and
data leaks. Read-only — never modifies files.

## What this lens checks

1. **Auth gating on protected routes** — `+page.server.ts` / `+layout.server.ts` calls
   `event.locals.user` (or stack convention `event.locals.session.user`) and redirects
   on missing session. **Heuristic (invert the allowlist, not the blocklist):** treat
   every route as protected *except* an explicit allowlist (`/`, `/login`, `/signup`,
   `/reset-password`, `/about`, anything under `/(public)`). Routes under `(authed)`
   route groups must never match the allowlist.
2. **No secret leakage via load return** — load return values end up serialized to the
   client. Flag any object containing fields whose name matches (substring, case-insensitive):
   `password`, `passwordHash`, `apiKey`, `secret`, `token`, `sessionToken`, `csrfToken`,
   `refreshToken`, `passwordResetToken`, `mfaSecret`, `totpSecret`, `recoveryCode`,
   `internalNotes`, `stripeCustomerId`, `privateKey`, `webhook`. Prefer explicit
   field-picking (`{ id, name, email }`) over spreading the full user object.
3. **`locals` usage discipline** — only `event.locals.*` for per-request state.
   Module-level mutable state (`let count = 0` at file top, mutated inside a load
   function) creates race conditions across concurrent requests.
4. **`parent()` chain isolation** — `parent()` calls in nested layouts must not
   depend on client-controlled route params without re-validation.

(Form-action authorization is out of scope here — covered by `form-actions-csrf` lens
to avoid duplicate findings.)

## Anti-pattern example

```ts
// DON'T — leaks passwordHash, sessionToken to client bundle
export const load = async ({ locals }) => {
  return { user: locals.user };  // full user object with hash, tokens, ...
};

// DO — pick only what the page needs
export const load = async ({ locals }) => {
  if (!locals.user) throw redirect(303, '/login');
  const { id, email, name, avatarUrl } = locals.user;
  return { user: { id, email, name, avatarUrl } };
};
```

## Signals to extract

- Count of `+page.server.ts` / `+layout.server.ts` files
- Files under non-allowlisted routes without a `locals.user` / `locals.session` check
- Load returns spreading full user/session objects (vs. explicit field pick)
- Load returns matching any secret-name substring pattern
- Module-level `let` / `var` declarations in `*.server.ts` files that are mutated

## Report template

```markdown
### Server Load Security Lens
- Server load files: {N}
- Missing auth on non-allowlisted routes: {M} (list)
- Potential secret leaks via load return: {K}
- Module-level mutable state: {J}
- Unvalidated `parent()` chains: {P}
- Top 3 issues:
  1. {file:line — issue — recommended fix}
```

## Severity mapping

- CRITICAL — load returns plaintext password / password hash / session token / refresh token
- CRITICAL — load spreads a full user object containing any secret-named field
- HIGH — non-allowlisted route lacks auth check
- HIGH — module-level mutable state in `*.server.ts`
- MEDIUM — load return includes PII-sensitive identifier (Stripe customer, internal notes)
   not strictly needed by the page
- LOW — nested `parent()` chain reads unvalidated client input

## Notes

- Read-only. No file modifications.
- Public-route allowlist is project-configurable via `hangar.config.js`
  `publicRoutes: string[]`; lens falls back to the default list above.
- Session-convention detection: lens reads `src/hooks.server.ts` to determine whether
  the project uses `locals.user` (direct) or `locals.session.user` (nested).
- Reference: https://kit.svelte.dev/docs/load
