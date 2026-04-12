# Tutorial: GSD Orchestrator — Autonomous Project Optimization

This tutorial shows how to use `/gsd-orchestrate` to drive GSD v1 through its full lifecycle automatically — from codebase scan to verified, committed code — including overnight batch runs across multiple projects.

## Prerequisites

- Claude Hangar deployed
- GSD v1 installed globally:
  ```bash
  npx get-shit-done-cc --claude --global
  ```
- At least one Git-tracked project
- Clean git working tree in the target project

## The Three Modes

| Mode | Default | Asks user when... | Best for |
|---|---|---|---|
| **checkpoint** | ✓ | Architecture or irreversible choice | Production code |
| **full-auto** | | Never (except hard-rule gates) | Overnight batch, prototypes |
| **assisted** | | Every GSD phase question | Learning, critical code |

All modes use Opus for every GSD subagent call. Full-auto is just as smart as checkpoint — it uses the same evidence-first reasoning protocol, it only skips user prompts for low-risk decisions.

---

## Scenario 1 — Checkpoint Mode (Default)

Say you want to add rate limiting to an API service.

```bash
cd ~/projects/api-service
claude
```

In Claude Code:

```
/gsd-orchestrate "Add rate limiting to public API endpoints"
```

What happens:

1. **Preflight** — Skill verifies GSD is installed, git tree is clean, goal is non-empty.
2. **Scan** — Runs `/gsd-map-codebase`. Produces `.planning/codebase/{stack,architecture,conventions,concerns}.md`.
3. **Milestone** — Runs `/gsd-new-milestone "Add rate limiting to public API endpoints"`. Creates `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`.
4. **Phase loop** — For each phase in the roadmap:
   - `/gsd-discuss-phase` runs, but the orchestrator intercepts each question.
   - For each question, the orchestrator loads evidence (CLAUDE.md, existing middleware code, package.json) and delegates to an Opus subagent.
   - The Opus subagent returns an answer + citations, or `INSUFFICIENT_EVIDENCE`.
   - If citations → auto-submit. If gap → **checkpoint triggers**: you get an `AskUserQuestion` with the question + evidence + recommendation.
5. **Plan** — Runs `/gsd-plan-phase`. Orchestrator reviews the plan via `gsd-plan-checker` agent.
6. **Architecture checkpoint** — If the plan touches > 10 files OR modifies auth/DB/API contract, orchestrator pauses and shows the plan summary for your approval.
7. **Execute** — Runs `/gsd-execute-phase` with wave-based parallelization.
8. **Verify** — Runs `/gsd-verify-work`.
9. **Report** — Writes `.planning/orchestrator/run-<timestamp>.md`.

Typical checkpoint prompts you might see:

- "Rate limiter: use `express-rate-limit` (existing `express` found in package.json:24) or Redis-backed `rate-limiter-flexible`? Recommendation: express-rate-limit (single-instance deploy detected in docker-compose.yml)."
- "Plan modifies 14 files including auth middleware. Review plan before execute?"

---

## Scenario 2 — Full-Auto Mode (Overnight Single Project)

You want to optimize performance and security on a well-understood project while you sleep. No prompts — just start and review in the morning.

```bash
cd ~/projects/marketing-site
claude
```

In Claude Code:

```
/gsd-orchestrate "Optimize Core Web Vitals and harden security headers" --mode=full-auto
```

**What makes full-auto smart (not generic):**

1. **Same evidence protocol** — Every GSD question still triggers: load CLAUDE.md, STATUS.md, stack files, relevant code, git history.
2. **Always Opus** — No Sonnet shortcuts. Every reasoning step runs on Opus.
3. **Citation required** — An answer without a source file citation is rejected and retried.
4. **Hard-rule gates still fire** — Even in full-auto, these ALWAYS ask you:
   - Database schema migrations
   - Auth/authentication changes
   - Breaking API changes
   - Major-version dependency bumps
   - Secrets/config changes
5. **Safe-fallback policy** — When evidence is thin, the skill picks the reversible option and flags it in the report.

Example decision log entry (`.planning/orchestrator/decisions.md`):

```markdown
## Phase 4 — Image optimization strategy

**Question:** Which image format pipeline — `sharp` at build time, `@astrojs/image`, or a CDN service?

**Answer:** @astrojs/image

**Reasoning:**
- Project uses Astro (package.json:18, astro@5.x)
- @astrojs/image is the official integration, no extra deps
- Build-time fits `output: "static"` mode (astro.config.mjs:4)
- No CDN currently wired (no Cloudflare/Imgix env vars in .env.example)

**Citations:** package.json:18, astro.config.mjs:4, .env.example

**Confidence:** High

**Auto-decided:** Yes (full-auto mode)
```

---

## Scenario 3 — Overnight Batch Across Multiple Projects

The killer feature. Create a list of projects, start before bed, review reports in the morning.

