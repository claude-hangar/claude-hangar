# SvelteKit Stack

Framework-specific extensions for [SvelteKit](https://svelte.dev/docs/kit) projects (SSR/SSG) with Svelte 5.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | SvelteKit and Svelte 5 audit skill (`/sveltekit-audit`) |
| `CLAUDE.md.snippet` | Paste-ready section for your project's CLAUDE.md |
| `fix-templates.md` | Quick-fix templates for common SvelteKit findings |
| `versions/` | Version-specific checklists |

## CLAUDE.md.snippet

Copy the contents of `CLAUDE.md.snippet` into your project's `CLAUDE.md` to give Claude Code
SvelteKit-specific context. This covers:

- Svelte 5 runes (`$state`, `$derived`, `$effect`)
- Load functions (universal vs server)
- Form actions with progressive enhancement
- SvelteKit hooks and middleware
- Routing conventions

## Version Checklists

| Directory | Covers |
|-----------|--------|
| `versions/kit2-svelte5/` | Best practices for SvelteKit 2 + Svelte 5 (48 checkpoints) |

## Usage

```bash
# Run the SvelteKit audit skill
/sveltekit-audit start

# Check for new SvelteKit/Svelte releases
/sveltekit-audit refresh
```

## Related Stacks

- `database/` — Drizzle ORM integration patterns for SvelteKit
- `auth/` — Custom auth with SvelteKit hooks and form actions
