# Code Quality Defaults

> Shared code quality reference for agents, governance rules, and review processes.
> Referenced by: `code-reviewer` agent, `adversarial-review` skill, `inline-review` skill, governance rules.
> Location: `core/references/code-quality.md`

## Cardinal Rule

**Fix code, never weaken configs.** When code fails a linter, type check, or test — fix the code. Never disable the rule, loosen the config, or add a suppression comment without explicit justification. Reference: `config-protection` hook.

## Immutability

- Create new objects instead of mutating existing ones
- Spread operator for shallow updates, `structuredClone` for deep copies
- Treat function arguments as read-only

## Control Flow

- **Early returns** over deep nesting — max 4 levels of indentation
- Guard clauses at the top of functions
- Ternaries for simple expressions, `if/else` for complex logic

## Size Limits

| Scope | Target | Maximum |
|-------|--------|---------|
| Function | 30 lines | 50 lines |
| File | 200-400 lines | 800 lines |
| Nesting depth | 2-3 levels | 4 levels |

Extract helpers, utilities, or modules when approaching limits.

## Validation & Error Handling

- **Validate at boundaries** — system edges (API handlers, CLI input, file parsing)
- **Trust internally** — once validated, pass typed data without re-checking
- **Handle every error explicitly** — no empty catch blocks, no swallowed promises
- **Typed errors** — use custom error classes or error enums, not string messages
- **User-facing messages** — clear and actionable, no stack traces

## Security Hygiene

- No hardcoded secrets (API keys, passwords, tokens) — use environment variables
- No hardcoded versions — always check live sources
- No personal data in committed code — use template placeholders (`{{UPPER_SNAKE}}`)
- Parameterized queries only — no string concatenation for SQL
- Input sanitization for HTML output — prevent XSS

## Testing Philosophy

- **Test behavior, not implementation** — what it does, not how it does it
- **80% coverage minimum** — baseline for all code paths
- **95%+ for critical paths** — authentication, payment, data mutations
- **Deterministic tests** — no flaky tests, no shared state between tests
- **Arrange-Act-Assert** pattern for clarity

## Code Smells to Flag

- Functions doing more than one thing
- Boolean parameters (use named options or separate functions)
- Magic numbers without named constants
- Commented-out code (delete it, git remembers)
- `any` type in TypeScript without documented justification
- Bare `except:` in Python
- `unwrap()` in Rust production code
