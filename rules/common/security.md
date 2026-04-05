# Security

Non-negotiable security rules for every project.

## Pre-Commit Checklist

Before any commit, verify:

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] SQL injection prevention (parameterized queries only)
- [ ] XSS prevention (sanitized HTML output)
- [ ] CSRF protection enabled (where applicable)
- [ ] Authentication/authorization verified on all endpoints
- [ ] Rate limiting on public endpoints
- [ ] Error messages do not leak sensitive data

## Secret Management

- **NEVER** hardcode secrets in source code
- **ALWAYS** use environment variables or a secret manager
- **VALIDATE** required secrets are present at startup
- **ROTATE** any secrets that may have been exposed
- **GITIGNORE** all .env files (except .env.example with placeholder values)

## Security Response Protocol

When a vulnerability is discovered:

1. **STOP** current work immediately
2. **ASSESS** severity (critical/high/medium/low)
3. **FIX** critical issues before resuming any other work
4. **ROTATE** any exposed credentials
5. **SCAN** codebase for similar vulnerabilities
6. **DOCUMENT** the vulnerability and fix

## Dependency Security

- Run `npm audit` / `pip audit` / `go vet` before deployment
- Pin exact dependency versions in lock files
- Review new dependencies for security advisories
- Prefer well-maintained packages with active security response

## OWASP Top 10 Awareness

Every developer interaction must consider:

1. **Injection** — Parameterized queries, no string concatenation
2. **Broken Auth** — Secure session management, strong passwords
3. **Sensitive Data** — Encrypt at rest and in transit
4. **XXE** — Disable external entity processing
5. **Broken Access** — Verify authorization on every request
6. **Misconfiguration** — Secure defaults, no debug in production
7. **XSS** — Output encoding, CSP headers
8. **Deserialization** — Validate before deserializing
9. **Components** — Keep dependencies updated
10. **Logging** — Log security events, monitor anomalies
