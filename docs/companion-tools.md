# Companion Tools

Claude Hangar provides the infrastructure layer: hooks, agents, skills, and config management. These four companion tools extend it with capabilities Hangar doesn't cover.

## The Stack

```
┌──────────────────────────────────────────────────────┐
│           claude-squad (Multi-Session)                │
│     Manages multiple Claude Code instances            │
├──────────────────────────────────────────────────────┤
│                    Claude Code                        │
│  ┌─────────────┐ ┌──────────────┐ ┌───────────────┐ │
│  │   Hangar     │ │ Superpowers  │ │ Trail of Bits │ │
│  │ Safety &     │ │ Workflow     │ │ Security      │ │
│  │ Config       │ │ Methodology  │ │ Skills        │ │
│  └─────────────┘ └──────────────┘ └───────────────┘ │
├──────────────────────────────────────────────────────┤
│           ccusage (Historical Analytics)              │
│     Token costs, session history, dashboards          │
└──────────────────────────────────────────────────────┘
```

## Installation Order

Install in this order to avoid conflicts:

1. **Claude Hangar** — base layer (hooks, agents, skills, config)
2. **Superpowers** — workflow skills (complementary, no overlap)
3. **Trail of Bits Skills** — security skills (complementary)
4. **ccusage** — standalone CLI (no conflicts)
5. **claude-squad** — standalone terminal app (no conflicts)

---

## 1. Superpowers (obra/superpowers)

**What it adds:** 14 deep workflow skills — brainstorming, subagent-driven development, TDD, systematic debugging, planning, and code review. (136K+ stars)

**Why alongside Hangar:** Hangar protects and organizes. Superpowers guides the development methodology. Zero overlap — Hangar has operational skills (`/scan`, `/audit`, `/deploy-check`), Superpowers has workflow skills (`/brainstorm`, `/write-plan`, `/tdd`).

**Install:**

```bash
claude install obra/superpowers
```

**Compatibility:** Superpowers adds one `SessionStart` hook. Hangar also has a `SessionStart` hook. Both fire independently — no conflict. Skills live in separate directories.

**Key skills to try:**

| From Superpowers | From Hangar |
|---|---|
| `/brainstorm` | `/scan` |
| `/write-plan` | `/audit` |
| `/tdd` | `/deploy-check` |

---

## 2. Trail of Bits Skills (trailofbits/skills)

**What it adds:** 12+ professional security skills from one of the world's leading security firms. CodeQL integration, Semgrep, variant analysis, fix verification, and differential code review.

**Why alongside Hangar:** Hangar's `security-reviewer` agent does OWASP Top 10 quick checks. Trail of Bits goes deeper with static analysis tools. Use Hangar for quick scans, Trail of Bits for deep audits.

**Install:**

```bash
claude install trailofbits/skills
```

**Compatibility:** No conflicts. Trail of Bits skills are in their own namespace.

**Workflow example:**

```
1. Run Hangar's /adversarial-review code    → fast OWASP check
2. Run Trail of Bits static analysis        → deep CodeQL/Semgrep audit
```

---

## 3. ccusage (ryoppippi/ccusage)

**What it adds:** CLI tool that analyzes Claude Code's JSONL session logs. Shows token consumption, costs per session, model usage, and historical trends.

**Why alongside Hangar:** Hangar's statusline shows live data during a session. ccusage shows historical data across ALL sessions. Together: real-time monitoring + post-hoc analysis.

**Install:**

```bash
npm install -g ccusage
```

**Compatibility:** 100% independent. ccusage reads log files that Claude Code writes anyway. No interaction with Hangar.

**Usage:**

```bash
# Summary of all sessions
ccusage

# Per-session breakdown
ccusage --detail
```

Run `ccusage` after a work session to see costs and token usage.

---

## 4. claude-squad (smtg-ai/claude-squad)

**What it adds:** Terminal app that manages multiple Claude Code instances simultaneously. Start, stop, and switch between instances in separate workspaces. tmux-based.

**Why alongside Hangar:** Hangar's multi-project registry defines WHICH config each project gets. claude-squad runs them IN PARALLEL. Define projects in `registry.json`, execute them simultaneously with claude-squad.

**Install:**

