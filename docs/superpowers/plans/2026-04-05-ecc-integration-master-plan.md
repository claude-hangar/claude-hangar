# ECC Integration Master Plan — Claude Hangar Enhancement

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the best features from Everything Claude Code (ECC) into Claude Hangar — rules system, context modes, expanded agents, learning mechanisms, and enhanced hooks — to make Hangar significantly more powerful while preserving its curated, modular philosophy.

**Architecture:** Claude Hangar stays modular (core/ + stacks/). New features integrate into existing directory conventions. Rules get their own top-level `rules/` directory. Context modes live in `core/contexts/`. New agents follow existing frontmatter conventions. Learning hooks extend the existing hook system. No breaking changes to existing installations.

**Tech Stack:** Bash 4.0+ (hooks), Markdown (agents, skills, rules, contexts), JSON (configuration), Node.js (hook scripts for cross-platform JSON parsing)

**Phases Overview:**
- Phase 1: Rules System + Context Modes (foundation)
- Phase 2: Agent Expansion (planner, architect, loop-operator, language reviewers)
- Phase 3: Learning System (continuous learning, instinct capture, pattern extraction)
- Phase 4: Enhanced Hooks (cost tracking, governance, hook profiles)
- Phase 5: Language Stacks (TypeScript, Python, Go, Rust, Java)

---

## Phase 1: Rules System + Context Modes

### Task 1: Create Rules Directory Structure

**Files:**
- Create: `rules/README.md`
- Create: `rules/common/coding-style.md`
- Create: `rules/common/security.md`
- Create: `rules/common/testing.md`
- Create: `rules/common/git-workflow.md`
- Create: `rules/common/agents.md`
- Create: `rules/common/performance.md`
- Create: `rules/common/governance.md`

- [ ] **Step 1: Create rules/README.md**

```markdown
# Rules — Governance for Claude Code

Rules are always-follow guidelines that govern how Claude Code behaves across all projects.
Unlike skills (invoked on demand) or hooks (triggered by events), rules are **always active**.

## Structure

```
rules/
├── common/          # Language-agnostic rules (always loaded)
│   ├── coding-style.md
│   ├── security.md
│   ├── testing.md
│   ├── git-workflow.md
│   ├── agents.md
│   ├── performance.md
│   └── governance.md
├── typescript/      # TypeScript-specific rules
├── python/          # Python-specific rules
├── go/              # Go-specific rules
├── rust/            # Rust-specific rules
└── java/            # Java-specific rules
```

## How Rules Work

Rules are deployed to `~/.claude/rules/` by `setup.sh`. Claude Code loads them via
the settings.json `rules` configuration. Common rules apply to every project.
Language-specific rules are activated per-project based on detected stack.

## Rule Format

Each rule file is a Markdown document with clear, enforceable guidelines.
Rules use imperative language: "Do X", "Never Y", "Always Z".

## Customization

- Override rules by placing project-specific versions in your repo's `.claude/rules/`
- Disable specific rules in `settings.json` under `rules.disabled`
- Add custom rules following the same format

## Relationship to Other Components

| Component | Purpose | When |
|-----------|---------|------|
| **Rules** | Always-on governance | Every interaction |
| **Skills** | On-demand workflows | Invoked by user |
| **Hooks** | Event-triggered automation | System events |
| **Agents** | Specialized delegation | Dispatched for tasks |
```

- [ ] **Step 2: Create rules/common/coding-style.md**

```markdown
# Coding Style

Rules for writing clean, maintainable code across all languages.

## Immutability

Prefer immutable patterns. Create new objects instead of mutating existing ones.

**Why:** Prevents hidden side effects, makes debugging easier, enables safe concurrency.

```
// GOOD: Create new object
const updated = { ...original, status: "active" };

// BAD: Mutate in place
original.status = "active";
```

## File Organization

Many small files > few large files.

- **Target:** 200-400 lines per file
- **Maximum:** 800 lines (extract utilities if exceeding)
- **Organize by:** Feature/domain, not by type
- **Each file:** One clear responsibility

## Function Size

- **Target:** Under 30 lines
- **Maximum:** 50 lines
- **Nesting:** Maximum 4 levels deep — extract helper if deeper

## Error Handling

Handle errors explicitly at every level:

- Provide user-friendly messages in UI code
- Log detailed error context server-side
- Never silently swallow errors
- Use typed error classes where the language supports them

## Input Validation

Validate at system boundaries:

- All user input before processing
- All API responses before use
- All file content before parsing
- Use schema-based validation (Zod, Pydantic, etc.)
- Fail fast with clear messages

## Naming

- Variables/functions: descriptive, verb-based for functions (`getUserById`, `validateInput`)
- Constants: UPPER_SNAKE_CASE
- Types/Classes: PascalCase
- Files: kebab-case or match framework convention
- No abbreviations unless universally understood (`id`, `url`, `db`)

## Code Quality Checklist

Before considering code complete:

- [ ] Readable without comments (self-documenting)
- [ ] Functions under 50 lines
- [ ] Files under 800 lines
- [ ] Nesting under 4 levels
- [ ] Errors handled explicitly
- [ ] No hardcoded values (use constants/config)
- [ ] Immutable patterns used where possible
```

- [ ] **Step 3: Create rules/common/security.md**

```markdown
# Security

Non-negotiable security rules for every project.

## Pre-Commit Checklist

Before any commit, verify:

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] SQL injection prevention (parameterized queries only)
- [ ] XSS prevention (sanitized HTML output)
- [ ] CSRF protection enabled (where applicable)
- [ ] Authentication/authorization verified on all endpoints
- [ ] Rate limiting on public endpoints
- [ ] Error messages do not leak sensitive data

## Secret Management

- **NEVER** hardcode secrets in source code
- **ALWAYS** use environment variables or a secret manager
- **VALIDATE** required secrets are present at startup
- **ROTATE** any secrets that may have been exposed
- **GITIGNORE** all .env files (except .env.example with placeholder values)

## Security Response Protocol

When a vulnerability is discovered:

1. **STOP** current work immediately
2. **ASSESS** severity (critical/high/medium/low)
3. **FIX** critical issues before resuming any other work
4. **ROTATE** any exposed credentials
5. **SCAN** codebase for similar vulnerabilities
6. **DOCUMENT** the vulnerability and fix

## Dependency Security

- Run `npm audit` / `pip audit` / `go vet` before deployment
- Pin exact dependency versions in lock files
- Review new dependencies for security advisories
- Prefer well-maintained packages with active security response

## OWASP Top 10 Awareness

Every developer interaction must consider:

1. **Injection** — Parameterized queries, no string concatenation
2. **Broken Auth** — Secure session management, strong passwords
3. **Sensitive Data** — Encrypt at rest and in transit
4. **XXE** — Disable external entity processing
5. **Broken Access** — Verify authorization on every request
6. **Misconfiguration** — Secure defaults, no debug in production
7. **XSS** — Output encoding, CSP headers
8. **Deserialization** — Validate before deserializing
9. **Components** — Keep dependencies updated
10. **Logging** — Log security events, monitor anomalies
```

- [ ] **Step 4: Create rules/common/testing.md**

```markdown
# Testing

Testing requirements for all projects.

## Minimum Coverage

**80%** test coverage as baseline. Critical paths (auth, payments, data mutations) require **95%+**.

## Required Test Types

| Type | Scope | When |
|------|-------|------|
| **Unit** | Isolated functions/components | Every feature |
| **Integration** | API endpoints, DB operations | Every backend change |
| **E2E** | Critical user workflows | Before release |

All three types are required — none optional.

## TDD Workflow (Mandatory for New Features)

1. **RED** — Write the failing test first
2. **GREEN** — Write minimum code to make it pass
3. **IMPROVE** — Refactor while keeping tests green
4. Verify coverage meets 80%+ threshold

## Test Quality

- Tests must be deterministic (no flaky tests)
- Tests must be independent (no shared state between tests)
- Test names describe the behavior, not the implementation
- Each test tests ONE thing
- Arrange-Act-Assert pattern

## When Tests Fail

1. **Fix the implementation**, not the test (unless the test is wrong)
2. Check test isolation — tests should not depend on each other
3. Validate mocks match real behavior
4. Use the tdd-guide agent for complex test scenarios

## What NOT to Test

- Framework internals (React rendering, Express routing)
- Simple getters/setters with no logic
- Third-party library behavior
- Constants and configuration values
```

- [ ] **Step 5: Create rules/common/git-workflow.md**

