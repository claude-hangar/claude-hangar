# Token Optimization Guide

Strategies for managing context efficiently in Claude Code sessions.
Based on production experience and insights from Everything Claude Code.

## Understanding Your Context Budget

Claude Code models have a context window (typically 200K tokens). Your
available budget is consumed by:

| Component | Typical Tokens | Notes |
|-----------|---------------|-------|
| System prompt | 3,000-5,000 | Built-in Claude Code instructions |
| CLAUDE.md | 500-3,000 | Your project instructions |
| MCP server schemas | 200-800 each | Each installed MCP server adds tool schemas |
| Loaded skills | 500-2,000 each | Skills loaded into context on invocation |
| Conversation history | Grows over time | Messages, tool calls, tool results |
| Available tools | 1,000-3,000 | Built-in + MCP tool definitions |

**Rule of thumb:** You start with ~180K usable tokens. A typical productive
session consumes 50-100K tokens. Quality degrades noticeably above 70% usage.

## Strategy 1: Strategic Compaction

Don't wait for context to fill up — compact proactively at workflow boundaries.

### Good Times to Compact
- After planning is complete (exploration clutter gone)
- After a commit (implementation details summarized)
- After switching tasks (previous context is stale)
- After long research phases (findings are in files)
- When token-warning fires (70%+ usage)

### Bad Times to Compact
- Mid-implementation (lose track of current work)
- During debugging (lose investigation trail)
- Before committing (lose change context)

Use `/strategic-compact` to analyze whether now is a good time.

## Strategy 2: Subagent Isolation

Large research tasks consume massive context. Delegate to subagents instead:

```
// BAD: Read 10 files yourself (10,000+ tokens in history)
Read file1.ts → Read file2.ts → Read file3.ts → ...

// GOOD: Delegate to explorer agent (result is summarized)
Agent(explorer, "Find all authentication patterns in src/")
→ Returns: "3 auth patterns found: JWT in auth.ts:45, session in..."
```

**Savings:** 60-80% of the tokens that tool results would consume.

## Strategy 3: Targeted File Reading

```
// BAD: Read entire file (1,000+ tokens)
Read("src/large-file.ts")

// GOOD: Read only what you need (100-200 tokens)
Read("src/large-file.ts", offset=42, limit=20)
```

After reading a file once, reference by file:line instead of re-reading.

## Strategy 4: Model Routing

Use the right model for each task:

| Task | Model | Why |
|------|-------|-----|
| Quick search, file exploration | Sonnet | Fast, cheap |
| Multi-file coding | Sonnet | Good balance |
| Architecture decisions | Opus | Best reasoning |
| Security review | Opus | Highest accuracy needed |
| Simple generation | Haiku | Fastest, cheapest |

The model-router hook does this automatically based on complexity analysis.

## Strategy 5: MCP Server Hygiene

Each MCP server adds its tool schemas to every message (~200-800 tokens).

- **Audit:** Run `/context-budget` to see MCP overhead
- **Remove unused servers:** If you're not using a server, uninstall it
- **Core only:** Context7 and GitHub are usually sufficient
- **Stack-specific:** Only install database/security MCPs when needed

## Strategy 6: CLAUDE.md Optimization

Keep CLAUDE.md concise — every token counts on every message:

- Remove outdated instructions
- Use short, imperative sentences
- Link to detailed docs instead of inlining them
- Remove redundant information (don't repeat defaults)

## Strategy 7: Parallel Agent Execution

Independent tasks should run as parallel subagents:

```
// BAD: Sequential (blocks context)
Agent(reviewer-ts, "Review auth") → wait →
Agent(reviewer-security, "Scan auth") → wait →
Agent(test-writer, "Write auth tests")

// GOOD: Parallel (isolated context per agent)
Agent(reviewer-ts, "Review auth")
Agent(reviewer-security, "Scan auth")
Agent(test-writer, "Write auth tests")
```

## Monitoring

- **token-warning hook** — Alerts at 70% and 80% usage
- **context-budget skill** — `/context-budget` for detailed analysis
- **strategic-compact skill** — `/strategic-compact` for compaction timing

## Quick Reference

| Situation | Action |
|-----------|--------|
| Session feels slow | Run `/context-budget` |
| 70% warning fired | Run `/strategic-compact` |
| Long research phase done | `/compact` |
| Large file to analyze | Use `Agent(explorer)` |
| Multiple independent tasks | Parallel subagents |
| MCP tools you don't use | Uninstall the server |
