# Python Testing

## Framework: pytest (mandatory)

### Conventions
- Test files: `test_<module>.py`
- Test functions: `test_<behavior>()`
- Fixtures for setup/teardown
- Parametrize for table-driven tests

### Patterns
- `pytest.raises()` for exception testing
- `pytest.mark.parametrize` for data-driven tests
- `conftest.py` for shared fixtures (don't import from other test files)
- `pytest-cov` for coverage reporting

### Mocking
- `unittest.mock.patch` for external dependencies
- Never mock the code under test
- Prefer dependency injection over patching
- Use `responses` or `httpx_mock` for HTTP mocking

### Coverage
- 80% minimum: `pytest --cov=src --cov-fail-under=80`
- Integration tests for database operations (use test database)
