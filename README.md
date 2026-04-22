<p align="center">
  <img src="docs/assets/logo.svg" alt="Claude Hangar" width="120">
</p>

<h1 align="center">Claude Hangar</h1>

<p align="center">
  <strong>Production-grade configuration management for Claude Code.</strong><br>
  Hooks, agents, skills, multi-project orchestration — open source.
</p>

<p align="center">
  <a href="https://github.com/lazaridis-com/claude-hangar/actions/workflows/ci.yml"><img src="https://github.com/lazaridis-com/claude-hangar/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/lazaridis-com/claude-hangar/releases"><img src="https://img.shields.io/github/v/release/lazaridis-com/claude-hangar" alt="Release"></a>
</p>

---

## Why Claude Hangar?

Most Claude Code configs are personal dotfiles — useful to read, hard to reuse. Claude Hangar is different:

- **One command** deploys a complete, tested setup to `~/.claude/`
- **Multi-project orchestration** — manage configs for multiple repos from one place
- **Modular stacks** — pick only what you need (`bash integrate.sh <stack>`) with `--with`/`--without` component control
- **Battle-tested hooks** that prevent real incidents (secret leaks, destructive commands, context overflow)
- **42 skills** from project scanning to pre-PR verification, context optimization, session recap, effort tuning, stack lenses, and meta-governance
- **31 lifecycle hooks** with 4-level quality gates, config protection, MCP health checks, design quality guards, permission-request inspection, budget caps, and smart context preservation
- **22 agents** for specialized tasks (code review, TDD enforcement, performance analysis, MCP server development, autonomous workflows) — deep-reasoning agents run at `effort: xhigh` (v2.1.111+)
- **20 governance rules** (common + language-specific) always-on code quality
- **3 context modes** — dev, research, review
- **Cross-platform** — Linux, macOS, and Windows (Git Bash)

## Prerequisites

- **Node.js** >= 18 LTS (for hook JSON parsing via `node -e`)
- **Bash** >= 4.0 (Git Bash on Windows, native on macOS/Linux)
- **Git** >= 2.20
- **GitHub CLI** (`gh`) — optional, for GitHub stack features and freshness checks

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
[+] Deployed: Hooks (31 scripts)
[+] Deployed: Agents (22 definitions)
[+] Deployed: Skills (41 commands)
[+] Deployed: Shared lib
[+] Deployed: Statusline
[+] Deployed: settings.json (from template)

