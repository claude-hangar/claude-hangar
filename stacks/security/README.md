# Security Stack

MCP server for security scanning. Provides Claude Code with vulnerability detection across dependencies, code, infrastructure-as-code, and container images.

## MCP Server

| Server | Package | Credentials |
|--------|---------|-------------|
| Snyk | `snyk` | OAuth (runs `snyk auth` on first use) |

## Setup

1. Install Snyk CLI: `npm install -g snyk`
2. Authenticate: `snyk auth`
3. Run `bash setup.sh` — the Snyk MCP server will be configured automatically

## What Claude Can Do With This

- `snyk_sca_scan` — Scan dependencies for known vulnerabilities
- `snyk_code_scan` — Static analysis for security flaws in source code
- `snyk_iac_scan` — Check infrastructure-as-code (Dockerfiles, Terraform, etc.)
- `snyk_container_scan` — Scan container images for vulnerabilities
