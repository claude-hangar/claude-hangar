# GitHub Stack

MCP server for GitHub integration. Provides Claude Code with direct access to repositories, pull requests, issues, code search, and branch management.

## MCP Server

| Server | Package | Credentials |
|--------|---------|-------------|
| GitHub | `@modelcontextprotocol/server-github` | `GITHUB_TOKEN` (Personal Access Token) |

## Setup

1. Create a GitHub Personal Access Token at https://github.com/settings/tokens
2. Set the environment variable: `export GITHUB_TOKEN=ghp_your_token_here`
3. Run `bash setup.sh` — the GitHub MCP server will be configured automatically

## What Claude Can Do With This

- Search code across repositories
- Read and create issues
- Review and create pull requests
- Create branches and manage files
- Query commit history

## GitHub Agentic Workflows (Technical Preview)

Since February 2026, GitHub offers **Agentic Workflows** in technical preview. Markdown files in `.github/workflows/` can be converted to GitHub Actions via the `gh aw` CLI. This allows defining workflows in natural language that are then compiled to standard Actions YAML. Informational only — evaluate if relevant for your project.