### Step 1: Create the batch file

`~/projects-batch.txt`:

```
D:/backupblu/github/marketing-site
D:/backupblu/github/admin-panel
D:/backupblu/github/api-service
D:/backupblu/github/docs-site
```

One project path per line. Lines starting with `#` are ignored.

### Step 2: Ensure all projects have clean git trees

```bash
for p in $(cat ~/projects-batch.txt); do
  cd "$p" && git status --short && echo "---"
done
```

Any project with uncommitted changes will be **skipped** (not aborted) in batch mode.

### Step 2b: Dry-run FIRST (mandatory for new batch configurations)

Always preview before committing to a multi-hour overnight run:

```bash
cd ~/any-starting-dir
claude -p "/gsd-orchestrate 'Optimize performance and harden security' --batch=~/projects-batch.txt --mode=full-auto --dry-run"
```

Output shows:
- Which projects passed pre-flight validation
- Estimated token budget (based on codebase size)
- Estimated duration
- Which hard gates will likely fire (auth, DB, etc.)
- Feature branch names that will be created

If the dry-run looks wrong (project skipped, token estimate too high, unexpected hard-gate), fix the batch file or raise `--token-budget=`.

### Step 3: Prepare the machine for unattended run

**Windows (disable sleep during run):**
```bash
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
```

Restore afterwards: `powercfg /change standby-timeout-ac 30`

**macOS:**
```bash
caffeinate -i &
echo $! > ~/.caffeinate.pid
# Restore: kill $(cat ~/.caffeinate.pid)
```

**Linux:**
```bash
systemd-inhibit --what=sleep --who=gsd --why="overnight run" sleep 8h &
```

### Step 4: Launch the overnight run

Three options — pick one:

#### Option A — Headless print mode (simplest)

```bash
claude -p "/gsd-orchestrate 'Optimize performance and harden security' --batch=~/projects-batch.txt --mode=full-auto --notify=file:~/.claude/orchestrator-done.flag" > ~/gsd-overnight.log 2>&1 &
```

`claude -p` = print mode (non-interactive). Runs, writes to stdout, exits. The `&` detaches it from your terminal. Log goes to `~/gsd-overnight.log`. Notification file appears when done.

Check in the morning:
```bash
ls -la ~/.claude/orchestrator-done.flag   # exists = done
tail -50 ~/gsd-overnight.log              # last output lines
```

#### Option B — Scheduled via Hangar `/schedule` skill

Schedule to run every night at 23:00:

```
/schedule create --cron="0 23 * * *" --prompt="/gsd-orchestrate 'nightly optimization' --batch=~/projects-batch.txt --mode=full-auto --notify=webhook:https://hooks.slack.com/services/..."
```

Manage with `/schedule list` and `/schedule delete <id>`.

#### Option C — tmux detached session

```bash
tmux new-session -d -s gsd-overnight "claude -p '/gsd-orchestrate \"Optimize performance and security\" --batch=~/projects-batch.txt --mode=full-auto'"
```

Check progress anytime:
```bash
tmux capture-pane -p -t gsd-overnight | tail -30
```

Attach if needed: `tmux attach -t gsd-overnight` (detach again with `Ctrl+B D`).

In Claude Code:

```
/gsd-orchestrate "Optimize performance and harden security across the stack" --batch=~/projects-batch.txt --mode=full-auto
```

### What happens overnight

For each project:

1. `cd` into project, verify git clean
2. Run full orchestrator flow (map → milestone → discuss → plan → execute → verify)
3. Collect per-project report
4. Log tokens, decisions, gaps, commits
5. Move to next project regardless of outcome

On any failure (GSD error, budget exceeded, hard gate hit, token cap), the orchestrator:
- Writes a failure entry to the batch summary
- Pauses that project (can be resumed later)
- Continues with the next one

### Step 4: Morning review

Open the batch summary:

```
~/.claude/orchestrator-batch/2026-04-13/SUMMARY.md
```

Example content:

```markdown
# Batch Run — 2026-04-13

**Started:** 2026-04-12 23:00
**Finished:** 2026-04-13 06:12
**Mode:** full-auto
**Goal:** Optimize performance and harden security across the stack

## Results

| Project | Status | Phases | Commits | Tokens | Gaps |
|---|---|---|---|---|---|
| marketing-site | ✓ Complete | 7/7 | 12 | 142k | 2 |
| admin-panel | ⚠ Paused (hard-gate) | 4/6 | 7 | 98k | 1 |
| api-service | ⚠ Failed (token cap) | 3/5 | 5 | 500k | 0 |
| docs-site | ✓ Complete | 5/5 | 8 | 84k | 0 |

**Total:** 824k tokens, 32 commits, 3 gaps for review

## Action Items

- **admin-panel**: Hard gate hit — auth middleware rewrite needs review.
  Reopen with: `cd admin-panel && /gsd-orchestrate resume`
- **api-service**: Token cap hit — raise budget with `--token-budget=1000000` or break into smaller goals.
- **marketing-site**: 2 gap-flagged decisions — see `marketing-site.md` section "Gaps".
```

