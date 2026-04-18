---
name: server-load-security
stack: sveltekit
category: security
effort_min: 2
effort_max: 6
---

# Lens: Server Load Security

Single-concern audit of SvelteKit server-side load functions for auth bypass and data leaks.

## What this lens checks

1. **Auth gating** — `+page.server.ts` / `+layout.server.ts` for protected routes calls
   `event.locals.user` (or equivalent) and `throw redirect(303, '/login')` on missing session.
2. **No secret leakage via return** — load functions never return objects containing
   `password`, `passwordHash`, `apiKey`, `secret`, `token`, `sessionToken`, `csrfToken`,
   or other server-only fields. These end up in the client bundle.
3. **`locals` usage discipline** — only `event.locals.*` for per-request state; never
   imported module-level mutable state (race conditions across requests).
4. **`fetch` parent isolation** — `parent()` calls in nested layouts do not depend on
   client-controlled data without re-validation.
5. **Form action authorization** — `actions` exports check `event.locals.user` before
   any mutation; never trust hidden form fields for user identity.

## Signals to extract

- Count of `+page.server.ts` / `+layout.server.ts` files
- Files missing auth check on protected routes (heuristic: route under `/admin`, `/account`, `/api`)
- Load functions returning objects with secret-named fields
- Module-level `let` / `var` in `*.server.ts` that mutate

## Report template

```markdown
### Server Load Security Lens
- Server load files: {N}
- Missing auth on protected routes: {M} (list)
- Potential secret leaks via load return: {K}
- Module-level mutable state: {J}
- Top 3 issues:
  1. {file:line — issue}
```

## Severity mapping

- CRITICAL — load function returns plaintext password / session token to client
- HIGH — protected route load function lacks auth check
- HIGH — module-level mutable state in `*.server.ts`
- MEDIUM — form action accepts user ID from form body without re-checking session
- LOW — nested `parent()` chain depends on unvalidated client input
