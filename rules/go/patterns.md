# Go Patterns

## Code Style

### Error Handling
- Check every error — no `_ = err`
- Wrap errors with context: `fmt.Errorf("doing X: %w", err)`
- Sentinel errors for expected conditions (`var ErrNotFound = errors.New(...)`)
- Custom error types for domain errors with additional context

### Naming
- Short names in small scopes (`i`, `r`, `ctx`)
- Descriptive names in larger scopes (`userRepository`, `processOrder`)
- Interfaces: verb-based (`Reader`, `Closer`, `Handler`)
- No stuttering: `user.User` bad, `user.Account` good

### Concurrency
- Don't start goroutines without a plan to stop them
- Use `errgroup` for parallel operations with error handling
- Prefer channels for communication, mutex for state protection
- Always use `context.Context` for cancellation

### Project Structure
- Follow standard Go project layout
- Internal packages for private code
- Cmd packages for entry points
- No init() functions — use explicit initialization
