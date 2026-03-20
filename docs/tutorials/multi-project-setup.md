# Tutorial: Multi-Project Setup

Configure Claude Hangar to manage multiple projects from a single registry, with project-specific CLAUDE.md files deployed by a single command.

## What You Will Build

A registry with three projects -- a marketing website (Astro), a web application (SvelteKit), and a backend API (Fastify) -- each with tailored instructions while sharing global hooks and skills.

## Step 1: Create Project Configurations

For each project, create a directory under `registry/projects/` with a CLAUDE.md file.

**`registry/projects/marketing-site/CLAUDE.md`** -- defines stack (Astro, Tailwind, Docker), conventions (self-hosted fonts, no client JS), and quality targets (Lighthouse >90, WCAG AA).

**`registry/projects/web-app/CLAUDE.md`** -- defines stack (SvelteKit, PostgreSQL, Drizzle, bcryptjs), conventions (Svelte 5 runes, form actions, server-only code in +page.server.ts).

**`registry/projects/backend-api/CLAUDE.md`** -- defines stack (Fastify, PostgreSQL, JWT), conventions (Fastify schema validation, pino logging, auto-generated OpenAPI spec).

Each CLAUDE.md should include: project description, stack, conventions, and quality standards.

## Step 2: Configure the Registry

Create or update `registry/registry.json`:

```json
{
  "projects": [
    {
      "name": "marketing-site",
      "repo": "https://github.com/your-org/marketing-site.git",
      "defaultPath": "~/projects/marketing-site",
      "stack": ["astro", "tailwind-v4", "docker"]
    },
    {
      "name": "web-app",
      "repo": "https://github.com/your-org/web-app.git",
      "defaultPath": "~/projects/web-app",
      "stack": ["sveltekit", "postgresql", "tailwind-v4", "docker"]
    },
    {
      "name": "backend-api",
      "repo": "https://github.com/your-org/backend-api.git",
      "defaultPath": "~/projects/backend-api",
      "stack": ["fastify", "postgresql", "docker"]
    }
  ]
}
```

## Step 3: Run Setup

```bash
bash setup.sh
```

The setup script processes three phases:

1. **Phase 1 -- Global:** Deploys `core/` to `~/.claude/` (hooks, agents, skills, statusline)
2. **Phase 2 -- Projects:** For each registry entry -- checks path, clones repo if needed, deploys CLAUDE.md and project-specific configs
3. **Phase 3 -- Infrastructure (optional):** Runs infrastructure setup if configured

On the first run, setup asks for each project path. Choices are saved in `.local-config.json` (gitignored). Subsequent runs use saved paths automatically.

## Step 4: Verify

```bash
bash setup.sh --verify
```

Confirms global config is deployed and each project has its CLAUDE.md in place.

## Managing Projects

**Adding:** Create `registry/projects/{name}/CLAUDE.md`, add entry to `registry/registry.json`, run `bash setup.sh`.

**Updating:** Edit the master copy in `registry/projects/{name}/CLAUDE.md`, run `bash setup.sh` to sync.

**Removing:** Remove the entry from `registry/registry.json`. The deployed CLAUDE.md at the project path is not deleted.

## How It Works in Practice

When you open Claude Code in any registered project, it reads the deployed CLAUDE.md for project-specific instructions. Global hooks and skills from `~/.claude/` are available everywhere:

```
~/.claude/                    -- Global (all projects)
  hooks/                      -- bash-guard, secret-leak-check, etc.
  skills/                     -- audit, adversarial-review, polish, etc.
  settings.json               -- Hook registration, statusline

~/projects/marketing-site/    -- Project-specific
  CLAUDE.md                   -- From registry (master copy in claude-hangar)
  .audit-state.json           -- Created by /audit at runtime
```

## Path Overrides

If a project lives at a non-default path, override it in `.local-config.json`:

```json
{
  "projects": {
    "marketing-site": {
      "path": "D:/work/marketing-site"
    }
  }
}
```

This file is gitignored and machine-specific. The registry keeps standard defaults while `.local-config.json` handles local deviations.
