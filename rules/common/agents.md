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

## Stall-Safe Agent Dispatch (Anti-Watchdog)

Subagents run under a stream watchdog — silent for ~600s → killed. Any agent doing deep scans, multi-file reads, or web fetches without pacing will stall. This is the #1 reason dispatched agents fail in Hangar.

**Rules for every `Agent(...)` call:**

1. **Scope the prompt** — one phase / one deliverable / one repo area. "Run full audit" stalls; "Phase 1 prescan only, return project-profile.md" doesn't.
2. **Declare caps** — include hard limits in the prompt: `max 15 tool calls`, `max 4 minutes`, `report under 600 words`. The agent respects limits when told; it blows past them when left open.
3. **Require heartbeats** — instruct the agent to emit a one-line progress marker every ≤2 minutes of work (`[progress] step N/M`). Silent Grep/Read loops starve the watchdog.
4. **Prefer parallel tool batches** — instruct the agent: "use parallel tool calls for independent scans, not sequential chains". A single batch of 5 Greps emits 5 tool-call events; a sequential chain emits one every N seconds.
5. **Use `timeout` in shell commands** — for any Bash command that could hang: `timeout 60 <cmd>`. Especially `find`, network tools, `gh api` without pagination.
6. **Fail-soft on stuck subtasks** — tell the agent: "if a subtask runs 5 min without new findings, mark it stalled and continue; do not retry".
7. **Chain phases externally** — don't spawn one agent for a 4-phase workflow. Spawn one agent per phase, synthesize in the parent. Each agent fits well under the watchdog window.

**Prompt template for scoped audit agents:**

```
You have ONE task: <narrow deliverable>.
Cap: <N> tool calls, <M> minutes. Emit `[progress]` line every ~90s.
Use parallel tool batches for independent scans.
If any single step takes >3 min with no output, mark it stalled and move on.
Report <= <K> words, structured, no preamble.
```

**When to skip the Agent and do it yourself:** if the task is <10 tool calls and needs fresh-session context, just run it in the main loop. The agent overhead (prompt + context rebuild) isn't worth it below that threshold — and you get live feedback instead of a black-box stall.
