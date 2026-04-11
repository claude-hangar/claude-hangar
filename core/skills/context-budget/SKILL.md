---
name: context-budget
description: Analyzes where context tokens are being spent and identifies optimization opportunities. Use when sessions feel slow or context is running out.
effort: low
user-invocable: true
argument-hint: ""
---

# /context-budget — Token Spending Analysis

Audits your current context window to show where tokens are being consumed
and identifies opportunities to reduce waste.

## Usage

```
/context-budget            # Full analysis
/context-budget quick      # Summary only
```

## What It Analyzes

### 1. System Prompt Weight
Estimate token cost of loaded context:
- CLAUDE.md content (project instructions)
- Active skills loaded into context
- MCP server tool schemas (each server adds 200-800 tokens)
- Rules loaded from ~/.claude/rules/

### 2. Conversation History
- Total messages in current conversation
- Average tokens per message
- Large tool results consuming disproportionate context

### 3. Tool Schema Overhead
- Count of available tools and their schema weight
- MCP servers contributing the most overhead
- Unused tools that could be removed

### 4. Optimization Opportunities

| Opportunity | Typical Savings | How |
|------------|----------------|-----|
| Compact after planning | 30-50% | `/compact` removes exploration clutter |
| Remove unused MCP servers | 200-800 tokens each | Uninstall servers you're not using |
| Trim CLAUDE.md | 500-2000 tokens | Remove outdated instructions |
| Use subagents for research | 60-80% of results | Agent tool isolates large outputs |
| Avoid re-reading large files | 1000+ tokens each | Read once, reference by line numbers |

## Output Format

```
## Context Budget Analysis

### Current Allocation (estimated)
| Component | Tokens | % |
|-----------|--------|---|
| System prompt | ~4,000 | 2% |
| CLAUDE.md | ~2,500 | 1.3% |
| MCP schemas (5 servers) | ~3,000 | 1.5% |
| Conversation history | ~45,000 | 22.5% |
| Available budget | ~145,500 | 72.7% |

### Top Optimizations
1. Consider /compact — conversation history is 22.5% of context
2. MCP server "sequential-thinking" adds ~800 tokens but hasn't been used this session
3. 3 large file reads (>500 lines each) in history could be replaced with targeted reads
```

## When to Use

- When you notice Claude Code getting slower or less accurate
- Before starting a large implementation task
- After a long research/exploration phase
- When token-warning hook fires (70%+ usage)

Inspired by ECC's context-budget skill and token optimization strategies.
