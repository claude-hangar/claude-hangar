---
name: form-actions-csrf
stack: sveltekit
category: security
effort_min: 1
effort_max: 4
---

# Lens: Form Actions & CSRF

Single-concern audit of SvelteKit form actions for CSRF, auth, validation, file
uploads, and redirect safety. Read-only — never modifies files.

## What this lens checks

1. **CSRF origin check enabled** — `svelte.config.js` has `csrf.checkOrigin` not
   explicitly `false`. Note this only blocks cross-origin POSTs; SameSite cookie
   attribute on the session cookie is still required for full CSRF defense. Flag
   session cookies without `SameSite=Lax` or `Strict`.
2. **`csrf.external` allowlist reviewed** — the external-origin allowlist is a
   common footgun; flag non-empty lists for manual review.
3. **Authorization inside the action** — mutating actions check `event.locals.user`
   (and any required role / permission) before the mutation. Heuristic for "public":
   action lives in a route matching the project's public-routes allowlist; otherwise
   auth is required.
4. **Input validation at the boundary** — every action validates `formData` via Zod
   / Valibot / custom schema before values flow into DB writes. Raw `formData.get()`
   passed straight to `insert/update` is a finding.
5. **File upload hygiene** — actions receiving `File` objects must: (a) check MIME
   type via magic-byte sniffing, not the client-supplied `.type` header, (b) enforce
   a max size, (c) sanitize or regenerate filenames (no path traversal). Lens flags
   any `formData.get(...) instanceof File` path missing these.
6. **Safe redirects** — `redirect(303, target)` with `target` from user input must
   URL-parse and check the host. String heuristics ("starts with /") are bypassable
   via `//evil.com` (protocol-relative). Use `new URL(target, url)` and compare
   `host`, or maintain an explicit path allowlist.
7. **Error handling discloses nothing sensitive** — `fail(400, { message: err.message })`
   leaks ORM / DB internals when `err` is a database error. Sanitize before returning.
8. **Rate limiting on public actions** — login, signup, password-reset, 2FA-verify,
   and contact form flagged if no rate-limit reference (middleware / `hooks.server.ts`
   / upstream reverse proxy rule).

## Anti-pattern examples

```ts
// DON'T — open redirect: protocol-relative URL bypasses "starts with /" check
const next = formData.get('next') as string;
if (next.startsWith('/')) throw redirect(303, next);  // //evil.com also "starts with /"

// DO — parse and verify
const next = formData.get('next') as string;
const url = new URL(next, request.url);
if (url.host !== request.url.host) throw redirect(303, '/');
throw redirect(303, url.pathname + url.search);
```

## Signals to extract

- Count form actions across `+page.server.ts`
- `csrf.checkOrigin: false` in `svelte.config.js`
- Session cookie declarations without SameSite=Lax/Strict
- `csrf.external` non-empty
- Mutating actions without auth check (excluding allowlisted public routes)
- Actions without input validation before DB writes
- File-upload actions without MIME check / size limit / filename sanitization
- Redirects with targets derived from user input and no URL-parse validation
- Public actions (login/signup/reset/verify/contact) without rate-limit reference
- Error handlers returning raw `err.message` from DB errors

## Report template

```markdown
### Form Actions & CSRF Lens
- Total actions: {N}
- CSRF protection: {enabled|disabled|external-allowlist-review-needed}
- Session cookie SameSite: {strict|lax|none|missing}
- Actions without validation: {M}
- Actions without auth check: {K}
- File uploads without MIME/size/filename hygiene: {F}
- Open-redirect candidates: {J}
- Public actions without rate limit: {L}
```

## Severity mapping

- CRITICAL — `csrf.checkOrigin: false` set explicitly
- CRITICAL — open-redirect via unvalidated form input (URL-parse bypass possible)
- CRITICAL — file-upload action without MIME check (RCE / XSS via content-type confusion)
- HIGH — mutating action without auth check
- HIGH — no input validation before DB write
- HIGH — session cookie without SameSite attribute
- HIGH — public auth action (login/reset/verify) without rate limit
- MEDIUM — file-upload without size limit (DoS risk)
- MEDIUM — `csrf.external` allowlist populated without documented justification
- LOW — error message exposes ORM internals
- LOW — filename not sanitized (risk depends on downstream consumer)

## Notes

- Read-only. Lens never modifies files.
- Public-routes allowlist read from `hangar.config.js` if present.
- Reference: https://kit.svelte.dev/docs/form-actions
- Reference: https://kit.svelte.dev/docs/configuration#csrf
