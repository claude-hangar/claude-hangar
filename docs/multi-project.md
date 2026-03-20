# Multi-Project Setup

How to manage Claude Code configuration for multiple repositories from a single Claude Hangar installation.

---

## Overview

If you work on more than one project, you probably want consistent hooks and skills across all of them — but with per-project customization. The multi-project registry lets you:

- Define all your projects in one JSON file
- Specify which config files, skills, hooks, and CI workflows each project gets
- Deploy everything with a single `bash setup.sh` command
- Override paths per machine without touching the shared config

---

## What Is the Registry?

The registry is a JSON file (`registry/registry.json`) that lists your projects and what gets deployed to each one. It follows the schema defined in `registry/registry.schema.json`.

The registry is **your file** — it is not included in the Claude Hangar repo (only an example is provided). You create it based on your own projects.

---

## Registry Schema

The schema lives at `registry/registry.schema.json`. Here is the full structure:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Claude Hangar Project Registry",
  "type": "object",
  "required": ["projects"],
  "properties": {
    "projects": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name", "repo", "defaultPath"],
        "properties": {
          "name":        { "type": "string" },
          "repo":        { "type": "string" },
          "defaultPath": { "type": "string" },
          "configFiles": { "type": "array", "items": { "type": "string" } },
          "skills":      { "type": "array", "items": { "type": "string" } },
          "hooks":       { "type": "array", "items": { "type": "string" } },
          "workflows":   { "type": "array", "items": { "type": "string" } },
          "description": { "type": "string" }
        }
      }
    }
  }
}
```

### Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Short identifier for the project (e.g., `"my-website"`) |
| `repo` | Yes | Git repository URL or `org/repo` shorthand |
| `defaultPath` | Yes | Default local path where the project lives (e.g., `"~/projects/my-website"`) |
| `configFiles` | No | Config files to deploy (e.g., `["CLAUDE.md", ".claude/settings.json"]`) |
| `skills` | No | Skill files to deploy from the skills directory |
| `hooks` | No | Hook scripts to deploy from the hooks directory |
| `workflows` | No | CI/CD workflow templates to deploy (e.g., `["ci-node.yml"]`) |
| `description` | No | Short description of what the project is |

---

## Example Registry Walkthrough

Here is the example from `registry/example-registry.json`:

```json
{
  "$schema": "./registry.schema.json",
  "projects": [
    {
      "name": "my-website",
      "repo": "my-org/my-website",
      "defaultPath": "~/projects/my-website",
      "configFiles": ["CLAUDE.md", ".claude/settings.json"],
      "skills": ["seo-audit.md", "performance-check.md"],
      "hooks": ["secret-leak-check.sh", "bash-guard.sh", "checkpoint.sh"],
      "workflows": ["ci-node.yml", "deploy-ghpages.yml"],
      "description": "Marketing website built with Astro (SSG) and Tailwind CSS."
    },
    {
      "name": "my-app",
      "repo": "my-org/my-app",
      "defaultPath": "~/projects/my-app",
      "configFiles": ["CLAUDE.md", ".claude/settings.json"],
      "skills": ["db-audit.md", "auth-audit.md", "api-review.md"],
      "hooks": ["secret-leak-check.sh", "bash-guard.sh", "checkpoint.sh", "token-warning.sh"],
      "workflows": ["ci-node.yml", "deploy-vps-ghcr.yml"],
      "description": "Full-stack web app with SvelteKit (SSR), Drizzle ORM, and PostgreSQL."
    }
  ]
}
```

### What This Means

**my-website** gets:
- A project-specific `CLAUDE.md` and `.claude/settings.json`
- SEO and performance skills (website-focused)
- Core safety hooks (secrets, bash guard, checkpoints)
- CI for Node.js + GitHub Pages deployment workflow

**my-app** gets:
- Its own `CLAUDE.md` and `.claude/settings.json`
- Database and auth audit skills (backend-focused)
- All core safety hooks plus token warning
- CI for Node.js + VPS deployment via GHCR

Each project gets exactly the components it needs — no more, no less.

---

## How Setup Deploys Per-Project Configs

When you run `bash setup.sh`, the deployment follows this flow:

```
1. Phase 1 — Global
   Deploy core/ → ~/.claude/
   (hooks, agents, skills, lib, statusline, settings)

