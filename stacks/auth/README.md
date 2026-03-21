# Auth Stack

Authentication patterns for custom bcrypt + session-based auth (no external auth providers).

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Auth security audit skill (`/auth-audit`) |
| `CLAUDE.md.snippet` | Paste-ready section for your project's CLAUDE.md |
| `fix-templates.md` | Quick-fix templates for common auth findings |
| `state-schema.md` | State schema for audit persistence |

## CLAUDE.md.snippet

Copy the contents of `CLAUDE.md.snippet` into your project's `CLAUDE.md` to give Claude Code
auth-specific context. This covers:

- Password hashing with bcryptjs
- Server-side session management
- Secure cookie configuration
- CSRF protection
- Rate limiting on auth endpoints

## Scope

This stack covers **custom auth only**:
- bcryptjs / argon2 password hashing
- Server-side sessions stored in database
- Secure cookie handling

**Out of scope:** NextAuth, Lucia, Auth.js, Supabase Auth, OAuth providers.

## Usage

```bash
# Run the auth audit skill
/auth-audit start

# OWASP ASVS coverage report
/auth-audit report
```

## Related Stacks

- `database/` — User and session table schema patterns
- `sveltekit/` — SvelteKit hooks for auth guards
