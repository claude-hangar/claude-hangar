# Astro Stack

Framework-specific extensions for [Astro](https://astro.build/) projects (SSG/SSR).

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Astro migration and best-practice audit skill (`/astro-audit`) |
| `CLAUDE.md.snippet` | Paste-ready section for your project's CLAUDE.md |
| `fix-templates.md` | Quick-fix templates for common Astro findings |
| `versions/` | Version-specific checklists and changelogs |

## CLAUDE.md.snippet

Copy the contents of `CLAUDE.md.snippet` into your project's `CLAUDE.md` to give Claude Code
Astro-specific context. This covers:

- SSG vs SSR output modes
- Content Collections and the Content Layer API
- View Transitions
- Astro components vs framework islands
- Tailwind CSS v4 integration patterns

## Version Checklists

| Directory | Covers |
|-----------|--------|
| `versions/v5-stable/` | Best practices for Astro 5.x |
| `versions/v6-beta/` | Migration guide Astro 5 to 6 (74 checkpoints) |
| `versions/v6-stable/` | Best practices for Astro 6.x stable |

## Usage

```bash
# Run the Astro audit skill
/astro-audit start

# Check for new Astro releases
/astro-audit refresh
```

## Related Stacks

- `database/` — If your Astro project uses Drizzle ORM
- `auth/` — If your Astro project has custom auth