2. Phase 2 — Projects (if registry exists)
   For each project in registry.json:
     a. Resolve local path (from .local-config.json or defaultPath)
     b. If path doesn't exist → clone the repo
     c. Deploy configFiles to project root
     d. Deploy skills to project's .claude/skills/
     e. Deploy hooks to project's .claude/hooks/
     f. Deploy workflows to project's .github/workflows/
```

Global deployment happens first, so all projects share the same base hooks and agents. Per-project configs add or override specific components.

---

## Project-Specific Overrides

### CLAUDE.md Per Project

Each project can have its own CLAUDE.md with project-specific instructions. When listed in `configFiles`, setup deploys it to the project root. Claude Code reads this file automatically when you open the project.

Example project CLAUDE.md:

```markdown
# My Website — Project Instructions

## Stack
- Astro 5.x (SSG)
- Tailwind CSS v4
- Deployed to GitHub Pages

## Conventions
- Components in src/components/
- Pages in src/pages/
- Assets in public/

## Quality
- Lighthouse score > 90 on all categories
- All images must have alt text
```

### Settings Per Project

Projects can have their own `.claude/settings.json` with project-specific hooks or environment variables. These are merged with (not replacing) the global settings.

---

## Adding a New Project

1. **Add the entry** to your `registry.json`:

```json
{
  "name": "my-new-project",
  "repo": "my-org/my-new-project",
  "defaultPath": "~/projects/my-new-project",
  "configFiles": ["CLAUDE.md"],
  "skills": ["deploy-check.md"],
  "hooks": ["secret-leak-check.sh", "bash-guard.sh"],
  "description": "New microservice for payment processing."
}
```

2. **Create the project config files** if needed (e.g., a CLAUDE.md for the project)

3. **Run setup:**

```bash
cd ~/.claude-hangar
bash setup.sh
```

If the project path does not exist, setup will clone the repo automatically.

---

## Removing a Project

1. **Remove the entry** from `registry.json`
2. **Run setup** — it will skip the removed project
3. The project's local files are not deleted — only future deployments stop

> Claude Hangar never deletes project files. Removal from the registry only stops deploying configs to that project.

---

## Path Configuration (.local-config.json)

Different machines may have projects in different directories. The `.local-config.json` file (gitignored) stores machine-specific path overrides.

### How It Works

On first run, setup asks where each project lives:

```
Project: my-website
Default path: ~/projects/my-website
Local path [Enter to accept default]: /d/code/my-website
```

Your answer is saved to `.local-config.json`:

```json
{
  "paths": {
    "my-website": "/d/code/my-website",
    "my-app": "~/projects/my-app"
  }
}
```

On subsequent runs, setup uses these paths automatically — no questions asked.

### Changing Paths

Edit `.local-config.json` directly, or delete it to re-trigger the interactive path selection on next setup run.

### Multiple Machines

Since `.local-config.json` is gitignored, each machine has its own path configuration. The registry defines defaults; local config provides overrides.

| File | Committed | Purpose |
|------|-----------|---------|
| `registry.json` | Yes | Shared project definitions |
| `.local-config.json` | No (gitignored) | Machine-specific path overrides |

---

## Tips

### Start Simple

Begin with just `configFiles` and `hooks`. Add skills and workflows as you identify what each project needs.

### Use Descriptions

The `description` field helps you remember what each project is. It also helps when reviewing the registry months later.

### Keep the Registry Clean

Remove projects you no longer work on. A lean registry means faster setup runs.

### Validate Before Deploying

```bash
bash setup.sh --check
```

This validates the registry JSON and checks that all referenced files exist.

---

## Next Steps

- [Configuration Reference](configuration.md) — detailed settings documentation
- [Getting Started](getting-started.md) — initial setup
- [FAQ](faq.md) — common questions
