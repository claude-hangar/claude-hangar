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