[+] Deployment complete!
[i] Open Claude Code in any project to start.
```

</details>

## What You Get

### Hooks (27) — Automated Safety Net

| Hook | Event | What It Does |
|------|-------|-------------|
| `secret-leak-check` | PreToolUse | Blocks writes containing API keys, tokens, or credentials |
| `bash-guard` | PreToolUse | Prevents destructive commands (`rm -rf`, `DROP TABLE`, force-push) |
| `checkpoint` | PreToolUse | Auto-creates git stash snapshots before file edits |
| `config-protection` | PreToolUse | Blocks weakening of linter/formatter/compiler configs |
| `mcp-health-check` | PreToolUse | Checks MCP server health before tool calls, warns on repeated failures |
| `db-query-guard` | PreToolUse | Warns when agent tries to directly query internal databases |
| `permission-denied-retry` | PermissionDenied | Retries with adjusted approach on permission denial |
| `token-warning` | PostToolUse | Alerts at 70% and 80% context utilization |
| `continuous-learning` | PostToolUse | Captures patterns and learnings from agent work |
| `cost-tracker` | PostToolUse | Tracks token costs per session |
| `design-quality-check` | PostToolUse | Detects generic AI UI drift patterns in frontend files |
| `batch-format-collector` | PostToolUse | Collects edited file paths for batch formatting |
| `instinct-capture` | PostToolUse | Captures instinct patterns from tool usage |
| `skill-suggest` | UserPromptSubmit | Suggests matching skills based on your prompts |
| `model-router` | UserPromptSubmit | Smart complexity analysis — structural signals, scope detection |
| `session-start` | SessionStart | Loads STATUS.md, tasks, and memory on session start |
| `config-change-guard` | ConfigChange | Warns on critical settings changes |
| `task-completed-gate` | TaskCompleted | 4-level quality gate (existence, errors, evidence, substance) |
| `task-created-init` | TaskCreated | Initializes new tasks with metadata |
| `subagent-tracker` | SubagentStart/Stop | Lifecycle tracking + forensics (duration, thrashing, failures) |
| `post-compact` | PostCompact | Smart context preservation — detects tasks, plans, branch, HANDOFF.md |
| `worktree-init` | WorktreeCreate | Initializes worktree environment for isolated work |
| `session-stop` | Stop | Cleans temp files, logs session cost |
| `stop-failure` | StopFailure | Logs errors on session failures |
| `stop-batch-format` | Stop | Runs formatters once at session end on all edited files |
| `instinct-evolve` | Stop | Evolves instinct data from session patterns |
| `desktop-notify` | Stop | OS notification when session ends (Windows/Linux/macOS) |

### MCP Server — Hangar State API

A zero-dependency MCP server (`core/mcp-server/server.js`) that exposes Hangar configuration state as 5 read-only tools: `hangar_hooks`, `hangar_skills`, `hangar_agents`, `hangar_config`, `hangar_freshness`.

### Shared References (3)

Shared behavioral files that skills and agents reference for consistency:

| Reference | Purpose |
|-----------|---------|
| `questioning.md` | Shared questioning style for skills and agents |
| `design-principles.md` | Design quality standards (no AI aesthetic, WCAG AA, curated palettes) |
| `code-quality.md` | Code quality defaults (fix code not configs, immutability, coverage) |

### Agents (21) — Specialized AI Workers

| Agent | Model | Purpose |
|-------|-------|---------|
| `explorer` | Sonnet | Fast read-only codebase analysis |
| `explorer-deep` | Opus | Deep architecture analysis (read-only) |
| `security-reviewer` | Opus | OWASP Top 10 + Agentic Top 10 security audit |
| `commit-reviewer` | Sonnet | Pre-commit review for staged changes |
| `plan-reviewer` | Sonnet | Spec/plan compliance — verifies nothing more, nothing less |
| `dependency-checker` | Sonnet | npm audit + outdated packages + CVE research |
| `planner` | Opus | Complex feature implementation planning |
| `architect` | Opus | System design and architecture decisions |
| `loop-operator` | Sonnet | Autonomous workflow with safety guardrails |
| `tdd-guide` | Sonnet | TDD enforcement (RED-GREEN-REFACTOR cycle) |
| `doc-updater` | Sonnet | Documentation maintenance and staleness detection |
| `refactor-agent` | Opus | Code restructuring and cleanup (worktree isolation) |
| `test-writer` | Sonnet | Test generation for new features |
| `typescript-reviewer` | Sonnet | TypeScript-specific code review |
| `python-reviewer` | Sonnet | Python-specific code review |
| `go-reviewer` | Sonnet | Go-specific code review |
| `build-resolver-typescript` | Sonnet | TS/JS build error resolution |
| `build-resolver-python` | Sonnet | Python build error resolution |
| `build-resolver-go` | Sonnet | Go build error resolution |
| `harness-optimizer` | Opus | Self-optimization of hooks, skills, rules, and agent configs |
| `performance-optimizer` | Opus | Bundle analysis, profiling, Core Web Vitals, memory leaks |

### Skills (31) — Slash Commands for Real Work

| Skill | Description |
|-------|-------------|
| `/scan` | Auto-detect tech stack, architecture, and generate CLAUDE.md |
| `/consult` | Interactive improvement wizard with structured plans |
| `/verify` | Pre-PR 6-phase quality pipeline (build, types, lint, test, security, diff) |
| `/context-budget` | Token spending analysis and optimization opportunities |
| `/strategic-compact` | Smart /compact timing based on workflow state |
| `/audit` | Three-layer website audit (9 phases) |
| `/project-audit` | Repository audit (10 phases) |
| `/adversarial-review` | Critical review — minimum 5 findings |
| `/safety-guard` | 3-mode write protection (Careful/Freeze/Guard) for autonomous runs |
| `/rules-distill` | Extract cross-cutting rules from skill collection |
| `/skill-stocktake` | Audit skill quality across 4 dimensions |
| `/prompt-optimizer` | 6-phase prompt analysis and skill matching pipeline |
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
| `/gsd-orchestrate` | GSD v1 end-to-end automation (checkpoint/full-auto/assisted, batch overnight runs) |
| `/handoff` | Structured session handoff for seamless context continuity |
| `/codebase-map` | Structural overview for context recovery after /compact |
| `/doctor` | Project health check (git-hygiene + deploy-check + freshness) |
| `/error-analyzer` | Systematic root-cause analysis for build/test/runtime failures |
| `/inline-review` | Quick self-review checklist after code changes |
| `/pattern-extractor` | Analyze captured patterns from continuous learning |
| `/security-scan` | Claude Code security scan (secrets, MCP, hooks, deps) |

### Stacks (9) — Framework & Tool Extensions

Drop-in extensions for your specific tech stack. Full stacks provide `CLAUDE.md.snippet` + audit skills. MCP stacks provide tool integrations.

| Stack | Type | Includes |
|-------|------|----------|
| **Astro** | Full | SSG/SSR patterns, content collections, View Transitions, `/astro-audit` |
| **SvelteKit** | Full | Svelte 5 runes, load functions, form actions, `/sveltekit-audit` |
| **Next.js** | Full | App Router, Server Components, Server Actions |
| **Database** | Full | Drizzle ORM, migrations, schema design, `/db-audit` |
| **Auth** | Full | Custom bcrypt + sessions, secure cookies, `/auth-audit` |
| **Docker** | Snippet | Docker/container CLAUDE.md context |
| **GitHub** | MCP | GitHub repos, PRs, issues via MCP server |
| **Web** | MCP | Browser automation (Playwright) via MCP server |
| **Security** | MCP | Security scanning (Snyk) via MCP server |

### Templates

- **5 project templates** — CLAUDE.md starters (minimal, web, fullstack, management) + DECISIONS.md (ADR register)
- **6 CI/CD templates** — GitHub Actions for Node.js, Python, VPS (GHCR), Docker Compose, GitHub Pages, Cloudflare Pages
- **Global CLAUDE.md template** — Baseline instructions with `{{PLACEHOLDER}}` customization

## Multi-Project Orchestration

Manage Claude Code configs for multiple repositories from one `registry.json`:

```json
{
  "projects": [
    {
      "name": "website",
      "repo": "my-org/website",
      "defaultPath": "~/projects/website",
      "skills": ["audit", "astro"],
      "workflows": ["ci-node.yml", "deploy-ghpages.yml"]
    },
    {
      "name": "api",
      "repo": "my-org/api",
      "defaultPath": "~/projects/api",
      "skills": ["audit", "database", "auth"],
      "workflows": ["ci-node.yml", "deploy-vps-ghcr.yml"]
    }
  ]
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
| [**Superpowers**](https://github.com/obra/superpowers) | 136K+ | Deep workflow methodology — brainstorming, TDD, subagent-driven development, systematic debugging |
| [**Trail of Bits Skills**](https://github.com/trailofbits/skills) | 3.8K+ | Professional security skills — CodeQL, Semgrep, variant analysis, fix verification |
| [**ccusage**](https://github.com/ryoppippi/ccusage) | 11.8K+ | Historical usage analytics — token costs, session history, dashboards |
| [**claude-squad**](https://github.com/smtg-ai/claude-squad) | 6.4K+ | Multi-session management — run multiple Claude Code instances in parallel |
| [**claude-mem**](https://github.com/thedotmack/claude-mem) | 39K+ | Persistent memory plugin — session captures, AI compression, semantic search |
| [**Everything Claude Code**](https://github.com/affaan-m/everything-claude-code) | 140K+ | Comprehensive system with instincts, memory, and security patterns |

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

- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) — Rules system, language agents, learning mechanisms, context modes, hook profiles, config protection, meta-governance, shared references
- [GSD v2](https://github.com/gsd-build/gsd-2) — DECISIONS.md (append-only ADR register) pattern
- [BMAD-METHOD](https://github.com/bmadcode/BMAD-METHOD) — Story continuity, intent cascade patterns
- [spec-kit](https://github.com/nicobailey/spec-kit) — User-invocable frontmatter, argument hints
- [oh-my-opencode](https://github.com/nicholasgubbins/oh-my-opencode) — Agent fallback, hook composition patterns
- [ui-ux-pro-max-skill](https://github.com/nicholasgubbins/ui-ux-pro-max-skill) — Design token architecture, product palettes

## License

[MIT](LICENSE) — Use it, fork it, extend it.