See [https://github.com/smtg-ai/claude-squad](https://github.com/smtg-ai/claude-squad) for platform-specific installation instructions.

**Compatibility:** Each claude-squad instance runs a full Claude Code process with all Hangar hooks, agents, and skills active.

**Usage:**

```bash
# Start claude-squad
claude-squad

# Create instances for different projects
# Each instance inherits the full Hangar setup from ~/.claude/
```

---

## Troubleshooting

**Superpowers skills don't show up**
Restart Claude Code after installing the plugin. Skills are loaded at session start.

**Too many SessionStart hooks**
Both Hangar and Superpowers register `SessionStart` hooks. This is normal — Claude Code runs all registered hooks. They do not interfere with each other.

**ccusage shows no data**
ccusage reads from `~/.claude/projects/*/sessions/`. You need at least one completed Claude Code session for data to appear.

---

## 5. claude-mem (thedotmack/claude-mem)

**What it adds:** Persistent memory system as a plugin. Automatic session captures, AI-powered compression, semantic search via SQLite + Chroma vector DB.

**Why alongside Hangar:** Hangar's `session-start` hook loads STATUS.md and tasks. claude-mem adds deep cross-session memory with AI compression and semantic retrieval. Together: Hangar manages project state, claude-mem manages knowledge.

**Install:**

```bash
claude install thedotmack/claude-mem
```

**Compatibility:** No conflicts. claude-mem operates as an independent MCP server.

---

## 6. Everything Claude Code (affaan-m/everything-claude-code)

**What it adds:** Comprehensive reference system with instincts, memory patterns, security guidelines, and curated best practices. The most popular community contribution (140K+ stars).

**Why alongside Hangar:** Good reference material for understanding Claude Code capabilities. Use it as a learning resource alongside Hangar's operational infrastructure.

**Link:** [https://github.com/affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)

---

## 7. GSD v1 — Get Shit Done (gsd-build/get-shit-done)

**What it adds:** Meta-prompting and spec-driven development system. v1.34+ provides 60+ slash commands (`/gsd:*`), 19+ agents, planning workflows, context monitoring, and a TypeScript SDK. Supports 12+ runtimes (Claude Code, Codex, Gemini, Copilot, OpenCode, Windsurf, Cursor, Trae, Kilo, Augment, Cline, Antigravity).

**Why alongside Hangar:** GSD v1 provides structured project planning (requirements, roadmap, phases, workstreams) that Hangar doesn't cover. Hangar provides safety hooks and operational skills that GSD doesn't.

**Key features (v1.28+):**

| Feature | Since | What it does |
|---------|-------|--------------|
| Workstreams | v1.28 | Parallel milestone work via `/gsd:workstreams` |
| Advisor Mode | v1.27 | Research-backed discussion with parallel evaluating agents |
| GSD SDK | v1.30 | TypeScript headless SDK (`gsd-sdk init`, `gsd-sdk auto`) |
| Skills Migration | v1.31 | Commands install as `skills/gsd-*/SKILL.md` files |
| STATE.md Gates | v1.32 | Consistency validation (`state validate`, `state sync`) |
| Autonomous Mode | v1.32 | `--to N`, `--interactive`, `--power` flags |
| Global Learnings | v1.34 | Persistent CRUD store with cross-session reuse |
| Codebase Intel | v1.34 | Queryable `.planning/intel/` JSON store |
| Execution Profiles | v1.34 | dev/research/review context modes |

**Install (local only — avoids global conflicts):**

```bash
cd your-project
npx get-shit-done-cc --claude --local
```

**Compatibility:** GSD v1 installed locally (`.claude/`) does not conflict with Hangar's global `~/.claude/` config. All GSD files use `gsd-` prefix. **Do NOT install globally** — this would conflict with Hangar's statusline and hooks. Requires Node.js >= 22.

**Conflict zones (global install only):**

| Area | Risk | Detail |
|------|------|--------|
| statusLine | HIGH | Only one active — GSD would replace Hangar's |
| settings.json hooks | MEDIUM | Both register SessionStart, PostToolUse, PreToolUse |
| package.json | MEDIUM | GSD writes `{"type":"commonjs"}` |

**Recommendation:** Always use `--local` when combining with Hangar.

---

## What NOT to Combine

**GSD v2 (gsd-build/gsd-2)**
GSD v2 is a standalone CLI agent built on the Pi SDK — it replaces Claude Code entirely. Hangar's hooks won't fire inside GSD v2. Use one or the other, not both. (GSD v1 as a local plugin is fine — see above.)

**Competing config managers**
Don't install multiple `settings.json` managers. Hangar is your config manager — let it own that layer.
