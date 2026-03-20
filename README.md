```
       _                 _            _
   ___| | __ _ _   _  __| | ___      | |__   __ _ _ __   __ _  __ _ _ __
  / __| |/ _` | | | |/ _` |/ _ \_____| '_ \ / _` | '_ \ / _` |/ _` | '__|
 | (__| | (_| | |_| | (_| |  __/_____| | | | (_| | | | | (_| | (_| | |
  \___|_|\__,_|\__,_|\__,_|\___|     |_| |_|\__,_|_| |_|\__, |\__,_|_|
                                                         |___/
```

# Claude Hangar

**The hangar for your Claude Code fleet.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/claude-hangar/claude-hangar/actions/workflows/ci.yml/badge.svg)](https://github.com/claude-hangar/claude-hangar/actions/workflows/ci.yml)

---

Production-grade configuration management for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Hooks, agents, skills, multi-project orchestration — battle-tested across 11 projects, now open source.

## What You Get

| Component | Count | Description |
|-----------|-------|-------------|
| **Hooks** | 10 | Secret leak detection, bash guard, token warnings, session lifecycle, checkpoints |
| **Agents** | 5 | Codebase explorer, security reviewer, commit reviewer, dependency checker |
| **Skills** | 17 | Project scanner, interactive consultant, three-layer audit, adversarial review, polish, and more |
| **Templates** | 5+ | CI/CD workflows (Node, Python, VPS, GitHub Pages, Cloudflare Pages) |
| **Stacks** | 5 | Astro, SvelteKit, Next.js, Database, Auth — community-extensible |

## Quick Start

```bash
git clone https://github.com/claude-hangar/claude-hangar.git ~/.claude-hangar
cd ~/.claude-hangar && bash setup.sh
```

The interactive wizard detects your OS, checks prerequisites, and deploys everything to `~/.claude/`.

## Key Features

- **Project Scanner** (`/scan`) — Auto-detect tech stack, frameworks, architecture, and generate CLAUDE.md
- **Project Consultant** (`/consult`) — Interactive improvement wizard with targeted questions and structured plans
- **Three-Layer Audit System** — Generic audit + project audit + adversarial review for comprehensive code quality
- **Session Lifecycle** — Automatic STATUS.md tracking, token warnings, checkpoint creation, compact handling
- **Multi-Project Registry** — Manage configs for multiple repos from one place
- **Smart Skill Suggestions** — Hook-driven skill recommendations based on your prompts
- **Stack Extensions** — Community-contributed framework-specific skills and templates
- **Template Engine** — Generate personalized CLAUDE.md from templates with your preferences

## Profiles

| Profile | Use Case |
|---------|----------|
| **Solo Dev** | Single project, full setup |
| **Multi-Project** | Multiple repos, centralized management |
| **Team** | Shared config for teams |
| **Minimal** | Just hooks + statusline |
| **Custom** | Pick and choose components |

## Documentation

- [Getting Started](docs/getting-started.md)
- [Configuration](docs/configuration.md)
- [Multi-Project Setup](docs/multi-project.md)
- [Writing Skills](docs/writing-skills.md)
- [Writing Hooks](docs/writing-hooks.md)
- [Writing Agents](docs/writing-agents.md)
- [Architecture](docs/architecture.md)
- [FAQ](docs/faq.md)

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas where contributions are especially valued:
- **New stacks** — Add support for your framework (Rails, Django, Go, Rust, ...)
- **Skills** — Share your workflow automations
- **Translations** — Help us reach more developers ([i18n guide](i18n/i18n.md))
- **Bug reports** — Issues with specific OS/shell combinations

## License

[MIT](LICENSE) — Use it, fork it, extend it.
