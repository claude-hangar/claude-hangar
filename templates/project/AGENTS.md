# AGENTS.md — {{PROJECT_NAME}}

Cross-tool agent configuration. Works with Claude Code, Cursor, Windsurf, and Copilot.

## Agents

### Code Quality

| Agent | Model | Purpose | Trigger |
|-------|-------|---------|---------|
| `code-reviewer` | opus | General code quality review | After implementation |
| `typescript-reviewer` | opus | TypeScript idioms and type safety | TypeScript changes |
| `python-reviewer` | opus | Python patterns and type hints | Python changes |
| `go-reviewer` | opus | Go idioms and error handling | Go changes |
| `plan-reviewer` | opus | Verify implementation matches spec | Before merge |

### Security & Architecture

| Agent | Model | Purpose | Trigger |
|-------|-------|---------|---------|
| `security-reviewer` | opus | OWASP Top 10, vulnerability scanning | Security-sensitive changes |
| `architect` | opus | System design, scalability decisions | Architectural decisions |
| `dependency-checker` | opus | npm audit, CVE research | Before deployment |

### Development

| Agent | Model | Purpose | Trigger |
|-------|-------|---------|---------|
| `planner` | opus | Implementation strategy for complex features | 3+ file changes |
| `tdd-guide` | opus | TDD enforcement (RED-GREEN-REFACTOR) | New features |
| `test-writer` | opus | Generate tests in isolated worktree | After implementation |
| `explorer` | opus | Quick codebase search and analysis | "explain", "find", "where" |
| `explorer-deep` | opus | Deep architecture analysis | Complex questions |

### Build & Operations

| Agent | Model | Purpose | Trigger |
|-------|-------|---------|---------|
| `build-resolver-typescript` | opus | Resolve TS/JS build errors | tsc, webpack, vite failures |
| `build-resolver-python` | opus | Resolve Python build errors | pip, poetry, pytest failures |
| `build-resolver-go` | opus | Resolve Go build errors | go build, go test failures |
| `doc-updater` | opus | Keep docs up-to-date after changes | After code changes |
| `refactor-agent` | opus | Systematic code restructuring | Refactoring tasks |
| `loop-operator` | opus | Autonomous workflow management | Multi-step autonomous tasks |

## Team Presets

### /review-team
Parallel code review from multiple perspectives:
- `code-reviewer` — Logic, naming, structure
- `security-reviewer` — Vulnerabilities, auth, secrets
- Language-specific reviewer — Idiomatic patterns

### /debug-team
Parallel debugging investigation:
- `explorer-deep` — Root cause analysis
- `build-resolver-*` — Build/dependency issues
- `tdd-guide` — Reproduction test

### /security-team
Comprehensive security assessment:
- `security-reviewer` — OWASP Top 10
- `dependency-checker` — Supply chain vulnerabilities
- `explorer-deep` — Architecture attack surface

## Rules

- All agents use the project's CLAUDE.md for context
- Reviewers are read-only (no Write/Edit access)
- Build resolvers have max 25 turns
- Explorers have max 15 turns
- Minimum 5 findings for code reviews
