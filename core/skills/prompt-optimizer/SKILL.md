---
name: prompt-optimizer
description: Analyzes draft prompts, identifies gaps, matches available skills/agents, and recommends optimal workflows. Advisory only — never executes, only optimizes. Use when unsure which skills or approach to use for a task.
user_invocable: true
---

# /prompt-optimizer — Prompt Analysis Pipeline

Six-phase advisory skill that takes a user's draft prompt or task description
and produces an optimized version with the right skills, agents, and workflow.

**Advisory only** — this skill never executes the task. It produces an optimized
prompt the user can then run.

## Usage

```
/prompt-optimizer "Add authentication to my SvelteKit app"
/prompt-optimizer                # Analyze the last user message
/prompt-optimizer --quick        # Short version for experienced users
```

## The Six Phases

### Phase 1: Detect Project Context

Gather project metadata without reading the full codebase:

```bash
# Quick project detection
cat CLAUDE.md 2>/dev/null | head -30
cat package.json 2>/dev/null | node -e "const p=require('/dev/stdin'); console.log(p.name, Object.keys(p.dependencies||{}).slice(0,10))"
ls -d src/ app/ lib/ pages/ routes/ components/ 2>/dev/null
git remote -v 2>/dev/null | head -1
```

**Output:** Tech stack, framework, project type, repo context.

### Phase 2: Detect User Intent

Parse the prompt to identify:

- **Primary goal**: What does the user want to achieve?
- **Implicit requirements**: What's assumed but not stated?
- **Scope boundaries**: What should NOT change?
- **Success criteria**: How will we know it's done?

### Phase 3: Assess Scope

Classify the task:

| Size | Criteria | Recommended Approach |
|------|----------|---------------------|
| **Small** | Single file, < 30 min | Direct implementation |
| **Medium** | 2-5 files, clear scope | Plan then implement |
| **Large** | 6+ files, architectural | Full planning phase with planner agent |
| **Ambiguous** | Unclear scope or requirements | Brainstorming first |

### Phase 4: Match Hangar Components

Scan available skills and agents for the best match:

```bash
# List available skills and their descriptions
for skill in core/skills/*/SKILL.md; do
  head -5 "$skill" | grep "description:"
done

# List available agents
for agent in core/agents/*.md; do
  head -5 "$agent" | grep "description:"
done
```

**Match criteria:**
- Skill trigger keywords vs. task keywords
- Agent capabilities vs. task requirements
- Stack-specific skills if applicable
- Context modes (dev/research/review) if applicable

### Phase 5: Identify Missing Context

What information would improve the prompt?

| Gap Type | Example | Question to Ask |
|----------|---------|-----------------|
| **Requirements** | No success criteria specified | "What should happen when auth fails?" |
| **Constraints** | No performance budget | "Any latency requirements?" |
| **Existing code** | Unknown current state | "Is there existing auth code to build on?" |
| **Dependencies** | Unclear external services | "Which auth provider (or custom)?" |

### Phase 6: Generate Optimized Prompt

Produce two versions:

#### Full Version (Copy-Paste Ready)

Includes all context, constraints, skill references, and step-by-step approach.
Ready to paste as a new prompt.

#### Quick Version (Experienced Users)

Key instructions only, assumes familiarity with Hangar tools.

## Output Format

```markdown
## Prompt Optimization Report

### Project Context
- **Framework:** SvelteKit 2 + Svelte 5
- **Stack:** Drizzle ORM + PostgreSQL
- **Context mode:** dev

### Intent Analysis
- **Goal:** Add user authentication
- **Implicit:** Session management, login/signup pages, protected routes
- **Scope:** Auth module only, don't touch existing routes
- **Success:** Users can register, login, access protected content

### Scope: LARGE (6+ files, architectural change)
**Recommended:** Use planner agent first, then TDD with tdd-guide

### Matched Components
| Component | Type | Relevance |
|-----------|------|-----------|
| Auth stack | Stack | High — has auth patterns for bcryptjs + sessions |
| security-scan | Skill | Medium — run after implementation |
| verification-loop | Skill | High — run before PR |
| tdd-guide | Agent | High — TDD for auth is critical |
| security-reviewer | Agent | High — auth needs security review |

### Missing Context (ask these first)
1. Custom auth or external provider (OAuth, Auth.js)?
2. Email verification required?
3. Role-based access control needed?

### Optimized Prompt (Full)

> I need to add custom authentication (bcryptjs + sessions) to my SvelteKit app.
>
> **Requirements:**
> - User registration with email + password
> - Login/logout with secure session cookies
> - Protected routes via server-side hooks
> - Password hashing with bcryptjs (12 rounds)
>
> **Approach:**
> 1. Use the Auth stack patterns from Hangar
> 2. Start with planner agent for implementation plan
> 3. Follow TDD (tdd-guide) for all auth logic
> 4. Run security-reviewer when done
> 5. Run /verify before PR
>
> **Constraints:**
> - No external auth providers
> - DSGVO-compliant (no tracking cookies)
> - Existing routes must not break

### Optimized Prompt (Quick)

> Add custom auth (bcryptjs + sessions) to SvelteKit.
> Use Auth stack patterns. TDD with tdd-guide. Security review after.
```

## When to Use

- **Unclear tasks** — When you don't know which skills to use
- **Large tasks** — When the approach matters as much as the implementation
- **New to Hangar** — When learning which tools are available
- **Complex prompts** — When the task has many implicit requirements

## What This Skill is NOT

- Not a prompt rewriter for AI conversations in general
- Not a prompt injection defense tool
- Not an auto-executor — it ONLY advises

Inspired by ECC's prompt-optimizer with Hangar's component-matching approach.
