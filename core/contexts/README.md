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