```markdown
# Git Workflow

Git conventions for consistent version control.

## Commit Messages

Format: `<type>(<scope>): <description>`

### Allowed Types

| Type | Use for |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring (no behavior change) |
| `docs` | Documentation only |
| `test` | Adding/fixing tests |
| `chore` | Build, tooling, dependencies |
| `perf` | Performance improvement |
| `ci` | CI/CD changes |
| `style` | Formatting (no code change) |
| `build` | Build system changes |
| `revert` | Reverting a previous commit |

### Rules

- Subject line: max 72 characters
- No trailing period
- Imperative mood ("add feature", not "added feature")
- Body: explain WHY, not WHAT (the diff shows what)

## Branch Strategy

- `main` — production-ready, always deployable
- `feat/<name>` — feature branches
- `fix/<name>` — bugfix branches
- `chore/<name>` — maintenance branches

## Pull Request Workflow

1. Review complete commit history (not just latest commit)
2. Run `git diff <base-branch>...HEAD` to inspect all changes
3. Write detailed PR description with context
4. Include test plan
5. Push with `-u` flag for new branches

## Pre-Push Checklist

- [ ] All tests pass
- [ ] No linting errors
- [ ] No type errors
- [ ] Branch is up-to-date with target
- [ ] Commit messages follow convention
```

- [ ] **Step 6: Create rules/common/agents.md**

```markdown
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
```

- [ ] **Step 7: Create rules/common/performance.md**

```markdown
# Performance

Performance guidelines for all projects.

## General Principles

- Measure before optimizing — no premature optimization
- Set performance budgets early (LCP < 2.5s, CLS < 0.1, INP < 200ms)
- Profile bottlenecks before fixing (CPU, memory, network, I/O)
- Cache aggressively at every layer (CDN, application, database)

## Frontend Performance

- **Bundle size:** Track and set limits (< 200KB initial JS)
- **Images:** Use modern formats (WebP/AVIF), lazy load below fold
- **Fonts:** Preload critical fonts, use font-display: swap
- **CSS:** Purge unused styles, use CSS containment
- **JavaScript:** Code-split by route, defer non-critical scripts
- **Rendering:** Minimize layout shifts, avoid forced reflows

## Backend Performance

- **Database:** Index frequently queried columns, avoid N+1 queries
- **Caching:** Redis/memory cache for hot data, cache invalidation strategy
- **API:** Pagination for list endpoints, field selection for large objects
- **Async:** Use async/await for I/O-bound operations
- **Pooling:** Connection pools for databases and HTTP clients

## Database Performance

- Use `EXPLAIN ANALYZE` before deploying complex queries
- Index foreign keys and frequently filtered columns
- Avoid SELECT * — specify needed columns
- Use batch operations instead of loops
- Monitor slow query logs
```

- [ ] **Step 8: Create rules/common/governance.md**

```markdown
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
```

- [ ] **Step 9: Commit rules directory**

```bash
cd D:/backupblu/github/claude-hangar/claude-hangar
git add rules/
git commit -m "feat(rules): add governance rules system inspired by ECC

Add common rules for coding-style, security, testing, git-workflow,
agents, performance, and governance. Rules are always-active guidelines
that complement hooks (event-triggered) and skills (on-demand).

Inspired by Everything Claude Code's rules system."
```

---

### Task 2: Create Context Modes

**Files:**
- Create: `core/contexts/dev.md`
- Create: `core/contexts/research.md`
- Create: `core/contexts/review.md`
- Create: `core/contexts/README.md`

- [ ] **Step 1: Create core/contexts/README.md**

```markdown
# Context Modes — Dynamic Prompt Injection

Context modes allow you to switch Claude Code's behavior profile without
modifying CLAUDE.md. Each mode adjusts priorities, tool preferences, and output style.

## Available Modes

| Mode | File | Focus |
|------|------|-------|
| `dev` | dev.md | Implementation, coding, building features |
| `research` | research.md | Understanding before acting, exploration |
| `review` | review.md | PR review, code analysis, quality |

## Usage

### Via CLI flag
```bash
claude --system-prompt "$(cat ~/.claude/contexts/dev.md)"
```

### Via session start
The session-start hook can auto-detect the appropriate context based on
the user's first message or current git state (e.g., review mode when
on a PR branch).

## Customization

Create project-specific contexts in your repo's `.claude/contexts/` directory.
These override the global contexts from `~/.claude/contexts/`.

## Philosophy

Context modes are **surgical, not monolithic**. Instead of bloating CLAUDE.md
with conditional instructions, modes provide focused behavioral profiles
that can be switched at any time.
```

- [ ] **Step 2: Create core/contexts/dev.md**

```markdown
# Development Context

Mode: Active development
Focus: Implementation, coding, building features

## Behavior

- Write code first, explain after
- Prefer working solutions over perfect solutions
- Run tests after changes
- Keep commits atomic
- Use TDD: RED → GREEN → IMPROVE

## Priorities

1. Get it working (correct behavior)
2. Get it right (clean architecture)
3. Get it fast (performance)

## Tool Preferences

- Edit, Write for code changes
- Bash for running tests/builds
- Grep, Glob for finding code
- Agent(planner) for complex features
- Agent(test-writer) for TDD guidance

## Anti-Patterns in Dev Mode

- Don't over-research before writing code
- Don't refactor unrelated code
- Don't add features that weren't requested
- Don't optimize before measuring
```

- [ ] **Step 3: Create core/contexts/research.md**

```markdown
# Research Context

Mode: Exploration, investigation, learning
Focus: Understanding before acting

## Behavior

- Read widely before concluding
- Ask clarifying questions when uncertain
- Document findings as you go
- Don't write code until understanding is clear
- Verify assumptions with evidence

## Research Process

1. Understand the question
2. Explore relevant code/docs
3. Form hypothesis
4. Verify with evidence
5. Summarize findings

## Tool Preferences

- Read for understanding code
- Grep, Glob for finding patterns
- WebSearch, WebFetch for external docs
- Agent(explorer) for quick codebase questions
- Agent(explorer-deep) for architecture analysis

## Output

Findings first, recommendations second.
Always cite file paths and line numbers.
```

- [ ] **Step 4: Create core/contexts/review.md**

```markdown
# Code Review Context

Mode: PR review, code analysis
Focus: Quality, security, maintainability

## Behavior

- Read thoroughly before giving feedback
- Rank issues by severity: critical > high > medium > low
- Suggest solutions alongside problems
- Check for security vulnerabilities first
- Verify test coverage

## Review Checklist

- [ ] Logic errors
- [ ] Edge cases not handled
- [ ] Error handling gaps
- [ ] Security concerns (injection, auth, secrets)
- [ ] Performance implications
- [ ] Readability and naming
- [ ] Test coverage adequate
- [ ] Consistent with project patterns

## Output Format

Organize findings by file, sorted by severity.
Include code suggestions for fixes.

## Tool Preferences

- Read for examining code
- Grep for finding patterns and usages
- Agent(security-reviewer) for security checks
- Bash for running tests and linters
```

- [ ] **Step 5: Commit context modes**

```bash
cd D:/backupblu/github/claude-hangar/claude-hangar
git add core/contexts/
git commit -m "feat(contexts): add dynamic context modes (dev, research, review)

Context modes allow switching Claude Code's behavioral profile without
modifying CLAUDE.md. Modes adjust priorities, tool preferences, and
output style. Inspired by ECC's context injection system."
```

---

### Task 3: Update setup.sh to Deploy Rules and Contexts

**Files:**
- Modify: `setup.sh`

- [ ] **Step 1: Add rules deployment to setup.sh**

After the existing agent deployment section, add:

```bash
# ─── Deploy Rules ─────────────────────────────────────────────────────

deploy_rules() {
  info "Deploying rules..."
  local rules_src="$SCRIPT_DIR/rules"
  local rules_dst="$CLAUDE_DIR/rules"

  if [ ! -d "$rules_src" ]; then
    warn "No rules directory found — skipping"
    return 0
  fi

  mkdir -p "$rules_dst"

  # Copy common rules (always deployed)
  if [ -d "$rules_src/common" ]; then
    mkdir -p "$rules_dst/common"
    cp -r "$rules_src/common/"* "$rules_dst/common/" 2>/dev/null || true
    success "Common rules deployed"
  fi

  # Copy language-specific rules if they exist
  for lang_dir in "$rules_src"/*/; do
    lang=$(basename "$lang_dir")
    [ "$lang" = "common" ] && continue
    [ "$lang" = "README.md" ] && continue
    [ ! -d "$lang_dir" ] && continue
    mkdir -p "$rules_dst/$lang"
    cp -r "$lang_dir"* "$rules_dst/$lang/" 2>/dev/null || true
    success "Rules deployed: $lang"
  done
}
```

- [ ] **Step 2: Add contexts deployment to setup.sh**

```bash
# ─── Deploy Contexts ──────────────────────────────────────────────────

deploy_contexts() {
  info "Deploying context modes..."
  local ctx_src="$SCRIPT_DIR/core/contexts"
  local ctx_dst="$CLAUDE_DIR/contexts"

  if [ ! -d "$ctx_src" ]; then
    warn "No contexts directory found — skipping"
    return 0
  fi

  mkdir -p "$ctx_dst"
  cp "$ctx_src"/*.md "$ctx_dst/" 2>/dev/null || true
  success "Context modes deployed ($(ls -1 "$ctx_dst"/*.md 2>/dev/null | wc -l) modes)"
}
```

- [ ] **Step 3: Wire deployment functions into main flow**

In the main deployment section (after `deploy_agents` call), add:

```bash
deploy_rules
deploy_contexts
```