Then dig into per-project reports:

```
~/.claude/orchestrator-batch/2026-04-13/marketing-site.md
~/.claude/orchestrator-batch/2026-04-13/admin-panel.md
...
```

### Step 5: Morning review workflow

Each project's run created a feature branch (`gsd/<timestamp>-<slug>`), never touched `main`. Review per project:

```bash
cd ~/projects/marketing-site
git branch --list "gsd/*"              # find the run branch
git checkout gsd/2026-04-13-performance-security
git log main..HEAD --oneline           # commits from the orchestrator
git diff main..HEAD --stat             # files changed summary
```

Fast review using the generated diff summary:

```bash
cat .planning/orchestrator/diffs/phase-*.md
```

Each phase wrote its diff summary — scan in minutes, not hours.

If happy: create PR.
```bash
gh pr create --base main --head gsd/2026-04-13-performance-security --fill
```

If not happy for specific commits: `/gsd-undo <commit>`.

If bad overall: full rollback.
```
/gsd-orchestrate rollback 2026-04-13 --project=~/projects/marketing-site
```

### Step 6: Post-run cleanup

Restore sleep settings if you changed them:

```bash
# Windows
powercfg /change standby-timeout-ac 30

# macOS
kill $(cat ~/.caffeinate.pid) && rm ~/.caffeinate.pid
```

---

## Advanced Options

### Limit phases

Run only the first 3 phases:

```
/gsd-orchestrate "Security hardening" --to=3
```

Useful for incremental rollouts or when you want to review mid-way.

### Skip the codebase map

If you already have `.planning/codebase/` from a recent `/gsd-map-codebase` run:

```
/gsd-orchestrate "Add monitoring" --skip-map
```

Saves ~30-60k tokens.

### Raise token budget

Default: 500k per project in batch mode.

```
/gsd-orchestrate "<goal>" --batch=projects.txt --mode=full-auto --token-budget=1000000
```

### Resume an interrupted run

```
/gsd-orchestrate resume
```

Reads `.gsd-orchestrate-state.json` and continues from the last completed phase.

---

## Safety Rules (active in ALL modes, including full-auto)

Even full-auto will always ask you for:

1. **Database schema migrations** (irreversible data changes)
2. **Auth/authentication changes** (security boundary)
3. **Breaking API changes** (downstream impact)
4. **Major-version dependency bumps** (likely breaking changes)
5. **Secrets/config file changes** (credential risk)
6. **Plans touching > 10 files** (blast radius)

These are hard-coded in the skill. You cannot override them with a flag — that is the contract.

---

## Troubleshooting

### "GSD not found"

Install GSD v1 globally:

```bash
npx get-shit-done-cc --claude --global
```

Verify:

```bash
ls ~/.claude/skills/ | grep gsd-map-codebase
```

### "Dirty git tree"

Commit or stash your changes:

```bash
git status
git add -A && git commit -m "wip: before orchestrator run"
```

In batch mode, dirty trees cause that project to be **skipped**, not failed.

### Full-auto made a bad choice

1. Open the decision log:
   ```bash
   cat .planning/orchestrator/decisions.md
   ```
2. Find the decision and its citations.
3. If wrong, revert the commit:
   ```
   /gsd-undo <commit-hash>
   ```
4. Re-run in checkpoint mode:
   ```
   /gsd-orchestrate "<goal>" --mode=checkpoint
   ```

### Decisions keep returning INSUFFICIENT_EVIDENCE

The project lacks context files. Add a `CLAUDE.md` with stack and conventions, then re-run. A thin CLAUDE.md forces the orchestrator into constant gap-flagging.

### Token budget hit mid-batch

Raise it:

```
--token-budget=1500000
```

Or split the goal into smaller goals and run them separately.

---

## Comparison with raw GSD commands

| Task | Raw GSD | With orchestrator |
|---|---|---|
| Answer phase questions | User clicks through | Opus answers with citations |
| Opus enforcement | Manual `/gsd-set-profile quality` | Always on, all subagents |
| Multiple projects | Run one at a time | `--batch` flag |
| Decision audit trail | Scattered across `.planning/` | Single `decisions.md` per run |
| Overnight runs | No protection | Token caps, error recovery, hard-gate enforcement |
| Resume after crash | Manual context reconstruction | `/gsd-orchestrate resume` |

---

## When to NOT use full-auto

- First time on a project — you need to learn the codebase
- Security-critical code without strong tests
- Projects with weak CLAUDE.md (evidence pool too thin)
- Any work where architectural trade-offs are genuinely unclear

In those cases, stick with the default checkpoint mode. Full-auto is for repeat optimization passes on repos you already understand.
