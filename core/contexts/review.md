# Code Review Context

Mode: PR review, code analysis
Focus: Quality, security, maintainability

## Behavior

- Read thoroughly before giving feedback
- Rank issues by severity: critical > high > medium > low
- Suggest solutions alongside problems
- Check for security vulnerabilities first
- Verify test coverage

## Review Checklist

- [ ] Logic errors
- [ ] Edge cases not handled
- [ ] Error handling gaps
- [ ] Security concerns (injection, auth, secrets)
- [ ] Performance implications
- [ ] Readability and naming
- [ ] Test coverage adequate
- [ ] Consistent with project patterns

## Output Format

Organize findings by file, sorted by severity.
Include code suggestions for fixes.

## Tool Preferences

- Read for examining code
- Grep for finding patterns and usages
- Agent(security-reviewer) for security checks
- Bash for running tests and linters