- [ ] **Step 4: Add rules and contexts to validate_structure**

In the `validate_structure` function, add the new directories to the check:

```bash
# Optional directories (warn if missing, don't fail)
for dir in rules core/contexts; do
  if [ ! -d "$SCRIPT_DIR/$dir" ]; then
    warn "Optional directory missing: $dir"
  fi
done
```

- [ ] **Step 5: Commit setup.sh changes**

```bash
git add setup.sh
git commit -m "feat(setup): add rules and contexts deployment

setup.sh now deploys rules/ to ~/.claude/rules/ and
core/contexts/ to ~/.claude/contexts/ during installation."
```

---

### Task 4: Update Documentation and skills_index.json

**Files:**
- Modify: `README.md` (add rules and contexts to structure table)
- Modify: `CLAUDE.md` (mention rules system)

- [ ] **Step 1: Update README.md structure table**

Add to the repository structure table:

```markdown
| `rules/` | Always-on governance rules (coding style, security, testing) |
| `core/contexts/` | Dynamic context modes (dev, research, review) |
```

- [ ] **Step 2: Update CLAUDE.md with rules reference**

Add to the "Repository Structure" table:

```markdown
| `rules/` | Always-on governance rules (common + language-specific) |
```

- [ ] **Step 3: Commit documentation updates**

```bash
git add README.md CLAUDE.md
git commit -m "docs: add rules system and context modes to documentation"
```

---

## Phase 2: Agent Expansion

### Task 5: Create Planner Agent

**Files:**
- Create: `core/agents/planner.md`

- [ ] **Step 1: Write planner agent**

```markdown
---
name: planner
description: >
  Expert planning specialist for complex features and refactoring.
  Use PROACTIVELY when users request feature implementation, architectural
  changes, or complex refactoring. Automatically activated for planning tasks.
model: opus
tools: Read, Grep, Glob
disallowedTools: Write, Edit, NotebookEdit
maxTurns: 20
---

You are an expert planning specialist focused on creating comprehensive,
actionable implementation plans.

## Your Role

- Analyze requirements and create detailed implementation plans
- Break down complex features into manageable steps
- Identify dependencies and potential risks
- Suggest optimal implementation order
- Consider edge cases and error scenarios

## Planning Process

### 1. Requirements Analysis
- Understand the feature request completely
- Ask clarifying questions if needed
- Identify success criteria
- List assumptions and constraints

### 2. Architecture Review
- Analyze existing codebase structure
- Identify affected components
- Review similar implementations
- Consider reusable patterns

### 3. Step Breakdown

Create detailed steps with:
- Clear, specific actions
- Exact file paths and locations
- Dependencies between steps
- Estimated complexity (S/M/L)
- Potential risks

### 4. Implementation Order
- Prioritize by dependencies
- Group related changes
- Minimize context switching
- Enable incremental testing

## Plan Format

```
# Implementation Plan: [Feature Name]

## Overview
[2-3 sentence summary]

## Requirements
- [Requirement 1]
- [Requirement 2]

## Implementation Steps

### Phase 1: [Phase Name]
1. **[Step Name]** (File: path/to/file)
   - Action: Specific action to take
   - Why: Reason for this step
   - Dependencies: None / Requires step X
   - Risk: Low/Medium/High

## Testing Strategy
- Unit tests: [files to test]
- Integration tests: [flows to test]

## Risks & Mitigations
- **Risk**: [Description] → Mitigation: [How to address]
```

## Best Practices

1. **Be Specific**: Exact file paths, function names, variable names
2. **Consider Edge Cases**: Error scenarios, null values, empty states
3. **Minimize Changes**: Extend existing code over rewriting
4. **Maintain Patterns**: Follow existing project conventions
5. **Enable Testing**: Structure changes to be easily testable
6. **Think Incrementally**: Each step should be independently verifiable
```

- [ ] **Step 2: Commit planner agent**

```bash
git add core/agents/planner.md
git commit -m "feat(agents): add planner agent for implementation planning

Expert planning specialist that creates detailed, actionable implementation
plans with phases, dependencies, and risk assessment. Uses Opus model.
Inspired by ECC's planner agent."
```

---

### Task 6: Create Architect Agent

**Files:**
- Create: `core/agents/architect.md`

- [ ] **Step 1: Write architect agent**

```markdown
---
name: architect
description: >
  Software architecture specialist for system design, scalability, and technical
  decisions. Use PROACTIVELY when planning new features, refactoring large systems,
  or making architectural decisions.
model: opus
tools: Read, Grep, Glob, WebSearch, WebFetch
disallowedTools: Write, Edit, NotebookEdit
maxTurns: 25
---

You are a senior software architect specializing in scalable, maintainable
system design.

## Your Role

- Design system architecture for new features
- Evaluate technical trade-offs
- Recommend patterns and best practices
- Identify scalability bottlenecks
- Ensure consistency across codebase

## Architecture Review Process

### 1. Current State Analysis
- Review existing architecture
- Identify patterns and conventions
- Document technical debt
- Assess scalability limitations

### 2. Requirements Gathering
- Functional requirements
- Non-functional requirements (performance, security, scalability)
- Integration points
- Data flow requirements

### 3. Design Proposal
- High-level architecture overview
- Component responsibilities
- Data models and API contracts
- Integration patterns

### 4. Trade-Off Analysis

For each design decision, document:
- **Pros**: Benefits and advantages
- **Cons**: Drawbacks and limitations
- **Alternatives**: Other options considered
- **Decision**: Final choice and rationale

## Architectural Principles

1. **Modularity** — Single responsibility, high cohesion, low coupling
2. **Scalability** — Horizontal scaling, stateless design, caching strategies
3. **Maintainability** — Clear organization, consistent patterns, easy to test
4. **Security** — Defense in depth, least privilege, secure by default
5. **Performance** — Efficient algorithms, minimal requests, appropriate caching

## Architecture Decision Records (ADRs)

For significant decisions, create an ADR:

```
# ADR-NNN: [Decision Title]

## Context
[Why this decision is needed]

## Decision
[What was decided]

## Consequences
### Positive
- [Benefit 1]

### Negative
- [Drawback 1]

### Alternatives Considered
- [Alternative 1]: [Why rejected]

## Status: [Proposed | Accepted | Deprecated]
```

## Anti-Patterns to Flag

- **Big Ball of Mud** — No clear structure
- **God Object** — One component does everything
- **Tight Coupling** — Components too dependent on each other
- **Premature Optimization** — Optimizing without measuring
- **Golden Hammer** — Using same solution for everything
```

- [ ] **Step 2: Commit architect agent**

```bash
git add core/agents/architect.md
git commit -m "feat(agents): add architect agent for system design

Senior architecture specialist that evaluates trade-offs, recommends
patterns, and creates Architecture Decision Records. Uses Opus model.
Inspired by ECC's architect agent."
```

---

### Task 7: Create Loop Operator Agent

**Files:**
- Create: `core/agents/loop-operator.md`

- [ ] **Step 1: Write loop-operator agent**

```markdown
---
name: loop-operator
description: >
  Manages autonomous execution workflows with safety guardrails.
  Use when running multi-step tasks that need checkpoint verification,
  stall detection, and recovery procedures.
model: sonnet
tools: Read, Grep, Glob, Bash, Edit, Write, Agent
maxTurns: 50
---

You are an autonomous workflow operator with built-in safety guardrails.

## Your Role

- Execute multi-step implementation plans
- Verify checkpoints between steps
- Detect and recover from stalls
- Maintain execution logs
- Know when to stop and escalate

## Execution Protocol

### Before Each Step
1. Read the current plan state
2. Verify prerequisites are met
3. Check for blockers

### During Each Step
1. Execute the planned action
2. Verify the result matches expectations
3. Log outcome and any surprises

### After Each Step
1. Run relevant tests
2. Update progress tracking
3. Commit if step is complete

### Stall Detection

If any of these occur, STOP and escalate:

- Same error occurs 3 times consecutively
- A step takes more than 10 minutes without progress
- Tests regress (previously passing tests now fail)
- A dependency is missing that wasn't in the plan
- Scope expansion detected (fixing things not in the plan)

## Safety Guardrails

1. **No destructive operations** without explicit confirmation
2. **No scope expansion** — stick to the plan
3. **Checkpoint commits** after every successful step
4. **Rollback capability** — know how to undo each step
5. **Escalation threshold** — 3 failures = stop and report

## Execution Log Format

```
## Step N: [Step Name]
- Status: SUCCESS | FAILED | SKIPPED
- Duration: Xm Ys
- Tests: X passed, Y failed
- Commit: abc1234
- Notes: [Any observations]
```

## Recovery Procedures

### On Test Failure
1. Read the error message carefully
2. Check if the failure is related to the current step
3. If yes: fix and retry (max 3 attempts)
4. If no: escalate — regression detected

### On Build Error
1. Check build output for the specific error
2. Fix the immediate cause
3. Re-run build to verify
4. If not fixable in 2 attempts: escalate

### On Stall
1. Document current state
2. List what was attempted
3. Propose 2 alternative approaches
4. Escalate to user for decision
```

