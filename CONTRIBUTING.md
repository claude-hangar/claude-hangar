# Contributing to Claude Hangar

Thank you for your interest in contributing! Claude Hangar is an open-source project and we welcome contributions of all kinds.

## Ways to Contribute

### New Stacks

Add support for your favorite framework:

1. Create a directory under `stacks/{framework-name}/`
2. Add a `README.md` explaining what the stack provides
3. Include skills, hooks, or template snippets specific to the framework
4. Submit a PR with a clear description of what the stack covers

### Skills

Share your workflow automations:

1. Create a directory under `core/skills/{skill-name}/`
2. Add a `SKILL.md` with trigger description and implementation
3. Include `fix-templates.md` if the skill generates fixes
4. Add a tutorial in `docs/tutorials/`

### Hooks

Extend the hook system:

1. Add your hook script to `core/hooks/`
2. Document the hook event and matcher pattern
3. Add test cases to `tests/test-hooks.sh`
4. Update the settings.json template if needed

### Translations

Help us reach more developers:

1. Check `i18n/i18n.md` for the translation guide
2. Create a directory under `i18n/{language-code}/`
3. Translate README.md and docs

### Bug Reports & Feature Requests

Use the [issue templates](https://github.com/claude-hangar/claude-hangar/issues/new/choose) to report bugs or suggest features.

## Development Setup

```bash
git clone https://github.com/claude-hangar/claude-hangar.git
cd claude-hangar

# Run tests
bash tests/test-hooks.sh

# Dry-run setup
bash setup.sh --check

# Validate everything
bash setup.sh --verify
```

## Pull Request Guidelines

1. **One PR per feature/fix** — keep changes focused
2. **Conventional Commits** — `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`
3. **Tests required** — add tests for new hooks, update tests for changes
4. **CI must pass** — ShellCheck, JSON validation, secret scan, markdown lint
5. **Fill out the PR template** completely
6. **No personal data** — use `{{PLACEHOLDER}}` format for configurable values

## Code Standards

- **Shell:** Bash 4.0+ compatible, cross-platform (Linux + Git Bash on Windows)
- **JSON:** Valid, 2-space indent
- **Markdown:** Pass markdownlint with project config
- **Templates:** `{{UPPER_SNAKE_CASE}}` for placeholders
- **No hardcoded versions** — always resolve dynamically

## Review Process

1. All PRs are reviewed by maintainers
2. Skills and hooks undergo adversarial review (does it handle edge cases?)
3. Cross-platform testing is required for shell scripts
4. Documentation updates are expected for user-facing changes

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
