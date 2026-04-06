# Stacks

Framework-specific extensions for Claude Code. Each stack provides audit skills, CLAUDE.md snippets, and fix templates tailored to a particular framework or technology.

## Available Stacks

| Stack | Directory | Audit Skill | Description |
|-------|-----------|-------------|-------------|
| **Astro** | `astro/` | `/astro-audit` | SSG/SSR with Astro, Content Collections, View Transitions |
| **SvelteKit** | `sveltekit/` | `/sveltekit-audit` | SSR/SSG with SvelteKit 2 + Svelte 5 runes |
| **Next.js** | `nextjs/` | — | App Router, Server Components, Server Actions |
| **Database** | `database/` | `/db-audit` | Drizzle ORM + PostgreSQL schema, migrations, performance |
| **Auth** | `auth/` | `/auth-audit` | Custom bcryptjs + sessions (no external auth providers) |
| **GitHub** | `github/` | — | GitHub repos, PRs, issues via MCP |
| **Web** | `web/` | — | Browser automation (Playwright) via MCP |
| **Security** | `security/` | — | Security scanning (Snyk) via MCP |
| **Docker** | `docker/` | — | Docker/container CLAUDE.md snippet |

## Directory Structure

```
stacks/
├── astro/
│   ├── SKILL.md            # /astro-audit — migration + best-practice audit
│   ├── CLAUDE.md.snippet   # Paste into project CLAUDE.md
│   ├── README.md           # Stack documentation
│   ├── fix-templates.md    # Quick-fix templates
│   └── versions/           # Version-specific checklists
│       ├── v5-stable/
│       ├── v6-beta/
│       └── v6-stable/
├── sveltekit/
│   ├── SKILL.md            # /sveltekit-audit — SvelteKit + Svelte 5 audit
│   ├── CLAUDE.md.snippet   # Paste into project CLAUDE.md
│   ├── README.md           # Stack documentation
│   ├── fix-templates.md    # Quick-fix templates
│   └── versions/
│       └── kit2-svelte5/
├── nextjs/
│   ├── CLAUDE.md.snippet   # Paste into project CLAUDE.md
│   └── README.md           # Stack documentation
├── database/
│   ├── SKILL.md            # /db-audit — Drizzle ORM + PostgreSQL audit
│   ├── CLAUDE.md.snippet   # Paste into project CLAUDE.md
│   ├── README.md           # Stack documentation
│   ├── fix-templates.md    # Quick-fix templates
│   └── state-schema.md     # Audit state schema
├── auth/
│   ├── SKILL.md            # /auth-audit — custom auth security audit
│   ├── CLAUDE.md.snippet   # Paste into project CLAUDE.md
│   ├── README.md           # Stack documentation
│   ├── fix-templates.md    # Quick-fix templates
│   └── state-schema.md     # Audit state schema
├── github/
│   ├── mcp.json              # GitHub MCP server configuration
│   └── README.md             # Stack documentation
├── web/
│   ├── mcp.json              # Playwright MCP server configuration
│   └── README.md             # Stack documentation
├── security/
│   ├── mcp.json              # Snyk MCP server configuration
│   └── README.md             # Stack documentation
├── docker/
│   └── CLAUDE.md.snippet     # Docker/container context snippet
└── README.md               # This file
```

## How to Use a Stack

### 1. CLAUDE.md Snippets

Each stack includes a `CLAUDE.md.snippet` file. Copy its contents into your project's `CLAUDE.md` to give Claude Code framework-specific context:

```bash
# Example: Add Astro context to your project
cat stacks/astro/CLAUDE.md.snippet >> your-project/CLAUDE.md
```

Snippets are designed to be concise (under 50 lines) and practical. They cover key patterns, file structure, conventions, and commands.

### 2. Audit Skills

Stacks with a `SKILL.md` file provide dedicated audit slash commands:

```
/astro-audit start       # Astro version + best practices
/sveltekit-audit start   # SvelteKit 2 + Svelte 5 patterns
/db-audit start          # Database schema + migrations
/auth-audit start        # Auth security (OWASP ASVS)
```

### 3. Fix Templates

When an audit finds issues, it loads matching fix templates from `fix-templates.md` — ready-to-apply code snippets adapted to your project.

## Creating a New Stack

1. Create a directory: `stacks/my-framework/`
2. Add `CLAUDE.md.snippet` — paste-ready section for project CLAUDE.md (under 50 lines)
3. Add `README.md` — what the stack includes and how to use it
4. Optionally add `SKILL.md` — audit skill with version detection, areas, fix templates
5. Reference the stack in this README

### Guidelines

- **One SKILL.md per stack** — keep it focused on the specific framework
- **No hardcoded versions** — always instruct Claude to check versions live
- **Cross-reference** related stacks (e.g., database + auth)
- **CLAUDE.md.snippet** must be practical and under 50 lines
- **Test your skill** against a real project before committing
- **MCP servers** — if your stack includes an MCP server, add a `mcp.json` file (see `core/mcp/README.md` for format)
