# Writing Agents

A guide to creating custom agents for Claude Hangar.

## What Is an Agent?

An agent is a markdown file with YAML frontmatter that defines a specialized sub-agent. When invoked via the `Agent` tool, Claude Code spawns a sub-conversation that runs independently with its own model, tools, and scope. The agent performs a focused task and returns its result to the main conversation.

Agents are ideal for tasks that need a different model (cheaper or more capable), restricted tool access, or isolated write operations that should not affect the main project directly.

## Frontmatter Fields

Every agent file starts with YAML frontmatter:

```yaml
---
name: changelog-writer
description: >
  Generates changelogs from git history. Analyzes commits,
  groups by type, and produces a formatted CHANGELOG entry.
  Use when: "changelog", "what changed", "release notes".
model: sonnet
effort: low
tools: Bash, Read, Grep, Glob
disallowedTools: Write, Edit, NotebookEdit
maxTurns: 10
---
```

### Field Reference

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | Yes | string | Agent identifier, matches filename (without `.md`) |
| `description` | Yes | string | What the agent does + trigger phrases |
| `model` | Yes | string | `sonnet` (fast/cheap) or `opus` (deep analysis) |
| `effort` | No | string | `low`, `medium`, `high` -- controls thinking depth |
| `tools` | Yes | string | Comma-separated list of allowed tools |
| `disallowedTools` | No | string | Explicitly blocked tools (overrides defaults) |
| `isolation` | No | string | `none` (default) or `worktree` (isolated git worktree) |
| `memory` | No | string | `project` -- enables persistent MEMORY.md across sessions |
| `maxTurns` | No | integer | Maximum conversation turns before forced stop |

## Model Selection

Choose the model based on the task complexity and cost sensitivity:

| Model | Cost | Speed | Best For |
|-------|------|-------|----------|
| `sonnet` | Low | Fast | Quick searches, simple checks, read-only analysis |
| `opus` | High | Slower | Deep analysis, multi-file reasoning, security review |

### Guidelines

- **Read-only tasks** (search, explain, list): `sonnet` with `effort: low`
- **Analysis tasks** (architecture, patterns, connections): `opus` with `effort: high`
- **Write tasks** (prototyping fixes, creating reports): `opus` with `isolation: worktree`

## Tool Permissions

Follow the principle of least privilege. An agent should only have the tools it needs.

### Common Tool Sets

| Profile | Tools | Use Case |
|---------|-------|----------|
| Read-only | `Read, Glob, Grep, Bash` | Search, explain, analyze |
| Read + web | `Read, Glob, Grep, Bash, WebFetch, WebSearch` | Research, documentation lookup |
| Full access | `Read, Glob, Grep, Bash, WebFetch, WebSearch, Write, Edit` | Prototyping, report generation |

### Bash Restrictions

When an agent has `Bash` access, document what commands are permitted in the agent body:

```markdown
## Rules
- **Bash** only for: `git log`, `git diff`, `npm ls`, `node -e` (read-only)
```

This instruction tells Claude Code to limit Bash usage even though the tool itself is available. The bash-guard hook provides an additional safety layer.

### Blocking Tools Explicitly

Use `disallowedTools` to prevent an agent from modifying files:

```yaml
disallowedTools: Write, Edit, NotebookEdit
```

This is stronger than simply not listing them in `tools` -- it explicitly rejects them even if the agent tries to use them.

## Isolation Modes

| Mode | Behavior | Use When |
|------|----------|----------|
| `none` (default) | Agent reads/writes in the main project | Read-only agents, quick checks |
| `worktree` | Agent gets an isolated git worktree | Write access needed, prototyping fixes |

### Worktree Isolation

When `isolation: worktree` is set, the agent operates in a separate git worktree. Changes do not affect the main project. The user decides whether to adopt the changes.

Always document this clearly in the agent body:

```markdown
## Isolation

You work in an isolated git worktree. This means:
- You can read AND write files without affecting the main project
- Changes are suggestions -- the user decides whether to adopt them
```

