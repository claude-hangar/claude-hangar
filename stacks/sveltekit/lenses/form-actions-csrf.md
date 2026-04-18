---
name: form-actions-csrf
stack: sveltekit
category: security
effort_min: 1
effort_max: 4
---

# Lens: Form Actions & CSRF

Single-concern audit of SvelteKit form actions for CSRF, validation, and redirect safety.

## What this lens checks

1. **CSRF protection enabled** — `svelte.config.js` has `csrf.checkOrigin` not disabled
   (default true). Flag any explicit `false`.
2. **Validation at boundary** — every form action validates `formData` via Zod / Valibot
   / explicit checks; no raw `formData.get()` flowing into DB writes.
3. **Authorization in action** — mutating actions check `event.locals.user` and required
   role/permission before performing the mutation.
4. **Safe redirects** — `redirect(303, target)` uses an allowlist or relative paths;
   never `redirect(303, formData.get('next'))` without validation (open-redirect).
5. **Error handling discloses nothing sensitive** — `fail(400, { message: err.message })`
   reviewed; raw DB / ORM errors must be sanitized.
6. **Rate limiting consideration** — public-facing actions (login, signup, password reset,
   contact form) flagged if no rate-limit middleware/hook detected.

## Signals to extract

- Count form actions across `+page.server.ts`
- Actions without input validation
- Actions without auth check (excluding public ones like login/signup)
- Actions with redirect targets from user input
- Public actions without rate-limit reference

## Report template

```markdown
### Form Actions & CSRF Lens
- Total actions: {N}
- CSRF protection: {enabled|disabled}
- Actions without validation: {M}
- Actions without auth check: {K}
- Open-redirect candidates: {J}
- Public actions without rate limit: {L}
```

## Severity mapping

- CRITICAL — `csrf.checkOrigin: false` set explicitly
- CRITICAL — open-redirect via unvalidated form input
- HIGH — mutating action without auth check
- HIGH — no input validation, value flows into DB write
- MEDIUM — public action without rate-limit reference
- LOW — error message exposes ORM internals
