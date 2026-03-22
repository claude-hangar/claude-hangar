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

**What it adds:** 14 deep workflow skills — brainstorming, subagent-driven development, TDD, systematic debugging, planning, and code review.

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

**What it adds:** Comprehensive reference system with instincts, memory patterns, security guidelines, and curated best practices. The most popular community contribution (97K+ stars).

**Why alongside Hangar:** Good reference material for understanding Claude Code capabilities. Use it as a learning resource alongside Hangar's operational infrastructure.

**Link:** [https://github.com/affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)

---

## What NOT to Combine

**GSD (gsd-build/gsd-2)**
GSD replaces Claude Code entirely with its own CLI. Hangar's hooks won't fire inside GSD. Use one or the other, not both.

**Competing config managers**
Don't install multiple `settings.json` managers. Hangar is your config manager — let it own that layer.