- [ ] **Step 2: Commit loop-operator agent**

```bash
git add core/agents/loop-operator.md
git commit -m "feat(agents): add loop-operator agent for autonomous workflows

Manages multi-step execution with checkpoint verification, stall detection,
and recovery procedures. Includes safety guardrails and escalation rules.
Inspired by ECC's loop-operator pattern."
```

---

### Task 8: Create Language-Specific Reviewer Agents

**Files:**
- Create: `core/agents/typescript-reviewer.md`
- Create: `core/agents/python-reviewer.md`
- Create: `core/agents/go-reviewer.md`

- [ ] **Step 1: Write TypeScript reviewer agent**

```markdown
---
name: typescript-reviewer
description: >
  TypeScript-specific code reviewer. Use when reviewing TypeScript/JavaScript code
  for type safety, patterns, and best practices.
model: sonnet
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit, NotebookEdit
maxTurns: 15
---

You are a TypeScript code review specialist.

## Review Focus

### Type Safety
- No `any` types without explicit justification
- Proper use of generics (not over-engineered)
- Strict null checks honored
- Union types preferred over type assertions
- Zod/Valibot for runtime validation at boundaries

### Patterns
- Immutable patterns (spread, Object.freeze for constants)
- Async/await over raw Promises (no callback hell)
- Proper error handling (typed errors, Result patterns)
- Module organization (barrel exports used sparingly)

### Performance
- No unnecessary re-renders (React: memo, useMemo, useCallback)
- Bundle size awareness (tree-shakeable imports)
- Lazy loading for routes and heavy components
- No synchronous file I/O in server code

### Common Issues
- Missing `return` types on exported functions
- Unused imports/variables
- Console.log left in production code
- Missing error boundaries (React)
- Unhandled promise rejections
- Circular dependencies

## Output Format

```
## [File Path]

### CRITICAL
- Line X: [Issue description]
  Fix: [Code suggestion]

### HIGH
- Line X: [Issue description]

### MEDIUM
- Line X: [Issue description]
```
```

- [ ] **Step 2: Write Python reviewer agent**

```markdown
---
name: python-reviewer
description: >
  Python-specific code reviewer. Use when reviewing Python code
  for type hints, patterns, and best practices.
model: sonnet
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit, NotebookEdit
maxTurns: 15
---

You are a Python code review specialist.

## Review Focus

### Type Hints
- All public functions must have type hints
- Use `from __future__ import annotations` for modern syntax
- Proper use of Optional, Union, TypeVar
- Pydantic models for data validation at boundaries

### Patterns
- Context managers for resource handling (with statements)
- List/dict/set comprehensions over manual loops (when readable)
- Proper exception hierarchy (specific exceptions, not bare except)
- Dataclasses or Pydantic for data containers
- Pathlib over os.path

### Performance
- Generator expressions for large datasets
- Avoid global mutable state
- Use slots for performance-critical classes
- Profile before optimizing (cProfile, line_profiler)

### Common Issues
- Bare `except:` clauses
- Mutable default arguments
- Missing `__init__.py` in packages
- Import cycles
- String formatting inconsistency (pick f-strings or .format)
- Missing virtual environment

## Output Format

Same as TypeScript reviewer — organize by file, rank by severity.
```

- [ ] **Step 3: Write Go reviewer agent**

```markdown
---
name: go-reviewer
description: >
  Go-specific code reviewer. Use when reviewing Go code
  for idioms, error handling, and best practices.
model: sonnet
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit, NotebookEdit
maxTurns: 15
---

You are a Go code review specialist.

## Review Focus

### Error Handling
- Every error must be checked (no `_ = err`)
- Wrap errors with context: `fmt.Errorf("operation failed: %w", err)`
- Use sentinel errors for expected conditions
- Custom error types for domain errors

### Idioms
- Accept interfaces, return structs
- Table-driven tests
- Short variable names in small scopes, descriptive in large
- Avoid init() functions
- Use context.Context for cancellation and deadlines

### Concurrency
- No goroutine leaks (ensure goroutines can exit)
- Channel direction in function signatures
- sync.Mutex for simple cases, channels for communication
- errgroup for parallel operations with error handling
- Race condition awareness (run with -race flag)

### Performance
- Avoid unnecessary allocations
- Pre-allocate slices when size is known
- Use strings.Builder for string concatenation
- Profile with pprof before optimizing

### Common Issues
- Exported names without documentation comments
- Unnecessary else clauses (use early returns)
- Over-use of interfaces (don't abstract too early)
- Missing defer for cleanup
- Unused parameters/variables

## Output Format

Same as TypeScript reviewer — organize by file, rank by severity.
```

- [ ] **Step 4: Commit language reviewers**

```bash
git add core/agents/typescript-reviewer.md core/agents/python-reviewer.md core/agents/go-reviewer.md
git commit -m "feat(agents): add language-specific reviewer agents (TS, Python, Go)

Specialized code reviewers for TypeScript, Python, and Go with
language-specific patterns, anti-patterns, and review checklists.
Inspired by ECC's language-specific reviewer agents."
```

---

### Task 9: Create Build Resolver Agents

**Files:**
- Create: `core/agents/build-resolver-typescript.md`
- Create: `core/agents/build-resolver-python.md`
- Create: `core/agents/build-resolver-go.md`

- [ ] **Step 1: Write TypeScript build resolver**

```markdown
---
name: build-resolver-typescript
description: >
  Resolves TypeScript/JavaScript build errors. Use when tsc, webpack, vite,
  esbuild, or other TS/JS build tools fail.
model: sonnet
tools: Read, Grep, Glob, Bash, Edit, Write
maxTurns: 20
---

You are a TypeScript build error specialist.

## Process

1. **Read the full error output** — don't guess from partial messages
2. **Identify the error type** — type error, module resolution, config issue
3. **Find the root cause** — often upstream from where the error appears
4. **Fix minimally** — smallest change that resolves the error
5. **Verify** — re-run the build to confirm

## Common Error Categories

### Type Errors (TS2xxx)
- TS2322: Type assignability — check the types on both sides
- TS2345: Argument type mismatch — check function signature
- TS2339: Property doesn't exist — check the type definition
- TS2304: Cannot find name — missing import or declaration

### Module Resolution
- Cannot find module — check paths, tsconfig paths, package.json exports
- Module has no exported member — version mismatch or wrong import

### Configuration
- tsconfig.json issues — check extends, paths, outDir, rootDir
- Conflicting options — strictNullChecks, esModuleInterop, moduleResolution

## Rules

- Never suppress errors with `@ts-ignore` unless explicitly approved
- Fix the type, don't cast to `any`
- If a dependency type is wrong, check for `@types/` package or create a `.d.ts`
- Always re-run build after fix to verify
```

- [ ] **Step 2: Write Python build resolver**

```markdown
---
name: build-resolver-python
description: >
  Resolves Python build, import, and runtime errors. Use when pip, poetry,
  pytest, or Python scripts fail.
model: sonnet
tools: Read, Grep, Glob, Bash, Edit, Write
maxTurns: 20
---

You are a Python build/runtime error specialist.

## Process

1. **Read the full traceback** — bottom-up (most specific error last)
2. **Identify the error type** — ImportError, SyntaxError, TypeError, etc.
3. **Find the root cause** — check imports, versions, virtual environments
4. **Fix minimally** — smallest change that resolves the error
5. **Verify** — re-run the failing command

## Common Error Categories

### Import Errors
- ModuleNotFoundError — missing package, wrong venv, or path issue
- ImportError — circular import or wrong module structure
- Fix: Check requirements.txt/pyproject.toml, verify venv activation

### Dependency Conflicts
- Version conflicts — pip install output shows incompatibility
- Fix: Use `pip install --dry-run` to check, pin compatible versions

### Runtime Errors
- TypeError — wrong argument types, check function signatures
- AttributeError — object doesn't have attribute, check types
- KeyError — missing dict key, use .get() with default

## Rules

- Always check if virtual environment is active first
- Never install packages globally — use venv/poetry/pipenv
- Check Python version compatibility (3.8+ minimum)
- Always re-run the failing command after fix
```

- [ ] **Step 3: Write Go build resolver**

```markdown
---
name: build-resolver-go
description: >
  Resolves Go build, test, and dependency errors. Use when go build, go test,
  or go mod commands fail.
model: sonnet
tools: Read, Grep, Glob, Bash, Edit, Write
maxTurns: 20
---

You are a Go build error specialist.

## Process

1. **Read the full error output** — Go errors are usually precise
2. **Identify the error type** — compilation, linking, module, or test
3. **Find the root cause** — check imports, types, and module graph
4. **Fix minimally** — smallest change that resolves the error
5. **Verify** — re-run `go build ./...` or `go test ./...`

## Common Error Categories

### Compilation Errors
- Undefined references — missing import or typo
- Type mismatch — check function signatures and interfaces
- Unused imports/variables — remove them (Go doesn't allow unused code)

### Module Errors
- Module not found — run `go mod tidy`
- Version conflicts — check go.mod replace directives
- Checksum mismatch — run `go clean -modcache`

### Test Errors
- Test compilation — check test file naming (_test.go)
- Test failures — read assertion messages carefully
- Race conditions — run with `go test -race`

## Rules

- Run `go mod tidy` after any dependency change
- Run `go vet ./...` before committing
- Never vendor without explicit approval
- Always re-run `go build ./...` after fix
```

