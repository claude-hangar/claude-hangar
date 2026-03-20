# Tutorial: Multi-Project Setup

This tutorial walks you through configuring Claude Hangar to manage multiple projects from a single registry. You will set up project-specific CLAUDE.md files and deploy configurations with a single command.

## What You Will Build

A registry with three projects:
- A marketing website (Astro)
- A web application (SvelteKit)
- A backend API (Fastify)

Each project gets its own CLAUDE.md with tailored instructions, while sharing the global hooks and skills from Claude Hangar.

## Step 1: Understand the Registry

The registry file (`registry/registry.json`) maps project names to their configuration. Each entry specifies:

- **name:** Project identifier
- **repo:** Git repository URL
- **defaultPath:** Where the project lives on disk
- **stack:** Technology stack (used for deploying stack-specific configs)

## Step 2: Create Project Configurations

For each project, create a directory under `registry/projects/` with a CLAUDE.md file.

### Marketing website

Create `registry/projects/marketing-site/CLAUDE.md`:

```markdown
# Marketing Site -- Project Instructions

## What Is This?

Company marketing website built with Astro and Tailwind CSS v4.
Deployed via Docker + Traefik on Hetzner VPS.

## Stack

- **Frontend:** Astro (SSG, static output)
- **CSS:** Tailwind CSS v4
- **Deployment:** Docker, Traefik reverse proxy
- **Hosting:** Hetzner VPS

## Conventions

- All pages in `src/pages/`
- Components in `src/components/` (Astro components, no framework)
- Self-hosted fonts only (GDPR compliance)
- Images optimized via Astro Image
- No client-side JavaScript unless absolutely necessary

## Quality Standards

- Lighthouse score > 90 on all categories
- WCAG AA compliance
- Core Web Vitals: LCP < 2.5s, CLS < 0.1
```

### Web application

Create `registry/projects/web-app/CLAUDE.md`:

```markdown
# Web App -- Project Instructions

## What Is This?

Internal dashboard built with SvelteKit and PostgreSQL.

## Stack

- **Frontend/Backend:** SvelteKit (SSR)
- **Database:** PostgreSQL via Drizzle ORM
- **Auth:** Custom bcryptjs + sessions
- **CSS:** Tailwind CSS v4

## Conventions

- Svelte 5 runes syntax (no legacy $: reactivity)
- Server-only code in +page.server.ts and +server.ts
- All database queries through Drizzle, never raw SQL
- Form actions for mutations, load functions for reads
```

### Backend API

Create `registry/projects/backend-api/CLAUDE.md`:

```markdown
# Backend API -- Project Instructions

## What Is This?

REST API for mobile app, built with Fastify.

## Stack

- **Runtime:** Node.js
- **Framework:** Fastify
- **Database:** PostgreSQL via Drizzle ORM
- **Auth:** JWT tokens

## Conventions

- Route handlers in `src/routes/`
- Fastify schema validation on all endpoints
- Structured logging with pino
- OpenAPI spec auto-generated from schemas
```

## Step 3: Configure the Registry

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

## Step 4: Run Setup

Deploy all configurations:

```bash
bash setup.sh
```

The setup script processes three phases:

1. **Phase 1 -- Global:** Deploys `core/` to `~/.claude/` (hooks, agents, skills, statusline)
2. **Phase 2 -- Projects:** For each project in the registry:
   - Checks if the project path exists
   - If not, clones the repo
   - Deploys the project-specific CLAUDE.md
   - Deploys any project-specific skills or hooks
3. **Phase 3 -- Infrastructure (optional):** If configured, runs infrastructure setup

### First run

On the first run, the setup script asks for each project path:

```
Project: marketing-site
  Default path: ~/projects/marketing-site
  Use default? [Y/n]:
```

Your choices are saved in `.local-config.json` (gitignored). Subsequent runs use the saved paths automatically.

## Step 5: Verify the Deployment

Check that each project has its CLAUDE.md deployed:

```bash
bash setup.sh --verify
```

This confirms:
- Global config deployed to `~/.claude/`
- Each project's CLAUDE.md is in place
- Hooks and skills are available

You can also verify manually:

```bash
cat ~/projects/marketing-site/CLAUDE.md
cat ~/projects/web-app/CLAUDE.md
cat ~/projects/backend-api/CLAUDE.md
```

Each file should contain the project-specific instructions you created.

## Managing Projects

### Adding a new project

1. Create `registry/projects/{name}/CLAUDE.md` with project instructions
2. Add an entry to `registry/registry.json`
3. Run `bash setup.sh`

### Updating a project's config

1. Edit `registry/projects/{name}/CLAUDE.md` (this is the master copy)
2. Run `bash setup.sh` to sync the change to the project path

### Removing a project

1. Remove the entry from `registry/registry.json`
2. Optionally delete `registry/projects/{name}/`
3. The CLAUDE.md at the project path remains untouched (no destructive cleanup)

## How It Works in Practice

When you open Claude Code in any registered project, it automatically reads the deployed CLAUDE.md and follows the project-specific instructions. At the same time, the global hooks (bash guard, secret leak check, token warning, etc.) and skills (audit, adversarial-review, polish, etc.) are available because they were deployed to `~/.claude/`.

```
~/.claude/                    -- Global (shared across all projects)
  hooks/                      -- bash-guard.sh, secret-leak-check.sh, etc.
  skills/                     -- audit, adversarial-review, polish, etc.
  agents/                     -- explorer, security-reviewer, etc.
  settings.json               -- Hook registration, statusline
  CLAUDE.md                   -- Global instructions

~/projects/marketing-site/    -- Project-specific
  CLAUDE.md                   -- Marketing site instructions (from registry)
  .audit-state.json           -- Audit state (created by /audit)

~/projects/web-app/           -- Project-specific
  CLAUDE.md                   -- Web app instructions (from registry)
```

## Path Overrides

If a project lives at a different path on your machine (e.g., a different drive on Windows), override the default path in `.local-config.json`:

```json
{
  "projects": {
    "marketing-site": {
      "path": "D:/work/marketing-site"
    }
  }
}
```

This file is gitignored and machine-specific. The registry keeps the standard default paths, while `.local-config.json` handles local deviations.
