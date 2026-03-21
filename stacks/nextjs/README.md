# Next.js Stack

Framework-specific extensions for [Next.js](https://nextjs.org/) projects using the App Router.

## What's Included

| File | Purpose |
|------|---------|
| `CLAUDE.md.snippet` | Paste-ready section for your project's CLAUDE.md |

## CLAUDE.md.snippet

Copy the contents of `CLAUDE.md.snippet` into your project's `CLAUDE.md` to give Claude Code
Next.js-specific context. This covers:

- App Router conventions (Server Components, Client Components)
- Server Actions for mutations
- Route handlers (API routes)
- Middleware patterns
- Metadata and SEO

## Usage

Paste the snippet into your project CLAUDE.md:

```bash
cat stacks/nextjs/CLAUDE.md.snippet >> your-project/CLAUDE.md
```

## Related Stacks

- `database/` — Drizzle ORM integration patterns
- `auth/` — Custom auth with Next.js middleware