- [ ] **Step 4: Commit build resolvers**

```bash
git add core/agents/build-resolver-*.md
git commit -m "feat(agents): add build resolver agents (TS, Python, Go)

Specialized agents for resolving build errors in TypeScript, Python, and Go.
Each agent follows a systematic process: read error → identify type →
find root cause → fix minimally → verify."
```

---

## Phase 3: Learning System

### Task 10: Create Continuous Learning Hook

**Files:**
- Create: `core/hooks/continuous-learning.sh`

- [ ] **Step 1: Write the continuous learning hook**

```bash
#!/usr/bin/env bash
# Hook: Continuous Learning (PostToolUse)
# Captures successful patterns and stores them for future reference.
# Trigger: PostToolUse (Bash, Edit, Write)
#
# Captures:
# - Commands that succeeded after a failure (recovery patterns)
# - File modifications that fixed test failures
# - Patterns in successful workflows
#
# Storage: ~/.claude/.patterns/

# No set -euo pipefail — hooks must be resilient on Windows

INPUT=$(cat 2>/dev/null) || true
[ -z "$INPUT" ] && exit 0

PATTERNS_DIR="$HOME/.claude/.patterns"
mkdir -p "$PATTERNS_DIR"

# Extract tool name and result
TOOL_NAME=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_name || '');
" 2>/dev/null || echo "")

# Only capture from Bash tool (commands with observable outcomes)
[ "$TOOL_NAME" != "Bash" ] && exit 0

COMMAND=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_input?.command || '');
" 2>/dev/null || echo "")

EXIT_CODE=$(echo "$INPUT" | node -e "
  const d = JSON.parse(require('fs').readFileSync(0,'utf8'));
  console.log(d.tool_result?.exit_code ?? '');
" 2>/dev/null || echo "")

# Skip empty or trivial commands
[ -z "$COMMAND" ] && exit 0
echo "$COMMAND" | grep -qE '^(ls|cd|pwd|echo|cat|head|tail)' && exit 0

# Record pattern: timestamp, command, success/failure
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOGFILE="$PATTERNS_DIR/session-$(date +%Y-%m-%d).jsonl"

node -e "
  const entry = {
    timestamp: process.argv[1],
    command: process.argv[2],
    exit_code: parseInt(process.argv[3]) || 0,
    project: process.cwd()
  };
  console.log(JSON.stringify(entry));
" "$TIMESTAMP" "$COMMAND" "$EXIT_CODE" >> "$LOGFILE" 2>/dev/null

exit 0
```

- [ ] **Step 2: Commit continuous learning hook**

```bash
git add core/hooks/continuous-learning.sh
git commit -m "feat(hooks): add continuous learning hook

Captures command patterns and outcomes to ~/.claude/.patterns/ for
future pattern analysis. Records timestamps, commands, exit codes,
and project context. Inspired by ECC's continuous learning system."
```

---

### Task 11: Create Pattern Extractor Skill

**Files:**
- Create: `core/skills/pattern-extractor/SKILL.md`
- Create: `core/skills/pattern-extractor/skill.json`

- [ ] **Step 1: Write skill.json**

```json
{
  "name": "pattern-extractor",
  "version": "1.0.0",
  "description": "Analyzes captured patterns from continuous learning to extract reusable workflows and anti-patterns.",
  "category": "learning",
  "risk": "safe",
  "triggers": ["patterns", "learn", "extract patterns", "what did I learn", "analyze patterns"],
  "platforms": { "claude-code": "supported" },
  "dependencies": [],
  "dataFiles": []
}
```

- [ ] **Step 2: Write SKILL.md**

```markdown
---
name: pattern-extractor
description: Analyzes captured patterns from continuous learning to extract reusable workflows and anti-patterns. Use when you want to review what's been learned across sessions.
user_invocable: true
---

# /pattern-extractor — Learn from History

Analyzes the command patterns captured by the continuous-learning hook
and extracts actionable insights.

## What It Does

1. Reads pattern logs from `~/.claude/.patterns/`
2. Identifies recurring success/failure patterns
3. Extracts reusable workflows (commands that consistently succeed)
4. Flags anti-patterns (commands that consistently fail)
5. Generates a summary with recommendations

## Usage

```
/pattern-extractor              # Analyze all patterns
/pattern-extractor last-week    # Analyze last 7 days
/pattern-extractor project      # Analyze current project only
```

## Analysis Process

### Step 1: Load Pattern Data

Read all `.jsonl` files from `~/.claude/.patterns/`:

```bash
cat ~/.claude/.patterns/session-*.jsonl
```

### Step 2: Categorize Patterns

Group commands by:
- **Recovery patterns**: Command that succeeded after a similar command failed
- **Workflow patterns**: Sequences of commands that appear together
- **Failure patterns**: Commands that consistently fail in certain contexts
- **Tool preferences**: Which tools are used most for which tasks

### Step 3: Generate Insights

For each pattern category, produce:

```markdown
## Recovery Patterns
| Failed Command | Successful Recovery | Frequency |
|----------------|---------------------|-----------|
| npm run build  | npm ci && npm run build | 5 times |

## Workflow Patterns
| Workflow | Steps | Frequency |
|----------|-------|-----------|
| TDD cycle | test → edit → test | 23 times |

## Anti-Patterns (Avoid)
| Command | Failure Rate | Recommendation |
|---------|-------------|----------------|
| git push -f | 80% blocked | Use regular push |
```

### Step 4: Save Insights

Write analysis to `~/.claude/.patterns/insights-YYYY-MM-DD.md`.
If insights reveal a reusable pattern, suggest creating a skill for it.

## Output

Summary with:
- Top 5 recovery patterns
- Top 5 workflow patterns
- Top 5 anti-patterns
- Recommendation: patterns worth formalizing as skills
```

- [ ] **Step 3: Commit pattern extractor**

```bash
git add core/skills/pattern-extractor/
git commit -m "feat(skills): add pattern-extractor skill for learning analysis

Analyzes command patterns captured by continuous-learning hook.
Identifies recovery patterns, workflow patterns, and anti-patterns.
Part of the learning system inspired by ECC."
```

---

### Task 12: Create Instinct Capture Hook

**Files:**
- Create: `core/hooks/instinct-capture.sh`

- [ ] **Step 1: Write the instinct capture hook**

```bash
#!/usr/bin/env bash
# Hook: Instinct Capture (Stop)
# Extracts session learnings and stores them as instincts with confidence scores.
# Trigger: Stop (session end)
#
# An "instinct" is a learned behavior with a confidence score:
# - Low confidence (1-3): Observed once, needs validation
# - Medium confidence (4-7): Observed multiple times, likely useful
# - High confidence (8-10): Repeatedly validated, should be a rule
#
# Storage: ~/.claude/.instincts/

# No set -euo pipefail — hooks must be resilient on Windows

INSTINCTS_DIR="$HOME/.claude/.instincts"
mkdir -p "$INSTINCTS_DIR"

INSTINCTS_FILE="$INSTINCTS_DIR/instincts.jsonl"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if we have pattern data from this session
SESSION_LOG="$HOME/.claude/.patterns/session-$(date +%Y-%m-%d).jsonl"
[ ! -f "$SESSION_LOG" ] && exit 0

# Count unique recovery patterns (failed then succeeded)
RECOVERY_COUNT=$(node -e "
  const fs = require('fs');
  try {
    const lines = fs.readFileSync(process.argv[1], 'utf8').trim().split('\n');
    const entries = lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    let recoveries = 0;
    for (let i = 1; i < entries.length; i++) {
      if (entries[i].exit_code === 0 && entries[i-1].exit_code !== 0) {
        recoveries++;
      }
    }
    console.log(recoveries);
  } catch { console.log(0); }
" "$SESSION_LOG" 2>/dev/null || echo "0")

# Only capture if there were interesting patterns
[ "$RECOVERY_COUNT" -lt 1 ] && exit 0

# Create instinct entry
node -e "
  const entry = {
    timestamp: process.argv[1],
    type: 'recovery',
    count: parseInt(process.argv[2]),
    confidence: Math.min(10, parseInt(process.argv[2]) + 2),
    session_date: process.argv[3],
    project: process.cwd()
  };
  const fs = require('fs');
  fs.appendFileSync(process.argv[4], JSON.stringify(entry) + '\n');
" "$TIMESTAMP" "$RECOVERY_COUNT" "$(date +%Y-%m-%d)" "$INSTINCTS_FILE" 2>/dev/null

exit 0
```

- [ ] **Step 2: Commit instinct capture hook**

