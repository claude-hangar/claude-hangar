# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest main branch | Yes |
| Older releases | Best effort |

## Reporting a Vulnerability

**Please do NOT create public issues for security vulnerabilities.**

Instead, email **security@claude-hangar.dev** with:

1. Description of the vulnerability
2. Steps to reproduce
3. Potential impact
4. Suggested fix (if any)

### Response Timeline

- **48 hours** — Acknowledgment of your report
- **7 days** — Initial assessment and severity classification
- **30 days** — Fix developed and tested (for confirmed vulnerabilities)

### What Qualifies as a Security Issue

- Secret/credential leaks through hooks or skills
- Hook bypass allowing blocked operations to proceed
- Command injection in hook scripts
- Memory poisoning via MEMORY.md manipulation
- Unauthorized file access through agent tools
- Supply chain issues in dependencies

### Scope

The following components are in scope:

- Hook scripts (`core/hooks/`)
- Agent definitions (`core/agents/`)
- Skill definitions (`core/skills/`)
- Setup script (`setup.sh`, `install.sh`)
- Settings template (`core/settings.json.template`)
- Statusline script (`core/statusline-command.sh`)

### Recognition

Security contributors are acknowledged in the CHANGELOG (unless they prefer to remain anonymous).

## Security Best Practices

When contributing to Claude Hangar:

- Never commit real secrets, tokens, or credentials
- Use `{{PLACEHOLDER}}` format for configurable sensitive values
- Test hooks for injection resistance
- Follow the principle of least privilege for agent tool permissions
- Validate all JSON input in hooks before processing
