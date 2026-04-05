# TypeScript Patterns

## Framework-Agnostic Rules

### Strict TypeScript
- Enable `strict: true` in tsconfig.json — no exceptions
- No `any` type without explicit `// @ts-expect-error: [reason]`
- Use `unknown` for truly unknown types, then narrow with type guards
- Prefer `interface` for object shapes, `type` for unions/intersections

### Import Style
- Named imports over default imports (better tree-shaking)
- Group imports: external → internal → relative
- No circular dependencies — use dependency injection if needed

### Async Patterns
- Always use async/await over .then() chains
- Handle errors with try/catch at the boundary, not every call
- Use Promise.all() for independent async operations
- AbortController for cancellable operations

### State Management
- Immutable updates (spread, structuredClone for deep copies)
- Single source of truth — avoid derived state
- Minimize global state — prefer local state and props/parameters

## React-Specific (When Applicable)

- Server Components by default, Client Components only when needed
- Use `use` hook for data fetching in React 19+
- Prefer composition over inheritance
- No useEffect for derived state — use useMemo
