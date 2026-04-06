# Claude Hangar — Project Instructions

## What Is This?

Open-source configuration management for Claude Code. This repo provides hooks, agents, skills, templates, and a setup wizard that deploys a production-grade Claude Code environment.

**This repo dogfoods itself** — the CLAUDE.md, hooks, and skills here are managed by Claude Hangar.

## Repository Structure

| Directory | Purpose |
|-----------|---------|
| `core/` | Global config deployed to ~/.claude/ (hooks, agents, skills, lib, statusline, mcp-server) |
| `stacks/` | Framework-specific extensions (Astro, SvelteKit, Next.js, Database, Auth, Docker, GitHub, Web, Security) |
| `rules/` | Governance rules (common + language-specific: TypeScript, Python, Go, Rust, Java) |
| `templates/` | CI/CD workflows and project CLAUDE.md templates |
| `registry/` | Multi-project management schema, examples, and deploy script |
| `tests/` | Hook tests (test-hooks.sh), setup tests, MCP tests, model tests |
| `docs/` | Documentation, concepts, tutorials |
| `i18n/` | Internationalization (currently: German) |

## Language & Communication

- All code, comments, docs, and commit messages in **English**
- i18n/ contains translations — do not mix languages outside i18n/
- Result first, no filler

## Quality Standards

- **ShellCheck** all .sh files (severity: warning)
- **Valid JSON** for all .json files
- **No hardcoded secrets** — use patterns like `{{USER_EMAIL}}` for personal data
- **No hardcoded versions** — always check live (npm view, context7, WebSearch)
- WCAG AA, OWASP Top 10 awareness in skills and templates
- Every hook must have a corresponding test in tests/

## Git & CI/CD

- Conventional Commits (feat:, fix:, docs:, chore:, refactor:)
- No auto-push, always `git status` + `git diff` before commit
- CI must pass: ShellCheck, JSON validation, secret scan, markdown lint
- PR template must be filled out completely

## Code Standards

- Shell scripts: Bash 4.0+ compatible, `set -euo pipefail` (Linux), no `set -e` on Windows Git Bash
- Template placeholders: `{{UPPER_SNAKE_CASE}}` format
- Skills: One SKILL.md per skill directory, clear trigger descriptions
- Hooks: stdin JSON parsing via `node -e`, not jq (cross-platform)
- Agents: Markdown frontmatter with model, description, tools

## Error Handling

- On error: stop, explain, suggest alternative
- Root cause analysis: SYMPTOM → CONTEXT → CAUSE → FIX → PREVENTION
- Reference: `docs/patterns.md`

## Anti-Patterns to Avoid

- Scope explosion — stay focused on the task
- Phantom fix — verify: IDENTIFY → RUN → READ → VERIFY → CLAIM
- Personal data leaks — no emails, names, paths in committed code (use templates)
- Platform assumptions — test on Linux AND Git Bash (Windows)

## Testing

Before any PR:
1. `bash tests/test-hooks.sh` — All hook patterns pass
2. `bash tests/test-setup.sh` — Setup validation passes
3. `bash tests/test-mcp.sh` — MCP config validation passes
4. `bash tests/test-models.sh` — Agent model references valid
5. `bash setup.sh --check` — Dry-run succeeds
6. CI green (ShellCheck, JSON, secrets, tests, markdown)

## File Naming

- Skills: `core/skills/{skill-name}/SKILL.md`
- Hooks: `core/hooks/{hook-name}.sh`
- Agents: `core/agents/{agent-name}.md`
- CI Templates: `templates/ci/{template-name}.yml`
- Stacks: `stacks/{stack-name}/`
