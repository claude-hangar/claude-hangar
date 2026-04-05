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
- **23 skills** from project scanning to deployment readiness checks
- **22 lifecycle hooks** with 4-level quality gates, forensics, and smart context preservation
- **17 agents** for specialized tasks, code review, and autonomous workflows
- **15 governance rules** (common + language-specific) always-on code quality
- **3 context modes** — dev, research, review
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
[+] Deployed: Hooks (13 scripts)
[+] Deployed: Agents (6 definitions)
[+] Deployed: Skills (18 commands)
[+] Deployed: Shared lib
[+] Deployed: Statusline
[+] Deployed: settings.json (from template)

[+] Deployment complete!
[i] Open Claude Code in any project to start.
```

</details>

## What You Get

### Hooks (13) — Automated Safety Net

| Hook | Event | What It Does |
|------|-------|-------------|
| `secret-leak-check` | PreToolUse | Blocks writes containing API keys, tokens, or credentials |
| `bash-guard` | PreToolUse | Prevents destructive commands (`rm -rf`, `DROP TABLE`, force-push) |
| `checkpoint` | PreToolUse | Auto-creates git stash snapshots before file edits |
| `token-warning` | PostToolUse | Alerts at 70% and 80% context utilization |
| `session-start` | SessionStart | Loads STATUS.md, tasks, and memory on session start |
| `session-stop` | Stop | Cleans temp files, logs session cost |
| `post-compact` | PostCompact | Smart context preservation — detects tasks, plans, branch, HANDOFF.md |
| `config-change-guard` | ConfigChange | Warns on critical settings changes |
| `skill-suggest` | UserPromptSubmit | Suggests matching skills based on your prompts |
| `model-router` | UserPromptSubmit | Smart complexity analysis — structural signals, scope detection |
| `task-completed-gate` | TaskCompleted | 4-level quality gate (existence, errors, evidence, substance) |
| `subagent-tracker` | SubagentStart/Stop | Lifecycle tracking + forensics (duration, thrashing, failures) |
| `stop-failure` | StopFailure | Logs errors on session failures |

### Agents (6) — Specialized AI Workers

| Agent | Model | Purpose |
|-------|-------|---------|
| `explorer` | Sonnet | Fast read-only codebase analysis |
| `explorer-deep` | Opus | Deep architecture analysis with worktree isolation |
| `security-reviewer` | Opus | OWASP Top 10 + Agentic Top 10 security audit |
| `commit-reviewer` | Sonnet | Pre-commit review for staged changes |
| `plan-reviewer` | Sonnet | Spec/plan compliance — verifies nothing more, nothing less |
| `dependency-checker` | Sonnet | npm audit + outdated packages + CVE research |

### Skills (18) — Slash Commands for Real Work

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
| `/handoff` | Structured session handoff for seamless context continuity |

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

## Repository Structure

| Directory | Purpose |
|-----------|---------|
| `core/` | Global config deployed to ~/.claude/ (hooks, agents, skills, lib, statusline) |
| `stacks/` | Framework-specific extensions (Astro, SvelteKit, Next.js, Database, Auth) |
| `templates/` | CI/CD workflows and project CLAUDE.md templates |
| `registry/` | Multi-project management schema and examples |
| `tests/` | Hook tests, setup tests, template tests |
| `docs/` | Documentation, concepts, tutorials |
| `i18n/` | Internationalization (currently: German) |
| `rules/` | Always-on governance rules (common + language-specific) |
| `core/contexts/` | Dynamic context modes (dev, research, review) |

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
| [Companion Tools](docs/companion-tools.md) | Superpowers, Trail of Bits, ccusage, claude-squad |
| [FAQ](docs/faq.md) | Common questions |

## Works Great With

Claude Hangar is the infrastructure layer. These companion tools extend it:

| Tool | Stars | What It Adds |
|------|------:|-------------|
| [**Superpowers**](https://github.com/obra/superpowers) | 104K+ | Deep workflow methodology — brainstorming, TDD, subagent-driven development, systematic debugging |
| [**Trail of Bits Skills**](https://github.com/trailofbits/skills) | 3.8K+ | Professional security skills — CodeQL, Semgrep, variant analysis, fix verification |
| [**ccusage**](https://github.com/ryoppippi/ccusage) | 11.8K+ | Historical usage analytics — token costs, session history, dashboards |
| [**claude-squad**](https://github.com/smtg-ai/claude-squad) | 6.4K+ | Multi-session management — run multiple Claude Code instances in parallel |
| [**claude-mem**](https://github.com/thedotmack/claude-mem) | 39K+ | Persistent memory plugin — session captures, AI compression, semantic search |
| [**Everything Claude Code**](https://github.com/affaan-m/everything-claude-code) | 97K+ | Comprehensive system with instincts, memory, and security patterns |

All are compatible with Hangar and each other. No conflicts, no overlap.

→ [Companion Tools Guide](docs/companion-tools.md)

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Areas where contributions are especially valued:**

- **New stacks** — Rails, Django, Go, Rust, Laravel, ...
- **Skills** — Share your workflow automations
- **Translations** — Help us reach more developers ([i18n guide](i18n/i18n.md))
- **Bug reports** — Issues with specific OS/shell combinations

## Inspired By

- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) — Rules system, language agents, learning mechanisms, context modes, hook profiles

## License

[MIT](LICENSE) — Use it, fork it, extend it.
