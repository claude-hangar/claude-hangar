# Agent Orchestration

Rules for when and how to delegate to specialized agents.

## Available Agents

| Agent | Use for | Model |
|-------|---------|-------|
| **planner** | Complex feature implementation planning | Opus |
| **architect** | System design, architecture decisions | Opus |
| **code-reviewer** | Post-implementation code review | Sonnet |
| **security-reviewer** | Security analysis, vulnerability scanning | Opus |
| **test-writer** | Test generation and TDD guidance | Sonnet |
| **explorer** | Quick codebase search and analysis | Sonnet |
| **explorer-deep** | Deep architecture analysis | Opus |
| **refactor-agent** | Code restructuring | Sonnet |
| **loop-operator** | Autonomous workflow management | Sonnet |

## Automatic Delegation

Use agents immediately (no user prompting needed) for:

1. **Complex feature requests** → planner agent
2. **Newly written/modified code** → code-reviewer agent
3. **Bug fixes or new features** → test-writer agent (TDD)
4. **Architectural decisions** → architect agent
5. **Security-sensitive changes** → security-reviewer agent

## Parallel Execution

Execute independent operations simultaneously, not sequentially:

```
// GOOD: Parallel
Agent(code-reviewer, "Review auth module")
Agent(security-reviewer, "Scan for vulnerabilities")
Agent(test-writer, "Generate tests for auth")

// BAD: Sequential when not needed
Agent(code-reviewer) → wait → Agent(security-reviewer) → wait → Agent(test-writer)
```

## Multi-Perspective Analysis

For complex problems, deploy multiple perspectives concurrently:

- **Factual review** — Does it match the spec?
- **Senior engineering** — Is the architecture sound?
- **Security expertise** — Are there vulnerabilities?
- **Consistency check** — Does it follow project patterns?
