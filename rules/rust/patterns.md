# Rust Patterns

## Code Style

### Ownership & Borrowing
- Prefer borrowing (`&T`) over cloning
- Use `Cow<'_, T>` when ownership is conditional
- Implement `Clone` only when genuinely needed
- Lifetime annotations: minimize, let the compiler infer where possible

### Error Handling
- Use `thiserror` for library errors, `anyhow` for applications
- `?` operator for error propagation
- No `unwrap()` in production code — use `expect("reason")` at minimum
- Custom error enums for domain errors

### Patterns
- Builder pattern for complex struct construction
- Type-state pattern for compile-time state machines
- Newtype pattern for type safety (`struct UserId(u64)`)
- Iterator adaptors over manual loops

### Performance
- Use `#[inline]` sparingly (compiler usually knows better)
- Profile with `cargo flamegraph` before optimizing
- Prefer stack allocation over heap when possible
- Use `SmallVec` for small, fixed-size collections
