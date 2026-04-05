# TypeScript Testing

## Framework: Vitest (preferred) or Jest

### Unit Tests
- One test file per source file: `foo.ts` → `foo.test.ts`
- Co-locate tests with source (not in separate `__tests__/` directory)
- Use `describe` for grouping, `it` for individual tests

### Component Testing (React/Svelte/Vue)
- Testing Library for user-interaction tests
- Test behavior, not implementation
- Never test CSS classes or DOM structure directly
- Use `screen.getByRole()` over `getByTestId()`

### API Testing
- Supertest for HTTP endpoint tests
- Test success, validation errors, auth errors, and edge cases
- Mock external services, never mock your own code

### Coverage
- 80% minimum, 95%+ for auth/payment/data mutation paths
- Branch coverage, not just line coverage
