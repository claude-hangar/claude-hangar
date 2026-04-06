# Multi-Project Setup

Manage Claude Code configuration for multiple repositories from a single Claude Hangar installation. This is the key differentiator of Claude Hangar.

---

## Why Multi-Project?

Without a registry, every project gets the same global config from `~/.claude/`. The multi-project registry lets you:

- Define all projects in one JSON file
- Select which hooks, skills, config files, and CI workflows each project gets
- Deploy everything with one `bash setup.sh` command
- Override paths per machine without touching the shared config

---

## Registry Schema

The schema lives at [`registry/registry.schema.json`](../registry/registry.schema.json). Each project entry:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Short identifier (e.g., `"my-website"`) |
| `repo` | Yes | Git repo URL or `org/repo` shorthand |
| `defaultPath` | Yes | Default local path (e.g., `"~/projects/my-website"`) |
| `configFiles` | No | Files to deploy to project root (e.g., `["CLAUDE.md"]`) |
| `skills` | No | Skills to deploy from the skills directory |
| `hooks` | No | Hook scripts to deploy from the hooks directory |
| `workflows` | No | CI/CD templates to deploy to `.github/workflows/` |
| `mcpServers` | No | MCP server IDs to activate (array of string) |
| `servers` | No | Deployment servers (array of objects) |
| `description` | No | Short project description |

---

## Example Registry

From [`registry/example-registry.json`](../registry/example-registry.json):

```json
{
  "$schema": "./registry.schema.json",
  "projects": [
    {
      "name": "my-website",
      "repo": "my-org/my-website",
      "defaultPath": "~/projects/my-website",
      "configFiles": ["CLAUDE.md", ".claude/settings.json"],
      "skills": ["audit", "astro"],
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
      "description": "Full-stack web app with SvelteKit, Drizzle ORM, and PostgreSQL."
    }
  ]
}
```

**my-website** gets SEO and performance skills (frontend-focused), core safety hooks, and GitHub Pages deployment. **my-app** gets database and auth audit skills (backend-focused), all core hooks plus token warning, and VPS deployment via GHCR.

Each project gets exactly what it needs.

---

## Deployment Flow

```
Phase 1 — Global
  core/ → ~/.claude/ (hooks, agents, skills, lib, statusline, settings)

Phase 2 — Per Project (if registry exists)
  For each project in registry.json:
    1. Resolve local path
    2. Deploy configFiles → project root
    3. Deploy skills → project .claude/skills/
    4. Deploy hooks → project .claude/hooks/
    5. Deploy workflows → project .github/workflows/
```

Global deployment happens first, so all projects share the same base. Per-project configs add or override specific components.

---

## Adding a Project

1. Add the entry to your `registry.json`:

```json
{
  "name": "my-new-project",
  "repo": "my-org/my-new-project",
  "defaultPath": "~/projects/my-new-project",
  "configFiles": ["CLAUDE.md"],
  "hooks": ["secret-leak-check.sh", "bash-guard.sh"],
  "description": "Payment microservice."
}
```

2. Run setup:

```bash
cd ~/.claude-hangar
bash setup.sh
```

If the project path does not exist, setup clones the repo automatically.

---

## Removing a Project

Remove the entry from `registry.json` and re-run setup. Claude Hangar never deletes project files — removal only stops future deployments to that project.

---

## Path Overrides (.local-config.json)

Different machines may store projects in different directories. The `.local-config.json` file (gitignored) provides machine-specific path overrides:

```json
{
  "paths": {
    "my-website": "/d/code/my-website",
    "my-app": "~/projects/my-app"
  }
}
```

On first run, setup asks where each project lives. Answers are saved to `.local-config.json`. On subsequent runs, paths are used automatically.

| File | Committed | Purpose |
|------|-----------|---------|
| `registry.json` | Yes | Shared project definitions |
| `.local-config.json` | No (gitignored) | Machine-specific paths |

---

## Tips

- **Start simple** — begin with `configFiles` and `hooks`, add skills as needed
- **Validate first** — `bash setup.sh --check` checks registry JSON and referenced files
- **Keep it lean** — remove projects you no longer work on
- **Use descriptions** — they help when reviewing the registry months later

## Parallel Execution with claude-squad

The registry defines *which config* each project gets. [claude-squad](https://github.com/smtg-ai/claude-squad) can run them *simultaneously* — each instance inherits Hangar's full setup from `~/.claude/`.

```bash
# Start claude-squad, create an instance per project
# Each instance loads Hangar hooks, agents, and skills automatically
```

→ [Companion Tools Guide](companion-tools.md) for setup details.

---

## Next Steps

- [Companion Tools](companion-tools.md) — Superpowers, ccusage, claude-squad
- [Configuration Reference](configuration.md) — settings details
- [Architecture](architecture.md) — how deployment works internally
- [Getting Started](getting-started.md) — initial setup
