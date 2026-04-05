# Go Testing

## Conventions
- Test files: `foo_test.go` (same package)
- Test functions: `TestFoo(t *testing.T)`
- Table-driven tests for multiple scenarios
- Testify for assertions (optional but recommended)

## Patterns

### Table-Driven Tests
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {"positive", 1, 2, 3},
        {"zero", 0, 0, 0},
        {"negative", -1, 1, 0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
            }
        })
    }
}
```

### Test Helpers
- Use `t.Helper()` for test utility functions
- Use `t.Cleanup()` for teardown
- Use `testdata/` directory for test fixtures

### Race Detection
- Always run tests with `-race` flag in CI
- `go test -race -count=1 ./...`

### Coverage
- `go test -cover -coverprofile=coverage.out ./...`
- 80% minimum coverage
