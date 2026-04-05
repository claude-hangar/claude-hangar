# Python Patterns

## Code Style

### Type Hints (Mandatory)
- All public functions must have type hints
- Use `from __future__ import annotations` for modern syntax
- Use `TypeAlias` for complex types
- Pydantic models for data validation at boundaries

### Project Structure
- `src/` layout for packages
- `pyproject.toml` over `setup.py` (PEP 621)
- Virtual environments mandatory (venv, poetry, or uv)
- Pin dependencies in lockfile

### Patterns
- Context managers for resource handling
- Dataclasses for simple data containers, Pydantic for validation
- Pathlib over os.path for file operations
- Comprehensions for simple transforms, regular loops for complex logic
- Generator expressions for large datasets

### Error Handling
- Specific exceptions only — never bare `except:`
- Custom exception hierarchy for domain errors
- Logging with structlog or stdlib logging (not print())
