# Coding Style

Rules for writing clean, maintainable code across all languages.

## Immutability

Prefer immutable patterns. Create new objects instead of mutating existing ones.

**Why:** Prevents hidden side effects, makes debugging easier, enables safe concurrency.

```
// GOOD: Create new object
const updated = { ...original, status: "active" };

// BAD: Mutate in place
original.status = "active";
```

## File Organization

Many small files > few large files.

- **Target:** 200-400 lines per file
- **Maximum:** 800 lines (extract utilities if exceeding)
- **Organize by:** Feature/domain, not by type
- **Each file:** One clear responsibility

## Function Size

- **Target:** Under 30 lines
- **Maximum:** 50 lines
- **Nesting:** Maximum 4 levels deep — extract helper if deeper

## Error Handling

Handle errors explicitly at every level:

- Provide user-friendly messages in UI code
- Log detailed error context server-side
- Never silently swallow errors
- Use typed error classes where the language supports them

## Input Validation

Validate at system boundaries:

- All user input before processing
- All API responses before use
- All file content before parsing
- Use schema-based validation (Zod, Pydantic, etc.)
- Fail fast with clear messages

## Naming

- Variables/functions: descriptive, verb-based for functions (`getUserById`, `validateInput`)
- Constants: UPPER_SNAKE_CASE
- Types/Classes: PascalCase
- Files: kebab-case or match framework convention
- No abbreviations unless universally understood (`id`, `url`, `db`)

## Code Quality Checklist

Before considering code complete:

- [ ] Readable without comments (self-documenting)
- [ ] Functions under 50 lines
- [ ] Files under 800 lines
- [ ] Nesting under 4 levels
- [ ] Errors handled explicitly
- [ ] No hardcoded values (use constants/config)
- [ ] Immutable patterns used where possible
