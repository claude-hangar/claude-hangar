# Writing Agents

How to create custom agents for Claude Hangar.

---

## What Is an Agent?

An agent is a markdown file with YAML frontmatter that defines a specialized sub-agent. When invoked, Claude Code spawns a sub-conversation with its own model, tools, and scope. The agent performs a focused task and returns its result to the main conversation.

Agents are ideal when you need a different model (cheaper or more capable), restricted tool access, or isolated write operations.

---

## Frontmatter

Every agent file starts with YAML frontmatter:

```yaml
---
name: changelog-writer
description: >
  Generates changelogs from git history.
  Use when: "changelog", "what changed", "release notes".
model: sonnet
effort: low
tools: Bash, Read, Grep, Glob
disallowedTools: Write, Edit, NotebookEdit
maxTurns: 10
---
```

### Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Matches filename without `.md` |
| `description` | Yes | What it does + trigger phrases |
| `model` | Yes | `opus` (recommended), `sonnet`, or `haiku` |
| `effort` | No | `low`, `medium` (default), `high`, `xhigh`, `max` — controls model reasoning depth. `xhigh` (v2.1.111+) sits between `high` and `max` and is Opus-4.7-only; other models fall back to `high`. Use `xhigh` for deep-reasoning agents (architect, planner, deep analysis, security review); `high` for focused reviews; `medium`/`low` for mechanical tasks |
| `tools` | Yes | Comma-separated allowed tools |
| `disallowedTools` | No | Explicitly blocked tools |
| `isolation` | No | `none` (default) or `worktree` |
| `memory` | No | `project` for persistent MEMORY.md |
| `maxTurns` | No | Max conversation turns (recommended for all agents) |
| `initialPrompt` | No | Auto-submit prompt on agent start |
| `skills` | No | Comma-separated skills available to the agent |
| `background` | No | `true` to run agent in background |

---

## Model Selection

| Model | Best For | Context | Max Output |
|-------|----------|---------|------------|
| `opus` | Deep analysis, multi-file reasoning, security review | 1M | 128K |
| `sonnet` | Quick searches, simple checks, read-only analysis | 1M | 64K |
| `haiku` | Simple, repetitive tasks | 200K | 64K |

Guidelines: Use `opus` for all agents (project default). Pair with `effort: low` for quick tasks, `effort: high` for deep analysis. Use `isolation: worktree` for write tasks that need rollback safety.

---

## Built-in Agents (21)

| Agent | Model | Effort | Tools | Isolation | maxTurns |
|-------|-------|--------|-------|-----------|----------|
| `explorer` | opus | low | Read, Glob, Grep, Bash, WebFetch | none | 15 |
| `explorer-deep` | opus | high | Read, Glob, Grep, Bash, WebFetch, WebSearch | none | 35 |
| `security-reviewer` | opus | high | All + Write/Edit | worktree | 25 |
| `commit-reviewer` | opus | low | Bash, Read, Grep, Glob | none | 10 |
| `dependency-checker` | opus | low | Bash, Read, Grep, Glob, WebSearch | none | 10 |

---

## Tool Permissions

Follow least privilege. Common profiles:

| Profile | Tools | Use Case |
|---------|-------|----------|
| Read-only | `Read, Glob, Grep, Bash` | Search, explain |
| Read + web | `+ WebFetch, WebSearch` | Research, docs lookup |
| Full access | `+ Write, Edit` | Prototyping (use with worktree) |

Use `disallowedTools` to explicitly block tools — stronger than simply not listing them.

Document Bash restrictions in the agent body:

```markdown
## Rules
- **Bash** only for: `git log`, `git diff`, `npm ls` (read-only)
```

---

## Isolation Modes

| Mode | Behavior | When |
|------|----------|------|
| `none` | Reads/writes in main project | Read-only agents |
| `worktree` | Isolated git worktree | Write access needed |

With `worktree`, changes do not affect the main project. The user decides whether to adopt them. Always document this:

```markdown
## Isolation

You work in an isolated git worktree. Changes are suggestions —
the user decides whether to adopt them.
```

---

## Minimal Example

Create `core/agents/changelog-writer.md`:

```markdown
---
name: changelog-writer
description: >
  Generates changelog entries from git history.
  Use when: "changelog", "what changed", "release notes".
model: sonnet
effort: low
tools: Bash, Read, Grep, Glob
disallowedTools: Write, Edit, NotebookEdit
maxTurns: 10
---

You are a changelog generator. Analyze git history and produce
structured entries.

## Procedure

1. Find latest tag: `git describe --tags --abbrev=0`
2. List commits since tag: `git log {tag}..HEAD --oneline`
3. Group by type: Added (feat), Fixed (fix), Changed (refactor)

## Rules

- **Read-only** -- Bash only for: git log, git tag, git describe
- No tags? Use last 20 commits. Skip merge commits.

## Output Format

## [Unreleased] - YYYY-MM-DD
### Added / Fixed / Changed
- Description (commit hash)
```

---

## Agent vs Skill

| Criterion | Agent | Skill |
|-----------|-------|-------|
| Execution | Separate sub-conversation | Instructions in main conversation |
| Model control | Own model (sonnet/opus) | Uses session model |
| Tool isolation | Own permissions | Shares session permissions |
| Worktree | Yes | No |
| Memory | `memory: project` | Via state files |
| Turn limits | `maxTurns` | No built-in limit |
| Invocation | Via Agent tool | Via `/skill-name` |
| Best for | Focused subtasks, different model | Multi-phase workflows, user interaction |

**Rule of thumb:** Agent for isolated subtasks with different model needs. Skill for complex multi-step workflows in the main conversation. They can be combined — a skill can delegate subtasks to agents.

---

## Agent Resilience

Agents should degrade gracefully when their designated model or type is unavailable:

- **Fallback behavior:** If a specific agent type is not available (e.g., model not accessible, agent file missing), the system falls back to a general-purpose agent in the main conversation.
- **Design for degradation:** Write agent instructions so the core task can still be performed by a less specialized model. Avoid hard dependencies on model-specific capabilities.
- **Retry pattern:** On "Agent not found" or model availability errors, retry the task with a fallback agent before failing. Pattern from oh-my-opencode: catch agent dispatch errors, retry with the default model.

This means agents should not assume they are the only way to accomplish a task — they are an optimization, not a hard requirement.

---

## Best Practices

1. **Always set maxTurns** — 10 for quick checks, 15-25 for analysis, 25-35 for deep work
2. **Define clear scope** — what the agent does AND does not do
3. **Structured output** — define exact format with code block examples
4. **Trigger phrases** — include in description for discoverability
5. **Read-only by default** — add Write/Edit only when needed, with worktree isolation
6. **Document Bash usage** — list specific permitted commands
7. **Sanitize agent names** — zero-width space characters (`\u200B`, `\uFEFF`, `\u200C`, `\u200D`) in agent names, YAML frontmatter keys, or markdown headers cause silent routing failures. These invisible Unicode characters can be introduced by copy-pasting from editors, web pages, or chat systems. Always strip non-printable characters except standard whitespace from agent names and config keys. (Reference: oh-my-opencode v3.16.0 fixed ZWSP pollution across multiple paths.)

---

## Next Steps

- [Writing Skills](writing-skills.md) — create skill workflows
- [Writing Hooks](writing-hooks.md) — create custom hooks
- [Architecture](architecture.md) — how agents are deployed
