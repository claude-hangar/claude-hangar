---
name: codebase-map
description: >
  Generate a structural overview of the codebase for context recovery.
  Use when: "map", "codebase map", "overview", "orient", "what is this project", or after /compact.
user_invocable: true
argument_hint: ""
---

<!-- AI-QUICK-REF
## /codebase-map — Quick Reference
- **Modes:** generate | refresh
- **Output:** Compact structural overview in stdout (not a file)
- **Use case:** Context recovery after /compact, new session orientation, handoff prep
- **Inspired by:** GSD v2 "codebase map — structural orientation for fresh agent contexts"
-->

# /codebase-map — Structural Codebase Overview

Generates a compact, navigable overview of the codebase for context recovery. Designed to be injected into context after `/compact` or at session start.

**Inspired by:** GSD v2 "codebase map — structural orientation for fresh agent contexts"

## When to Use

- After `/compact` wipes detailed file knowledge
- At the start of a new session in an unfamiliar project
- When preparing a handoff to another agent or session
- When a subagent needs project orientation

## What the Map Contains

### 1. Project Identity
```
Project: {name} ({framework})
Root: {path}
Stack: {detected technologies}
```

### 2. Directory Structure (depth 2, annotated)
```
src/
  components/  — 12 Svelte components (Button, Card, Header, ...)
  lib/
    server/    — DB client, auth helpers, email service
    utils/     — formatDate, slugify, validateEmail
  routes/      — 8 pages (/, /about, /contact, /blog, /blog/[slug], ...)
static/        — fonts, favicon, robots.txt
tests/         — 3 test files (unit, integration, e2e setup)
```

### 3. Entry Points
```
Entry points:
  Web:    src/routes/+layout.svelte → src/routes/+page.svelte
  API:    src/routes/api/*/+server.ts (3 endpoints)
  DB:     src/lib/server/db/schema.ts (5 tables)
  Config: svelte.config.js, vite.config.ts, drizzle.config.ts
```

### 4. Key Files (by importance)
```
Key files:
  src/lib/server/db/schema.ts    — Database schema (users, posts, sessions, ...)
  src/hooks.server.ts            — Auth guard, locale detection
  src/routes/+layout.server.ts   — Session loading, global data
  src/lib/server/auth.ts         — Login, register, session management
```

### 5. Recent Activity
```
Recent (last 5 commits):
  fix: session cookie path       — 2h ago (hooks.server.ts, auth.ts)
  feat: blog pagination          — 5h ago (blog/+page.server.ts, +page.svelte)
  ...
```

## Generation Process

1. **Detect project type:** Read `package.json`, config files, framework markers
2. **Scan directory tree:** `find . -type f` with smart depth limits (2 for dirs, show file counts)
3. **Identify entry points:** Framework-specific detection (routes, API, DB schema, config)
4. **Rank files by importance:** Git activity (most changed) + size + import count
5. **Recent activity:** `git log --oneline -5` with changed files
6. **Format output:** Compact, scannable, no prose — designed for context injection

## Modes

### `/codebase-map generate`
Full generation. Scans the project and outputs the map.

### `/codebase-map refresh`
Lightweight refresh — only updates "Recent Activity" and file counts. Reuses the structural data.

## Rules

- **Output to stdout** (not a file) — designed for context injection, not persistence
- **Compact:** The entire map must fit in ~2000 tokens. No verbose descriptions.
- **No opinions:** Just facts. No recommendations or analysis.
- **Framework-aware:** Knows where to look for Astro, SvelteKit, Next.js, Express, etc.