```bash
git add core/hooks/instinct-capture.sh
git commit -m "feat(hooks): add instinct capture hook for learning system

Captures session-level learnings as 'instincts' with confidence scores.
Analyzes recovery patterns from continuous-learning data and builds
a knowledge base over time. Inspired by ECC's instinct system."
```

---

## Phase 4: Enhanced Hooks

### Task 13: Create Cost Tracking Hook

**Files:**
- Create: `core/hooks/cost-tracker.sh`

- [ ] **Step 1: Write cost tracking hook**

```bash
#!/usr/bin/env bash
# Hook: Cost Tracker (Stop)
# Tracks session duration and tool usage for cost awareness.
# Trigger: Stop (session end, async)
#
# Logs session metrics to ~/.claude/.metrics/
# No blocking — runs async with 10s timeout

# No set -euo pipefail — hooks must be resilient on Windows

METRICS_DIR="$HOME/.claude/.metrics"
mkdir -p "$METRICS_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOGFILE="$METRICS_DIR/sessions-$(date +%Y-%m).jsonl"

# Count tool calls from today's pattern log
SESSION_LOG="$HOME/.claude/.patterns/session-$(date +%Y-%m-%d).jsonl"
TOOL_COUNT=0
if [ -f "$SESSION_LOG" ]; then
  TOOL_COUNT=$(wc -l < "$SESSION_LOG" 2>/dev/null || echo "0")
fi

# Log session end
node -e "
  const entry = {
    timestamp: process.argv[1],
    tool_calls: parseInt(process.argv[2]) || 0,
    project: process.cwd(),
    type: 'session_end'
  };
  const fs = require('fs');
  fs.appendFileSync(process.argv[3], JSON.stringify(entry) + '\n');
" "$TIMESTAMP" "$TOOL_COUNT" "$LOGFILE" 2>/dev/null

exit 0
```

- [ ] **Step 2: Commit cost tracker**

```bash
git add core/hooks/cost-tracker.sh
git commit -m "feat(hooks): add cost tracking hook for session metrics

Tracks session tool usage and duration to ~/.claude/.metrics/.
Runs async on session end. Inspired by ECC's cost tracking hooks."
```

---

### Task 14: Create Desktop Notification Hook

**Files:**
- Create: `core/hooks/desktop-notify.sh`

- [ ] **Step 1: Write desktop notification hook**

```bash
#!/usr/bin/env bash
# Hook: Desktop Notification (Stop)
# Sends a desktop notification when Claude Code completes a task.
# Trigger: Stop (async, 10s timeout)
#
# Supports: macOS (osascript), Linux (notify-send), Windows (PowerShell)

# No set -euo pipefail — hooks must be resilient on Windows

TITLE="Claude Code"
MSG="Task completed"

# Detect OS and send notification
case "$(uname -s)" in
  Darwin*)
    osascript -e "display notification \"$MSG\" with title \"$TITLE\"" 2>/dev/null
    ;;
  Linux*)
    if command -v notify-send &>/dev/null; then
      notify-send "$TITLE" "$MSG" 2>/dev/null
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    powershell.exe -Command "
      [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
      \$notify = New-Object System.Windows.Forms.NotifyIcon
      \$notify.Icon = [System.Drawing.SystemIcons]::Information
      \$notify.Visible = \$true
      \$notify.ShowBalloonTip(5000, '$TITLE', '$MSG', 'Info')
      Start-Sleep -Seconds 6
      \$notify.Dispose()
    " 2>/dev/null &
    ;;
esac

exit 0
```

- [ ] **Step 2: Commit desktop notify hook**

```bash
git add core/hooks/desktop-notify.sh
git commit -m "feat(hooks): add desktop notification hook

Sends OS-native notifications when Claude Code completes a task.
Supports macOS (osascript), Linux (notify-send), and Windows (PowerShell).
Inspired by ECC's desktop-notify hook."
```

---

### Task 15: Create Hook Profiles System

**Files:**
- Create: `core/hooks/hook-profiles.md`
- Modify: `core/lib/common.sh` — add profile detection function

- [ ] **Step 1: Write hook profiles documentation**

```markdown
# Hook Profiles

Control hook strictness via the `HANGAR_HOOK_PROFILE` environment variable.

## Available Profiles

| Profile | Behavior | Use When |
|---------|----------|----------|
| `minimal` | Safety hooks only (bash-guard, secret-leak-check) | Quick prototyping |
| `standard` | Safety + quality hooks (default) | Normal development |
| `strict` | All hooks active, blocking mode | Production/CI |

## Usage

```bash
# Set profile for current session
export HANGAR_HOOK_PROFILE=minimal

# Set profile permanently in shell profile
echo 'export HANGAR_HOOK_PROFILE=standard' >> ~/.bashrc
```

## Disabling Individual Hooks

```bash
# Comma-separated list of hooks to disable
export HANGAR_DISABLED_HOOKS=token-warning,desktop-notify
```

## Profile Mapping

### minimal
- bash-guard.sh ✓
- secret-leak-check.sh ✓
- Everything else: disabled

### standard (default)
- All safety hooks ✓
- checkpoint.sh ✓
- session-start.sh ✓
- session-stop.sh ✓
- skill-suggest.sh ✓
- token-warning.sh ✓
- Learning hooks: disabled
- Desktop notify: disabled

### strict
- Everything enabled ✓
- Blocking mode for quality gates ✓
- Cost tracking active ✓
- Learning system active ✓
```

- [ ] **Step 2: Add profile check function to common.sh**

Add to `core/lib/common.sh`:

```bash
# ─── Hook Profile Check ──────────────────────────────────────────────

# Check if current hook should run based on profile
# Usage: should_hook_run "hook-name" "minimal|standard|strict" || exit 0
should_hook_run() {
  local hook_name="$1"
  local min_profile="${2:-standard}"
  local current_profile="${HANGAR_HOOK_PROFILE:-standard}"

  # Check disabled hooks list
  if [ -n "${HANGAR_DISABLED_HOOKS:-}" ]; then
    echo "$HANGAR_DISABLED_HOOKS" | tr ',' '\n' | grep -qx "$hook_name" && return 1
  fi

  # Profile hierarchy: minimal < standard < strict
  case "$min_profile" in
    minimal) return 0 ;;  # Always runs
    standard)
      [ "$current_profile" = "minimal" ] && return 1
      return 0
      ;;
    strict)
      [ "$current_profile" = "strict" ] && return 0
      return 1
      ;;
  esac
}
```

- [ ] **Step 3: Commit hook profiles**

```bash
git add core/hooks/hook-profiles.md core/lib/common.sh
git commit -m "feat(hooks): add hook profile system (minimal/standard/strict)

Environment variable HANGAR_HOOK_PROFILE controls which hooks run.
HANGAR_DISABLED_HOOKS allows disabling individual hooks.
Inspired by ECC's ECC_HOOK_PROFILE system."
```

---

## Phase 5: Language Stacks

### Task 16: Create Language-Specific Rules

**Files:**
- Create: `rules/typescript/patterns.md`
- Create: `rules/typescript/testing.md`
- Create: `rules/python/patterns.md`
- Create: `rules/python/testing.md`
- Create: `rules/go/patterns.md`
- Create: `rules/go/testing.md`
- Create: `rules/rust/patterns.md`
- Create: `rules/java/patterns.md`

- [ ] **Step 1: Write TypeScript patterns rules**

```markdown
# TypeScript Patterns

## Framework-Agnostic Rules

### Strict TypeScript
- Enable `strict: true` in tsconfig.json — no exceptions
- No `any` type without explicit `// @ts-expect-error: [reason]`
- Use `unknown` for truly unknown types, then narrow with type guards
- Prefer `interface` for object shapes, `type` for unions/intersections

### Import Style
- Named imports over default imports (better tree-shaking)
- Group imports: external → internal → relative
- No circular dependencies — use dependency injection if needed

### Async Patterns
- Always use async/await over .then() chains
- Handle errors with try/catch at the boundary, not every call
- Use Promise.all() for independent async operations
- AbortController for cancellable operations

### State Management
- Immutable updates (spread, structuredClone for deep copies)
- Single source of truth — avoid derived state
- Minimize global state — prefer local state and props/parameters

## React-Specific (When Applicable)

- Server Components by default, Client Components only when needed
- Use `use` hook for data fetching in React 19+
- Prefer composition over inheritance
- No useEffect for derived state — use useMemo
```

- [ ] **Step 2: Write TypeScript testing rules**

```markdown
# TypeScript Testing

## Framework: Vitest (preferred) or Jest

### Unit Tests
- One test file per source file: `foo.ts` → `foo.test.ts`
- Co-locate tests with source (not in separate `__tests__/` directory)
- Use `describe` for grouping, `it` for individual tests

### Component Testing (React/Svelte/Vue)
- Testing Library for user-interaction tests
- Test behavior, not implementation
- Never test CSS classes or DOM structure directly
- Use `screen.getByRole()` over `getByTestId()`

### API Testing
- Supertest for HTTP endpoint tests
- Test success, validation errors, auth errors, and edge cases
- Mock external services, never mock your own code

