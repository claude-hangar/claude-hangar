# Java Patterns

## Code Style

### Modern Java (17+)
- Use records for data classes
- Pattern matching with `instanceof`
- Sealed classes for restricted hierarchies
- Text blocks for multi-line strings
- Switch expressions over switch statements

### Error Handling
- Checked exceptions for recoverable errors
- Unchecked exceptions for programming errors
- Never catch `Exception` or `Throwable` directly
- Always close resources with try-with-resources

### Patterns
- Dependency injection (constructor injection preferred)
- Repository pattern for data access
- Builder pattern for complex objects
- Strategy pattern over long if-else chains

### Testing
- JUnit 5 for unit tests
- Mockito for mocking
- AssertJ for fluent assertions
- Testcontainers for integration tests
- 80% minimum coverage