## Minimal Example: changelog-writer

Create `core/agents/changelog-writer.md`:

```markdown
---
name: changelog-writer
description: >
  Generates changelog entries from git history.
  Use when: "changelog", "what changed", "release notes", "what's new".
model: sonnet
effort: low
tools: Bash, Read, Grep, Glob
disallowedTools: Write, Edit, NotebookEdit
maxTurns: 10
---

You are a changelog generator. Analyze git history and produce structured entries.

## Procedure

1. Find latest tag: `git describe --tags --abbrev=0`
2. List commits since tag: `git log {tag}..HEAD --oneline`
3. Group by type: Added (feat), Fixed (fix), Changed (refactor, perf)
4. Format as changelog entry

## Rules

- **Read-only** -- Bash only for: `git log`, `git tag`, `git describe`
- If no tags: use last 20 commits. Skip merge commits.

## Output Format

## [Unreleased] - YYYY-MM-DD
### Added / Fixed / Changed
- Description (commit hash)
```

## Agent vs Skill: When to Use Which

| Criterion | Agent | Skill |
|-----------|-------|-------|
| **Execution model** | Separate sub-conversation | Instructions in main conversation |
| **Model control** | Can use different model (sonnet for cheap tasks) | Uses the session model |
| **Tool isolation** | Own tool permissions | Shares session permissions |
| **Worktree support** | Yes (`isolation: worktree`) | No |
| **Persistent memory** | Yes (`memory: project`) | Via state files only |
| **Turn limits** | Yes (`maxTurns`) | No built-in limit |
| **State persistence** | Via memory files | Via `.{skill}-state.json` |
| **Invocation** | Via Agent tool (automatic or user request) | Via `/skill-name` command |
| **Best for** | Focused subtasks, parallel work, different model needs | Complex workflows, multi-phase processes, user interaction |

### Rules of Thumb

- **Use an agent** when you need a different model, isolated writes, or a focused subtask that should not pollute the main conversation context.
- **Use a skill** when you need multi-phase workflows, user interaction between steps, or complex state management across sessions.
- **Combine both**: A skill can delegate subtasks to agents. For example, the audit-orchestrator skill delegates phases to agent-like sub-processes.

## Best Practices

### 1. Set maxTurns

Always set `maxTurns` to prevent runaway agents:

| Agent Type | Recommended maxTurns |
|------------|---------------------|
| Quick check (read-only) | 10 |
| Standard analysis | 15-25 |
| Deep analysis with writes | 25-35 |

### 2. Clear Scope Definition

Define what the agent does and does not do. Include a comparison table if similar agents exist (see explorer.md for an example).

### 3. Structured Output Format

Define the exact output format with a code block example. This ensures consistent results across invocations.

### 4. Trigger Phrases in Description

Include natural language phrases in the description: `Use when: "changelog", "what changed", "release notes".`

### 5. Read-Only by Default

Start with minimum tools. Only add Write/Edit if genuinely needed, and use `isolation: worktree` when you do.

### 6. Document Bash Usage

List specific permitted commands: `**Bash** only for: git log, npm audit, curl (read-only)`.

### 7. Use Memory for Learning Agents

Enable `memory: project` for agents that should remember across sessions. Reference it in the body: "Use your MEMORY.md to build on previous findings."

## File Naming

Agents live in `core/agents/` as individual markdown files:

```
core/agents/
├── explorer.md
├── explorer-deep.md
├── security-reviewer.md
├── commit-reviewer.md
├── dependency-checker.md
└── changelog-writer.md      # Your new agent
```

The filename (without `.md`) becomes the agent name. Use kebab-case.

## Contributing

When submitting an agent via PR:

1. Follow naming: `core/agents/{kebab-case-name}.md`
2. Include all required frontmatter fields
3. Define clear scope, rules, and output format
4. Set appropriate `maxTurns` limit
5. Use minimum required tools
6. Test on both Linux and Git Bash (Windows) if the agent uses Bash
7. Conventional Commit: `feat(agents): add changelog-writer agent`
