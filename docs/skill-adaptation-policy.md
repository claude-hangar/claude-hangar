# Skill Adaptation Policy

Rules for adopting patterns, skills, hooks, and ideas from external repositories
into Claude Hangar. This policy ensures we build on community innovation while
maintaining our own architectural coherence.

Inspired by [Everything Claude Code](https://github.com/affaan-m/everything-claude-code).

## Core Principles

### 1. Copy the idea, not the dependency

External repos are inspiration sources, not dependencies. Never import files
directly — understand the pattern, then implement it natively in Hangar's
architecture.

### 2. Use Hangar-native surfaces

If an external skill uses a different structure (e.g., YAML config, custom
runner), translate it to Hangar surfaces: SKILL.md, Hook (.sh), Agent (.md),
Rule (.md). See [Capability Surface Guide](capability-surface-guide.md).

### 3. Rename when scope changes materially

If Hangar's version of a pattern differs significantly from the source (narrower
scope, different trigger, different output), give it a different name to avoid
confusion.

### 4. Credit the source

Every adopted pattern must credit its source in:
- The CHANGELOG entry
- The file header (one-line reference)
- The `.freshness-state.json` opportunities array

### 5. No external runtime dependencies

Adopted patterns must work with Hangar's existing tools: Bash, Node.js, standard
CLI tools. Do not introduce new runtime dependencies without explicit justification.

## Evaluation Criteria

Before adopting a pattern, evaluate:

| Criterion | Question |
|-----------|----------|
| **Need** | Does Hangar actually need this? |
| **Fit** | Does it align with Hangar's architecture? |
| **Quality** | Is the source implementation mature? |
| **Maintenance** | Can we maintain this independently? |
| **Overlap** | Does it duplicate something we already have? |

All five must be "yes" before adopting.

## Process

1. **Discover** — Freshness check Tier 5 identifies new community activity
2. **Evaluate** — Apply criteria above in the opportunity analysis (Tier 6)
3. **Design** — Choose the right Hangar surface (rule, skill, hook, agent)
4. **Implement** — Build natively, credit source
5. **Test** — Verify with existing test suite
6. **Document** — CHANGELOG, freshness-state, as-of dates

## Tracked Sources

See `.freshness-state.json` → `community` for the full list of tracked repos
and their check status.
