# Testing

Testing requirements for all projects.

## Minimum Coverage

**80%** test coverage as baseline. Critical paths (auth, payments, data mutations) require **95%+**.

## Required Test Types

| Type | Scope | When |
|------|-------|------|
| **Unit** | Isolated functions/components | Every feature |
| **Integration** | API endpoints, DB operations | Every backend change |
| **E2E** | Critical user workflows | Before release |

All three types are required — none optional.

## TDD Workflow (Mandatory for New Features)

1. **RED** — Write the failing test first
2. **GREEN** — Write minimum code to make it pass
3. **IMPROVE** — Refactor while keeping tests green
4. Verify coverage meets 80%+ threshold

## Test Quality

- Tests must be deterministic (no flaky tests)
- Tests must be independent (no shared state between tests)
- Test names describe the behavior, not the implementation
- Each test tests ONE thing
- Arrange-Act-Assert pattern

## When Tests Fail

1. **Fix the implementation**, not the test (unless the test is wrong)
2. Check test isolation — tests should not depend on each other
3. Validate mocks match real behavior
4. Use the tdd-guide agent for complex test scenarios

## What NOT to Test

- Framework internals (React rendering, Express routing)
- Simple getters/setters with no logic
- Third-party library behavior
- Constants and configuration values
