# Git Workflow

Git conventions for consistent version control.

## Commit Messages

Format: `<type>(<scope>): <description>`

### Allowed Types

| Type | Use for |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring (no behavior change) |
| `docs` | Documentation only |
| `test` | Adding/fixing tests |
| `chore` | Build, tooling, dependencies |
| `perf` | Performance improvement |
| `ci` | CI/CD changes |
| `style` | Formatting (no code change) |
| `build` | Build system changes |
| `revert` | Reverting a previous commit |

### Rules

- Subject line: max 72 characters
- No trailing period
- Imperative mood ("add feature", not "added feature")
- Body: explain WHY, not WHAT (the diff shows what)

## Branch Strategy

- `main` — production-ready, always deployable
- `feat/<name>` — feature branches
- `fix/<name>` — bugfix branches
- `chore/<name>` — maintenance branches

## Pull Request Workflow

1. Review complete commit history (not just latest commit)
2. Run `git diff <base-branch>...HEAD` to inspect all changes
3. Write detailed PR description with context
4. Include test plan
5. Push with `-u` flag for new branches

## Pre-Push Checklist

- [ ] All tests pass
- [ ] No linting errors
- [ ] No type errors
- [ ] Branch is up-to-date with target
- [ ] Commit messages follow convention
