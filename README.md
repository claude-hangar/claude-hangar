<p align="center">
  <img src="docs/assets/logo.svg" alt="Claude Hangar" width="120">
</p>

<h1 align="center">Claude Hangar</h1>

<p align="center">
  <strong>Production-grade configuration management for Claude Code.</strong><br>
  Hooks, agents, skills, multi-project orchestration — open source.
</p>

<p align="center">
  <a href="https://github.com/claude-hangar/claude-hangar/actions/workflows/ci.yml"><img src="https://github.com/claude-hangar/claude-hangar/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/claude-hangar/claude-hangar/releases"><img src="https://img.shields.io/github/v/release/claude-hangar/claude-hangar" alt="Release"></a>
</p>

---

## Why Claude Hangar?

Most Claude Code configs are personal dotfiles — useful to read, hard to reuse. Claude Hangar is different:

- **One command** deploys a complete, tested setup to `~/.claude/`
- **Multi-project orchestration** — manage configs for multiple repos from one place
- **Modular stacks** — pick only what you need (Astro, SvelteKit, Next.js, Database, Auth)
- **Battle-tested hooks** that prevent real incidents (secret leaks, destructive commands, context overflow)
- **17 skills** from project scanning to deployment readiness checks
- **Cross-platform** — Linux, macOS, and Windows (Git Bash)

## Quick Start

**One-liner install:**

```bash
curl -fsSL https://raw.githubusercontent.com/claude-hangar/claude-hangar/main/install.sh | bash
```

**Or clone manually:**

```bash
git clone https://github.com/claude-hangar/claude-hangar.git ~/.claude-hangar
cd ~/.claude-hangar && bash setup.sh
```

<details>
<summary><strong>What happens during setup</strong></summary>

```
  Claude Hangar — Setup
  ─────────────────────

[i] Running on: linux
[+] Prerequisites: git ✓  node ✓
[+] Structure validation passed
[i] Deploying to /home/user/.claude/...
[+] Deployed: Hooks (10 scripts)
[+] Deployed: Agents (5 definitions)
[+] Deployed: Skills (17 commands)
[+] Deployed: Shared lib
[+] Deployed: Statusline
[+] Deployed: settings.json (from template)

[+] Deployment complete!
[i] Open Claude Code in any project to start.
```

</details>

## What You Get

### Hooks (10) — Automated Safety Net

| Hook | What It Does |
|------|-------------|
| `secret-leak-check` | Blocks writes containing API keys, tokens, or credentials |
| `bash-guard` | Prevents destructive commands (`rm -rf`, `DROP TABLE`, force-push) |
| `checkpoint` | Auto-creates git stash snapshots before file edits |
| `token-warning` | Alerts at 70% and 80% context utilization |
| `session-start` | Loads STATUS.md, tasks, and memory on session start |
| `session-stop` | Cleans temp files, logs session cost |
| `post-compact` | Resets token tracking after context compaction |
| `config-change-guard` | Warns on critical settings changes |
| `skill-suggest` | Suggests matching skills based on your prompts |
| `stop-failure` | Logs errors on session failures |

### Agents (5) — Specialized AI Workers

| Agent | Model | Purpose |
|-------|-------|---------|
| `explorer` | Sonnet | Fast read-only codebase analysis |
| `explorer-deep` | Opus | Deep architecture analysis with worktree isolation |
| `security-reviewer` | Opus | OWASP Top 10 + Agentic Top 10 security audit |
| `commit-reviewer` | Sonnet | Pre-commit review for staged changes |
| `dependency-checker` | Sonnet | npm audit + outdated packages + CVE research |

### Skills (17) — Slash Commands for Real Work

| Skill | Description |
|-------|-------------|
| `/scan` | Auto-detect tech stack, architecture, and generate CLAUDE.md |
| `/consult` | Interactive improvement wizard with structured plans |
| `/audit` | Three-layer website audit (9 phases) |
| `/project-audit` | Repository audit (10 phases) |
| `/adversarial-review` | Critical review — minimum 5 findings |
| `/polish` | Frontend quick wins across 6 dimensions |
| `/deploy-check` | Docker/Traefik deployment readiness |
| `/git-hygiene` | Stale branches, large files, commit quality |
| `/freshness-check` | Framework and dependency version tracking |
| `/lighthouse-quick` | Core Web Vitals performance check |
| `/capture-pdf` | Multi-page website PDF capture |
| `/meta-tags` | OG/Twitter/Structured Data validation |
| `/favicon-check` | Icon completeness check |
| `/design-system` | Tailwind v4 design reference |
| `/lesson-learned` | Extract and persist learnings |
| `/audit-orchestrator` | Multi-audit coordination |
| `/audit-runner` | Autonomous batch audit execution |

### Stacks (5) — Framework Extensions

Drop-in extensions for your specific tech stack. Each provides a `CLAUDE.md.snippet` you can paste into your project:

| Stack | Includes |
|-------|----------|
| **Astro** | SSG/SSR patterns, content collections, View Transitions, v5→v6 migration |
| **SvelteKit** | Svelte 5 runes, load functions, form actions, Kit 2 migration |
| **Next.js** | App Router, Server Components, Server Actions |
| **Database** | Drizzle ORM, migrations, schema design, connection pooling |
| **Auth** | Custom bcrypt + sessions, secure cookies, CSRF, rate limiting |

### Templates

- **4 project templates** — CLAUDE.md starters (minimal, web, fullstack, management)
- **5 CI/CD templates** — GitHub Actions for Node.js, Python, VPS, GitHub Pages, Cloudflare Pages
- **Global CLAUDE.md template** — Baseline instructions with `{{PLACEHOLDER}}` customization

## Multi-Project Orchestration

Manage Claude Code configs for multiple repositories from one `registry.json`:

```json
{
  "projects": {
    "website": {
      "path": "~/projects/website",
      "stack": "astro",
      "template": "web"
    },
    "api": {
      "path": "~/projects/api",
      "stack": "database",
      "template": "fullstack"
    },
    "docs": {
      "path": "~/projects/docs",
      "stack": null,
      "template": "minimal"
    }
  }
}
```

Each project gets the right CLAUDE.md, stack-specific skills, and CI templates — all from one source of truth.

→ [Multi-Project Guide](docs/multi-project.md)

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | Installation and first run |
| [Configuration](docs/configuration.md) | Settings, hooks, environment variables |
| [Multi-Project Setup](docs/multi-project.md) | Registry-based project management |
| [Writing Skills](docs/writing-skills.md) | Create your own slash commands |
| [Writing Hooks](docs/writing-hooks.md) | Extend the hook system |
| [Writing Agents](docs/writing-agents.md) | Custom agent definitions |
| [Architecture](docs/architecture.md) | System design and internals |
| [FAQ](docs/faq.md) | Common questions |

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Areas where contributions are especially valued:**

- **New stacks** — Rails, Django, Go, Rust, Laravel, ...
- **Skills** — Share your workflow automations
- **Translations** — Help us reach more developers ([i18n guide](i18n/i18n.md))
- **Bug reports** — Issues with specific OS/shell combinations

## License

[MIT](LICENSE) — Use it, fork it, extend it.