### Coverage
- 80% minimum, 95%+ for auth/payment/data mutation paths
- Branch coverage, not just line coverage
```

- [ ] **Step 3: Write Python patterns rules**

```markdown
# Python Patterns

## Code Style

### Type Hints (Mandatory)
- All public functions must have type hints
- Use `from __future__ import annotations` for modern syntax
- Use `TypeAlias` for complex types
- Pydantic models for data validation at boundaries

### Project Structure
- `src/` layout for packages
- `pyproject.toml` over `setup.py` (PEP 621)
- Virtual environments mandatory (venv, poetry, or uv)
- Pin dependencies in lockfile

### Patterns
- Context managers for resource handling
- Dataclasses for simple data containers, Pydantic for validation
- Pathlib over os.path for file operations
- Comprehensions for simple transforms, regular loops for complex logic
- Generator expressions for large datasets

### Error Handling
- Specific exceptions only — never bare `except:`
- Custom exception hierarchy for domain errors
- Logging with structlog or stdlib logging (not print())
```

- [ ] **Step 4: Write Python testing rules**

```markdown
# Python Testing

## Framework: pytest (mandatory)

### Conventions
- Test files: `test_<module>.py`
- Test functions: `test_<behavior>()`
- Fixtures for setup/teardown
- Parametrize for table-driven tests

### Patterns
- `pytest.raises()` for exception testing
- `pytest.mark.parametrize` for data-driven tests
- `conftest.py` for shared fixtures (don't import from other test files)
- `pytest-cov` for coverage reporting

### Mocking
- `unittest.mock.patch` for external dependencies
- Never mock the code under test
- Prefer dependency injection over patching
- Use `responses` or `httpx_mock` for HTTP mocking

### Coverage
- 80% minimum: `pytest --cov=src --cov-fail-under=80`
- Integration tests for database operations (use test database)
```

- [ ] **Step 5: Write Go patterns rules**

```markdown
# Go Patterns

## Code Style

### Error Handling
- Check every error — no `_ = err`
- Wrap errors with context: `fmt.Errorf("doing X: %w", err)`
- Sentinel errors for expected conditions (`var ErrNotFound = errors.New(...)`)
- Custom error types for domain errors with additional context

### Naming
- Short names in small scopes (`i`, `r`, `ctx`)
- Descriptive names in larger scopes (`userRepository`, `processOrder`)
- Interfaces: verb-based (`Reader`, `Closer`, `Handler`)
- No stuttering: `user.User` bad, `user.Account` good

### Concurrency
- Don't start goroutines without a plan to stop them
- Use `errgroup` for parallel operations with error handling
- Prefer channels for communication, mutex for state protection
- Always use `context.Context` for cancellation

### Project Structure
- Follow standard Go project layout
- Internal packages for private code
- Cmd packages for entry points
- No init() functions — use explicit initialization
```

- [ ] **Step 6: Write Go testing rules**

```markdown
# Go Testing

## Conventions
- Test files: `foo_test.go` (same package)
- Test functions: `TestFoo(t *testing.T)`
- Table-driven tests for multiple scenarios
- Testify for assertions (optional but recommended)

## Patterns

### Table-Driven Tests
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {"positive", 1, 2, 3},
        {"zero", 0, 0, 0},
        {"negative", -1, 1, 0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
            }
        })
    }
}
```

### Test Helpers
- Use `t.Helper()` for test utility functions
- Use `t.Cleanup()` for teardown
- Use `testdata/` directory for test fixtures

### Race Detection
- Always run tests with `-race` flag in CI
- `go test -race -count=1 ./...`

### Coverage
- `go test -cover -coverprofile=coverage.out ./...`
- 80% minimum coverage
```

- [ ] **Step 7: Write Rust patterns rules**

```markdown
# Rust Patterns

## Code Style

### Ownership & Borrowing
- Prefer borrowing (`&T`) over cloning
- Use `Cow<'_, T>` when ownership is conditional
- Implement `Clone` only when genuinely needed
- Lifetime annotations: minimize, let the compiler infer where possible

### Error Handling
- Use `thiserror` for library errors, `anyhow` for applications
- `?` operator for error propagation
- No `unwrap()` in production code — use `expect("reason")` at minimum
- Custom error enums for domain errors

### Patterns
- Builder pattern for complex struct construction
- Type-state pattern for compile-time state machines
- Newtype pattern for type safety (`struct UserId(u64)`)
- Iterator adaptors over manual loops

### Performance
- Use `#[inline]` sparingly (compiler usually knows better)
- Profile with `cargo flamegraph` before optimizing
- Prefer stack allocation over heap when possible
- Use `SmallVec` for small, fixed-size collections
```

- [ ] **Step 8: Write Java patterns rules**

```markdown
# Java Patterns

## Code Style

### Modern Java (17+)
- Use records for data classes
- Pattern matching with `instanceof`
- Sealed classes for restricted hierarchies
- Text blocks for multi-line strings
- Switch expressions over switch statements

### Error Handling
- Checked exceptions for recoverable errors
- Unchecked exceptions for programming errors
- Never catch `Exception` or `Throwable` directly
- Always close resources with try-with-resources

### Patterns
- Dependency injection (constructor injection preferred)
- Repository pattern for data access
- Builder pattern for complex objects
- Strategy pattern over long if-else chains

### Testing
- JUnit 5 for unit tests
- Mockito for mocking
- AssertJ for fluent assertions
- Testcontainers for integration tests
- 80% minimum coverage
```

- [ ] **Step 9: Commit language-specific rules**

```bash
git add rules/typescript/ rules/python/ rules/go/ rules/rust/ rules/java/
git commit -m "feat(rules): add language-specific rules (TS, Python, Go, Rust, Java)

Each language gets patterns and testing rules with idiomatic conventions,
common anti-patterns, and testing frameworks. Inspired by ECC's
multi-language rules system."
```

---

### Task 17: Update skills_index.json and Documentation

**Files:**
- Modify: `skills_index.json`
- Modify: `README.md`

- [ ] **Step 1: Add learning category and pattern-extractor to skills_index.json**

Add `"learning": ["pattern-extractor"]` to the categories object.

Add to the skills array:
```json
{
  "id": "pattern-extractor",
  "path": "core/skills/pattern-extractor",
  "category": "learning",
  "risk": "safe",
  "description": "Analyzes captured patterns from continuous learning to extract reusable workflows and anti-patterns.",
  "triggers": ["patterns", "learn", "extract patterns", "what did I learn", "analyze patterns"]
}
```

Update `skillCount` to 23.

- [ ] **Step 2: Update README.md with full structure**

Update the Repository Structure table to include all new directories:

```markdown
| Directory | Purpose |
|-----------|---------|
| `core/` | Global config deployed to ~/.claude/ (hooks, agents, skills, lib, contexts, statusline) |
| `rules/` | Always-on governance rules (common + language-specific) |
| `stacks/` | Framework-specific extensions (Astro, SvelteKit, Next.js, Database, Auth) |
| `templates/` | CI/CD workflows and project CLAUDE.md templates |
| `registry/` | Multi-project management schema and examples |
| `tests/` | Hook tests, setup tests, template tests |
| `docs/` | Documentation, concepts, tutorials |
| `i18n/` | Internationalization (currently: German) |
```

Add a new "What's Inside" section or update the existing features list:

```markdown
## What's Inside

| Component | Count | Highlights |
|-----------|-------|------------|
| **Agents** | 17 | Planner, Architect, Loop-Operator, Language Reviewers (TS/Python/Go), Build Resolvers, Security, Explorer |
| **Skills** | 23 | Audit, Design, Scan, Pattern Extractor, Handoff, Error Analyzer |
| **Hooks** | 21 | Bash Guard, Secret Leak Check, Continuous Learning, Instinct Capture, Cost Tracker, Desktop Notify |
| **Rules** | 15 | Coding Style, Security, Testing, Git Workflow, Governance + 5 Languages |
| **Contexts** | 3 | Dev, Research, Review modes |
| **Stacks** | 8 | Astro, SvelteKit, Next.js, Auth, Database, Docker, GitHub, Security |
```

- [ ] **Step 3: Commit documentation updates**

```bash
git add skills_index.json README.md
git commit -m "docs: update skills index and README with all new components

Updated skill count (23), added learning category, and updated
README with full component inventory including agents (17),
hooks (21), rules (15), and contexts (3)."
```

---

### Task 18: Update setup.sh for New Components

**Files:**
- Modify: `setup.sh`

- [ ] **Step 1: Add new hooks to deployment**

Ensure the hooks deployment section copies all new hook files:
- `continuous-learning.sh`
- `instinct-capture.sh`
- `cost-tracker.sh`
- `desktop-notify.sh`

These should already be covered if the existing hook deployment copies all `.sh` files from `core/hooks/`. Verify this is the case.

- [ ] **Step 2: Add learning directories to deployment**

Add creation of learning system directories:

```bash
# ─── Initialize Learning System ───────────────────────────────────────

