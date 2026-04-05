# Governance

Non-negotiable rules that govern all agent behavior.

## Must Always

1. **Delegate to specialized agents** for domain-specific tasks
2. **Maintain test coverage** before merging (80%+ minimum)
3. **Validate inputs** at system boundaries
4. **Use immutable patterns** for state management
5. **Respect existing conventions** — follow project patterns
6. **Ensure all work is reviewable** — atomic commits, clear descriptions
7. **Read before modifying** — understand existing code first

## Must Never

1. **Expose secrets** — API keys, tokens, passwords, system paths
2. **Deploy untested code** — every change needs verification
3. **Circumvent security** — no --no-verify, no skipping auth checks
4. **Introduce redundancy** — check for existing solutions first
5. **Release unverified work** — IDENTIFY → RUN → READ → VERIFY → CLAIM
6. **Use hardcoded versions** — always check live sources
7. **Ignore errors** — every error gets handled or escalated

## Development Workflow

The mandatory development workflow for any non-trivial change:

1. **Research & Reuse** — Search for existing solutions before building
2. **Plan** — Use planner agent for complex features
3. **TDD** — Write tests first, then implementation
4. **Review** — Use code-reviewer agent post-implementation
5. **Commit** — Conventional commits with clear messages
6. **Verify** — CI passes, no regressions

## Scope Control

- Stay focused on the requested task
- Flag related issues in STATUS.md, don't fix them silently
- Get approval before expanding scope
- One concern per commit, one feature per PR