init_learning_system() {
  info "Initializing learning system..."
  mkdir -p "$CLAUDE_DIR/.patterns"
  mkdir -p "$CLAUDE_DIR/.instincts"
  mkdir -p "$CLAUDE_DIR/.metrics"
  success "Learning system directories initialized"
}
```

Wire into main flow after `deploy_contexts`.

- [ ] **Step 3: Add --list-components flag**

Add a new flag to show all installed components:

```bash
list_components() {
  echo ""
  echo "Claude Hangar — Installed Components"
  echo "======================================"
  echo ""

  echo "Agents:"
  ls -1 "$CLAUDE_DIR/agents/"*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  - /'
  echo ""

  echo "Hooks:"
  ls -1 "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null | xargs -I{} basename {} .sh | sed 's/^/  - /'
  echo ""

  echo "Skills:"
  ls -1d "$CLAUDE_DIR/skills/"*/ 2>/dev/null | xargs -I{} basename {} | grep -v '^_' | sed 's/^/  - /'
  echo ""

  echo "Rules:"
  find "$CLAUDE_DIR/rules/" -name '*.md' ! -name 'README.md' 2>/dev/null | sed "s|$CLAUDE_DIR/rules/||" | sed 's/^/  - /'
  echo ""

  echo "Contexts:"
  ls -1 "$CLAUDE_DIR/contexts/"*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  - /'
}
```

- [ ] **Step 4: Commit setup.sh updates**

```bash
git add setup.sh
git commit -m "feat(setup): add learning system init and component listing

setup.sh now creates learning system directories (.patterns, .instincts,
.metrics) and supports --list-components flag to show all installed
components."
```

---

### Task 19: Final Integration Test

**Files:**
- Modify: `tests/test-hooks.sh` (add new hook tests)
- Modify: `tests/test-setup.sh` (verify new directories)

- [ ] **Step 1: Add hook tests for new hooks**

Add test cases to `tests/test-hooks.sh`:

```bash
# --- Test: continuous-learning.sh ---
test_continuous_learning() {
  local hook="$HOOKS_DIR/continuous-learning.sh"
  [ ! -f "$hook" ] && { warn "continuous-learning.sh not found"; return 1; }

  # Test with Bash tool input
  echo '{"tool_name":"Bash","tool_input":{"command":"npm test"},"tool_result":{"exit_code":0}}' | \
    bash "$hook"
  local exit_code=$?
  [ $exit_code -eq 0 ] && success "continuous-learning: accepts Bash tool" || error "continuous-learning: failed"
}

# --- Test: cost-tracker.sh ---
test_cost_tracker() {
  local hook="$HOOKS_DIR/cost-tracker.sh"
  [ ! -f "$hook" ] && { warn "cost-tracker.sh not found"; return 1; }

  bash "$hook" < /dev/null
  local exit_code=$?
  [ $exit_code -eq 0 ] && success "cost-tracker: runs without error" || error "cost-tracker: failed"
}

# --- Test: desktop-notify.sh ---
test_desktop_notify() {
  local hook="$HOOKS_DIR/desktop-notify.sh"
  [ ! -f "$hook" ] && { warn "desktop-notify.sh not found"; return 1; }

  # Should not error even without notification system
  bash "$hook" < /dev/null
  local exit_code=$?
  [ $exit_code -eq 0 ] && success "desktop-notify: runs without error" || error "desktop-notify: failed"
}
```

- [ ] **Step 2: Add structure tests for new directories**

Add to `tests/test-setup.sh`:

```bash
# Test: rules directory exists and has content
test_rules_structure() {
  [ -d "$SCRIPT_DIR/rules/common" ] || { error "rules/common/ missing"; return 1; }
  [ -f "$SCRIPT_DIR/rules/common/security.md" ] || { error "rules/common/security.md missing"; return 1; }
  [ -f "$SCRIPT_DIR/rules/common/governance.md" ] || { error "rules/common/governance.md missing"; return 1; }
  success "Rules directory structure valid"
}

# Test: contexts directory exists and has content
test_contexts_structure() {
  [ -d "$SCRIPT_DIR/core/contexts" ] || { error "core/contexts/ missing"; return 1; }
  [ -f "$SCRIPT_DIR/core/contexts/dev.md" ] || { error "core/contexts/dev.md missing"; return 1; }
  [ -f "$SCRIPT_DIR/core/contexts/research.md" ] || { error "core/contexts/research.md missing"; return 1; }
  [ -f "$SCRIPT_DIR/core/contexts/review.md" ] || { error "core/contexts/review.md missing"; return 1; }
  success "Contexts directory structure valid"
}

# Test: new agents exist
test_new_agents() {
  for agent in planner architect loop-operator typescript-reviewer python-reviewer go-reviewer; do
    [ -f "$SCRIPT_DIR/core/agents/$agent.md" ] || { error "Agent $agent.md missing"; return 1; }
  done
  success "All new agents present"
}
```

- [ ] **Step 3: Commit test updates**

```bash
git add tests/
git commit -m "test: add tests for new hooks, rules, contexts, and agents

Verify continuous-learning, cost-tracker, and desktop-notify hooks.
Validate rules directory structure, context modes, and new agents."
```

---

### Task 20: Final Commit — Update CHANGELOG.md

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Add changelog entry**

Add at the top of CHANGELOG.md:

```markdown
## [Unreleased] — 2026-04-05

### Added — ECC Integration (Major Enhancement)

#### Rules System (7 common rules + 5 language-specific rule sets)
- `rules/common/` — coding-style, security, testing, git-workflow, agents, performance, governance
- `rules/typescript/` — patterns and testing rules
- `rules/python/` — patterns and testing rules
- `rules/go/` — patterns and testing rules
- `rules/rust/` — patterns rules
- `rules/java/` — patterns rules

#### Context Modes (3 modes)
- `core/contexts/dev.md` — active development focus
- `core/contexts/research.md` — exploration and understanding
- `core/contexts/review.md` — PR review and code analysis

#### New Agents (9 agents)
- **planner** — Expert planning for complex features (Opus)
- **architect** — System design and architecture decisions (Opus)
- **loop-operator** — Autonomous workflow management with safety guardrails (Sonnet)
- **typescript-reviewer** — TypeScript-specific code review (Sonnet)
- **python-reviewer** — Python-specific code review (Sonnet)
- **go-reviewer** — Go-specific code review (Sonnet)
- **build-resolver-typescript** — TypeScript build error resolution (Sonnet)
- **build-resolver-python** — Python build error resolution (Sonnet)
- **build-resolver-go** — Go build error resolution (Sonnet)

#### Learning System
- **continuous-learning hook** — Captures command patterns and outcomes
- **instinct-capture hook** — Extracts session learnings with confidence scores
- **pattern-extractor skill** — Analyzes patterns to extract reusable workflows

#### Enhanced Hooks
- **cost-tracker** — Session metrics and tool usage tracking
- **desktop-notify** — OS-native notifications (macOS, Linux, Windows)
- **hook-profiles** — Environment-based hook strictness (minimal/standard/strict)

#### Setup Improvements
- Rules and contexts deployment in setup.sh
- Learning system directory initialization
- `--list-components` flag for component inventory

### Inspired By
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) — rules system, language agents, learning mechanisms, context modes, hook profiles
```

- [ ] **Step 2: Commit changelog**

```bash
git add CHANGELOG.md
git commit -m "docs: update CHANGELOG with ECC integration enhancements"
```

---

## Summary

### What This Plan Delivers

| Before | After |
|--------|-------|
| 8 agents | **17 agents** (+9: planner, architect, loop-operator, 3 reviewers, 3 build resolvers) |
| 22 skills | **23 skills** (+1: pattern-extractor) |
| 18 hooks | **22 hooks** (+4: continuous-learning, instinct-capture, cost-tracker, desktop-notify) |
| 0 rules | **15 rule files** (7 common + 8 language-specific) |
| 0 context modes | **3 context modes** (dev, research, review) |
| No learning system | **Full learning pipeline** (capture → extract → analyze) |
| No hook profiles | **3 profiles** (minimal/standard/strict) |

### What We Explicitly Did NOT Copy

- **Multi-harness support** — Hangar stays Claude Code focused (opinionated choice)
- **72 legacy command shims** — We use skills, not commands
- **ECC's plugin marketplace** — Not relevant to our distribution model
- **Chief-of-Staff agent** — Too specialized (email/Slack triage)
- **Domain-specific agents** (Healthcare, GAN, Flutter) — Not aligned with Hangar's focus
- **Bloated skill count** — Quality over quantity; 23 curated skills > 156 mixed quality

### Execution Estimate

- **Phase 1** (Rules + Contexts): ~20 files, foundational
- **Phase 2** (Agents): ~9 files, independent of Phase 1
- **Phase 3** (Learning): ~4 files, depends on hooks infrastructure
- **Phase 4** (Enhanced Hooks): ~4 files, independent
- **Phase 5** (Language Rules + Docs): ~12 files, depends on Phase 1

**Phases 1, 2, and 4 can run in parallel.** Phase 3 depends on existing hook infrastructure. Phase 5 depends on Phase 1's rules directory.
